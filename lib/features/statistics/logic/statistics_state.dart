import 'package:equatable/equatable.dart';

abstract class StatisticsState extends Equatable {
  const StatisticsState();
  @override
  List<Object?> get props => [];
}

class StatisticsInitial extends StatisticsState {
  const StatisticsInitial();
}

class StatisticsLoading extends StatisticsState {
  const StatisticsLoading();
}

class StatisticsLoaded extends StatisticsState {
  final double totalIncome;
  final double totalExpense;
  final double netBalance;
  final Map<int, ({double income, double expense})> monthlyData;
  final int selectedYear;

  const StatisticsLoaded({
    required this.totalIncome,
    required this.totalExpense,
    required this.netBalance,
    required this.monthlyData,
    required this.selectedYear,
  });

  @override
  List<Object?> get props => [
        totalIncome,
        totalExpense,
        netBalance,
        monthlyData,
        selectedYear
      ];
}

class StatisticsError extends StatisticsState {
  final String message;
  const StatisticsError(this.message);
  @override
  List<Object?> get props => [message];
}
