import 'dart:convert';

import '../../domain/entities/wallet.dart';

class WalletModel extends Wallet {
  const WalletModel({
    required super.address,
    super.ensName,
    required super.createdAt,
  });

  factory WalletModel.fromEntity(Wallet wallet) {
    return WalletModel(
      address: wallet.address,
      ensName: wallet.ensName,
      createdAt: wallet.createdAt,
    );
  }

  factory WalletModel.fromJson(Map<String, dynamic> json) {
    return WalletModel(
      address: json['address'] as String,
      ensName: json['ensName'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'address': address,
      'ensName': ensName,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  String encode() => jsonEncode(toJson());

  static WalletModel decode(String value) =>
      WalletModel.fromJson(jsonDecode(value) as Map<String, dynamic>);
}
