import 'package:flutter/material.dart';

class ChatSidebar extends StatelessWidget {
  final VoidCallback onNewChat;

  const ChatSidebar({super.key, required this.onNewChat});

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
              child: OutlinedButton.icon(
                onPressed: onNewChat,
                icon: const Icon(Icons.add),
                label: const Text('New chat'),
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(8),
              children: const <Widget>[
                ListTile(
                  dense: true,
                  leading: Icon(Icons.chat_outlined),
                  title: Text('Welcome to Kavi'),
                ),
                ListTile(
                  dense: true,
                  leading: Icon(Icons.chat_outlined),
                  title: Text('How to use the app?'),
                ),
                ListTile(
                  dense: true,
                  leading: Icon(Icons.chat_outlined),
                  title: Text('Mock conversation'),
                ),
              ],
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
                  onPressed: () {},
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