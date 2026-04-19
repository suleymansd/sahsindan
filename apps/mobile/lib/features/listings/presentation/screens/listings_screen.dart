import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/error_text.dart';
import '../../../../core/routing/verification_gate.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_error_view.dart';
import '../../../../shared/widgets/app_chrome.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import '../../../../shared/widgets/app_skeleton.dart';
import '../../../auth/presentation/providers/auth_controller.dart';
import '../providers/listings_providers.dart';
import '../widgets/listing_row.dart';

class ListingsScreen extends ConsumerWidget {
  const ListingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncListings = ref.watch(listingsProvider);
    final query = ref.watch(listingsQueryProvider);
    final auth = ref.watch(authControllerProvider);

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Ilanlar'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () => context.push('/app/listings/favorites'),
              child: const Icon(CupertinoIcons.heart, size: 22),
            ),
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () => context.push('/app/listings/mine'),
              child: const Icon(CupertinoIcons.archivebox, size: 22),
            ),
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () async {
                final newQuery = await showModalBottomSheet<ListingsQuery>(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => _FiltersSheet(initial: query),
                );
                if (newQuery != null) {
                  ref.read(listingsQueryProvider.notifier).state = newQuery;
                }
              },
              child: const Icon(CupertinoIcons.slider_horizontal_3, size: 22),
            ),
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () {
                if (!VerificationGate.ensureVerified(
                  context: context,
                  ref: ref,
                  message: 'Ilan vermek icin hesabini dogrulaman gerekiyor.',
                )) {
                  return;
                }
                context.go('/app/listings/new');
              },
              child: const Icon(CupertinoIcons.add, size: 24),
            ),
          ],
        ),
        border: const Border(bottom: BorderSide(color: AppColors.separator)),
        backgroundColor: AppColors.surface,
      ),
      child: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: CupertinoSearchTextField(
                  placeholder: 'Ara: baslik, marka, ilan no',
                  onSubmitted: (v) {
                    final t = v.trim();
                    ref.read(listingsQueryProvider.notifier).state = query.copyWith(q: t.isEmpty ? null : t);
                  },
                ),
              ),
            ),
            if (!auth.isVerified)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                  child: _VerificationBanner(
                    onTap: () => context.push('/verification/status?message=Hesabini%20dogrula%2C%20ilan%20ver%20ve%20mesajlas.'),
                  ),
                ),
              ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Row(
                  children: [
                    FilterChip(
                      label: const Text('Aktifligi onayla'),
                      selected: query.needsConfirmationOnly,
                      onSelected: (v) {
                        ref.read(listingsQueryProvider.notifier).state = query.copyWith(needsConfirmationOnly: v);
                      },
                      avatar: const Icon(CupertinoIcons.exclamationmark_triangle, size: 18),
                    ),
                    const SizedBox(width: 8),
                    if (query.brand != null ||
                        query.model != null ||
                        query.yearMin != null ||
                        query.yearMax != null ||
                        query.mileageMin != null ||
                        query.mileageMax != null ||
                        query.district != null)
                      OutlinedButton(
                        onPressed: () {
                          ref.read(listingsQueryProvider.notifier).state = ListingsQuery(city: query.city, needsConfirmationOnly: query.needsConfirmationOnly);
                        },
                        child: const Text('Temizle'),
                      ),
                    const Spacer(),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () => ref.invalidate(listingsProvider),
                      child: const Icon(CupertinoIcons.refresh, size: 22),
                    ),
                  ],
                ),
              ),
            ),
            asyncListings.when(
              data: (items) {
                if (items.isEmpty) {
                  return SliverFillRemaining(
                    hasScrollBody: false,
                    child: AppEmptyState(
                      title: 'Ilan yok',
                      description: 'Filtreleri degistirerek tekrar dene.',
                      icon: CupertinoIcons.car_detailed,
                      secondaryLabel: 'Yenile',
                      onSecondary: () => ref.invalidate(listingsProvider),
                    ),
                  );
                }
                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  sliver: SliverList.separated(
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final listing = items[index];
                      return ListingRow(
                        listing: listing,
                        onTap: () => context.go('/app/listings/${listing.id}'),
                      );
                    },
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                  ),
                );
              },
              error: (e, _) => SliverFillRemaining(
                hasScrollBody: false,
                child: AppErrorView(
                  title: 'Ilanlar yuklenemedi',
                  description: friendlyErrorText(e),
                  onRetry: () => ref.invalidate(listingsProvider),
                ),
              ),
              loading: () => SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                sliver: SliverList.separated(
                  itemCount: 8,
                  itemBuilder: (_, __) => const ListingRowSkeleton(),
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VerificationBanner extends StatelessWidget {
  const _VerificationBanner({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.separator),
        ),
        child: Row(
          children: [
            const Icon(CupertinoIcons.lock_shield, color: AppColors.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Dogrula, daha fazlasini yap',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Ilan ver, favorilere ekle, mesajlas ve randevu olustur.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            const Icon(CupertinoIcons.chevron_forward, color: AppColors.primary, size: 18),
          ],
        ),
      ),
    );
  }
}

class _FiltersSheet extends StatefulWidget {
  const _FiltersSheet({required this.initial});

  final ListingsQuery initial;

  @override
  State<_FiltersSheet> createState() => _FiltersSheetState();
}

class _FiltersSheetState extends State<_FiltersSheet> {
  late final TextEditingController _min;
  late final TextEditingController _max;
  late final TextEditingController _district;
  late final TextEditingController _brand;
  late final TextEditingController _model;
  late final TextEditingController _yearMin;
  late final TextEditingController _yearMax;
  late final TextEditingController _mileageMin;
  late final TextEditingController _mileageMax;
  String _transmission = '';
  String _fuel = '';
  String _sort = 'newest';

  @override
  void initState() {
    super.initState();
    _min = TextEditingController(text: widget.initial.minPrice?.toStringAsFixed(0) ?? '');
    _max = TextEditingController(text: widget.initial.maxPrice?.toStringAsFixed(0) ?? '');
    _district = TextEditingController(text: widget.initial.district ?? '');
    _brand = TextEditingController(text: widget.initial.brand ?? '');
    _model = TextEditingController(text: widget.initial.model ?? '');
    _yearMin = TextEditingController(text: widget.initial.yearMin?.toString() ?? '');
    _yearMax = TextEditingController(text: widget.initial.yearMax?.toString() ?? '');
    _mileageMin = TextEditingController(text: widget.initial.mileageMin?.toString() ?? '');
    _mileageMax = TextEditingController(text: widget.initial.mileageMax?.toString() ?? '');
    _transmission = widget.initial.transmission ?? '';
    _fuel = widget.initial.fuel ?? '';
    _sort = widget.initial.sort;
  }

  @override
  void dispose() {
    _min.dispose();
    _max.dispose();
    _district.dispose();
    _brand.dispose();
    _model.dispose();
    _yearMin.dispose();
    _yearMax.dispose();
    _mileageMin.dispose();
    _mileageMax.dispose();
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
          children: [
            TextField(
              controller: _district,
              decoration: const InputDecoration(labelText: 'Ilce (district)'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _brand,
                    decoration: const InputDecoration(labelText: 'Marka (brand)'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _model,
                    decoration: const InputDecoration(labelText: 'Model'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _yearMin,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Yil min'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _yearMax,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Yil max'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _mileageMin,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Km min'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _mileageMax,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Km max'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _min,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Min fiyat'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _max,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Max fiyat'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _transmission.isEmpty ? null : _transmission,
                    items: const [
                      DropdownMenuItem(value: 'Automatic', child: Text('Otomatik (Automatic)')),
                      DropdownMenuItem(value: 'Manual', child: Text('Manuel (Manual)')),
                    ],
                    onChanged: (v) => setState(() => _transmission = v ?? ''),
                    decoration: const InputDecoration(labelText: 'Sanziman'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _fuel.isEmpty ? null : _fuel,
                    items: const [
                      DropdownMenuItem(value: 'Gasoline', child: Text('Benzin (Gasoline)')),
                      DropdownMenuItem(value: 'Diesel', child: Text('Dizel (Diesel)')),
                      DropdownMenuItem(value: 'Hybrid', child: Text('Hibrit (Hybrid)')),
                      DropdownMenuItem(value: 'Electric', child: Text('Elektrik (Electric)')),
                      DropdownMenuItem(value: 'LPG', child: Text('LPG (LPG)')),
                    ],
                    onChanged: (v) => setState(() => _fuel = v ?? ''),
                    decoration: const InputDecoration(labelText: 'Yakit'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _sort,
              items: const [
                DropdownMenuItem(value: 'newest', child: Text('Yeni -> Eski')),
                DropdownMenuItem(value: 'price_asc', child: Text('Fiyat (artan)')),
                DropdownMenuItem(value: 'price_desc', child: Text('Fiyat (azalan)')),
                DropdownMenuItem(value: 'year_desc', child: Text('Yil (yeni)')),
                DropdownMenuItem(value: 'year_asc', child: Text('Yil (eski)')),
                DropdownMenuItem(value: 'mileage_asc', child: Text('Km (artan)')),
                DropdownMenuItem(value: 'mileage_desc', child: Text('Km (azalan)')),
              ],
              onChanged: (v) => setState(() => _sort = v ?? 'newest'),
              decoration: const InputDecoration(labelText: 'Siralama'),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).pop(
                        ListingsQuery(city: widget.initial.city, needsConfirmationOnly: widget.initial.needsConfirmationOnly),
                      );
                    },
                    child: const Text('Sifirla'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      final min = double.tryParse(_min.text.trim());
                      final max = double.tryParse(_max.text.trim());
                      final yearMin = int.tryParse(_yearMin.text.trim());
                      final yearMax = int.tryParse(_yearMax.text.trim());
                      final mileageMin = int.tryParse(_mileageMin.text.trim());
                      final mileageMax = int.tryParse(_mileageMax.text.trim());

                      Navigator.of(context).pop(
                        widget.initial.copyWith(
                          minPrice: min,
                          maxPrice: max,
                          district: _district.text.trim().isEmpty ? null : _district.text.trim(),
                          brand: _brand.text.trim().isEmpty ? null : _brand.text.trim(),
                          model: _model.text.trim().isEmpty ? null : _model.text.trim(),
                          yearMin: yearMin,
                          yearMax: yearMax,
                          mileageMin: mileageMin,
                          mileageMax: mileageMax,
                          transmission: _transmission.isEmpty ? null : _transmission,
                          fuel: _fuel.isEmpty ? null : _fuel,
                          sort: _sort,
                        ),
                      );
                    },
                    child: const SizedBox(width: double.infinity, child: Center(child: Text('Uygula'))),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
