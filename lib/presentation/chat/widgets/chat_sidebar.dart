import 'package:flutter/material.dart';
import '../../widgets/glass_morphism_widget.dart';
import '../../../domain/models/chat_model.dart';

class ChatSidebar extends StatefulWidget {
  final VoidCallback onNewChat;
  final VoidCallback onOpenSettings;
  final List<ChatModel> chats;
  final String? activeChatId;
  final ValueChanged<String>? onSelectChat;
  final VoidCallback? onDeleteChat;

  const ChatSidebar({
    super.key, 
    required this.onNewChat, 
    required this.onOpenSettings, 
    List<ChatModel>? chats, 
    this.activeChatId, 
    this.onSelectChat,
    this.onDeleteChat,
  }) : chats = chats ?? const <ChatModel>[];

  @override
  State<ChatSidebar> createState() => _ChatSidebarState();
}

class _ChatSidebarState extends State<ChatSidebar> {
  bool _showSearch = false;
  String _searchQuery = '';

  List<ChatModel> get filteredChats {
    if (_searchQuery.isEmpty) return widget.chats;
    return widget.chats.where((chat) {
      return chat.title.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return GlassMorphismWidget(
      blur: 10,
      opacity: 0.1,
      borderRadius: BorderRadius.zero,
      border: Border(right: BorderSide(color: colors.outlineVariant.withOpacity(0.5))),
      child: Container(
        width: 280,
        color: colors.surface.withOpacity(0.8),
        child: Column(
          children: <Widget>[
            // Header with New Chat and Search
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    colors.primaryContainer.withOpacity(0.3),
                    colors.secondaryContainer.withOpacity(0.2),
                  ],
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.tonalIcon(
                          onPressed: widget.onNewChat,
                          icon: const Icon(Icons.add),
                          label: const Text('New chat'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: Icon(_showSearch ? Icons.close : Icons.search),
                        onPressed: () {
                          setState(() {
                            _showSearch = !_showSearch;
                            if (!_showSearch) _searchQuery = '';
                          });
                        },
                      ),
                    ],
                  ),
                  if (_showSearch) ...[
                    const SizedBox(height: 8),
                    TextField(
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: 'Search chats...',
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: colors.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                    ),
                  ],
                ],
              ),
            ),
            // Chat list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: filteredChats.length,
                itemBuilder: (BuildContext context, int index) {
                  final ChatModel chat = filteredChats[index];
                  final bool selected = chat.id == widget.activeChatId;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Material(
                      color: selected 
                        ? colors.primaryContainer.withOpacity(0.3)
                        : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: widget.onSelectChat != null 
                          ? () => widget.onSelectChat!(chat.id) 
                          : null,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          child: Row(
                            children: [
                              Icon(
                                Icons.chat_bubble_outline,
                                size: 20,
                                color: selected ? colors.primary : colors.onSurfaceVariant,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      chat.title.isEmpty ? 'Untitled' : chat.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                                        color: selected ? colors.primary : null,
                                      ),
                                    ),
                                    if (chat.messages.isNotEmpty)
                                      Text(
                                        '${chat.messages.length} messages',
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: colors.onSurfaceVariant,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              if (selected)
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, size: 18),
                                  onPressed: widget.onDeleteChat,
                                  tooltip: 'Delete chat',
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const Divider(height: 1),
            // User profile section with glass effect
            GlassMorphismWidget(
              blur: 5,
              opacity: 0.05,
              borderRadius: BorderRadius.zero,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: <Widget>[
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [colors.primary, colors.secondary],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: const CircleAvatar(
                        backgroundColor: Colors.transparent,
                        child: Icon(Icons.person, color: Colors.white),
                      ),
                    ),
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
                      onPressed: widget.onOpenSettings,
                      icon: const Icon(Icons.settings_outlined),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 