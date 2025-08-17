import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';


import '../../mcp/controller/mcp_controller.dart';
import '../../mcp/models/mcp_server_config.dart';

class McpSettingsPage extends StatelessWidget {
  const McpSettingsPage({
    super.key,
    required this.mcpController,
  });

  final McpController mcpController;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MCP Settings'),
        actions: [
          ListenableBuilder(
            listenable: mcpController,
            builder: (context, _) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Test connection button
                  if (mcpController.servers.isNotEmpty)
                    TextButton(
                      onPressed: () async {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Testing MCP connection...')),
                        );
                        await mcpController.initialize();
                      },
                      child: const Text('Test'),
                    ),
                  const SizedBox(width: 8),
                  Switch(
                    value: mcpController.isEnabled,
                    onChanged: (_) => mcpController.toggleEnabled(),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: mcpController,
        builder: (context, _) {
          return Column(
            children: [
              // Status card
              Card(
                margin: const EdgeInsets.all(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                                                Icon(
                        mcpController.isConnected
                            ? Icons.check_circle
                            : Icons.cancel,
                        color: mcpController.isConnected
                            ? Colors.green
                            : Colors.red,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        mcpController.isConnected
                            ? 'Connected'
                            : mcpController.isInitializing
                                ? 'Connecting...'
                                : 'Disconnected',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                  if (mcpController.error != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      mcpController.error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                  if (mcpController.isConnected) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Available tools: ${mcpController.mcpService.availableTools.length}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                    ],
                  ),
                ),
              ),
              
              // Server list header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'MCP Servers',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () => _showServerDialog(context, mcpController),
                    ),
                  ],
                ),
              ),
              
              // Server list
              Expanded(
                child: mcpController.servers.isEmpty
                    ? const Center(
                        child: Text('No MCP servers configured'),
                      )
                    : ListView.builder(
                        itemCount: mcpController.servers.length,
                        itemBuilder: (context, index) {
                          final server = mcpController.servers[index];
                          return ListTile(
                            leading: Icon(
                              server.enabled
                                  ? Icons.power
                                  : Icons.power_off,
                              color: server.enabled
                                  ? Colors.green
                                  : Colors.grey,
                            ),
                            title: Text(server.name),
                            subtitle: Text(server.fullCommand),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit),
                                                                  onPressed: () => _showServerDialog(
                                  context,
                                  mcpController,
                                  server: server,
                                  index: index,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () => mcpController.removeServer(index),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showServerDialog(
    BuildContext context,
    McpController controller, {
    McpServerConfig? server,
    int? index,
  }) {
    final nameController = TextEditingController(text: server?.name ?? '');
    final commandController = TextEditingController(text: server?.command ?? '');
    final argsController = TextEditingController(
      text: server?.args.isNotEmpty == true 
          ? (server!.args.first == 'run' && server.args.length > 1 
              ? server.args[1] 
              : server.args.join(' '))
          : '',
    );
    bool enabled = server?.enabled ?? true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(server == null ? 'Add MCP Server' : 'Edit MCP Server'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Server Name',
                    hintText: 'e.g., File System Server',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: commandController,
                  decoration: const InputDecoration(
                    labelText: 'Command',
                    hintText: 'e.g., node, dart, python',
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: argsController,
                        decoration: const InputDecoration(
                          labelText: 'Server file path',
                          hintText: 'e.g., /path/to/server.js',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.folder_open),
                      onPressed: () async {
                        final result = await FilePicker.platform.pickFiles(
                          type: FileType.custom,
                          allowedExtensions: ['js', 'dart', 'py', 'exe', 'sh', 'bat'],
                        );
                        if (result != null && result.files.single.path != null) {
                          argsController.text = result.files.single.path!;
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Enabled'),
                  value: enabled,
                  onChanged: (value) => setState(() => enabled = value),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final name = nameController.text.trim();
                final command = commandController.text.trim();
                final serverPath = argsController.text.trim();

                if (name.isEmpty || command.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Name and command are required'),
                    ),
                  );
                  return;
                }

                // Parse command and arguments properly
                List<String> args = [];
                
                // If command contains spaces, split it
                final commandParts = command.split(' ');
                final actualCommand = commandParts.first;
                final extraArgs = commandParts.skip(1).toList();
                
                // Add extra args from command
                args.addAll(extraArgs);
                
                // Add the server path
                if (serverPath.isNotEmpty) {
                  args.add(serverPath);
                }
                
                print('MCP Dialog: Creating server with command: $actualCommand, args: $args');

                final newServer = McpServerConfig(
                  name: name,
                  command: actualCommand,
                  args: args,
                  enabled: enabled,
                );

                if (index != null) {
                  mcpController.updateServer(index, newServer);
                } else {
                  mcpController.addServer(newServer);
                }

                Navigator.of(context).pop();
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
} 