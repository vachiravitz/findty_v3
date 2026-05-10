import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_profile_model.dart';
import '../models/review_model.dart';

/// CRUD profile + reviews
/// reviews อยู่ที่ users/{uid}/reviews/{reviewId}
class UserService {
  UserService._();
  static final instance = UserService._();

  CollectionReference<Map<String, dynamic>> get _users =>
      FirebaseFirestore.instance.collection('users');

  // ============ PROFILE ============
  Future<void> createOrUpdateProfile(UserProfile profile) =>
      _users.doc(profile.uid).set(profile.toMap(), SetOptions(merge: true));

  Future<UserProfile?> getProfile(String uid) async {
    final doc = await _users.doc(uid).get();
    if (!doc.exists) return null;
    return UserProfile.fromDoc(doc);
  }

  Stream<UserProfile?> watchProfile(String uid) =>
      _users.doc(uid).snapshots().map(
            (d) => d.exists ? UserProfile.fromDoc(d) : null,
          );

  // ============ REVIEWS ============
  CollectionReference<Map<String, dynamic>> _reviewsCol(String targetUid) =>
      _users.doc(targetUid).collection('reviews');

  Future<void> addReview(String targetUid, Review review) =>
      _reviewsCol(targetUid).add(review.toMap());

  Stream<List<Review>> watchReviews(String targetUid) =>
      _reviewsCol(targetUid).snapshots().map((s) {
        final list = s.docs.map(Review.fromDoc).toList();
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return list;
      });

  /// คะแนนเฉลี่ย (realtime)
  Stream<double> watchAverageRating(String uid) =>
      watchReviews(uid).map((reviews) {
        if (reviews.isEmpty) return 0;
        final sum = reviews.fold<double>(0, (a, r) => a + r.rating);
        return sum / reviews.length;
      });
}
