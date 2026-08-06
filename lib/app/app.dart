import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import 'router.dart';

class PuffAndCrunchApp extends StatelessWidget {
  const PuffAndCrunchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Puff & Crunch: Island Match',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: appRouter,
    );
  }
}
