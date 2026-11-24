import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'app/routes/app_pages.dart';
import 'app/theme/app_theme.dart';
import 'features/game/data/progress_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await progressService.initialize();
  runApp(const ArrowEscapeApp());
}

class ArrowEscapeApp extends StatelessWidget {
  const ArrowEscapeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Arrow Escape',
      theme: AppTheme.light,
      initialRoute: AppPages.home,
      getPages: AppPages.pages,
    );
  }
}
