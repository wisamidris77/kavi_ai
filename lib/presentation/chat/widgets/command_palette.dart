import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CommandAction {
  final String id;
  final String label;
  final String? description;
  final IconData? icon;
  final List<String> shortcuts;
  final VoidCallback action;
  final bool Function()? isEnabled;

  const CommandAction({
    required this.id,
    required this.label,
    this.description,
    this.icon,
    this.shortcuts = const [],
    required this.action,
    this.isEnabled,
  });
}

class CommandPalette extends StatefulWidget {
  final List<CommandAction> actions;
  
  const CommandPalette({
    super.key,
    required this.actions,
  });

  static Future<void> show(BuildContext context, List<CommandAction> actions) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black54,
      builder: (context) => CommandPalette(actions: actions),
    );
  }

  @override
  State<CommandPalette> createState() => _CommandPaletteState();
}

class _CommandPaletteState extends State<CommandPalette> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<CommandAction> _filteredActions = [];
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _filteredActions = widget.actions;
    _searchController.addListener(_onSearchChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredActions = widget.actions;
      } else {
        _filteredActions = widget.actions.where((action) {
          return action.label.toLowerCase().contains(query) ||
              (action.description?.toLowerCase().contains(query) ?? false) ||
              action.shortcuts.any((s) => s.toLowerCase().contains(query));
        }).toList();
      }
      _selectedIndex = 0;
    });
  }

  void _executeAction(CommandAction action) {
    if (action.isEnabled?.call() ?? true) {
      Navigator.of(context).pop();
      action.action();
    }
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        setState(() {
          _selectedIndex = (_selectedIndex + 1) % _filteredActions.length;
        });
      } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        setState(() {
          _selectedIndex = (_selectedIndex - 1 + _filteredActions.length) % _filteredActions.length;
        });
      } else if (event.logicalKey == LogicalKeyboardKey.enter) {
        if (_filteredActions.isNotEmpty) {
          _executeAction(_filteredActions[_selectedIndex]);
        }
      } else if (event.logicalKey == LogicalKeyboardKey.escape) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    
    return KeyboardListener(
      focusNode: FocusNode(),
      onKeyEvent: _handleKeyEvent,
      child: Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          width: 600,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: colors.shadow.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Search field
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: colors.outlineVariant),
                  ),
                ),
                child: TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  decoration: InputDecoration(
                    hintText: 'Type a command or search...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: colors.surfaceVariant,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
              
              // Actions list
              Flexible(
                child: _filteredActions.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.search_off,
                                size: 48,
                                color: colors.outline,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No commands found',
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: colors.outline,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: _filteredActions.length,
                        itemBuilder: (context, index) {
                          final action = _filteredActions[index];
                          final isEnabled = action.isEnabled?.call() ?? true;
                          final isSelected = index == _selectedIndex;
                          
                          return Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: isEnabled ? () => _executeAction(action) : null,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                color: isSelected
                                    ? colors.primaryContainer.withOpacity(0.3)
                                    : null,
                                child: Row(
                                  children: [
                                    if (action.icon != null) ...[
                                      Icon(
                                        action.icon,
                                        size: 20,
                                        color: isEnabled
                                            ? (isSelected
                                                ? colors.primary
                                                : colors.onSurfaceVariant)
                                            : colors.outline,
                                      ),
                                      const SizedBox(width: 12),
                                    ],
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            action.label,
                                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                              color: isEnabled
                                                  ? (isSelected
                                                      ? colors.primary
                                                      : colors.onSurface)
                                                  : colors.outline,
                                              fontWeight: isSelected
                                                  ? FontWeight.w600
                                                  : FontWeight.normal,
                                            ),
                                          ),
                                          if (action.description != null) ...[
                                            const SizedBox(height: 2),
                                            Text(
                                              action.description!,
                                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                color: isEnabled
                                                    ? colors.onSurfaceVariant
                                                    : colors.outline,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    if (action.shortcuts.isNotEmpty)
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: action.shortcuts.map((shortcut) {
                                          return Container(
                                            margin: const EdgeInsets.only(left: 4),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: colors.surfaceVariant,
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              shortcut,
                                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                                color: colors.onSurfaceVariant,
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 