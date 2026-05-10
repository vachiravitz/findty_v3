import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/message_model.dart';

/// chat ใน party — sub-collection ของ parties/{partyId}/messages
class ChatService {
  ChatService._();
  static final instance = ChatService._();

  CollectionReference<Map<String, dynamic>> _msgCol(String partyId) =>
      FirebaseFirestore.instance
          .collection('parties')
          .doc(partyId)
          .collection('messages');

  Future<void> sendMessage(String partyId, Message msg) =>
      _msgCol(partyId).add(msg.toMap());

  /// stream messages เรียง เก่า -> ใหม่ (ตามที่ chat ปกติแสดง)
  Stream<List<Message>> watchMessages(String partyId) =>
      _msgCol(partyId).snapshots().map((s) {
        final list = s.docs.map(Message.fromDoc).toList();
        list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        return list;
      });
}
