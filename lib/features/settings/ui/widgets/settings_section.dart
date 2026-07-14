import 'package:finance_tracker_app_001/core/theming/app_colors.dart';
import 'package:finance_tracker_app_001/core/theming/app_text_styles.dart';
import 'package:flutter/material.dart';

class SettingsSection extends StatelessWidget {
  final String? title;
  final List<Widget> children;

  const SettingsSection({
    super.key,
    this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 8, right: 4, left: 4),
            child: Text(
              title!,
              style: AppTextStyles.titleSmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
        Material(
          color: Theme.of(context).colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Theme.of(context).colorScheme.outline),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(children: children),
        ),
      ],
    );
  }
}
