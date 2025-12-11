import 'package:equatable/equatable.dart';

enum TransactionType { sent, received }

class TransactionEntity extends Equatable {
  final String hash;
  final String from;
  final String to;
  final double value;
  final String asset;
  final String category;
  final DateTime timestamp;
  final TransactionType type;
  final String uniqueId; // hash + logIndex (to handle multiple transfers in one tx)

  const TransactionEntity({
    required this.hash,
    required this.from,
    required this.to,
    required this.value,
    required this.asset,
    required this.category,
    required this.timestamp,
    required this.type,
    required this.uniqueId,
  });

  @override
  List<Object> get props => [hash, uniqueId, from, to, value, asset, category, timestamp, type];
}
