import 'package:flutter/material.dart';

import '../../../core/widgets/app_logo.dart';

/// Shown while the stored session is being restored.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppLogo(size: 56),
            SizedBox(height: 12),
            Wordmark(fontSize: 28),
            SizedBox(height: 24),
            SizedBox.square(dimension: 24, child: CircularProgressIndicator(strokeWidth: 2.5)),
          ],
        ),
      ),
    );
  }
}
