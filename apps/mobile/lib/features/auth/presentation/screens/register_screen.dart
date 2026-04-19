import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/error_mapper.dart';
import '../../../../core/l10n/strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_chrome.dart';
import '../providers/auth_controller.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  String _city = 'ISTANBUL';
  bool _loading = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await ref.read(authControllerProvider.notifier).register(
            email: _email.text.trim(),
            phone: _phone.text.trim(),
            password: _password.text,
            name: _name.text.trim(),
            city: _city,
          );
      if (mounted) context.go('/app/listings');
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
      appBar: AppBar(title: const Text(S.registerTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            const Center(
              child: AppHeroBadgeIcon(icon: Icons.person_add_alt_1_rounded, size: 74),
            ),
            const SizedBox(height: 12),
            Text(
              'Guvenilir hesap olustur',
              textAlign: TextAlign.center,
              style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            Text(
              'Dogrulama adimini tamamla, tum ozellikleri ac.',
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
                      controller: _name,
                      decoration: const InputDecoration(labelText: S.name, prefixIcon: Icon(Icons.badge_outlined)),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Ad soyad gerekli' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(labelText: S.email, prefixIcon: Icon(Icons.mail_outline_rounded)),
                      validator: (v) {
                        final t = (v ?? '').trim();
                        if (t.isEmpty) return 'E-posta gerekli';
                        if (!t.contains('@')) return 'Gecerli e-posta girin';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _phone,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(labelText: S.phone, hintText: '5552000000', prefixIcon: Icon(Icons.phone_outlined)),
                      validator: (v) {
                        final t = (v ?? '').trim();
                        if (t.isEmpty) return 'Telefon gerekli';
                        if (t.length < 10) return 'Telefon en az 10 hane';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _password,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: S.password, prefixIcon: Icon(Icons.lock_outline_rounded)),
                      validator: (v) {
                        final t = v ?? '';
                        if (t.length < 6) return 'Sifre en az 6 karakter';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _city,
                      items: const [DropdownMenuItem(value: 'ISTANBUL', child: Text('Istanbul'))],
                      onChanged: (v) => setState(() => _city = v ?? 'ISTANBUL'),
                      decoration: const InputDecoration(labelText: S.city, prefixIcon: Icon(Icons.location_city_outlined)),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _loading ? null : _submit,
                      child: SizedBox(
                        width: double.infinity,
                        child: Center(child: Text(_loading ? 'Kayit yapiliyor...' : S.registerTitle)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => context.go('/login'),
              child: const Text('Zaten hesabim var'),
            ),
          ],
        ),
      ),
    );
  }
}
