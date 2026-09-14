import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_chrome.dart';
import '../../../../shared/widgets/app_loading.dart';
import '../../../auth/presentation/providers/auth_controller.dart';
import '../providers/verification_providers.dart';

class VerificationWizardScreen extends ConsumerStatefulWidget {
  const VerificationWizardScreen({super.key});

  @override
  ConsumerState<VerificationWizardScreen> createState() => _VerificationWizardScreenState();
}

class _VerificationWizardScreenState extends ConsumerState<VerificationWizardScreen> {
  bool _consent = false;

  PlatformFile? _idFront;
  PlatformFile? _idBack;
  PlatformFile? _selfie;
  PlatformFile? _profession;

  bool _loading = false;
  double? _progress;
  String? _status;

  @override
  void dispose() {
    super.dispose();
  }

  Future<PlatformFile?> _pick({required List<String> allowedExtensions}) async {
    final res = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: allowedExtensions,
      withData: true,
    );
    return res?.files.single;
  }

  Future<void> _submit() async {
    setState(() {
      _loading = true;
      _progress = null;
      _status = null;
    });

    try {
      final repo = ref.read(verificationRepositoryProvider);
      final requestId = await repo.submit(
        phoneOtp: '',
        backgroundConsent: _consent,
        professionProof: _profession != null,
      );

      Future<void> upload(PlatformFile file, String type) async {
        final bytes = file.bytes;
        if (bytes == null) throw StateError('Dosya okunamadi');

        final name = file.name;
        final ext = (name.split('.').lastOrNull ?? '').toLowerCase();
        final ct = ext == 'png' ? 'image/png' : 'image/jpeg';

        await repo.uploadAsset(
          requestId: requestId,
          type: type,
          filename: name,
          bytes: bytes,
          contentType: ct,
          onProgress: (sent, total) {
            if (!mounted || total <= 0) return;
            setState(() => _progress = sent / total);
          },
        );
      }

      if (_idFront != null) await upload(_idFront!, 'id_front');
      if (_idBack != null) await upload(_idBack!, 'id_back');
      if (_selfie != null) await upload(_selfie!, 'selfie');
      if (_profession != null) await upload(_profession!, 'profession');

      if (!mounted) return;
      setState(() {
        _status = 'Basvurun alinmistir. Inceleme sureci basladi.';
      });

      await ref.read(authControllerProvider.notifier).refreshVerificationStatus();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _status = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          _progress = null;
        });
      }
    }
  }

  Widget _fileRow(String label, PlatformFile? file, VoidCallback pick) {
    return AppGlass(
      radius: 16,
      child: Row(
        children: [
          const AppHeroBadgeIcon(icon: Icons.insert_drive_file_outlined, size: 34),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(file?.name ?? 'Secilmedi', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: pick,
            child: const Text('Sec'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dogrulama')),
      body: SafeArea(
        child: _loading
            ? Column(
                children: [
                  const Expanded(child: AppLoading(message: 'Gonderiliyor...')),
                  if (_progress != null)
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: LinearProgressIndicator(value: _progress),
                    ),
                ],
              )
            : ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  const AppGlass(
                    radius: 22,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            AppHeroBadgeIcon(icon: Icons.verified_user_rounded, size: 42),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Kimlik dogrulama adimlari',
                                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 6),
                        Text('Belgeleriniz yetkili ekip tarafından incelenir. Otomatik SMS veya biyometrik doğrulama yapılmaz.', style: TextStyle(color: AppColors.textSecondary, height: 1.5)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text('Yalnızca JPEG/PNG. İncelenen belgeler saklama süresi dolunca otomatik silinir.'),
                  _fileRow('Kimlik on (jpg/png)', _idFront, () async {
                    final f = await _pick(allowedExtensions: const ['jpg', 'jpeg', 'png']);
                    if (!mounted) return;
                    setState(() => _idFront = f);
                  }),
                  const SizedBox(height: 10),
                  _fileRow('Kimlik arka (jpg/png)', _idBack, () async {
                    final f = await _pick(allowedExtensions: const ['jpg', 'jpeg', 'png']);
                    if (!mounted) return;
                    setState(() => _idBack = f);
                  }),
                  const SizedBox(height: 10),
                  _fileRow('Selfie (jpg/png)', _selfie, () async {
                    final f = await _pick(allowedExtensions: const ['jpg', 'jpeg', 'png']);
                    if (!mounted) return;
                    setState(() => _selfie = f);
                  }),
                  const SizedBox(height: 10),
                  _fileRow('Meslek belgesi (jpg/png)', _profession, () async {
                    final f = await _pick(allowedExtensions: const ['jpg', 'jpeg', 'png']);
                    if (!mounted) return;
                    setState(() => _profession = f);
                  }),
                  const SizedBox(height: 12),
                  AppGlass(
                    radius: 18,
                    child: CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _consent,
                      onChanged: (v) => setState(() => _consent = v ?? false),
                      title: const Text('Belgelerimin hesap doğrulaması için incelenmesini kabul ediyorum.'),
                      activeColor: AppColors.primary,
                    ),
                  ),
                  if (_status != null) ...[
                    const SizedBox(height: 12),
                    Text(_status!, style: const TextStyle(color: AppColors.primaryDeep, fontWeight: FontWeight.w700)),
                  ],
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _consent ? _submit : null,
                    child: const Text('Dogrulamayi gonder'),
                  ),
                ],
              ),
      ),
    );
  }
}

extension on List<String> {
  String? get lastOrNull => isEmpty ? null : last;
}
