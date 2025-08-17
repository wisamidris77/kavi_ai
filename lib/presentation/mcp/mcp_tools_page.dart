import 'package:flutter/material.dart';
import 'package:dart_mcp/client.dart' show Tool, Schema;
import '../../mcp/controller/mcp_controller.dart';
import '../../mcp/service/mcp_integration_service.dart';
import '../../mcp/models/mcp_tools_storage.dart';

class McpToolsPage extends StatefulWidget {
  final McpController mcpController;

  const McpToolsPage({super.key, required this.mcpController});

  @override
  State<McpToolsPage> createState() => _McpToolsPageState();
}

class _McpToolsPageState extends State<McpToolsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  String _selectedCategory = 'All';
  List<String> _categories = ['All'];

  final McpToolsStorage _storage = McpToolsStorage();
  List<String> _favorites = [];
  List<ToolExecutionRecord> _history = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _updateCategories();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final favorites = await _storage.loadFavorites();
      final history = await _storage.loadHistory();

      setState(() {
        _favorites = favorites;
        _history = history;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _updateCategories() {
    final tools = mcpService.availableTools.values.toList();
    final categories = <String>{'All'};

    for (final tool in tools) {
      if (tool.description?.isNotEmpty ?? false) {
        // Extract category from description or tool name
        final category = _extractCategory(tool);
        categories.add(category);
      }
    }

    setState(() {
      _categories = categories.toList()..sort();
    });
  }

  String _extractCategory(Tool tool) {
    // Try to extract category from tool name or description
    final name = tool.name.toLowerCase();
    final description = tool.description?.toLowerCase() ?? '';

    if (name.contains('file') || description.contains('file')) return 'File System';
    if (name.contains('search') || description.contains('search')) return 'Search';
    if (name.contains('web') || description.contains('web')) return 'Web';
    if (name.contains('code') || description.contains('code')) return 'Development';
    if (name.contains('database') || description.contains('database')) return 'Database';
    if (name.contains('image') || description.contains('image')) return 'Media';
    if (name.contains('audio') || description.contains('audio')) return 'Media';
    if (name.contains('video') || description.contains('video')) return 'Media';

    return 'Other';
  }

  List<Tool> _getFilteredTools() {
    final tools = mcpService.availableTools.values.toList();

    return tools.where((tool) {
      // Filter by search query
      final matchesSearch =
          _searchQuery.isEmpty ||
          tool.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (tool.description?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);

      // Filter by category
      final matchesCategory = _selectedCategory == 'All' || _extractCategory(tool) == _selectedCategory;

      return matchesSearch && matchesCategory;
    }).toList();
  }

  McpController get mcpController => widget.mcpController;
  McpIntegrationService get mcpService => widget.mcpController.mcpService;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MCP Tools'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Available Tools'),
            Tab(text: 'Favorites'),
            Tab(text: 'Execution History'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              mcpController.initialize();
              _updateCategories();
            },
            tooltip: 'Refresh tools',
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: mcpController,
        builder: (context, _) {
          if (!mcpController.isConnected) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.wifi_off, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('MCP not connected'),
                  Text('Connect to an MCP server to view available tools'),
                ],
              ),
            );
          }

          return TabBarView(controller: _tabController, children: [_buildAvailableToolsTab(), _buildFavoritesTab(), _buildHistoryTab()]);
        },
      ),
    );
  }

  Widget _buildAvailableToolsTab() {
    final tools = _getFilteredTools();

    return Column(
      children: [
        // Search and filter bar
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                decoration: InputDecoration(
                  hintText: 'Search tools...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _categories.map((category) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(category),
                        selected: _selectedCategory == category,
                        onSelected: (selected) {
                          setState(() {
                            _selectedCategory = selected ? category : 'All';
                          });
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),

        // Tools list
        Expanded(
          child: tools.isEmpty
              ? const Center(child: Text('No tools found'))
              : ListView.builder(
                  itemCount: tools.length,
                  itemBuilder: (context, index) {
                    final tool = tools[index];
                    final toolKey = _getToolKey(tool);
                    final isFavorite = _favorites.contains(toolKey);
                    return _ToolCard(
                      tool: tool,
                      isFavorite: isFavorite,
                      onFavorite: () => _toggleFavorite(tool),
                      onExecute: () => _showToolExecutionDialog(tool),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildFavoritesTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final favoriteTools = _getFilteredTools().where((tool) {
      final toolKey = _getToolKey(tool);
      return _favorites.contains(toolKey);
    }).toList();

    if (favoriteTools.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite_border, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No favorite tools yet'),
            Text('Add tools to favorites for quick access'),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: favoriteTools.length,
      itemBuilder: (context, index) {
        final tool = favoriteTools[index];
        return _ToolCard(tool: tool, isFavorite: true, onFavorite: () => _toggleFavorite(tool), onExecute: () => _showToolExecutionDialog(tool));
      },
    );
  }

  String _getToolKey(Tool tool) {
    // Generate a unique key for the tool
    return '${tool.name}_${tool.description.hashCode}';
  }

  Future<void> _toggleFavorite(Tool tool) async {
    final toolKey = _getToolKey(tool);
    final isFavorite = _favorites.contains(toolKey);

    if (isFavorite) {
      await _storage.removeFromFavorites(toolKey);
      setState(() {
        _favorites.remove(toolKey);
      });
    } else {
      await _storage.addToFavorites(toolKey);
      setState(() {
        _favorites.add(toolKey);
      });
    }
  }

  Widget _buildHistoryTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_history.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No execution history yet'),
            Text('Tool executions will appear here'),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _history.length,
      itemBuilder: (context, index) {
        final record = _history[index];
        return _HistoryCard(record: record);
      },
    );
  }

  void _showToolExecutionDialog(Tool tool) {
    showDialog(
      context: context,
      builder: (context) => _ToolExecutionDialog(
        tool: tool,
        mcpController: widget.mcpController,
        onToolExecuted: (record) async {
          await _storage.addToHistory(record);
          _loadData();
        },
        storage: _storage,
      ),
    );
  }
}

class _ToolCard extends StatelessWidget {
  final Tool tool;
  final bool isFavorite;
  final VoidCallback onFavorite;
  final VoidCallback onExecute;

  const _ToolCard({required this.tool, this.isFavorite = false, required this.onFavorite, required this.onExecute});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(tool.name, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                ),
                IconButton(
                  icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_border, color: isFavorite ? Colors.red : null),
                  onPressed: onFavorite,
                  tooltip: isFavorite ? 'Remove from favorites' : 'Add to favorites',
                ),
                IconButton(icon: const Icon(Icons.play_arrow), onPressed: onExecute, tooltip: 'Execute tool'),
              ],
            ),
            if (tool.description?.isNotEmpty ?? false) ...[
              const SizedBox(height: 8),
              Text(tool.description!, style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant)),
            ],
            if (tool.inputSchema != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: colorScheme.primaryContainer, borderRadius: BorderRadius.circular(4)),
                child: Text(
                  '${tool.inputSchema.properties?.length ?? 0} parameters',
                  style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onPrimaryContainer),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ToolExecutionDialog extends StatefulWidget {
  final Tool tool;
  final McpController mcpController;
  final Future<void> Function(ToolExecutionRecord) onToolExecuted;
  final McpToolsStorage storage;
  const _ToolExecutionDialog({required this.tool, required this.mcpController, required this.onToolExecuted, required this.storage});

  @override
  State<_ToolExecutionDialog> createState() => _ToolExecutionDialogState();
}

class _ToolExecutionDialogState extends State<_ToolExecutionDialog> {
  final Map<String, TextEditingController> _controllers = {};
  bool _isExecuting = false;
  String? _result;
  String? _error;

  @override
  void initState() {
    super.initState();
    for (final MapEntry<String, Schema> entry in widget.tool.inputSchema.properties?.entries ?? []) {
      _controllers[entry.key] = TextEditingController();
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _executeTool() async {
    setState(() {
      _isExecuting = true;
      _result = null;
      _error = null;
    });

    try {
      // Prepare arguments from form controllers
      final arguments = <String, dynamic>{};
      for (final entry in _controllers.entries) {
        final value = entry.value.text.trim();
        if (value.isNotEmpty) {
          arguments[entry.key] = value;
        }
      }

      // Execute the tool through MCP service
      final mcpService = widget.mcpController.mcpService;
      final result = await mcpService.executeToolCall(toolKey: widget.tool.name, arguments: arguments.isNotEmpty ? arguments : null);

      final record = ToolExecutionRecord(
        toolKey: widget.tool.name,
        toolName: widget.tool.name,
        timestamp: DateTime.now(),
        arguments: arguments.isNotEmpty ? arguments : null,
        result: result.$1.content,
        duration: Duration(milliseconds: 1000), // Approximate
      );

      // Save to history
      await widget.onToolExecuted(record);

      setState(() {
        _result = result.$1.content;
        _isExecuting = false;
      });
    } catch (e) {
      final record = ToolExecutionRecord(
        toolKey: widget.tool.name,
        toolName: widget.tool.name,
        timestamp: DateTime.now(),
        arguments: _controllers.map((k, v) => MapEntry(k, v.text)),
        error: e.toString(),
        duration: Duration(milliseconds: 1000), // Approximate
      );

      // Save error to history
      await widget.storage.addToHistory(record);

      setState(() {
        _error = e.toString();
        _isExecuting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text('Execute: ${widget.tool.name}'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.tool.description?.isNotEmpty ?? false) ...[
              Text(widget.tool.description!, style: theme.textTheme.bodyMedium),
              const SizedBox(height: 16),
            ],
            ...[
              Text('Parameters', style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              ...widget.tool.inputSchema.properties?.entries.map((entry) {
                    final controller = _controllers[entry.key]!;
                    final property = entry.value;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: TextField(
                        controller: controller,
                        decoration: InputDecoration(
                          labelText: entry.key,
                          hintText: property.description ?? 'Enter ${entry.key}',
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    );
                  }) ??
                  [],
            ],
            if (_isExecuting) ...[const SizedBox(height: 16), const Center(child: CircularProgressIndicator())],
            if (_result != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: theme.colorScheme.surfaceVariant, borderRadius: BorderRadius.circular(8)),
                child: Text(_result!),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: theme.colorScheme.errorContainer, borderRadius: BorderRadius.circular(8)),
                child: Text(_error!, style: TextStyle(color: theme.colorScheme.onErrorContainer)),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        ElevatedButton(onPressed: _isExecuting ? null : _executeTool, child: Text(_isExecuting ? 'Executing...' : 'Execute')),
      ],
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final ToolExecutionRecord record;

  const _HistoryCard({required this.record});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(record.error != null ? Icons.error : Icons.check_circle, color: record.error != null ? Colors.red : Colors.green, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(record.toolName, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                ),
                Text(_formatDuration(record.duration), style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant)),
              ],
            ),
            const SizedBox(height: 8),
            Text(_formatTimestamp(record.timestamp), style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant)),
            if (record.arguments != null && record.arguments!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Arguments: ${record.arguments!.entries.map((e) => '${e.key}=${e.value}').join(', ')}', style: theme.textTheme.bodySmall),
            ],
            if (record.error != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: colorScheme.errorContainer, borderRadius: BorderRadius.circular(4)),
                child: Text(record.error!, style: TextStyle(color: colorScheme.onErrorContainer, fontSize: 12)),
              ),
            ],
            if (record.result != null && record.result!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: colorScheme.surfaceVariant, borderRadius: BorderRadius.circular(4)),
                child: Text(record.result!, style: theme.textTheme.bodySmall, maxLines: 3, overflow: TextOverflow.ellipsis),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }

  String _formatDuration(Duration duration) {
    if (duration.inSeconds < 1) {
      return '${duration.inMilliseconds}ms';
    } else if (duration.inMinutes < 1) {
      return '${duration.inSeconds}s';
    } else {
      return '${duration.inMinutes}m ${duration.inSeconds % 60}s';
    }
  }
}
