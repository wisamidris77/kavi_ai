import 'package:flutter/material.dart';

import '../../providers/base/provider_type.dart';
import '../../providers/base/provider_type.dart' as types;
import '../../settings/controller/settings_controller.dart';
import '../../settings/models/app_settings.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key, required this.controller});

  final SettingsController controller;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    final AppSettings settings = widget.controller.settings;
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: AnimatedBuilder(
        animation: widget.controller,
        builder: (context, _) {
          final AppSettings s = widget.controller.settings;
          final enabledProviders = s.providers.entries.where((e) => e.value.enabled).map((e) => e.key).toList();
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('Active Provider', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              DropdownButtonFormField<AiProviderType>(
                value: s.activeProvider,
                items: AiProviderType.values
                    .map((t) => DropdownMenuItem(value: t, child: Text(_providerLabel(t))))
                    .toList(growable: false),
                onChanged: (v) {
                  if (v != null) widget.controller.setActiveProvider(v);
                },
                decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
              ),
              const SizedBox(height: 24),
              Text('Defaults', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      initialValue: s.defaultTemperature.toStringAsFixed(2),
                      decoration: const InputDecoration(labelText: 'Temperature', border: OutlineInputBorder(), isDense: true),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (v) {
                        final parsed = double.tryParse(v);
                        if (parsed != null) widget.controller.setDefaultTemperature(parsed.clamp(0.0, 2.0));
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      initialValue: s.defaultMaxTokens?.toString() ?? '',
                      decoration: const InputDecoration(labelText: 'Max tokens', border: OutlineInputBorder(), isDense: true),
                      keyboardType: TextInputType.number,
                      onChanged: (v) => widget.controller.setDefaultMaxTokens(int.tryParse(v.isEmpty ? '0' : v) == 0 ? null : int.tryParse(v)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text('Providers', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              ...AiProviderType.values.map((t) => _ProviderCard(type: t, controller: widget.controller)),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.check),
                label: const Text('Done'),
              ),
            ],
          );
        },
      ),
    );
  }

  String _providerLabel(AiProviderType t) {
    switch (t) {
      case types.AiProviderType.openAI:
        return 'OpenAI';
      case types.AiProviderType.deepSeek:
        return 'DeepSeek';
    }
  }
}

class _ProviderCard extends StatefulWidget {
  const _ProviderCard({required this.type, required this.controller});

  final AiProviderType type;
  final SettingsController controller;

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
    final ProviderSettings settings = widget.controller.settings.providers[widget.type] ??
        const ProviderSettings(enabled: false, apiKey: '');

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
                  onChanged: (v) => widget.controller.setProviderEnabled(widget.type, v),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextFormField(
              initialValue: settings.apiKey,
              decoration: const InputDecoration(labelText: 'API Key', border: OutlineInputBorder(), isDense: true),
              obscureText: true,
              onChanged: (v) => widget.controller.setApiKey(widget.type, v),
            ),
            const SizedBox(height: 8),
            TextFormField(
              initialValue: settings.baseUrl ?? '',
              decoration: const InputDecoration(labelText: 'Base URL (optional)', border: OutlineInputBorder(), isDense: true),
              onChanged: (v) => widget.controller.setBaseUrl(widget.type, v.isEmpty ? null : v),
            ),
            const SizedBox(height: 8),
            TextFormField(
              initialValue: settings.defaultModel ?? '',
              decoration: const InputDecoration(labelText: 'Default model (optional)', border: OutlineInputBorder(), isDense: true),
              onChanged: (v) => widget.controller.setDefaultModel(widget.type, v.isEmpty ? null : v),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ...settings.customModels.map((m) => InputChip(
                      label: Text(m),
                      onDeleted: () => widget.controller.removeCustomModel(widget.type, m),
                    )),
                SizedBox(
                  width: 220,
                  child: TextField(
                    controller: _newModelController,
                    decoration: const InputDecoration(hintText: 'Add custom model', isDense: true, border: OutlineInputBorder()),
                    onSubmitted: (v) {
                      if (v.trim().isNotEmpty) {
                        widget.controller.addCustomModel(widget.type, v.trim());
                        _newModelController.clear();
                        setState(() {});
                      }
                    },
                  ),
                ),
              ],
            ),
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
    }
  }
} 