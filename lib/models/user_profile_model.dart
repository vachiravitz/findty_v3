import 'package:cloud_firestore/cloud_firestore.dart';

/// Profile ของ user (เก็บใน collection 'users' ที่ doc id = uid)
class UserProfile {
  final String uid;
  final String username;
  final String email;
  final String avatarUrl;
  final String discordTag;
  final String steamId;
  final String tagline; // คำอธิบายตัวเอง เช่น "Professional Duelist"
  final List<String> traits; // tag การเล่น เช่น ['Aggressive', 'Friendly']
  final DateTime createdAt;

  UserProfile({
    required this.uid,
    required this.username,
    required this.email,
    required this.avatarUrl,
    required this.discordTag,
    required this.steamId,
    required this.tagline,
    required this.traits,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'username': username,
        'email': email,
        'avatarUrl': avatarUrl,
        'discordTag': discordTag,
        'steamId': steamId,
        'tagline': tagline,
        'traits': traits,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  factory UserProfile.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return UserProfile(
      uid: doc.id,
      username: (d['username'] ?? 'Unknown') as String,
      email: (d['email'] ?? '') as String,
      avatarUrl: (d['avatarUrl'] ?? 'https://i.pravatar.cc/300?u=${doc.id}')
          as String,
      discordTag: (d['discordTag'] ?? '') as String,
      steamId: (d['steamId'] ?? '') as String,
      tagline: (d['tagline'] ?? '') as String,
      traits: List<String>.from(d['traits'] ?? const []),
      createdAt: (d['createdAt'] is Timestamp)
          ? (d['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  UserProfile copyWith({
    String? username,
    String? avatarUrl,
    String? discordTag,
    String? steamId,
    String? tagline,
    List<String>? traits,
  }) =>
      UserProfile(
        uid: uid,
        email: email,
        createdAt: createdAt,
        username: username ?? this.username,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        discordTag: discordTag ?? this.discordTag,
        steamId: steamId ?? this.steamId,
        tagline: tagline ?? this.tagline,
        traits: traits ?? this.traits,
      );

  /// profile เปล่าๆ สำหรับ user ที่เพิ่ง register
  factory UserProfile.fresh({
    required String uid,
    required String username,
    required String email,
  }) =>
      UserProfile(
        uid: uid,
        username: username,
        email: email,
        avatarUrl: 'https://i.pravatar.cc/300?u=$uid',
        discordTag: '',
        steamId: '',
        tagline: 'New Player',
        traits: const [],
        createdAt: DateTime.now(),
      );
}
