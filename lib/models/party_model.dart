import 'package:cloud_firestore/cloud_firestore.dart';

/// โมเดลของ "ตี้" หนึ่งใบ
class PartyModel {
  final String? id;
  final String title;
  final String gameId;
  final String? rank;
  final String? role;
  final int current;
  final int? max;
  final String ownerId;
  final String ownerName;
  final String leadAvatar;

  /// uid ของสมาชิกทุกคนในตี้ (รวม owner)
  /// owner จะอยู่ index 0 เสมอ
  /// length ของ list = current
  final List<String> memberIds;

  final DateTime createdAt;

  PartyModel({
    this.id,
    required this.title,
    required this.gameId,
    this.rank,
    this.role,
    required this.current,
    this.max,
    required this.ownerId,
    required this.ownerName,
    required this.leadAvatar,
    required this.memberIds,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'gameId': gameId,
      'rank': rank,
      'role': role,
      'current': current,
      'max': max,
      'ownerId': ownerId,
      'ownerName': ownerName,
      'leadAvatar': leadAvatar,
      'memberIds': memberIds,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory PartyModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final ownerId = (data['ownerId'] ?? '') as String;

    // backward compat: party เก่าที่ยังไม่มี memberIds
    // -> สมมุติว่ามีแค่ owner คนเดียว
    final memberIds = List<String>.from(data['memberIds'] ?? [ownerId]);

    return PartyModel(
      id: doc.id,
      title: (data['title'] ?? '') as String,
      gameId: (data['gameId'] ?? '') as String,
      rank: data['rank'] as String?,
      role: data['role'] as String?,
      current: (data['current'] ?? memberIds.length) as int,
      max: data['max'] as int?,
      ownerId: ownerId,
      ownerName: (data['ownerName'] ?? 'Unknown') as String,
      leadAvatar: (data['leadAvatar'] ?? '') as String,
      memberIds: memberIds,
      createdAt: (data['createdAt'] is Timestamp)
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  // ===== shortcuts =====
  bool isMember(String uid) => memberIds.contains(uid);
  bool isFull() => max != null && current >= max!;
}