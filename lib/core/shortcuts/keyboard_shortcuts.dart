import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class KeyboardShortcuts extends StatelessWidget {
  final Widget child;
  final Map<ShortcutKey, VoidCallback> shortcuts;
  final bool enabled;

  const KeyboardShortcuts({
    super.key,
    required this.child,
    required this.shortcuts,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;

    final shortcutMap = <LogicalKeySet, VoidCallback>{};
    
    for (final entry in shortcuts.entries) {
      shortcutMap[entry.key.logicalKeySet] = entry.value;
    }

    return Shortcuts(
      shortcuts: shortcutMap,
      child: Actions(
        actions: shortcutMap.map((key, callback) => MapEntry(
          key,
          CallbackAction<ShortcutKey>(onInvoke: (_) => callback()),
        )),
        child: child,
      ),
    );
  }
}

class ShortcutKey {
  final LogicalKeySet logicalKeySet;
  final String description;
  final String category;

  const ShortcutKey({
    required this.logicalKeySet,
    required this.description,
    required this.category,
  });

  String get displayText {
    final keys = logicalKeySet.keys.map((key) => _getKeyDisplay(key)).join(' + ');
    return keys;
  }

  String _getKeyDisplay(LogicalKeyboardKey key) {
    if (key == LogicalKeyboardKey.control) return 'Ctrl';
    if (key == LogicalKeyboardKey.meta) return 'Cmd';
    if (key == LogicalKeyboardKey.shift) return 'Shift';
    if (key == LogicalKeyboardKey.alt) return 'Alt';
    if (key == LogicalKeyboardKey.enter) return 'Enter';
    if (key == LogicalKeyboardKey.escape) return 'Esc';
    if (key == LogicalKeyboardKey.backspace) return 'Backspace';
    if (key == LogicalKeyboardKey.delete) return 'Delete';
    if (key == LogicalKeyboardKey.arrowUp) return '↑';
    if (key == LogicalKeyboardKey.arrowDown) return '↓';
    if (key == LogicalKeyboardKey.arrowLeft) return '←';
    if (key == LogicalKeyboardKey.arrowRight) return '→';
    if (key == LogicalKeyboardKey.home) return 'Home';
    if (key == LogicalKeyboardKey.end) return 'End';
    if (key == LogicalKeyboardKey.pageUp) return 'Page Up';
    if (key == LogicalKeyboardKey.pageDown) return 'Page Down';
    if (key == LogicalKeyboardKey.tab) return 'Tab';
    if (key == LogicalKeyboardKey.space) return 'Space';
    
    // Handle letter keys
    if (key.keyLabel != null) {
      return key.keyLabel!.toUpperCase();
    }
    
    return key.debugName ?? 'Unknown';
  }
}

class KeyboardShortcutManager extends ChangeNotifier {
  static final KeyboardShortcutManager _instance = KeyboardShortcutManager._internal();
  factory KeyboardShortcutManager() => _instance;
  KeyboardShortcutManager._internal();

  final Map<String, ShortcutKey> _shortcuts = {};
  final Map<String, VoidCallback> _actions = {};
  bool _enabled = true;

  bool get enabled => _enabled;
  Map<String, ShortcutKey> get shortcuts => Map.unmodifiable(_shortcuts);

  void setEnabled(bool enabled) {
    _enabled = enabled;
    notifyListeners();
  }

  void registerShortcut(String id, ShortcutKey shortcut, VoidCallback action) {
    _shortcuts[id] = shortcut;
    _actions[id] = action;
    notifyListeners();
  }

  void unregisterShortcut(String id) {
    _shortcuts.remove(id);
    _actions.remove(id);
    notifyListeners();
  }

  void executeShortcut(String id) {
    if (_enabled && _actions.containsKey(id)) {
      _actions[id]!();
    }
  }

  List<ShortcutKey> getShortcutsByCategory(String category) {
    return _shortcuts.values.where((shortcut) => shortcut.category == category).toList();
  }

  Map<String, List<ShortcutKey>> getShortcutsByCategory() {
    final categories = <String, List<ShortcutKey>>{};
    for (final shortcut in _shortcuts.values) {
      categories.putIfAbsent(shortcut.category, () => []).add(shortcut);
    }
    return categories;
  }
}

// Predefined shortcut keys
class AppShortcuts {
  // Navigation
  static const newChat = ShortcutKey(
    logicalKeySet: LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyN),
    description: 'New Chat',
    category: 'Navigation',
  );

  static const openSettings = ShortcutKey(
    logicalKeySet: LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.comma),
    description: 'Open Settings',
    category: 'Navigation',
  );

  static const openCommandPalette = ShortcutKey(
    logicalKeySet: LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyK),
    description: 'Open Command Palette',
    category: 'Navigation',
  );

  static const openMCPTools = ShortcutKey(
    logicalKeySet: LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyT),
    description: 'Open MCP Tools',
    category: 'Navigation',
  );

  // Chat Actions
  static const sendMessage = ShortcutKey(
    logicalKeySet: LogicalKeySet(LogicalKeyboardKey.enter),
    description: 'Send Message',
    category: 'Chat',
  );

  static const sendMessageShift = ShortcutKey(
    logicalKeySet: LogicalKeySet(LogicalKeyboardKey.shift, LogicalKeyboardKey.enter),
    description: 'New Line',
    category: 'Chat',
  );

  static const stopGeneration = ShortcutKey(
    logicalKeySet: LogicalKeySet(LogicalKeyboardKey.escape),
    description: 'Stop Generation',
    category: 'Chat',
  );

  static const regenerateResponse = ShortcutKey(
    logicalKeySet: LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyR),
    description: 'Regenerate Response',
    category: 'Chat',
  );

  // Message Actions
  static const copyMessage = ShortcutKey(
    logicalKeySet: LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyC),
    description: 'Copy Message',
    category: 'Messages',
  );

  static const editMessage = ShortcutKey(
    logicalKeySet: LogicalKeySet(LogicalKeyboardKey.keyE),
    description: 'Edit Message',
    category: 'Messages',
  );

  static const deleteMessage = ShortcutKey(
    logicalKeySet: LogicalKeySet(LogicalKeyboardKey.delete),
    description: 'Delete Message',
    category: 'Messages',
  );

  static const pinMessage = ShortcutKey(
    logicalKeySet: LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyP),
    description: 'Pin Message',
    category: 'Messages',
  );

  // Search
  static const searchMessages = ShortcutKey(
    logicalKeySet: LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyF),
    description: 'Search Messages',
    category: 'Search',
  );

  static const searchNext = ShortcutKey(
    logicalKeySet: LogicalKeySet(LogicalKeyboardKey.keyF3),
    description: 'Next Search Result',
    category: 'Search',
  );

  static const searchPrevious = ShortcutKey(
    logicalKeySet: LogicalKeySet(LogicalKeyboardKey.shift, LogicalKeyboardKey.keyF3),
    description: 'Previous Search Result',
    category: 'Search',
  );

  // File Operations
  static const attachFile = ShortcutKey(
    logicalKeySet: LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyU),
    description: 'Attach File',
    category: 'Files',
  );

  static const exportChat = ShortcutKey(
    logicalKeySet: LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyE),
    description: 'Export Chat',
    category: 'Files',
  );

  // View
  static const toggleSidebar = ShortcutKey(
    logicalKeySet: LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyB),
    description: 'Toggle Sidebar',
    category: 'View',
  );

  static const toggleTheme = ShortcutKey(
    logicalKeySet: LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyJ),
    description: 'Toggle Theme',
    category: 'View',
  );

  static const zoomIn = ShortcutKey(
    logicalKeySet: LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.equal),
    description: 'Zoom In',
    category: 'View',
  );

  static const zoomOut = ShortcutKey(
    logicalKeySet: LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.minus),
    description: 'Zoom Out',
    category: 'View',
  );

  static const resetZoom = ShortcutKey(
    logicalKeySet: LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.digit0),
    description: 'Reset Zoom',
    category: 'View',
  );

  // System
  static const quit = ShortcutKey(
    logicalKeySet: LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyQ),
    description: 'Quit Application',
    category: 'System',
  );

  static const help = ShortcutKey(
    logicalKeySet: LogicalKeySet(LogicalKeyboardKey.f1),
    description: 'Show Help',
    category: 'System',
  );

  static const about = ShortcutKey(
    logicalKeySet: LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyI),
    description: 'About',
    category: 'System',
  );
}

class ShortcutsHelpDialog extends StatelessWidget {
  const ShortcutsHelpDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final shortcutManager = KeyboardShortcutManager();
    final shortcutsByCategory = shortcutManager.getShortcutsByCategory();

    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 500),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surfaceVariant,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.keyboard, color: colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Keyboard Shortcuts',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: shortcutsByCategory.length,
                itemBuilder: (context, index) {
                  final category = shortcutsByCategory.keys.elementAt(index);
                  final shortcuts = shortcutsByCategory[category]!;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...shortcuts.map((shortcut) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceVariant,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: colorScheme.outline),
                              ),
                              child: Text(
                                shortcut.displayText,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontFamily: 'monospace',
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                shortcut.description,
                                style: theme.textTheme.bodyMedium,
                              ),
                            ),
                          ],
                        ),
                      )),
                      const SizedBox(height: 16),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ShortcutIndicator extends StatelessWidget {
  final ShortcutKey shortcut;
  final bool showDescription;

  const ShortcutIndicator({
    super.key,
    required this.shortcut,
    this.showDescription = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: colorScheme.surfaceVariant,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: colorScheme.outline),
          ),
          child: Text(
            shortcut.displayText,
            style: theme.textTheme.bodySmall?.copyWith(
              fontFamily: 'monospace',
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        if (showDescription) ...[
          const SizedBox(width: 8),
          Text(
            shortcut.description,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}