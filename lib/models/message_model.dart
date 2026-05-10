import 'package:cloud_firestore/cloud_firestore.dart';

/// 1 message = 1 doc ใน parties/{partyId}/messages/{msgId}
class Message {
  final String? id;
  final String senderId;
  final String senderName;
  final String senderAvatar;
  final String text;
  final DateTime createdAt;

  Message({
    this.id,
    required this.senderId,
    required this.senderName,
    required this.senderAvatar,
    required this.text,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'senderId': senderId,
        'senderName': senderName,
        'senderAvatar': senderAvatar,
        'text': text,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  factory Message.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return Message(
      id: doc.id,
      senderId: (d['senderId'] ?? '') as String,
      senderName: (d['senderName'] ?? 'Anon') as String,
      senderAvatar: (d['senderAvatar'] ?? '') as String,
      text: (d['text'] ?? '') as String,
      createdAt: (d['createdAt'] is Timestamp)
          ? (d['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }
}
