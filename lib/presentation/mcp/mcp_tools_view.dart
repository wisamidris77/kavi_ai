import 'package:flutter/material.dart';
import 'package:dart_mcp/client.dart' show Tool;
import '../../mcp/controller/mcp_controller.dart';

class McpToolsView extends StatefulWidget {
  final McpController mcpController;
  
  const McpToolsView({
    super.key,
    required this.mcpController,
  });

  @override
  State<McpToolsView> createState() => _McpToolsViewState();
}

class _McpToolsViewState extends State<McpToolsView> {
  String _searchQuery = '';
  String? _selectedCategory;
  
  @override
  void initState() {
    super.initState();
    widget.mcpController.addListener(_onMcpStateChanged);
  }
  
  @override
  void dispose() {
    widget.mcpController.removeListener(_onMcpStateChanged);
    super.dispose();
  }
  
  void _onMcpStateChanged() {
    if (mounted) setState(() {});
  }
  
  Map<String, List<MapEntry<String, Tool>>> _categorizeTools() {
    final tools = widget.mcpController.mcpService.availableTools;
    final categories = <String, List<MapEntry<String, Tool>>>{};
    
    for (final entry in tools.entries) {
      final toolKey = entry.key;
      final tool = entry.value;
      
      // Extract category from tool key (e.g., "server:toolName" -> "server")
      final category = toolKey.contains(':') 
          ? toolKey.split(':').first 
          : 'Uncategorized';
      
      categories.putIfAbsent(category, () => []).add(entry);
    }
    
    return categories;
  }
  
  List<MapEntry<String, Tool>> _filterTools(List<MapEntry<String, Tool>> tools) {
    if (_searchQuery.isEmpty) return tools;
    
    final query = _searchQuery.toLowerCase();
    return tools.where((entry) {
      final tool = entry.value;
      final toolKey = entry.key.toLowerCase();
      final name = (tool.name ?? '').toLowerCase();
      final description = (tool.description ?? '').toLowerCase();
      
      return toolKey.contains(query) ||
             name.contains(query) ||
             description.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final isConnected = widget.mcpController.isConnected;
    final isInitializing = widget.mcpController.isInitializing;
    final error = widget.mcpController.error;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('MCP Tools Discovery'),
        actions: [
          if (isConnected)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => widget.mcpController.initialize(),
              tooltip: 'Refresh tools',
            ),
        ],
      ),
      body: Column(
        children: [
          // Connection status
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isConnected 
                  ? colors.primaryContainer 
                  : error != null 
                      ? colors.errorContainer
                      : colors.secondaryContainer,
              border: Border(
                bottom: BorderSide(color: colors.outlineVariant),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isConnected ? Icons.check_circle : Icons.error_outline,
                  color: isConnected 
                      ? colors.onPrimaryContainer 
                      : error != null 
                          ? colors.onErrorContainer
                          : colors.onSecondaryContainer,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isConnected 
                            ? 'MCP Connected' 
                            : error != null 
                                ? 'Connection Error'
                                : 'Not Connected',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: isConnected 
                              ? colors.onPrimaryContainer 
                              : error != null 
                                  ? colors.onErrorContainer
                                  : colors.onSecondaryContainer,
                        ),
                      ),
                      if (isConnected)
                        Text(
                          '${widget.mcpController.mcpService.availableTools.length} tools available',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colors.onPrimaryContainer.withOpacity(0.7),
                          ),
                        ),
                      if (error != null)
                        Text(
                          error,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colors.onErrorContainer.withOpacity(0.7),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                if (isInitializing)
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
          ),
          
          // Search bar
          if (isConnected)
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search tools...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: colors.surfaceVariant,
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
            ),
          
          // Content
          Expanded(
            child: isConnected
                ? _buildToolsList()
                : _buildEmptyState(),
          ),
        ],
      ),
    );
  }
  
  Widget _buildToolsList() {
    final categorizedTools = _categorizeTools();
    final categories = categorizedTools.keys.toList()..sort();
    
    if (categories.isEmpty) {
      return const Center(
        child: Text('No tools available'),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        final tools = _filterTools(categorizedTools[category]!);
        
        if (tools.isEmpty) return const SizedBox.shrink();
        
        final isExpanded = _selectedCategory == category;
        
        return _ToolCategorySection(
          category: category,
          tools: tools,
          isExpanded: isExpanded,
          onToggle: () {
            setState(() {
              _selectedCategory = isExpanded ? null : category;
            });
          },
        );
      },
    );
  }
  
  Widget _buildEmptyState() {
    final ColorScheme colors = Theme.of(context).colorScheme;
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.extension_off,
            size: 64,
            color: colors.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'No MCP connection',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: colors.outline,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Configure MCP servers in settings to discover tools',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colors.outline,
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/mcp-settings'),
            icon: const Icon(Icons.settings),
            label: const Text('Go to MCP Settings'),
          ),
        ],
      ),
    );
  }
}

class _ToolCategorySection extends StatelessWidget {
  final String category;
  final List<MapEntry<String, Tool>> tools;
  final bool isExpanded;
  final VoidCallback onToggle;
  
  const _ToolCategorySection({
    required this.category,
    required this.tools,
    required this.isExpanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: colors.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.folder,
                      color: colors.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          category,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          '${tools.length} tool${tools.length == 1 ? '' : 's'}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: colors.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
          
          if (isExpanded) ...[
            const Divider(height: 1),
            ...tools.map((entry) => _ToolTile(
              toolKey: entry.key,
              tool: entry.value,
            )),
          ],
        ],
      ),
    );
  }
}

class _ToolTile extends StatelessWidget {
  final String toolKey;
  final Tool tool;
  
  const _ToolTile({
    required this.toolKey,
    required this.tool,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final toolName = tool.name ?? toolKey.split(':').last;
    
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: colors.secondaryContainer,
        child: Icon(
          _getToolIcon(toolName),
          color: colors.onSecondaryContainer,
          size: 20,
        ),
      ),
      title: Text(toolName),
      subtitle: tool.description != null
          ? Text(
              tool.description!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            )
          : null,
      trailing: IconButton(
        icon: const Icon(Icons.info_outline),
        onPressed: () => _showToolDetails(context),
      ),
    );
  }
  
  IconData _getToolIcon(String toolName) {
    final name = toolName.toLowerCase();
    if (name.contains('file') || name.contains('list')) {
      return Icons.folder_open;
    } else if (name.contains('read')) {
      return Icons.description;
    } else if (name.contains('write') || name.contains('create')) {
      return Icons.edit_note;
    } else if (name.contains('search')) {
      return Icons.search;
    } else if (name.contains('delete')) {
      return Icons.delete_outline;
    } else if (name.contains('run') || name.contains('execute')) {
      return Icons.play_arrow;
    }
    return Icons.extension;
  }
  
  void _showToolDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tool.name ?? toolKey),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (tool.description != null) ...[
                Text(
                  'Description',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                Text(tool.description!),
                const SizedBox(height: 16),
              ],
              Text(
                'Tool Key',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: SelectableText(
                  toolKey,
                  style: const TextStyle(fontFamily: 'monospace'),
                ),
              ),
              if (tool.inputSchema != null) ...[
                const SizedBox(height: 16),
                Text(
                  'Parameters',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: SelectableText(
                    tool.inputSchema.toString(),
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
} 