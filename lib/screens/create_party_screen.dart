import 'package:flutter/material.dart';

import '../constants.dart';
import '../config/game_config.dart';
import '../models/party_model.dart';
import '../services/auth_service.dart';
import '../services/party_service.dart';
import '../services/user_service.dart';

class CreatePartyScreen extends StatefulWidget {
  final GameConfig game;
  const CreatePartyScreen({super.key, required this.game});

  @override
  State<CreatePartyScreen> createState() => _CreatePartyScreenState();
}

class _CreatePartyScreenState extends State<CreatePartyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _roomNameController = TextEditingController();

  String? selectedRank;
  String? currentMembers;
  String? lookingForMembers;

  String? selectedRole;
  final Set<String> selectedRoles = {};

  bool _saving = false;

  @override
  void dispose() {
    _roomNameController.dispose();
    super.dispose();
  }

  List<String> get _currentOptions {
    final cap = widget.game.maxPartySize;
    if (cap == null) return List.generate(20, (i) => '${i + 1}');
    return List.generate(cap - 1, (i) => '${i + 1}');
  }

  List<String> get _lookingForOptions {
    final cap = widget.game.maxPartySize;
    if (cap == null) return List.generate(20, (i) => '${i + 1}');
    final current = int.tryParse(currentMembers ?? '');
    if (current == null) return [];
    final remaining = cap - current;
    if (remaining <= 0) return [];
    return List.generate(remaining, (i) => '${i + 1}');
  }

  String? _resolveRoleString() {
    if (!widget.game.hasRole) return null;
    if (widget.game.allowMultiRole) {
      if (selectedRoles.isEmpty) return null;
      final ordered = widget.game.roles
          .where(selectedRoles.contains)
          .toList(growable: false);
      return ordered.join(', ');
    }
    return selectedRole;
  }

  Future<void> _onSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    if (widget.game.hasRole &&
        widget.game.allowMultiRole &&
        selectedRoles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาเลือกตำแหน่งที่ต้องการอย่างน้อย 1')),
      );
      return;
    }

    final uid = AuthService.instance.currentUid;
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาเข้าสู่ระบบก่อน')),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final me = await UserService.instance.getProfile(uid);
      final ownerName = me?.username ?? 'Unknown';
      final ownerAvatar =
          me?.avatarUrl ?? 'https://i.pravatar.cc/150?u=$uid';

      final current = int.parse(currentMembers!);
      final looking = int.parse(lookingForMembers!);

      final party = PartyModel(
        title: _roomNameController.text.trim(),
        gameId: widget.game.id,
        rank: widget.game.hasRank ? selectedRank : null,
        role: _resolveRoleString(),
        current: current,
        max: current + looking,
        ownerId: uid,
        ownerName: ownerName,
        leadAvatar: ownerAvatar,
        memberIds: [uid],
        createdAt: DateTime.now(),
      );

      await PartyService.instance.createParty(party);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('สร้างปาร์ตี้สำเร็จ!'),
            backgroundColor: Colors.green),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('สร้างไม่สำเร็จ: $e'),
            backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final game = widget.game;
    return Scaffold(
      backgroundColor: bgWhite,
      appBar: AppBar(
        title: Text('Create ${game.displayName} Party',
            style: const TextStyle(
                color: textMain, fontWeight: FontWeight.bold)),
        backgroundColor: bgWhite,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: deepPink),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _roomNameController,
                decoration: _decoration('ชื่อห้อง (Room Name)'),
                validator: (v) =>
                (v == null || v.isEmpty) ? 'กรุณาตั้งชื่อห้อง' : null,
              ),
              const SizedBox(height: 15),
              if (game.hasRank) ...[
                DropdownButtonFormField<String>(
                  decoration: _decoration('เลือกแรงค์ (Required Rank)'),
                  initialValue: selectedRank,
                  items: game.ranks
                      .map((r) =>
                      DropdownMenuItem<String>(value: r, child: Text(r)))
                      .toList(),
                  onChanged: (v) => setState(() => selectedRank = v),
                  validator: (v) => v == null ? 'กรุณาเลือกแรงค์' : null,
                ),
                const SizedBox(height: 15),
              ],
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      decoration: _decoration('ในตี้มี'),
                      initialValue: currentMembers,
                      items: _currentOptions
                          .map((n) => DropdownMenuItem(
                          value: n,
                          child: Text('$n ${game.memberLabel}')))
                          .toList(),
                      onChanged: (v) => setState(() {
                        currentMembers = v;
                        if (lookingForMembers != null &&
                            !_lookingForOptions.contains(lookingForMembers)) {
                          lookingForMembers = null;
                        }
                      }),
                      validator: (v) => v == null ? 'ระบุ' : null,
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Text('+',
                        style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: deepPink)),
                  ),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      decoration: _decoration('จะหา'),
                      initialValue: lookingForMembers,
                      items: _lookingForOptions
                          .map((n) => DropdownMenuItem(
                          value: n,
                          child: Text('$n ${game.memberLabel}')))
                          .toList(),
                      onChanged: _lookingForOptions.isEmpty
                          ? null
                          : (v) => setState(() => lookingForMembers = v),
                      validator: (v) => v == null ? 'ระบุ' : null,
                      disabledHint: const Text('เลือกจำนวนที่มีก่อน',
                          style: TextStyle(fontSize: 12, color: textSub)),
                    ),
                  ),
                ],
              ),
              if (currentMembers != null && lookingForMembers != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'รวมทั้งหมด ${int.parse(currentMembers!) + int.parse(lookingForMembers!)} ${game.memberLabel}',
                      style: const TextStyle(
                          color: textSub,
                          fontSize: 13,
                          fontStyle: FontStyle.italic),
                    ),
                  ),
                ),
              const SizedBox(height: 15),
              if (game.hasRole)
                game.allowMultiRole
                    ? _buildMultiRoleSelector(game)
                    : _buildSingleRoleDropdown(game),
              const SizedBox(height: 25),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: deepPink,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15)),
                  ),
                  onPressed: _saving ? null : _onSubmit,
                  child: _saving
                      ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.5))
                      : const Text('Create Party',
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

  Widget _buildSingleRoleDropdown(GameConfig game) {
    return DropdownButtonFormField<String>(
      decoration: _decoration('ตำแหน่งที่ขาด (Missing Role)'),
      initialValue: selectedRole,
      items: game.roles
          .map((r) => DropdownMenuItem<String>(value: r, child: Text(r)))
          .toList(),
      onChanged: (v) => setState(() => selectedRole = v),
      validator: (v) => v == null ? 'กรุณาเลือกตำแหน่งที่ต้องการ' : null,
    );
  }

  Widget _buildMultiRoleSelector(GameConfig game) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: primaryPink.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('ตำแหน่งที่ขาด',
                  style:
                  TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(width: 6),
              const Text('(เลือกได้หลายอัน)',
                  style: TextStyle(fontSize: 12, color: textSub)),
              const Spacer(),
              if (selectedRoles.isNotEmpty)
                Text('${selectedRoles.length} เลือก',
                    style: const TextStyle(
                        fontSize: 12,
                        color: deepPink,
                        fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: game.roles.map((role) {
              final isSelected = selectedRoles.contains(role);
              return FilterChip(
                label: Text(role),
                selected: isSelected,
                showCheckmark: false,
                onSelected: (val) => setState(() {
                  if (val) {
                    selectedRoles.add(role);
                  } else {
                    selectedRoles.remove(role);
                  }
                }),
                backgroundColor: Colors.white,
                selectedColor: deepPink,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : textMain,
                  fontWeight:
                  isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                      color: isSelected ? deepPink : Colors.grey.shade300),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  InputDecoration _decoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: primaryPink.withValues(alpha: 0.5),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none),
    );
  }
}