import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class TokenTracker {
  static const String _storageKey = 'token_usage';
  static const String _costKey = 'token_costs';
  
  // Token costs per 1K tokens (approximate)
  static const Map<String, Map<String, double>> _tokenCosts = {
    'openai': {
      'gpt-4o': 0.005,
      'gpt-4o-mini': 0.00015,
      'gpt-4-turbo': 0.01,
      'gpt-3.5-turbo': 0.0005,
    },
    'anthropic': {
      'claude-3-opus-20240229': 0.015,
      'claude-3-sonnet-20240229': 0.003,
      'claude-3-haiku-20240307': 0.00025,
      'claude-3-5-sonnet-20241022': 0.003,
      'claude-3-5-haiku-20241022': 0.00025,
    },
    'deepseek': {
      'deepseek-chat': 0.0007,
      'deepseek-coder': 0.0014,
    },
  };

  final StreamController<TokenUsage> _usageController = StreamController<TokenUsage>.broadcast();
  final StreamController<CostEstimate> _costController = StreamController<CostEstimate>.broadcast();

  Stream<TokenUsage> get usageStream => _usageController.stream;
  Stream<CostEstimate> get costStream => _costController.stream;

  TokenUsage _currentUsage = TokenUsage();
  CostEstimate _currentCost = CostEstimate();

  TokenTracker() {
    _loadUsage();
  }

  Future<void> _loadUsage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final usageJson = prefs.getString(_storageKey);
      final costJson = prefs.getString(_costKey);

      if (usageJson != null) {
        final usageMap = jsonDecode(usageJson) as Map<String, dynamic>;
        _currentUsage = TokenUsage.fromJson(usageMap);
      }

      if (costJson != null) {
        final costMap = jsonDecode(costJson) as Map<String, dynamic>;
        _currentCost = CostEstimate.fromJson(costMap);
      }
    } catch (e) {
      print('Error loading token usage: $e');
    }
  }

  Future<void> _saveUsage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, jsonEncode(_currentUsage.toJson()));
      await prefs.setString(_costKey, jsonEncode(_currentCost.toJson()));
    } catch (e) {
      print('Error saving token usage: $e');
    }
  }

  void trackTokens({
    required String provider,
    required String model,
    required int inputTokens,
    required int outputTokens,
    String? conversationId,
  }) {
    final totalTokens = inputTokens + outputTokens;
    final cost = _calculateCost(provider, model, inputTokens, outputTokens);

    // Update current usage
    _currentUsage = _currentUsage.copyWith(
      totalTokens: _currentUsage.totalTokens + totalTokens,
      inputTokens: _currentUsage.inputTokens + inputTokens,
      outputTokens: _currentUsage.outputTokens + outputTokens,
      conversations: _currentUsage.conversations + (conversationId != null ? 1 : 0),
      lastUsed: DateTime.now(),
    );

    // Update current cost
    _currentCost = _currentCost.copyWith(
      totalCost: _currentCost.totalCost + cost,
      dailyCost: _currentCost.dailyCost + cost,
      monthlyCost: _currentCost.monthlyCost + cost,
    );

    // Add to conversation history
    if (conversationId != null) {
      _currentUsage.conversationHistory[conversationId] = TokenUsage(
        totalTokens: totalTokens,
        inputTokens: inputTokens,
        outputTokens: outputTokens,
        lastUsed: DateTime.now(),
      );
    }

    // Notify listeners
    _usageController.add(_currentUsage);
    _costController.add(_currentCost);

    // Save to storage
    _saveUsage();
  }

  double _calculateCost(String provider, String model, int inputTokens, int outputTokens) {
    final providerCosts = _tokenCosts[provider.toLowerCase()];
    if (providerCosts == null) return 0.0;

    final costPer1k = providerCosts[model] ?? 0.0;
    final inputCost = (inputTokens / 1000) * costPer1k;
    final outputCost = (outputTokens / 1000) * costPer1k;

    return inputCost + outputCost;
  }

  TokenUsage get currentUsage => _currentUsage;
  CostEstimate get currentCost => _currentCost;

  Future<void> resetUsage() async {
    _currentUsage = TokenUsage();
    _currentCost = CostEstimate();
    _usageController.add(_currentUsage);
    _costController.add(_currentCost);
    await _saveUsage();
  }

  Future<void> resetDailyUsage() async {
    _currentCost = _currentCost.copyWith(dailyCost: 0.0);
    _costController.add(_currentCost);
    await _saveUsage();
  }

  Future<void> resetMonthlyUsage() async {
    _currentCost = _currentCost.copyWith(monthlyCost: 0.0);
    _costController.add(_currentCost);
    await _saveUsage();
  }

  void dispose() {
    _usageController.close();
    _costController.close();
  }
}

class TokenUsage {
  final int totalTokens;
  final int inputTokens;
  final int outputTokens;
  final int conversations;
  final DateTime lastUsed;
  final Map<String, TokenUsage> conversationHistory;

  const TokenUsage({
    this.totalTokens = 0,
    this.inputTokens = 0,
    this.outputTokens = 0,
    this.conversations = 0,
    DateTime? lastUsed,
    Map<String, TokenUsage>? conversationHistory,
  }) : lastUsed = lastUsed ?? DateTime.now(),
       conversationHistory = conversationHistory ?? const {};

  TokenUsage copyWith({
    int? totalTokens,
    int? inputTokens,
    int? outputTokens,
    int? conversations,
    DateTime? lastUsed,
    Map<String, TokenUsage>? conversationHistory,
  }) {
    return TokenUsage(
      totalTokens: totalTokens ?? this.totalTokens,
      inputTokens: inputTokens ?? this.inputTokens,
      outputTokens: outputTokens ?? this.outputTokens,
      conversations: conversations ?? this.conversations,
      lastUsed: lastUsed ?? this.lastUsed,
      conversationHistory: conversationHistory ?? this.conversationHistory,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalTokens': totalTokens,
      'inputTokens': inputTokens,
      'outputTokens': outputTokens,
      'conversations': conversations,
      'lastUsed': lastUsed.toIso8601String(),
      'conversationHistory': conversationHistory.map(
        (key, value) => MapEntry(key, value.toJson()),
      ),
    };
  }

  factory TokenUsage.fromJson(Map<String, dynamic> json) {
    return TokenUsage(
      totalTokens: json['totalTokens'] as int? ?? 0,
      inputTokens: json['inputTokens'] as int? ?? 0,
      outputTokens: json['outputTokens'] as int? ?? 0,
      conversations: json['conversations'] as int? ?? 0,
      lastUsed: DateTime.tryParse(json['lastUsed'] as String? ?? '') ?? DateTime.now(),
      conversationHistory: (json['conversationHistory'] as Map<String, dynamic>?)?.map(
        (key, value) => MapEntry(key, TokenUsage.fromJson(value as Map<String, dynamic>)),
      ) ?? const {},
    );
  }
}

class CostEstimate {
  final double totalCost;
  final double dailyCost;
  final double monthlyCost;
  final DateTime lastReset;

  const CostEstimate({
    this.totalCost = 0.0,
    this.dailyCost = 0.0,
    this.monthlyCost = 0.0,
    DateTime? lastReset,
  }) : lastReset = lastReset ?? DateTime.now();

  CostEstimate copyWith({
    double? totalCost,
    double? dailyCost,
    double? monthlyCost,
    DateTime? lastReset,
  }) {
    return CostEstimate(
      totalCost: totalCost ?? this.totalCost,
      dailyCost: dailyCost ?? this.dailyCost,
      monthlyCost: monthlyCost ?? this.monthlyCost,
      lastReset: lastReset ?? this.lastReset,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalCost': totalCost,
      'dailyCost': dailyCost,
      'monthlyCost': monthlyCost,
      'lastReset': lastReset.toIso8601String(),
    };
  }

  factory CostEstimate.fromJson(Map<String, dynamic> json) {
    return CostEstimate(
      totalCost: (json['totalCost'] as num?)?.toDouble() ?? 0.0,
      dailyCost: (json['dailyCost'] as num?)?.toDouble() ?? 0.0,
      monthlyCost: (json['monthlyCost'] as num?)?.toDouble() ?? 0.0,
      lastReset: DateTime.tryParse(json['lastReset'] as String? ?? '') ?? DateTime.now(),
    );
  }
}