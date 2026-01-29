import 'dart:io';

import 'package:crypto_wallet_pro/core/constants/env_config.dart';
import 'package:crypto_wallet_pro/features/dashboard/data/datasources/balance_remote_datasource.dart';
import 'package:crypto_wallet_pro/features/dashboard/data/repositories/balance_repository_impl.dart';
import 'package:crypto_wallet_pro/features/nft/data/datasources/nft_remote_datasource.dart';
import 'package:crypto_wallet_pro/features/send/data/datasources/transaction_remote_datasource.dart';
import 'package:crypto_wallet_pro/features/send/domain/entities/gas_estimate.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:web3dart/web3dart.dart';

Map<String, String> _parseEnvFile(String content) {
  final map = <String, String>{};
  for (final rawLine in content.split('\n')) {
    var line = rawLine.trim();
    if (line.isEmpty || line.startsWith('#')) continue;
    if (line.startsWith('export ')) {
      line = line.substring(7).trim();
    }
    final idx = line.indexOf('=');
    if (idx <= 0) continue;
    final key = line.substring(0, idx).trim();
    var value = line.substring(idx + 1).trim();
    if ((value.startsWith('"') && value.endsWith('"')) ||
        (value.startsWith("'") && value.endsWith("'"))) {
      value = value.substring(1, value.length - 1);
    }
    map[key] = value;
  }
  return map;
}

final Map<String, String> _fileEnv = () {
  final file = File('.env');
  if (!file.existsSync()) return <String, String>{};
  return _parseEnvFile(file.readAsStringSync());
}();

String? _envValue(String key) => Platform.environment[key] ?? _fileEnv[key];

bool _hasEnv(String key) => (_envValue(key)?.trim().isNotEmpty ?? false);

String _buildEnvString() {
  final file = File('.env');
  final fileContent = file.existsSync() ? file.readAsStringSync() : '';
  final platformLines = Platform.environment.entries
      .map((entry) => '${entry.key}=${entry.value}')
      .join('\n');
  if (fileContent.isEmpty) return platformLines;
  if (platformLines.isEmpty) return fileContent;
  return '$fileContent\n$platformLines';
}

String _sepoliaRpcUrl(String apiKey) =>
    'https://eth-sepolia.g.alchemy.com/v2/$apiKey';

String? _resolveWalletAddress() {
  final address = _envValue('TEST_WALLET_ADDRESS');
  if (address != null && address.trim().isNotEmpty) return address.trim();
  final privateKey = _envValue('TEST_PRIVATE_KEY');
  if (privateKey == null || privateKey.trim().isEmpty) return null;
  final credentials = EthPrivateKey.fromHex(privateKey.trim());
  return credentials.address.hexEip55;
}

void main() {
  final hasAlchemyKey = _hasEnv('ALCHEMY_API_KEY');
  final hasWalletAddress =
      _hasEnv('TEST_WALLET_ADDRESS') || _hasEnv('TEST_PRIVATE_KEY');
  final hasTokenAddress = _hasEnv('TEST_ERC20_ADDRESS');
  final sendEnabled = _envValue('E2E_ENABLE_SEND')?.toLowerCase() == 'true';
  final hasPrivateKey = _hasEnv('TEST_PRIVATE_KEY');

  late http.Client httpClient;
  late Web3Client web3Client;
  late BalanceRemoteDataSourceImpl balanceRemote;
  late BalanceRepositoryImpl balanceRepository;
  late TransactionRemoteDataSourceImpl transactionRemote;
  late NftRemoteDataSourceImpl nftRemote;

  setUpAll(() {
    final envString = _buildEnvString();
    dotenv.loadFromString(envString: envString, isOptional: true);

    if (!hasAlchemyKey) return;
    final apiKey = _envValue('ALCHEMY_API_KEY')!.trim();

    httpClient = http.Client();
    web3Client = Web3Client(_sepoliaRpcUrl(apiKey), httpClient);
    balanceRemote = BalanceRemoteDataSourceImpl(web3Client);
    balanceRepository = BalanceRepositoryImpl(balanceRemote);
    transactionRemote = TransactionRemoteDataSourceImpl(web3Client);
    nftRemote = NftRemoteDataSourceImpl(Dio(), NetworkType.sepolia);
  });

  tearDownAll(() {
    if (hasAlchemyKey) {
      web3Client.dispose();
      httpClient.close();
    }
  });

  group('Sepolia real flow (no mocks)', () {
    test(
      'ETH balance fetch succeeds',
      () async {
        final address = _resolveWalletAddress()!;
        final balance = await balanceRemote.getEthBalance(address);
        expect(balance >= BigInt.zero, isTrue);
      },
      skip: !hasAlchemyKey || !hasWalletAddress
          ? 'Missing ALCHEMY_API_KEY or TEST_WALLET_ADDRESS/TEST_PRIVATE_KEY'
          : false,
      timeout: const Timeout(Duration(seconds: 30)),
    );

    test(
      'ERC-20 balance fetch succeeds (optional token)',
      () async {
        final address = _resolveWalletAddress()!;
        final tokenAddress = _envValue('TEST_ERC20_ADDRESS')!;
        final balance = await balanceRemote.getERC20Balance(
          tokenAddress.trim(),
          address,
        );
        expect(balance >= BigInt.zero, isTrue);
      },
      skip: !hasAlchemyKey || !hasWalletAddress || !hasTokenAddress
          ? 'Missing ALCHEMY_API_KEY, TEST_WALLET_ADDRESS/TEST_PRIVATE_KEY, or TEST_ERC20_ADDRESS'
          : false,
      timeout: const Timeout(Duration(seconds: 30)),
    );

    test(
      'Token list fetch via repository completes',
      () async {
        final address = _resolveWalletAddress()!;
        final result = await balanceRepository.getTokens(address);
        result.match(
          (failure) => fail('Token fetch failed: ${failure.message}'),
          (tokens) => expect(tokens, isA<List>()),
        );
      },
      skip: !hasAlchemyKey || !hasWalletAddress
          ? 'Missing ALCHEMY_API_KEY or TEST_WALLET_ADDRESS/TEST_PRIVATE_KEY'
          : false,
      timeout: const Timeout(Duration(seconds: 45)),
    );

    test(
      'Gas estimation succeeds (ETH transfer)',
      () async {
        final address = _resolveWalletAddress()!;
        final recipient =
            (_envValue('TEST_RECIPIENT_ADDRESS') ?? address).trim();
        final estimates = await transactionRemote.getGasEstimates(
          senderAddress: address,
          recipientAddress: recipient,
          amountInWei: BigInt.from(1000000000000), // 0.000001 ETH
        );
        expect(estimates[GasPriority.low]!.estimatedFeeInWei > BigInt.zero, isTrue);
        expect(estimates[GasPriority.medium]!.estimatedFeeInWei > BigInt.zero, isTrue);
        expect(estimates[GasPriority.high]!.estimatedFeeInWei > BigInt.zero, isTrue);
      },
      skip: !hasAlchemyKey || !hasWalletAddress
          ? 'Missing ALCHEMY_API_KEY or TEST_WALLET_ADDRESS/TEST_PRIVATE_KEY'
          : false,
      timeout: const Timeout(Duration(seconds: 30)),
    );

    test(
      'Send transaction succeeds (opt-in)',
      () async {
        final privateKey = _envValue('TEST_PRIVATE_KEY')!.trim();
        final credentials = EthPrivateKey.fromHex(privateKey);
        final sender = credentials.address.hexEip55;
        final recipient =
            (_envValue('TEST_RECIPIENT_ADDRESS') ?? sender).trim();

        final estimates = await transactionRemote.getGasEstimates(
          senderAddress: sender,
          recipientAddress: recipient,
          amountInWei: BigInt.from(1000000000000), // 0.000001 ETH
        );

        final params = SendTransactionParams(
          senderAddress: sender,
          recipientAddress: recipient,
          amountInWei: BigInt.from(1000000000000),
          gasEstimate: estimates[GasPriority.low]!,
        );

        final txHash = await transactionRemote.sendTransaction(
          params: params,
          privateKey: privateKey,
        );
        expect(txHash.startsWith('0x'), isTrue);
        expect(txHash.length > 10, isTrue);
      },
      skip: !sendEnabled || !hasAlchemyKey || !hasPrivateKey
          ? 'Set E2E_ENABLE_SEND=true and provide ALCHEMY_API_KEY + TEST_PRIVATE_KEY'
          : false,
      timeout: const Timeout(Duration(seconds: 60)),
    );

    test(
      'NFT fetch succeeds',
      () async {
        final address = _resolveWalletAddress()!;
        final nfts = await nftRemote.getNfts(address);
        expect(nfts, isA<List>());
      },
      skip: !hasAlchemyKey || !hasWalletAddress
          ? 'Missing ALCHEMY_API_KEY or TEST_WALLET_ADDRESS/TEST_PRIVATE_KEY'
          : false,
      timeout: const Timeout(Duration(seconds: 45)),
    );
  });
}
