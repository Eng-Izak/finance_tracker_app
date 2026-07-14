import 'package:equatable/equatable.dart';

class CurrencyModel extends Equatable {
  final String code;       // 'USD', 'EUR', 'EGP', 'SAR', 'LOCAL'
  final String name;       // 'US Dollar', 'Euro' ...
  final String nameAr;     // 'دولار أمريكي', 'يورو' ...
  final String symbol;     // '$', '€', '£' ...
  final double rateToBase; // Exchange rate relative to base (USD)
  final DateTime lastUpdated;
  final bool isLocal;      // True for the user-defined local currency

  const CurrencyModel({
    required this.code,
    required this.name,
    required this.nameAr,
    required this.symbol,
    this.rateToBase = 1.0,
    required this.lastUpdated,
    this.isLocal = false,
  });

  CurrencyModel copyWith({
    String? code,
    String? name,
    String? nameAr,
    String? symbol,
    double? rateToBase,
    DateTime? lastUpdated,
    bool? isLocal,
  }) {
    return CurrencyModel(
      code: code ?? this.code,
      name: name ?? this.name,
      nameAr: nameAr ?? this.nameAr,
      symbol: symbol ?? this.symbol,
      rateToBase: rateToBase ?? this.rateToBase,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      isLocal: isLocal ?? this.isLocal,
    );
  }

  Map<String, dynamic> toMap() => {
        'code': code,
        'name': name,
        'nameAr': nameAr,
        'symbol': symbol,
        'rateToBase': rateToBase,
        'lastUpdated': lastUpdated.toIso8601String(),
        'isLocal': isLocal,
      };

  factory CurrencyModel.fromMap(Map<String, dynamic> map) => CurrencyModel(
        code: map['code'] as String,
        name: map['name'] as String,
        nameAr: map['nameAr'] as String? ?? map['name'] as String,
        symbol: map['symbol'] as String,
        rateToBase: (map['rateToBase'] as num?)?.toDouble() ?? 1.0,
        lastUpdated: map['lastUpdated'] != null
            ? DateTime.parse(map['lastUpdated'] as String)
            : DateTime.now(),
        isLocal: map['isLocal'] as bool? ?? false,
      );

  /// Convert [amount] from this currency to [target] currency.
  double convertTo(CurrencyModel target, double amount) {
    if (code == target.code) return amount;
    // amount / rateToBase = amount in USD → * target.rateToBase = in target
    final inBase = amount / rateToBase;
    return inBase * target.rateToBase;
  }

  @override
  List<Object?> get props =>
      [code, name, nameAr, symbol, rateToBase, lastUpdated, isLocal];

  // ─── Default currencies list ─────────────────────────────────
  static List<CurrencyModel> get defaults => [
        CurrencyModel(
          code: 'LOCAL',
          name: 'Local Currency',
          nameAr: 'العملة المحلية',
          symbol: '🏠',
          rateToBase: 1.0,
          lastUpdated: DateTime.now(),
          isLocal: true,
        ),
        CurrencyModel(
          code: 'USD',
          name: 'US Dollar',
          nameAr: 'دولار أمريكي',
          symbol: '\$',
          rateToBase: 1.0,
          lastUpdated: DateTime.now(),
        ),
        CurrencyModel(
          code: 'EUR',
          name: 'Euro',
          nameAr: 'يورو',
          symbol: '€',
          rateToBase: 0.92,
          lastUpdated: DateTime.now(),
        ),
        CurrencyModel(
          code: 'GBP',
          name: 'British Pound',
          nameAr: 'جنيه إسترليني',
          symbol: '£',
          rateToBase: 0.79,
          lastUpdated: DateTime.now(),
        ),
        CurrencyModel(
          code: 'SAR',
          name: 'Saudi Riyal',
          nameAr: 'ريال سعودي',
          symbol: '﷼',
          rateToBase: 3.75,
          lastUpdated: DateTime.now(),
        ),
        CurrencyModel(
          code: 'EGP',
          name: 'Egyptian Pound',
          nameAr: 'جنيه مصري',
          symbol: 'ج.م',
          rateToBase: 48.5,
          lastUpdated: DateTime.now(),
        ),
        CurrencyModel(
          code: 'AED',
          name: 'UAE Dirham',
          nameAr: 'درهم إماراتي',
          symbol: 'د.إ',
          rateToBase: 3.67,
          lastUpdated: DateTime.now(),
        ),
        CurrencyModel(
          code: 'KWD',
          name: 'Kuwaiti Dinar',
          nameAr: 'دينار كويتي',
          symbol: 'د.ك',
          rateToBase: 0.31,
          lastUpdated: DateTime.now(),
        ),
        CurrencyModel(
          code: 'TRY',
          name: 'Turkish Lira',
          nameAr: 'ليرة تركية',
          symbol: '₺',
          rateToBase: 32.0,
          lastUpdated: DateTime.now(),
        ),
        CurrencyModel(
          code: 'JPY',
          name: 'Japanese Yen',
          nameAr: 'ين ياباني',
          symbol: '¥',
          rateToBase: 150.0,
          lastUpdated: DateTime.now(),
        ),
      ];
}
