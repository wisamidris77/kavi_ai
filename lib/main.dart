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
    return MaterialApp(
      title: 'Kavi AI',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple, brightness: Brightness.dark),
        brightness: Brightness.dark,
      ),
      themeMode: ThemeMode.system,
      home: _loaded
          ? ChatAiPage(settings: _settingsController)
          : const _LoadingScreen(),
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
