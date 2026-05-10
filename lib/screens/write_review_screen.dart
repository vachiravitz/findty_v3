import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

import '../constants.dart';
import '../models/review_model.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';

class WriteReviewScreen extends StatefulWidget {
  final String targetUid;
  final String targetName;
  const WriteReviewScreen(
      {super.key, required this.targetUid, required this.targetName});

  @override
  State<WriteReviewScreen> createState() => _WriteReviewScreenState();
}

class _WriteReviewScreenState extends State<WriteReviewScreen> {
  double _rating = 5;
  final _textController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาเขียนรีวิว')),
      );
      return;
    }
    final myUid = AuthService.instance.currentUid;
    if (myUid == null) return;

    if (myUid == widget.targetUid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('รีวิวตัวเองไม่ได้นะ')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      // โหลด profile ของ reviewer (ตัวเอง) เพื่อ snapshot ชื่อ+รูป
      final me = await UserService.instance.getProfile(myUid);
      final review = Review(
        reviewerUid: myUid,
        reviewerName: me?.username ?? 'Anonymous',
        reviewerAvatar: me?.avatarUrl ?? '',
        rating: _rating,
        text: text,
        createdAt: DateTime.now(),
      );
      await UserService.instance.addReview(widget.targetUid, review);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('ส่งรีวิวสำเร็จ!'),
            backgroundColor: Colors.green),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('ส่งไม่สำเร็จ: $e'),
            backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgWhite,
      appBar: AppBar(
        backgroundColor: bgWhite,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: deepPink),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Write Review',
            style: TextStyle(color: textMain, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Text('ให้คะแนน ${widget.targetName}',
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 20),
            RatingBar.builder(
              initialRating: _rating,
              minRating: 1,
              direction: Axis.horizontal,
              allowHalfRating: true,
              itemCount: 5,
              itemSize: 44,
              itemPadding:
                  const EdgeInsets.symmetric(horizontal: 4),
              itemBuilder: (context, _) =>
                  const Icon(Icons.star, color: Colors.amber),
              onRatingUpdate: (r) => setState(() => _rating = r),
            ),
            const SizedBox(height: 8),
            Text('${_rating.toStringAsFixed(1)} / 5.0',
                style: const TextStyle(color: deepPink, fontSize: 16)),
            const SizedBox(height: 25),
            TextField(
              controller: _textController,
              maxLines: 5,
              maxLength: 500,
              decoration: InputDecoration(
                hintText: 'เล่าประสบการณ์การเล่นด้วยกัน...',
                filled: true,
                fillColor: primaryPink.withValues(alpha: 0.4),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: deepPink,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15)),
                ),
                onPressed: _saving ? null : _submit,
                child: _saving
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.5))
                    : const Text('Submit Review',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
