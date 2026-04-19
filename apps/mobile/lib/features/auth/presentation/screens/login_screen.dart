import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/error_mapper.dart';
import '../../../../core/l10n/strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_chrome.dart';
import '../providers/auth_controller.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await ref.read(authControllerProvider.notifier).login(_email.text.trim(), _password.text);
      if (mounted) context.go('/app/listings');
    } catch (e) {
      final err = ErrorMapper.fromDio(e);
      final msg = err.when(
        network: (m) => m,
        unauthorized: () => 'E-posta veya sifre hatali.',
        forbidden: (m) => m ?? 'Erisim engellendi.',
        rateLimited: (m) => m ?? 'Cok fazla deneme. Biraz bekleyin.',
        validation: (m, _) => m ?? 'Gecersiz veri',
        server: (m) => m,
        unknown: (m) => m,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _demoLogin() async {
    setState(() => _loading = true);
    try {
      await ref.read(authControllerProvider.notifier).login('verified@test.com', 'Test1234!');
      if (mounted) context.go('/app/listings');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Demo girisi basarisiz. Backend seed calisiyor mu?')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text(S.loginTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            const Center(
              child: AppHeroBadgeIcon(icon: Icons.login_rounded, size: 74),
            ),
            const SizedBox(height: 12),
            Text(
              'Hesabina guvenli giris yap',
              textAlign: TextAlign.center,
              style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            Text(
              'Ilanlar, mesajlar ve randevular tek panelde.',
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
                      autofillHints: const [AutofillHints.email],
                      decoration: const InputDecoration(labelText: S.email, prefixIcon: Icon(Icons.mail_outline_rounded)),
                      validator: (v) {
                        final t = (v ?? '').trim();
                        if (t.isEmpty) return 'E-posta gerekli';
                        if (!t.contains('@')) return 'Gecerli bir e-posta girin';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _password,
                      obscureText: true,
                      autofillHints: const [AutofillHints.password],
                      decoration: const InputDecoration(labelText: S.password, prefixIcon: Icon(Icons.lock_outline_rounded)),
                      validator: (v) {
                        final t = (v ?? '');
                        if (t.isEmpty) return 'Sifre gerekli';
                        if (t.length < 6) return 'Sifre en az 6 karakter';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _loading ? null : _submit,
                      child: SizedBox(
                        width: double.infinity,
                        child: Center(child: Text(_loading ? 'Giris yapiliyor...' : S.loginTitle)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => context.go('/register'),
                  child: const Text('Uye ol'),
                ),
                TextButton(
                  onPressed: () => context.go('/forgot'),
                  child: const Text('Sifremi unuttum'),
                ),
              ],
            ),
            if (kDebugMode) ...[
              const SizedBox(height: 2),
              Center(
                child: OutlinedButton.icon(
                  onPressed: _loading ? null : _demoLogin,
                  icon: const Icon(Icons.auto_awesome),
                  label: const Text('Demo ile giris'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
