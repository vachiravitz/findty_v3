import 'package:flutter/material.dart';
import '../constants.dart';
import '../models/user_profile_model.dart';
import '../services/user_service.dart';

/// แก้ไขโปรไฟล์ของตัวเอง
///
/// รูปโปรไฟล์ตอนนี้ใช้ "URL paste" — แปะลิงก์รูปก็เปลี่ยนได้ทันที
/// (ถ้าจะอัปโหลดจริง: ดู README หัวข้อ "Image Upload (Optional)")
class EditProfileScreen extends StatefulWidget {
  final UserProfile profile;
  const EditProfileScreen({super.key, required this.profile});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _name;
  late TextEditingController _avatar;
  late TextEditingController _tagline;
  late TextEditingController _discord;
  late TextEditingController _steam;
  late TextEditingController _traits; // comma-separated
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.profile.username);
    _avatar = TextEditingController(text: widget.profile.avatarUrl);
    _tagline = TextEditingController(text: widget.profile.tagline);
    _discord = TextEditingController(text: widget.profile.discordTag);
    _steam = TextEditingController(text: widget.profile.steamId);
    _traits = TextEditingController(text: widget.profile.traits.join(', '));
  }

  @override
  void dispose() {
    _name.dispose();
    _avatar.dispose();
    _tagline.dispose();
    _discord.dispose();
    _steam.dispose();
    _traits.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final traits = _traits.text
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
      final updated = widget.profile.copyWith(
        username: _name.text.trim(),
        avatarUrl: _avatar.text.trim().isEmpty
            ? widget.profile.avatarUrl
            : _avatar.text.trim(),
        tagline: _tagline.text.trim(),
        discordTag: _discord.text.trim(),
        steamId: _steam.text.trim(),
        traits: traits,
      );
      await UserService.instance.createOrUpdateProfile(updated);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('บันทึกสำเร็จ!'),
            backgroundColor: Colors.green),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('บันทึกไม่ได้: $e'),
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
        title: const Text('แก้ไขโปรไฟล์',
            style: TextStyle(color: textMain, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // preview รูป
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: primaryPink, width: 3),
                  image: DecorationImage(
                    image: NetworkImage(_avatar.text.isEmpty
                        ? 'https://i.pravatar.cc/300?u=${widget.profile.uid}'
                        : _avatar.text),
                    fit: BoxFit.cover,
                    onError: (_, __) {},
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _field(
                controller: _avatar,
                label: 'รูปโปรไฟล์ (URL)',
                hint: 'https://i.pravatar.cc/300?u=...',
                icon: Icons.image,
                onChanged: (_) => setState(() {}), // refresh preview
              ),
              _field(
                controller: _name,
                label: 'ชื่อโปรไฟล์',
                icon: Icons.person,
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'กรุณากรอกชื่อ' : null,
              ),
              _field(
                controller: _tagline,
                label: 'Tagline',
                hint: 'เช่น Professional Duelist',
                icon: Icons.star,
              ),
              _field(
                controller: _discord,
                label: 'Discord',
                hint: 'username#1234',
                icon: Icons.discord,
              ),
              _field(
                controller: _steam,
                label: 'Steam',
                hint: 'steamcommunity.com/id/...',
                icon: Icons.videogame_asset,
              ),
              _field(
                controller: _traits,
                label: 'Personal Style (คั่นด้วย ,)',
                hint: 'เช่น Aggressive, Friendly, Tactical',
                icon: Icons.tag,
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
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2.5))
                      : const Text('บันทึก',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    String? hint,
    required IconData icon,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        controller: controller,
        validator: validator,
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, color: deepPink),
          filled: true,
          fillColor: primaryPink.withValues(alpha: 0.5),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide.none),
        ),
      ),
    );
  }
}
