import 'package:finance_tracker_app_001/core/routing/routes.dart';
import 'package:finance_tracker_app_001/features/home/ui/widgets/nav_item.dart';
import 'package:finance_tracker_app_001/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomeBottomAppBar extends StatelessWidget {
  final int currentTab;
  final ValueChanged<int> onTabChanged;

  const HomeBottomAppBar({
    super.key,
    required this.currentTab,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isCurrent = ModalRoute.of(context)?.isCurrent ?? true;

    return IgnorePointer(
      ignoring: !isCurrent,
      child: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            NavItem(
              icon: Icons.home_rounded,
              label: l10n.home,
              isSelected: currentTab == 0,
              onTap: () => onTabChanged(0),
            ),
            NavItem(
              icon: Icons.currency_exchange_rounded,
              label: l10n.currencies,
              isSelected: currentTab == 1,
              onTap: () {
                onTabChanged(1);
                context.push(AppRoutes.currencies).then((_) {
                  onTabChanged(0);
                });
              },
            ),
            const SizedBox(width: 48), // مساحة للـ FAB المُنحني
            NavItem(
              icon: Icons.bar_chart_rounded,
              label: l10n.statistics,
              isSelected: currentTab == 2,
              onTap: () {
                onTabChanged(2);
                context.push(AppRoutes.statistics).then((_) {
                  onTabChanged(0);
                });
              },
            ),
            NavItem(
              icon: Icons.settings_rounded,
              label: l10n.settings,
              isSelected: currentTab == 3,
              onTap: () {
                onTabChanged(3);
                context.push(AppRoutes.settings).then((_) {
                  onTabChanged(0);
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}
