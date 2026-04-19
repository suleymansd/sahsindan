import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/error_mapper.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_chrome.dart';
import '../providers/auth_controller.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key, this.resetToken});

  final String? resetToken;

  @override
  ConsumerState<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _token;
  final _password = TextEditingController();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _token = TextEditingController(text: widget.resetToken ?? '');
  }

  @override
  void dispose() {
    _token.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await ref.read(authControllerProvider.notifier).resetPassword(
            token: _token.text.trim(),
            newPassword: _password.text,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sifre sifirlandi.')));
        context.go('/login');
      }
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
      appBar: AppBar(title: const Text('Sifre Sifirla')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            const Center(
              child: AppHeroBadgeIcon(icon: Icons.key_rounded, size: 72),
            ),
            const SizedBox(height: 12),
            Text(
              'Yeni sifre olustur',
              textAlign: TextAlign.center,
              style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            Text(
              'Token ve yeni sifre ile hesaba tekrar erisim ac.',
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
                      controller: _token,
                      decoration: const InputDecoration(labelText: 'Reset token', prefixIcon: Icon(Icons.confirmation_number_outlined)),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Token gerekli' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _password,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'Yeni sifre', prefixIcon: Icon(Icons.lock_outline_rounded)),
                      validator: (v) {
                        final t = v ?? '';
                        if (t.length < 6) return 'Sifre en az 6 karakter';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _loading ? null : _submit,
                      child: SizedBox(
                        width: double.infinity,
                        child: Center(child: Text(_loading ? 'Gonderiliyor...' : 'Sifreyi sifirla')),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
