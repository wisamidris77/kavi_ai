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

    final shortcutMap = <ShortcutActivator, Intent>{};
    final actions = <Type, Action<Intent>>{};
    
    for (final entry in shortcuts.entries) {
      final intent = CallbackIntent(entry.value);
      shortcutMap[entry.key.activator] = intent;
      actions[intent.runtimeType] = CallbackAction<CallbackIntent>(
        onInvoke: (intent) => intent.callback(),
      );
    }

    return Shortcuts(
      shortcuts: shortcutMap,
      child: Actions(
        actions: actions,
        child: child,
      ),
    );
  }
}

class CallbackIntent extends Intent {
  final VoidCallback callback;
  const CallbackIntent(this.callback);
}

class ShortcutKey {
  final ShortcutActivator activator;
  final String description;
  final String category;

  const ShortcutKey({
    required this.activator,
    required this.description,
    required this.category,
  });

  String get displayText {
    if (activator is SingleActivator) {
      final single = activator as SingleActivator;
      final parts = <String>[];
      
      if (single.control) parts.add('Ctrl');
      if (single.meta) parts.add('Cmd');
      if (single.alt) parts.add('Alt');
      if (single.shift) parts.add('Shift');
      
      final key = single.trigger;
      if (key == LogicalKeyboardKey.enter) {
        parts.add('Enter');
      } else if (key == LogicalKeyboardKey.escape) {
        parts.add('Esc');
      } else if (key == LogicalKeyboardKey.tab) {
        parts.add('Tab');
      } else if (key == LogicalKeyboardKey.space) {
        parts.add('Space');
      } else if (key == LogicalKeyboardKey.delete) {
        parts.add('Delete');
      } else if (key == LogicalKeyboardKey.backspace) {
        parts.add('Backspace');
      } else if (key == LogicalKeyboardKey.comma) {
        parts.add(',');
      } else if (key == LogicalKeyboardKey.slash) {
        parts.add('/');
      } else {
        parts.add(key.keyLabel);
      }
      
      return parts.join('+');
    }
    return 'Unknown';
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

  List<ShortcutKey> getShortcutsForCategory(String category) {
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
    activator: SingleActivator(LogicalKeyboardKey.keyN, control: true),
    description: 'New Chat',
    category: 'Navigation',
  );

  static const openSettings = ShortcutKey(
    activator: SingleActivator(LogicalKeyboardKey.comma, control: true),
    description: 'Open Settings',
    category: 'Navigation',
  );

  static const openCommandPalette = ShortcutKey(
    activator: SingleActivator(LogicalKeyboardKey.keyK, control: true),
    description: 'Open Command Palette',
    category: 'Navigation',
  );

  static const openMCPTools = ShortcutKey(
    activator: SingleActivator(LogicalKeyboardKey.keyT, control: true),
    description: 'Open MCP Tools',
    category: 'Navigation',
  );

  // Chat Actions
  static const sendMessage = ShortcutKey(
    activator: SingleActivator(LogicalKeyboardKey.enter),
    description: 'Send Message',
    category: 'Chat',
  );

  static const sendMessageShift = ShortcutKey(
    activator: SingleActivator(LogicalKeyboardKey.enter, shift: true),
    description: 'New Line',
    category: 'Chat',
  );

  static const stopGeneration = ShortcutKey(
    activator: SingleActivator(LogicalKeyboardKey.escape),
    description: 'Stop Generation',
    category: 'Chat',
  );

  static const regenerateResponse = ShortcutKey(
    activator: SingleActivator(LogicalKeyboardKey.keyR, control: true),
    description: 'Regenerate Response',
    category: 'Chat',
  );

  // Message Actions
  static const copyMessage = ShortcutKey(
    activator: SingleActivator(LogicalKeyboardKey.keyC, control: true),
    description: 'Copy Message',
    category: 'Messages',
  );

  static const editMessage = ShortcutKey(
    activator: SingleActivator(LogicalKeyboardKey.keyE),
    description: 'Edit Message',
    category: 'Messages',
  );

  static const deleteMessage = ShortcutKey(
    activator: SingleActivator(LogicalKeyboardKey.delete),
    description: 'Delete Message',
    category: 'Messages',
  );

  static const pinMessage = ShortcutKey(
    activator: SingleActivator(LogicalKeyboardKey.keyP, control: true),
    description: 'Pin Message',
    category: 'Messages',
  );

  // Search
  static const searchMessages = ShortcutKey(
    activator: SingleActivator(LogicalKeyboardKey.keyF, control: true),
    description: 'Search Messages',
    category: 'Search',
  );

  static const searchNext = ShortcutKey(
    activator: SingleActivator(LogicalKeyboardKey.f3),
    description: 'Next Search Result',
    category: 'Search',
  );

  static const searchPrevious = ShortcutKey(
    activator: SingleActivator(LogicalKeyboardKey.f3, shift: true),
    description: 'Previous Search Result',
    category: 'Search',
  );

  // File Operations
  static const attachFile = ShortcutKey(
    activator: SingleActivator(LogicalKeyboardKey.keyU, control: true),
    description: 'Attach File',
    category: 'Files',
  );

  static const exportChat = ShortcutKey(
    activator: SingleActivator(LogicalKeyboardKey.keyE, control: true),
    description: 'Export Chat',
    category: 'Files',
  );

  // View
  static const toggleSidebar = ShortcutKey(
    activator: SingleActivator(LogicalKeyboardKey.keyB, control: true),
    description: 'Toggle Sidebar',
    category: 'View',
  );

  static const toggleTheme = ShortcutKey(
    activator: SingleActivator(LogicalKeyboardKey.keyJ, control: true),
    description: 'Toggle Theme',
    category: 'View',
  );

  static const zoomIn = ShortcutKey(
    activator: SingleActivator(LogicalKeyboardKey.equal, control: true),
    description: 'Zoom In',
    category: 'View',
  );

  static const zoomOut = ShortcutKey(
    activator: SingleActivator(LogicalKeyboardKey.minus, control: true),
    description: 'Zoom Out',
    category: 'View',
  );

  static const resetZoom = ShortcutKey(
    activator: SingleActivator(LogicalKeyboardKey.digit0, control: true),
    description: 'Reset Zoom',
    category: 'View',
  );

  // System
  static const quit = ShortcutKey(
    activator: SingleActivator(LogicalKeyboardKey.keyQ, control: true),
    description: 'Quit Application',
    category: 'System',
  );

  static const help = ShortcutKey(
    activator: SingleActivator(LogicalKeyboardKey.f1),
    description: 'Show Help',
    category: 'System',
  );

  static const about = ShortcutKey(
    activator: SingleActivator(LogicalKeyboardKey.keyI, control: true),
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
                color: colorScheme.surfaceContainerHighest,
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
                                color: colorScheme.surfaceContainerHighest,
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
            color: colorScheme.surfaceContainerHighest,
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