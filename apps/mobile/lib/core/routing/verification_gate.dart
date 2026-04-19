import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/providers/auth_controller.dart';

class VerificationGate {
  static bool ensureVerified({
    required BuildContext context,
    required WidgetRef ref,
    required String message,
    String? next,
  }) {
    final auth = ref.read(authControllerProvider);
    if (auth.isVerified) return true;

    // UI-level feedback.
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));

    final qp = <String, String>{'message': message};
    if (next != null && next.trim().isNotEmpty) qp['next'] = next.trim();
    context.push(Uri(path: '/verification/status', queryParameters: qp).toString());
    return false;
  }
}

