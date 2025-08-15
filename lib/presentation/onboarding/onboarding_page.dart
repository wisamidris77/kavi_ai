import 'package:flutter/material.dart';

import '../../providers/base/provider_type.dart';
import '../../settings/controller/settings_controller.dart';
import '../../settings/models/app_settings.dart';
import '../chat/chat_ai_page.dart';
import '../../mcp/controller/mcp_controller.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({
    super.key, 
    required this.controller,
    required this.mcpController,
  });

  final SettingsController controller;
  final McpController mcpController;

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  int _currentStep = 0;
  late AppSettings _draft;
  late AiProviderType _activeProviderDraft;
  final TextEditingController _apiKeyController = TextEditingController();
  final TextEditingController _baseUrlController = TextEditingController();
  final TextEditingController _defaultModelController = TextEditingController();
  final TextEditingController _newModelController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _draft = widget.controller.settings;
    _activeProviderDraft = _draft.activeProvider;
    final ProviderSettings ps = _draft.providers[_activeProviderDraft] ?? const ProviderSettings(enabled: false, apiKey: '');
    _apiKeyController.text = ps.apiKey;
    _baseUrlController.text = ps.baseUrl ?? '';
    _defaultModelController.text = ps.defaultModel ?? '';
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _baseUrlController.dispose();
    _defaultModelController.dispose();
    _newModelController.dispose();
    super.dispose();
  }

  void _persistDraft({bool notify = true}) {
    widget.controller.replaceSettings(_draft, persist: false);
    if (notify) setState(() {});
  }

  void _setProviderDraft(AiProviderType type, ProviderSettings settings) {
    final current = Map<AiProviderType, ProviderSettings>.from(_draft.providers);
    current[type] = settings;
    _draft = _draft.copyWith(providers: current);
  }

  void _onSkip() async {
    await widget.controller.setOnboardingComplete(true);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => ChatAiPage(
        settings: widget.controller,
        mcpController: widget.mcpController,
      )),
    );
  }

  Future<void> _onFinish() async {
    widget.controller.replaceSettings(_draft, persist: true);
    await widget.controller.setOnboardingComplete(true);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => ChatAiPage(
        settings: widget.controller,
        mcpController: widget.mcpController,
      )),
    );
  }

  void _onNext() {
    setState(() {
      _currentStep = (_currentStep + 1).clamp(0, 3);
    });
  }

  void _onBack() {
    setState(() {
      _currentStep = (_currentStep - 1).clamp(0, 3);
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isWide = MediaQuery.of(context).size.width >= 900;

    final ProviderSettings activePs = _draft.providers[_activeProviderDraft] ?? const ProviderSettings(enabled: false, apiKey: '');

    final List<Step> steps = <Step>[
      Step(
        title: const Text('Welcome'),
        isActive: _currentStep >= 0,
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text('Welcome to Kavi AI', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
              SizedBox(height: 8),
              Text('Let\'s get you set up with your preferred theme, AI provider, and models. You can change these later in Settings.'),
            ],
          ),
        ),
      ),
      Step(
        title: const Text('Appearance'),
        isActive: _currentStep >= 1,
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Theme mode'),
              const SizedBox(height: 8),
              SegmentedButton<ThemeMode>(
                segments: const <ButtonSegment<ThemeMode>>[
                  ButtonSegment(value: ThemeMode.system, label: Text('System'), icon: Icon(Icons.computer)),
                  ButtonSegment(value: ThemeMode.light, label: Text('Light'), icon: Icon(Icons.light_mode)),
                  ButtonSegment(value: ThemeMode.dark, label: Text('Dark'), icon: Icon(Icons.dark_mode)),
                ],
                selected: {_draft.themeMode},
                onSelectionChanged: (s) {
                  _draft = _draft.copyWith(themeMode: s.first);
                  _persistDraft();
                },
              ),
              const SizedBox(height: 16),
              const Text('Accent color'),
              const SizedBox(height: 8),
              _ColorSeedGrid(
                selectedColor: Color(_draft.primaryColorSeed),
                onSelect: (c) {
                  _draft = _draft.copyWith(primaryColorSeed: c.value);
                  _persistDraft();
                },
              ),
            ],
          ),
        ),
      ),
      Step(
        title: const Text('Provider'),
        isActive: _currentStep >= 2,
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Choose your AI provider'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: AiProviderType.values.map((t) {
                  final bool selected = t == _activeProviderDraft;
                  return ChoiceChip(
                    label: Text(_providerLabel(t)),
                    selected: selected,
                    onSelected: (_) {
                      setState(() {
                        _activeProviderDraft = t;
                      });
                      _draft = _draft.copyWith(activeProvider: t);
                      final ProviderSettings ps = _draft.providers[t] ?? const ProviderSettings(enabled: false, apiKey: '');
                      _apiKeyController.text = ps.apiKey;
                      _baseUrlController.text = ps.baseUrl ?? '';
                      _defaultModelController.text = ps.defaultModel ?? '';
                      _persistDraft(notify: false);
                    },
                  );
                }).toList(growable: false),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('Enable provider'),
                  const SizedBox(width: 8),
                  Switch(
                    value: activePs.enabled,
                    onChanged: (v) {
                      _setProviderDraft(_activeProviderDraft, activePs.copyWith(enabled: v));
                      _persistDraft();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _apiKeyController,
                decoration: const InputDecoration(labelText: 'API Key', border: OutlineInputBorder(), isDense: true),
                obscureText: true,
                onChanged: (v) {
                  _setProviderDraft(_activeProviderDraft, activePs.copyWith(apiKey: v));
                  _persistDraft(notify: false);
                },
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _baseUrlController,
                decoration: const InputDecoration(labelText: 'Base URL (optional)', border: OutlineInputBorder(), isDense: true),
                onChanged: (v) {
                  _setProviderDraft(_activeProviderDraft, activePs.copyWith(baseUrl: v.isEmpty ? null : v));
                  _persistDraft(notify: false);
                },
              ),
            ],
          ),
        ),
      ),
      Step(
        title: const Text('Models'),
        isActive: _currentStep >= 3,
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Configure models for ${_providerLabel(_activeProviderDraft)}'),
              const SizedBox(height: 8),
              TextField(
                controller: _defaultModelController,
                decoration: const InputDecoration(labelText: 'Default model (optional)', border: OutlineInputBorder(), isDense: true),
                onChanged: (v) {
                  _setProviderDraft(_activeProviderDraft, activePs.copyWith(defaultModel: v.isEmpty ? null : v));
                  _persistDraft(notify: false);
                },
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ...activePs.customModels.map((m) => InputChip(
                        label: Text(m),
                        onDeleted: () {
                          final List<String> updated = List<String>.from(activePs.customModels)..remove(m);
                          _setProviderDraft(_activeProviderDraft, activePs.copyWith(customModels: updated));
                          _persistDraft();
                        },
                      )),
                  SizedBox(
                    width: 280,
                    child: TextField(
                      controller: _newModelController,
                      decoration: const InputDecoration(hintText: 'Add custom model', isDense: true, border: OutlineInputBorder()),
                      onSubmitted: (v) {
                        if (v.trim().isEmpty) return;
                        final List<String> updated = List<String>.from(activePs.customModels);
                        if (!updated.contains(v.trim())) {
                          updated.add(v.trim());
                          _setProviderDraft(_activeProviderDraft, activePs.copyWith(customModels: updated));
                          _persistDraft();
                        }
                        _newModelController.clear();
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Get Started'),
        actions: [
          TextButton(
            onPressed: _onSkip,
            child: const Text('Skip'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Expanded(
                    child: Stepper(
                      type: isWide ? StepperType.horizontal : StepperType.vertical,
                      currentStep: _currentStep,
                      controlsBuilder: (context, details) => const SizedBox.shrink(),
                      onStepTapped: (i) => setState(() => _currentStep = i),
                      steps: steps,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      border: Border(top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant)),
                    ),
                    padding: const EdgeInsets.fromLTRB(0, 12, 0, 12),
                    child: SafeArea(
                      top: false,
                      child: Row(
                        children: [
                          // Next on the left
                          FilledButton(
                            onPressed: _currentStep == steps.length - 1 ? _onFinish : _onNext,
                            child: Text(_currentStep == steps.length - 1 ? 'Finish' : 'Next'),
                          ),
                          const Spacer(),
                          // Back on the right
                          if (_currentStep > 0)
                            OutlinedButton(
                              onPressed: _onBack,
                              child: const Text('Back'),
                            ),
                        ],
                      ),
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

  String _providerLabel(AiProviderType t) {
    switch (t) {
      case AiProviderType.openAI:
        return 'OpenAI';
      case AiProviderType.deepSeek:
        return 'DeepSeek';
      default:
        return t.name;
    }
  }
}

class _ColorSeedGrid extends StatelessWidget {
  final Color selectedColor;
  final ValueChanged<Color> onSelect;
  const _ColorSeedGrid({required this.selectedColor, required this.onSelect});

  static const List<Color> _choices = <Color>[
    Color(0xFF2962FF),
    Color(0xFF00C853),
    Color(0xFFFFAB00),
    Color(0xFFD50000),
    Color(0xFFAA00FF),
    Color(0xFF00BFA5),
    Color(0xFF6200EE),
    Color(0xFF1E88E5),
    Color(0xFF43A047),
    Color(0xFFF4511E),
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