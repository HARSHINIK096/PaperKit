import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Legacy compatibility shim.
/// The old BiometricAppLockScreen has been replaced by the new
/// Biometric Vault feature. This class redirects to the new vault page
/// so that any existing navigation links remain functional.
class BiometricAppLockScreen extends StatelessWidget {
  const BiometricAppLockScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Redirect to new Biometric Vault page
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) {
        context.go('/vault');
      }
    });
    return const SizedBox.shrink();
  }
}
