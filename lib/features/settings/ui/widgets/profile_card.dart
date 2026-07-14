import 'package:finance_tracker_app_001/core/theming/app_colors.dart';
import 'package:finance_tracker_app_001/core/theming/app_text_styles.dart';
import 'package:finance_tracker_app_001/features/auth/logic/auth_state.dart';
import 'package:flutter/material.dart';

class ProfileCard extends StatelessWidget {
  final AuthAuthenticated auth;

  const ProfileCard({super.key, required this.auth});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundImage:
                auth.photoUrl != null ? NetworkImage(auth.photoUrl!) : null,
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            child: auth.photoUrl == null
                ? Text(
                    auth.displayName.isNotEmpty
                        ? auth.displayName[0].toUpperCase()
                        : 'U',
                    style: AppTextStyles.headlineMedium
                        .copyWith(color: Colors.white),
                  )
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(auth.displayName,
                    style: AppTextStyles.onDarkTitle,
                    overflow: TextOverflow.ellipsis),
                Text(auth.email,
                    style: AppTextStyles.onDarkBody,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
