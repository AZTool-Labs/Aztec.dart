import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:aztecdart/noir/circuit_manager.dart';
import 'package:convert/convert.dart';
import 'package:aztecdart/core/noir_engine.dart';
import 'package:aztecdart/utils/logging.dart';
import 'package:crypto/crypto.dart';
import 'account.dart';
import 'network.dart';
import '../core/proof_generator.dart';

/// Status of an Aztec transaction
enum AztecTransactionStatus {
  /// Transaction is being created
  creating,

  /// Transaction is being signed
  signing,

  /// Transaction is being submitted to the network
  submitting,

  /// Transaction is pending confirmation
  pending,

  /// Transaction has been confirmed
  confirmed,

  /// Transaction has failed
  failed,

  /// Transaction has been rejected
  rejected,
}

/// Type of an Aztec transaction
enum AztecTransactionType {
  /// Transfer of assets between accounts
  transfer,

  /// Shielding of assets (public to private)
  shield,

  /// Unshielding of assets (private to public)
  unshield,

  /// Interaction with a smart contract
  contract,

  /// Deployment of a smart contract
  deploy,
}

/// Represents a transaction on the Aztec Network
class AztecTransaction {
  /// Unique ID of the transaction
  final String id;

  /// Type of the transaction
  final AztecTransactionType type;

  /// Sender account ID
  final String fromAccountId;

  /// Recipient account ID (if applicable)
  final String? toAccountId;

  /// Asset ID being transferred
  final String? assetId;

  /// Amount being transferred
  final BigInt? amount;

  /// Transaction fee
  final BigInt fee;

  /// Transaction nonce
  final BigInt nonce;

  /// Transaction timestamp
  final DateTime timestamp;

  /// Current status of the transaction
  AztecTransactionStatus _status;

  /// Transaction proof
  Proof? _proof;

  /// Transaction signature
  Uint8List? _signature;

  /// Additional transaction data
  final Map<String, dynamic> data;

  /// Logger instance for the AztecTransaction
  final Logger _logger = Logger('AztecTransaction');

  /// Constructor for AztecTransaction
  AztecTransaction({
    required this.id,
    required this.type,
    required this.fromAccountId,
    this.toAccountId,
    this.assetId,
    this.amount,
    required this.fee,
    required this.nonce,
    required this.timestamp,
    AztecTransactionStatus status = AztecTransactionStatus.creating,
    Proof? proof,
    Uint8List? signature,
    Map<String, dynamic>? data,
  })  : _status = status,
        _proof = proof,
        _signature = signature,
        data = data ?? {};

  /// Get the current status of the transaction
  AztecTransactionStatus get status => _status;

  /// Set the status of the transaction
  set status(AztecTransactionStatus value) {
    _status = value;
    _logger.debug('Transaction $id status changed to: $_status');
  }

  /// Get the transaction proof
  Proof? get proof => _proof;

  /// Get the transaction signature
  Uint8List? get signature => _signature;

  /// Create a new transfer transaction
  ///
  /// [from] - The sender account
  /// [to] - The recipient account
  /// [assetId] - The asset to transfer
  /// [amount] - The amount to transfer
  /// [fee] - The transaction fee
  /// [data] - Additional transaction data
  ///
  /// Returns a new AztecTransaction
  static Future<AztecTransaction> createTransfer({
    required AztecAccount from,
    required String toAccountId,
    required String assetId,
    required BigInt amount,
    required BigInt fee,
    Map<String, dynamic>? data,
  }) async {
    try {
      // Generate a transaction ID
      final id = _generateTransactionId();

      // Get the next nonce for the sender account
      final nonce = await _getNextNonce(from);

      // Create the transaction
      final transaction = AztecTransaction(
        id: id,
        type: AztecTransactionType.transfer,
        fromAccountId: from.id,
        toAccountId: toAccountId,
        assetId: assetId,
        amount: amount,
        fee: fee,
        nonce: nonce,
        timestamp: DateTime.now(),
        data: data,
      );

      return transaction;
    } catch (e, stackTrace) {
      throw AztecTransactionException(
          'Failed to create transfer transaction: $e', stackTrace);
    }
  }

  /// Create a new shield transaction (public to private)
  ///
  /// [from] - The sender account
  /// [assetId] - The asset to shield
  /// [amount] - The amount to shield
  /// [fee] - The transaction fee
  /// [data] - Additional transaction data
  ///
  /// Returns a new AztecTransaction
  static Future<AztecTransaction> createShield({
    required AztecAccount from,
    required String assetId,
    required BigInt amount,
    required BigInt fee,
    Map<String, dynamic>? data,
  }) async {
    try {
      // Generate a transaction ID
      final id = _generateTransactionId();

      // Get the next nonce for the sender account
      final nonce = await _getNextNonce(from);

      // Create the transaction
      final transaction = AztecTransaction(
        id: id,
        type: AztecTransactionType.shield,
        fromAccountId: from.id,
        assetId: assetId,
        amount: amount,
        fee: fee,
        nonce: nonce,
        timestamp: DateTime.now(),
        data: data,
      );

      return transaction;
    } catch (e, stackTrace) {
      throw AztecTransactionException(
          'Failed to create shield transaction: $e', stackTrace);
    }
  }

  /// Create a new unshield transaction (private to public)
  ///
  /// [from] - The sender account
  /// [toAccountId] - The recipient account (public)
  /// [assetId] - The asset to unshield
  /// [amount] - The amount to unshield
  /// [fee] - The transaction fee
  /// [data] - Additional transaction data
  ///
  /// Returns a new AztecTransaction
  static Future<AztecTransaction> createUnshield({
    required AztecAccount from,
    required String toAccountId,
    required String assetId,
    required BigInt amount,
    required BigInt fee,
    Map<String, dynamic>? data,
  }) async {
    try {
      // Generate a transaction ID
      final id = _generateTransactionId();

      // Get the next nonce for the sender account
      final nonce = await _getNextNonce(from);

      // Create the transaction
      final transaction = AztecTransaction(
        id: id,
        type: AztecTransactionType.unshield,
        fromAccountId: from.id,
        toAccountId: toAccountId,
        assetId: assetId,
        amount: amount,
        fee: fee,
        nonce: nonce,
        timestamp: DateTime.now(),
        data: data,
      );

      return transaction;
    } catch (e, stackTrace) {
      throw AztecTransactionException(
          'Failed to create unshield transaction: $e', stackTrace);
    }
  }

  /// Generate a unique transaction ID
  static String _generateTransactionId() {
    final random = Uint8List.fromList(
        List.generate(32, (_) => DateTime.now().microsecondsSinceEpoch % 256));
    final hash = sha256.convert(random).bytes;
    return hex.encode(hash);
  }

  /// Get the next nonce for an account
  static Future<BigInt> _getNextNonce(AztecAccount account) async {
    // In a real implementation, this would query the network for the next nonce
    // For now, we'll just return a random nonce
    return BigInt.from(DateTime.now().millisecondsSinceEpoch);
  }

  /// Generate a proof for this transaction
  ///
  /// [circuitManager] - The circuit manager to use
  /// [proofGenerator] - The proof generator to use
  /// [account] - The account to generate the proof for
  ///
  /// Returns the generated proof
  Future<Proof> generateProof(
    CircuitManager circuitManager,
    ProofGenerator proofGenerator,
    AztecAccount account, {
    void Function(double progress)? onProgress,
  }) async {
    try {
      _logger.debug('Generating proof for transaction: $id');

      // Update the transaction status
      status = AztecTransactionStatus.signing;

      // Get the appropriate circuit for this transaction type
      final circuitName = _getCircuitName();
      final circuit = await circuitManager.getCachedCircuit(circuitName);

      if (circuit == null) {
        throw AztecTransactionException('Circuit not found: $circuitName');
      }

      // Prepare the inputs for the circuit
      final inputs = await _prepareCircuitInputs(account);

      // Generate the proof
      final proof = await proofGenerator.generateProofInBackground(
        circuit,
        inputs,
        onProgress: onProgress,
      );

      // Store the proof
      _proof = proof;

      _logger.debug('Proof generated for transaction: $id');

      return proof;
    } catch (e, stackTrace) {
      status = AztecTransactionStatus.failed;
      _logger.error(
          'Failed to generate proof for transaction: $id', e, stackTrace);
      rethrow;
    }
  }

  /// Get the circuit name for this transaction type
  String _getCircuitName() {
    switch (type) {
      case AztecTransactionType.transfer:
        return 'transfer_circuit';
      case AztecTransactionType.shield:
        return 'shield_circuit';
      case AztecTransactionType.unshield:
        return 'unshield_circuit';
      case AztecTransactionType.contract:
        return 'contract_circuit';
      case AztecTransactionType.deploy:
        return 'deploy_circuit';
    }
  }

  /// Prepare the inputs for the circuit
  Future<Map<String, dynamic>> _prepareCircuitInputs(
      AztecAccount account) async {
    // This is a simplified implementation - a real implementation would need
    // to prepare the inputs based on the transaction type and details
    final inputs = <String, dynamic>{
      'from': fromAccountId,
      'to': toAccountId,
      'asset': assetId,
      'amount': amount?.toString(),
      'fee': fee.toString(),
      'nonce': nonce.toString(),
      'timestamp': timestamp.millisecondsSinceEpoch,
    };

    // Add any additional data
    inputs.addAll(data);

    return inputs;
  }

  /// Sign this transaction
  ///
  /// [account] - The account to sign with
  ///
  /// Returns the signature
  Future<Uint8List> sign(AztecAccount account) async {
    try {
      _logger.debug('Signing transaction: $id');

      // Ensure the account is the sender
      if (account.id != fromAccountId) {
        throw AztecTransactionException(
            'Account is not the sender of this transaction');
      }

      // Serialize the transaction for signing
      final message = await _serializeForSigning();

      // Sign the message
      final signature = await account.signMessage(message);

      // Store the signature
      _signature = signature;

      _logger.debug('Transaction signed: $id');

      return signature;
    } catch (e, stackTrace) {
      _logger.error('Failed to sign transaction: $id', e, stackTrace);
      rethrow;
    }
  }

  /// Serialize the transaction for signing
  Future<Uint8List> _serializeForSigning() async {
    // This is a simplified implementation - a real implementation would need
    // to properly serialize the transaction for signing
    jsonEncode({
      'id': id,
      'type': type.toString(),
      'from': fromAccountId,
      'to': toAccountId,
      'asset': assetId,
      'amount': amount?.toString(),
      'fee': fee.toString(),
      'nonce': nonce.toString(),
      'timestamp': timestamp.millisecondsSinceEpoch,
      'data': data,
    });

    return Uint8List.fromList(utf8.encode(jsonEncode(data)));
  }

  /// Submit this transaction to the network
  ///
  /// [network] - The network to submit to
  ///
  /// Returns the transaction receipt
  Future<AztecTransactionReceipt> submit(AztecNetwork network) async {
    try {
      _logger.debug('Submitting transaction: $id');

      // Ensure the transaction has a proof and signature
      if (_proof == null) {
        throw AztecTransactionException('Transaction does not have a proof');
      }

      if (_signature == null) {
        throw AztecTransactionException(
            'Transaction does not have a signature');
      }

      // Update the transaction status
      status = AztecTransactionStatus.submitting;

      // Serialize the transaction for submission
      final serialized = await serialize();

      // Submit the transaction to the network
      final receipt = await network.submitTransaction(serialized);

      // Update the transaction status based on the receipt
      status = receipt.status;

      _logger.debug('Transaction submitted: $id, status: ${receipt.status}');

      return receipt;
    } catch (e, stackTrace) {
      status = AztecTransactionStatus.failed;
      _logger.error('Failed to submit transaction: $id', e, stackTrace);
      rethrow;
    }
  }

  /// Serialize the transaction for submission
  Future<Uint8List> serialize() async {
    try {
      // This is a simplified implementation - a real implementation would need
      // to properly serialize the transaction for submission
      final transactionData = {
        'id': id,
        'type': type.toString(),
        'from': fromAccountId,
        'to': toAccountId,
        'asset': assetId,
        'amount': amount?.toString(),
        'fee': fee.toString(),
        'nonce': nonce.toString(),
        'timestamp': timestamp.millisecondsSinceEpoch,
        'data': data,
        'proof': await _proof?.serialize(),
        'signature': _signature,
      };

      final jsonData = jsonEncode(transactionData);
      return Uint8List.fromList(utf8.encode(jsonData));
    } catch (e, stackTrace) {
      _logger.error('Failed to serialize transaction: $id', e, stackTrace);
      rethrow;
    }
  }

  /// Deserialize a transaction from a binary representation
  static Future<AztecTransaction> deserialize(Uint8List bytes) async {
    try {
      final jsonData = utf8.decode(bytes);
      final data = jsonDecode(jsonData) as Map<String, dynamic>;

      // Parse the transaction data
      final id = data['id'] as String;
      final typeStr = data['type'] as String;
      final type = AztecTransactionType.values.firstWhere(
        (t) => t.toString() == typeStr,
        orElse: () =>
            throw FormatException('Invalid transaction type: $typeStr'),
      );
      final fromAccountId = data['from'] as String;
      final toAccountId = data['to'] as String?;
      final assetId = data['asset'] as String?;
      final amount = data['amount'] != null
          ? BigInt.parse(data['amount'] as String)
          : null;
      final fee = BigInt.parse(data['fee'] as String);
      final nonce = BigInt.parse(data['nonce'] as String);
      final timestamp =
          DateTime.fromMillisecondsSinceEpoch(data['timestamp'] as int);
      final additionalData = data['data'] as Map<String, dynamic>?;

      // Create the transaction
      final transaction = AztecTransaction(
        id: id,
        type: type,
        fromAccountId: fromAccountId,
        toAccountId: toAccountId,
        assetId: assetId,
        amount: amount,
        fee: fee,
        nonce: nonce,
        timestamp: timestamp,
        data: additionalData,
      );

      // Set the proof and signature if available
      if (data['proof'] != null) {
        // In a real implementation, we would deserialize the proof
        // transaction._proof = Proof.fromBytes(data['proof'] as List<int>);
      }

      if (data['signature'] != null) {
        transaction._signature =
            Uint8List.fromList(data['signature'] as List<int>);
      }

      return transaction;
    } catch (e, stackTrace) {
      throw AztecTransactionException(
          'Failed to deserialize transaction: $e', stackTrace);
    }
  }
}

/// Receipt for a submitted transaction
class AztecTransactionReceipt {
  /// Transaction ID
  final String transactionId;

  /// Block number where the transaction was included
  final int? blockNumber;

  /// Transaction status
  final AztecTransactionStatus status;

  /// Gas used by the transaction
  final BigInt gasUsed;

  /// Timestamp of the receipt
  final DateTime timestamp;

  /// Additional receipt data
  final Map<String, dynamic> data;

  /// Constructor for AztecTransactionReceipt
  AztecTransactionReceipt({
    required this.transactionId,
    this.blockNumber,
    required this.status,
    required this.gasUsed,
    required this.timestamp,
    Map<String, dynamic>? data,
  }) : data = data ?? {};
}

/// Exception thrown when there is an error with an Aztec transaction
class AztecTransactionException implements Exception {
  final String message;
  final StackTrace? stackTrace;

  AztecTransactionException(this.message, [this.stackTrace]);

  @override
  String toString() => 'AztecTransactionException: $message';
}
