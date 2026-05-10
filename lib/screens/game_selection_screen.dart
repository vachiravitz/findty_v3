import 'package:flutter/material.dart';
import '../constants.dart';
import '../config/game_config.dart';
import '../models/user_profile_model.dart';
import '../services/auth_service.dart';
import '../services/party_service.dart';
import '../services/user_service.dart';
import 'party_feed_screen.dart';
import 'profile_screen.dart';

class GameSelectionScreen extends StatelessWidget {
  const GameSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final games = GameRegistry.all;
    final myUid = AuthService.instance.currentUid;

    return Scaffold(
      backgroundColor: bgWhite,
      appBar: AppBar(
        title: const Text('Select Game',
            style: TextStyle(color: textMain, fontWeight: FontWeight.bold)),
        backgroundColor: bgWhite,
        elevation: 0,
        centerTitle: true,
        actions: [
          // ปุ่ม profile -> โชว์รูป avatar จริงของ user แทน icon ธรรมดา
          if (myUid != null)
            StreamBuilder<UserProfile?>(
              stream: UserService.instance.watchProfile(myUid),
              builder: (context, snap) {
                final avatarUrl = snap.data?.avatarUrl ?? '';
                return GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const ProfileScreen()),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 8),
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: primaryPink,
                      // ถ้ามี url -> ใช้ NetworkImage
                      // ถ้ายังไม่โหลด/ไม่มี -> โชว์ icon คนแทน
                      backgroundImage: avatarUrl.isNotEmpty
                          ? NetworkImage(avatarUrl)
                          : null,
                      onBackgroundImageError: avatarUrl.isNotEmpty
                          ? (_, __) {} // กัน crash ถ้าโหลด url ไม่ได้
                          : null,
                      child: avatarUrl.isEmpty
                          ? const Icon(Icons.person,
                          color: deepPink, size: 20)
                          : null,
                    ),
                  ),
                );
              },
            ),
          // ปุ่ม logout
          IconButton(
            icon: const Icon(Icons.logout, color: deepPink),
            tooltip: 'ออกจากระบบ',
            onPressed: () => AuthService.instance.signOut(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1,
          ),
          itemCount: games.length,
          itemBuilder: (context, index) => _GameCard(game: games[index]),
        ),
      ),
    );
  }
}

class _GameCard extends StatelessWidget {
  final GameConfig game;
  const _GameCard({required this.game});

  Widget _buildIcon(double size) {
    if (game.iconAsset != null && game.iconAsset!.isNotEmpty) {
      return Image.asset(
        game.iconAsset!,
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return Icon(game.icon, size: size, color: deepPink);
        },
      );
    }
    return Icon(game.icon, size: size, color: deepPink);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => PartyFeedScreen(game: game)),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(15),
        ),
        child: Stack(
          children: [
            Center(child: _buildIcon(72)),
            Positioned(
              top: 10,
              right: 10,
              child: StreamBuilder<int>(
                stream: PartyService.instance.watchPartyCount(game.id),
                builder: (context, snap) {
                  return CircleAvatar(
                    radius: 12,
                    backgroundColor: deepPink,
                    child: Text(
                      '${snap.data ?? 0}',
                      style: const TextStyle(
                          color: Colors.white, fontSize: 12),
                    ),
                  );
                },
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                  BorderRadius.vertical(bottom: Radius.circular(15)),
                ),
                child: Text(game.displayName,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}