
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:web3dart/web3dart.dart';
import '../../../../core/network/web3_client_provider.dart';

part 'balance_remote_datasource.g.dart';

abstract class BalanceRemoteDataSource {
  Future<BigInt> getEthBalance(String address);
  Future<BigInt> getERC20Balance(String tokenAddress, String walletAddress);
}

class BalanceRemoteDataSourceImpl implements BalanceRemoteDataSource {
  final Web3Client _web3Client;

  BalanceRemoteDataSourceImpl(this._web3Client);

  @override
  Future<BigInt> getEthBalance(String address) async {
    try {
      final ethAddress = EthereumAddress.fromHex(address);
      final balance = await _web3Client.getBalance(ethAddress);
      return balance.getInWei;
    } catch (e) {
      // Re-throw or handle error suitable for the app
      throw Exception('Failed to fetch ETH balance: $e');
    }
  }

  @override
  Future<BigInt> getERC20Balance(String tokenAddress, String walletAddress) async {
    try {
      const erc20Abi = '[{"constant":true,"inputs":[{"name":"_owner","type":"address"}],"name":"balanceOf","outputs":[{"name":"balance","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function"}]';
      
      final contract = DeployedContract(
        ContractAbi.fromJson(erc20Abi, 'ERC20'),
        EthereumAddress.fromHex(tokenAddress),
      );
      
      final balanceFunction = contract.function('balanceOf');
      
      final result = await _web3Client.call(
        contract: contract,
        function: balanceFunction,
        params: [EthereumAddress.fromHex(walletAddress)],
      );
      
      if (result.isEmpty) {
        throw Exception('No result returned from contract call');
      }
      
      return result.first as BigInt;
    } catch (e) {
      throw Exception('Failed to fetch ERC20 balance: $e');
    }
  }

  // NOTE: In a real production app, we should use an Indexer API (Alchemy/Infura/TheGraph) 
  // to fetch all tokens held by an address efficiently in one call. 
  // Iterating through a static list is inefficient but works for this demo.
}

@riverpod
BalanceRemoteDataSource balanceRemoteDataSource(BalanceRemoteDataSourceRef ref) {
  final web3Client = ref.watch(web3ClientProvider);
  return BalanceRemoteDataSourceImpl(web3Client);
}
