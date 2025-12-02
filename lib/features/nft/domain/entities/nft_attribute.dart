import 'package:equatable/equatable.dart';

/// NFT attribute entity representing a single trait
class NftAttribute extends Equatable {
  final String traitType;
  final String value;
  final String? displayType; // number, date, boost_percentage, boost_number
  final double? rarity; // Rarity percentage (0-100)

  const NftAttribute({
    required this.traitType,
    required this.value,
    this.displayType,
    this.rarity,
  });

  @override
  List<Object?> get props => [traitType, value, displayType, rarity];
}
