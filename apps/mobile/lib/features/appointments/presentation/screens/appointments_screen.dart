import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/routing/verification_gate.dart';
import '../../../../core/errors/error_text.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_error_view.dart';
import '../../../../shared/widgets/app_loading.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import '../../../../shared/widgets/app_section.dart';
import '../../../../shared/widgets/app_cell.dart';
import '../../../../shared/widgets/verification_required_view.dart';
import '../../../auth/presentation/providers/auth_controller.dart';
import '../providers/appointments_providers.dart';
import '../utils/appointment_actions.dart';

class AppointmentsScreen extends ConsumerWidget {
  const AppointmentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncItems = ref.watch(appointmentsProvider);
    final myId = ref.watch(authControllerProvider).user?.id;

    return CupertinoPageScaffold(
      child: SafeArea(
        child: asyncItems.when(
          data: (items) {
            return CustomScrollView(
              slivers: [
                CupertinoSliverNavigationBar(
                  largeTitle: const Text('Randevular'),
                  trailing: CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => ref.invalidate(appointmentsProvider),
                    child: const Icon(CupertinoIcons.refresh, size: 22, color: AppColors.primary),
                  ),
                  border: const Border(bottom: BorderSide(color: AppColors.separator)),
                  backgroundColor: AppColors.surface,
                ),
                if (items.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: AppEmptyState(
                      title: 'Randevu yok',
                      description: 'Olusturdugun randevular burada gorunur.',
                      icon: CupertinoIcons.calendar,
                      secondaryLabel: 'Yenile',
                      onSecondary: () => ref.invalidate(appointmentsProvider),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    sliver: SliverList.separated(
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, i) {
                        final a = items[i];
                        final isSeller = myId != null && a.sellerId == myId;
                        final isBuyer = myId != null && a.buyerId == myId;
                        final avail = AppointmentActionAvailability(status: a.status);

                        return AppSection(
                          header: 'Ilan ${a.listingId}',
                          children: [
                            AppCell(
                              icon: CupertinoIcons.time,
                              title: 'Tarih',
                              subtitle: a.scheduledAt.toLocal().toString(),
                              trailing: const SizedBox.shrink(),
                            ),
                            AppCell(
                              icon: CupertinoIcons.location,
                              title: 'Konum',
                              subtitle: a.location,
                              trailing: const SizedBox.shrink(),
                            ),
                            if ((a.notes ?? '').trim().isNotEmpty)
                              AppCell(
                                icon: CupertinoIcons.pencil,
                                title: 'Not',
                                subtitle: a.notes!,
                                trailing: const SizedBox.shrink(),
                              ),
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  _ActionButton(
                                    label: 'Tarih',
                                    icon: CupertinoIcons.calendar,
                                    onPressed: !avail.canReschedule
                                        ? null
                                        : () async {
                                            if (!VerificationGate.ensureVerified(
                                              context: context,
                                              ref: ref,
                                              message: 'Randevu islemleri icin hesabini dogrulaman gerekiyor.',
                                            )) {
                                              return;
                                            }
                                            final now = DateTime.now();
                                            final date = await showDatePicker(
                                              context: context,
                                              firstDate: now,
                                              lastDate: now.add(const Duration(days: 180)),
                                              initialDate: a.scheduledAt,
                                            );
                                            if (date == null) return;
                                            if (!context.mounted) return;
                                            final time = await showTimePicker(
                                              context: context,
                                              initialTime: TimeOfDay.fromDateTime(a.scheduledAt),
                                            );
                                            if (time == null) return;
                                            final dt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
                                            try {
                                              await ref.read(appointmentsRepositoryProvider).reschedule(a.id, dt);
                                              ref.invalidate(appointmentsProvider);
                                            } catch (e) {
                                              final msg = friendlyErrorText(e);
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
                                              }
                                            }
                                          },
                                  ),
                                  if ((isBuyer || isSeller) && avail.canCancel)
                                    _PrimaryActionButton(
                                      onPressed: () async {
                                        if (!VerificationGate.ensureVerified(
                                          context: context,
                                          ref: ref,
                                          message: 'Randevu islemleri icin hesabini dogrulaman gerekiyor.',
                                        )) {
                                          return;
                                        }
                                        try {
                                          await ref.read(appointmentsRepositoryProvider).cancel(a.id);
                                          ref.invalidate(appointmentsProvider);
                                        } catch (e) {
                                          final msg = friendlyErrorText(e);
                                          if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
                                        }
                                      },
                                      label: 'Iptal',
                                      icon: CupertinoIcons.xmark_circle_fill,
                                    ),
                                  if (isSeller && avail.canAcceptDecline) ...[
                                    _ActionButton(
                                      onPressed: () async {
                                        if (!VerificationGate.ensureVerified(
                                          context: context,
                                          ref: ref,
                                          message: 'Randevu islemleri icin hesabini dogrulaman gerekiyor.',
                                        )) {
                                          return;
                                        }
                                        try {
                                          await ref.read(appointmentsRepositoryProvider).accept(a.id);
                                          ref.invalidate(appointmentsProvider);
                                        } catch (e) {
                                          final msg = friendlyErrorText(e);
                                          if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
                                        }
                                      },
                                      label: 'Kabul',
                                      icon: CupertinoIcons.checkmark_seal,
                                    ),
                                    _ActionButton(
                                      onPressed: () async {
                                        if (!VerificationGate.ensureVerified(
                                          context: context,
                                          ref: ref,
                                          message: 'Randevu islemleri icin hesabini dogrulaman gerekiyor.',
                                        )) {
                                          return;
                                        }
                                        try {
                                          await ref.read(appointmentsRepositoryProvider).decline(a.id);
                                          ref.invalidate(appointmentsProvider);
                                        } catch (e) {
                                          final msg = friendlyErrorText(e);
                                          if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
                                        }
                                      },
                                      label: 'Reddet',
                                      icon: CupertinoIcons.xmark_seal,
                                    ),
                                  ],
                                  if (isSeller && avail.canCompleteOrNoShow) ...[
                                    _PrimaryActionButton(
                                      onPressed: () async {
                                        if (!VerificationGate.ensureVerified(
                                          context: context,
                                          ref: ref,
                                          message: 'Randevu islemleri icin hesabini dogrulaman gerekiyor.',
                                        )) {
                                          return;
                                        }
                                        try {
                                          await ref.read(appointmentsRepositoryProvider).complete(a.id);
                                          ref.invalidate(appointmentsProvider);
                                        } catch (e) {
                                          final msg = friendlyErrorText(e);
                                          if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
                                        }
                                      },
                                      label: 'Tamam',
                                      icon: CupertinoIcons.checkmark_circle_fill,
                                    ),
                                    _ActionButton(
                                      onPressed: () async {
                                        if (!VerificationGate.ensureVerified(
                                          context: context,
                                          ref: ref,
                                          message: 'Randevu islemleri icin hesabini dogrulaman gerekiyor.',
                                        )) {
                                          return;
                                        }
                                        try {
                                          await ref.read(appointmentsRepositoryProvider).noShow(a.id);
                                          ref.invalidate(appointmentsProvider);
                                        } catch (e) {
                                          final msg = friendlyErrorText(e);
                                          if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
                                        }
                                      },
                                      label: 'No-show',
                                      icon: CupertinoIcons.hand_raised_slash,
                                    ),
                                  ],
                                  _ActionButton(
                                    onPressed: !avail.canRate
                                        ? null
                                        : () async {
                                            if (!VerificationGate.ensureVerified(
                                              context: context,
                                              ref: ref,
                                              message: 'Randevu islemleri icin hesabini dogrulaman gerekiyor.',
                                            )) {
                                              return;
                                            }
                                            final rating = await showDialog<int>(
                                              context: context,
                                              builder: (_) => const _RateDialog(),
                                            );
                                            if (rating == null) return;
                                            try {
                                              await ref.read(appointmentsRepositoryProvider).rate(a.id, rating);
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Degerlendirildi')));
                                              }
                                            } catch (e) {
                                              final msg = friendlyErrorText(e);
                                              if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
                                            }
                                          },
                                    label: 'Puan',
                                    icon: CupertinoIcons.star_circle,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
              ],
            );
          },
          error: (e, _) {
            if (isForbiddenError(e)) {
              return VerificationRequiredView(
                message: 'Randevu islemleri icin hesabini dogrulaman gerekiyor.',
                next: '/app/appointments',
                onRetry: () => ref.invalidate(appointmentsProvider),
              );
            }
            return AppErrorView(
              title: 'Randevular yuklenemedi',
              description: friendlyErrorText(e),
              onRetry: () => ref.invalidate(appointmentsProvider),
            );
          },
          loading: () => const AppLoading(message: 'Yukleniyor...'),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.label, required this.icon, required this.onPressed});

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null;
    return CupertinoButton(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      onPressed: onPressed,
      borderRadius: BorderRadius.circular(999),
      color: AppColors.surface,
      disabledColor: AppColors.surface,
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

class _PrimaryActionButton extends StatelessWidget {
  const _PrimaryActionButton({required this.label, required this.icon, required this.onPressed});

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

class _RateDialog extends StatefulWidget {
  const _RateDialog();

  @override
  State<_RateDialog> createState() => _RateDialogState();
}

class _RateDialogState extends State<_RateDialog> {
  int _rating = 5;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Puan ver'),
      content: DropdownButton<int>(
        value: _rating,
        items: List.generate(5, (i) => i + 1)
            .map((v) => DropdownMenuItem(value: v, child: Text('$v')))
            .toList(),
        onChanged: (v) => setState(() => _rating = v ?? 5),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Vazgec')),
        FilledButton(onPressed: () => Navigator.of(context).pop(_rating), child: const Text('Gonder')),
      ],
    );
  }
}
