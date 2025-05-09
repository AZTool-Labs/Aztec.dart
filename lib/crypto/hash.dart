import 'dart:typed_data';
import 'package:aztecdart/utils/logging.dart';
import 'package:crypto/crypto.dart';

/// HashFunction is a class that provides various hash functions used in the Aztec protocol.
///
/// It includes implementations of hash functions like Poseidon, Pedersen, and SHA256.
class HashFunction {
  /// Logger instance for the HashFunction
  final Logger _logger = Logger('HashFunction');

  /// Compute a Poseidon hash of the inputs
  ///
  /// Poseidon is a ZK-friendly hash function used in the Aztec protocol.
  ///
  /// [inputs] - The inputs to hash
  /// [domain] - Optional domain separator
  ///
  /// Returns the hash as a Uint8List
  Uint8List poseidon(List<BigInt> inputs, {BigInt? domain}) {
    try {
      // This is a placeholder implementation - a real implementation would use
      // the actual Poseidon algorithm

      // Convert inputs to bytes
      final buffer = StringBuffer();
      for (final input in inputs) {
        buffer.write(input.toString());
      }

      if (domain != null) {
        buffer.write(domain.toString());
      }

      // Use SHA-256 as a placeholder
      final hash =
          sha256.convert(Uint8List.fromList(buffer.toString().codeUnits));

      return Uint8List.fromList(hash.bytes);
    } catch (e, stackTrace) {
      _logger.error('Failed to compute Poseidon hash', e, stackTrace);
      rethrow;
    }
  }

  /// Compute a Pedersen hash of the inputs
  ///
  /// Pedersen is a ZK-friendly hash function used in the Aztec protocol.
  ///
  /// [inputs] - The inputs to hash
  /// [domain] - Optional domain separator
  ///
  /// Returns the hash as a Uint8List
  Uint8List pedersen(List<BigInt> inputs, {BigInt? domain}) {
    try {
      // This is a placeholder implementation - a real implementation would use
      // the actual Pedersen algorithm

      // Convert inputs to bytes
      final buffer = StringBuffer();
      for (final input in inputs) {
        buffer.write(input.toString());
      }

      if (domain != null) {
        buffer.write(domain.toString());
      }

      // Use SHA-256 as a placeholder
      final hash =
          sha256.convert(Uint8List.fromList(buffer.toString().codeUnits));

      return Uint8List.fromList(hash.bytes);
    } catch (e, stackTrace) {
      _logger.error('Failed to compute Pedersen hash', e, stackTrace);
      rethrow;
    }
  }

  /// Compute a SHA-256 hash of the input
  ///
  /// [input] - The input to hash
  ///
  /// Returns the hash as a Uint8List
  Uint8List computeSha256(Uint8List input) {
    try {
      final hash = sha256.convert(input);
      return Uint8List.fromList(hash.bytes);
    } catch (e, stackTrace) {
      _logger.error('Failed to compute SHA-256 hash', e, stackTrace);
      rethrow;
    }
  }

  /// Compute a Keccak-256 hash of the input
  ///
  /// [input] - The input to hash
  ///
  /// Returns the hash as a Uint8List
  Uint8List keccak256(Uint8List input) {
    try {
      // This is a placeholder implementation - a real implementation would use
      // the actual Keccak-256 algorithm

      // Use SHA-256 as a placeholder
      final hash = sha256.convert(input);

      return Uint8List.fromList(hash.bytes);
    } catch (e, stackTrace) {
      _logger.error('Failed to compute Keccak-256 hash', e, stackTrace);
      rethrow;
    }
  }
}
