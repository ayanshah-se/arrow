import 'package:get/get.dart';

import '../../features/game/presentation/bindings/game_binding.dart';
import '../../features/game/presentation/ui/game_page.dart';
import '../../features/game/presentation/ui/home_screen.dart';

abstract final class AppPages {
  static const home = '/';
  static const game = '/game';

  static final pages = <GetPage<dynamic>>[
    GetPage(name: home, page: HomeScreen.new),
    GetPage(name: game, page: GamePage.new, binding: GameBinding()),
  ];
}
