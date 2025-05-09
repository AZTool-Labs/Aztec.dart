import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:aztecdart/utils/logging.dart';
import 'package:http/http.dart' as http;
import 'account.dart';
import 'asset.dart';
import 'transaction.dart';

/// Represents a connection to the Aztec Network
class AztecNetwork {
  /// Unique ID of the network
  final String networkId;

  /// Name of the network
  final String name;

  /// URL of the network
  final String url;

  /// Chain ID of the network
  final int chainId;

  /// Whether this is a testnet
  final bool isTestnet;

  /// HTTP client for network requests
  final http.Client _client;

  /// Logger instance for the AztecNetwork
  final Logger _logger = Logger('AztecNetwork');

  /// Constructor for AztecNetwork
  AztecNetwork({
    required this.networkId,
    required this.name,
    required this.url,
    required this.chainId,
    this.isTestnet = false,
    http.Client? client,
  }) : _client = client ?? http.Client();

  /// Initialize the network connection
  Future<void> initialize() async {
    try {
      // Test the connection to the network
      final response = await _client.get(Uri.parse('$url/status'));

      if (response.statusCode != 200) {
        throw AztecNetworkException(
            'Failed to connect to network: ${response.statusCode}');
      }

      _logger.info('Connected to network: $name ($networkId)');
    } catch (e, stackTrace) {
      _logger.error('Failed to initialize network connection', e, stackTrace);
      rethrow;
    }
  }

  /// Register an account with the network
  Future<void> registerAccount(AztecAccount account) async {
    try {
      // Get the public key for the account
      final publicKey = await account.getPublicKey();

      // Register the account with the network
      final response = await _client.post(
        Uri.parse('$url/accounts'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'id': account.id,
          'publicKey': base64Encode(publicKey),
        }),
      );

      if (response.statusCode != 200) {
        throw AztecNetworkException(
            'Failed to register account: ${response.statusCode}');
      }

      _logger.info('Account registered: ${account.id}');
    } catch (e, stackTrace) {
      _logger.error('Failed to register account: ${account.id}', e, stackTrace);
      rethrow;
    }
  }

  /// Get the balance of an asset for an account
  Future<BigInt> getBalance(String accountId, String assetId) async {
    try {
      // Get the balance from the network
      final response = await _client.get(
        Uri.parse('$url/accounts/$accountId/assets/$assetId/balance'),
      );

      if (response.statusCode != 200) {
        throw AztecNetworkException(
            'Failed to get balance: ${response.statusCode}');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return BigInt.parse(data['balance'] as String);
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
      // Get all balances from the network
      final response = await _client.get(
        Uri.parse('$url/accounts/$accountId/balances'),
      );

      if (response.statusCode != 200) {
        throw AztecNetworkException(
            'Failed to get balances: ${response.statusCode}');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final balances = <String, BigInt>{};

      for (final entry in data.entries) {
        balances[entry.key] = BigInt.parse(entry.value as String);
      }

      return balances;
    } catch (e, stackTrace) {
      _logger.error(
          'Failed to get all balances for account: $accountId', e, stackTrace);
      rethrow;
    }
  }

  /// Get all assets from the network
  Future<List<AztecAsset>> getAssets() async {
    try {
      // Get all assets from the network
      final response = await _client.get(
        Uri.parse('$url/assets'),
      );

      if (response.statusCode != 200) {
        throw AztecNetworkException(
            'Failed to get assets: ${response.statusCode}');
      }

      final data = jsonDecode(response.body) as List<dynamic>;
      final assets = <AztecAsset>[];

      for (final item in data) {
        final asset = item as Map<String, dynamic>;
        assets.add(AztecAsset(
          id: asset['id'] as String,
          name: asset['name'] as String,
          symbol: asset['symbol'] as String,
          decimals: asset['decimals'] as int,
          isPrivate: asset['isPrivate'] as bool,
          l1Address: asset['l1Address'] as String?,
        ));
      }

      return assets;
    } catch (e, stackTrace) {
      _logger.error('Failed to get assets', e, stackTrace);
      rethrow;
    }
  }

  /// Register a new asset with the network
  Future<AztecAsset> registerAsset({
    required String name,
    required String symbol,
    required int decimals,
    required bool isPrivate,
    String? l1Address,
  }) async {
    try {
      // Register the asset with the network
      final response = await _client.post(
        Uri.parse('$url/assets'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'symbol': symbol,
          'decimals': decimals,
          'isPrivate': isPrivate,
          'l1Address': l1Address,
        }),
      );

      if (response.statusCode != 200) {
        throw AztecNetworkException(
            'Failed to register asset: ${response.statusCode}');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      return AztecAsset(
        id: data['id'] as String,
        name: data['name'] as String,
        symbol: data['symbol'] as String,
        decimals: data['decimals'] as int,
        isPrivate: data['isPrivate'] as bool,
        l1Address: data['l1Address'] as String?,
      );
    } catch (e, stackTrace) {
      _logger.error('Failed to register asset', e, stackTrace);
      rethrow;
    }
  }

  /// Submit a transaction to the network
  Future<AztecTransactionReceipt> submitTransaction(
      Uint8List serializedTransaction) async {
    try {
      // Submit the transaction to the network
      final response = await _client.post(
        Uri.parse('$url/transactions'),
        headers: {'Content-Type': 'application/octet-stream'},
        body: serializedTransaction,
      );

      if (response.statusCode != 200) {
        throw AztecNetworkException(
            'Failed to submit transaction: ${response.statusCode}');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      // Parse the transaction status
      final statusStr = data['status'] as String;
      final status = AztecTransactionStatus.values.firstWhere(
        (s) => s.toString() == statusStr,
        orElse: () => AztecTransactionStatus.pending,
      );

      return AztecTransactionReceipt(
        transactionId: data['transactionId'] as String,
        blockNumber: data['blockNumber'] as int?,
        status: status,
        gasUsed: BigInt.parse(data['gasUsed'] as String),
        timestamp:
            DateTime.fromMillisecondsSinceEpoch(data['timestamp'] as int),
        data: data['data'] as Map<String, dynamic>?,
      );
    } catch (e, stackTrace) {
      _logger.error('Failed to submit transaction', e, stackTrace);
      rethrow;
    }
  }

  /// Get a transaction by ID
  Future<AztecTransaction> getTransaction(String transactionId) async {
    try {
      // Get the transaction from the network
      final response = await _client.get(
        Uri.parse('$url/transactions/$transactionId'),
      );

      if (response.statusCode != 200) {
        throw AztecNetworkException(
            'Failed to get transaction: ${response.statusCode}');
      }

      final data = Uint8List.fromList(response.bodyBytes);
      return await AztecTransaction.deserialize(data);
    } catch (e, stackTrace) {
      _logger.error('Failed to get transaction: $transactionId', e, stackTrace);
      rethrow;
    }
  }

  /// Get transactions for an account
  Future<List<AztecTransaction>> getTransactions(String accountId,
      {int limit = 10, int offset = 0}) async {
    try {
      // Get transactions from the network
      final response = await _client.get(
        Uri.parse(
            '$url/accounts/$accountId/transactions?limit=$limit&offset=$offset'),
      );

      if (response.statusCode != 200) {
        throw AztecNetworkException(
            'Failed to get transactions: ${response.statusCode}');
      }

      final data = jsonDecode(response.body) as List<dynamic>;
      final transactions = <AztecTransaction>[];

      for (final item in data) {
        final txData = Uint8List.fromList(base64Decode(item as String));
        final transaction = await AztecTransaction.deserialize(txData);
        transactions.add(transaction);
      }

      return transactions;
    } catch (e, stackTrace) {
      _logger.error(
          'Failed to get transactions for account: $accountId', e, stackTrace);
      rethrow;
    }
  }

  /// Get the network status
  Future<AztecNetworkStatus> getStatus() async {
    try {
      // Get the network status
      final response = await _client.get(
        Uri.parse('$url/status'),
      );

      if (response.statusCode != 200) {
        throw AztecNetworkException(
            'Failed to get network status: ${response.statusCode}');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      return AztecNetworkStatus(
        isConnected: data['isConnected'] as bool,
        blockHeight: data['blockHeight'] as int,
        syncStatus: data['syncStatus'] as String,
        peers: data['peers'] as int,
        version: data['version'] as String,
      );
    } catch (e, stackTrace) {
      _logger.error('Failed to get network status', e, stackTrace);
      rethrow;
    }
  }

  /// Close the network connection
  Future<void> close() async {
    try {
      _client.close();
      _logger.info('Network connection closed');
    } catch (e, stackTrace) {
      _logger.error('Failed to close network connection', e, stackTrace);
      rethrow;
    }
  }
}

/// Status of the Aztec Network
class AztecNetworkStatus {
  /// Whether the network is connected
  final bool isConnected;

  /// Current block height
  final int blockHeight;

  /// Sync status of the network
  final String syncStatus;

  /// Number of connected peers
  final int peers;

  /// Version of the network
  final String version;

  /// Constructor for AztecNetworkStatus
  AztecNetworkStatus({
    required this.isConnected,
    required this.blockHeight,
    required this.syncStatus,
    required this.peers,
    required this.version,
  });
}

/// Exception thrown when there is an error with the Aztec Network
class AztecNetworkException implements Exception {
  final String message;
  final StackTrace? stackTrace;

  AztecNetworkException(this.message, [this.stackTrace]);

  @override
  String toString() => 'AztecNetworkException: $message';
}

/// Factory for creating Aztec Network instances
class AztecNetworkFactory {
  /// Create a mainnet network instance
  static Future<AztecNetwork> createMainnet() async {
    final network = AztecNetwork(
      networkId: 'aztec-mainnet',
      name: 'Aztec Mainnet',
      url: 'https://api.aztec.network',
      chainId: 1,
      isTestnet: false,
    );

    await network.initialize();
    return network;
  }

  /// Create a testnet network instance
  static Future<AztecNetwork> createTestnet() async {
    final network = AztecNetwork(
      networkId: 'aztec-testnet',
      name: 'Aztec Testnet',
      url: 'https://testnet-api.aztec.network',
      chainId: 2,
      isTestnet: true,
    );

    await network.initialize();
    return network;
  }

  /// Create a local network instance
  static Future<AztecNetwork> createLocal(
      {String url = 'http://localhost:8545'}) async {
    final network = AztecNetwork(
      networkId: 'aztec-local',
      name: 'Aztec Local',
      url: url,
      chainId: 31337,
      isTestnet: true,
    );

    await network.initialize();
    return network;
  }

  /// Create a custom network instance
  static Future<AztecNetwork> createCustom({
    required String networkId,
    required String name,
    required String url,
    required int chainId,
    bool isTestnet = false,
  }) async {
    final network = AztecNetwork(
      networkId: networkId,
      name: name,
      url: url,
      chainId: chainId,
      isTestnet: isTestnet,
    );

    await network.initialize();
    return network;
  }
}
