
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../core/constants/env_config.dart';

part 'network_provider.g.dart';

@riverpod
class SelectedNetwork extends _$SelectedNetwork {
  @override
  NetworkType build() {
    return NetworkType.sepolia; // Default to Sepolia for development
  }

  void setNetwork(NetworkType network) {
    state = network;
  }
}
