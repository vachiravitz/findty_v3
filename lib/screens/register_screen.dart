import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../constants.dart';
import '../models/user_profile_model.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _onRegister() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      // 1. สร้าง auth user (Firebase auto-login ให้ทันทีหลังสร้าง)
      final cred = await AuthService.instance.register(
        _emailController.text.trim(),
        _passwordController.text,
      );
      final uid = cred.user!.uid;

      // 2. สร้าง profile doc ใน Firestore
      final profile = UserProfile.fresh(
        uid: uid,
        username: _nameController.text.trim(),
        email: _emailController.text.trim(),
      );
      await UserService.instance.createOrUpdateProfile(profile);

      // 3. signOut ออก — เพื่อบังคับให้ user login เอง
      // (ถ้าไม่ signOut, authStateChanges จะ trigger ให้ home เป็น GameSelection
      //  แล้วถ้า user กดย้อนกลับจะเข้าแอปทันทีโดยไม่ผ่านหน้า login)
      await AuthService.instance.signOut();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('สมัครสมาชิกสำเร็จ! กรุณาเข้าสู่ระบบ'),
            backgroundColor: Colors.green),
      );
      // 4. กลับไปหน้า login
      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('สมัครไม่ได้: ${e.message ?? e.code}'),
            backgroundColor: Colors.red),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('เกิดข้อผิดพลาด: $e'),
            backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
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
        title: const Text('Create Account',
            style: TextStyle(color: textMain, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const SizedBox(height: 20),
              _buildField(
                controller: _nameController,
                hint: 'Profile Name',
                icon: Icons.person,
                validator: (v) =>
                (v == null || v.isEmpty) ? 'กรุณากรอกชื่อโปรไฟล์' : null,
              ),
              _buildField(
                controller: _emailController,
                hint: 'Email',
                icon: Icons.email,
                keyboard: TextInputType.emailAddress,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'กรุณากรอกอีเมล';
                  if (!v.contains('@')) return 'อีเมลไม่ถูกต้อง';
                  return null;
                },
              ),
              _buildField(
                controller: _passwordController,
                hint: 'Password',
                icon: Icons.lock,
                isPassword: true,
                validator: (v) => (v == null || v.length < 6)
                    ? 'รหัสต้องมี 6 ตัวอักษรขึ้นไป'
                    : null,
              ),
              _buildField(
                controller: _confirmController,
                hint: 'Confirm Password',
                icon: Icons.lock_outline,
                isPassword: true,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'กรุณายืนยันรหัสผ่าน';
                  if (v != _passwordController.text) return 'รหัสผ่านไม่ตรงกัน';
                  return null;
                },
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: deepPink,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15)),
                  ),
                  onPressed: _loading ? null : _onRegister,
                  child: _loading
                      ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.5))
                      : const Text('Register',
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

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required String? Function(String?) validator,
    bool isPassword = false,
    TextInputType? keyboard,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword,
        keyboardType: keyboard,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon, color: deepPink),
          filled: true,
          fillColor: primaryPink.withValues(alpha: 0.5),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide.none),
        ),
        validator: validator,
      ),
    );
  }
}