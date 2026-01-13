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
    balance: '1.5234',
    valueUsd: '\$3,045.68',
    color: AppColors.ethColor,
    decimals: 18,
  );

  static const Token usdt = Token(
    symbol: 'USDT',
    name: 'Tether USD',
    balance: '2,500.00',
    valueUsd: '\$2,500.00',
    color: AppColors.usdtColor,
    contractAddress: '0xdAC17F958D2ee523a2206206994597C13D831ec7',
    decimals: 6,
  );

  static const Token usdc = Token(
    symbol: 'USDC',
    name: 'USD Coin',
    balance: '5,000.00',
    valueUsd: '\$5,000.00',
    color: Color(0xFF2775CA),
    contractAddress: '0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48',
    decimals: 6,
  );

  static const Token uni = Token(
    symbol: 'UNI',
    name: 'Uniswap',
    balance: '45.75',
    valueUsd: '\$321.25',
    color: AppColors.uniColor,
    contractAddress: '0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984',
    decimals: 18,
  );

  static const Token link = Token(
    symbol: 'LINK',
    name: 'Chainlink',
    balance: '120.50',
    valueUsd: '\$1,566.50',
    color: Color(0xFF375BD2),
    contractAddress: '0x514910771AF9Ca656af840dff83E8264EcF986CA',
    decimals: 18,
  );

  static const Token dai = Token(
    symbol: 'DAI',
    name: 'Dai Stablecoin',
    balance: '1,234.56',
    valueUsd: '\$1,234.56',
    color: Color(0xFFF5AC37),
    contractAddress: '0x6B175474E89094C44Da98b954EedeAC495271d0F',
    decimals: 18,
  );

  static const List<Token> all = [eth, usdt, usdc, uni, link, dai];
}
