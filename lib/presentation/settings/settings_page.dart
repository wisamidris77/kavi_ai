import 'package:flutter/material.dart';

import '../../providers/base/provider_type.dart';
import '../../settings/controller/settings_controller.dart';
import '../../settings/models/app_settings.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key, required this.controller});

  final SettingsController controller;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late AppSettings _draft;
  late AppSettings _original;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _draft = widget.controller.settings;
    _original = widget.controller.settings;
  }

  void _save() {
    widget.controller.replaceSettings(_draft, persist: true);
    _original = _draft;
    Navigator.of(context).pop();
  }

  void _reset() {
    setState(() => _draft = _original);
    widget.controller.replaceSettings(_original, persist: false);
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final bool isWide = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final EdgeInsets pad = const EdgeInsets.all(16);
          final List<Widget> left = <Widget>[
            _SectionHeader(title: 'Appearance'),
            _ThemeModeSelector(
              mode: _draft.themeMode,
              onChanged: (mode) {
                setState(() => _draft = _draft.copyWith(themeMode: mode));
                widget.controller.replaceSettings(_draft, persist: false);
              },
            ),
            const SizedBox(height: 12),
            _ColorSeedGrid(
              selectedColor: Color(_draft.primaryColorSeed),
              onSelect: (c) {
                setState(() => _draft = _draft.copyWith(primaryColorSeed: c.value));
                widget.controller.replaceSettings(_draft, persist: false);
              },
            ),
            const SizedBox(height: 24),
            _SectionHeader(title: 'Defaults'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    key: const ValueKey('temperature'),
                    initialValue: _draft.defaultTemperature.toStringAsFixed(2),
                    decoration: const InputDecoration(labelText: 'Temperature', border: OutlineInputBorder(), isDense: true),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (v) {
                      final parsed = double.tryParse(v);
                      if (parsed != null) setState(() => _draft = _draft.copyWith(defaultTemperature: parsed.clamp(0.0, 2.0)));
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    key: const ValueKey('max_tokens'),
                    initialValue: _draft.defaultMaxTokens?.toString() ?? '',
                    decoration: const InputDecoration(labelText: 'Max tokens', border: OutlineInputBorder(), isDense: true),
                    keyboardType: TextInputType.number,
                    onChanged: (v) {
                      final int? parsed = int.tryParse(v.isEmpty ? '0' : v);
                      setState(() => _draft = _draft.copyWith(defaultMaxTokens: parsed == null || parsed == 0 ? null : parsed));
                    },
                  ),
                ),
              ],
            ),
          ];

          final List<Widget> right = <Widget>[
            _SectionHeader(title: 'Providers'),
            const SizedBox(height: 8),
            _ActiveProviderSelector(
              value: _draft.activeProvider,
              onChanged: (v) {
                setState(() => _draft = _draft.copyWith(activeProvider: v));
                widget.controller.replaceSettings(_draft, persist: true);
              },
            ),
            const SizedBox(height: 12),
            ...AiProviderType.values.map((t) => _ProviderCard(
                  type: t,
                  settings: _draft.providers[t] ?? const ProviderSettings(enabled: false, apiKey: ''),
                  onChanged: (updated) {
                    final current = Map<AiProviderType, ProviderSettings>.from(_draft.providers);
                    current[t] = updated;
                    setState(() => _draft = _draft.copyWith(providers: current));
                    // Apply and save changes immediately
                    widget.controller.replaceSettings(_draft, persist: true);
                  },
                )),
            const SizedBox(height: 24),
            _SectionHeader(title: 'MCP Integration'),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.extension),
              title: const Text('MCP Settings'),
              subtitle: const Text('Configure Model Context Protocol servers'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                // Navigate to MCP settings if route is available
                Navigator.pushNamed(context, '/mcp-settings').catchError((e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('MCP Settings route not configured. Use main_with_mcp.dart'),
                    ),
                  );
                  return Future.value();
                });
              },
            ),
          ];

          return SafeArea(
            child: Form(
              key: _formKey,
              child: Stack(
                children: [
                  SingleChildScrollView(
                    padding: pad.copyWith(bottom: 96),
                    child: isWide
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: left)),
                              const SizedBox(width: 16),
                              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: right)),
                            ],
                          )
                        : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            ...left,
                            const SizedBox(height: 24),
                            ...right,
                          ]),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        border: Border(top: BorderSide(color: colors.outlineVariant)),
                      ),
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12 + 8),
                      child: SafeArea(
                        top: false,
                        child: Row(
                          children: [
                            TextButton.icon(
                              onPressed: _reset,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Reset changes'),
                            ),
                            const Spacer(),
                            FilledButton.icon(
                              onPressed: _save,
                              icon: const Icon(Icons.save_outlined),
                              label: const Text('Save'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(title, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}

class _ThemeModeSelector extends StatelessWidget {
  final ThemeMode mode;
  final ValueChanged<ThemeMode> onChanged;
  const _ThemeModeSelector({required this.mode, required this.onChanged});
  @override
  Widget build(BuildContext context) {
    return SegmentedButton<ThemeMode>(
      segments: const <ButtonSegment<ThemeMode>>[
        ButtonSegment(value: ThemeMode.system, label: Text('System'), icon: Icon(Icons.computer)),
        ButtonSegment(value: ThemeMode.light, label: Text('Light'), icon: Icon(Icons.light_mode)),
        ButtonSegment(value: ThemeMode.dark, label: Text('Dark'), icon: Icon(Icons.dark_mode)),
      ],
      selected: {mode},
      onSelectionChanged: (s) => onChanged(s.first),
    );
  }
}

class _ColorSeedGrid extends StatelessWidget {
  final Color selectedColor;
  final ValueChanged<Color> onSelect;
  const _ColorSeedGrid({required this.selectedColor, required this.onSelect});

  static const List<Color> _choices = <Color>[
    Color(0xFF2962FF), // Blue A700
    Color(0xFF00C853), // Green A700
    Color(0xFFFFAB00), // Amber A700
    Color(0xFFD50000), // Red A700
    Color(0xFFAA00FF), // Purple A700
    Color(0xFF00BFA5), // Teal A700
    Color(0xFF6200EE), // Deep Purple
    Color(0xFF1E88E5), // Blue 600
    Color(0xFF43A047), // Green 600
    Color(0xFFF4511E), // Deep Orange 600
  ];

  @override
  Widget build(BuildContext context) {
    final double maxWidth = MediaQuery.of(context).size.width;
    final int columns = maxWidth >= 900 ? 10 : 5;
    return GridView.count(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      crossAxisCount: columns,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      children: _choices.map((c) {
        final bool isSelected = c.value == selectedColor.value;
        return InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => onSelect(c),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).dividerColor,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: c,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                if (isSelected)
                  const Align(
                    alignment: Alignment.center,
                    child: Icon(Icons.check, color: Colors.white),
                  ),
              ],
            ),
          ),
        );
      }).toList(growable: false),
    );
  }
}

class _ProviderCard extends StatefulWidget {
  const _ProviderCard({required this.type, required this.settings, required this.onChanged});

  final AiProviderType type;
  final ProviderSettings settings;
  final ValueChanged<ProviderSettings> onChanged;

  @override
  State<_ProviderCard> createState() => _ProviderCardState();
}

class _ProviderCardState extends State<_ProviderCard> {
  final TextEditingController _newModelController = TextEditingController();

  @override
  void dispose() {
    _newModelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ProviderSettings settings = widget.settings;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(_title(widget.type), style: Theme.of(context).textTheme.titleMedium),
                ),
                Switch(
                  value: settings.enabled,
                  onChanged: (v) => widget.onChanged(settings.copyWith(enabled: v)),
                ),
              ],
            ),
            if (widget.type == AiProviderType.mock) ...[
              const SizedBox(height: 8),
              const Text('Uses built-in mock responses. No API key required.'),
            ] else if (widget.type == AiProviderType.ollama) ...[
              const SizedBox(height: 8),
              const Text('Local Ollama instance. No API key required.'),
            ] else ...[
            if (widget.type != AiProviderType.ollama) ...[
              const SizedBox(height: 8),
              TextFormField(
                initialValue: settings.apiKey,
                decoration: const InputDecoration(labelText: 'API Key', border: OutlineInputBorder(), isDense: true),
                obscureText: true,
                onChanged: (v) => widget.onChanged(settings.copyWith(apiKey: v)),
              ),
            ],
            const SizedBox(height: 8),
            TextFormField(
              initialValue: settings.baseUrl ?? '',
              decoration: const InputDecoration(
                labelText: 'Base URL (optional)', 
                border: OutlineInputBorder(), 
                isDense: true,
                hintText: 'Leave empty for default',
              ),
              onChanged: (v) {
                final trimmed = v.trim();
                // Filter out invalid partial URLs
                if (trimmed.isEmpty || 
                    trimmed == 'http' || 
                    trimmed == 'https' ||
                    trimmed == 'http:' ||
                    trimmed == 'https:' ||
                    trimmed == 'http://' ||
                    trimmed == 'https://') {
                  widget.onChanged(settings.copyWith(baseUrl: null));
                } else {
                  widget.onChanged(settings.copyWith(baseUrl: trimmed));
                }
              },
            ),
            const SizedBox(height: 8),
            TextFormField(
              initialValue: settings.defaultModel ?? '',
              decoration: const InputDecoration(labelText: 'Default model (optional)', border: OutlineInputBorder(), isDense: true),
              onChanged: (v) => widget.onChanged(settings.copyWith(defaultModel: v.isEmpty ? null : v)),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ...settings.customModels.map((m) => InputChip(
                      label: Text(m),
                      onDeleted: () {
                        final updated = List<String>.from(settings.customModels)..remove(m);
                        widget.onChanged(settings.copyWith(customModels: updated));
                      },
                    )),
                SizedBox(
                  width: 220,
                  child: TextField(
                    controller: _newModelController,
                    decoration: const InputDecoration(hintText: 'Add custom model', isDense: true, border: OutlineInputBorder()),
                    onSubmitted: (v) {
                      if (v.trim().isNotEmpty) {
                        final updated = List<String>.from(settings.customModels);
                        if (!updated.contains(v.trim())) {
                          updated.add(v.trim());
                          widget.onChanged(settings.copyWith(customModels: updated));
                        }
                        _newModelController.clear();
                        setState(() {});
                      }
                    },
                  ),
                ),
              ],
            ),
            ],
          ],
        ),
      ),
    );
  }

  String _title(AiProviderType t) {
    switch (t) {
      case AiProviderType.openAI:
        return 'OpenAI';
      case AiProviderType.deepSeek:
        return 'DeepSeek';
      case AiProviderType.ollama:
        return 'Ollama';
      case AiProviderType.mock:
        return 'Mock';
    }
  }
}

class _ActiveProviderSelector extends StatelessWidget {
  final AiProviderType value;
  final ValueChanged<AiProviderType> onChanged;
  const _ActiveProviderSelector({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<AiProviderType>(
      segments: const <ButtonSegment<AiProviderType>>[
        ButtonSegment(value: AiProviderType.openAI, label: Text('OpenAI'), icon: Icon(Icons.api)),
        ButtonSegment(value: AiProviderType.deepSeek, label: Text('DeepSeek'), icon: Icon(Icons.bolt)),
        ButtonSegment(value: AiProviderType.ollama, label: Text('Ollama'), icon: Icon(Icons.computer)),
        ButtonSegment(value: AiProviderType.mock, label: Text('Mock'), icon: Icon(Icons.smart_toy_outlined)),
      ],
      selected: {value},
      onSelectionChanged: (s) => onChanged(s.first),
    );
  }
} 