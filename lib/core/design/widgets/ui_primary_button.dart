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
    final enabled = onPressed != null;
    final background = enabled ? AppColors.brand : AppColors.border;
    final foreground = enabled ? AppColors.onBrand : AppColors.inkMuted;

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          animationDuration: Duration.zero,
          backgroundColor: background,
          disabledBackgroundColor: background,
          foregroundColor: foreground,
          disabledForegroundColor: foreground,
          textStyle: AppTypography.bodyStrong.copyWith(color: foreground),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.lgAll),
        ),
        child: Text(label, style: AppTypography.bodyStrong.copyWith(color: foreground)),
      ),
    );
  }
}
