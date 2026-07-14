import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ─── Primary Blue ───────────────────────────────────────────
  static const Color primary = Color(0xFF2563EB);
  static const Color primaryDark = Color(0xFF1D4ED8);
  static const Color primaryLight = Color(0xFF3B82F6);
  static const Color primarySurface = Color(0xFFEFF6FF);

  // ─── Creditor "له" – Green ──────────────────────────────────
  static const Color creditor = Color(0xFF16A34A);
  static const Color creditorLight = Color(0xFF22C55E);
  static const Color creditorSurface = Color(0xFFF0FDF4);
  static const Color creditorBorder = Color(0xFFBBF7D0);

  // ─── Debtor "عليه" – Orange ─────────────────────────────────
  static const Color debtor = Color(0xFFEA580C);
  static const Color debtorLight = Color(0xFFF97316);
  static const Color debtorSurface = Color(0xFFFFF7ED);
  static const Color debtorBorder = Color(0xFFFED7AA);

  // ─── Warning / Caution ──────────────────────────────────────
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningSurface = Color(0xFFFFFBEB);

  // ─── Neutral Background ─────────────────────────────────────
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF1F5F9);
  static const Color surfaceElevated = Color(0xFFFFFFFF);

  // ─── Borders & Dividers ─────────────────────────────────────
  static const Color border = Color(0xFFE2E8F0);
  static const Color divider = Color(0xFFF1F5F9);
  static const Color borderLight = Color(0xFFF1F5F9);

  // ─── Text ───────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textTertiary = Color(0xFF94A3B8);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  static const Color textOnDark = Color(0xFFFFFFFF);

  // ─── Icons ──────────────────────────────────────────────────
  static const Color iconPrimary = Color(0xFF475569);
  static const Color iconSecondary = Color(0xFF94A3B8);

  // ─── Shadow ─────────────────────────────────────────────────
  static const Color shadow = Color(0x0F000000);
  static const Color shadowMedium = Color(0x1A000000);

  // ─── Dark Theme ─────────────────────────────────────────────
  static const Color darkBackground = Color(0xFF0F172A);
  static const Color darkSurface = Color(0xFF1E293B);
  static const Color darkSurfaceVariant = Color(0xFF334155);
  static const Color darkBorder = Color(0xFF334155);
  static const Color darkDivider = Color(0xFF1E293B);
  static const Color darkTextPrimary = Color(0xFFF1F5F9);
  static const Color darkTextSecondary = Color(0xFF94A3B8);
  static const Color darkTextTertiary = Color(0xFF64748B);
  static const Color darkIconPrimary = Color(0xFF94A3B8);
  static const Color darkPrimarySurface = Color(0xFF1E3A5F);
  static const Color darkCreditorSurface = Color(0xFF14532D);
  static const Color darkDebtorSurface = Color(0xFF431407);
  static const Color darkIconSecondary = Color(0xFF64748B);

  // ─── Gradient ───────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
  );

  static const LinearGradient summaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1E40AF), Color(0xFF2563EB)],
  );

  static const LinearGradient creditorGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF15803D), Color(0xFF16A34A)],
  );

  static const LinearGradient debtorGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFC2410C), Color(0xFFEA580C)],
  );
}
