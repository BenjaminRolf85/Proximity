import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/person.dart';
import '../state/chat_provider.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key, required this.person});
  final Person person;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    await ref.read(chatProvider.notifier).messagesFor(widget.person.id);
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(chatProvider.select((map) => map[widget.person.id])) ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 14,
              backgroundImage: widget.person.avatarUrl != null && widget.person.avatarUrl!.isNotEmpty
                  ? NetworkImage(widget.person.avatarUrl!)
                  : null,
              onBackgroundImageError: (_, __) {},
              child: widget.person.avatarUrl == null || widget.person.avatarUrl!.isEmpty
                  ? Text(widget.person.name.characters.first)
                  : null,
            ),
            const SizedBox(width: 8),
            Text(widget.person.name),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              itemCount: messages.length,
              itemBuilder: (context, i) {
                final m = messages[i];
                final isMe = m.fromId == 'me';
                return Align(
                  alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isMe
                          ? Theme.of(context).colorScheme.primaryContainer
                          : Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(m.text),
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      minLines: 1,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        hintText: 'Message',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () async {
                      final text = _controller.text.trim();
                      if (text.isEmpty) return;
                      _controller.clear();
                      await ref.read(chatProvider.notifier).sendTo(widget.person.id, text);
                      
                      // Scroll to bottom after sending
                      if (_scroll.hasClients) {
                        await Future.delayed(const Duration(milliseconds: 100));
                        _scroll.animateTo(
                          _scroll.position.maxScrollExtent + 80,
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeOut,
                        );
                      }
                    },
                    child: const Text('Send'),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}


