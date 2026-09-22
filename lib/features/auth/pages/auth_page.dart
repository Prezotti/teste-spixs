import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:teste_spixs/core/design/design.dart';
import 'package:teste_spixs/features/auth/controllers/auth_controller.dart';

class AuthPage extends GetView<AuthController> {
  const AuthPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ink,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space4),
          child: Column(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 72,
                      height: 72,
                      child: DecoratedBox(
                        decoration: const BoxDecoration(color: AppColors.brand, borderRadius: AppRadius.lgAll),
                        child: Center(
                          child: SvgPicture.asset(
                            'assets/icons/location-pin.svg',
                            width: 36,
                            height: 36,
                            fit: BoxFit.contain,
                            colorFilter: const ColorFilter.mode(AppColors.onBrand, BlendMode.srcIn),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.space3),
                    const UIText.display('Rota', color: AppColors.onBrand, textAlign: TextAlign.center),
                    const SizedBox(height: AppSpacing.space2),
                    UIText.body(
                      'Entregas mais rápidas,\ncidades mais próximas.',
                      color: AppColors.onBrand.withValues(alpha: 0.55),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              UIPrimaryButton(label: 'Usar senha do celular', onPressed: controller.authenticateWithPassword),
              const SizedBox(height: AppSpacing.space4),
            ],
          ),
        ),
      ),
    );
  }
}
