import 'package:get/get.dart';
import 'package:teste_spixs/core/routes/app_routes.dart';
import 'package:teste_spixs/features/auth/controllers/auth_controller.dart';
import 'package:teste_spixs/features/auth/pages/auth_page.dart';
import 'package:teste_spixs/features/home/pages/home_page.dart';

abstract final class AppPages {
  static final routes = [
    GetPage(
      name: AppRoutes.auth,
      page: () => const AuthPage(),
      binding: BindingsBuilder(() {
        Get.lazyPut<AuthController>(AuthController.new);
      }),
    ),
    GetPage(
      name: AppRoutes.home,
      page: () => const HomePage(),
    ),
  ];
}
