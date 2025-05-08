import 'package:flutter/material.dart';
import '../aztec/account.dart';
import '../aztec/asset.dart';
import '../aztec/transaction.dart';

/// UI components for Aztec integration in Flutter applications.
///
/// This file contains reusable UI components for displaying Aztec-related
/// information and interacting with the Aztec Network.

/// A widget that displays an Aztec account
class AztecAccountCard extends StatelessWidget {
  /// The account to display
  final AztecAccount account;

  /// Callback when the account is tapped
  final VoidCallback? onTap;

  /// Constructor for AztecAccountCard
  const AztecAccountCard({
    Key? key,
    required this.account,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                account.name ?? 'Account',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8.0),
              Text(
                'ID: ${account.id}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 4.0),
              Text(
                'Index: ${account.index}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A widget that displays an Aztec asset balance
class AztecAssetBalanceCard extends StatelessWidget {
  /// The asset to display
  final AztecAsset asset;

  /// The balance of the asset
  final BigInt balance;

  /// Callback when the asset is tapped
  final VoidCallback? onTap;

  /// Constructor for AztecAssetBalanceCard
  const AztecAssetBalanceCard({
    Key? key,
    required this.asset,
    required this.balance,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // Asset icon or placeholder
              Container(
                width: 40.0,
                height: 40.0,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(20.0),
                ),
                child: Center(
                  child: Text(
                    asset.symbol.substring(0, 1),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ),
              const SizedBox(width: 16.0),
              // Asset details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      asset.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      asset.symbol,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              // Balance
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    asset.formatAmount(balance),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    asset.isPrivate ? 'Private' : 'Public',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: asset.isPrivate ? Colors.green : Colors.blue,
                        ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A widget that displays an Aztec transaction
class AztecTransactionCard extends StatelessWidget {
  /// The transaction to display
  final AztecTransaction transaction;

  /// The asset associated with the transaction
  final AztecAsset? asset;

  /// Callback when the transaction is tapped
  final VoidCallback? onTap;

  /// Constructor for AztecTransactionCard
  const AztecTransactionCard({
    Key? key,
    required this.transaction,
    this.asset,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Transaction type and status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _getTransactionTypeLabel(transaction.type),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  _buildStatusChip(context, transaction.status),
                ],
              ),
              const SizedBox(height: 8.0),
              // Transaction details
              if (asset != null && transaction.amount != null)
                Text(
                  '${asset!.formatAmount(transaction.amount!)} ${asset!.symbol}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              const SizedBox(height: 4.0),
              // Transaction ID
              Text(
                'ID: ${transaction.id}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 4.0),
              // Transaction timestamp
              Text(
                'Date: ${transaction.timestamp.toLocal()}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Get a human-readable label for a transaction type
  String _getTransactionTypeLabel(AztecTransactionType type) {
    switch (type) {
      case AztecTransactionType.transfer:
        return 'Transfer';
      case AztecTransactionType.shield:
        return 'Shield';
      case AztecTransactionType.unshield:
        return 'Unshield';
      case AztecTransactionType.contract:
        return 'Contract';
      case AztecTransactionType.deploy:
        return 'Deploy';
    }
  }

  /// Build a chip for the transaction status
  Widget _buildStatusChip(BuildContext context, AztecTransactionStatus status) {
    Color color;
    String label;

    switch (status) {
      case AztecTransactionStatus.creating:
        color = Colors.grey;
        label = 'Creating';
        break;
      case AztecTransactionStatus.signing:
        color = Colors.orange;
        label = 'Signing';
        break;
      case AztecTransactionStatus.submitting:
        color = Colors.blue;
        label = 'Submitting';
        break;
      case AztecTransactionStatus.pending:
        color = Colors.amber;
        label = 'Pending';
        break;
      case AztecTransactionStatus.confirmed:
        color = Colors.green;
        label = 'Confirmed';
        break;
      case AztecTransactionStatus.failed:
        color = Colors.red;
        label = 'Failed';
        break;
      case AztecTransactionStatus.rejected:
        color = Colors.red.shade900;
        label = 'Rejected';
        break;
    }

    return Chip(
      backgroundColor: color.withOpacity(0.2),
      label: Text(
        label,
        style: TextStyle(color: color),
      ),
    );
  }
}

/// A widget for creating a new transaction
class AztecTransactionForm extends StatefulWidget {
  /// The sender account
  final AztecAccount fromAccount;

  /// The available assets
  final List<AztecAsset> assets;

  /// Callback when a transaction is created
  final void Function(AztecTransaction transaction)? onTransactionCreated;

  /// Constructor for AztecTransactionForm
  const AztecTransactionForm({
    Key? key,
    required this.fromAccount,
    required this.assets,
    this.onTransactionCreated,
  }) : super(key: key);

  @override
  State<AztecTransactionForm> createState() => _AztecTransactionFormState();
}

class _AztecTransactionFormState extends State<AztecTransactionForm> {
  AztecTransactionType _transactionType = AztecTransactionType.transfer;
  AztecAsset? _selectedAsset;
  final TextEditingController _toAccountController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _feeController = TextEditingController();

  @override
  void initState() {
    super.initState();

    // Set default values
    if (widget.assets.isNotEmpty) {
      _selectedAsset = widget.assets.first;
    }
    _feeController.text = '0.001';
  }

  @override
  void dispose() {
    _toAccountController.dispose();
    _amountController.dispose();
    _feeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Transaction type selector
          Text(
            'Transaction Type',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8.0),
          DropdownButtonFormField<AztecTransactionType>(
            value: _transactionType,
            onChanged: (value) {
              setState(() {
                _transactionType = value!;
              });
            },
            items: AztecTransactionType.values.map((type) {
              return DropdownMenuItem<AztecTransactionType>(
                value: type,
                child: Text(_getTransactionTypeLabel(type)),
              );
            }).toList(),
          ),
          const SizedBox(height: 16.0),

          // Asset selector
          Text(
            'Asset',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8.0),
          DropdownButtonFormField<AztecAsset>(
            value: _selectedAsset,
            onChanged: (value) {
              setState(() {
                _selectedAsset = value;
              });
            },
            items: widget.assets.map((asset) {
              return DropdownMenuItem<AztecAsset>(
                value: asset,
                child: Text('${asset.name} (${asset.symbol})'),
              );
            }).toList(),
          ),
          const SizedBox(height: 16.0),

          // To account field (for transfer and unshield)
          if (_transactionType == AztecTransactionType.transfer ||
              _transactionType == AztecTransactionType.unshield)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'To Account',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8.0),
                TextFormField(
                  controller: _toAccountController,
                  decoration: const InputDecoration(
                    hintText: 'Enter recipient account ID',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16.0),
              ],
            ),

          // Amount field
          Text(
            'Amount',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8.0),
          TextFormField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              hintText: 'Enter amount',
              border: const OutlineInputBorder(),
              suffixText: _selectedAsset?.symbol,
            ),
          ),
          const SizedBox(height: 16.0),

          // Fee field
          Text(
            'Fee',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8.0),
          TextFormField(
            controller: _feeController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              hintText: 'Enter fee',
              border: OutlineInputBorder(),
              suffixText: 'ETH',
            ),
          ),
          const SizedBox(height: 24.0),

          // Create transaction button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _createTransaction,
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 12.0),
                child: Text('Create Transaction'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Get a human-readable label for a transaction type
  String _getTransactionTypeLabel(AztecTransactionType type) {
    switch (type) {
      case AztecTransactionType.transfer:
        return 'Transfer';
      case AztecTransactionType.shield:
        return 'Shield';
      case AztecTransactionType.unshield:
        return 'Unshield';
      case AztecTransactionType.contract:
        return 'Contract';
      case AztecTransactionType.deploy:
        return 'Deploy';
    }
  }

  /// Create a transaction from the form data
  Future<void> _createTransaction() async {
    if (_selectedAsset == null) {
      _showError('Please select an asset');
      return;
    }

    if (_amountController.text.isEmpty) {
      _showError('Please enter an amount');
      return;
    }

    if (_feeController.text.isEmpty) {
      _showError('Please enter a fee');
      return;
    }

    if ((_transactionType == AztecTransactionType.transfer ||
            _transactionType == AztecTransactionType.unshield) &&
        _toAccountController.text.isEmpty) {
      _showError('Please enter a recipient account ID');
      return;
    }

    try {
      // Parse the amount and fee
      final amount = _selectedAsset!.parseAmount(_amountController.text);
      final fee = BigInt.parse((_feeController.text.contains('.')
          ? _feeController.text.replaceAll('.', '')
          : _feeController.text + '000000000000000000'));

      // Create the transaction based on the type
      AztecTransaction transaction;

      switch (_transactionType) {
        case AztecTransactionType.transfer:
          transaction = await AztecTransaction.createTransfer(
            from: widget.fromAccount,
            toAccountId: _toAccountController.text,
            assetId: _selectedAsset!.id,
            amount: amount,
            fee: fee,
          );
          break;
        case AztecTransactionType.shield:
          transaction = await AztecTransaction.createShield(
            from: widget.fromAccount,
            assetId: _selectedAsset!.id,
            amount: amount,
            fee: fee,
          );
          break;
        case AztecTransactionType.unshield:
          transaction = await AztecTransaction.createUnshield(
            from: widget.fromAccount,
            toAccountId: _toAccountController.text,
            assetId: _selectedAsset!.id,
            amount: amount,
            fee: fee,
          );
          break;
        default:
          _showError('Unsupported transaction type');
          return;
      }

      // Call the callback
      if (widget.onTransactionCreated != null) {
        widget.onTransactionCreated!(transaction);
      }

      // Clear the form
      _amountController.clear();
      _toAccountController.clear();

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Transaction created successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      _showError('Failed to create transaction: $e');
    }
  }

  /// Show an error message
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}

/// A widget for displaying proof generation progress
class ProofGenerationProgressDialog extends StatelessWidget {
  /// The current progress (0.0 to 1.0)
  final double progress;

  /// Constructor for ProofGenerationProgressDialog
  const ProofGenerationProgressDialog({
    Key? key,
    required this.progress,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Generating Proof',
              style: TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16.0),
            LinearProgressIndicator(
              value: progress,
            ),
            const SizedBox(height: 8.0),
            Text('${(progress * 100).toStringAsFixed(1)}%'),
            const SizedBox(height: 16.0),
            const Text(
              'This may take a few moments...',
              style: TextStyle(
                fontSize: 14.0,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
