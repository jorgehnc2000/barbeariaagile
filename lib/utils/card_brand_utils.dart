import 'package:flutter/material.dart';

/// Bandeira inferida pelos primeiros dígitos (apenas UI — o MP valida no token).
enum CardBrand {
  unknown,
  visa,
  mastercard,
  amex,
  elo,
  hipercard,
}

abstract final class CardBrandUtils {
  static CardBrand detect(String rawNumber) {
    final digits = rawNumber.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return CardBrand.unknown;

    if (digits.startsWith('4')) return CardBrand.visa;

    if (digits.length >= 2) {
      final two = int.tryParse(digits.substring(0, 2)) ?? 0;
      final four = digits.length >= 4
          ? int.tryParse(digits.substring(0, 4)) ?? 0
          : 0;
      if (two >= 51 && two <= 55) return CardBrand.mastercard;
      if (four >= 2221 && four <= 2720) return CardBrand.mastercard;
    }

    if (digits.startsWith('34') || digits.startsWith('37')) {
      return CardBrand.amex;
    }

    if (digits.startsWith('636368') ||
        digits.startsWith('438935') ||
        digits.startsWith('504175') ||
        digits.startsWith('451416') ||
        digits.startsWith('636297') ||
        digits.startsWith('5067') ||
        digits.startsWith('4576') ||
        digits.startsWith('4011')) {
      return CardBrand.elo;
    }

    if (digits.startsWith('606282') || digits.startsWith('3841')) {
      return CardBrand.hipercard;
    }

    return CardBrand.unknown;
  }

  static String label(CardBrand brand) => switch (brand) {
        CardBrand.visa => 'Visa',
        CardBrand.mastercard => 'Mastercard',
        CardBrand.amex => 'Amex',
        CardBrand.elo => 'Elo',
        CardBrand.hipercard => 'Hipercard',
        CardBrand.unknown => '',
      };

  static IconData icon(CardBrand brand) => switch (brand) {
        CardBrand.unknown => Icons.credit_card_rounded,
        _ => Icons.credit_card_rounded,
      };
}
