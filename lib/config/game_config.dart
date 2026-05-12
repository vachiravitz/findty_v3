import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// คลาสกลางอธิบาย "หน้าตา" ของเกมแต่ละเกมในแอปนี้
class GameConfig {
  final String id;
  final String displayName;

  /// ไอคอน fallback ของ Material (ใช้กรณีไม่มี iconUrl หรือโหลดรูปไม่ได้)
  final IconData icon;

  /// URL ของรูป icon เกมที่เก็บอยู่บน Firebase Storage หรือเว็บอื่นๆ
  final String? iconUrl;

  final String category;

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
    this.iconUrl,
    this.category = 'General',
    this.hasRank = true,
    this.ranks = const ['Any Rank'],
    this.hasRole = false,
    this.roles = const [],
    this.allowMultiRole = false,
    this.maxPartySize,
    this.memberLabel = 'คน',
  });

  bool get hasMemberLimit => maxPartySize != null;

  /// ฟังก์ชันแปลงข้อมูลจาก Firestore Document ให้กลายเป็น Object GameConfig
  factory GameConfig.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return GameConfig(
      id: doc.id,
      displayName: (d['displayName'] ?? 'Unknown') as String,
      icon: Icons.sports_esports, // ไอคอนสำรองกรณีไม่มีรูป
      iconUrl: d['iconUrl'] as String?, // ดึง URL จาก Firebase แทน
      hasRank: (d['hasRank'] ?? false) as bool,
      ranks: List<String>.from(d['ranks'] ?? const []),

      category: (d['category'] ?? 'General') as String,

      hasRole: (d['hasRole'] ?? false) as bool,
      roles: List<String>.from(d['roles'] ?? const []),
      allowMultiRole: (d['allowMultiRole'] ?? false) as bool,
      maxPartySize: d['maxPartySize'] as int?,
      memberLabel: (d['memberLabel'] ?? 'คน') as String,
    );
  }
}