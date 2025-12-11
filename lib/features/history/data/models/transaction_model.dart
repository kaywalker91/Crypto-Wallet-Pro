import '../../domain/entities/transaction_entity.dart';

class TransactionModel extends TransactionEntity {
  const TransactionModel({
    required super.hash,
    required super.from,
    required super.to,
    required super.value,
    required super.asset,
    required super.category,
    required super.timestamp,
    required super.type,
    required super.uniqueId,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json, String userAddress) {
    final from = json['from'] as String? ?? '';
    final to = json['to'] as String? ?? '';
    final rawValue = json['value'];
    final value = rawValue is num ? rawValue.toDouble() : 0.0;
    
    // Determine type based on userAddress
    final isSent = from.toLowerCase() == userAddress.toLowerCase();
    
    // Parse timestamp (Alchemy returns ISO8601 string in metadata)
    DateTime timestamp = DateTime.now();
    if (json['metadata'] != null && json['metadata']['blockTimestamp'] != null) {
      timestamp = DateTime.parse(json['metadata']['blockTimestamp']);
    }

    return TransactionModel(
      hash: json['hash'] as String? ?? '',
      uniqueId: json['uniqueId'] as String? ?? json['hash'] as String? ?? DateTime.now().toString(),
      from: from,
      to: to,
      value: value,
      asset: json['asset'] as String? ?? 'Unknown',
      category: json['category'] as String? ?? 'external',
      timestamp: timestamp,
      type: isSent ? TransactionType.sent : TransactionType.received,
    );
  }
}
