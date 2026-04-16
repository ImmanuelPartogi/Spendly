import 'package:flutter/material.dart';

/// Wallet types yang didukung.
enum WalletType {
  cash,
  bank,
  ewallet,
  credit,
  investment,
  other;

  String get label {
    switch (this) {
      case WalletType.cash:
        return 'Cash';
      case WalletType.bank:
        return 'Bank';
      case WalletType.ewallet:
        return 'E-Wallet';
      case WalletType.credit:
        return 'Credit Card';
      case WalletType.investment:
        return 'Investment';
      case WalletType.other:
        return 'Other';
    }
  }

  String get emoji {
    switch (this) {
      case WalletType.cash:
        return '💵';
      case WalletType.bank:
        return '🏦';
      case WalletType.ewallet:
        return '📱';
      case WalletType.credit:
        return '💳';
      case WalletType.investment:
        return '📈';
      case WalletType.other:
        return '👛';
    }
  }
}

class WalletEntity {
  final String id;
  final String name;
  final double balance;
  final WalletType type;
  final Color color;
  final bool isDefault;
  final DateTime createdAt;

  const WalletEntity({
    required this.id,
    required this.name,
    required this.balance,
    required this.type,
    required this.color,
    this.isDefault = false,
    required this.createdAt,
  });

  WalletEntity copyWith({
    String? id,
    String? name,
    double? balance,
    WalletType? type,
    Color? color,
    bool? isDefault,
    DateTime? createdAt,
  }) {
    return WalletEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      balance: balance ?? this.balance,
      type: type ?? this.type,
      color: color ?? this.color,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// Preset wallet populer di Indonesia.
class WalletPreset {
  final String name;
  final WalletType type;
  final Color color;
  final String emoji;

  const WalletPreset({
    required this.name,
    required this.type,
    required this.color,
    required this.emoji,
  });

  static const List<WalletPreset> all = [
    WalletPreset(
        name: 'Cash',
        type: WalletType.cash,
        color: Color(0xFF00C48C),
        emoji: '💵'),
    WalletPreset(
        name: 'BCA',
        type: WalletType.bank,
        color: Color(0xFF0066AE),
        emoji: '🏦'),
    WalletPreset(
        name: 'Mandiri',
        type: WalletType.bank,
        color: Color(0xFF003D79),
        emoji: '🏦'),
    WalletPreset(
        name: 'BNI',
        type: WalletType.bank,
        color: Color(0xFFEB6823),
        emoji: '🏦'),
    WalletPreset(
        name: 'BRI',
        type: WalletType.bank,
        color: Color(0xFF003087),
        emoji: '🏦'),
    WalletPreset(
        name: 'GoPay',
        type: WalletType.ewallet,
        color: Color(0xFF00AED6),
        emoji: '📱'),
    WalletPreset(
        name: 'OVO',
        type: WalletType.ewallet,
        color: Color(0xFF4C3494),
        emoji: '📱'),
    WalletPreset(
        name: 'Dana',
        type: WalletType.ewallet,
        color: Color(0xFF118EEA),
        emoji: '📱'),
    WalletPreset(
        name: 'ShopeePay',
        type: WalletType.ewallet,
        color: Color(0xFFEE4D2D),
        emoji: '📱'),
    WalletPreset(
        name: 'Jenius',
        type: WalletType.bank,
        color: Color(0xFF2B2D42),
        emoji: '💳'),
  ];
}