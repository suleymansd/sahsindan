import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/error_mapper.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_chrome.dart';
import '../providers/auth_controller.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  bool _loading = false;
  String? _resetToken;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final token = await ref.read(authControllerProvider.notifier).forgotPassword(_email.text.trim());
      setState(() => _resetToken = token);
    } catch (e) {
      final err = ErrorMapper.fromDio(e);
      final msg = err.when(
        network: (m) => m,
        unauthorized: () => 'Yetkisiz',
        forbidden: (m) => m ?? 'Erisim engellendi',
        rateLimited: (m) => m ?? 'Cok fazla istek',
        validation: (m, _) => m ?? 'Gecersiz veri',
        server: (m) => m,
        unknown: (m) => m,
      );
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Sifremi Unuttum')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            const Center(
              child: AppHeroBadgeIcon(icon: Icons.mark_email_unread_rounded, size: 72),
            ),
            const SizedBox(height: 12),
            Text(
              'Sifre yenileme baglantisi al',
              textAlign: TextAlign.center,
              style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            Text(
              'MVP modunda token uretilir, uretimde e-posta linki gonderilir.',
              textAlign: TextAlign.center,
              style: tt.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            AppGlass(
              radius: 24,
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(labelText: 'E-posta', prefixIcon: Icon(Icons.mail_outline_rounded)),
                      validator: (v) {
                        final t = (v ?? '').trim();
                        if (t.isEmpty) return 'E-posta gerekli';
                        if (!t.contains('@')) return 'Gecerli e-posta girin';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _loading ? null : _submit,
                      child: SizedBox(
                        width: double.infinity,
                        child: Center(child: Text(_loading ? 'Gonderiliyor...' : 'Reset token al')),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_resetToken != null) ...[
              const SizedBox(height: 14),
              AppGlass(
                radius: 20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Reset token', style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 8),
                    SelectableText(_resetToken!, style: tt.bodySmall?.copyWith(color: AppColors.textSecondary)),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () => context.go('/reset?token=${Uri.encodeComponent(_resetToken!)}'),
                      child: const Text('Sifre sifirlama ekranina git'),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
