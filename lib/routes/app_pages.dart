import 'package:get/get.dart';
import '../screens/connection/connection_screen.dart';

part 'app_routes.dart';

class AppPages {
  static const initial = Routes.CONNECTION;

  static final routes = [
    GetPage(
      name: Routes.CONNECTION,
      page: () => const ConnectionScreen(),
      // binding: ConnectionBinding(),
    ),
    // Add more routes here
  ];
}
