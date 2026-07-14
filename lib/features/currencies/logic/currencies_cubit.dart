import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/network/exchange_rate_service.dart';
import '../../../core/shared/models/currency_model.dart';
import 'currencies_state.dart';

class CurrenciesCubit extends Cubit<CurrenciesState> {
  final ExchangeRateService _exchangeRateService;

  CurrenciesCubit({required ExchangeRateService exchangeRateService})
      : _exchangeRateService = exchangeRateService,
        super(const CurrenciesInitial());

  Future<void> loadCurrencies() async {
    // Show cached first
    final cached = _exchangeRateService.getCachedCurrencies();
    if (cached.isNotEmpty) {
      emit(CurrenciesLoaded(cached));
    } else {
      emit(const CurrenciesLoading());
    }

    // Refresh from API if cache is stale
    if (_exchangeRateService.isCacheStale()) {
      try {
        final currencies = await _exchangeRateService.fetchLatestRates();
        emit(CurrenciesLoaded(currencies));
      } catch (e) {
        if (cached.isEmpty) {
          emit(CurrenciesLoaded(CurrencyModel.defaults));
        }
      }
    }
  }

  Future<void> refreshRates() async {
    final current = state;
    final List<CurrencyModel> existing = current is CurrenciesLoaded
        ? current.currencies
        : <CurrencyModel>[];
    emit(CurrenciesLoaded(existing, isRefreshing: true));
    try {
      final currencies = await _exchangeRateService.fetchLatestRates();
      emit(CurrenciesLoaded(currencies));
    } catch (e) {
      emit(CurrenciesLoaded(existing));
    }
  }
}
