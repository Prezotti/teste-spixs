import 'package:flutter/material.dart';

import '../app_colors.dart';
import '../app_radius.dart';
import '../app_typography.dart';

class UIPrimaryButton extends StatelessWidget {
  const UIPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.brand,
          disabledBackgroundColor: AppColors.border,
          foregroundColor: AppColors.onBrand,
          disabledForegroundColor: AppColors.inkMuted,
          textStyle: AppTypography.bodyStrong,
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.lgAll),
        ),
        child: Text(label),
      ),
    );
  }
}
