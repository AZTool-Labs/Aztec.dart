import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'noir_runtime.dart';
import '../utils/logger.dart';

/// CircuitManager handles the lifecycle of Noir circuits.
///
/// It provides functionality for compiling, loading, caching, and managing
/// circuits. This class abstracts away the details of circuit storage and
/// retrieval, providing a simple API for working with circuits.
class CircuitManager {
  /// Singleton instance of the CircuitManager
  static final CircuitManager _instance = CircuitManager._internal();

  /// Factory constructor to return the singleton instance
  factory CircuitManager() {
    return _instance;
  }

  /// Private constructor for singleton pattern
  CircuitManager._internal();

  /// The Noir runtime instance
  final NoirRuntime _noirRuntime = NoirRuntime();

  /// Logger instance for the CircuitManager
  final Logger _logger = Logger('CircuitManager');

  /// Cache of compiled circuits
  final Map<String, CompiledCircuit> _circuitCache = {};

  /// Directory for storing compiled circuits
  late Directory _circuitDir;

  /// Initialize the CircuitManager
  ///
  /// This method initializes the circuit storage directory and loads
  /// any cached circuits. It should be called before any other methods
  /// on this class.
  Future<void> initialize() async {
    try {
      // Ensure the Noir runtime is initialized
      await _noirRuntime.initialize();

      // Get the application documents directory
      final appDir = await getApplicationDocumentsDirectory();
      _circuitDir = Directory(path.join(appDir.path, 'aztec_circuits'));

      // Create the circuit directory if it doesn't exist
      if (!await _circuitDir.exists()) {
        await _circuitDir.create(recursive: true);
      }

      _logger.info('CircuitManager initialized successfully');
    } catch (e, stackTrace) {
      _logger.error('Failed to initialize CircuitManager', e, stackTrace);
      rethrow;
    }
  }

  /// Compile a Noir circuit from source code
  ///
  /// [source] - The Noir source code as a string
  /// [name] - Name for the circuit (required for caching)
  /// [options] - Compilation options
  /// [cache] - Whether to cache the compiled circuit
  ///
  /// Returns a compiled circuit that can be used for proof generation
  Future<CompiledCircuit> compileCircuit(
    String source, {
    required String name,
    CompilationOptions? options,
    bool cache = true,
  }) async {
    try {
      _logger.debug('Compiling circuit: $name');

      // Check if the circuit is already in the cache
      if (_circuitCache.containsKey(name)) {
        _logger.debug('Circuit found in memory cache: $name');
        return _circuitCache[name]!;
      }

      // Check if the circuit is in the file cache
      final circuitFile = File(path.join(_circuitDir.path, '$name.circuit'));
      if (await circuitFile.exists()) {
        _logger.debug('Circuit found in file cache: $name');
        final bytes = await circuitFile.readAsBytes();
        final circuit =
            await _noirRuntime.loadCompiledCircuit(bytes, name: name);

        if (cache) {
          _circuitCache[name] = circuit;
        }

        return circuit;
      }

      // Compile the circuit
      final circuit = await _noirRuntime.compileCircuit(
        source,
        name: name,
        options: options,
      );

      // Cache the circuit if requested
      if (cache) {
        _circuitCache[name] = circuit;

        // Serialize and save the circuit to the file cache
        final bytes = await circuit.serialize();
        await circuitFile.writeAsBytes(bytes);
      }

      return circuit;
    } catch (e, stackTrace) {
      _logger.error('Failed to compile circuit: $name', e, stackTrace);
      rethrow;
    }
  }

  /// Load a pre-compiled circuit from a binary representation
  ///
  /// [bytes] - The binary representation of the compiled circuit
  /// [name] - Name for the circuit (required for caching)
  /// [cache] - Whether to cache the compiled circuit
  ///
  /// Returns a compiled circuit that can be used for proof generation
  Future<CompiledCircuit> loadCircuit(
    Uint8List bytes, {
    required String name,
    bool cache = true,
  }) async {
    try {
      _logger.debug('Loading circuit: $name');

      // Check if the circuit is already in the cache
      if (_circuitCache.containsKey(name)) {
        _logger.debug('Circuit found in memory cache: $name');
        return _circuitCache[name]!;
      }

      // Load the circuit
      final circuit = await _noirRuntime.loadCompiledCircuit(bytes, name: name);

      // Cache the circuit if requested
      if (cache) {
        _circuitCache[name] = circuit;

        // Save the circuit to the file cache
        final circuitFile = File(path.join(_circuitDir.path, '$name.circuit'));
        await circuitFile.writeAsBytes(bytes);
      }

      return circuit;
    } catch (e, stackTrace) {
      _logger.error('Failed to load circuit: $name', e, stackTrace);
      rethrow;
    }
  }

  /// Load a circuit from the cache by name
  ///
  /// [name] - The name of the circuit to load
  ///
  /// Returns the cached circuit, or null if not found
  Future<CompiledCircuit?> getCachedCircuit(String name) async {
    try {
      // Check if the circuit is in the memory cache
      if (_circuitCache.containsKey(name)) {
        return _circuitCache[name];
      }

      // Check if the circuit is in the file cache
      final circuitFile = File(path.join(_circuitDir.path, '$name.circuit'));
      if (await circuitFile.exists()) {
        final bytes = await circuitFile.readAsBytes();
        final circuit =
            await _noirRuntime.loadCompiledCircuit(bytes, name: name);

        // Add to memory cache
        _circuitCache[name] = circuit;

        return circuit;
      }

      return null;
    } catch (e, stackTrace) {
      _logger.error('Failed to get cached circuit: $name', e, stackTrace);
      return null;
    }
  }

  /// Remove a circuit from the cache
  ///
  /// [name] - The name of the circuit to remove
  /// [deleteFile] - Whether to also delete the circuit file
  Future<void> removeCircuit(String name, {bool deleteFile = false}) async {
    try {
      // Remove from memory cache
      _circuitCache.remove(name);

      // Remove from file cache if requested
      if (deleteFile) {
        final circuitFile = File(path.join(_circuitDir.path, '$name.circuit'));
        if (await circuitFile.exists()) {
          await circuitFile.delete();
        }
      }
    } catch (e, stackTrace) {
      _logger.error('Failed to remove circuit: $name', e, stackTrace);
      rethrow;
    }
  }

  /// Clear the circuit cache
  ///
  /// [deleteFiles] - Whether to also delete the circuit files
  Future<void> clearCache({bool deleteFiles = false}) async {
    try {
      // Clear memory cache
      _circuitCache.clear();

      // Clear file cache if requested
      if (deleteFiles) {
        await _circuitDir.delete(recursive: true);
        await _circuitDir.create(recursive: true);
      }
    } catch (e, stackTrace) {
      _logger.error('Failed to clear circuit cache', e, stackTrace);
      rethrow;
    }
  }

  /// Get the list of cached circuit names
  Future<List<String>> getCachedCircuitNames() async {
    try {
      final files = await _circuitDir.list().toList();
      return files
          .where((file) => file is File && file.path.endsWith('.circuit'))
          .map((file) => path.basenameWithoutExtension(file.path))
          .toList();
    } catch (e, stackTrace) {
      _logger.error('Failed to get cached circuit names', e, stackTrace);
      rethrow;
    }
  }

  /// Dispose of the CircuitManager and free resources
  Future<void> dispose() async {
    try {
      // Dispose of all cached circuits
      for (final circuit in _circuitCache.values) {
        circuit.dispose();
      }

      // Clear the cache
      _circuitCache.clear();

      _logger.info('CircuitManager disposed successfully');
    } catch (e, stackTrace) {
      _logger.error('Failed to dispose CircuitManager', e, stackTrace);
      rethrow;
    }
  }
}
