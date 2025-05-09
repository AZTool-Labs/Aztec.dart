import 'dart:async';

/// Type of plugin
enum PluginType {
  /// Core functionality plugin
  core,

  /// UI plugin
  ui,

  /// Integration plugin
  integration,

  /// Security plugin
  security,

  /// Analytics plugin
  analytics,
}

/// Interface for Aztec plugins
abstract class AztecPlugin {
  /// Unique ID of the plugin
  String get id;

  /// Name of the plugin
  String get name;

  /// Description of the plugin
  String get description;

  /// Version of the plugin
  String get version;

  /// Type of the plugin
  PluginType get type;

  /// Initialize the plugin
  Future<void> initialize();

  /// Check if the plugin supports a hook
  bool supportsHook(String hook);

  /// Execute a hook
  Future<dynamic> executeHook(String hook, Map<String, dynamic> args);
}

/// Base implementation of AztecPlugin
abstract class BaseAztecPlugin implements AztecPlugin {
  @override
  final String id;

  @override
  final String name;

  @override
  final String description;

  @override
  final String version;

  @override
  final PluginType type;

  /// Map of hook names to handler functions
  final Map<String, Future<dynamic> Function(Map<String, dynamic>)> _hooks = {};

  /// Constructor for BaseAztecPlugin
  BaseAztecPlugin({
    required this.id,
    required this.name,
    required this.description,
    required this.version,
    required this.type,
  });

  /// Register a hook handler
  void registerHook(
      String hook, Future<dynamic> Function(Map<String, dynamic>) handler) {
    _hooks[hook] = handler;
  }

  @override
  bool supportsHook(String hook) {
    return _hooks.containsKey(hook);
  }

  @override
  Future<dynamic> executeHook(String hook, Map<String, dynamic> args) async {
    if (!supportsHook(hook)) {
      throw UnsupportedError('Hook not supported: $hook');
    }

    return await _hooks[hook]!(args);
  }
}
