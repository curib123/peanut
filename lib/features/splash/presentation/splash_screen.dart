import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../progress/application/progress_controller.dart';

class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(progressControllerProvider);
    if (progress.isLoaded) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.go('/home');
      });
    }
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bakery_dining_rounded, size: 88),
            SizedBox(height: 20),
            Text('Puff & Crunch'),
            SizedBox(height: 20),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
