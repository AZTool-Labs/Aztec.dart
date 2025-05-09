import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:aztecdart/noir/circuit_manager.dart';
import 'package:aztecdart/utils/logging.dart';
import 'package:http/http.dart' as http;

import '../aztec/account.dart';
import '../aztec/network.dart';
import '../aztec/transaction.dart';
import '../core/proof_generator.dart';

/// SmartContractManager provides functionality for interacting with smart contracts on the Aztec Network.
///
/// It includes methods for deploying, calling, and querying smart contracts.
class SmartContractManager {
  /// Singleton instance of the SmartContractManager
  static final SmartContractManager _instance =
      SmartContractManager._internal();

  /// Factory constructor to return the singleton instance
  factory SmartContractManager() {
    return _instance;
  }

  /// Private constructor for singleton pattern
  SmartContractManager._internal();

  /// Logger instance for the SmartContractManager
  final Logger _logger = Logger('SmartContractManager');

  /// The circuit manager
  final CircuitManager _circuitManager = CircuitManager();

  /// The proof generator
  final ProofGenerator _proofGenerator = ProofGenerator();

  /// Initialize the smart contract manager
  Future<void> initialize() async {
    try {
      // Initialize the circuit manager
      await _circuitManager.initialize();

      _logger.info('SmartContractManager initialized successfully');
    } catch (e, stackTrace) {
      _logger.error('Failed to initialize SmartContractManager', e, stackTrace);
      rethrow;
    }
  }

  /// Deploy a smart contract
  ///
  /// [account] - The account to deploy the contract from
  /// [network] - The network to deploy the contract to
  /// [contractCode] - The contract code
  /// [constructorArgs] - Arguments for the contract constructor
  /// [fee] - The transaction fee
  ///
  /// Returns the deployed contract
  Future<AztecContract> deployContract(
    AztecAccount account,
    AztecNetwork network,
    String contractCode,
    List<dynamic> constructorArgs,
    BigInt fee,
  ) async {
    try {
      _logger.debug('Deploying contract from account: ${account.id}');

      // Create a deploy transaction
      final transaction = await AztecTransactionExtension.createDeploy(
        from: account,
        fee: fee,
        data: {
          'contractCode': contractCode,
          'constructorArgs': constructorArgs,
        },
      );

      // Generate a proof for the transaction
      final proof = await transaction.generateProof(
        _circuitManager,
        _proofGenerator,
        account,
      );

      // Sign the transaction
      await transaction.sign(account);

      // Submit the transaction
      final receipt = await transaction.submit(network);

      // Check if the transaction was successful
      if (receipt.status != AztecTransactionStatus.confirmed) {
        throw Exception('Contract deployment failed: ${receipt.status}');
      }

      // Get the contract address from the receipt
      final contractAddress = receipt.data['contractAddress'] as String;

      // Create a contract instance
      final contract = AztecContract(
        address: contractAddress,
        code: contractCode,
        network: network,
      );

      _logger.debug('Contract deployed at address: $contractAddress');

      return contract;
    } catch (e, stackTrace) {
      _logger.error('Failed to deploy contract', e, stackTrace);
      rethrow;
    }
  }

  /// Call a smart contract method
  ///
  /// [account] - The account to call the contract from
  /// [contract] - The contract to call
  /// [method] - The method to call
  /// [args] - Arguments for the method
  /// [fee] - The transaction fee
  ///
  /// Returns the transaction receipt
  Future<AztecTransactionReceipt> callContract(
    AztecAccount account,
    AztecContract contract,
    String method,
    List<dynamic> args,
    BigInt fee,
  ) async {
    try {
      _logger.debug(
          'Calling contract method: $method on contract: ${contract.address}');

      // Create a contract transaction
      final transaction = await AztecTransactionExtension.createContract(
        from: account,
        fee: fee,
        data: {
          'contractAddress': contract.address,
          'method': method,
          'args': args,
        },
      );

      // Generate a proof for the transaction
      final proof = await transaction.generateProof(
        _circuitManager,
        _proofGenerator,
        account,
      );

      // Sign the transaction
      await transaction.sign(account);

      // Submit the transaction
      final receipt = await transaction.submit(contract.network);

      _logger
          .debug('Contract method called: $method, status: ${receipt.status}');

      return receipt;
    } catch (e, stackTrace) {
      _logger.error('Failed to call contract method: $method', e, stackTrace);
      rethrow;
    }
  }

  /// Query a smart contract method (read-only)
  ///
  /// [contract] - The contract to query
  /// [method] - The method to query
  /// [args] - Arguments for the method
  ///
  /// Returns the result of the query
  Future<dynamic> queryContract(
    AztecContract contract,
    String method,
    List<dynamic> args,
  ) async {
    try {
      _logger.debug(
          'Querying contract method: $method on contract: ${contract.address}');

      // Prepare the query data
      final queryData = {
        'contractAddress': contract.address,
        'method': method,
        'args': args,
      };

      // Send the query to the network
      final response = await contract.network.queryContract(queryData);

      _logger.debug('Contract query result: $response');

      return response;
    } catch (e, stackTrace) {
      _logger.error('Failed to query contract method: $method', e, stackTrace);
      rethrow;
    }
  }

  /// Load a contract from its address
  ///
  /// [address] - The contract address
  /// [network] - The network the contract is on
  ///
  /// Returns the contract
  Future<AztecContract> loadContract(
    String address,
    AztecNetwork network,
  ) async {
    try {
      _logger.debug('Loading contract at address: $address');

      // Get the contract code from the network
      final code = await network.getContractCode(address);

      // Create a contract instance
      final contract = AztecContract(
        address: address,
        code: code,
        network: network,
      );

      _logger.debug('Contract loaded: $address');

      return contract;
    } catch (e, stackTrace) {
      _logger.error('Failed to load contract: $address', e, stackTrace);
      rethrow;
    }
  }
}

/// Represents a smart contract on the Aztec Network
class AztecContract {
  /// The contract address
  final String address;

  /// The contract code
  final String code;

  /// The network the contract is on
  final AztecNetwork network;

  /// Constructor for AztecContract
  AztecContract({
    required this.address,
    required this.code,
    required this.network,
  });
}

/// Extension methods for AztecTransaction
extension AztecTransactionExtension on AztecTransaction {
  /// Create a deploy transaction
  static Future<AztecTransaction> createDeploy({
    required AztecAccount from,
    required BigInt fee,
    Map<String, dynamic>? data,
  }) async {
    // Generate a transaction ID
    final id = _generateTransactionId();

    // Get the next nonce for the sender account
    final nonce = await _getNextNonce(from);

    // Create the transaction
    final transaction = AztecTransaction(
      id: id,
      type: AztecTransactionType.deploy,
      fromAccountId: from.id,
      fee: fee,
      nonce: nonce,
      timestamp: DateTime.now(),
      data: data ?? {},
    );

    return transaction;
  }

  /// Create a contract transaction
  static Future<AztecTransaction> createContract({
    required AztecAccount from,
    required BigInt fee,
    Map<String, dynamic>? data,
  }) async {
    // Generate a transaction ID
    final id = _generateTransactionId();

    // Get the next nonce for the sender account
    final nonce = await _getNextNonce(from);

    // Create the transaction
    final transaction = AztecTransaction(
      id: id,
      type: AztecTransactionType.contract,
      fromAccountId: from.id,
      fee: fee,
      nonce: nonce,
      timestamp: DateTime.now(),
      data: data ?? {},
    );

    return transaction;
  }

  /// Generate a unique transaction ID
  static String _generateTransactionId() {
    final random = Uint8List.fromList(
        List.generate(32, (_) => DateTime.now().microsecondsSinceEpoch % 256));
    final hash = utf8.encode(random.toString());
    return base64Encode(hash);
  }

  /// Get the next nonce for an account
  static Future<BigInt> _getNextNonce(AztecAccount account) async {
    // In a real implementation, this would query the network for the next nonce
    // For now, we'll just return a random nonce
    return BigInt.from(DateTime.now().millisecondsSinceEpoch);
  }
}

/// Extension methods for AztecNetwork
extension AztecNetworkExtension on AztecNetwork {
  /// HTTP client for network requests
  static final http.Client _client = http.Client();

  /// Query a contract
  Future<dynamic> queryContract(Map<String, dynamic> queryData) async {
    try {
      // Send the query to the network
      final response = await _client.post(
        Uri.parse('$url/contracts/query'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(queryData),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to query contract: ${response.statusCode}');
      }

      return jsonDecode(response.body);
    } catch (e, stackTrace) {
      throw Exception('Failed to query contract: $e');
    }
  }

  /// Get the code of a contract
  Future<String> getContractCode(String address) async {
    try {
      // Get the contract code from the network
      final response = await _client.get(
        Uri.parse('$url/contracts/$address/code'),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to get contract code: ${response.statusCode}');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data['code'] as String;
    } catch (e, stackTrace) {
      throw Exception('Failed to get contract code: $e');
    }
  }
}
