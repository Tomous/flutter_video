import 'package:flutter_mvc/main.dart';
import 'package:get/get.dart';

class RouterPage {
  static const String home = '/';
  static const String mvc = '/mvc';

  static final routes = [
    GetPage(
      name: home,
      page: () => const MyHomePage(),
    ),
  ];
}
