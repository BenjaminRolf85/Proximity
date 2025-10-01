import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../state/groups_provider.dart';
import '../models/group.dart';
import '../utils/proximity_utils.dart';

class GroupManagementScreen extends ConsumerWidget {
  const GroupManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groups = ref.watch(groupsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Groups')),
      body: ListView.separated(
        itemCount: groups.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (_, i) {
          final g = groups[i];
          return ListTile(
            leading: _GroupIcon(type: g.type),
            title: Text(g.name),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final name = await showTextInputDialog(
            context,
            title: 'Create group',
            hint: 'Group name',
          );
          if (name != null && name.trim().isNotEmpty) {
            ref.read(groupsProvider.notifier).addCustomGroup(name.trim());
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('New group'),
      ),
    );
  }
}

class _GroupIcon extends StatelessWidget {
  const _GroupIcon({required this.type});
  final GroupType type;
  @override
  Widget build(BuildContext context) {
    return CircleAvatar(child: Icon(getGroupIcon(type)));
  }
}


