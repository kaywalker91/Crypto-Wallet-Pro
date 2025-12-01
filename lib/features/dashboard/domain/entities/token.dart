import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Token entity representing a cryptocurrency token
class Token extends Equatable {
  final String symbol;
  final String name;
  final String balance;
  final String valueUsd;
  final String? iconUrl;
  final Color color;
  final String? contractAddress;
  final int decimals;

  const Token({
    required this.symbol,
    required this.name,
    required this.balance,
    required this.valueUsd,
    this.iconUrl,
    required this.color,
    this.contractAddress,
    this.decimals = 18,
  });

  @override
  List<Object?> get props => [
        symbol,
        name,
        balance,
        valueUsd,
        iconUrl,
        color,
        contractAddress,
        decimals,
      ];
}

/// Mock tokens for development
class MockTokens {
  MockTokens._();

  static const Token eth = Token(
    symbol: 'ETH',
    name: 'Ethereum',
    balance: '0.5234',
    valueUsd: '\$987.65',
    color: AppColors.ethColor,
    decimals: 18,
  );

  static const Token usdt = Token(
    symbol: 'USDT',
    name: 'Tether USD',
    balance: '100.00',
    valueUsd: '\$100.00',
    color: AppColors.usdtColor,
    contractAddress: '0xdAC17F958D2ee523a2206206994597C13D831ec7',
    decimals: 6,
  );

  static const Token uni = Token(
    symbol: 'UNI',
    name: 'Uniswap',
    balance: '25.5',
    valueUsd: '\$150.00',
    color: AppColors.uniColor,
    contractAddress: '0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984',
    decimals: 18,
  );

  static const List<Token> all = [eth, usdt, uni];
}
