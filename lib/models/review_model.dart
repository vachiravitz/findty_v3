import 'package:cloud_firestore/cloud_firestore.dart';

/// 1 review = 1 doc ใน users/{targetUid}/reviews/{reviewId}
class Review {
  final String? id;
  final String reviewerUid;
  final String reviewerName;
  final String reviewerAvatar;
  final double rating; // 1.0 - 5.0
  final String text;
  final DateTime createdAt;

  Review({
    this.id,
    required this.reviewerUid,
    required this.reviewerName,
    required this.reviewerAvatar,
    required this.rating,
    required this.text,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'reviewerUid': reviewerUid,
        'reviewerName': reviewerName,
        'reviewerAvatar': reviewerAvatar,
        'rating': rating,
        'text': text,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  factory Review.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return Review(
      id: doc.id,
      reviewerUid: (d['reviewerUid'] ?? '') as String,
      reviewerName: (d['reviewerName'] ?? 'Anonymous') as String,
      reviewerAvatar: (d['reviewerAvatar'] ?? '') as String,
      rating: (d['rating'] ?? 5).toDouble(),
      text: (d['text'] ?? '') as String,
      createdAt: (d['createdAt'] is Timestamp)
          ? (d['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }
}
