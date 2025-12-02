import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/nft.dart';

/// NFT gallery state
class NftState {
  final List<Nft> nfts;
  final Nft? selectedNft;
  final bool isLoading;
  final String? error;
  final NftFilter filter;

  const NftState({
    this.nfts = const [],
    this.selectedNft,
    this.isLoading = false,
    this.error,
    this.filter = NftFilter.all,
  });

  NftState copyWith({
    List<Nft>? nfts,
    Nft? selectedNft,
    bool? isLoading,
    String? error,
    NftFilter? filter,
    bool clearSelectedNft = false,
    bool clearError = false,
  }) {
    return NftState(
      nfts: nfts ?? this.nfts,
      selectedNft: clearSelectedNft ? null : (selectedNft ?? this.selectedNft),
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      filter: filter ?? this.filter,
    );
  }

  /// Get filtered NFTs based on current filter
  List<Nft> get filteredNfts {
    switch (filter) {
      case NftFilter.all:
        return nfts;
      case NftFilter.erc721:
        return nfts.where((nft) => nft.tokenType == NftTokenType.erc721).toList();
      case NftFilter.erc1155:
        return nfts.where((nft) => nft.tokenType == NftTokenType.erc1155).toList();
    }
  }

  /// Get unique collection names
  List<String> get collections {
    return nfts.map((nft) => nft.collectionName).toSet().toList()..sort();
  }

  /// Total NFT count
  int get totalCount => nfts.length;

  /// ERC-721 count
  int get erc721Count =>
      nfts.where((nft) => nft.tokenType == NftTokenType.erc721).length;

  /// ERC-1155 count
  int get erc1155Count =>
      nfts.where((nft) => nft.tokenType == NftTokenType.erc1155).length;
}

/// NFT filter options
enum NftFilter {
  all,
  erc721,
  erc1155,
}

/// NFT state notifier for managing gallery state
class NftNotifier extends StateNotifier<NftState> {
  NftNotifier() : super(const NftState(isLoading: true)) {
    _loadMockData();
  }

  /// Load mock NFT data (simulates API call)
  Future<void> _loadMockData() async {
    try {
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 1500));

      state = NftState(
        nfts: MockNfts.all,
        isLoading: false,
      );
    } catch (e) {
      state = NftState(
        isLoading: false,
        error: 'Failed to load NFTs: $e',
      );
    }
  }

  /// Refresh NFT list
  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, clearError: true);
    await _loadMockData();
  }

  /// Select an NFT for detail view
  void selectNft(Nft nft) {
    state = state.copyWith(selectedNft: nft);
  }

  /// Clear selected NFT
  void clearSelectedNft() {
    state = state.copyWith(clearSelectedNft: true);
  }

  /// Update filter
  void setFilter(NftFilter filter) {
    state = state.copyWith(filter: filter);
  }

  /// Get NFT by token ID and contract address
  Nft? getNftById(String contractAddress, String tokenId) {
    try {
      return state.nfts.firstWhere(
        (nft) =>
            nft.contractAddress.toLowerCase() == contractAddress.toLowerCase() &&
            nft.tokenId == tokenId,
      );
    } catch (_) {
      return null;
    }
  }
}

/// NFT provider
final nftProvider = StateNotifierProvider<NftNotifier, NftState>((ref) {
  return NftNotifier();
});

/// Selected NFT provider (for detail page navigation)
final selectedNftProvider = Provider<Nft?>((ref) {
  return ref.watch(nftProvider).selectedNft;
});

/// NFT filter provider
final nftFilterProvider = Provider<NftFilter>((ref) {
  return ref.watch(nftProvider).filter;
});

/// Filtered NFTs provider
final filteredNftsProvider = Provider<List<Nft>>((ref) {
  return ref.watch(nftProvider).filteredNfts;
});

/// NFT collections provider
final nftCollectionsProvider = Provider<List<String>>((ref) {
  return ref.watch(nftProvider).collections;
});

/// NFT loading state provider
final nftLoadingProvider = Provider<bool>((ref) {
  return ref.watch(nftProvider).isLoading;
});

/// NFT error state provider
final nftErrorProvider = Provider<String?>((ref) {
  return ref.watch(nftProvider).error;
});

/// NFT count providers
final nftCountProvider = Provider<({int total, int erc721, int erc1155})>((ref) {
  final state = ref.watch(nftProvider);
  return (
    total: state.totalCount,
    erc721: state.erc721Count,
    erc1155: state.erc1155Count,
  );
});
