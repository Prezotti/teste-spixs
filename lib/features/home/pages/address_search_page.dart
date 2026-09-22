import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:teste_spixs/core/design/design.dart';
import 'package:teste_spixs/features/home/controllers/home_controller.dart';
import 'package:teste_spixs/features/home/widgets/place_suggestions_list.dart';

class AddressSearchPage extends GetView<HomeController> {
  const AddressSearchPage({super.key, required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    final field = controller.points[index];
    return Scaffold(
      backgroundColor: AppColors.surface100,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.space3,
            AppSpacing.space2,
            AppSpacing.space3,
            AppSpacing.space3,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconButton(
                    onPressed: Get.back,
                    icon: const Icon(Icons.arrow_back),
                    color: AppColors.ink,
                  ),
                  Expanded(
                    child: UIPrimaryInput(
                      controller: field.textController,
                      focusNode: field.focusNode,
                      hintText: field.label,
                      autofocus: true,
                      onChanged: (value) => controller.onQueryChanged(index, value),
                      onClear: () => controller.onClear(index),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.space3),
              Expanded(
                child: Obx(() {
                  final panel = controller.searchPanel.value;
                  if (panel.index != index) return const SizedBox.shrink();

                  return PlaceSuggestionsList(
                    expanded: true,
                    suggestions: panel.suggestions,
                    isLoading: panel.isLoading,
                    errorText: panel.errorText,
                    onSelected: (prediction) {
                      controller.selectPrediction(index, prediction).then((_) {
                        if (controller.points[index].hasSelection) Get.back();
                      });
                    },
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
