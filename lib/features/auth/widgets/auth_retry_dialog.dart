import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:teste_spixs/core/design/design.dart';

class AuthRetryDialog extends StatelessWidget {
  const AuthRetryDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface200,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.lgAll),
      child: Padding(
        padding: AppSpacing.card,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const UIText.heading('Rosto não reconhecido', textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.space2),
            const UIText.body('Tente de novo', color: AppColors.inkMuted, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.space4),
            UIPrimaryButton(label: 'Tentar Face ID novamente', onPressed: () => Get.back(result: true)),
            const SizedBox(height: AppSpacing.space2),
            TextButton(
              onPressed: () => Get.back(result: false),
              style: TextButton.styleFrom(foregroundColor: AppColors.inkMuted, textStyle: AppTypography.bodyStrong),
              child: Center(child: const Text('Cancelar')),
            ),
          ],
        ),
      ),
    );
  }
}
