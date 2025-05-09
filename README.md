### Aztec.dart
A comprehensive Flutter SDK for Noir and Aztec Network integration
Build privacy-preserving applications with zero-knowledge proofs


## Overview

Aztec.dart is a Flutter SDK that provides a comprehensive toolkit for integrating zero-knowledge proofs using Noir and interacting with the Aztec Network. It enables developers to build privacy-preserving applications with features like private transactions, zero-knowledge smart contracts, and secure cross-chain operations.

## Features

- 🔐 **Zero-Knowledge Proofs**: Generate and verify zero-knowledge proofs using the Noir language
- 🌐 **Aztec Network Integration**: Seamless interaction with the Aztec Network
- 💼 **Account Management**: Create, import, and manage Aztec accounts
- 💰 **Asset Operations**: Handle private and public assets
- 📝 **Transaction Support**: Create, sign, and submit private transactions
- 🔄 **Cross-Chain Functionality**: Bridge assets between Aztec and other chains
- 📱 **Platform Integration**: Native support for Android and iOS
- 🧩 **Plugin System**: Extensible architecture for custom functionality
- 🔒 **Security Features**: Biometric authentication, secure storage, and device security checks


## Architecture

Aztec.dart follows a modular architecture designed for flexibility, security, and performance:


### Core Components

- **Core Module**: Handles zero-knowledge proof generation and verification
- **Crypto Module**: Provides cryptographic primitives for secure operations
- **Network Module**: Manages communication with the Aztec Network
- **Flutter Integration**: Bridges the SDK with Flutter applications
- **Plugin System**: Enables extensibility through custom plugins


## Installation

Add Aztec.dart to your `pubspec.yaml`:

```yaml
dependencies:
  aztec_dart: ^0.1.0
```

Then run:

```shellscript
flutter pub get
```

### Platform Configuration

#### Android

Add the following to your `android/app/build.gradle`:

```plaintext
android {
    defaultConfig {
        // ...
        ndk {
            abiFilters 'armeabi-v7a', 'arm64-v8a', 'x86_64'
        }
    }
}
```

#### iOS

Add the following to your `ios/Runner/Info.plist`:

```xml
<key>NSFaceIDUsageDescription</key>
<string>This app uses Face ID for secure authentication</string>
```

## Usage

### Initialization

```plaintext
import 'package:aztec_dart/aztec_dart.dart';

Future<void> initializeAztec() async {
  // Initialize the Noir runtime
  final noirRuntime = NoirRuntime();
  await noirRuntime.initialize();
  
  // Initialize the circuit manager
  final circuitManager = CircuitManager();
  await circuitManager.initialize();
  
  // Connect to the Aztec Network (testnet)
  final network = await AztecNetworkClientFactory.createTestnet();
  
  // Initialize the key manager
  final keyManager = KeyManager();
  await keyManager.initialize();
}
```

### Account Management

```plaintext
// Create a new account
final account = await AztecAccount.create(
  keyManager: keyManager,
  client: network,
  name: 'My Aztec Account',
);

// Get account balance
final balance = await account.getBalance('eth');
print('ETH Balance: $balance');

// Export account (for backup)
final accountData = await account.export();
```

### Zero-Knowledge Proofs

```plaintext
// Compile a Noir circuit
final circuit = await circuitManager.compileCircuit(
  noirSource,
  name: 'my_circuit',
);

// Create a witness (inputs for the circuit)
final witness = Witness();
witness.addPrivateInput('amount', 100);
witness.addPublicInput('recipient', '0x123...');

// Generate a proof
final proof = await Prover().generateProof(circuit, witness);

// Verify the proof
final isValid = await Verifier().verifyProof(
  circuit,
  proof,
  publicInputs: {'recipient': '0x123...'},
);
```

### Private Transactions

```plaintext
// Create a transfer transaction
final transaction = await AztecTransaction.createTransfer(
  from: account,
  toAccountId: recipientId,
  assetId: 'eth',
  amount: BigInt.from(1000000000000000000), // 1 ETH
  fee: BigInt.from(100000000000000), // 0.0001 ETH
);

// Generate a proof for the transaction
final proof = await transaction.generateProof(
  circuitManager,
  Prover(),
  account,
  onProgress: (progress) {
    print('Proof generation progress: ${(progress * 100).toStringAsFixed(1)}%');
  },
);

// Sign the transaction
await transaction.sign(account);

// Submit the transaction
final receipt = await transaction.submit(network);
```

### UI Components

```plaintext
// Display an account
AztecAccountCard(
  account: account,
  onTap: () {
    // Handle tap
  },
);

// Display an asset balance
AztecAssetBalanceCard(
  asset: asset,
  balance: balance,
  onTap: () {
    // Handle tap
  },
);

// Create a transaction form
AztecTransactionForm(
  fromAccount: account,
  assets: assets,
  onTransactionCreated: (transaction) {
    // Handle the created transaction
  },
);
```

## Project Structure

```plaintext
lib/
├── aztec_dart.dart          # Main library file
├── src/
│   ├── core/                # Core ZK-proof functionality
│   │   ├── noir_runtime.dart
│   │   ├── circuit_manager.dart
│   │   ├── prover.dart
│   │   ├── verifier.dart
│   │   └── witness.dart
│   ├── crypto/              # Cryptographic primitives
│   │   ├── key_manager.dart
│   │   ├── hash.dart
│   │   ├── signature.dart
│   │   └── encryption.dart
│   ├── network/             # Aztec Network integration
│   │   ├── account.dart
│   │   ├── asset.dart
│   │   ├── transaction.dart
│   │   └── client.dart
│   ├── flutter/             # Flutter integration
│   │   ├── ui_components.dart
│   │   ├── platform_bindings.dart
│   │   └── state_management.dart
│   ├── advanced/            # Advanced features
│   │   ├── smart_contract.dart
│   │   ├── cross_chain.dart
│   │   └── privacy.dart
│   ├── plugins/             # Plugin system
│   │   ├── plugin_manager.dart
│   │   └── plugin_interface.dart
│   └── utils/               # Utilities
│       ├── logger.dart
│       ├── error_handler.dart
│       └── test_utils.dart
├── android/                 # Android platform code
│   └── src/main/kotlin/...
└── ios/                     # iOS platform code
    └── Classes/...
```

## Security Considerations

Aztec.dart implements several security features to protect user data and assets:

- **Secure Key Storage**: Private keys are stored securely using platform-specific secure storage
- **Biometric Authentication**: Support for fingerprint and face recognition
- **Device Security Checks**: Detection of rooted/jailbroken devices
- **Encrypted Storage**: Sensitive data is encrypted at rest
- **Memory Protection**: Sensitive data is cleared from memory when no longer needed
- **Secure Communication**: All network communication uses TLS


## Roadmap

- **Noir Circuit Library**: Pre-compiled common circuits
- **Account Recovery**: Social recovery and backup mechanisms
- **Hardware Wallet Support**: Integration with hardware wallets
- **Multi-signature Accounts**: Support for multi-signature operations
- **Recursive Proofs**: Support for recursive proof composition
- **Mobile Wallet Reference App**: Complete wallet application example
- **Desktop Support**: Extend to desktop platforms
- **Web Support**: WASM-based implementation for web applications


## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request


## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgements

- [Aztec Network](https://aztec.network/) for their groundbreaking work on privacy technology
- [Noir](https://noir-lang.org/) for the zero-knowledge proof language
- The Flutter team for their excellent cross-platform framework


---

Built with ❤️ for privacy and security
