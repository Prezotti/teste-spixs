import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:teste_spixs/core/design/design.dart';
import 'package:teste_spixs/features/home/controllers/address_field.dart';
import 'package:teste_spixs/features/home/controllers/home_controller.dart';
import 'package:teste_spixs/features/home/widgets/place_suggestions_list.dart';

class HomePage extends GetView<HomeController> {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface100,
      body: SafeArea(
        child: Padding(
          padding: AppSpacing.screen,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const UIText.title('Para onde vamos?'),
              const SizedBox(height: AppSpacing.space2),
              const UIText.body(
                'Adicione 3 endereços para otimizar a rota.',
                color: AppColors.inkMuted,
              ),
              const SizedBox(height: AppSpacing.space4),
              Expanded(
                child: Obx(() {
                  final fields = controller.points.toList();
                  return ListView(
                    children: [
                      for (var index = 0; index < fields.length; index++) ...[
                        _AddressFieldRow(
                          index: index,
                          field: fields[index],
                        ),
                        const SizedBox(height: AppSpacing.space2),
                      ],
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(
                          onPressed: controller.addPoint,
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.brand,
                            textStyle: AppTypography.bodyStrong,
                            padding: EdgeInsets.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text('Adicionar ponto'),
                        ),
                      ),
                    ],
                  );
                }),
              ),
              const SizedBox(height: AppSpacing.space3),
              Obx(
                () => UIPrimaryButton(
                  label: 'Confirmar rota',
                  onPressed: controller.canConfirm.value
                      ? controller.confirmRoute
                      : null,
                ),
              ),
              const SizedBox(height: AppSpacing.space2),
              Obx(() {
                if (controller.canConfirm.value) {
                  return const SizedBox.shrink();
                }
                return const Center(
                  child: UIText.caption(
                    'Preencha os 3 endereços para continuar',
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddressFieldRow extends GetView<HomeController> {
  const _AddressFieldRow({
    required this.index,
    required this.field,
  });

  final int index;
  final AddressField field;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: UIPrimaryInput(
                key: ObjectKey(field),
                controller: field.textController,
                focusNode: field.focusNode,
                hintText: field.label,
                errorText: field.error,
                onChanged: (value) => controller.onQueryChanged(index, value),
                onClear: () => controller.onClear(index),
              ),
            ),
            if (index >= HomeController.minStops)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.space2),
                child: IconButton(
                  onPressed: () => controller.removePoint(index),
                  icon: const Icon(Icons.close, size: 20),
                  color: AppColors.inkMuted,
                  tooltip: 'Remover ponto',
                  visualDensity: VisualDensity.compact,
                ),
              ),
          ],
        ),
        Obx(() {
          final panel = controller.searchPanel.value;
          if (panel.index != index) return const SizedBox.shrink();

          return PlaceSuggestionsList(
            suggestions: panel.suggestions,
            isLoading: panel.isLoading,
            errorText: panel.errorText,
            onSelected: (prediction) =>
                controller.selectPrediction(index, prediction),
          );
        }),
      ],
    );
  }
}
