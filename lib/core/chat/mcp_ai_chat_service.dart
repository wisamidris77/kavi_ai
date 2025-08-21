import 'dart:async';

import '../../domain/domain.dart' as domain;
import '../../mcp/service/mcp_integration_service.dart';
import '../../mcp/models/tool_call_info.dart';
import '../../providers/providers.dart' as providers;
import 'ai_chat_service.dart';
import 'chat_message.dart';

/// AI Chat Service that enhances existing providers with MCP tool capabilities
class McpAiChatService implements AiChatService {
  McpAiChatService({
    required providers.AiProviderType providerType,
    required providers.AiProviderConfig config,
    required this.mcpService,
    String? model,
    this.temperature,
    this.maxTokens,
  })  : _providerType = providerType,
        _model = model,
        _service = domain.AiChatService(
          providerType: providerType,
          config: config,
        );

  final providers.AiProviderType _providerType;
  final String? _model;
  final double? temperature;
  final int? maxTokens;
  final McpIntegrationService mcpService;

  final domain.AiChatService _service;
  final Map<String, StreamSubscription<String>> _inflight = {};
  final Map<String, StreamController<ChatMessage>> _controllers = {};
  final Map<String, List<ToolCallInfo>> _currentToolCalls = {};

  @override
  Stream<ChatMessage> sendMessage({
    required List<ChatMessage> history,
    required String prompt,
  }) {
    final String messageId = 'mcp_${DateTime.now().microsecondsSinceEpoch}';
    final controller = StreamController<ChatMessage>();
    _controllers[messageId] = controller;

    // Convert chat history to domain models
    final domainHistory = history
        .map((m) => ChatMessage(
              id: m.id,
              role: m.role,
              content: m.content,
              createdAt: m.createdAt,
            ))
        .toList();

    // Add MCP tool system prompt if MCP is connected
    if (mcpService.isConnected) {
      final toolPrompt = mcpService.createToolSystemPrompt();
      if (toolPrompt.isNotEmpty) {
        print('MCP: Adding system prompt with ${mcpService.availableTools.length} tools');
        print('MCP System Prompt Preview:');
        print(toolPrompt.split('\n').take(10).join('\n'));
        print('...');
        
        domainHistory.insert(
          0,
          ChatMessage(
            id: 'mcp_system',
            role: ChatRole.system,
            content: toolPrompt,
            createdAt: DateTime.now(),
          ),
        );
      }
    }

    final accumulator = StringBuffer();
    Future<void>.microtask(() async {
      try {
        final sub = _service
            .streamReply(
              history: domainHistory,
              userInput: prompt,
              model: _model,
              temperature: temperature,
              maxTokens: maxTokens,
            )
            .listen(
          (chunk) async {
            accumulator.write(chunk);
            final currentContent = accumulator.toString();

            // Check if the AI is trying to call a tool
            if (mcpService.isConnected) {
              final toolCall = mcpService.parseToolCall(currentContent);
              if (toolCall != null) {
                // Pause the stream to execute the tool
                _inflight[messageId]?.pause();

                // Send current message state
                if (!controller.isClosed) {
                  controller.add(ChatMessage(
                    id: messageId,
                    role: ChatRole.assistant,
                    content: currentContent,
                    createdAt: DateTime.now(),
                  ));
                }

                // Execute the tool call
                final (toolResult, toolCallInfo) = await mcpService.executeToolCall(
                  toolKey: toolCall.toolKey,
                  arguments: toolCall.arguments,
                );

                // Add tool result to history and continue conversation
                domainHistory.add(toolResult);
                
                // Update message with tool call info
                final existingToolCalls = _currentToolCalls[messageId] ?? [];
                _currentToolCalls[messageId] = [...existingToolCalls, toolCallInfo];
                
                // Clear accumulator and continue with tool result context
                accumulator.clear();
                accumulator.write('Based on the tool result:\n');

                // Resume the stream
                _inflight[messageId]?.resume();
              }
            }

            // Send updated message with tool calls
            final update = ChatMessage(
              id: messageId,
              role: ChatRole.assistant,
              content: currentContent,
              createdAt: DateTime.now(),
              toolCalls: _currentToolCalls[messageId] ?? [],
            );
            if (!controller.isClosed) controller.add(update);
          },
          onError: (Object err, StackTrace st) async {
            if (!controller.isClosed) {
              controller.addError(err, st);
            }
            await controller.close();
            _inflight.remove(messageId);
            _controllers.remove(messageId);
            _currentToolCalls.remove(messageId);
          },
          onDone: () async {
            await controller.close();
            _inflight.remove(messageId);
            _controllers.remove(messageId);
            _currentToolCalls.remove(messageId);
          },
        );

        _inflight[messageId] = sub;
      } catch (e, st) {
        if (!controller.isClosed) {
          controller.addError(e, st);
        }
        await controller.close();
        _inflight.remove(messageId);
        _controllers.remove(messageId);
        _currentToolCalls.remove(messageId);
      }
    });

    return controller.stream;
  }

  @override
  Future<void> abort({required String messageId}) async {
    await _inflight.remove(messageId)?.cancel();
    await _controllers.remove(messageId)?.close();
  }
} 