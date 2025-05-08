import 'dart:async';
import 'package:flutter/foundation.dart';
import '../aztec/account.dart';
import '../aztec/asset.dart';
import '../aztec/network.dart';
import '../aztec/transaction.dart';
import '../utils/logger.dart';

/// AztecState is a ChangeNotifier that manages the state of the Aztec.dart package.
///
/// It provides a reactive state management solution for Flutter applications
/// using the Aztec.dart package.
class AztecState extends ChangeNotifier {
  /// Logger instance for the AztecState
  final Logger _logger = Logger('AztecState');

  /// The current network
  AztecNetwork? _network;

  /// The account manager
  final AztecAccountManager _accountManager = AztecAccountManager();

  /// The asset manager
  final AztecAssetManager _assetManager = AztecAssetManager();

  /// Map of account IDs to balances
  final Map<String, Map<String, BigInt>> _balances = {};

  /// Map of account IDs to transactions
  final Map<String, List<AztecTransaction>> _transactions = {};

  /// Loading state
  bool _isLoading = false;

  /// Error message
  String? _errorMessage;

  /// Get the current network
  AztecNetwork? get network => _network;

  /// Get the account manager
  AztecAccountManager get accountManager => _accountManager;

  /// Get the asset manager
  AztecAssetManager get assetManager => _assetManager;

  /// Get the active account
  AztecAccount? get activeAccount => _accountManager.activeAccount;

  /// Get all accounts
  List<AztecAccount> get accounts => _accountManager.getAllAccounts();

  /// Get all assets
  List<AztecAsset> get assets => _assetManager.getAllAssets();

  /// Get the loading state
  bool get isLoading => _isLoading;

  /// Get the error message
  String? get errorMessage => _errorMessage;

  /// Set the loading state
  set isLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  /// Set the error message
  set errorMessage(String? value) {
    _errorMessage = value;
    notifyListeners();
  }

  /// Initialize the state with a network
  Future<void> initialize(AztecNetwork network) async {
    try {
      isLoading = true;
      errorMessage = null;

      // Initialize the network
      _network = network;

      // Initialize the asset manager
      _assetManager.network = network;
      await _assetManager.initialize(network);

      isLoading = false;
      notifyListeners();
    } catch (e, stackTrace) {
      _logger.error('Failed to initialize AztecState', e, stackTrace);
      isLoading = false;
      errorMessage = 'Failed to initialize: $e';
    }
  }

  /// Set the active account
  void setActiveAccount(AztecAccount account) {
    _accountManager.activeAccount = account;
    notifyListeners();
  }

  /// Add an account
  void addAccount(AztecAccount account) {
    _accountManager.addAccount(account);
    notifyListeners();
  }

  /// Remove an account
  void removeAccount(String accountId) {
    _accountManager.removeAccount(accountId);
    notifyListeners();
  }

  /// Get the balance of an asset for an account
  Future<BigInt> getBalance(String accountId, String assetId) async {
    try {
      if (_network == null) {
        throw StateError('Network not initialized');
      }

      // Check if the balance is cached
      if (_balances.containsKey(accountId) &&
          _balances[accountId]!.containsKey(assetId)) {
        return _balances[accountId]![assetId]!;
      }

      // Get the balance from the network
      final balance = await _network!.getBalance(accountId, assetId);

      // Cache the balance
      _balances[accountId] ??= {};
      _balances[accountId]![assetId] = balance;

      notifyListeners();

      return balance;
    } catch (e, stackTrace) {
      _logger.error(
          'Failed to get balance for account: $accountId, asset: $assetId',
          e,
          stackTrace);
      rethrow;
    }
  }

  /// Get all balances for an account
  Future<Map<String, BigInt>> getAllBalances(String accountId) async {
    try {
      if (_network == null) {
        throw StateError('Network not initialized');
      }

      // Get all balances from the network
      final balances = await _network!.getAllBalances(accountId);

      // Cache the balances
      _balances[accountId] = balances;

      notifyListeners();

      return balances;
    } catch (e, stackTrace) {
      _logger.error(
          'Failed to get all balances for account: $accountId', e, stackTrace);
      rethrow;
    }
  }

  /// Refresh all balances for the active account
  Future<void> refreshBalances() async {
    try {
      if (_network == null) {
        throw StateError('Network not initialized');
      }

      if (activeAccount == null) {
        return;
      }

      isLoading = true;

      // Get all balances for the active account
      await getAllBalances(activeAccount!.id);

      isLoading = false;
    } catch (e, stackTrace) {
      _logger.error('Failed to refresh balances', e, stackTrace);
      isLoading = false;
      errorMessage = 'Failed to refresh balances: $e';
    }
  }

  /// Get transactions for an account
  Future<List<AztecTransaction>> getTransactions(String accountId,
      {int limit = 10, int offset = 0}) async {
    try {
      if (_network == null) {
        throw StateError('Network not initialized');
      }

      // Get transactions from the network
      final transactions = await _network!
          .getTransactions(accountId, limit: limit, offset: offset);

      // Cache the transactions
      _transactions[accountId] = transactions;

      notifyListeners();

      return transactions;
    } catch (e, stackTrace) {
      _logger.error(
          'Failed to get transactions for account: $accountId', e, stackTrace);
      rethrow;
    }
  }

  /// Refresh transactions for the active account
  Future<void> refreshTransactions() async {
    try {
      if (_network == null) {
        throw StateError('Network not initialized');
      }

      if (activeAccount == null) {
        return;
      }

      isLoading = true;

      // Get transactions for the active account
      await getTransactions(activeAccount!.id);

      isLoading = false;
    } catch (e, stackTrace) {
      _logger.error('Failed to refresh transactions', e, stackTrace);
      isLoading = false;
      errorMessage = 'Failed to refresh transactions: $e';
    }
  }

  /// Submit a transaction
  Future<AztecTransactionReceipt> submitTransaction(
      AztecTransaction transaction) async {
    try {
      if (_network == null) {
        throw StateError('Network not initialized');
      }

      isLoading = true;

      // Submit the transaction
      final receipt = await transaction.submit(_network!);

      // Refresh balances and transactions
      await refreshBalances();
      await refreshTransactions();

      isLoading = false;

      return receipt;
    } catch (e, stackTrace) {
      _logger.error('Failed to submit transaction', e, stackTrace);
      isLoading = false;
      errorMessage = 'Failed to submit transaction: $e';
      rethrow;
    }
  }

  /// Refresh all data
  Future<void> refreshAll() async {
    try {
      if (_network == null) {
        throw StateError('Network not initialized');
      }

      isLoading = true;

      // Refresh assets
      await _assetManager.refreshAssets();

      // Refresh balances and transactions for the active account
      if (activeAccount != null) {
        await getAllBalances(activeAccount!.id);
        await getTransactions(activeAccount!.id);
      }

      isLoading = false;
    } catch (e, stackTrace) {
      _logger.error('Failed to refresh all data', e, stackTrace);
      isLoading = false;
      errorMessage = 'Failed to refresh data: $e';
    }
  }
}
