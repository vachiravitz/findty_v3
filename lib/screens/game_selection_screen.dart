import 'package:flutter/material.dart';
import '../constants.dart';
import '../config/game_config.dart';
import '../models/user_profile_model.dart';
import '../services/auth_service.dart';
import '../services/party_service.dart';
import '../services/user_service.dart';
import '../services/game_service.dart';
import 'party_feed_screen.dart';
import 'profile_screen.dart';

class GameSelectionScreen extends StatefulWidget {
  const GameSelectionScreen({super.key});

  @override
  State<GameSelectionScreen> createState() => _GameSelectionScreenState();
}

class _GameSelectionScreenState extends State<GameSelectionScreen> {
  String _searchQuery = '';
  String _selectedCategory = 'All'; // เก็บค่า category ที่กำลังเลือก
  final TextEditingController _searchController = TextEditingController();

  // รายการหมวดหมู่ทั้งหมดสำหรับทำปุ่ม Filter
  final List<String> _categories = ['All', 'FPS', 'MOBA', 'Battle Royale', 'MMORPG'];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
          if (myUid != null)
            StreamBuilder<UserProfile?>(
              stream: UserService.instance.watchProfile(myUid),
              builder: (context, snap) {
                final avatarUrl = snap.data?.avatarUrl ?? '';
                return GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ProfileScreen()),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: primaryPink,
                      backgroundImage: avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
                      child: avatarUrl.isEmpty
                          ? const Icon(Icons.person, color: deepPink, size: 20)
                          : null,
                    ),
                  ),
                );
              },
            ),
          IconButton(
            icon: const Icon(Icons.logout, color: deepPink),
            tooltip: 'ออกจากระบบ',
            onPressed: () => AuthService.instance.signOut(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'ค้นหาเกม...',
                prefixIcon: const Icon(Icons.search, color: deepPink),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.grey),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
                    : null,
                filled: true,
                fillColor: primaryPink.withValues(alpha: 0.3),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // 2. Filter Category Chips
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = _selectedCategory == category;

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(category),
                    selected: isSelected,
                    selectedColor: deepPink,
                    backgroundColor: Colors.grey[200],
                    showCheckmark: false,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : textMain,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(color: isSelected ? deepPink : Colors.transparent),
                    ),
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _selectedCategory = category);
                      }
                    },
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 15),

          // 3. GridView แสดงรายชื่อเกม
          Expanded(
            child: StreamBuilder<List<GameConfig>>(
              stream: GameService.instance.watchAllGames(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return const Center(child: Text('เกิดข้อผิดพลาดในการโหลดข้อมูลเกม'));
                }

                final allGames = snapshot.data ?? [];

                // กรองเกมจาก Search Query และ Category พร้อมกัน
                final filteredGames = allGames.where((game) {
                  final matchSearch = game.displayName
                      .toLowerCase()
                      .contains(_searchQuery.toLowerCase());

                  final matchCategory = _selectedCategory == 'All' ||
                      game.category.toLowerCase() == _selectedCategory.toLowerCase();

                  return matchSearch && matchCategory;
                }).toList();

                if (allGames.isEmpty) {
                  return const Center(child: Text('ยังไม่มีเกมที่เปิดให้บริการ'));
                }

                if (filteredGames.isEmpty) {
                  return Center(
                    child: Text('ไม่พบเกมในหมวดหมู่นี้', style: const TextStyle(color: textSub)),
                  );
                }

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1,
                    ),
                    itemCount: filteredGames.length,
                    itemBuilder: (context, index) =>
                        _GameCard(game: filteredGames[index]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _GameCard extends StatelessWidget {
  final GameConfig game;
  const _GameCard({required this.game});

  Widget _buildIcon(double size) {
    if (game.iconUrl != null && game.iconUrl!.isNotEmpty) {
      return Image.network(
        game.iconUrl!,
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
                      style: const TextStyle(color: Colors.white, fontSize: 12),
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
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(15)),
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