import 'package:flutter/material.dart';
import '../../../../core/theming/app_colors.dart';
import '../../../../core/theming/app_text_styles.dart';

/// Full numeric keypad for PIN entry
class PinNumpad extends StatelessWidget {
  final void Function(String digit) onDigit;
  final VoidCallback onDelete;
  final VoidCallback onSubmit;
  final bool showBiometric;
  final VoidCallback? onBiometric;

  const PinNumpad({
    super.key,
    required this.onDigit,
    required this.onDelete,
    required this.onSubmit,
    this.showBiometric = false,
    this.onBiometric,
  });

  @override
  Widget build(BuildContext context) {
    final buttons = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
    ];

    return Column(
      children: [
        ...buttons.map(
          (row) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: row.map((digit) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: _PinKey(digit: digit, onTap: () => onDigit(digit)),
                );
              }).toList(),
            ),
          ),
        ),
        // Last row: biometric | 0 | delete
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: showBiometric && onBiometric != null
                  ? _PinActionKey(
                      icon: Icons.fingerprint_rounded,
                      onTap: onBiometric!,
                      color: AppColors.primary,
                    )
                  : const SizedBox(width: 72, height: 72),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: _PinKey(digit: '0', onTap: () => onDigit('0')),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: _PinActionKey(
                icon: Icons.backspace_outlined,
                onTap: onDelete,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PinKey extends StatelessWidget {
  final String digit;
  final VoidCallback onTap;

  const _PinKey({required this.digit, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(36),
        splashColor: AppColors.primary.withValues(alpha: 0.15),
        child: Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: AppColors.surface,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadow,
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(digit, style: AppTextStyles.headlineMedium),
        ),
      ),
    );
  }
}

class _PinActionKey extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  const _PinActionKey({
    required this.icon,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(36),
      child: SizedBox(
        width: 72,
        height: 72,
        child: Icon(icon, color: color, size: 28),
      ),
    );
  }
}
