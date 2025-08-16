import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CommandPalette extends StatefulWidget {
  final List<CommandAction> actions;
  final VoidCallback? onClose;

  const CommandPalette({
    super.key,
    required this.actions,
    this.onClose,
  });

  @override
  State<CommandPalette> createState() => _CommandPaletteState();
}

class _CommandPaletteState extends State<CommandPalette>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  List<CommandAction> _filteredActions = [];
  int _selectedIndex = 0;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _filteredActions = widget.actions;
    _animationController.forward();
    _searchFocusNode.requestFocus();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _filterActions(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
      _selectedIndex = 0;
      
      if (query.isEmpty) {
        _filteredActions = widget.actions;
      } else {
        _filteredActions = widget.actions.where((action) {
          return action.title.toLowerCase().contains(query) ||
                 action.description.toLowerCase().contains(query) ||
                 action.keywords.any((keyword) => keyword.toLowerCase().contains(query));
        }).toList();
      }
    });
  }

  void _selectNext() {
    if (_filteredActions.isEmpty) return;
    setState(() {
      _selectedIndex = (_selectedIndex + 1) % _filteredActions.length;
    });
  }

  void _selectPrevious() {
    if (_filteredActions.isEmpty) return;
    setState(() {
      _selectedIndex = _selectedIndex == 0 
          ? _filteredActions.length - 1 
          : _selectedIndex - 1;
    });
  }

  void _executeSelected() {
    if (_filteredActions.isEmpty) return;
    final action = _filteredActions[_selectedIndex];
    action.onExecute();
    widget.onClose?.call();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Material(
          color: Colors.black54,
          child: Center(
            child: Container(
              width: 600,
              height: 400,
              margin: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceVariant,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.search,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            focusNode: _searchFocusNode,
                            decoration: InputDecoration(
                              hintText: 'Search commands...',
                              border: InputBorder.none,
                              hintStyle: TextStyle(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            style: theme.textTheme.titleMedium,
                            onChanged: _filterActions,
                            onSubmitted: (_) => _executeSelected(),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: widget.onClose,
                          tooltip: 'Close (Esc)',
                        ),
                      ],
                    ),
                  ),
                  
                  // Actions list
                  Expanded(
                    child: _filteredActions.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.search_off,
                                  size: 48,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No commands found',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                if (_searchQuery.isNotEmpty)
                                  Text(
                                    'Try a different search term',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: _filteredActions.length,
                            itemBuilder: (context, index) {
                              final action = _filteredActions[index];
                              final isSelected = index == _selectedIndex;
                              
                              return Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () {
                                    setState(() {
                                      _selectedIndex = index;
                                    });
                                    _executeSelected();
                                  },
                                  onHover: (hovering) {
                                    if (hovering) {
                                      setState(() {
                                        _selectedIndex = index;
                                      });
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: isSelected 
                                          ? colorScheme.primaryContainer
                                          : Colors.transparent,
                                      border: Border(
                                        bottom: BorderSide(
                                          color: colorScheme.outlineVariant,
                                          width: 0.5,
                                        ),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            color: isSelected
                                                ? colorScheme.primary
                                                : colorScheme.surfaceVariant,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Icon(
                                            action.icon,
                                            color: isSelected
                                                ? colorScheme.onPrimary
                                                : colorScheme.onSurfaceVariant,
                                            size: 20,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                action.title,
                                                style: theme.textTheme.titleSmall?.copyWith(
                                                  fontWeight: FontWeight.w600,
                                                  color: isSelected
                                                      ? colorScheme.onPrimaryContainer
                                                      : colorScheme.onSurface,
                                                ),
                                              ),
                                              if (action.description.isNotEmpty) ...[
                                                const SizedBox(height: 4),
                                                Text(
                                                  action.description,
                                                  style: theme.textTheme.bodySmall?.copyWith(
                                                    color: isSelected
                                                        ? colorScheme.onPrimaryContainer.withOpacity(0.8)
                                                        : colorScheme.onSurfaceVariant,
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                        if (action.shortcut != null)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: colorScheme.surfaceVariant,
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              action.shortcut!,
                                              style: theme.textTheme.bodySmall?.copyWith(
                                                color: colorScheme.onSurfaceVariant,
                                                fontFamily: 'monospace',
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                  
                  // Footer
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceVariant,
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(16),
                        bottomRight: Radius.circular(16),
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(
                          '${_filteredActions.length} command${_filteredActions.length == 1 ? '' : 's'}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const Spacer(),
                        Row(
                          children: [
                            _ShortcutHint(
                              keys: ['↑', '↓'],
                              description: 'Navigate',
                            ),
                            const SizedBox(width: 16),
                            _ShortcutHint(
                              keys: ['Enter'],
                              description: 'Execute',
                            ),
                            const SizedBox(width: 16),
                            _ShortcutHint(
                              keys: ['Esc'],
                              description: 'Close',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ShortcutHint extends StatelessWidget {
  final List<String> keys;
  final String description;

  const _ShortcutHint({
    required this.keys,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...keys.map((key) => Container(
          margin: const EdgeInsets.only(right: 4),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: colorScheme.outline),
          ),
          child: Text(
            key,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface,
              fontFamily: 'monospace',
              fontWeight: FontWeight.w600,
            ),
          ),
        )),
        const SizedBox(width: 4),
        Text(
          description,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class CommandAction {
  final String title;
  final String description;
  final IconData icon;
  final VoidCallback onExecute;
  final String? shortcut;
  final List<String> keywords;

  const CommandAction({
    required this.title,
    required this.description,
    required this.icon,
    required this.onExecute,
    this.shortcut,
    this.keywords = const [],
  });
}

class CommandPaletteController {
  static void show(
    BuildContext context, {
    required List<CommandAction> actions,
  }) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => CommandPalette(
        actions: actions,
        onClose: () => Navigator.of(context).pop(),
      ),
    );
  }
}