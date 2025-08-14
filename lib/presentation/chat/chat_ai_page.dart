import 'dart:async';

import 'package:flutter/material.dart';
import '../../core/chat/ai_chat_service.dart';
import '../../core/chat/chat_message.dart';
import '../../core/chat/mock_ai_chat_service.dart';
import '../../providers/providers.dart';
import '../../core/chat/provider_ai_chat_service.dart';
import '../settings/settings_page.dart';
import '../../settings/controller/settings_controller.dart';
import '../../settings/models/app_settings.dart';
import '../../providers/base/provider_config.dart';

import 'widgets/chat_input.dart';
import 'widgets/chat_messages_list.dart';
import 'widgets/chat_sidebar.dart';

class ChatAiPage extends StatefulWidget {
  final AiChatService? service;
  final SettingsController settings;

  const ChatAiPage({super.key, this.service, required this.settings});

  @override
  State<ChatAiPage> createState() => _ChatAiPageState();
}

class _ChatAiPageState extends State<ChatAiPage> {
  late AiChatService _chatService;
  final List<ChatMessage> _messages = <ChatMessage>[];
  final ScrollController _scrollController = ScrollController();
  StreamSubscription<ChatMessage>? _subscription;
  bool _isBusy = false;

  @override
  void initState() {
    super.initState();
    _chatService = widget.service ?? MockAiChatService();
    widget.settings.addListener(_applyProviderFromSettings);
    _applyProviderFromSettings();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _scrollController.dispose();
    widget.settings.removeListener(_applyProviderFromSettings);
    super.dispose();
  }

  void _applyProviderFromSettings() {
    final AppSettings s = widget.settings.settings;
    final AiProviderType type = s.activeProvider;
    final ProviderSettings ps = s.providers[type] ?? const ProviderSettings(enabled: false, apiKey: '');

    if (!ps.enabled || ps.apiKey.isEmpty) {
      setState(() {
        _chatService = MockAiChatService();
      });
      return;
    }

    final AiProviderConfig config = AiProviderConfig(
      apiKey: ps.apiKey,
      baseUrl: ps.baseUrl,
      defaultModel: ps.defaultModel,
    );

    setState(() {
      _chatService = ProviderAiChatService(
        providerType: type,
        config: config,
        model: ps.defaultModel,
        temperature: s.defaultTemperature,
        maxTokens: s.defaultMaxTokens,
      );
    });
  }

  void _openSettings() {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => SettingsPage(controller: widget.settings)));
  }

  void _newChat() {
    setState(() {
      _messages.clear();
    });
  }

  Future<void> _send(String text) async {
    final ChatMessage userMessage = ChatMessage(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      role: ChatRole.user,
      content: text,
      createdAt: DateTime.now(),
    );

    setState(() {
      _messages.add(userMessage);
      _isBusy = true;
    });
    _scrollToBottomDeferred();

    _subscription?.cancel();
    _subscription = _chatService
        .sendMessage(history: List<ChatMessage>.from(_messages), prompt: text)
        .listen((ChatMessage assistantUpdate) {
      final int existingIndex = _messages.lastIndexWhere((ChatMessage m) => m.id == assistantUpdate.id);
      setState(() {
        if (existingIndex >= 0) {
          _messages[existingIndex] = assistantUpdate;
        } else {
          _messages.add(assistantUpdate);
        }
      });
      _scrollToBottomDeferred();
    }, onDone: () {
      setState(() {
        _isBusy = false;
      });
    }, onError: (_) {
      setState(() {
        _isBusy = false;
      });
    });
  }

  void _scrollToBottomDeferred() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 120,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: <Widget>[
          const SizedBox(width: 8),
          if (MediaQuery.of(context).size.width >= 900)
            ChatSidebar(onNewChat: _newChat),
          if (MediaQuery.of(context).size.width >= 900)
            VerticalDivider(width: 1, color: Theme.of(context).colorScheme.outlineVariant),
          Expanded(
            child: Column(
              children: <Widget>[
                _TopBar(onNewChat: _newChat, onSettings: _openSettings),
                const Divider(height: 1),
                Expanded(
                  child: _messages.isEmpty
                      ? _EmptyState(onNewChat: _newChat)
                      : ChatMessagesList(messages: _messages, controller: _scrollController),
                ),
                const Divider(height: 1),
                ChatInput(
                  isBusy: _isBusy,
                  onSend: _send,
                  onStop: () => _subscription?.cancel(),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final VoidCallback onNewChat;
  final VoidCallback onSettings;

  const _TopBar({required this.onNewChat, required this.onSettings});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: <Widget>[
            Text(
              'Chat',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const Spacer(),
            IconButton(
              tooltip: 'Settings',
              onPressed: onSettings,
              icon: const Icon(Icons.settings_outlined),
            ),
            const SizedBox(width: 4),
            FilledButton.tonalIcon(
              onPressed: onNewChat,
              icon: const Icon(Icons.add),
              label: const Text('New chat'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onNewChat;

  const _EmptyState({required this.onNewChat});

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(Icons.smart_toy_outlined, size: 48, color: colors.primary),
          const SizedBox(height: 12),
          Text('How can I help you today?', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          FilledButton(onPressed: onNewChat, child: const Text('Start a new chat')),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
} 