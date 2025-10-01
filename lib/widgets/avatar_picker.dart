import 'package:flutter/material.dart';

// Encode an icon avatar as a token string that can be saved in state.
// Format: icon:<codePoint>:<colorValue>
String encodeIconAvatar(IconData icon, Color color) => 'icon:${icon.codePoint}:${color.value}';

// Try to decode an icon avatar token.
({IconData icon, Color color})? tryDecodeIconAvatar(String token) {
  if (!token.startsWith('icon:')) return null;
  final parts = token.split(':');
  if (parts.length != 3) return null;
  final int? codePoint = int.tryParse(parts[1]);
  final int? colorValue = int.tryParse(parts[2]);
  if (codePoint == null || colorValue == null) return null;
  return (
    icon: IconData(codePoint, fontFamily: 'MaterialIcons'),
    color: Color(colorValue),
  );
}

class _IconChoice {
  const _IconChoice(this.icon, this.color);
  final IconData icon;
  final Color color;
}

const List<_IconChoice> _kPresetIconChoices = [
  _IconChoice(Icons.person, Colors.blue),
  _IconChoice(Icons.sentiment_satisfied, Colors.orange),
  _IconChoice(Icons.sports_esports, Colors.purple),
  _IconChoice(Icons.directions_bike, Colors.teal),
  _IconChoice(Icons.flight, Colors.indigo),
  _IconChoice(Icons.brush, Colors.pink),
  _IconChoice(Icons.code, Colors.green),
  _IconChoice(Icons.school, Colors.deepPurple),
  _IconChoice(Icons.work, Colors.brown),
  _IconChoice(Icons.music_note, Colors.cyan),
  _IconChoice(Icons.camera_alt, Colors.red),
  _IconChoice(Icons.pets, Colors.orange),
  _IconChoice(Icons.local_cafe, Colors.blueGrey),
  _IconChoice(Icons.fitness_center, Colors.deepOrange),
  _IconChoice(Icons.emoji_nature, Colors.lightGreen),
  _IconChoice(Icons.science, Colors.amber),
];

Future<String?> showAvatarPicker(BuildContext context) {
  return showModalBottomSheet<String>(
    context: context,
    useSafeArea: true,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => const _AvatarPickerSheet(),
  );
}

class _AvatarPickerSheet extends StatelessWidget {
  const _AvatarPickerSheet();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Avatar auswählen', style: theme.textTheme.titleLarge),
          const SizedBox(height: 12),
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.5,
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1,
              ),
              itemCount: _kPresetIconChoices.length,
              itemBuilder: (context, index) {
                final c = _kPresetIconChoices[index];
                return _AvatarCell(
                  icon: c.icon,
                  color: c.color,
                  onSelected: () => Navigator.pop(context, encodeIconAvatar(c.icon, c.color)),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              TextButton(onPressed: () => Navigator.pop(context, ''), child: const Text('Avatar entfernen')),
              const Spacer(),
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Abbrechen')),
            ],
          ),
        ],
      ),
    );
  }
}

class _AvatarCell extends StatelessWidget {
  const _AvatarCell({required this.icon, required this.color, required this.onSelected});
  final IconData icon;
  final Color color;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onSelected,
      borderRadius: BorderRadius.circular(40),
      child: Ink(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withOpacity(0.15),
          border: Border.all(color: color.withOpacity(0.5)),
        ),
        child: Center(child: Icon(icon, color: color)),
      ),
    );
  }
}


