import 'package:flutter/foundation.dart';

import '../models/mcp_server_config.dart';
import '../service/mcp_integration_service.dart';
import '../../settings/controller/settings_controller.dart';

class McpController extends ChangeNotifier {
  McpController({required this.settingsController}) {
    settingsController.addListener(_onSettingsChanged);
    _initializeIfEnabled();
  }

  final SettingsController settingsController;
  final McpIntegrationService _mcpService = McpIntegrationService();

  bool _isInitializing = false;
  String? _error;

  McpIntegrationService get mcpService => _mcpService;
  bool get isConnected => _mcpService.isConnected;
  bool get isInitializing => _isInitializing;
  String? get error => _error;
  
  List<McpServerConfig> get servers => 
      settingsController.settings.mcpServers;
  
  bool get isEnabled => settingsController.settings.mcpEnabled;

  void _onSettingsChanged() {
    if (isEnabled && !isConnected && !_isInitializing) {
      _initializeIfEnabled();
    } else if (!isEnabled && isConnected) {
      disconnect();
    }
  }

  Future<void> _initializeIfEnabled() async {
    if (!isEnabled || servers.isEmpty) return;
    await initialize();
  }

  Future<void> initialize() async {
    if (_isInitializing) return;

    _isInitializing = true;
    _error = null;
    notifyListeners();

    try {
      print('MCP: Initializing with ${servers.length} servers');
      for (final server in servers) {
        print('MCP: Server "${server.name}" - ${server.command} ${server.args.join(' ')}');
      }
      await _mcpService.initialize(servers);
      _error = null;
      print('MCP: Initialization complete, connected: $isConnected');
    } catch (e) {
      _error = 'Failed to initialize MCP: $e';
      print('MCP Error: $e');
    } finally {
      _isInitializing = false;
      notifyListeners();
    }
  }

  Future<void> disconnect() async {
    await _mcpService.shutdown();
    _error = null;
    notifyListeners();
  }

  Future<void> addServer(McpServerConfig server) async {
    final updatedServers = [...servers, server];
    await settingsController.updateMcpServers(updatedServers);
    
    if (isEnabled) {
      await initialize();
    }
  }

  Future<void> updateServer(int index, McpServerConfig server) async {
    if (index < 0 || index >= servers.length) return;
    
    final updatedServers = [...servers];
    updatedServers[index] = server;
    await settingsController.updateMcpServers(updatedServers);
    
    if (isEnabled) {
      await initialize();
    }
  }

  Future<void> removeServer(int index) async {
    if (index < 0 || index >= servers.length) return;
    
    final updatedServers = [...servers]..removeAt(index);
    await settingsController.updateMcpServers(updatedServers);
    
    if (isEnabled && updatedServers.isNotEmpty) {
      await initialize();
    }
  }

  Future<void> toggleEnabled() async {
    await settingsController.updateMcpEnabled(!isEnabled);
  }

  @override
  void dispose() {
    settingsController.removeListener(_onSettingsChanged);
    _mcpService.shutdown();
    super.dispose();
  }
} 