import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:teste_spixs/core/design/design.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.surface100,
        body: SafeArea(
          child: Padding(
            padding: AppSpacing.screen,
            child: const UIText.title('Home'),
          ),
        ),
      ),
    );
  }
}
