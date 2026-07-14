import 'package:finance_tracker_app_001/core/theming/app_colors.dart';
import 'package:finance_tracker_app_001/features/home/logic/home_cubit.dart';
import 'package:finance_tracker_app_001/features/home/logic/home_state.dart';
import 'package:finance_tracker_app_001/features/home/ui/widgets/extracted_cuntent_widget.dart';
import 'package:finance_tracker_app_001/features/home/ui/widgets/home_app_bar.dart';
import 'package:finance_tracker_app_001/features/home/ui/widgets/home_bottom_app_bar.dart';
import 'package:finance_tracker_app_001/features/home/ui/widgets/home_drawer.dart';
import 'package:finance_tracker_app_001/features/home/ui/widgets/home_error_view.dart';
import 'package:finance_tracker_app_001/features/home/ui/widgets/home_floating_action_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _currentTab = 0; // 0=home, 1=stats, 2=settings

  @override
  Widget build(BuildContext context) {
    // final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      key: _scaffoldKey,
      drawer: const HomeDrawer(),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: HomeAppBar(scaffoldKey: _scaffoldKey),
      ),
      body: RefreshIndicator(
        onRefresh: () => context.read<HomeCubit>().refresh(),
        color: AppColors.primary,
        child: BlocBuilder<HomeCubit, HomeState>(
          builder: (context, state) {
            if (state is HomeLoading) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              );
            }
            if (state is HomeError) {
              return HomeErrorView(message: state.message);
            }
            if (state is HomeLoaded) {
              return HomeContent(state: state);
            }
            return const SizedBox.shrink();
          },
        ),
      ),
      bottomNavigationBar: HomeBottomAppBar(
        currentTab: _currentTab,
        onTabChanged: (index) => setState(() => _currentTab = index),
      ),
      floatingActionButton: const HomeFloatingActionButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}
