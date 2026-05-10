import 'package:flutter/material.dart';
import '../constants.dart';
import '../models/review_model.dart';
import '../models/user_profile_model.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import 'edit_profile_screen.dart';
import 'write_review_screen.dart';

/// หน้า profile
/// - uid == null  -> profile ของฉัน (เห็นปุ่ม Edit)
/// - uid != null  -> profile คนอื่น (เห็นปุ่ม Write Review)
class ProfileScreen extends StatelessWidget {
  final String? uid;
  const ProfileScreen({super.key, this.uid});

  @override
  Widget build(BuildContext context) {
    final myUid = AuthService.instance.currentUid;
    final targetUid = uid ?? myUid;

    if (targetUid == null) {
      return const Scaffold(
        body: Center(child: Text('ไม่พบผู้ใช้')),
      );
    }
    final isMe = targetUid == myUid;

    return Scaffold(
      backgroundColor: bgWhite,
      appBar: AppBar(
        backgroundColor: primaryPink,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: deepPink),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<UserProfile?>(
        stream: UserService.instance.watchProfile(targetUid),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final profile = snap.data;
          if (profile == null) {
            return const Center(child: Text('ไม่พบข้อมูลผู้ใช้'));
          }
          return _buildBody(context, profile, isMe);
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, UserProfile profile, bool isMe) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context, profile, isMe),
          if (profile.discordTag.isNotEmpty || profile.steamId.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.fromLTRB(25, 20, 25, 10),
              child: Text('Social Links',
                  style:
                      TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ),
            if (profile.discordTag.isNotEmpty)
              _socialItem(const Color(0xFF5865F2),
                  'Discord: ${profile.discordTag}'),
            if (profile.steamId.isNotEmpty)
              _socialItem(
                  const Color(0xFF171A21), 'Steam: ${profile.steamId}'),
          ],
          if (profile.traits.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.fromLTRB(25, 20, 25, 10),
              child: Text('Personal Style',
                  style:
                      TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: profile.traits.map(_traitTag).toList(),
              ),
            ),
          ],
          _buildReviewsSection(context, profile, isMe),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, UserProfile profile, bool isMe) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(bottom: 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [primaryPink, bgWhite],
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 130,
            height: 130,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 4),
              image: DecorationImage(
                image: NetworkImage(profile.avatarUrl),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 15),
          Text(profile.username,
              style: const TextStyle(
                  fontSize: 22, fontWeight: FontWeight.bold)),
          if (profile.tagline.isNotEmpty)
            Text(profile.tagline,
                style: const TextStyle(color: textSub, fontSize: 16)),
          const SizedBox(height: 14),
          // ปุ่ม edit / write review
          if (isMe)
            ElevatedButton.icon(
              icon: const Icon(Icons.edit, size: 18),
              label: const Text('แก้ไขโปรไฟล์'),
              style: ElevatedButton.styleFrom(
                backgroundColor: deepPink,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
              ),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => EditProfileScreen(profile: profile)),
              ),
            )
          else
            ElevatedButton.icon(
              icon: const Icon(Icons.star, size: 18),
              label: const Text('Write Review'),
              style: ElevatedButton.styleFrom(
                backgroundColor: deepPink,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
              ),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => WriteReviewScreen(
                    targetUid: profile.uid,
                    targetName: profile.username,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildReviewsSection(
      BuildContext context, UserProfile profile, bool isMe) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(25, 30, 25, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Reviews',
                  style:
                      TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              StreamBuilder<double>(
                stream:
                    UserService.instance.watchAverageRating(profile.uid),
                builder: (context, snap) {
                  final avg = snap.data ?? 0;
                  if (avg == 0) {
                    return const Text('ยังไม่มีรีวิว',
                        style: TextStyle(color: textSub));
                  }
                  return Text('(${avg.toStringAsFixed(1)}/5.0)',
                      style: const TextStyle(
                          color: deepPink, fontWeight: FontWeight.bold));
                },
              ),
            ],
          ),
          const SizedBox(height: 10),
          StreamBuilder<List<Review>>(
            stream: UserService.instance.watchReviews(profile.uid),
            builder: (context, snap) {
              final reviews = snap.data ?? [];
              if (reviews.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Text('ยังไม่มีใครรีวิว',
                      style: TextStyle(color: textSub)),
                );
              }
              return Column(
                children: reviews.map(_reviewItem).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _socialItem(Color color, String text) {
    return Container(
      margin: const EdgeInsets.only(left: 25, right: 25, bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
          color: const Color(0xFFF9F9F9),
          borderRadius: BorderRadius.circular(15)),
      child: Row(
        children: [
          Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                  color: color, borderRadius: BorderRadius.circular(8))),
          const SizedBox(width: 15),
          Expanded(
              child: Text(text,
                  style: const TextStyle(color: textSub, fontSize: 14))),
        ],
      ),
    );
  }

  Widget _traitTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        color: deepPink,
        border: Border.all(color: deepPink, width: 1.5),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Text(text,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.w500)),
    );
  }

  Widget _reviewItem(Review r) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: primaryPink,
                backgroundImage: r.reviewerAvatar.isNotEmpty
                    ? NetworkImage(r.reviewerAvatar)
                    : null,
                child: r.reviewerAvatar.isEmpty
                    ? const Icon(Icons.person, color: deepPink)
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r.reviewerName,
                        style:
                            const TextStyle(fontWeight: FontWeight.bold)),
                    Text(_formatTime(r.createdAt),
                        style: const TextStyle(
                            color: textSub, fontSize: 11)),
                  ],
                ),
              ),
              Row(
                children: List.generate(5, (i) {
                  return Icon(
                    i < r.rating.round() ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 16,
                  );
                }),
              ),
            ],
          ),
          if (r.text.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(r.text,
                style: const TextStyle(fontSize: 14, color: textSub)),
          ],
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'เมื่อสักครู่';
    if (diff.inHours < 1) return '${diff.inMinutes} นาทีที่แล้ว';
    if (diff.inDays < 1) return '${diff.inHours} ชม.ที่แล้ว';
    if (diff.inDays < 7) return '${diff.inDays} วันที่แล้ว';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
