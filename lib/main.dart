import 'package:aztecdart/aztec/account.dart';
import 'package:aztecdart/aztec/asset.dart';
import 'package:aztecdart/crypto/key_manager.dart';
import 'package:aztecdart/network/client.dart';
import 'package:aztecdart/noir/circuit_manager.dart';
import 'package:aztecdart/noir/noir_runtime.dart';
import 'package:aztecdart/utils/error_handler.dart';
import 'package:aztecdart/utils/logging.dart';
import 'package:flutter/material.dart';
// import 'package:aztec_dart/aztec_dart.dart';

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize error handling
  ErrorHandler.initialize();

  // Set up logging
  Logger.setMinLevel(LogLevel.debug);
  final logger = Logger('Main');

  try {
    // Initialize the Noir runtime
    final noirRuntime = NoirRuntime();
    await noirRuntime.initialize();
    logger.info('Noir runtime initialized successfully');

    // Initialize the circuit manager
    final circuitManager = CircuitManager();
    await circuitManager.initialize();
    logger.info('Circuit manager initialized successfully');

    // Connect to the Aztec Network (testnet for example)
    final networkClient = await AztecNetworkClientFactory.createTestnet();
    logger.info('Connected to Aztec Network: ${networkClient.name}');

    // Run the app
    runApp(AztecDartExampleApp(
      noirRuntime: noirRuntime,
      circuitManager: circuitManager,
      networkClient: networkClient,
    ));
  } catch (e, stackTrace) {
    logger.error('Failed to initialize app', e, stackTrace);
    // Show an error screen or handle the error appropriately
    runApp(ErrorApp(error: e.toString()));
  }
}

class AztecDartExampleApp extends StatelessWidget {
  final NoirRuntime noirRuntime;
  final CircuitManager circuitManager;
  final AztecNetworkClient networkClient;

  const AztecDartExampleApp({
    super.key,
    required this.noirRuntime,
    required this.circuitManager,
    required this.networkClient,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aztec.dart Example',
      theme: ThemeData(
        primarySwatch: Colors.purple,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: HomePage(
        noirRuntime: noirRuntime,
        circuitManager: circuitManager,
        networkClient: networkClient,
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  final NoirRuntime noirRuntime;
  final CircuitManager circuitManager;
  final AztecNetworkClient networkClient;

  const HomePage({
    super.key,
    required this.noirRuntime,
    required this.circuitManager,
    required this.networkClient,
  });

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final logger = Logger('HomePage');
  KeyManager? keyManager;
  AztecAccount? account;
  List<AztecAsset> assets = [];
  bool isLoading = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeAccount();
  }

  Future<void> _initializeAccount() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      // Initialize key manager
      keyManager = KeyManager();
      await keyManager!.initialize();
      logger.info('Key manager initialized');

      // Create or load an account
      account = await AztecAccount.create(
        keyManager: keyManager!,
        client: widget.networkClient,
        network: widget.networkClient.network,
        name: 'Example Account',
      );
      logger.info('Account created: ${account!.id}');

      // Get available assets
      assets = await widget.networkClient.getAssets();
      logger.info('Loaded ${assets.length} assets');

      setState(() {
        isLoading = false;
      });
    } catch (e, stackTrace) {
      logger.error('Failed to initialize account', e, stackTrace);
      setState(() {
        isLoading = false;
        errorMessage = 'Failed to initialize: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Aztec.dart Example'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? Center(child: Text('Error: $errorMessage'))
              : account == null
                  ? const Center(child: Text('No account initialized'))
                  : _buildAccountView(),
    );
  }

  Widget _buildAccountView() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Account: ${account!.name ?? 'Unnamed'}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          Text('ID: ${account!.id}'),
          const SizedBox(height: 16),
          Text(
            'Assets',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          Expanded(
            child: assets.isEmpty
                ? const Center(child: Text('No assets available'))
                : ListView.builder(
                    itemCount: assets.length,
                    itemBuilder: (context, index) {
                      final asset = assets[index];
                      return ListTile(
                        title: Text('${asset.name} (${asset.symbol})'),
                        subtitle: Text(
                            'Decimals: ${asset.decimals}, Private: ${asset.isPrivate}'),
                        onTap: () => _showAssetDetails(asset),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showAssetDetails(AztecAsset asset) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${asset.name} (${asset.symbol})'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ID: ${asset.id}'),
            Text('Decimals: ${asset.decimals}'),
            Text('Private: ${asset.isPrivate}'),
            if (asset.l1Address != null) Text('L1 Address: ${asset.l1Address}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    widget.networkClient.close();
    super.dispose();
  }
}

class ErrorApp extends StatelessWidget {
  final String error;

  const ErrorApp({Key? key, required this.error}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                const Text(
                  'Failed to initialize application',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(error),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
