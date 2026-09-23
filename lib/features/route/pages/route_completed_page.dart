import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:teste_spixs/core/design/design.dart';
import 'package:teste_spixs/core/routes/app_routes.dart';
import 'package:teste_spixs/features/route/domain/entities/route_completion.dart';

class RouteCompletedPage extends StatelessWidget {
  const RouteCompletedPage({super.key, required this.summary});

  final RouteCompletion summary;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface200,
      body: SafeArea(
        child: Padding(
          padding: AppSpacing.screen,
          child: Column(
            children: [
              const Spacer(),
              const DecoratedBox(
                decoration: BoxDecoration(color: AppColors.success, shape: BoxShape.circle),
                child: SizedBox(
                  width: 72,
                  height: 72,
                  child: Center(child: Icon(Icons.check, color: AppColors.onBrand, size: 36)),
                ),
              ),
              const SizedBox(height: AppSpacing.space3),
              const UIText.title('Rota concluída!', textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.space2),
              const UIText.body(
                'Todas as entregas foram realizadas\ncom sucesso.',
                color: AppColors.inkMuted,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.space4),
              Container(
                width: double.infinity,
                padding: AppSpacing.card,
                decoration: BoxDecoration(
                  color: AppColors.surface200,
                  borderRadius: AppRadius.mdAll,
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    _SummaryRow(
                      icon: Icons.inventory_2_outlined,
                      value: '${summary.deliveries}',
                      label: summary.deliveries == 1 ? 'Entrega' : 'Entregas',
                    ),
                    const SizedBox(height: AppSpacing.space3),
                    _SummaryRow(
                      icon: Icons.schedule,
                      value: _formatDuration(summary.durationSeconds),
                      label: 'Tempo total',
                    ),
                    const SizedBox(height: AppSpacing.space3),
                    _SummaryRow(
                      icon: Icons.location_on_outlined,
                      value: _formatDistance(summary.distanceMeters),
                      label: 'Distância percorrida',
                    ),
                  ],
                ),
              ),
              const Spacer(),
              UIPrimaryButton(
                label: 'Concluir',
                onPressed: () => Get.offAllNamed(AppRoutes.home),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.ink, size: 22),
        const SizedBox(width: AppSpacing.space3),
        UIText.heading(value),
        const SizedBox(width: AppSpacing.space2),
        Expanded(child: UIText.body(label, color: AppColors.inkMuted)),
      ],
    );
  }
}

String _formatDistance(int meters) {
  if (meters < 1000) return '$meters m';
  final km = meters / 1000;
  final digits = km >= 100 ? 0 : 1;
  return '${km.toStringAsFixed(digits).replaceAll('.', ',')} km';
}

String _formatDuration(int seconds) {
  final minutes = (seconds / 60).round();
  if (minutes < 60) return '$minutes min';
  final hours = minutes ~/ 60;
  final rest = minutes % 60;
  if (rest == 0) return '$hours h';
  return '$hours h $rest min';
}
