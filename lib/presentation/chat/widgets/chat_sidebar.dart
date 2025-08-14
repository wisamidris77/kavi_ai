import 'package:flutter/material.dart';

import '../../../domain/models/chat_model.dart';

class ChatSidebar extends StatelessWidget {
  final VoidCallback onNewChat;
  final VoidCallback onOpenSettings;
  final List<ChatModel> chats;
  final String? activeChatId;
  final ValueChanged<String>? onSelectChat;

  const ChatSidebar({super.key, required this.onNewChat, required this.onOpenSettings, List<ChatModel>? chats, this.activeChatId, this.onSelectChat})
      : chats = chats ?? const <ChatModel>[];

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(right: BorderSide(color: colors.outlineVariant)),
      ),
      child: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(12),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.tonalIcon(
                onPressed: onNewChat,
                icon: const Icon(Icons.add),
                label: const Text('New chat'),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: chats.length,
              itemBuilder: (BuildContext context, int index) {
                final ChatModel chat = chats[index];
                final bool selected = chat.id == activeChatId;
                return ListTile(
                  dense: true,
                  selected: selected,
                  leading: const Icon(Icons.chat_outlined),
                  title: Text(chat.title.isEmpty ? 'Untitled' : chat.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                  onTap: onSelectChat != null ? () => onSelectChat!(chat.id) : null,
                );
              },
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: <Widget>[
                const CircleAvatar(child: Icon(Icons.person)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text('You', style: Theme.of(context).textTheme.bodyLarge),
                      Text('Free plan', style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Settings',
                  onPressed: onOpenSettings,
                  icon: const Icon(Icons.settings_outlined),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 