import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class ColorSchemeManager extends ChangeNotifier {
  static const String _storageKey = 'selected_color_scheme';
  
  static final List<ColorSchemeOption> _defaultSchemes = [
    ColorSchemeOption(
      name: 'Purple',
      description: 'Default purple theme',
      seedColor: Color(0xFF6750A4),
      category: ColorSchemeCategory.primary,
    ),
    ColorSchemeOption(
      name: 'Blue',
      description: 'Professional blue theme',
      seedColor: Color(0xFF1976D2),
      category: ColorSchemeCategory.primary,
    ),
    ColorSchemeOption(
      name: 'Green',
      description: 'Nature-inspired green theme',
      seedColor: Color(0xFF2E7D32),
      category: ColorSchemeCategory.primary,
    ),
    ColorSchemeOption(
      name: 'Orange',
      description: 'Warm orange theme',
      seedColor: Color(0xFFF57C00),
      category: ColorSchemeCategory.primary,
    ),
    ColorSchemeOption(
      name: 'Pink',
      description: 'Playful pink theme',
      seedColor: Color(0xFFC2185B),
      category: ColorSchemeCategory.primary,
    ),
    ColorSchemeOption(
      name: 'Teal',
      description: 'Calm teal theme',
      seedColor: Color(0xFF00695C),
      category: ColorSchemeCategory.primary,
    ),
    ColorSchemeOption(
      name: 'Indigo',
      description: 'Deep indigo theme',
      seedColor: Color(0xFF3F51B5),
      category: ColorSchemeCategory.primary,
    ),
    ColorSchemeOption(
      name: 'Red',
      description: 'Bold red theme',
      seedColor: Color(0xFFD32F2F),
      category: ColorSchemeCategory.primary,
    ),
    ColorSchemeOption(
      name: 'Brown',
      description: 'Earthy brown theme',
      seedColor: Color(0xFF5D4037),
      category: ColorSchemeCategory.primary,
    ),
    ColorSchemeOption(
      name: 'Grey',
      description: 'Minimal grey theme',
      seedColor: Color(0xFF424242),
      category: ColorSchemeCategory.neutral,
    ),
    ColorSchemeOption(
      name: 'Cyan',
      description: 'Fresh cyan theme',
      seedColor: Color(0xFF0097A7),
      category: ColorSchemeCategory.primary,
    ),
    ColorSchemeOption(
      name: 'Lime',
      description: 'Vibrant lime theme',
      seedColor: Color(0xFF827717),
      category: ColorSchemeCategory.primary,
    ),
  ];

  ColorSchemeOption _selectedScheme = _defaultSchemes[0];
  List<ColorSchemeOption> _customSchemes = [];

  ColorSchemeManager() {
    _loadSelectedScheme();
  }

  ColorSchemeOption get selectedScheme => _selectedScheme;
  List<ColorSchemeOption> get allSchemes => [..._defaultSchemes, ..._customSchemes];
  List<ColorSchemeOption> get defaultSchemes => _defaultSchemes;
  List<ColorSchemeOption> get customSchemes => _customSchemes;

  List<ColorSchemeOption> getSchemesByCategory(ColorSchemeCategory category) {
    return allSchemes.where((scheme) => scheme.category == category).toList();
  }

  Future<void> _loadSelectedScheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final schemeJson = prefs.getString(_storageKey);
      
      if (schemeJson != null) {
        final schemeData = jsonDecode(schemeJson) as Map<String, dynamic>;
        final schemeName = schemeData['name'] as String;
        final schemeColor = Color(schemeData['seedColor'] as int);
        
        // Find the scheme in our lists
        final scheme = allSchemes.firstWhere(
          (s) => s.name == schemeName && s.seedColor == schemeColor,
          orElse: () => _defaultSchemes[0],
        );
        
        _selectedScheme = scheme;
        notifyListeners();
      }
    } catch (e) {
      print('Error loading color scheme: $e');
    }
  }

  Future<void> selectScheme(ColorSchemeOption scheme) async {
    _selectedScheme = scheme;
    notifyListeners();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final schemeData = {
        'name': scheme.name,
        'seedColor': scheme.seedColor.value,
        'description': scheme.description,
        'category': scheme.category.name,
      };
      await prefs.setString(_storageKey, jsonEncode(schemeData));
    } catch (e) {
      print('Error saving color scheme: $e');
    }
  }

  Future<void> addCustomScheme(ColorSchemeOption scheme) async {
    _customSchemes.add(scheme);
    notifyListeners();
    await _saveCustomSchemes();
  }

  Future<void> removeCustomScheme(ColorSchemeOption scheme) async {
    _customSchemes.removeWhere((s) => s.name == scheme.name);
    notifyListeners();
    await _saveCustomSchemes();
  }

  Future<void> _saveCustomSchemes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final schemesData = _customSchemes.map((scheme) => {
        'name': scheme.name,
        'description': scheme.description,
        'seedColor': scheme.seedColor.value,
        'category': scheme.category.name,
      }).toList();
      await prefs.setString('custom_color_schemes', jsonEncode(schemesData));
    } catch (e) {
      print('Error saving custom color schemes: $e');
    }
  }

  ColorScheme getLightColorScheme() {
    return ColorScheme.fromSeed(
      seedColor: _selectedScheme.seedColor,
      brightness: Brightness.light,
    );
  }

  ColorScheme getDarkColorScheme() {
    return ColorScheme.fromSeed(
      seedColor: _selectedScheme.seedColor,
      brightness: Brightness.dark,
    );
  }

  ThemeData getLightTheme() {
    final colorScheme = getLightColorScheme();
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      brightness: Brightness.light,
    );
  }

  ThemeData getDarkTheme() {
    final colorScheme = getDarkColorScheme();
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      brightness: Brightness.dark,
    );
  }
}

class ColorSchemeOption {
  final String name;
  final String description;
  final Color seedColor;
  final ColorSchemeCategory category;

  const ColorSchemeOption({
    required this.name,
    required this.description,
    required this.seedColor,
    required this.category,
  });

  ColorSchemeOption copyWith({
    String? name,
    String? description,
    Color? seedColor,
    ColorSchemeCategory? category,
  }) {
    return ColorSchemeOption(
      name: name ?? this.name,
      description: description ?? this.description,
      seedColor: seedColor ?? this.seedColor,
      category: category ?? this.category,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'seedColor': seedColor.value,
      'category': category.name,
    };
  }

  factory ColorSchemeOption.fromJson(Map<String, dynamic> json) {
    return ColorSchemeOption(
      name: json['name'] as String,
      description: json['description'] as String,
      seedColor: Color(json['seedColor'] as int),
      category: ColorSchemeCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => ColorSchemeCategory.primary,
      ),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ColorSchemeOption &&
        other.name == name &&
        other.seedColor == seedColor;
  }

  @override
  int get hashCode => name.hashCode ^ seedColor.hashCode;
}

enum ColorSchemeCategory {
  primary,
  neutral,
  custom,
}