import 'dart:async';
import 'dart:convert';

import 'package:dart_mcp/client.dart' show Tool;

import '../client/mcp_client_service.dart';
import '../models/mcp_server_config.dart';
import '../models/tool_call_info.dart';
import '../../domain/models/chat_message_model.dart';
import '../../domain/models/chat_role.dart';

/// Service that integrates MCP tools with AI providers
class McpIntegrationService {
  McpIntegrationService() : _client = McpClientService();

  final McpClientService _client;
  
  bool get isConnected => _client.hasActiveConnections;
  Map<String, Tool> get availableTools => _client.availableTools;

  /// Initialize MCP connections based on configuration
  Future<void> initialize(List<McpServerConfig> servers) async {
    await _client.connectToServers(servers);
  }

  /// Shutdown all MCP connections
  Future<void> shutdown() async {
    await _client.disconnectAll();
  }

  /// Process a message and check if it contains tool calls
  Future<String?> processMessageForTools(String message) async {
    if (!isConnected) return null;

    // Check if the message mentions any available tools
    final toolsInfo = StringBuffer();
    final tools = _client.availableTools;
    
    if (tools.isNotEmpty) {
      toolsInfo.writeln('\n[Available MCP Tools]');
      for (final toolKey in tools.keys) {
        toolsInfo.writeln(_client.getToolDescription(toolKey));
      }
    }

    return toolsInfo.isEmpty ? null : toolsInfo.toString();
  }

  /// Execute a tool call and return both the result and tool call info
  Future<(ChatMessageModel, ToolCallInfo)> executeToolCall({
    required String toolKey,
    Map<String, dynamic>? arguments,
  }) async {
    final startTime = DateTime.now();
    final tool = _client.availableTools[toolKey];
    final toolName = tool?.name ?? toolKey.split(':').last;
    
    try {
      final result = await _client.callTool(
        toolKey: toolKey,
        arguments: arguments,
      );

      final endTime = DateTime.now();
      final formattedResult = await _client.formatToolResult(result);
      
      final toolCall = ToolCallInfo(
        toolKey: toolKey,
        toolName: toolName,
        timestamp: startTime,
        arguments: arguments,
        result: formattedResult,
        duration: endTime.difference(startTime),
      );
      
      final message = ChatMessageModel(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        role: ChatRole.tool,
        content: 'Tool: $toolKey\nResult:\n$formattedResult',
        createdAt: DateTime.now(),
      );
      
      return (message, toolCall);
    } catch (e) {
      final endTime = DateTime.now();
      
      final toolCall = ToolCallInfo(
        toolKey: toolKey,
        toolName: toolName,
        timestamp: startTime,
        arguments: arguments,
        error: e.toString(),
        duration: endTime.difference(startTime),
      );
      
      final message = ChatMessageModel(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        role: ChatRole.tool,
        content: 'Tool Error: $toolKey\nError: $e',
        createdAt: DateTime.now(),
      );
      
      return (message, toolCall);
    }
  }

  /// Create a system prompt that includes available tools
  String createToolSystemPrompt() {
    if (!isConnected || _client.availableTools.isEmpty) {
      return '';
    }

    final prompt = StringBuffer();
    prompt.writeln('=== MCP TOOLS AVAILABLE ===');
    prompt.writeln('You have access to MCP (Model Context Protocol) tools that extend your capabilities.');
    prompt.writeln('When asked about available tools, ALWAYS mention these MCP tools in addition to any built-in capabilities.');
    prompt.writeln();
    prompt.writeln('Available MCP tools:');

    for (final entry in _client.availableTools.entries) {
      final toolKey = entry.key;
      final tool = entry.value;
      
      prompt.writeln();
      prompt.writeln('• Tool: ${tool.name ?? toolKey}');
      if (tool.description != null) {
        prompt.writeln('  Description: ${tool.description}');
      }
      prompt.writeln('  Usage: To use this tool, respond with: TOOL_CALL:$toolKey');
      if (tool.inputSchema != null) {
        prompt.writeln('  Parameters: ${_client.getToolDescription(toolKey)}');
      }
    }

    prompt.writeln();
    prompt.writeln('=== IMPORTANT INSTRUCTIONS ===');
    prompt.writeln('1. When asked "what tools do you have available", you MUST list these MCP tools specifically.');
    prompt.writeln('2. Example response for "what tools do you have available":');
    prompt.writeln('   "I have access to several MCP tools including:');
    prompt.writeln('   - listFiles: List files and directories');
    prompt.writeln('   - readFile: Read the contents of a file');
    prompt.writeln('   - getFileInfo: Get information about a file');
    prompt.writeln('   I can also help with general questions, analysis, and conversations."');
    prompt.writeln();
    prompt.writeln('3. To use a tool, format your response as:');
    prompt.writeln('TOOL_CALL:toolKey');
    prompt.writeln('ARGUMENTS:');
    prompt.writeln('{"param1": "value1", "param2": "value2"}');
    prompt.writeln();
    prompt.writeln('Then wait for the tool result before continuing.');

    return prompt.toString();
  }

  /// Parse a message to extract tool calls
  ToolCallRequest? parseToolCall(String message) {
    final lines = message.split('\n');
    String? toolKey;
    final argumentLines = <String>[];
    bool inArguments = false;

    for (final line in lines) {
      if (line.startsWith('TOOL_CALL:')) {
        toolKey = line.substring('TOOL_CALL:'.length).trim();
      } else if (line.trim() == 'ARGUMENTS:') {
        inArguments = true;
      } else if (inArguments && line.trim().isNotEmpty) {
        argumentLines.add(line);
      }
    }

    if (toolKey == null) return null;

    Map<String, dynamic>? arguments;
    if (argumentLines.isNotEmpty) {
      try {
        final jsonString = argumentLines.join('\n');
        arguments = Map<String, dynamic>.from(
          json.decode(jsonString) as Map,
        );
      } catch (_) {
        // Invalid JSON, ignore arguments
      }
    }

    return ToolCallRequest(toolKey: toolKey, arguments: arguments);
  }
}

class ToolCallRequest {
  final String toolKey;
  final Map<String, dynamic>? arguments;

  ToolCallRequest({required this.toolKey, this.arguments});
} 