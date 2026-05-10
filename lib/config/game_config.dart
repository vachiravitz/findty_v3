import 'package:flutter/material.dart';

/// คลาสกลางอธิบาย "หน้าตา" ของเกมแต่ละเกมในแอปนี้
class GameConfig {
  final String id;
  final String displayName;

  /// ไอคอน fallback ของ Material (ใช้กรณีไม่มี iconAsset หรือโหลดรูปไม่ได้)
  final IconData icon;

  /// path ของรูป icon เกม ใน assets/ (เช่น 'assets/games/valorant.png')
  /// ถ้าใส่ค่านี้ -> UI จะใช้รูปแทน Material icon
  /// ต้องเพิ่ม path ใน pubspec.yaml ส่วน flutter -> assets ด้วย
  final String? iconAsset;

  final bool hasRank;
  final List<String> ranks;

  final bool hasRole;
  final List<String> roles;

  /// เกมนี้อนุญาตให้เลือกตำแหน่งได้หลายอันหรือไม่?
  final bool allowMultiRole;

  final int? maxPartySize;
  final String memberLabel;

  const GameConfig({
    required this.id,
    required this.displayName,
    required this.icon,
    this.iconAsset,
    this.hasRank = true,
    this.ranks = const ['Any Rank'],
    this.hasRole = false,
    this.roles = const [],
    this.allowMultiRole = false,
    this.maxPartySize,
    this.memberLabel = 'คน',
  });

  bool get hasMemberLimit => maxPartySize != null;
}

/// Registry รวมเกมที่แอปรองรับทั้งหมด
class GameRegistry {
  GameRegistry._();

  static const List<GameConfig> all = [
    GameConfig(
      id: 'valorant',
      displayName: 'Valorant',
      icon: Icons.gps_fixed,
      iconAsset: 'assets/games/valorant.png',
      hasRank: true,
      ranks: [
        'Any Rank',
        'Iron / Bronze',
        'Silver / Gold',
        'Platinum / Diamond',
        'Ascendant+',
      ],
      hasRole: true,
      allowMultiRole: true,
      roles: ['Duelist', 'Controller', 'Initiator', 'Sentinel'],
      maxPartySize: 5,
    ),
    GameConfig(
      id: 'cs2',
      displayName: 'CS2',
      icon: Icons.sports_esports,
      iconAsset: 'assets/games/cs2.png',
      hasRank: true,
      ranks: [
        'Any Rank',
        'Silver',
        'Gold Nova',
        'Master Guardian',
        'Legendary Eagle',
        'Global Elite',
      ],
      hasRole: false,
      maxPartySize: 5,
    ),
    GameConfig(
      id: 'rov',
      displayName: 'ROV',
      icon: Icons.shield,
      iconAsset: 'assets/games/rov.png',
      hasRank: true,
      ranks: [
        'Any Rank',
        'Bronze / Silver',
        'Gold / Platinum',
        'Diamond / Commander',
        'Conqueror',
      ],
      hasRole: true,
      roles: ['Carry', 'Mage', 'Fighter', 'Support', 'Assassin', 'Tank'],
      maxPartySize: 5,
    ),
    GameConfig(
      id: 'minecraft',
      displayName: 'Minecraft',
      icon: Icons.grid_view,
      iconAsset: 'assets/games/minecraft.png',
      hasRank: false,
      hasRole: false,
      maxPartySize: null,
      memberLabel: 'ผู้เล่น',
    ),
  ];

  static GameConfig? byId(String id) {
    for (final g in all) {
      if (g.id == id) return g;
    }
    return null;
  }

  static GameConfig? byName(String name) {
    for (final g in all) {
      if (g.displayName == name) return g;
    }
    return null;
  }
}