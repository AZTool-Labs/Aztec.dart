import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:aztecdart/utils/logging.dart';
import 'package:crypto/crypto.dart';
import '../crypto/key_manager.dart';
import '../utils/error_handler.dart';
import 'network.dart';

/// AztecAccount represents a user account on the Aztec Network.
///
/// It provides functionality for managing account keys, viewing keys,
/// and interacting with the Aztec Network.
class AztecAccount {
  /// The account ID
  final String id;

  /// The account index
  final int index;

  /// The account name (optional)
  final String? name;

  /// The key manager for this account
  final KeyManager _keyManager;

  /// The network this account is associated with
  final AztecNetwork _network;

  /// Logger instance for the AztecAccount
  final Logger _logger = Logger('AztecAccount');

  /// Constructor for AztecAccount
  AztecAccount({
    required this.id,
    required this.index,
    this.name,
    required KeyManager keyManager,
    required AztecNetwork network,
  })  : _keyManager = keyManager,
        _network = network;

  /// Create a new Aztec account
  ///
  /// [keyManager] - The key manager to use for the account
  /// [network] - The network to create the account on
  /// [name] - Optional name for the account
  /// [index] - Optional index for the account (defaults to 0)
  ///
  /// Returns a new AztecAccount
  static Future<AztecAccount> create({
    required KeyManager keyManager,
    required AztecNetwork network,
    String? name,
    int index = 0,
  }) async {
    try {
      // Generate a new account ID
      final accountId = _generateAccountId(keyManager, index);

      // Create the account
      final account = AztecAccount(
        id: accountId,
        index: index,
        name: name,
        keyManager: keyManager,
        network: network,
      );

      // Initialize the account on the network
      await account._initialize();

      return account;
    } catch (e, stackTrace) {
      throw AztecAccountException('Failed to create account: $e', stackTrace);
    }
  }

  /// Generate an account ID from a key manager and index
  static String _generateAccountId(KeyManager keyManager, int index) {
    // Get the public key for the account
    final publicKey = keyManager.derivePublicKey(index);

    // Hash the public key to create an account ID
    final hash = sha256.convert(publicKey).bytes;

    // Encode the hash as a hex string
    return hex.encode(hash);
  }

  /// Initialize the account on the network
  Future<void> _initialize() async {
    try {
      // Register the account with the network
      await _network.registerAccount(this);

      _logger.info('Account initialized: $id');
    } catch (e, stackTrace) {
      _logger.error('Failed to initialize account: $id', e, stackTrace);
      rethrow;
    }
  }

  /// Get the public key for this account
  Future<Uint8List> getPublicKey() async {
    try {
      return await _keyManager.derivePublicKey(index);
    } catch (e, stackTrace) {
      _logger.error('Failed to get public key for account: $id', e, stackTrace);
      rethrow;
    }
  }

  /// Get the viewing key for this account
  Future<Uint8List> getViewingKey() async {
    try {
      return await _keyManager.deriveViewingKey(index);
    } catch (e, stackTrace) {
      _logger.error(
          'Failed to get viewing key for account: $id', e, stackTrace);
      rethrow;
    }
  }

  /// Sign a message with this account's private key
  Future<Uint8List> signMessage(Uint8List message) async {
    try {
      return await _keyManager.sign(message, index);
    } catch (e, stackTrace) {
      _logger.error('Failed to sign message for account: $id', e, stackTrace);
      rethrow;
    }
  }

  /// Verify a signature with this account's public key
  Future<bool> verifySignature(Uint8List message, Uint8List signature) async {
    try {
      final publicKey = await getPublicKey();
      return await _keyManager.verify(message, signature, publicKey);
    } catch (e, stackTrace) {
      _logger.error(
          'Failed to verify signature for account: $id', e, stackTrace);
      rethrow;
    }
  }

  /// Get the balance of an asset for this account
  Future<BigInt> getBalance(String assetId) async {
    try {
      return await _network.getBalance(id, assetId);
    } catch (e, stackTrace) {
      _logger.error('Failed to get balance for account: $id, asset: $assetId',
          e, stackTrace);
      rethrow;
    }
  }

  /// Get all balances for this account
  Future<Map<String, BigInt>> getAllBalances() async {
    try {
      return await _network.getAllBalances(id);
    } catch (e, stackTrace) {
      _logger.error(
          'Failed to get all balances for account: $id', e, stackTrace);
      rethrow;
    }
  }

  /// Export the account data as a JSON string
  Future<String> export({bool includePrivateData = false}) async {
    try {
      final data = {
        'id': id,
        'index': index,
        'name': name,
        'network': _network.networkId,
      };

      if (includePrivateData) {
        // Include private data if requested
        // This should be used with caution and only when necessary
        data['privateData'] = await _keyManager.exportPrivateData();
      }

      return jsonEncode(data);
    } catch (e, stackTrace) {
      _logger.error('Failed to export account: $id', e, stackTrace);
      rethrow;
    }
  }

  /// Import an account from a JSON string
  static Future<AztecAccount> import(
    String json, {
    required KeyManager keyManager,
    required AztecNetwork network,
  }) async {
    try {
      final data = jsonDecode(json) as Map<String, dynamic>;

      // Validate the data
      if (!data.containsKey('id') || !data.containsKey('index')) {
        throw FormatException('Invalid account data format');
      }

      // Create the account
      final account = AztecAccount(
        id: data['id'] as String,
        index: data['index'] as int,
        name: data['name'] as String?,
        keyManager: keyManager,
        network: network,
      );

      return account;
    } catch (e, stackTrace) {
      throw AztecAccountException('Failed to import account: $e', stackTrace);
    }
  }
}

/// Exception thrown when there is an error with an Aztec account
class AztecAccountException implements Exception {
  final String message;
  final StackTrace? stackTrace;

  AztecAccountException(this.message, [this.stackTrace]);

  @override
  String toString() => 'AztecAccountException: $message';
}

/// Manager for Aztec accounts
class AztecAccountManager {
  /// Singleton instance of the AztecAccountManager
  static final AztecAccountManager _instance = AztecAccountManager._internal();

  /// Factory constructor to return the singleton instance
  factory AztecAccountManager() {
    return _instance;
  }

  /// Private constructor for singleton pattern
  AztecAccountManager._internal();

  /// Logger instance for the AztecAccountManager
  final Logger _logger = Logger('AztecAccountManager');

  /// Map of account IDs to accounts
  final Map<String, AztecAccount> _accounts = {};

  /// The currently active account
  AztecAccount? _activeAccount;

  /// Get the currently active account
  AztecAccount? get activeAccount => _activeAccount;

  /// Set the active account
  set activeAccount(AztecAccount? account) {
    _activeAccount = account;
    if (account != null) {
      _logger.info('Active account set to: ${account.id}');
    } else {
      _logger.info('Active account cleared');
    }
  }

  /// Add an account to the manager
  void addAccount(AztecAccount account) {
    _accounts[account.id] = account;
    _logger.info('Account added: ${account.id}');

    // If this is the first account, make it the active account
    if (_accounts.length == 1) {
      activeAccount = account;
    }
  }

  /// Remove an account from the manager
  void removeAccount(String accountId) {
    final account = _accounts.remove(accountId);
    if (account != null) {
      _logger.info('Account removed: $accountId');

      // If the active account was removed, clear it
      if (_activeAccount?.id == accountId) {
        activeAccount = _accounts.isNotEmpty ? _accounts.values.first : null;
      }
    }
  }

  /// Get an account by ID
  AztecAccount? getAccount(String accountId) {
    return _accounts[accountId];
  }

  /// Get all accounts
  List<AztecAccount> getAllAccounts() {
    return _accounts.values.toList();
  }

  /// Clear all accounts
  void clearAccounts() {
    _accounts.clear();
    activeAccount = null;
    _logger.info('All accounts cleared');
  }
}
