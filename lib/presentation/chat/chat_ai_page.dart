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
import '../chat/controller/chat_history_controller.dart';
import '../chat/repository/chat_history_repository.dart';
import '../../domain/models/chat_message_model.dart' as domain_msg;
import '../../domain/models/chat_role.dart' as domain_role;

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

  late final ChatHistoryController _history;
  late final VoidCallback _historyListener;

  @override
  void initState() {
    super.initState();
    _chatService = widget.service ?? MockAiChatService();
    _history = ChatHistoryController(
      repository: ChatHistoryRepository(),
      defaultProvider: widget.settings.settings.activeProvider,
    );
    _historyListener = () {
      setState(() {});
    };
    _history.addListener(_historyListener);
    unawaited(_loadHistory());
    widget.settings.addListener(_applyProviderFromSettings);
    _applyProviderFromSettings();
  }

  Future<void> _loadHistory() async {
    await _history.load();
    final List<domain_msg.ChatMessageModel> hist = _history.activeChat?.messages ?? <domain_msg.ChatMessageModel>[];
    setState(() {
      _messages
        ..clear()
        ..addAll(hist.map(_mapDomainToCore));
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _scrollController.dispose();
    widget.settings.removeListener(_applyProviderFromSettings);
    _history.removeListener(_historyListener);
    super.dispose();
  }

  void _applyProviderFromSettings() {
    final AppSettings s = widget.settings.settings;
    final AiProviderType type = s.activeProvider;
    final ProviderSettings ps = s.providers[type] ?? const ProviderSettings(enabled: false, apiKey: '');

    _history.setDefaultProvider(type);

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

  Future<void> _newChat() async {
    await _history.createNewChat();
    setState(() {
      _messages.clear();
    });
  }

  void _stop() {
    _subscription?.cancel();
    setState(() {
      _isBusy = false;
    });
  }

  Future<void> _send(String text) async {
    final ChatMessage userMessage = ChatMessage(
      id: 'u_${DateTime.now().microsecondsSinceEpoch}',
      role: ChatRole.user,
      content: text,
      createdAt: DateTime.now(),
    );

    await _history.addUserMessage(text, id: userMessage.id);

    setState(() {
      _messages.add(userMessage);
      _isBusy = true;
    });
    _scrollToBottomDeferred();

    _subscription?.cancel();
    _subscription = _chatService
        .sendMessage(history: List<ChatMessage>.from(_messages), prompt: text)
        .listen((ChatMessage assistantUpdate) async {
      final int existingIndex = _messages.lastIndexWhere((ChatMessage m) => m.id == assistantUpdate.id);
      setState(() {
        if (existingIndex >= 0) {
          _messages[existingIndex] = assistantUpdate;
        } else {
          _messages.add(assistantUpdate);
        }
      });
      await _history.upsertAssistantMessage(id: assistantUpdate.id, content: assistantUpdate.content);
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

  ChatMessage _mapDomainToCore(domain_msg.ChatMessageModel m) {
    final ChatRole role;
    switch (m.role) {
      case domain_role.ChatRole.user:
        role = ChatRole.user;
        break;
      case domain_role.ChatRole.assistant:
        role = ChatRole.assistant;
        break;
      case domain_role.ChatRole.system:
        role = ChatRole.system;
        break;
      default:
        role = ChatRole.assistant;
        break;
    }
    return ChatMessage(
      id: m.id,
      role: role,
      content: m.content,
      createdAt: m.createdAt ?? DateTime.now(),
    );
  }

  String _providerLabel(AiProviderType t) {
    switch (t) {
      case AiProviderType.openAI:
        return 'OpenAI';
      case AiProviderType.deepSeek:
        return 'DeepSeek';
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppSettings s = widget.settings.settings;
    final AiProviderType type = s.activeProvider;
    final ProviderSettings ps = s.providers[type] ?? const ProviderSettings(enabled: false, apiKey: '');
    final String assistantLabel = ps.enabled
        ? [
            _providerLabel(type),
            if (ps.defaultModel != null && ps.defaultModel!.isNotEmpty) ps.defaultModel!,
          ].join(' • ')
        : 'Assistant';

    final bool isWide = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      drawer: isWide
          ? null
          : Drawer(
              child: SafeArea(
                child: ChatSidebar(
                  onNewChat: _newChat,
                  onOpenSettings: _openSettings,
                  chats: _history.chats,
                  activeChatId: _history.activeChatId,
                  onSelectChat: _selectChat,
                ),
              ),
            ),
      body: Row(
        children: <Widget>[
          const SizedBox(width: 8),
          if (isWide)
            ChatSidebar(
              onNewChat: _newChat,
              onOpenSettings: _openSettings,
              chats: _history.chats,
              activeChatId: _history.activeChatId,
              onSelectChat: _selectChat,
            ),
          if (isWide)
            VerticalDivider(width: 1, color: Theme.of(context).colorScheme.outlineVariant),
          Expanded(
            child: Column(
              children: <Widget>[
                _TopBar(showMenu: !isWide),
                const Divider(height: 1),
                Expanded(
                  child: _messages.isEmpty
                      ? const _EmptyState()
                      : ChatMessagesList(messages: _messages, controller: _scrollController, assistantLabel: assistantLabel),
                ),
                const Divider(height: 1),
                ChatInput(
                  isBusy: _isBusy,
                  onSend: _send,
                  onStop: _stop,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  void _selectChat(String chatId) async {
    await _history.selectChat(chatId);
    final List<domain_msg.ChatMessageModel> hist = _history.activeChat?.messages ?? <domain_msg.ChatMessageModel>[];
    setState(() {
      _messages
        ..clear()
        ..addAll(hist.map(_mapDomainToCore));
    });
    _scrollToBottomDeferred();
  }
}

class _TopBar extends StatelessWidget {
  final bool showMenu;

  const _TopBar({required this.showMenu});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: <Widget>[
            if (showMenu)
              Builder(
                builder: (context) => IconButton(
                  tooltip: 'Menu',
                  icon: const Icon(Icons.menu),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              ),
            Text(
              'Chat',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

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
          const SizedBox(height: 24),
        ],
      ),
    );
  }
} 