import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/shared/repos/transactions_repo.dart';
import 'statistics_state.dart';

class StatisticsCubit extends Cubit<StatisticsState> {
  final TransactionsRepo _transactionsRepo;

  StatisticsCubit({
    required TransactionsRepo transactionsRepo,
  })  : _transactionsRepo = transactionsRepo,
        super(const StatisticsInitial());

  Future<void> loadStatistics({int? year}) async {
    emit(const StatisticsLoading());
    try {
      final selectedYear = year ?? DateTime.now().year;
      final monthlyData =
          _transactionsRepo.getMonthlyBreakdown(selectedYear);

      double totalIncome = 0;
      double totalExpense = 0;
      for (final entry in monthlyData.values) {
        totalIncome += entry.income;
        totalExpense += entry.expense;
      }

      emit(StatisticsLoaded(
        totalIncome: totalIncome,
        totalExpense: totalExpense,
        netBalance: totalIncome - totalExpense,
        monthlyData: monthlyData,
        selectedYear: selectedYear,
      ));
    } catch (e) {
      emit(StatisticsError(e.toString()));
    }
  }
}
