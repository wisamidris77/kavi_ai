# MCP (Model Context Protocol) Integration

This module provides MCP client functionality for Kavi AI, allowing integration with external tools and services through the Model Context Protocol.

## Overview

MCP enables AI providers (OpenAI, DeepSeek, etc.) to access external tools and capabilities through a standardized protocol. This implementation allows you to:

- Connect to multiple MCP servers
- Use tools exposed by MCP servers in your AI conversations
- Manage server configurations through the UI
- Automatically enhance AI responses with tool capabilities

## Usage

### 1. Basic Setup in Your App

```dart
import 'package:flutter/material.dart';
import 'settings/controller/settings_controller.dart';
import 'mcp/controller/mcp_controller.dart';
import 'core/chat/mcp_ai_chat_service.dart';

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final SettingsController _settingsController;
  late final McpController _mcpController;
  
  @override
  void initState() {
    super.initState();
    _settingsController = SettingsController(SettingsRepository());
    _mcpController = McpController(settingsController: _settingsController);
    _bootstrap();
  }
  
  @override
  void dispose() {
    _mcpController.dispose();
    super.dispose();
  }
  
  // Use McpAiChatService instead of ProviderAiChatService when MCP is enabled
  AiChatService _createChatService() {
    if (_mcpController.isEnabled && _mcpController.isConnected) {
      return McpAiChatService(
        providerType: _settingsController.settings.activeProvider,
        config: _getProviderConfig(),
        mcpService: _mcpController.mcpService,
      );
    } else {
      return ProviderAiChatService(
        providerType: _settingsController.settings.activeProvider,
        config: _getProviderConfig(),
      );
    }
  }
}
```

### 2. Configure MCP Servers

MCP servers can be configured through the settings UI or programmatically:

```dart
// Add a server programmatically
await _mcpController.addServer(
  McpServerConfig(
    name: 'File System Server',
    command: 'node',
    args: ['/path/to/filesystem-server.js'],
    enabled: true,
  ),
);

// Or configure through settings JSON
{
  "mcpEnabled": true,
  "mcpServers": [
    {
      "name": "File System Server",
      "command": "node",
      "args": ["/path/to/filesystem-server.js"],
      "enabled": true
    }
  ]
}
```

### 3. Example MCP Server (from example1.dart)

Here's a simple file system MCP server implementation:

```dart
import 'dart:io';
import 'package:dart_mcp/server.dart';
import 'package:dart_mcp/stdio.dart';

void main() {
  SimpleFileSystemServer.fromStreamChannel(
    stdioChannel(input: stdin, output: stdout),
  );
}

final class SimpleFileSystemServer extends MCPServer
    with LoggingSupport, RootsTrackingSupport, ToolsSupport {
  SimpleFileSystemServer.fromStreamChannel(super.channel)
    : super.fromStreamChannel(
        implementation: Implementation(name: 'file system', version: '0.0.1'),
      );

  @override
  FutureOr<InitializeResult> initialize(InitializeRequest request) {
    registerTool(
      Tool(
        name: 'readFile',
        description: 'Reads a file from the file system.',
        inputSchema: Schema.object(
          properties: {
            'path': Schema.string(description: 'The path to the file to read.'),
          },
        ),
      ),
      _readFile,
    );
    return super.initialize(request);
  }

  Future<CallToolResult> _readFile(CallToolRequest request) async {
    final path = request.arguments!['path'] as String;
    final file = File(path);
    if (!await file.exists()) {
      return CallToolResult(
        content: [TextContent(text: 'File does not exist')],
        isError: true,
      );
    }
    return CallToolResult(
      content: [TextContent(text: await file.readAsString())],
    );
  }
}
```

### 4. Using MCP in Conversations

When MCP is enabled and connected, the AI will automatically have access to the tools. The system will:

1. Add tool descriptions to the system prompt
2. Parse AI responses for tool calls
3. Execute tools and feed results back to the AI
4. Continue the conversation with tool results

Example conversation:
```
User: Can you read the contents of config.json?

AI: I'll read the config.json file for you.

TOOL_CALL:filesystem:readFile
ARGUMENTS:
{"path": "config.json"}

[Tool executes and returns content]

AI: Based on the tool result:
The config.json file contains the following configuration...
```

## Navigation to MCP Settings

To navigate to MCP settings from your settings page:

```dart
ListTile(
  leading: const Icon(Icons.extension),
  title: const Text('MCP Settings'),
  subtitle: const Text('Configure Model Context Protocol servers'),
  trailing: const Icon(Icons.arrow_forward_ios),
  onTap: () {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => McpSettingsPage(
          mcpController: _mcpController,
        ),
      ),
    );
  },
),
```

## Architecture

The MCP integration consists of several key components:

1. **McpClientService** - Low-level MCP client that manages server connections
2. **McpIntegrationService** - High-level service that integrates MCP with AI providers
3. **McpController** - State management for MCP connections and settings
4. **McpAiChatService** - Enhanced chat service that adds MCP capabilities to existing providers
5. **McpSettingsPage** - UI for managing MCP server configurations

## Security Considerations

- MCP servers run as separate processes with full system access
- Only configure trusted MCP servers
- Consider running servers with restricted permissions
- Validate all tool inputs and outputs

## Troubleshooting

1. **Server won't connect**: Check that the command and arguments are correct
2. **Tools not appearing**: Ensure the server implements tool listing correctly
3. **Tool execution fails**: Check server logs for errors
4. **AI not using tools**: Verify the system prompt includes tool descriptions

## Example Servers

You can find example MCP servers at:
- https://github.com/modelcontextprotocol/servers
- The `mcp/example1.dart` file in this project (simple file system server) 