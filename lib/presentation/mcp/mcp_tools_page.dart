import 'package:flutter/material.dart';
import '../../mcp/controller/mcp_controller.dart';
import '../../mcp/models/mcp_tool.dart';
import '../../mcp/service/mcp_integration_service.dart';

class McpToolsPage extends StatefulWidget {
  final McpController mcpController;

  const McpToolsPage({
    super.key,
    required this.mcpController,
  });

  @override
  State<McpToolsPage> createState() => _McpToolsPageState();
}

class _McpToolsPageState extends State<McpToolsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  String _selectedCategory = 'All';
  List<String> _categories = ['All'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _updateCategories();
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
      if (tool.description.isNotEmpty) {
        // Extract category from description or tool name
        final category = _extractCategory(tool);
        categories.add(category);
      }
    }
    
    setState(() {
      _categories = categories.toList()..sort();
    });
  }

  String _extractCategory(McpTool tool) {
    // Try to extract category from tool name or description
    final name = tool.name.toLowerCase();
    final description = tool.description.toLowerCase();
    
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

  List<McpTool> _getFilteredTools() {
    final tools = mcpService.availableTools.values.toList();
    
    return tools.where((tool) {
      // Filter by search query
      final matchesSearch = _searchQuery.isEmpty ||
          tool.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          tool.description.toLowerCase().contains(_searchQuery.toLowerCase());
      
      // Filter by category
      final matchesCategory = _selectedCategory == 'All' ||
          _extractCategory(tool) == _selectedCategory;
      
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

          return TabBarView(
            controller: _tabController,
            children: [
              _buildAvailableToolsTab(),
              _buildFavoritesTab(),
              _buildHistoryTab(),
            ],
          );
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
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
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
              ? const Center(
                  child: Text('No tools found'),
                )
              : ListView.builder(
                  itemCount: tools.length,
                  itemBuilder: (context, index) {
                    final tool = tools[index];
                    return _ToolCard(
                      tool: tool,
                      onFavorite: () {
                        // TODO: Implement favorites
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Added ${tool.name} to favorites')),
                        );
                      },
                      onExecute: () => _showToolExecutionDialog(tool),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildFavoritesTab() {
    // TODO: Implement favorites functionality
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

  Widget _buildHistoryTab() {
    // TODO: Implement execution history
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

  void _showToolExecutionDialog(McpTool tool) {
    showDialog(
      context: context,
      builder: (context) => _ToolExecutionDialog(tool: tool),
    );
  }
}

class _ToolCard extends StatelessWidget {
  final McpTool tool;
  final VoidCallback onFavorite;
  final VoidCallback onExecute;

  const _ToolCard({
    required this.tool,
    required this.onFavorite,
    required this.onExecute,
  });

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
                  child: Text(
                    tool.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.favorite_border),
                  onPressed: onFavorite,
                  tooltip: 'Add to favorites',
                ),
                IconButton(
                  icon: const Icon(Icons.play_arrow),
                  onPressed: onExecute,
                  tooltip: 'Execute tool',
                ),
              ],
            ),
            if (tool.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                tool.description,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            if (tool.inputSchema != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${tool.inputSchema!.properties.length} parameters',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                  ),
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
  final McpTool tool;

  const _ToolExecutionDialog({required this.tool});

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
    if (widget.tool.inputSchema != null) {
      for (final entry in widget.tool.inputSchema!.properties.entries) {
        _controllers[entry.key] = TextEditingController();
      }
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
      // TODO: Implement actual tool execution
      await Future.delayed(const Duration(seconds: 2)); // Simulate execution
      
      setState(() {
        _result = 'Tool executed successfully!\n\nParameters:\n${_controllers.entries.map((e) => '${e.key}: ${e.value.text}').join('\n')}';
        _isExecuting = false;
      });
    } catch (e) {
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
            if (widget.tool.description.isNotEmpty) ...[
              Text(
                widget.tool.description,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
            ],
            if (widget.tool.inputSchema != null) ...[
              Text(
                'Parameters',
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              ...widget.tool.inputSchema!.properties.entries.map((entry) {
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
              }),
            ],
            if (_isExecuting) ...[
              const SizedBox(height: 16),
              const Center(child: CircularProgressIndicator()),
            ],
            if (_result != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(_result!),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _error!,
                  style: TextStyle(color: theme.colorScheme.onErrorContainer),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isExecuting ? null : _executeTool,
          child: Text(_isExecuting ? 'Executing...' : 'Execute'),
        ),
      ],
    );
  }
}