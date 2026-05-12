import 'package:firebase_auth/firebase_auth.dart';


/// service ห่อ FirebaseAuth ให้เรียกใช้ง่าย
class AuthService {
  AuthService._();
  static final instance = AuthService._();

  FirebaseAuth get _auth => FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;
  String? get currentUid => _auth.currentUser?.uid;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  Future<UserCredential> signIn(String email, String password) =>
      _auth.signInWithEmailAndPassword(email: email, password: password);

  Future<UserCredential> register(String email, String password) =>
      _auth.createUserWithEmailAndPassword(email: email, password: password);

  Future<void> signOut() => _auth.signOut();

  Future<void> changePassword(String currentPassword, String newPassword) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('ผู้ใช้ยังไม่ได้เข้าสู่ระบบ');
    if (user.email == null) throw Exception('ไม่พบอีเมลของผู้ใช้');

    try {
      // 1. ยืนยันตัวตนด้วยรหัสผ่านเดิมก่อน
      final cred = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(cred);

      // 2. ทำการอัปเดตรหัสผ่านใหม่
      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password') {
        throw Exception('รหัสผ่านปัจจุบันไม่ถูกต้อง');
      } else if (e.code == 'weak-password') {
        throw Exception('รหัสผ่านใหม่ต้องมีอย่างน้อย 6 ตัวอักษร');
      } else {
        throw Exception(e.message ?? 'เกิดข้อผิดพลาดในการเปลี่ยนรหัสผ่าน');
      }
    }
  }
}
