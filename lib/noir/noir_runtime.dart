import 'dart:async';
import 'dart:ffi' as ffi;
import 'dart:io';
import 'package:aztecdart/utils/logging.dart';
import 'package:ffi/ffi.dart';
import '../flutter/platform_bindings.dart';

/// Native struct for NoirRuntimeConfig
final class NoirRuntimeConfigNative extends ffi.Struct {
  @ffi.Uint64()
  external int maxMemory;

  @ffi.Uint32()
  external int numThreads;

  @ffi.Uint8()
  external int debugMode; // Using int as boolean
}

/// Native struct for CompilationOptions
final class CompilationOptionsNative extends ffi.Struct {
  @ffi.Uint32()
  external int optimizationLevel;

  @ffi.Uint8()
  external int debugInfo; // Using int as boolean
}

/// NoirRuntime provides the core interface to the Noir language runtime.
///
/// It handles native bindings to the Noir compiler and execution environment,
/// allowing Flutter applications to compile circuits and generate/verify proofs.
class NoirRuntime {
  /// Singleton instance of the NoirRuntime
  static final NoirRuntime _instance = NoirRuntime._internal();

  /// Factory constructor to return the singleton instance
  factory NoirRuntime() {
    return _instance;
  }

  /// Private constructor for singleton pattern
  NoirRuntime._internal();

  /// The native library handle
  late ffi.DynamicLibrary _noirLib;

  /// Flag indicating if the runtime has been initialized
  bool _initialized = false;

  /// Logger instance for the NoirRuntime
  final Logger _logger = Logger('NoirRuntime');

  /// Initialize the Noir runtime with the given configuration
  ///
  /// This method loads the appropriate native library for the current platform
  /// and initializes the Noir runtime. It should be called before any other
  /// methods on this class.
  ///
  /// [config] - Configuration options for the Noir runtime
  Future<void> initialize({NoirRuntimeConfig? config}) async {
    if (_initialized) {
      _logger.warn('NoirRuntime already initialized');
      return;
    }

    try {
      // Load the appropriate native library based on the platform
      if (Platform.isAndroid) {
        _noirLib = await _loadAndroidLibrary();
      } else if (Platform.isIOS) {
        _noirLib = await _loadIOSLibrary();
      } else if (Platform.isLinux) {
        _noirLib = ffi.DynamicLibrary.open('libnoir.so');
      } else if (Platform.isMacOS) {
        _noirLib = ffi.DynamicLibrary.open('libnoir.dylib');
      } else if (Platform.isWindows) {
        _noirLib = ffi.DynamicLibrary.open('noir.dll');
      } else {
        throw UnsupportedError(
            'Unsupported platform: ${Platform.operatingSystem}');
      }

      // Initialize the Noir runtime with the provided configuration
      final initResult = _initializeRuntime(config ?? NoirRuntimeConfig());

      if (!initResult) {
        throw Exception('Failed to initialize Noir runtime');
      }

      _initialized = true;
      _logger.info('NoirRuntime initialized successfully');
    } catch (e, stackTrace) {
      _logger.error('Failed to initialize NoirRuntime', e, stackTrace);
      throw NoirRuntimeException('Failed to initialize NoirRuntime: $e');
    }
  }

  /// Load the Noir native library for Android
  Future<ffi.DynamicLibrary> _loadAndroidLibrary() async {
    // On Android, we need to extract the library from assets and load it
    return PlatformBindings.loadAndroidLibrary('libnoir.so');
  }

  /// Load the Noir native library for iOS
  Future<ffi.DynamicLibrary> _loadIOSLibrary() async {
    // On iOS, the library is embedded in the app bundle
    return PlatformBindings.loadIOSLibrary('Noir');
  }

  /// Initialize the Noir runtime with the given configuration
  bool _initializeRuntime(NoirRuntimeConfig config) {
    // Convert the configuration to a native structure
    final configPtr = _configToNative(config);

    try {
      // Get the function pointer for the initialization function
      final initFunctionPtr = _noirLib.lookup<
          ffi.NativeFunction<
              ffi.Bool Function(
                  ffi.Pointer<NoirRuntimeConfigNative>)>>('noir_initialize');

      // Create the Dart function from the native function
      final initFunction = initFunctionPtr
          .asFunction<bool Function(ffi.Pointer<NoirRuntimeConfigNative>)>();

      // Call the initialization function
      return initFunction(configPtr);
    } finally {
      // Free the configuration memory
      calloc.free(configPtr);
    }
  }

  /// Convert a Dart configuration object to a native pointer
  ffi.Pointer<NoirRuntimeConfigNative> _configToNative(
      NoirRuntimeConfig config) {
    final configPtr = calloc<NoirRuntimeConfigNative>();
    configPtr.ref.maxMemory = config.maxMemory;
    configPtr.ref.numThreads = config.numThreads;
    configPtr.ref.debugMode = config.debugMode ? 1 : 0;
    return configPtr;
  }

  /// Compile a Noir circuit from source code
  ///
  /// [source] - The Noir source code as a string
  /// [name] - Optional name for the circuit
  /// [options] - Compilation options
  ///
  /// Returns a compiled circuit that can be used for proof generation
  Future<CompiledCircuit> compileCircuit(
    String source, {
    String? name,
    CompilationOptions? options,
  }) async {
    _ensureInitialized();

    // Convert the source to a native string
    final sourcePtr = source.toNativeUtf8();

    // Convert options to native structure if provided
    final optionsPtr =
        options != null ? _optionsToNative(options) : ffi.nullptr;

    try {
      _logger.debug('Compiling circuit: ${name ?? 'unnamed'}');

      // Get the function pointer for the compilation function
      final compileFunctionPtr = _noirLib.lookup<
              ffi.NativeFunction<
                  ffi.Pointer<ffi.Void> Function(ffi.Pointer<ffi.Char>,
                      ffi.Pointer<CompilationOptionsNative>)>>(
          'noir_compile_circuit');

      // Create the Dart function from the native function
      final compileFunction = compileFunctionPtr.asFunction<
          ffi.Pointer<ffi.Void> Function(
              ffi.Pointer<ffi.Char>, ffi.Pointer<CompilationOptionsNative>)>();

      // Call the compilation function
      final circuitPtr =
          compileFunction(sourcePtr.cast<ffi.Char>(), optionsPtr);

      if (circuitPtr == ffi.nullptr) {
        throw Exception('Circuit compilation failed');
      }

      // Create a CompiledCircuit object from the native pointer
      return CompiledCircuit.fromNative(circuitPtr, name: name);
    } catch (e, stackTrace) {
      _logger.error('Circuit compilation failed', e, stackTrace);
      throw NoirCompilationException('Failed to compile circuit: $e');
    } finally {
      // Free the source and options memory
      calloc.free(sourcePtr);
      if (options != null) calloc.free(optionsPtr);
    }
  }

  /// Convert compilation options to a native pointer
  ffi.Pointer<CompilationOptionsNative> _optionsToNative(
      CompilationOptions options) {
    final optionsPtr = calloc<CompilationOptionsNative>();
    optionsPtr.ref.optimizationLevel = options.optimizationLevel;
    optionsPtr.ref.debugInfo = options.debugInfo ? 1 : 0;
    return optionsPtr;
  }

  /// Load a pre-compiled circuit from a binary representation
  ///
  /// [bytes] - The binary representation of the compiled circuit
  /// [name] - Optional name for the circuit
  ///
  /// Returns a compiled circuit that can be used for proof generation
  Future<CompiledCircuit> loadCompiledCircuit(
    List<int> bytes, {
    String? name,
  }) async {
    _ensureInitialized();

    // Allocate memory for the binary data
    final dataPtr = calloc<ffi.Uint8>(bytes.length);

    try {
      _logger.debug('Loading compiled circuit: ${name ?? 'unnamed'}');

      // Copy the bytes to the native memory
      for (var i = 0; i < bytes.length; i++) {
        dataPtr[i] = bytes[i];
      }

      // Get the function pointer for the loading function
      final loadFunctionPtr = _noirLib.lookup<
          ffi.NativeFunction<
              ffi.Pointer<ffi.Void> Function(
                  ffi.Pointer<ffi.Uint8>, ffi.Uint32)>>('noir_load_circuit');

      // Create the Dart function from the native function
      final loadFunction = loadFunctionPtr.asFunction<
          ffi.Pointer<ffi.Void> Function(ffi.Pointer<ffi.Uint8>, int)>();

      // Call the loading function
      final circuitPtr = loadFunction(dataPtr, bytes.length);

      if (circuitPtr == ffi.nullptr) {
        throw Exception('Circuit loading failed');
      }

      // Create a CompiledCircuit object from the native pointer
      return CompiledCircuit.fromNative(circuitPtr, name: name);
    } catch (e, stackTrace) {
      _logger.error('Circuit loading failed', e, stackTrace);
      throw NoirLoadException('Failed to load circuit: $e');
    } finally {
      // Free the data memory
      calloc.free(dataPtr);
    }
  }

  /// Ensure that the runtime has been initialized
  void _ensureInitialized() {
    if (!_initialized) {
      throw StateError('NoirRuntime not initialized. Call initialize() first.');
    }
  }

  /// Get access to the native library for advanced usage
  ffi.DynamicLibrary get nativeLib {
    _ensureInitialized();
    return _noirLib;
  }

  /// Clean up resources used by the Noir runtime
  ///
  /// This method should be called when the runtime is no longer needed
  /// to free up native resources.
  Future<void> dispose() async {
    if (!_initialized) {
      return;
    }

    try {
      // Get the function pointer for the cleanup function
      final cleanupFunctionPtr = _noirLib
          .lookup<ffi.NativeFunction<ffi.Void Function()>>('noir_cleanup');

      // Create the Dart function from the native function
      final cleanupFunction = cleanupFunctionPtr.asFunction<void Function()>();

      // Call the cleanup function
      cleanupFunction();

      _initialized = false;
      _logger.info('NoirRuntime disposed successfully');
    } catch (e, stackTrace) {
      _logger.error('Failed to dispose NoirRuntime', e, stackTrace);
      throw NoirRuntimeException('Failed to dispose NoirRuntime: $e');
    }
  }
}

/// Configuration options for the Noir runtime
class NoirRuntimeConfig {
  /// Maximum memory to use for the Noir runtime (in bytes)
  final int maxMemory;

  /// Number of threads to use for parallel operations
  final int numThreads;

  /// Enable debug mode for additional logging
  final bool debugMode;

  /// Constructor for NoirRuntimeConfig
  const NoirRuntimeConfig({
    this.maxMemory = 1024 * 1024 * 1024, // 1 GB default
    this.numThreads = 0, // 0 means use all available threads
    this.debugMode = false,
  });
}

/// Options for circuit compilation
class CompilationOptions {
  /// Optimization level (0-3)
  final int optimizationLevel;

  /// Enable debug information in the compiled circuit
  final bool debugInfo;

  /// Constructor for CompilationOptions
  const CompilationOptions({
    this.optimizationLevel = 2,
    this.debugInfo = false,
  });
}

/// Represents a compiled Noir circuit
class CompiledCircuit {
  /// Native pointer to the compiled circuit
  final ffi.Pointer<ffi.Void> _nativePtr;

  /// Name of the circuit (optional)
  final String? name;

  /// Constructor for CompiledCircuit
  CompiledCircuit.fromNative(this._nativePtr, {this.name});

  /// Get the native pointer to the compiled circuit
  ffi.Pointer<ffi.Void> get nativePtr => _nativePtr;

  /// Serialize the compiled circuit to a binary representation
  Future<List<int>> serialize() async {
    // Get the function pointer for the serialization function
    final serializeFunctionPtr = NoirRuntime().nativeLib.lookup<
        ffi.NativeFunction<
            ffi.Pointer<SerializedCircuitNative> Function(
                ffi.Pointer<ffi.Void>)>>('noir_serialize_circuit');

    // Create the Dart function from the native function
    final serializeFunction = serializeFunctionPtr.asFunction<
        ffi.Pointer<SerializedCircuitNative> Function(ffi.Pointer<ffi.Void>)>();

    // Call the serialization function
    final serializedPtr = serializeFunction(_nativePtr);

    try {
      if (serializedPtr == ffi.nullptr) {
        throw Exception('Circuit serialization failed');
      }

      // Extract the data from the serialized circuit
      final dataPtr = serializedPtr.ref.data;
      final dataLength = serializedPtr.ref.length;

      // Copy the data to a Dart list
      final result = List<int>.filled(dataLength, 0);
      for (var i = 0; i < dataLength; i++) {
        result[i] = dataPtr[i];
      }

      return result;
    } finally {
      // Free the serialized circuit
      final freeFunctionPtr = NoirRuntime().nativeLib.lookup<
              ffi.NativeFunction<
                  ffi.Void Function(ffi.Pointer<SerializedCircuitNative>)>>(
          'noir_free_serialized_circuit');

      final freeFunction = freeFunctionPtr
          .asFunction<void Function(ffi.Pointer<SerializedCircuitNative>)>();

      freeFunction(serializedPtr);
    }
  }

  /// Free the resources used by the compiled circuit
  void dispose() {
    if (_nativePtr != ffi.nullptr) {
      // Get the function pointer for the disposal function
      final disposeFunctionPtr = NoirRuntime()
          .nativeLib
          .lookup<ffi.NativeFunction<ffi.Void Function(ffi.Pointer<ffi.Void>)>>(
              'noir_free_circuit');

      // Create the Dart function from the native function
      final disposeFunction =
          disposeFunctionPtr.asFunction<void Function(ffi.Pointer<ffi.Void>)>();

      // Call the disposal function
      disposeFunction(_nativePtr);
    }
  }
}

/// Native struct for serialized circuit data
final class SerializedCircuitNative extends ffi.Struct {
  external ffi.Pointer<ffi.Uint8> data;

  @ffi.Uint32()
  external int length;
}

/// Exception thrown when there is an error in the Noir runtime
class NoirRuntimeException implements Exception {
  final String message;
  NoirRuntimeException(this.message);

  @override
  String toString() => 'NoirRuntimeException: $message';
}

/// Exception thrown when there is an error during circuit compilation
class NoirCompilationException implements Exception {
  final String message;
  NoirCompilationException(this.message);

  @override
  String toString() => 'NoirCompilationException: $message';
}

/// Exception thrown when there is an error loading a circuit
class NoirLoadException implements Exception {
  final String message;
  NoirLoadException(this.message);

  @override
  String toString() => 'NoirLoadException: $message';
}
