import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/error_text.dart';
import '../../../../core/network/providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/url_utils.dart';
import '../../../../core/routing/verification_gate.dart';
import '../../../../shared/widgets/app_chrome.dart';
import '../../../../shared/widgets/app_error_view.dart';
import '../../../../shared/widgets/app_loading.dart';
import '../../../../shared/widgets/app_section.dart';
import '../../../../shared/widgets/app_cell.dart';
import '../../../auth/presentation/providers/auth_controller.dart';
import '../../../appointments/presentation/providers/appointments_providers.dart';
import '../../../messaging/presentation/providers/messaging_providers.dart';
import '../../../reports/presentation/providers/reports_providers.dart';
import '../providers/listings_providers.dart';
import '../providers/favorites_state.dart';

class ListingDetailScreen extends ConsumerWidget {
  const ListingDetailScreen({super.key, required this.id});

  final int id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncListing = ref.watch(listingDetailProvider(id));
    final auth = ref.watch(authControllerProvider);
    final fav = ref.watch(favoritesControllerProvider);
    final favCtrl = ref.read(favoritesControllerProvider.notifier);

    return CupertinoPageScaffold(
      child: SafeArea(
        bottom: false,
        child: asyncListing.when(
          data: (listing) {
            final cfg = ref.watch(appConfigProvider);
            final photoUrls = listing.photos.map((p) => p.url).toList();
            final isOwner = auth.user?.id == listing.owner.id;

            Future<void> createThread() async {
              if (!VerificationGate.ensureVerified(
                context: context,
                ref: ref,
                message: 'Mesaj gondermek icin hesabini dogrulaman gerekiyor.',
              )) {
                return;
              }
              final t = await ref.read(messagingRepositoryProvider).createThread(listingId: listing.id);
              ref.invalidate(threadsProvider);
              if (context.mounted) context.go('/app/threads/${t.id}');
            }

            Future<void> createAppointment() async {
              if (!VerificationGate.ensureVerified(
                context: context,
                ref: ref,
                message: 'Randevu olusturmak icin hesabini dogrulaman gerekiyor.',
              )) {
                return;
              }
              final created = await showModalBottomSheet<_AppointmentDraft>(
                context: context,
                isScrollControlled: true,
                builder: (_) => _AppointmentSheet(listingId: listing.id),
              );
              if (created == null) return;
              await ref.read(appointmentsRepositoryProvider).create(
                    listingId: listing.id,
                    scheduledAt: created.scheduledAt,
                    location: created.location,
                    notes: created.notes,
                  );
              ref.invalidate(appointmentsProvider);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Randevu olusturuldu')));
                context.go('/app/appointments');
              }
            }

            Future<void> report() async {
              if (!VerificationGate.ensureVerified(
                context: context,
                ref: ref,
                message: 'Rapor gondermek icin hesabini dogrulaman gerekiyor.',
              )) {
                return;
              }
              final payload = await showDialog<_ReportDraft>(
                context: context,
                builder: (_) => const _ReportDialog(),
              );
              if (payload == null) return;
              await ref.read(reportsRepositoryProvider).createReport(
                    listingId: listing.id,
                    reason: payload.reason,
                    category: payload.category,
                  );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Rapor gonderildi')));
              }
            }

            Future<void> ownerAction(String action) async {
              if (!VerificationGate.ensureVerified(
                context: context,
                ref: ref,
                message: 'Ilan islemleri icin hesabini dogrulaman gerekiyor.',
              )) {
                return;
              }
              final repo = ref.read(listingsRepositoryProvider);
              if (action == 'publish') await repo.publish(listing.id);
              if (action == 'sold') await repo.markSold(listing.id);
              if (action == 'confirm') await repo.confirmActive(listing.id);
              ref.invalidate(listingDetailProvider(id));
              ref.invalidate(myListingsProvider);
              ref.invalidate(listingsProvider);
            }

            return Stack(
              children: [
                CustomScrollView(
                  slivers: [
                    CupertinoSliverNavigationBar(
                      largeTitle: const Text('Ilan'),
                      border: const Border(bottom: BorderSide(color: AppColors.separator)),
                      backgroundColor: AppColors.surface,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CupertinoButton(
                            padding: EdgeInsets.zero,
                            onPressed: fav.loading
                                ? null
                                : () async {
                                    if (!VerificationGate.ensureVerified(
                                      context: context,
                                      ref: ref,
                                      message: 'Favoriye eklemek icin hesabini dogrulaman gerekiyor.',
                                    )) {
                                      return;
                                    }
                                    try {
                                      await favCtrl.toggle(id);
                                    } catch (e) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(friendlyErrorText(e))));
                                      }
                                    }
                                  },
                            child: Icon(
                              fav.ids.contains(id) ? CupertinoIcons.heart_fill : CupertinoIcons.heart,
                              size: 22,
                              color: fav.ids.contains(id) ? AppColors.primary : AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 6),
                          CupertinoButton(
                            padding: EdgeInsets.zero,
                            onPressed: () => ref.invalidate(listingDetailProvider(id)),
                            child: const Icon(CupertinoIcons.refresh, size: 22, color: AppColors.primary),
                          ),
                        ],
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate(
                          [
                            if (!auth.isVerified) _InlineVerifyBanner(onTap: () => context.push('/verification/status?message=Ilan%20detayini%20goruyorsun.%20Islem%20yapmak%20icin%20dogrulama%20gerekli.')),
                            _PhotoCarousel(photos: photoUrls, publicBaseUrl: cfg.publicBaseUrl),
                            const SizedBox(height: 12),
                            Text(
                              listing.title,
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '₺${listing.price.toStringAsFixed(0)}',
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900, color: AppColors.textPrimary),
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _Pill(text: '${listing.city} • ${listing.district}', icon: CupertinoIcons.location),
                                _Pill(text: '${listing.carDetails.brand} ${listing.carDetails.model}', icon: CupertinoIcons.car_detailed),
                                _Pill(text: '${listing.carDetails.year}', icon: CupertinoIcons.calendar),
                                _Pill(text: '${listing.carDetails.mileage} km', icon: CupertinoIcons.speedometer),
                                _Pill(text: listing.state, icon: CupertinoIcons.circle_fill),
                                if (listing.staleState != null) _Pill(text: 'Stale: ${listing.staleState}', icon: CupertinoIcons.exclamationmark_triangle),
                              ],
                            ),
                            const SizedBox(height: 16),
                            AppSection(
                              header: 'Satici',
                              children: [
                                AppCell(
                                  icon: CupertinoIcons.person_crop_circle,
                                  title: listing.owner.name,
                                  subtitle: 'Trust score: ${listing.owner.trustScore}',
                                  trailing: const SizedBox.shrink(),
                                ),
                                if (listing.owner.responseTimeBucket != null)
                                  AppCell(
                                    icon: CupertinoIcons.timer,
                                    title: 'Yanıt hizı',
                                    subtitle: listing.owner.responseTimeBucket!,
                                    trailing: const SizedBox.shrink(),
                                  ),
                                AppCell(
                                  icon: CupertinoIcons.clock,
                                  title: 'Son aktif',
                                  subtitle: listing.owner.lastActiveBucket,
                                  trailing: const SizedBox.shrink(),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            AppSection(
                              header: 'Aciklama',
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Text(
                                    listing.description,
                                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.textPrimary),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            if (isOwner)
                              AppSection(
                                header: 'Ilan aksiyonlari',
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: [
                                        _OutlinePillButton(
                                          label: 'Duzenle',
                                          icon: CupertinoIcons.pencil,
                                          onPressed: () => context.go('/app/listings/${listing.id}/edit'),
                                        ),
                                        _PrimaryPillButton(
                                          label: 'Yayinla',
                                          icon: CupertinoIcons.arrow_up_circle_fill,
                                          onPressed: listing.state == 'DRAFT' ? () => ownerAction('publish') : null,
                                        ),
                                        _OutlinePillButton(
                                          label: 'Satildi',
                                          icon: CupertinoIcons.checkmark_seal,
                                          onPressed: listing.state == 'PUBLISHED' ? () => ownerAction('sold') : null,
                                        ),
                                        if (listing.staleState == 'NEEDS_CONFIRMATION')
                                          _PrimaryPillButton(
                                            label: 'Aktifligi onayla',
                                            icon: CupertinoIcons.checkmark_circle_fill,
                                            onPressed: () => ownerAction('confirm'),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: _BottomActions(
                    onMessage: () async {
                      try {
                        await createThread();
                      } catch (e) {
                        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(friendlyErrorText(e))));
                      }
                    },
                    onAppointment: () async {
                      try {
                        await createAppointment();
                      } catch (e) {
                        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(friendlyErrorText(e))));
                      }
                    },
                    onReport: () async {
                      try {
                        await report();
                      } catch (e) {
                        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(friendlyErrorText(e))));
                      }
                    },
                  ),
                ),
              ],
            );
          },
          error: (e, _) => AppErrorView(
            title: 'Ilan yuklenemedi',
            description: friendlyErrorText(e),
            onRetry: () => ref.invalidate(listingDetailProvider(id)),
          ),
          loading: () => const AppLoading(),
        ),
      ),
    );
  }
}

class _InlineVerifyBanner extends StatelessWidget {
  const _InlineVerifyBanner({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.separator),
          ),
          child: Row(
            children: [
              const Icon(CupertinoIcons.checkmark_shield, color: AppColors.primary, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Islem yapabilmek icin dogrulama gerekli',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Mesaj, randevu ve rapor icin hesabini dogrula.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              const Icon(CupertinoIcons.chevron_forward, color: AppColors.primary, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text, required this.icon});

  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.separator),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Text(text, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textPrimary)),
        ],
      ),
    );
  }
}

class _BottomActions extends StatelessWidget {
  const _BottomActions({
    required this.onMessage,
    required this.onAppointment,
    required this.onReport,
  });

  final VoidCallback onMessage;
  final VoidCallback onAppointment;
  final VoidCallback onReport;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.separator)),
        ),
        child: Row(
          children: [
            Expanded(
              child: CupertinoButton.filled(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                onPressed: onMessage,
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(CupertinoIcons.chat_bubble_2_fill, size: 18),
                    SizedBox(width: 8),
                    Text('Mesaj'),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _OutlineButton(
                onPressed: onAppointment,
                icon: CupertinoIcons.calendar_badge_plus,
                label: 'Randevu',
              ),
            ),
            const SizedBox(width: 10),
            _IconOnlyButton(onPressed: onReport, icon: CupertinoIcons.flag),
          ],
        ),
      ),
    );
  }
}

class _OutlineButton extends StatelessWidget {
  const _OutlineButton({required this.onPressed, required this.icon, required this.label});

  final VoidCallback? onPressed;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null;
    return CupertinoButton(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      onPressed: onPressed,
      color: disabled ? AppColors.separator : AppColors.surface,
      disabledColor: AppColors.separator,
      borderRadius: BorderRadius.circular(14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: disabled ? AppColors.textSecondary : AppColors.primary),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(color: disabled ? AppColors.textSecondary : AppColors.primary, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _IconOnlyButton extends StatelessWidget {
  const _IconOnlyButton({required this.onPressed, required this.icon});

  final VoidCallback onPressed;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      onPressed: onPressed,
      child: Icon(icon, size: 20, color: AppColors.primary),
    );
  }
}

class _PrimaryPillButton extends StatelessWidget {
  const _PrimaryPillButton({required this.label, required this.icon, required this.onPressed});

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton.filled(
      onPressed: onPressed,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }
}

class _OutlinePillButton extends StatelessWidget {
  const _OutlinePillButton({required this.label, required this.icon, required this.onPressed});

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null;
    return CupertinoButton(
      onPressed: onPressed,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      color: AppColors.surface,
      disabledColor: AppColors.surface,
      borderRadius: BorderRadius.circular(999),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppColors.separator),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: disabled ? AppColors.textSecondary : AppColors.primary),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(color: disabled ? AppColors.textSecondary : AppColors.primary, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PhotoCarousel extends StatefulWidget {
  const _PhotoCarousel({required this.photos, required this.publicBaseUrl});

  final List<String> photos;
  final String publicBaseUrl;

  @override
  State<_PhotoCarousel> createState() => _PhotoCarouselState();
}

class _PhotoCarouselState extends State<_PhotoCarousel> {
  int _active = 0;

  @override
  Widget build(BuildContext context) {
    final items = widget.photos;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        children: [
          AspectRatio(
            aspectRatio: 4 / 3,
            child: items.isEmpty
                ? Container(
                    color: AppColors.background,
                    child: const Center(child: Icon(CupertinoIcons.photo, size: 48, color: AppColors.textSecondary)),
                  )
                : PageView.builder(
                    itemCount: items.length,
                    onPageChanged: (i) => setState(() => _active = i),
                    itemBuilder: (context, i) {
                      final url = resolvePublicUrl(publicBaseUrl: widget.publicBaseUrl, maybeRelative: items[i]);
                      return Image.network(url, fit: BoxFit.cover);
                    },
                  ),
          ),
          Positioned(
            right: 12,
            bottom: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                items.isEmpty ? '0 / 0' : '${_active + 1} / ${items.length}',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AppointmentDraft {
  const _AppointmentDraft({required this.scheduledAt, required this.location, required this.notes});

  final DateTime scheduledAt;
  final String location;
  final String? notes;
}

class _AppointmentSheet extends StatefulWidget {
  const _AppointmentSheet({required this.listingId});

  final int listingId;

  @override
  State<_AppointmentSheet> createState() => _AppointmentSheetState();
}

class _AppointmentSheetState extends State<_AppointmentSheet> {
  DateTime _scheduled = DateTime.now().add(const Duration(days: 1));
  final _location = TextEditingController();
  final _notes = TextEditingController();

  @override
  void dispose() {
    _location.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + pad),
      child: AppGlass(
        radius: 24,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Randevu olustur', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () async {
                final now = DateTime.now();
                final date = await showDatePicker(
                  context: context,
                  firstDate: now,
                  lastDate: now.add(const Duration(days: 180)),
                  initialDate: _scheduled,
                );
                if (date == null) return;
                if (!context.mounted) return;
                final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_scheduled));
                if (time == null) return;
                setState(() {
                  _scheduled = DateTime(date.year, date.month, date.day, time.hour, time.minute);
                });
              },
              icon: const Icon(Icons.schedule),
              label: Text('Tarih: ${_scheduled.toLocal()}'),
            ),
            const SizedBox(height: 12),
            TextField(controller: _location, decoration: const InputDecoration(labelText: 'Konum')),
            const SizedBox(height: 12),
            TextField(controller: _notes, decoration: const InputDecoration(labelText: 'Not (opsiyonel)')),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {
                if (_location.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Konum gerekli')));
                  return;
                }
                Navigator.of(context).pop(_AppointmentDraft(
                  scheduledAt: _scheduled,
                  location: _location.text.trim(),
                  notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
                ));
              },
              child: const Text('Olustur'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportDraft {
  const _ReportDraft({required this.reason, this.category});

  final String reason;
  final String? category;
}

class _ReportDialog extends StatefulWidget {
  const _ReportDialog();

  @override
  State<_ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<_ReportDialog> {
  final _reason = TextEditingController();
  String? _category;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Raporla'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<String>(
            initialValue: _category,
            items: const [
              DropdownMenuItem(value: 'scam', child: Text('Sahte / scam')),
              DropdownMenuItem(value: 'spam', child: Text('Spam')),
              DropdownMenuItem(value: 'illegal', child: Text('Ihlal / illegal')),
            ],
            onChanged: (v) => setState(() => _category = v),
            decoration: const InputDecoration(labelText: 'Kategori (opsiyonel)'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _reason,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(labelText: 'Aciklama'),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Vazgec')),
        FilledButton(
          onPressed: () {
            if (_reason.text.trim().isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Aciklama gerekli')));
              return;
            }
            Navigator.of(context).pop(_ReportDraft(reason: _reason.text.trim(), category: _category));
          },
          child: const Text('Gonder'),
        ),
      ],
    );
  }
}
