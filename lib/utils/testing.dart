import 'dart:async';
import 'dart:typed_data';
import 'package:aztecdart/utils/logging.dart';

import '../aztec/account.dart';
import '../aztec/asset.dart';
import '../aztec/network.dart';
import '../aztec/transaction.dart';
import '../crypto/key_manager.dart';

/// TestUtils provides utilities for testing the Aztec.dart package.
///
/// It includes mock implementations of various components for testing
/// without requiring a real network connection.
class TestUtils {
  /// Logger instance for the TestUtils
  static final Logger _logger = Logger('TestUtils');

  /// Create a mock network for testing
  static Future<AztecNetwork> createMockNetwork() async {
    final network = MockAztecNetwork(
      networkId: 'mock-network',
      name: 'Mock Network',
      url: 'http://localhost:8545',
      chainId: 31337,
      isTestnet: true,
    );

    await network.initialize();
    return network;
  }

  /// Create a mock account for testing
  static Future<AztecAccount> createMockAccount(AztecNetwork network,
      {String? name, int index = 0}) async {
    final keyManager = await createMockKeyManager();

    return AztecAccount.create(
      keyManager: keyManager,
      network: network,
      name: name ?? 'Test Account $index',
      index: index,
    );
  }

  /// Create a mock key manager for testing
  static Future<KeyManager> createMockKeyManager() async {
    final keyManager = MockKeyManager();
    await keyManager.initialize(
        seedPhrase:
            'test test test test test test test test test test test junk');
    return keyManager;
  }

  /// Create mock assets for testing
  static List<AztecAsset> createMockAssets() {
    return [
      AztecAsset(
        id: 'eth',
        name: 'Ethereum',
        symbol: 'ETH',
        decimals: 18,
        isPrivate: false,
        l1Address: '0x0000000000000000000000000000000000000000',
      ),
      AztecAsset(
        id: 'dai',
        name: 'Dai Stablecoin',
        symbol: 'DAI',
        decimals: 18,
        isPrivate: true,
        l1Address: '0x6b175474e89094c44da98b954eedeac495271d0f',
      ),
      AztecAsset(
        id: 'usdc',
        name: 'USD Coin',
        symbol: 'USDC',
        decimals: 6,
        isPrivate: true,
        l1Address: '0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48',
      ),
    ];
  }

  /// Create a mock transaction for testing
  static Future<AztecTransaction> createMockTransaction(AztecAccount from,
      {AztecAccount? to, AztecAsset? asset, BigInt? amount}) async {
    return AztecTransaction.createTransfer(
      from: from,
      toAccountId: to?.id ?? 'mock-account',
      assetId: asset?.id ?? 'eth',
      amount: amount ?? BigInt.from(1000000000000000000), // 1 ETH
      fee: BigInt.from(100000000000000), // 0.0001 ETH
    );
  }

  /// Run a test with a mock environment
  static Future<void> runTest(
      Future<void> Function(MockEnvironment) test) async {
    final environment = await MockEnvironment.create();

    try {
      await test(environment);
    } finally {
      await environment.dispose();
    }
  }
}

/// Mock environment for testing
class MockEnvironment {
  /// The mock network
  final AztecNetwork network;

  /// The mock account
  final AztecAccount account;

  /// The mock assets
  final List<AztecAsset> assets;

  /// The mock key manager
  final KeyManager keyManager;

  /// Constructor for MockEnvironment
  MockEnvironment({
    required this.network,
    required this.account,
    required this.assets,
    required this.keyManager,
  });

  /// Create a mock environment
  static Future<MockEnvironment> create() async {
    final network = await TestUtils.createMockNetwork();
    final keyManager = await TestUtils.createMockKeyManager();
    final account = await TestUtils.createMockAccount(network);
    final assets = TestUtils.createMockAssets();

    return MockEnvironment(
      network: network,
      account: account,
      assets: assets,
      keyManager: keyManager,
    );
  }

  /// Dispose of the mock environment
  Future<void> dispose() async {
    // Clean up resources
  }
}

/// Mock implementation of AztecNetwork for testing
class MockAztecNetwork extends AztecNetwork {
  /// Constructor for MockAztecNetwork
  MockAztecNetwork({
    required String networkId,
    required String name,
    required String url,
    required int chainId,
    required bool isTestnet,
  }) : super(
          networkId: networkId,
          name: name,
          url: url,
          chainId: chainId,
          isTestnet: isTestnet,
        );

  @override
  Future<void> initialize() async {
    // No-op for mock
  }

  @override
  Future<void> registerAccount(AztecAccount account) async {
    // No-op for mock
  }

  @override
  Future<BigInt> getBalance(String accountId, String assetId) async {
    // Return a mock balance
    return BigInt.from(1000000000000000000); // 1 ETH
  }

  @override
  Future<Map<String, BigInt>> getAllBalances(String accountId) async {
    // Return mock balances
    return {
      'eth': BigInt.from(1000000000000000000), // 1 ETH
      'dai': BigInt.from(1000000000000000000), // 1 DAI
      'usdc': BigInt.from(1000000), // 1 USDC
    };
  }

  @override
  Future<List<AztecAsset>> getAssets() async {
    // Return mock assets
    return TestUtils.createMockAssets();
  }

  @override
  Future<AztecAsset> registerAsset({
    required String name,
    required String symbol,
    required int decimals,
    required bool isPrivate,
    String? l1Address,
  }) async {
    // Return a mock asset
    return AztecAsset(
      id: symbol.toLowerCase(),
      name: name,
      symbol: symbol,
      decimals: decimals,
      isPrivate: isPrivate,
      l1Address: l1Address,
    );
  }

  @override
  Future<AztecTransactionReceipt> submitTransaction(
      Uint8List serializedTransaction) async {
    // Return a mock receipt
    return AztecTransactionReceipt(
      transactionId: 'mock-transaction',
      status: AztecTransactionStatus.confirmed,
      gasUsed: BigInt.from(100000),
      timestamp: DateTime.now(),
    );
  }

  @override
  Future<AztecTransaction> getTransaction(String transactionId) async {
    // Return a mock transaction
    return AztecTransaction(
      id: transactionId,
      type: AztecTransactionType.transfer,
      fromAccountId: 'mock-account',
      toAccountId: 'mock-account-2',
      assetId: 'eth',
      amount: BigInt.from(1000000000000000000), // 1 ETH
      fee: BigInt.from(100000000000000), // 0.0001 ETH
      nonce: BigInt.from(1),
      timestamp: DateTime.now(),
    );
  }

  @override
  Future<List<AztecTransaction>> getTransactions(String accountId,
      {int limit = 10, int offset = 0}) async {
    // Return mock transactions
    return [
      AztecTransaction(
        id: 'mock-transaction-1',
        type: AztecTransactionType.transfer,
        fromAccountId: accountId,
        toAccountId: 'mock-account-2',
        assetId: 'eth',
        amount: BigInt.from(1000000000000000000), // 1 ETH
        fee: BigInt.from(100000000000000), // 0.0001 ETH
        nonce: BigInt.from(1),
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
      ),
      AztecTransaction(
        id: 'mock-transaction-2',
        type: AztecTransactionType.shield,
        fromAccountId: accountId,
        assetId: 'dai',
        amount: BigInt.from(1000000000000000000), // 1 DAI
        fee: BigInt.from(100000000000000), // 0.0001 ETH
        nonce: BigInt.from(2),
        timestamp: DateTime.now().subtract(const Duration(days: 2)),
      ),
    ];
  }

  @override
  Future<AztecNetworkStatus> getStatus() async {
    // Return a mock status
    return AztecNetworkStatus(
      isConnected: true,
      blockHeight: 1000000,
      syncStatus: 'synced',
      peers: 10,
      version: '1.0.0',
    );
  }
}

/// Mock implementation of KeyManager for testing
class MockKeyManager extends KeyManager {
  /// Constructor for MockKeyManager
  MockKeyManager() : super();

  @override
  Future<void> initialize({String? seedPhrase, String? password}) async {
    // No-op for mock
  }

  @override
  Future<String> getSeedPhrase() async {
    // Return a mock seed phrase
    return 'test test test test test test test test test test test junk';
  }

  @override
  Future<Uint8List> derivePrivateKey(int index) async {
    // Return a mock private key
    return Uint8List.fromList(List.generate(32, (i) => i));
  }

  @override
  Future<Uint8List> derivePublicKey(int index) async {
    // Return a mock public key
    return Uint8List.fromList(List.generate(32, (i) => i + 100));
  }

  @override
  Future<Uint8List> deriveViewingKey(int index) async {
    // Return a mock viewing key
    return Uint8List.fromList(List.generate(32, (i) => i + 200));
  }

  @override
  Future<Uint8List> sign(Uint8List message, int keyIndex) async {
    // Return a mock signature
    return Uint8List.fromList(List.generate(64, (i) => i));
  }

  @override
  Future<bool> verify(
      Uint8List message, Uint8List signature, Uint8List publicKey) async {
    // Always return true for mock
    return true;
  }
}
