import 'package:flutter/material.dart';
import '../models/person.dart';
import '../utils/proximity_utils.dart';

class PersonListItem extends StatelessWidget {
  const PersonListItem({
    super.key,
    required this.person,
    required this.onPing,
    required this.onOpenChat,
  });

  final Person person;
  final VoidCallback onPing;
  final VoidCallback onOpenChat;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final onlineColor = person.isOnline ? scheme.primary : scheme.outlineVariant;

    return ListTile(
      leading: Badge(
        smallSize: 10,
        backgroundColor: onlineColor,
        alignment: Alignment.bottomRight,
        child: _Avatar(name: person.name, url: person.avatarUrl),
      ),
      title: Text(person.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Row(children: [
        Icon(getProximityIcon(person.distanceMeters), size: 18),
      ]),
      trailing: Wrap(
        spacing: 6,
        children: [
          IconButton.filledTonal(
            style: const ButtonStyle(
              iconSize: WidgetStatePropertyAll(18),
              padding: WidgetStatePropertyAll(EdgeInsets.all(6)),
              minimumSize: WidgetStatePropertyAll(Size(36, 36)),
            ),
            tooltip: "I'm nearby",
            icon: const Icon(Icons.near_me_outlined),
            onPressed: onPing,
          ),
          IconButton.filledTonal(
            style: const ButtonStyle(
              iconSize: WidgetStatePropertyAll(18),
              padding: WidgetStatePropertyAll(EdgeInsets.all(6)),
              minimumSize: WidgetStatePropertyAll(Size(36, 36)),
            ),
            tooltip: 'Chat',
            icon: const Icon(Icons.chat_bubble_outline),
            onPressed: onOpenChat,
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.name, this.url});
  final String name;
  final String? url;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
      backgroundImage: url != null && url!.isNotEmpty ? NetworkImage(url!) : null,
      onBackgroundImageError: (_, __) {},
      child: url == null || url!.isEmpty ? Text(name.characters.first) : null,
    );
  }
}


