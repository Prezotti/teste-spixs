import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:teste_spixs/core/design/design.dart';
import 'package:teste_spixs/features/location/controllers/location_permission_controller.dart';

class LocationPermissionPage extends GetView<LocationPermissionController> {
  const LocationPermissionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface200,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space4),
          child: Column(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 128,
                      height: 128,
                      decoration: BoxDecoration(color: AppColors.brand.withValues(alpha: 0.12), shape: BoxShape.circle),
                      alignment: Alignment.center,
                      child: SvgPicture.asset(
                        'assets/icons/location-pin.svg',
                        width: 56,
                        height: 56,
                        fit: BoxFit.contain,
                        colorFilter: const ColorFilter.mode(AppColors.brand, BlendMode.srcIn),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.space4),
                    const UIText.title('Precisamos da sua localização', textAlign: TextAlign.center),
                    const SizedBox(height: AppSpacing.space2),
                    const UIText.body(
                      'Usaremos sua localização para mostrar o seu ponto de partida, calcular rotas e fornecer navegação em tempo real.',
                      color: AppColors.inkMuted,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              Obx(
                () => UIPrimaryButton(
                  label: 'Permitir localização',
                  onPressed: controller.isRequesting.value ? null : controller.allow,
                ),
              ),
              const SizedBox(height: AppSpacing.space2),
              TextButton(
                onPressed: controller.skip,
                style: TextButton.styleFrom(foregroundColor: AppColors.inkMuted, textStyle: AppTypography.body),
                child: const Text('Agora não'),
              ),
              const SizedBox(height: AppSpacing.space3),
            ],
          ),
        ),
      ),
    );
  }
}
