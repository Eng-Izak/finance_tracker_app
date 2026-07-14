import 'package:dio/dio.dart';
import '../shared/models/currency_model.dart';
import '../utils/constants/app_constants.dart';
import '../services/local_db_service.dart';

/// Exchange Rate service using the free frankfurter.app API.
/// No API key required. Caches results locally in Hive.
class ExchangeRateService {
  final Dio _dio;

  ExchangeRateService()
      : _dio = Dio(BaseOptions(
          baseUrl: AppConstants.exchangeRateBaseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ));

  // ─── Fetch Latest Rates ──────────────────────────────────────
  /// Fetches latest exchange rates from the API.
  /// Returns a list of [CurrencyModel] with updated rates.
  Future<List<CurrencyModel>> fetchLatestRates({
    String baseCurrency = 'USD',
  }) async {
    try {
      final response = await _dio.get(
        '/latest',
        queryParameters: {'base': baseCurrency},
      );

      final data = response.data as Map<String, dynamic>;
      final rates = data['rates'] as Map<String, dynamic>;

      final now = DateTime.now();
      final updatedCurrencies = CurrencyModel.defaults.map((currency) {
        if (currency.code == 'LOCAL') return currency;
        if (currency.code == baseCurrency) {
          return currency.copyWith(rateToBase: 1.0, lastUpdated: now);
        }
        final rate = (rates[currency.code] as num?)?.toDouble();
        if (rate == null) return currency;
        return currency.copyWith(rateToBase: rate, lastUpdated: now);
      }).toList();

      // Cache rates in Hive
      await _saveRatesToLocal(updatedCurrencies);

      return updatedCurrencies;
    } catch (e) {
      // Return cached rates on error
      return _loadRatesFromLocal();
    }
  }

  // ─── Local Cache ─────────────────────────────────────────────
  Future<void> _saveRatesToLocal(List<CurrencyModel> currencies) async {
    final box = LocalDbService.currenciesBox;
    for (final currency in currencies) {
      await box.put(currency.code, currency.toMap());
    }
  }

  List<CurrencyModel> _loadRatesFromLocal() {
    final box = LocalDbService.currenciesBox;
    if (box.isEmpty) return CurrencyModel.defaults;

    return box.values
        .map((v) => CurrencyModel.fromMap(
            Map<String, dynamic>.from(v as Map)))
        .toList();
  }

  // ─── Get Cached Currencies ───────────────────────────────────
  List<CurrencyModel> getCachedCurrencies() {
    return _loadRatesFromLocal();
  }

  // ─── Check if cache is stale ─────────────────────────────────
  bool isCacheStale() {
    final box = LocalDbService.currenciesBox;
    if (box.isEmpty) return true;

    final firstEntry = box.values.first;
    if (firstEntry is! Map) return true;

    final map = Map<String, dynamic>.from(firstEntry);
    final lastUpdatedStr = map['lastUpdated'] as String?;
    if (lastUpdatedStr == null) return true;

    final lastUpdated = DateTime.parse(lastUpdatedStr);
    return DateTime.now().difference(lastUpdated) >
        AppConstants.exchangeRateCacheDuration;
  }

  // ─── Convert Amount ──────────────────────────────────────────
  double convert({
    required double amount,
    required String fromCode,
    required String toCode,
    required List<CurrencyModel> currencies,
  }) {
    if (fromCode == toCode) return amount;

    final from = currencies.firstWhere(
      (c) => c.code == fromCode,
      orElse: () => CurrencyModel.defaults.first,
    );
    final to = currencies.firstWhere(
      (c) => c.code == toCode,
      orElse: () => CurrencyModel.defaults.first,
    );

    return from.convertTo(to, amount);
  }
}
