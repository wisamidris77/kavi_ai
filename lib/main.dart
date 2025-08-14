import 'package:flutter/material.dart';
import 'presentation/presentation.dart';
import 'settings/controller/settings_controller.dart';
import 'settings/repository/settings_repository.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final SettingsController _settingsController;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _settingsController = SettingsController(SettingsRepository());
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await _settingsController.load();
    setState(() {
      _loaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _settingsController,
      builder: (context, _) {
        final seed = Color(_settingsController.settings.primaryColorSeed);
        final mode = _settingsController.settings.themeMode;
        return MaterialApp(
          title: 'Kavi AI',
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.light),
            brightness: Brightness.light,
            visualDensity: VisualDensity.standard,
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.dark),
            brightness: Brightness.dark,
            visualDensity: VisualDensity.standard,
          ),
          themeMode: mode,
          home: _loaded
              ? ChatAiPage(settings: _settingsController)
              : const _LoadingScreen(),
        );
      },
    );
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
