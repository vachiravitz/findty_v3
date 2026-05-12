import 'package:cloud_firestore/cloud_firestore.dart';
import '../config/game_config.dart';

class GameService {
  GameService._();
  static final instance = GameService._();

  final CollectionReference<Map<String, dynamic>> _games =
  FirebaseFirestore.instance.collection('games');

  /// ดึงข้อมูลเกมทั้งหมดมาแสดงในหน้า Selection
  Future<List<GameConfig>> getAllGames() async {
    final snapshot = await _games.get();
    return snapshot.docs.map((doc) => GameConfig.fromDoc(doc)).toList();
  }

  /// ดึงข้อมูลเกมแบบ Real-time (ถ้ามีการเพิ่มเกมในหลังบ้าน แอปจะเปลี่ยนทันที)
  Stream<List<GameConfig>> watchAllGames() {
    return _games.snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => GameConfig.fromDoc(doc)).toList());
  }

  /// ดึงข้อมูลเกมรายตัวตาม ID (เอาไว้ใช้ในหน้า Party Detail)
  Future<GameConfig?> getGameById(String gameId) async {
    final doc = await _games.doc(gameId).get();
    if (!doc.exists) return null;
    return GameConfig.fromDoc(doc);
  }
}