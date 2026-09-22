import 'package:flutter/material.dart';
import 'package:teste_spixs/core/design/design.dart';
import 'package:teste_spixs/features/home/domain/entities/place_details.dart';

class RecentAddressesList extends StatelessWidget {
  const RecentAddressesList({
    super.key,
    required this.addresses,
    required this.onSelected,
  });

  final List<PlaceDetails> addresses;
  final ValueChanged<PlaceDetails> onSelected;

  @override
  Widget build(BuildContext context) {
    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(AppSpacing.space3, 0, AppSpacing.space3, AppSpacing.space2),
          child: UIText.caption('Recentes'),
        ),
        for (final place in addresses)
          InkWell(
            onTap: () {
              FocusManager.instance.primaryFocus?.unfocus();
              onSelected(place);
            },
            child: Padding(
              padding: AppSpacing.card,
              child: UIText.body(place.address),
            ),
          ),
      ],
    );
  }
}
