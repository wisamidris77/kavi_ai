import 'package:flutter/foundation.dart';
import 'package:kavi/core/chat/chat_message.dart';

import '../../../domain/models/chat_message_model.dart' as domain_msg;
import '../../../domain/models/chat_model.dart';
import '../../../providers/base/provider_type.dart';
import '../repository/chat_history_repository.dart';

class ChatHistoryController extends ChangeNotifier {
  ChatHistoryController({required ChatHistoryRepository repository, required AiProviderType defaultProvider})
      : _repository = repository,
        _defaultProvider = defaultProvider;

  final ChatHistoryRepository _repository;
  AiProviderType _defaultProvider;

  List<ChatModel> _chats = <ChatModel>[];
  String? _activeChatId;

  List<ChatModel> get chats => List<ChatModel>.unmodifiable(_chats);
  ChatModel? get activeChat {
    if (_activeChatId == null) return null;
    for (final ChatModel c in _chats) {
      if (c.id == _activeChatId) return c;
    }
    return null;
  }

  String? get activeChatId => _activeChatId;

  void setDefaultProvider(AiProviderType type) {
    _defaultProvider = type;
  }

  Future<void> load() async {
    _chats = await _repository.loadAll();
    // Do not auto-select a chat; start with no active chat by default
    _activeChatId = null;
    notifyListeners();
  }

  Future<void> _persist() async {
    await _repository.saveAll(_chats);
  }

  Future<void> createNewChat({String? title}) async {
    final ChatModel chat = ChatModel(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: title ?? 'New chat',
      providerType: _defaultProvider,
      messages: const <ChatMessage>[],
    );
    _chats = <ChatModel>[chat, ..._chats];
    _activeChatId = chat.id;
    notifyListeners();
    await _persist();
  }

  Future<void> selectChat(String chatId) async {
    if (_activeChatId == chatId) return;
    _activeChatId = chatId;
    notifyListeners();
  }

  Future<void> addUserMessage(String content, {String? id}) async {
    if (activeChat == null) {
      await createNewChat();
    }
    final String messageId = id ?? DateTime.now().microsecondsSinceEpoch.toString();
    final ChatMessage message = ChatMessage(
      id: messageId,
      role: ChatRole.user,
      content: content,
      createdAt: DateTime.now(),
    );
    _chats = _chats.map((ChatModel c) {
      if (c.id != (_activeChatId ?? '')) return c;
      final bool needsTitle = c.title.isEmpty || c.title == 'New chat';
      final String computedTitle = needsTitle
          ? (content.length > 24 ? content.substring(0, 24) : content)
          : c.title;
      return ChatModel(
        id: c.id,
        title: computedTitle,
        providerType: c.providerType,
        model: c.model,
        messages: <ChatMessage>[...c.messages, message],
        metadata: c.metadata,
      );
    }).toList();
    notifyListeners();
    await _persist();
  }

  Future<void> upsertAssistantMessage({required String id, required String content}) async {
    _chats = _chats.map((ChatModel c) {
      if (c.id != (_activeChatId ?? '')) return c;
      final List<ChatMessage> updated = List<ChatMessage>.from(c.messages);
      final int idx = updated.indexWhere((ChatMessage m) => m.id == id);
      if (idx >= 0) {
        updated[idx] = ChatMessage(
          id: id,
          role: ChatRole.assistant,
          content: content,
          createdAt: updated[idx].createdAt ?? DateTime.now(),
        );
      } else {
        updated.add(ChatMessage(
          id: id,
          role: ChatRole.assistant,
          content: content,
          createdAt: DateTime.now(),
        ));
      }
      return ChatModel(
        id: c.id,
        title: c.title,
        providerType: c.providerType,
        model: c.model,
        messages: updated,
        metadata: c.metadata,
      );
    }).toList();
    notifyListeners();
    await _persist();
  }

  Future<void> clearActiveChat() async {
    if (_activeChatId == null) {
      await createNewChat();
      return;
    }
    _chats = _chats.map((ChatModel c) {
      if (c.id != _activeChatId) return c;
      return ChatModel(
        id: c.id,
        title: 'New chat',
        providerType: c.providerType,
        model: c.model,
        messages: const <ChatMessage>[],
        metadata: c.metadata,
      );
    }).toList();
    notifyListeners();
    await _persist();
  }

  Future<void> removeLastAssistantMessage() async {
    if (activeChat == null) return;
    _chats = _chats.map((ChatModel c) {
      if (c.id != (_activeChatId ?? '')) return c;
      final List<ChatMessage> updated = List<ChatMessage>.from(c.messages);
      for (int i = updated.length - 1; i >= 0; i--) {
        if (updated[i].role == ChatRole.assistant) {
          updated.removeAt(i);
          break;
        }
      }
      return ChatModel(
        id: c.id,
        title: c.title,
        providerType: c.providerType,
        model: c.model,
        messages: updated,
        metadata: c.metadata,
      );
    }).toList();
    notifyListeners();
    await _persist();
  }
} 