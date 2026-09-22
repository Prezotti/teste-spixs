import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:teste_spixs/core/design/design.dart';
import 'package:teste_spixs/core/di/core_bindings.dart';
import 'package:teste_spixs/core/routes/app_pages.dart';
import 'package:teste_spixs/core/routes/app_routes.dart';

class RotaApp extends StatelessWidget {
  const RotaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Rota',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.surface100,
        colorScheme: const ColorScheme.light(
          primary: AppColors.brand,
          onPrimary: AppColors.onBrand,
          error: AppColors.danger,
          surface: AppColors.surface200,
          onSurface: AppColors.ink,
          outline: AppColors.border,
        ),
      ),
      initialBinding: CoreBindings(),
      initialRoute: AppRoutes.auth,
      getPages: AppPages.routes,
    );
  }
}
