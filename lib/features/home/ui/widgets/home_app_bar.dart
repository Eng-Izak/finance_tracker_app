import 'package:finance_tracker_app_001/features/home/logic/home_cubit.dart';
import 'package:finance_tracker_app_001/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'financial_reports_dialog.dart';

class HomeAppBar extends StatefulWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;
  const HomeAppBar({super.key, required this.scaffoldKey});

  @override
  State<HomeAppBar> createState() => _HomeAppBarState();
}

class _HomeAppBarState extends State<HomeAppBar> {
  final _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (_isSearching) {
      return AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            setState(() => _isSearching = false);
            _searchController.clear();
            context.read<HomeCubit>().refresh();
          },
        ),
        title: TextField(
          controller: _searchController,
          autofocus: true,
          onChanged: (q) => context.read<HomeCubit>().searchAccounts(q),
          decoration: InputDecoration(
            hintText: '${l10n.search}...',
            border: InputBorder.none,
            fillColor: Colors.transparent,
          ),
        ),
      );
    }

    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.menu_rounded),
        onPressed: () => widget.scaffoldKey.currentState?.openDrawer(),
      ),
      title: Text(l10n.general),
      actions: [
        IconButton(
          icon: Image.asset(
            'assets/icons/export_icon.png',
            width: 24,
            height: 24,
          ),
          tooltip: l10n.exportData,
          onPressed: () => FinancialReportsDialog.show(context),
        ),
        IconButton(
          icon: const Icon(Icons.search_rounded),
          tooltip: l10n.search,
          onPressed: () => setState(() => _isSearching = true),
        ),
        const SizedBox(width: 4),
      ],
    );
  }
}
