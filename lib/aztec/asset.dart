import 'dart:async';
import 'package:aztecdart/utils/logging.dart';
import 'network.dart';

/// Represents an asset on the Aztec Network
class AztecAsset {
  /// Unique ID of the asset
  final String id;

  /// Name of the asset
  final String name;

  /// Symbol of the asset
  final String symbol;

  /// Decimals of the asset
  final int decimals;

  /// Whether the asset is a private asset
  final bool isPrivate;

  /// Address of the asset on the L1 network (if applicable)
  final String? l1Address;

  /// Logger instance for the AztecAsset
  final Logger _logger = Logger('AztecAsset');

  /// Constructor for AztecAsset
  AztecAsset({
    required this.id,
    required this.name,
    required this.symbol,
    required this.decimals,
    required this.isPrivate,
    this.l1Address,
  });

  /// Format an amount of this asset for display
  String formatAmount(BigInt amount) {
    // Convert the amount to a decimal string based on the asset's decimals
    final amountStr = amount.toString();

    // Ensure the string has enough digits
    final paddedStr = amountStr.padLeft(decimals + 1, '0');

    // Insert the decimal point
    final intPart = paddedStr.substring(0, paddedStr.length - decimals);
    final fracPart = paddedStr.substring(paddedStr.length - decimals);

    // Remove trailing zeros from the fractional part
    var trimmedFracPart = fracPart;
    while (trimmedFracPart.isNotEmpty && trimmedFracPart.endsWith('0')) {
      trimmedFracPart =
          trimmedFracPart.substring(0, trimmedFracPart.length - 1);
    }

    // Return the formatted amount
    if (trimmedFracPart.isEmpty) {
      return intPart;
    } else {
      return '$intPart.$trimmedFracPart';
    }
  }

  /// Parse a display amount to a BigInt
  BigInt parseAmount(String amount) {
    // Split the amount into integer and fractional parts
    final parts = amount.split('.');
    final intPart = parts[0];
    final fracPart = parts.length > 1 ? parts[1] : '';

    // Pad or truncate the fractional part to match the asset's decimals
    final paddedFracPart =
        fracPart.padRight(decimals, '0').substring(0, decimals);

    // Combine the parts and parse as a BigInt
    return BigInt.parse(intPart + paddedFracPart);
  }
}

/// Manager for Aztec assets
class AztecAssetManager {
  /// Singleton instance of the AztecAssetManager
  static final AztecAssetManager _instance = AztecAssetManager._internal();

  /// Factory constructor to return the singleton instance
  factory AztecAssetManager() {
    return _instance;
  }

  /// Private constructor for singleton pattern
  AztecAssetManager._internal();

  /// Logger instance for the AztecAssetManager
  final Logger _logger = Logger('AztecAssetManager');

  /// Map of asset IDs to assets
  final Map<String, AztecAsset> _assets = {};

  /// The network this asset manager is associated with
  AztecNetwork? _network;

  /// Set the network for this asset manager
  set network(AztecNetwork network) {
    _network = network;
  }

  /// Initialize the asset manager
  ///
  /// [network] - The network to use
  Future<void> initialize(AztecNetwork network) async {
    try {
      _network = network;

      // Fetch assets from the network
      await refreshAssets();

      _logger.info('AssetManager initialized successfully');
    } catch (e, stackTrace) {
      _logger.error('Failed to initialize AssetManager', e, stackTrace);
      rethrow;
    }
  }

  /// Refresh the list of assets from the network
  Future<void> refreshAssets() async {
    try {
      if (_network == null) {
        throw StateError('Network not set');
      }

      // Fetch assets from the network
      final assets = await _network!.getAssets();

      // Update the asset map
      _assets.clear();
      for (final asset in assets) {
        _assets[asset.id] = asset;
      }

      _logger.info('Assets refreshed: ${_assets.length} assets found');
    } catch (e, stackTrace) {
      _logger.error('Failed to refresh assets', e, stackTrace);
      rethrow;
    }
  }

  /// Get an asset by ID
  AztecAsset? getAsset(String assetId) {
    return _assets[assetId];
  }

  /// Get all assets
  List<AztecAsset> getAllAssets() {
    return _assets.values.toList();
  }

  /// Get all private assets
  List<AztecAsset> getPrivateAssets() {
    return _assets.values.where((asset) => asset.isPrivate).toList();
  }

  /// Get all public assets
  List<AztecAsset> getPublicAssets() {
    return _assets.values.where((asset) => !asset.isPrivate).toList();
  }

  /// Register a new asset
  Future<AztecAsset> registerAsset({
    required String name,
    required String symbol,
    required int decimals,
    required bool isPrivate,
    String? l1Address,
  }) async {
    try {
      if (_network == null) {
        throw StateError('Network not set');
      }

      // Register the asset with the network
      final asset = await _network!.registerAsset(
        name: name,
        symbol: symbol,
        decimals: decimals,
        isPrivate: isPrivate,
        l1Address: l1Address,
      );

      // Add the asset to the map
      _assets[asset.id] = asset;

      _logger.info('Asset registered: ${asset.id}');

      return asset;
    } catch (e, stackTrace) {
      _logger.error('Failed to register asset', e, stackTrace);
      rethrow;
    }
  }

  /// Get the balance of an asset for an account
  Future<BigInt> getBalance(String assetId, String accountId) async {
    try {
      if (_network == null) {
        throw StateError('Network not set');
      }

      // Get the asset
      final asset = getAsset(assetId);
      if (asset == null) {
        throw AztecAssetException('Asset not found: $assetId');
      }

      // Get the balance from the network
      return await _network!.getBalance(accountId, assetId);
    } catch (e, stackTrace) {
      _logger.error(
          'Failed to get balance for asset: $assetId, account: $accountId',
          e,
          stackTrace);
      rethrow;
    }
  }

  /// Get all balances for an account
  Future<Map<String, BigInt>> getAllBalances(String accountId) async {
    try {
      if (_network == null) {
        throw StateError('Network not set');
      }

      // Get all balances from the network
      return await _network!.getAllBalances(accountId);
    } catch (e, stackTrace) {
      _logger.error(
          'Failed to get all balances for account: $accountId', e, stackTrace);
      rethrow;
    }
  }
}

/// Exception thrown when there is an error with an Aztec asset
class AztecAssetException implements Exception {
  final String message;
  final StackTrace? stackTrace;

  AztecAssetException(this.message, [this.stackTrace]);

  @override
  String toString() => 'AztecAssetException: $message';
}
