import 'package:flutter/material.dart';
import '../constants.dart';
import '../config/game_config.dart';
import '../models/party_model.dart';
import '../services/party_service.dart';
import 'create_party_screen.dart';
import 'party_detail_screen.dart';

class PartyFeedScreen extends StatelessWidget {
  final GameConfig game;
  const PartyFeedScreen({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text('Find Party: ${game.displayName}',
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: deepPink,
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: deepPink,
        child: const Icon(Icons.add, color: Colors.white, size: 30),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => CreatePartyScreen(game: game)),
        ),
      ),
      body: StreamBuilder<List<PartyModel>>(
        stream: PartyService.instance.watchParties(game.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _buildError(snapshot.error.toString());
          }
          final parties = snapshot.data ?? [];
          if (parties.isEmpty) {
            return ListView(
              children: const [
                SizedBox(height: 200),
                Center(child: Text('ยังไม่มีปาร์ตี้ในขณะนี้')),
              ],
            );
          }
          return ListView.builder(
            itemCount: parties.length,
            itemBuilder: (context, index) =>
                _PartyCard(party: parties[index]),
          );
        },
      ),
    );
  }

  Widget _buildError(String msg) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: deepPink),
            const SizedBox(height: 12),
            const Text('โหลดข้อมูลไม่ได้',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(msg,
                textAlign: TextAlign.center,
                style: const TextStyle(color: textSub, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _PartyCard extends StatelessWidget {
  final PartyModel party;
  const _PartyCard({required this.party});

  @override
  Widget build(BuildContext context) {
    final leadAvatar = party.leadAvatar.isNotEmpty
        ? party.leadAvatar
        : 'https://i.pravatar.cc/150?u=${party.ownerId}';

    return GestureDetector(
      // กด card -> ไปหน้า detail (ดูสมาชิก + chat)
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => PartyDetailScreen(party: party)),
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4))
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundImage: NetworkImage(leadAvatar),
                    backgroundColor: primaryPink,
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(party.title,
                            style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis),
                        Text('โดย ${party.ownerName}',
                            style: const TextStyle(
                                color: textSub, fontSize: 12)),
                        if (party.rank != null && party.rank!.isNotEmpty)
                          Text(party.rank!,
                              style: const TextStyle(
                                  color: Colors.grey, fontSize: 14)),
                        if (party.role != null && party.role!.isNotEmpty)
                          Text('ตำแหน่งที่ขาด: ${party.role}',
                              style: const TextStyle(
                                  color: deepPink,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (party.max != null)
              Text('${party.current}/${party.max}',
                  style: const TextStyle(
                      color: deepPink,
                      fontSize: 18,
                      fontWeight: FontWeight.w900))
            else
              const Icon(Icons.all_inclusive, color: deepPink, size: 22),
          ],
        ),
      ),
    );
  }
}
