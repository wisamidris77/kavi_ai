import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dart_mcp/client.dart';
import 'package:dart_mcp/stdio.dart';

import '../models/mcp_server_config.dart';

base class McpClientService extends MCPClient {
  McpClientService()
      : super(Implementation(name: 'Kavi AI MCP Client', version: '0.1.0'));

  final Map<String, ServerConnection> _connections = {};
  final Map<String, ServerConnection> _toolToConnection = {};
  final Map<String, Tool> _availableTools = {};

  bool get hasActiveConnections => _connections.isNotEmpty;
  
  Map<String, Tool> get availableTools => Map.unmodifiable(_availableTools);

  /// Connect to multiple MCP servers based on configuration
  Future<void> connectToServers(List<McpServerConfig> configs) async {
    // Disconnect from any existing servers first
    await disconnectAll();

    for (final config in configs) {
      if (!config.enabled) {
        print('MCP Client: Skipping disabled server "${config.name}"');
        continue;
      }
      
      try {
        await _connectToServer(config);
      } catch (e, stack) {
        print('Failed to connect to MCP server ${config.name}: $e');
        print('Stack trace: $stack');
      }
    }
    
    print('MCP Client: Connection process complete. Active connections: ${_connections.length}');
    print('MCP Client: Available tools: ${_availableTools.length}');
  }

  /// Connect to a single MCP server
  Future<void> _connectToServer(McpServerConfig config) async {
    print('MCP Client: Connecting to server "${config.name}"');
    print('MCP Client: Command: ${config.command}');
    print('MCP Client: Args: ${config.args}');
    print('MCP Client: Full command: ${config.fullCommand}');
    
    // Additional debug info
    print('MCP Client: Command length: ${config.command.length}');
    print('MCP Client: Command bytes: ${config.command.codeUnits}');
    
    Process process;
    try {
      // Try to start the process normally first
      process = await Process.start(
        config.command,
        config.args,
        environment: config.env.isEmpty ? null : config.env,
        mode: ProcessStartMode.normal,
        runInShell: Platform.isWindows, // Use shell on Windows to find executables in PATH
      );
    } catch (e) {
      print('MCP Client: Process.start failed');
      print('MCP Client: Error: $e');
      print('MCP Client: Command was: "${config.command}"');
      print('MCP Client: Args were: ${config.args}');
      
      // On Windows, if dart command fails, try with .bat extension
      if (Platform.isWindows && config.command.toLowerCase() == 'dart') {
        print('MCP Client: Trying dart.bat on Windows...');
        try {
          process = await Process.start(
            'dart.bat',
            config.args,
            environment: config.env.isEmpty ? null : config.env,
            mode: ProcessStartMode.normal,
            runInShell: true,
          );
        } catch (e2) {
          print('MCP Client: dart.bat also failed: $e2');
          // Try to find Flutter's dart
          final flutterRoot = Platform.environment['FLUTTER_ROOT'];
          if (flutterRoot != null) {
            final dartPath = '$flutterRoot\\bin\\dart.exe';
            print('MCP Client: Trying Flutter dart at $dartPath');
            try {
              process = await Process.start(
                dartPath,
                config.args,
                environment: config.env.isEmpty ? null : config.env,
                mode: ProcessStartMode.normal,
              );
            } catch (e3) {
              print('MCP Client: Flutter dart also failed: $e3');
              rethrow;
            }
          } else {
            rethrow;
          }
        }
      } else {
        rethrow;
      }
    }
    
    print('MCP Client: Process started for "${config.name}"');
    
    // Listen to stderr for debugging
    process.stderr.transform(utf8.decoder).listen((data) {
      print('MCP Server "${config.name}" stderr: $data');
    });

    final connection = connectServer(
      stdioChannel(input: process.stdout, output: process.stdin),
    );

    // Clean up process when connection is done
    connection.done.then((_) {
      print('MCP Client: Connection done for "${config.name}", killing process');
      process.kill();
    });

    // Initialize the connection
    final initResult = await connection.initialize(
      InitializeRequest(
        protocolVersion: ProtocolVersion.latestSupported,
        capabilities: capabilities,
        clientInfo: implementation,
      ),
    );

    if (!initResult.protocolVersion!.isSupported) {
      await connection.shutdown();
      throw Exception(
        'Protocol version mismatch for ${config.name}, '
        'expected a version between ${ProtocolVersion.oldestSupported} and '
        '${ProtocolVersion.latestSupported}, but got '
        '${initResult.protocolVersion}',
      );
    }

    connection.notifyInitialized(InitializedNotification());
    print('MCP Client: Server "${config.name}" initialized successfully');
    
    _connections[config.name] = connection;

    // Discover available tools
    await _discoverTools(config.name, connection);
  }

  /// Discover and register tools from a connection
  Future<void> _discoverTools(String serverName, ServerConnection connection) async {
    print('MCP Client: Discovering tools for "$serverName"');
    final response = await connection.listTools();
    print('MCP Client: Found ${response.tools.length} tools');
    
    for (final tool in response.tools) {
      final toolKey = '$serverName:${tool.name}';
      _availableTools[toolKey] = tool;
      _toolToConnection[toolKey] = connection;
      print('MCP Client: Registered tool: $toolKey');
    }
  }

  /// Call a tool on the appropriate server
  Future<CallToolResult> callTool({
    required String toolKey,
    Map<String, dynamic>? arguments,
  }) async {
    final connection = _toolToConnection[toolKey];
    if (connection == null) {
      throw Exception('No connection found for tool: $toolKey');
    }

    final tool = _availableTools[toolKey];
    if (tool == null) {
      throw Exception('Tool not found: $toolKey');
    }

    return await connection.callTool(
      CallToolRequest(
        name: tool.name,
        arguments: arguments ?? {},
      ),
    );
  }

  /// Get formatted tool description for AI providers
  String getToolDescription(String toolKey) {
    final tool = _availableTools[toolKey];
    if (tool == null) return '';

    final buffer = StringBuffer();
    buffer.writeln('Tool: $toolKey');
    if (tool.description != null) {
      buffer.writeln('Description: ${tool.description}');
    }
    
    buffer.writeln('Parameters: ${_formatSchema(tool.inputSchema)}');
      
    return buffer.toString();
  }

  String _formatSchema(Schema schema) {
    // Simple schema formatting for AI consumption
    final props = <String>[];
    
    if (schema is ObjectSchema && schema.properties != null) {
      for (final entry in schema.properties!.entries) {
        final propSchema = entry.value;
        var desc = entry.key;
        if (propSchema.description != null) {
          desc += ' (${propSchema.description})';
        }
        props.add(desc);
      }
    }
    
    return props.isEmpty ? 'none' : props.join(', ');
  }

  /// Format tool result for AI consumption
  Future<String> formatToolResult(CallToolResult result) async {
    final buffer = StringBuffer();
    
    if (result.isError == true) {
      buffer.write('Error: ');
    }
    
    for (final content in result.content) {
      switch (content) {
        case TextContent(text: final text):
          buffer.writeln(text);
        case ImageContent(mimeType: final mimeType, data: final data):
          buffer.writeln('[Image: $mimeType]');
        default:
          buffer.writeln('[Unsupported content type: ${content.type}]');
      }
    }
    
    return buffer.toString();
  }

  /// Disconnect from all servers
  Future<void> disconnectAll() async {
    for (final connection in _connections.values) {
      try {
        await connection.shutdown();
      } catch (_) {
        // Ignore shutdown errors
      }
    }
    
    _connections.clear();
    _toolToConnection.clear();
    _availableTools.clear();
  }

  /// Disconnect from a specific server
  Future<void> disconnectServer(String serverName) async {
    final connection = _connections.remove(serverName);
    if (connection != null) {
      try {
        await connection.shutdown();
      } catch (_) {
        // Ignore shutdown errors
      }
      
      // Remove tools associated with this server
      final toolsToRemove = _toolToConnection.entries
          .where((e) => e.value == connection)
          .map((e) => e.key)
          .toList();
      
      for (final toolKey in toolsToRemove) {
        _toolToConnection.remove(toolKey);
        _availableTools.remove(toolKey);
      }
    }
  }
} 