import 'package:flutter/material.dart';
import 'package:teste_spixs/core/design/design.dart';
import 'package:teste_spixs/features/home/domain/entities/place_prediction.dart';

class PlaceSuggestionsList extends StatelessWidget {
  const PlaceSuggestionsList({
    super.key,
    required this.suggestions,
    required this.isLoading,
    this.errorText,
    required this.onSelected,
    this.expanded = false,
  });

  final List<PlacePrediction> suggestions;
  final bool isLoading;
  final String? errorText;
  final ValueChanged<PlacePrediction> onSelected;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    if (!isLoading && errorText == null && suggestions.isEmpty) {
      return const SizedBox.shrink();
    }

    final tiles = <Widget>[
          if (isLoading)
            const Padding(
              padding: AppSpacing.card,
              child: UIText.caption('Buscando endereços...'),
            ),
          if (!isLoading && errorText != null)
            Padding(
              padding: AppSpacing.card,
              child: UIText.caption(errorText!, color: AppColors.danger),
            ),
          if (!isLoading)
            ...suggestions.map(
              (prediction) => InkWell(
                onTap: () {
                  FocusManager.instance.primaryFocus?.unfocus();
                  onSelected(prediction);
                },
                child: Padding(
                  padding: AppSpacing.card,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      UIText.body(prediction.mainText ?? prediction.description),
                      if (prediction.secondaryText != null) ...[
                        const SizedBox(height: AppSpacing.space1),
                        UIText.caption(prediction.secondaryText!),
                      ],
                    ],
                  ),
                ),
              ),
            ),
    ];

    if (expanded) {
      return ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        children: tiles,
      );
    }

    return Container(
      margin: const EdgeInsets.only(top: AppSpacing.space1),
      decoration: BoxDecoration(
        color: AppColors.surface200,
        borderRadius: AppRadius.mdAll,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: tiles,
      ),
    );
  }
}
