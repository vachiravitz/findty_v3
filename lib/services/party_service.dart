import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/party_model.dart';

/// service ห่อ logic ของ Firestore สำหรับ party
class PartyService {
  PartyService._();
  static final instance = PartyService._();

  static const String _collection = 'parties';

  CollectionReference<Map<String, dynamic>> get _col =>
      FirebaseFirestore.instance.collection(_collection);

  Stream<List<PartyModel>> watchParties(String gameId) {
    return _col.where('gameId', isEqualTo: gameId).snapshots().map((snap) {
      final list = snap.docs.map(PartyModel.fromDoc).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  Stream<int> watchPartyCount(String gameId) {
    return _col
        .where('gameId', isEqualTo: gameId)
        .snapshots()
        .map((s) => s.docs.length);
  }

  Stream<PartyModel?> watchParty(String partyId) {
    return _col
        .doc(partyId)
        .snapshots()
        .map((d) => d.exists ? PartyModel.fromDoc(d) : null);
  }

  Future<String> createParty(PartyModel party) async {
    final ref = await _col.add(party.toMap());
    return ref.id;
  }

  /// เข้าร่วมตี้ — ใช้ transaction กัน race condition
  Future<void> joinParty(String partyId, String uid) async {
    final ref = _col.doc(partyId);
    await FirebaseFirestore.instance.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) {
        throw Exception('ตี้ไม่มีอยู่แล้ว');
      }
      final data = snap.data() as Map<String, dynamic>;
      final ownerId = (data['ownerId'] ?? '') as String;
      final memberIds = List<String>.from(data['memberIds'] ?? [ownerId]);
      final max = data['max'] as int?;

      if (memberIds.contains(uid)) {
        throw Exception('คุณอยู่ในตี้นี้แล้ว');
      }
      if (max != null && memberIds.length >= max) {
        throw Exception('ตี้เต็มแล้ว');
      }

      memberIds.add(uid);
      tx.update(ref, {
        'memberIds': memberIds,
        'current': memberIds.length,
      });
    });
  }

  /// ออกจากตี้ — owner ออกไม่ได้ (ต้องลบทั้งตี้)
  Future<void> leaveParty(String partyId, String uid) async {
    final ref = _col.doc(partyId);
    await FirebaseFirestore.instance.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) return;
      final data = snap.data() as Map<String, dynamic>;
      final ownerId = (data['ownerId'] ?? '') as String;
      if (ownerId == uid) {
        throw Exception('หัวตี้ออกไม่ได้ ต้องลบตี้แทน');
      }
      final memberIds = List<String>.from(data['memberIds'] ?? [ownerId]);
      memberIds.remove(uid);
      tx.update(ref, {
        'memberIds': memberIds,
        'current': memberIds.length,
      });
    });
  }

  /// ลบตี้ + ข้อความ chat ทั้งหมดในตี้นั้น
  ///
  /// Firestore ไม่ auto-delete sub-collection -> ต้องลบ messages เองก่อน
  /// ใช้ WriteBatch เพื่อลบหลาย doc ในการเรียก commit ครั้งเดียว
  ///
  /// หมายเหตุ: caller (UI) ควร verify ก่อนว่า user เป็น owner
  /// แม้ Firestore Rules จะ enforce ให้แล้วก็ตาม
  Future<void> deleteParty(String partyId) async {
    final firestore = FirebaseFirestore.instance;
    final partyRef = _col.doc(partyId);
    final messagesSnap = await partyRef.collection('messages').get();

    // batch จำกัดที่ ~500 ops ถ้า message เยอะกว่านั้นต้อง chunk (โอกาสน้อย)
    final batch = firestore.batch();
    for (final m in messagesSnap.docs) {
      batch.delete(m.reference);
    }
    batch.delete(partyRef);
    await batch.commit();
  }
}