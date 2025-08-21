import 'dart:async';
import 'dart:convert';

import 'package:dart_mcp/client.dart' show Tool;
import 'package:kavi/core/chat/chat_message.dart';

import '../client/mcp_client_service.dart';
import '../models/mcp_server_config.dart';
import '../models/tool_call_info.dart';

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
  Future<(ChatMessage, ToolCallInfo)> executeToolCall({
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
      
      final message = ChatMessage(
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
      
      final message = ChatMessage(
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
    prompt.writeln('=== MCP TOOLS SYSTEM ===');
    prompt.writeln('You are an AI assistant with access to MCP (Model Context Protocol) tools.');
    prompt.writeln('When users request file operations, YOU MUST USE THESE TOOLS.');
    prompt.writeln();
    prompt.writeln('AVAILABLE TOOLS:');

    // Collect specific examples based on actual available tools
    final examples = <String>[];
    
    for (final entry in _client.availableTools.entries) {
      final toolKey = entry.key;
      final tool = entry.value;
      
      prompt.writeln();
      prompt.writeln('• ${tool.name ?? toolKey}');
      if (tool.description != null) {
        prompt.writeln('  Description: ${tool.description}');
      }
      prompt.writeln('  Tool Key: $toolKey');
      prompt.writeln('  Parameters: ${_client.getToolDescription(toolKey)}');
          
      // Add specific examples for common tools
      if (tool.name == 'listFiles' || toolKey.contains('listFiles')) {
        examples.add('''
User: "list files"
Assistant: TOOL_CALL:$toolKey
ARGUMENTS:
{}''');
        
        examples.add('''
User: "show me what's on my desktop"
Assistant: TOOL_CALL:$toolKey
ARGUMENTS:
{"path": ""}''');
      } else if (tool.name == 'readFile' || toolKey.contains('readFile')) {
        examples.add('''
User: "read test.txt"
Assistant: TOOL_CALL:$toolKey
ARGUMENTS:
{"path": "test.txt"}''');
      }
    }

    prompt.writeln();
    prompt.writeln('=== CRITICAL INSTRUCTIONS ===');
    prompt.writeln();
    prompt.writeln('1. When users ask about files, YOU MUST use the appropriate tool.');
    prompt.writeln();
    prompt.writeln('2. YOUR ENTIRE RESPONSE MUST BE IN THIS EXACT FORMAT:');
    prompt.writeln('TOOL_CALL:<exactToolKey>');
    prompt.writeln('ARGUMENTS:');
    prompt.writeln('<jsonArguments>');
    prompt.writeln();
    prompt.writeln('3. IMPORTANT: Use the EXACT tool key shown above, including the colon and any spaces.');
    prompt.writeln();
    prompt.writeln('4. EXAMPLES OF CORRECT RESPONSES:');
    
    // Add collected examples
    for (final example in examples.take(3)) {
      prompt.writeln();
      prompt.writeln(example);
    }
    
    prompt.writeln();
    prompt.writeln('5. DO NOT:');
    prompt.writeln('   - Add any explanation before or after the tool call');
    prompt.writeln('   - Truncate or abbreviate the tool key');
    prompt.writeln('   - Use a different format');
    prompt.writeln();
    prompt.writeln('6. After I give you the tool result, then you can provide a natural language response.');

    return prompt.toString();
  }

  /// Parse a message to extract tool calls
  ToolCallRequest? parseToolCall(String message) {
    // Add logging to debug DeepSeek responses
    print('MCP: Parsing message for tool calls (length: ${message.length})');
    if (message.length < 100) {
      print('MCP: Full message: $message');
    } else {
      print('MCP: Message preview: ${message.substring(0, 100)}...');
    }
    
    // First check if the message contains TOOL_CALL pattern
    if (!message.contains('TOOL_CALL:')) {
      print('MCP: No TOOL_CALL pattern found');
      return null;
    }
    
    // Try to extract the tool call more reliably
    final toolCallMatch = RegExp(r'TOOL_CALL\s*:\s*([^\n]+)', caseSensitive: false).firstMatch(message);
    if (toolCallMatch == null) {
      print('MCP: Could not extract tool call');
      return null;
    }
    
    var toolKey = toolCallMatch.group(1)?.trim();
    if (toolKey == null || toolKey.isEmpty) {
      print('MCP: Empty tool key');
      return null;
    }
    
    print('MCP: Raw tool key extracted: "$toolKey"');
    
    // Extract arguments
    Map<String, dynamic>? arguments;
    final argumentsMatch = RegExp(r'ARGUMENTS\s*:\s*\n([^]*?)(?:\n\n|\$)', caseSensitive: false).firstMatch(message);
    if (argumentsMatch != null) {
      final argString = argumentsMatch.group(1)?.trim();
      if (argString != null && argString.isNotEmpty) {
        try {
          // Handle empty JSON object
          if (argString == '{}') {
            arguments = <String, dynamic>{};
          } else {
            // Try to find JSON object in the string
            final jsonMatch = RegExp(r'\{[^}]*\}', dotAll: true).firstMatch(argString);
            if (jsonMatch != null) {
              arguments = Map<String, dynamic>.from(
                json.decode(jsonMatch.group(0)!) as Map,
              );
            } else {
              arguments = Map<String, dynamic>.from(
                json.decode(argString) as Map,
              );
            }
          }
        } catch (e) {
          print('MCP: Failed to parse arguments: $e');
          arguments = <String, dynamic>{};
        }
      }
    }
    
    // Validate and fix the tool key
    if (!_client.availableTools.containsKey(toolKey)) {
      print('MCP: Tool key "$toolKey" not found in available tools');
      print('MCP: Available tools: ${_client.availableTools.keys.toList()}');
      
      // Try exact case-insensitive match first
      final exactMatch = _client.availableTools.keys.firstWhere(
        (key) => key.toLowerCase() == toolKey!.toLowerCase(),
        orElse: () => '',
      );
      
      if (exactMatch.isNotEmpty) {
        print('MCP: Found exact match (case-insensitive): $exactMatch');
        toolKey = exactMatch;
      } else {
        // Try to find a partial match in case of truncation
        final possibleKeys = _client.availableTools.keys
            .where((key) => key.startsWith(toolKey!) || (toolKey.startsWith(key.split(':').first) ?? false))
            .toList();
        
        if (possibleKeys.isEmpty) {
          // Try more flexible matching
          possibleKeys.addAll(
            _client.availableTools.keys.where((key) {
              final keyParts = key.split(':');
              final toolKeyParts = toolKey!.split(':');
              if (keyParts.length >= 2 && toolKeyParts.isNotEmpty) {
                // Match if tool name matches
                return keyParts.last.toLowerCase() == toolKeyParts.last.toLowerCase();
              }
              return false;
            })
          );
        }
        
        if (possibleKeys.isNotEmpty) {
          print('MCP: Possible matches: $possibleKeys');
          if (possibleKeys.length == 1) {
            print('MCP: Using closest match: ${possibleKeys.first}');
            toolKey = possibleKeys.first;
          } else {
            // If multiple matches, prefer the one with matching server prefix
            final bestMatch = possibleKeys.firstWhere(
              (key) => key.toLowerCase().startsWith(toolKey!.split(':').first.toLowerCase()),
              orElse: () => possibleKeys.first,
            );
            print('MCP: Using best match: $bestMatch');
            toolKey = bestMatch;
          }
        }
      }
    }

    print('MCP: Final parsed tool call - Key: "$toolKey", Arguments: $arguments');
    return ToolCallRequest(toolKey: toolKey, arguments: arguments);
  }
}

class ToolCallRequest {
  final String toolKey;
  final Map<String, dynamic>? arguments;

  ToolCallRequest({required this.toolKey, this.arguments});
} 