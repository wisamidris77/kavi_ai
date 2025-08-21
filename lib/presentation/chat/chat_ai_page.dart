import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/chat/ai_chat_service.dart';
import '../../core/chat/chat_message.dart';
import '../../core/chat/mock_ai_chat_service.dart';
import '../../providers/providers.dart';
import '../../core/chat/provider_ai_chat_service.dart';
import '../../core/chat/mcp_ai_chat_service.dart';
import '../settings/settings_page.dart';
import '../../settings/controller/settings_controller.dart';
import '../../settings/models/app_settings.dart';
import '../../mcp/controller/mcp_controller.dart';

import 'widgets/enhanced_chat_input.dart';
import 'widgets/chat_messages_list.dart';
import 'widgets/chat_sidebar.dart';
import '../widgets/command_palette.dart';
import '../widgets/responsive_layout.dart';
import '../widgets/thread_view.dart';
import '../chat/controller/chat_history_controller.dart';
import '../chat/repository/chat_history_repository.dart';
import '../../core/file/file_handler_service.dart';

class _OpenCommandPaletteIntent extends Intent {
  const _OpenCommandPaletteIntent();
}

class ChatAiPage extends StatefulWidget {
  final AiChatService? service;
  final SettingsController settings;
  final McpController mcpController;

  const ChatAiPage({super.key, this.service, required this.settings, required this.mcpController});

  @override
  State<ChatAiPage> createState() => _ChatAiPageState();
}

class _ChatAiPageState extends State<ChatAiPage> {
  late AiChatService _chatService;
  final List<ChatMessage> _messages = <ChatMessage>[];
  final ScrollController _scrollController = ScrollController();
  final FileHandlerService _fileHandler = FileHandlerService();
  StreamSubscription<ChatMessage>? _subscription;
  bool _isBusy = false;
  String? _activeMessageId;
  final List<FileInfo> _attachedFiles = [];

  // New state for features
  bool _showSearch = false;
  bool _showPinned = false;
  bool _showBookmarks = false;
  bool _showThread = false;
  final List<String> _pinnedMessageIds = [];
  final List<String> _bookmarkedMessageIds = [];
  ChatMessage? _threadParentMessage;
  final List<ThreadMessage> _threadMessages = [];

  late final ChatHistoryController _history;
  late final VoidCallback _historyListener;

  @override
  void initState() {
    super.initState();
    _chatService = widget.service ?? MockAiChatService();
    _history = ChatHistoryController(repository: ChatHistoryRepository(), defaultProvider: widget.settings.settings.activeProvider);
    _historyListener = () {
      setState(() {});
    };
    _history.addListener(_historyListener);
    unawaited(_loadHistory());
    widget.settings.addListener(_applyProviderFromSettings);
    widget.mcpController.addListener(_applyProviderFromSettings);
    _applyProviderFromSettings();
  }

  Future<void> _loadHistory() async {
    await _history.load();
    // Start a fresh empty chat by default when opening the app
    await _history.createNewChat();
    final List<ChatMessage> hist = _history.activeChat?.messages ?? <ChatMessage>[];
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
    widget.mcpController.removeListener(_applyProviderFromSettings);
    _history.removeListener(_historyListener);
    super.dispose();
  }

  void _applyProviderFromSettings() {
    final AppSettings s = widget.settings.settings;
    final AiProviderType type = s.activeProvider;
    final ProviderSettings ps = s.providers[type] ?? const ProviderSettings(enabled: false, apiKey: '');

    print('Applying provider: $type, enabled: ${ps.enabled}, hasKey: ${ps.apiKey.isNotEmpty}');

    _history.setDefaultProvider(type);

    if (type == AiProviderType.mock) {
      setState(() {
        _chatService = MockAiChatService();
      });
      return;
    }

    if (!ps.enabled || ps.apiKey.isEmpty) {
      print('Provider not enabled or no API key, falling back to mock');
      setState(() {
        _chatService = MockAiChatService();
      });
      return;
    }

    final AiProviderConfig config = AiProviderConfig(apiKey: ps.apiKey, baseUrl: ps.baseUrl, defaultModel: ps.defaultModel);

    // Check if MCP is enabled and connected
    if (widget.mcpController.isEnabled && widget.mcpController.isConnected) {
      print('MCP is connected, using McpAiChatService with ${widget.mcpController.mcpService.availableTools.length} tools');
      setState(() {
        _chatService = McpAiChatService(
          providerType: type,
          config: config,
          mcpService: widget.mcpController.mcpService,
          model: ps.defaultModel,
          temperature: s.defaultTemperature,
          maxTokens: s.defaultMaxTokens,
        );
      });
    } else {
      print('MCP not connected, using regular ProviderAiChatService');
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
  }

  void _openSettings() {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => SettingsPage(controller: widget.settings)));
  }

  Future<void> _newChat() async {
    // Cancel any active message generation
    if (_subscription != null) {
      await _subscription!.cancel();
      _subscription = null;
      if (_activeMessageId != null) {
        await _chatService.abort(messageId: _activeMessageId!);
        _activeMessageId = null;
      }
    }

    await _history.createNewChat();
    setState(() {
      _messages.clear();
      _isBusy = false;
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
    _activeMessageId = null;
    _subscription = _chatService
        .sendMessage(history: List<ChatMessage>.from(_messages), prompt: text)
        .listen(
          (ChatMessage assistantUpdate) async {
            _activeMessageId = assistantUpdate.id;
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
          },
          onDone: () {
            setState(() {
              _isBusy = false;
              _activeMessageId = null;
            });
          },
          onError: (_) {
            setState(() {
              _isBusy = false;
              _activeMessageId = null;
            });
          },
        );
  }

  void _onFilesSelected(List<File> files) async {
    try {
      final fileInfos = <FileInfo>[];

      for (final file in files) {
        final fileInfo = _fileHandler.getFileInfo(file);
        fileInfos.add(fileInfo);
      }

      setState(() {
        _attachedFiles.addAll(fileInfos);
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${files.length} file(s) attached'), duration: const Duration(seconds: 2)));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error attaching files: $e'), backgroundColor: Colors.red, duration: const Duration(seconds: 3)));
    }
  }

  void _onClearFiles() {
    setState(() {
      _attachedFiles.clear();
    });
  }

  void _removeFile(FileInfo fileInfo) {
    setState(() {
      _attachedFiles.remove(fileInfo);
    });
  }

  void _showCommandPalette() {
    final actions = [
      CommandAction(
        title: 'New Chat',
        description: 'Start a new conversation',
        icon: Icons.add,
        shortcut: 'Ctrl+N',
        onExecute: _newChat,
        keywords: ['new', 'start', 'conversation'],
      ),
      CommandAction(
        title: 'Open Settings',
        description: 'Configure app settings',
        icon: Icons.settings,
        shortcut: 'Ctrl+,',
        onExecute: _openSettings,
        keywords: ['settings', 'config', 'preferences'],
      ),
      CommandAction(
        title: 'MCP Tools',
        description: 'Manage MCP tools and servers',
        icon: Icons.build,
        shortcut: 'Ctrl+T',
        onExecute: () => Navigator.of(context).pushNamed('/mcp-tools'),
        keywords: ['tools', 'mcp', 'servers'],
      ),
      CommandAction(
        title: 'MCP Settings',
        description: 'Configure MCP servers',
        icon: Icons.settings_applications,
        onExecute: () => Navigator.of(context).pushNamed('/mcp-settings'),
        keywords: ['mcp', 'settings', 'servers'],
      ),
      CommandAction(
        title: 'Regenerate Last Response',
        description: 'Regenerate the last assistant response',
        icon: Icons.refresh,
        shortcut: 'Ctrl+R',
        onExecute: _regenerateLast,
        keywords: ['regenerate', 'retry', 'response'],
      ),
      CommandAction(
        title: 'Clear Chat',
        description: 'Clear current conversation',
        icon: Icons.clear_all,
        onExecute: () {
          setState(() {
            _messages.clear();
          });
        },
        keywords: ['clear', 'reset', 'conversation'],
      ),
    ];

    CommandPaletteController.show(context, actions: actions);
  }

  Future<void> _regenerateLast() async {
    // Find last user message content
    String? lastUserContent;
    for (int i = _messages.length - 1; i >= 0; i--) {
      if (_messages[i].role == ChatRole.user) {
        lastUserContent = _messages[i].content;
        break;
      }
    }
    if (lastUserContent == null || lastUserContent.trim().isEmpty) return;

    // Remove the last assistant message from UI and history if present
    if (_messages.isNotEmpty && _messages.last.role == ChatRole.assistant) {
      setState(() {
        _messages.removeLast();
      });
      await _history.removeLastAssistantMessage();
    }

    setState(() {
      _isBusy = true;
    });
    _scrollToBottomDeferred();

    _subscription?.cancel();
    _activeMessageId = null;
    _subscription = _chatService
        .sendMessage(history: List<ChatMessage>.from(_messages), prompt: lastUserContent)
        .listen(
          (ChatMessage assistantUpdate) async {
            _activeMessageId = assistantUpdate.id;
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
          },
          onDone: () {
            setState(() {
              _isBusy = false;
              _activeMessageId = null;
            });
          },
          onError: (_) {
            setState(() {
              _isBusy = false;
              _activeMessageId = null;
            });
          },
        );
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

  ChatMessage _mapDomainToCore(ChatMessage m) {
    final ChatRole role;
    switch (m.role) {
      case ChatRole.user:
        role = ChatRole.user;
        break;
      case ChatRole.assistant:
        role = ChatRole.assistant;
        break;
      case ChatRole.system:
        role = ChatRole.system;
        break;
      default:
        role = ChatRole.assistant;
        break;
    }
    return ChatMessage(id: m.id, role: role, content: m.content, createdAt: m.createdAt ?? DateTime.now());
  }

  String _providerLabel(AiProviderType t) {
    switch (t) {
      case AiProviderType.openAI:
        return 'OpenAI';
      case AiProviderType.deepSeek:
        return 'DeepSeek';
      case AiProviderType.ollama:
        return 'Ollama';
      case AiProviderType.anthropic:
        return 'Anthropic';
      case AiProviderType.gemini:
        return 'Gemini';
      case AiProviderType.mistral:
        return 'Mistral';
      case AiProviderType.cohere:
        return 'Cohere';
      case AiProviderType.mock:
        return 'Mock';
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppSettings s = widget.settings.settings;
    final AiProviderType type = s.activeProvider;
    final ProviderSettings ps = s.providers[type] ?? const ProviderSettings(enabled: false, apiKey: '');
    final String assistantLabel = [
      _providerLabel(type),
      if (ps.defaultModel != null && ps.defaultModel!.isNotEmpty) ps.defaultModel!,
      if (ps.defaultModel == null || ps.defaultModel!.isEmpty)
        if (type == AiProviderType.mock) 'mock-sim',
    ].join(' • ');

    final ColorScheme colors = Theme.of(context).colorScheme;

    return Shortcuts(
      shortcuts: {const SingleActivator(LogicalKeyboardKey.keyK, control: true): const _OpenCommandPaletteIntent()},
      child: Actions(
        actions: {_OpenCommandPaletteIntent: CallbackAction<_OpenCommandPaletteIntent>(onInvoke: (_) => _showCommandPalette())},
        child: Focus(
          autofocus: true,
          child: ResponsiveLayout(
            mobile: _buildMobileLayout(assistantLabel, colors),
            tablet: _buildTabletLayout(assistantLabel, colors),
            desktop: _buildDesktopLayout(assistantLabel, colors),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileLayout(String assistantLabel, ColorScheme colors) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Align(
          alignment: Alignment.centerLeft,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: InkWell(
              borderRadius: BorderRadius.circular(6),
              onTapDown: (details) => _openModelMenu(details.globalPosition),
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('KAVI', style: TextStyle(fontWeight: FontWeight.bold)),
                        if (assistantLabel.isNotEmpty) Text(assistantLabel, style: Theme.of(context).textTheme.labelSmall),
                        const SizedBox(width: 6),
                        const Icon(Icons.expand_more, size: 18),
                      ],
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.expand_more, size: 18),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      drawer: Drawer(
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
      body: _buildChatContent(assistantLabel),
    );
  }

  Widget _buildTabletLayout(String assistantLabel, ColorScheme colors) {
    return Scaffold(
      appBar: AppBar(automaticallyImplyLeading: false, titleSpacing: 20, title: _buildAppBarTitle(assistantLabel)),
      body: Row(
        children: <Widget>[
          ChatSidebar(
            onNewChat: _newChat,
            onOpenSettings: _openSettings,
            chats: _history.chats,
            activeChatId: _history.activeChatId,
            onSelectChat: _selectChat,
          ),
          VerticalDivider(width: 1, color: Theme.of(context).colorScheme.outlineVariant),
          Expanded(child: _buildChatContent(assistantLabel)),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(String assistantLabel, ColorScheme colors) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        titleSpacing: 20,
        title: _buildAppBarTitle(assistantLabel),
        actions: [
          // Thread view button
          IconButton(
            icon: Icon(_showThread ? Icons.account_tree : Icons.account_tree_outlined),
            onPressed: () {
              setState(() {
                _showThread = !_showThread;
                if (_showThread) {
                  _showSearch = false;
                  _showPinned = false;
                  _showBookmarks = false;
                }
              });
            },
            tooltip: _showThread ? 'Hide thread' : 'Show thread view',
          ),
          // Search button
          IconButton(
            icon: Icon(_showSearch ? Icons.search_off : Icons.search),
            onPressed: () {
              setState(() {
                _showSearch = !_showSearch;
                if (_showSearch) {
                  _showPinned = false;
                  _showBookmarks = false;
                  _showThread = false;
                }
              });
            },
            tooltip: _showSearch ? 'Close search' : 'Search messages',
          ),
          // Pinned messages button
          IconButton(
            icon: Icon(_showPinned ? Icons.push_pin : Icons.push_pin_outlined),
            onPressed: () {
              setState(() {
                _showPinned = !_showPinned;
                if (_showPinned) {
                  _showSearch = false;
                  _showBookmarks = false;
                  _showThread = false;
                }
              });
            },
            tooltip: _showPinned ? 'Hide pinned' : 'Show pinned messages',
          ),
          // Bookmarks button
          IconButton(
            icon: Icon(_showBookmarks ? Icons.bookmark : Icons.bookmark_border),
            onPressed: () {
              setState(() {
                _showBookmarks = !_showBookmarks;
                if (_showBookmarks) {
                  _showSearch = false;
                  _showPinned = false;
                  _showThread = false;
                }
              });
            },
            tooltip: _showBookmarks ? 'Hide bookmarks' : 'Show bookmarks',
          ),
          const VerticalDivider(width: 1),
          IconButton(icon: const Icon(Icons.tune), onPressed: _openSettings, tooltip: 'Settings'),
          IconButton(icon: const Icon(Icons.build_outlined), onPressed: () => Navigator.pushNamed(context, '/mcp-tools'), tooltip: 'MCP Tools'),
          const SizedBox(width: 8),
        ],
      ),
      body: Row(
        children: <Widget>[
          const SizedBox(width: 8),
          ChatSidebar(
            onNewChat: _newChat,
            onOpenSettings: _openSettings,
            chats: _history.chats,
            activeChatId: _history.activeChatId,
            onSelectChat: _selectChat,
          ),
          VerticalDivider(width: 1, color: Theme.of(context).colorScheme.outlineVariant),
          Expanded(child: _showThread ? _buildThreadLayout(colors) : _buildChatContent(assistantLabel)),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildAppBarTitle(String assistantLabel) {
    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: InkWell(
          borderRadius: BorderRadius.circular(6),
          onTapDown: (details) => _openModelMenu(details.globalPosition),
          child: Padding(
            padding: const EdgeInsets.all(4.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('KAVI', style: TextStyle(fontWeight: FontWeight.bold)),
                    if (assistantLabel.isNotEmpty) Text(assistantLabel, style: Theme.of(context).textTheme.labelSmall),
                  ],
                ),
                const SizedBox(width: 6),
                const Icon(Icons.expand_more, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChatContent(String assistantLabel) {
    return Column(
      children: <Widget>[
        Expanded(
          child: _messages.isEmpty
              ? const _EmptyState()
              : ChatMessagesList(
                  messages: _messages,
                  controller: _scrollController,
                  assistantLabel: assistantLabel,
                  onRegenerateLast: _regenerateLast,
                  onCopyMessage: (_) {},
                  onEditMessage: _editMessage,
                  onReactionToggled: _toggleReaction,
                  isBusy: _isBusy,
                  showTypingIndicator: true,
                ),
        ),
        const Divider(height: 1),
        EnhancedChatInput(
          isBusy: _isBusy,
          onSend: _send,
          onStop: _stop,
          onFilesSelected: _onFilesSelected,
          onClearFiles: _onClearFiles,
          // attachedFiles: _attachedFiles.map((e) => e.path).toList(),
          // onRemoveFile: _removeFile,
        ),
      ],
    );
  }

  void _selectChat(String chatId) async {
    // Cancel any active message generation
    if (_subscription != null) {
      await _subscription!.cancel();
      _subscription = null;
      if (_activeMessageId != null) {
        await _chatService.abort(messageId: _activeMessageId!);
        _activeMessageId = null;
      }
    }

    await _history.selectChat(chatId);
    final List<ChatMessage> hist = _history.activeChat?.messages ?? <ChatMessage>[];
    setState(() {
      _isBusy = false;
      _messages
        ..clear()
        ..addAll(hist.map(_mapDomainToCore));
    });
    _scrollToBottomDeferred();
  }

  Future<void> _openModelMenu(Offset globalPosition) async {
    final AppSettings s = widget.settings.settings;
    final AiProviderType currentType = s.activeProvider;
    final List<AiProviderType> types = AiProviderType.values; // will filter below to only those with models
    final Map<AiProviderType, ProviderSettings> providersMap = s.providers;
    final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final RelativeRect position = RelativeRect.fromLTRB(
      globalPosition.dx,
      globalPosition.dy,
      overlay.size.width - globalPosition.dx,
      overlay.size.height - globalPosition.dy,
    );

    final _ModelSelectionResult? result = await showMenu<_ModelSelectionResult>(
      context: context,
      position: position,
      items: <PopupMenuEntry<_ModelSelectionResult>>[
        PopupMenuItem<_ModelSelectionResult>(
          enabled: false,
          padding: EdgeInsets.zero,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Select model', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  ...types
                      .where((t) {
                        final ProviderSettings ts = providersMap[t] ?? const ProviderSettings(enabled: false, apiKey: '');
                        final List<String> models = <String>{
                          if (t == AiProviderType.mock) 'mock-sim',
                          if (ts.defaultModel != null && ts.defaultModel!.isNotEmpty) ts.defaultModel!,
                          ...ts.customModels,
                        }.toList();
                        return models.isNotEmpty;
                      })
                      .map((t) {
                        final ProviderSettings ts = providersMap[t] ?? const ProviderSettings(enabled: false, apiKey: '');
                        final List<String> models = <String>{
                          if (t == AiProviderType.mock) 'mock-sim',
                          if (ts.defaultModel != null && ts.defaultModel!.isNotEmpty) ts.defaultModel!,
                          ...ts.customModels,
                        }.toList();
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(child: Divider(color: Theme.of(context).colorScheme.outlineVariant)),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  child: Text(_providerLabel(t), style: Theme.of(context).textTheme.labelMedium),
                                ),
                                Expanded(child: Divider(color: Theme.of(context).colorScheme.outlineVariant)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: models
                                  .map(
                                    (m) => ChoiceChip(
                                      label: Text(m),
                                      selected: t == currentType && (ts.defaultModel == m || (t == AiProviderType.mock && m == 'mock-sim')),
                                      onSelected: (_) {
                                        Navigator.of(context).pop(_ModelSelectionResult(type: t, model: m));
                                      },
                                    ),
                                  )
                                  .toList(),
                            ),
                            const SizedBox(height: 12),
                          ],
                        );
                      })
                      ,
                ],
              ),
            ),
          ),
        ),
      ],
    );
    if (!mounted) return;
    if (result != null) {
      final AppSettings current = widget.settings.settings;
      final Map<AiProviderType, ProviderSettings> updatedProviders = Map<AiProviderType, ProviderSettings>.from(current.providers);
      final ProviderSettings currentPs = updatedProviders[result.type] ?? const ProviderSettings(enabled: false, apiKey: '');
      updatedProviders[result.type] = currentPs.copyWith(defaultModel: result.model);
      final AppSettings updated = current.copyWith(activeProvider: result.type, providers: updatedProviders);
      widget.settings.replaceSettings(updated, persist: true);
      _applyProviderFromSettings();
    }
  }

  Future<void> _verifyProvider(AiProviderType t) async {
    final AppSettings s = widget.settings.settings;
    final ProviderSettings ps = s.providers[t] ?? const ProviderSettings(enabled: false, apiKey: '');
    if (!ps.enabled || (t != AiProviderType.mock && t != AiProviderType.ollama && ps.apiKey.isEmpty)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enable and set API key first')));
      return;
    }
    try {
      final AiProviderConfig config = AiProviderConfig(apiKey: ps.apiKey, baseUrl: ps.baseUrl, defaultModel: ps.defaultModel);
      final domain = ProviderAiChatService(providerType: t, config: config, model: ps.defaultModel);
      final sub = domain.sendMessage(history: const [], prompt: 'ping').listen((_) {});
      await sub.asFuture<void>();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${_providerLabel(t)} verified')));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to verify ${_providerLabel(t)}')));
    }
  }

  Widget _buildThreadLayout(ColorScheme colors) {
    return Row(
      children: [
        // Main chat on the left
        Expanded(flex: 2, child: _buildChatContent(_getAssistantLabel())),
        // Thread view on the right
        Container(width: 1, color: colors.outlineVariant),
        Expanded(
          flex: 1,
          child: Container(
            color: colors.surfaceContainerHighest.withOpacity(0.3),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    border: Border(bottom: BorderSide(color: colors.outlineVariant)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.account_tree, color: colors.primary),
                      const SizedBox(width: 8),
                      Text('Thread', style: Theme.of(context).textTheme.titleMedium),
                      const Spacer(),
                      if (_threadParentMessage != null) TextButton(onPressed: _clearThread, child: const Text('Clear')),
                    ],
                  ),
                ),
                Expanded(
                  child: ThreadView(
                    threadMessages: _threadMessages.toList(),
                    onMessageSelected: (message) {
                      // Handle message selection in thread
                      _startThreadFromMessage(
                        ChatMessage(
                          id: message.id,
                          role: _mapDomainRoleToCore(message.role),
                          content: message.content,
                          createdAt: message.createdAt ?? DateTime.now(),
                        ),
                      );
                    },
                    onReplyToMessage: (message) {
                      // Handle reply to message in thread
                      _replyInThread(
                        ChatMessage(
                          id: message.id,
                          role: _mapDomainRoleToCore(message.role),
                          content: message.content,
                          createdAt: message.createdAt ?? DateTime.now(),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _getAssistantLabel() {
    final AppSettings s = widget.settings.settings;
    final AiProviderType type = s.activeProvider;
    final ProviderSettings ps = s.providers[type] ?? const ProviderSettings(enabled: false, apiKey: '');
    final String assistantLabel = [
      _providerLabel(type),
      if (ps.defaultModel != null && ps.defaultModel!.isNotEmpty) ps.defaultModel!,
      if (ps.defaultModel == null || ps.defaultModel!.isEmpty)
        if (type == AiProviderType.mock) 'mock-sim',
    ].join(' • ');
    return assistantLabel;
  }

  void _startThreadFromMessage(ChatMessage message) {
    setState(() {
      _threadParentMessage = message;
      _threadMessages.clear();
      _threadMessages.add(ThreadMessage(message: _mapCoreToDomain(message), depth: 0));
    });
  }

  void _replyInThread(ChatMessage message) {
    if (_threadParentMessage == null) return;

    final newMessage = ChatMessage(
      id: 'u_${DateTime.now().microsecondsSinceEpoch}',
      role: ChatRole.user,
      content: message.content,
      createdAt: DateTime.now(),
    );

    setState(() {
      _messages.add(newMessage);
      _isBusy = true;
    });
    _scrollToBottomDeferred();

    _subscription?.cancel();
    _activeMessageId = null;
    _subscription = _chatService
        .sendMessage(history: List<ChatMessage>.from(_messages), prompt: message.content)
        .listen(
          (ChatMessage assistantUpdate) async {
            _activeMessageId = assistantUpdate.id;
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
          },
          onDone: () {
            setState(() {
              _isBusy = false;
              _activeMessageId = null;
            });
          },
          onError: (_) {
            setState(() {
              _isBusy = false;
              _activeMessageId = null;
            });
          },
        );

    setState(() {
      _threadMessages.add(ThreadMessage(message: _mapCoreToDomain(newMessage), depth: 1, parentMessageId: newMessage.id));
    });
  }

  void _clearThread() {
    setState(() {
      _threadParentMessage = null;
      _threadMessages.clear();
    });
  }

  ChatMessage _mapCoreToDomain(ChatMessage m) {
    final ChatRole role;
    switch (m.role) {
      case ChatRole.user:
        role = ChatRole.user;
        break;
      case ChatRole.assistant:
        role = ChatRole.assistant;
        break;
      case ChatRole.system:
        role = ChatRole.system;
        break;
      default:
        role = ChatRole.assistant;
        break;
    }
    return ChatMessage(id: m.id, role: role, content: m.content, createdAt: m.createdAt);
  }

  ChatRole _mapDomainRoleToCore(ChatRole r) {
    switch (r) {
      case ChatRole.user:
        return ChatRole.user;
      case ChatRole.assistant:
        return ChatRole.assistant;
      case ChatRole.system:
        return ChatRole.system;
      default:
        return ChatRole.assistant;
    }
  }

  Future<void> _editMessage(String messageId, String newContent) async {
    // Update the message in the history controller
    await _history.editMessage(messageId, newContent);
    
    // Update the local messages list to reflect the change
    final int messageIndex = _messages.indexWhere((m) => m.id == messageId);
    if (messageIndex != -1) {
      setState(() {
        _messages[messageIndex] = _messages[messageIndex].copyWith(
          content: newContent,
          createdAt: DateTime.now(),
        );
      });
      
      // If this is a user message, regenerate the AI response
      if (_messages[messageIndex].role == ChatRole.user) {
        // Remove all assistant messages that came after this user message
        final List<ChatMessage> updatedMessages = [];
        for (int i = 0; i <= messageIndex; i++) {
          updatedMessages.add(_messages[i]);
        }
        
        setState(() {
          _messages.clear();
          _messages.addAll(updatedMessages);
        });
        
        // Trigger AI response to the edited message
        await _send(newContent);
      }
    }
  }

  Future<void> _toggleReaction(String messageId, String emoji) async {
    // Update the message in the history controller
    await _history.addReactionToMessage(messageId, emoji);
    
    // Update the local messages list to reflect the change
    final int messageIndex = _messages.indexWhere((m) => m.id == messageId);
    if (messageIndex != -1) {
      final updatedMessage = _history.activeChat?.messages.firstWhere(
        (m) => m.id == messageId,
        orElse: () => _messages[messageIndex],
      );
      
      if (updatedMessage != null) {
        setState(() {
          _messages[messageIndex] = _mapDomainToCore(updatedMessage);
        });
        
        // Show visual feedback
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Toggled $emoji reaction'),
              duration: const Duration(seconds: 1),
            ),
          );
        }
      }
    }
  }
}

class _ModelSelectionResult {
  final AiProviderType type;
  final String? model;
  _ModelSelectionResult({required this.type, this.model});
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
          CircleAvatar(
            radius: 28,
            backgroundColor: colors.primary,
            child: Text(
              'K',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800, color: colors.onPrimary),
            ),
          ),
          const SizedBox(height: 12),
          Text('How can I help you today?', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
