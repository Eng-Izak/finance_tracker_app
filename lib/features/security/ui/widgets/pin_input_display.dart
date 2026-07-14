import 'package:flutter/material.dart';
import '../../../../core/theming/app_colors.dart';

/// Visual PIN dot indicators
class PinInputDisplay extends StatelessWidget {
  final String entered;
  final int pinLength;
  final bool hasError;

  const PinInputDisplay({
    super.key,
    required this.entered,
    required this.pinLength,
    this.hasError = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(pinLength, (i) {
        final isFilled = i < entered.length;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          margin: const EdgeInsets.symmetric(horizontal: 8),
          width: isFilled ? 18 : 14,
          height: isFilled ? 18 : 14,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: hasError
                ? AppColors.debtor
                : isFilled
                    ? AppColors.primary
                    : Colors.transparent,
            border: Border.all(
              color: hasError
                  ? AppColors.debtor
                  : isFilled
                      ? AppColors.primary
                      : AppColors.border,
              width: 2,
            ),
            boxShadow: isFilled && !hasError
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 8,
                      spreadRadius: 1,
                    )
                  ]
                : null,
          ),
        );
      }),
    );
  }
}
