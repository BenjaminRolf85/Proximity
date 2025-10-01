import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../state/profile_provider.dart';
import '../widgets/avatar_picker.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _nameCtrl = TextEditingController();
  final _avatarCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final s = ref.read(profileProvider);
    _nameCtrl.text = s.name;
    _avatarCtrl.text = s.avatarUrl ?? '';
    _bioCtrl.text = s.bio;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _avatarCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(profileProvider);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Center(
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Builder(
                    builder: (context) {
                      final token = state.avatarUrl ?? '';
                      final decoded = tryDecodeIconAvatar(token);
                      if (decoded != null) {
                        return CircleAvatar(
                          radius: 40,
                          backgroundColor: decoded.color.withOpacity(0.15),
                          child: Icon(decoded.icon, color: decoded.color, size: 32),
                        );
                      }
                      return CircleAvatar(
                        radius: 40,
                        backgroundColor: theme.colorScheme.surfaceContainerLowest,
                        foregroundImage: token.isNotEmpty ? NetworkImage(token) : null,
                        child: Text(state.name.isNotEmpty ? state.name.characters.first : 'Y'),
                      );
                    },
                  ),
                  IconButton.filledTonal(
                    onPressed: () async {
                      final selected = await showAvatarPicker(context);
                      if (selected == null) return; // cancelled
                      if (selected.isEmpty) {
                        ref.read(profileProvider.notifier).updateAvatarUrl(null);
                        _avatarCtrl.text = '';
                      } else {
                        ref.read(profileProvider.notifier).updateAvatarUrl(selected);
                        _avatarCtrl.text = selected;
                      }
                    },
                    icon: const Icon(Icons.edit),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Name'),
              onChanged: (v) => ref.read(profileProvider.notifier).updateName(v.trim()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _avatarCtrl,
              decoration: const InputDecoration(labelText: 'Avatar-URL (optional)'),
              onChanged: (v) => ref.read(profileProvider.notifier).updateAvatarUrl(v.trim().isEmpty ? null : v.trim()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _bioCtrl,
              decoration: const InputDecoration(labelText: 'Über mich'),
              maxLines: 4,
              onChanged: (v) => ref.read(profileProvider.notifier).updateBio(v),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () => Navigator.of(context).maybePop(),
              icon: const Icon(Icons.check),
              label: const Text('Speichern'),
            ),
          ],
        ),
      ),
    );
  }
}


