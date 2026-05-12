import 'package:flutter/material.dart';
import '../constants.dart';
import '../config/game_config.dart';
import '../models/message_model.dart';
import '../models/party_model.dart';
import '../models/user_profile_model.dart';
import '../services/auth_service.dart';
import '../services/chat_service.dart';
import '../services/party_service.dart';
import '../services/user_service.dart';
import '../services/game_service.dart'; // เพิ่ม import นี้
import 'profile_screen.dart';

class PartyDetailScreen extends StatefulWidget {
  final PartyModel party;
  const PartyDetailScreen({super.key, required this.party});

  @override
  State<PartyDetailScreen> createState() => _PartyDetailScreenState();
}

class _PartyDetailScreenState extends State<PartyDetailScreen> {
  final _msgController = TextEditingController();
  final _scrollController = ScrollController();
  bool _sending = false;
  bool _joining = false;
  bool _deleting = false;

  // เพิ่มตัวแปรสำหรับเก็บข้อมูลเกม
  GameConfig? _game;

  @override
  void initState() {
    super.initState();
    _loadGameInfo(); // โหลดข้อมูลเกมเมื่อเข้าหน้าจอ
  }

  // ฟังก์ชันโหลดข้อมูลเกมจาก Firestore
  Future<void> _loadGameInfo() async {
    final g = await GameService.instance.getGameById(widget.party.gameId);
    if (mounted) {
      setState(() => _game = g);
    }
  }

  @override
  void dispose() {
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send(PartyModel party) async {
    final text = _msgController.text.trim();
    if (text.isEmpty || party.id == null) return;
    final myUid = AuthService.instance.currentUid;
    if (myUid == null) return;

    setState(() => _sending = true);
    try {
      final me = await UserService.instance.getProfile(myUid);
      final msg = Message(
        senderId: myUid,
        senderName: me?.username ?? 'Anon',
        senderAvatar: me?.avatarUrl ?? '',
        text: text,
        createdAt: DateTime.now(),
      );
      await ChatService.instance.sendMessage(party.id!, msg);
      _msgController.clear();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
      });
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _joinParty(PartyModel party) async {
    final uid = AuthService.instance.currentUid;
    if (uid == null || party.id == null) return;
    setState(() => _joining = true);
    try {
      await PartyService.instance.joinParty(party.id!, uid);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('เข้าร่วมตี้สำเร็จ!'),
            backgroundColor: Colors.green),
      );
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().replaceFirst('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _joining = false);
    }
  }

  Future<void> _leaveParty(PartyModel party) async {
    final uid = AuthService.instance.currentUid;
    if (uid == null || party.id == null) return;
    setState(() => _joining = true);
    try {
      await PartyService.instance.leaveParty(party.id!, uid);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ออกจากตี้แล้ว')),
      );
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().replaceFirst('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _joining = false);
    }
  }

  Future<void> _confirmAndDelete() async {
    if (widget.party.id == null) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ลบปาร์ตี้'),
        content: const Text(
            'การลบจะลบข้อความ chat ในตี้ทั้งหมดด้วย'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('ยกเลิก',
                style: TextStyle(color: textSub)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('ลบเลย',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (ok != true || !mounted) return;

    setState(() => _deleting = true);
    try {
      await PartyService.instance.deleteParty(widget.party.id!);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('ลบตี้เรียบร้อย'),
            backgroundColor: Colors.green),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('ลบไม่ได้: $e'),
            backgroundColor: Colors.red),
      );
      setState(() => _deleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final partyId = widget.party.id;
    if (partyId == null) {
      return const Scaffold(
          body: Center(child: Text('party id ไม่ถูกต้อง')));
    }

    final isOwner =
        AuthService.instance.currentUid == widget.party.ownerId;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(widget.party.title,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: deepPink,
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
        actions: [
          if (isOwner)
            IconButton(
              icon: _deleting
                  ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.delete_outline, color: Colors.white),
              tooltip: 'ลบตี้',
              onPressed: _deleting ? null : _confirmAndDelete,
            ),
        ],
      ),
      body: StreamBuilder<PartyModel?>(
        stream: PartyService.instance.watchParty(partyId),
        initialData: widget.party,
        builder: (context, snap) {
          final party = snap.data ?? widget.party;
          final myUid = AuthService.instance.currentUid;

          return Column(
            children: [
              _buildHeaderCard(context, party, _game, myUid),
              _buildJoinSection(party, myUid),
              const Divider(height: 1),
              Expanded(child: _buildChatList(party, myUid)),
              _buildInputBar(party),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeaderCard(BuildContext context, PartyModel party,
      GameConfig? game, String? myUid) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // ปรับการแสดงผล icon: ถ้ามี iconUrl ให้โชว์รูปจากเน็ต ถ้าไม่มีโชว์ icon fallback
              if (game != null)
                game.iconUrl != null && game.iconUrl!.isNotEmpty
                    ? Image.network(game.iconUrl!, width: 20, height: 20)
                    : Icon(game.icon, size: 20, color: deepPink),
              const SizedBox(width: 6),
              Text(game?.displayName ?? party.gameId,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const Spacer(),
              if (party.max != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: primaryPink,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text('${party.current}/${party.max}',
                      style: const TextStyle(
                          color: deepPink, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
          if (party.rank != null && party.rank!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('Rank: ${party.rank}',
                  style: const TextStyle(color: textSub, fontSize: 13)),
            ),
          if (party.role != null && party.role!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text('ตำแหน่งที่ขาด: ${party.role}',
                  style: const TextStyle(
                      color: deepPink,
                      fontSize: 13,
                      fontWeight: FontWeight.w500)),
            ),
          const Divider(height: 20),
          const Text('สมาชิก',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _buildMembersRow(context, party),
        ],
      ),
    );
  }

  Widget _buildMembersRow(BuildContext context, PartyModel party) {
    final emptySlots = party.max == null
        ? 0
        : (party.max! - party.memberIds.length).clamp(0, party.max!);

    return SizedBox(
      height: 80,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (var i = 0; i < party.memberIds.length; i++)
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: _MemberChip(
                uid: party.memberIds[i],
                isOwner: party.memberIds[i] == party.ownerId,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          ProfileScreen(uid: party.memberIds[i])),
                ),
              ),
            ),
          for (var i = 0; i < emptySlots; i++)
            const Padding(
              padding: EdgeInsets.only(right: 10),
              child: _EmptySlot(),
            ),
        ],
      ),
    );
  }

  Widget _buildJoinSection(PartyModel party, String? myUid) {
    if (myUid == null) return const SizedBox.shrink();

    final isOwner = party.ownerId == myUid;
    final isMember = party.isMember(myUid);
    final isFull = party.isFull();

    String label;
    Color color;
    VoidCallback? onPressed;
    IconData icon;

    if (isOwner) {
      label = 'คุณคือหัวตี้';
      color = Colors.grey;
      onPressed = null;
      icon = Icons.workspace_premium;
    } else if (isMember) {
      label = 'ออกจากตี้';
      color = Colors.orange;
      onPressed = _joining ? null : () => _leaveParty(party);
      icon = Icons.exit_to_app;
    } else if (isFull) {
      label = 'ตี้เต็มแล้ว';
      color = Colors.grey;
      onPressed = null;
      icon = Icons.block;
    } else {
      label = 'เข้าร่วมตี้';
      color = deepPink;
      onPressed = _joining ? null : () => _joinParty(party);
      icon = Icons.login;
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: SizedBox(
        width: double.infinity,
        height: 48,
        child: ElevatedButton.icon(
          icon: _joining
              ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                  color: Colors.white, strokeWidth: 2))
              : Icon(icon, color: Colors.white, size: 18),
          label: Text(label,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15)),
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            disabledBackgroundColor: color.withValues(alpha: 0.6),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: onPressed,
        ),
      ),
    );
  }

  Widget _buildChatList(PartyModel party, String? myUid) {
    return StreamBuilder<List<Message>>(
      stream: ChatService.instance.watchMessages(party.id ?? ''),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final messages = snap.data!;
        if (messages.isEmpty) {
          return const Center(
            child: Text('ยังไม่มีข้อความ — เริ่มแชทกันเลย!',
                style: TextStyle(color: textSub)),
          );
        }
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController
                .jumpTo(_scrollController.position.maxScrollExtent);
          }
        });
        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.all(12),
          itemCount: messages.length,
          itemBuilder: (ctx, i) =>
              _buildMessageRow(ctx, messages[i], myUid),
        );
      },
    );
  }

  Widget _buildMessageRow(BuildContext ctx, Message m, String? myUid) {
    final isMe = m.senderId == myUid;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment:
        isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isMe) ...[
            GestureDetector(
              onTap: () => Navigator.push(
                ctx,
                MaterialPageRoute(
                    builder: (_) => ProfileScreen(uid: m.senderId)),
              ),
              child: CircleAvatar(
                radius: 16,
                backgroundColor: primaryPink,
                backgroundImage: m.senderAvatar.isNotEmpty
                    ? NetworkImage(m.senderAvatar)
                    : null,
                child: m.senderAvatar.isEmpty
                    ? const Icon(Icons.person, size: 16, color: deepPink)
                    : null,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(ctx).size.width * 0.7),
              padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isMe ? deepPink : Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isMe)
                    Text(m.senderName,
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: deepPink)),
                  Text(m.text,
                      style: TextStyle(
                          color: isMe ? Colors.white : textMain,
                          fontSize: 14)),
                ],
              ),
            ),
          ),
          if (isMe) const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildInputBar(PartyModel party) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 6,
              offset: const Offset(0, -2)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _msgController,
                onSubmitted: (_) => _send(party),
                decoration: InputDecoration(
                  hintText: 'พิมพ์ข้อความ...',
                  filled: true,
                  fillColor: primaryPink.withValues(alpha: 0.4),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none),
                ),
              ),
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 22,
              backgroundColor: deepPink,
              child: IconButton(
                icon: _sending
                    ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.send,
                    color: Colors.white, size: 18),
                onPressed: _sending ? null : () => _send(party),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MemberChip extends StatelessWidget {
  final String uid;
  final bool isOwner;
  final VoidCallback onTap;
  const _MemberChip(
      {required this.uid, required this.isOwner, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserProfile?>(
      future: UserService.instance.getProfile(uid),
      builder: (context, snap) {
        final profile = snap.data;
        final avatar = profile?.avatarUrl ?? '';
        final name = profile?.username ?? '...';
        return GestureDetector(
          onTap: onTap,
          child: Column(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: primaryPink,
                    backgroundImage:
                    avatar.isNotEmpty ? NetworkImage(avatar) : null,
                    child: avatar.isEmpty
                        ? const Icon(Icons.person, color: deepPink)
                        : null,
                  ),
                  if (isOwner)
                    const Positioned(
                      bottom: -2,
                      right: -2,
                      child: CircleAvatar(
                        radius: 9,
                        backgroundColor: Colors.amber,
                        child: Icon(Icons.star,
                            size: 10, color: Colors.white),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              SizedBox(
                width: 70,
                child: Text(
                  isOwner ? '$name (หัวตี้)' : name,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 10, color: textSub),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _EmptySlot extends StatelessWidget {
  const _EmptySlot();
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.grey[400]!),
          ),
          child: const Icon(Icons.add, color: Colors.grey),
        ),
        const SizedBox(height: 4),
        const SizedBox(
          width: 70,
          child: Text('ที่ว่าง',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 10, color: textSub)),
        ),
      ],
    );
  }
}