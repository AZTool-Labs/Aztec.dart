import 'dart:async';
import 'dart:ffi' as ffi;
import 'dart:io';
import 'package:flutter/services.dart';
import '../utils/logger.dart';

/// PlatformBindings provides platform-specific functionality for the Aztec.dart package.
///
/// It handles loading native libraries, interacting with platform channels,
/// and other platform-specific operations.
class PlatformBindings {
  /// Logger instance for the PlatformBindings
  static final Logger _logger = Logger('PlatformBindings');

  /// Method channel for communicating with the platform
  static const MethodChannel _channel = MethodChannel('com.example.aztec_dart');

  /// Load a native library on Android
  static Future<ffi.DynamicLibrary> loadAndroidLibrary(
      String libraryName) async {
    try {
      // Get the application directory
      final appDir = await _getApplicationDirectory();

      // Extract the library from assets
      await _extractLibrary(libraryName, appDir);

      // Load the library
      final libraryPath = '$appDir/$libraryName';
      return ffi.DynamicLibrary.open(libraryPath);
    } catch (e, stackTrace) {
      _logger.error(
          'Failed to load Android library: $libraryName', e, stackTrace);
      rethrow;
    }
  }

  /// Load a native library on iOS
  static Future<ffi.DynamicLibrary> loadIOSLibrary(String libraryName) async {
    try {
      // On iOS, the library is embedded in the app bundle
      return ffi.DynamicLibrary.process();
    } catch (e, stackTrace) {
      _logger.error('Failed to load iOS library: $libraryName', e, stackTrace);
      rethrow;
    }
  }

  /// Get the application directory
  static Future<String> _getApplicationDirectory() async {
    try {
      final result =
          await _channel.invokeMethod<String>('getApplicationDirectory');
      return result!;
    } catch (e, stackTrace) {
      _logger.error('Failed to get application directory', e, stackTrace);
      rethrow;
    }
  }

  /// Extract a library from assets
  static Future<void> _extractLibrary(
      String libraryName, String directory) async {
    try {
      await _channel.invokeMethod<void>('extractLibrary', {
        'libraryName': libraryName,
        'directory': directory,
      });
    } catch (e, stackTrace) {
      _logger.error('Failed to extract library: $libraryName', e, stackTrace);
      rethrow;
    }
  }

  /// Check if biometric authentication is available
  static Future<bool> isBiometricAvailable() async {
    try {
      final result = await _channel.invokeMethod<bool>('isBiometricAvailable');
      return result ?? false;
    } catch (e, stackTrace) {
      _logger.error('Failed to check biometric availability', e, stackTrace);
      return false;
    }
  }

  /// Authenticate using biometrics
  static Future<bool> authenticateWithBiometrics(String reason) async {
    try {
      final result =
          await _channel.invokeMethod<bool>('authenticateWithBiometrics', {
        'reason': reason,
      });
      return result ?? false;
    } catch (e, stackTrace) {
      _logger.error('Failed to authenticate with biometrics', e, stackTrace);
      return false;
    }
  }

  /// Get the device ID
  static Future<String?> getDeviceId() async {
    try {
      return await _channel.invokeMethod<String>('getDeviceId');
    } catch (e, stackTrace) {
      _logger.error('Failed to get device ID', e, stackTrace);
      return null;
    }
  }

  /// Check if the device is rooted/jailbroken
  static Future<bool> isDeviceRooted() async {
    try {
      final result = await _channel.invokeMethod<bool>('isDeviceRooted');
      return result ?? false;
    } catch (e, stackTrace) {
      _logger.error('Failed to check if device is rooted', e, stackTrace);
      return false;
    }
  }
}
