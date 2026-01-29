
import 'package:http/http.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:riverpod/riverpod.dart';
import 'package:web3dart/web3dart.dart';
import '../constants/env_config.dart';
import '../../shared/providers/network_provider.dart';

part 'web3_client_provider.g.dart';

@riverpod
Web3Client web3Client(Ref ref) {
  final network = ref.watch(selectedNetworkProvider);
  final rpcUrl = EnvConfig.getRpcUrl(network);
  
  final httpClient = Client();
  final web3Client = Web3Client(rpcUrl, httpClient);
  
  ref.onDispose(() {
    web3Client.dispose();
    // Verify if we need to close httpClient explicitly. 
    // Web3Client docs say: "The client will not be closed when this client is disposed."
    // So we should close it.
    httpClient.close();
  });
  
  return web3Client;
}
