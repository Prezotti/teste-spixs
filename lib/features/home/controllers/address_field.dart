import 'package:flutter/material.dart';
import 'package:teste_spixs/features/home/domain/entities/place_details.dart';

class AddressField {
  AddressField({required this.label})
    : textController = TextEditingController(),
      focusNode = FocusNode();

  String label;
  final TextEditingController textController;
  final FocusNode focusNode;
  PlaceDetails? selected;
  String? error;

  bool get hasSelection => selected != null;

  void dispose() {
    textController.dispose();
    focusNode.dispose();
  }
}
