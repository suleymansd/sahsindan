import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/error_text.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_error_view.dart';
import '../../../../shared/widgets/app_chrome.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import '../../../../shared/widgets/app_skeleton.dart';
import '../../../../shared/widgets/marketplace_header.dart';
import '../providers/comparison_provider.dart';
import '../providers/listings_providers.dart';
import '../widgets/listing_row.dart';

class ListingsScreen extends ConsumerWidget {
  const ListingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncListings = ref.watch(listingsProvider);
    final query = ref.watch(listingsQueryProvider);
    final selected = ref.watch(comparisonProvider);

    Future<void> filters() async {
      final newQuery = await showModalBottomSheet<ListingsQuery>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (_) => _FiltersSheet(initial: query),
      );
      if (newQuery != null && context.mounted) {
        ref.read(listingsQueryProvider.notifier).state = newQuery;
      }
    }

    return Scaffold(
      appBar: const MarketplaceHeader(),
      bottomNavigationBar: selected.isEmpty
          ? null
          : Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: FilledButton.icon(
                onPressed: () => context.push('/app/listings/compare'),
                icon: const Icon(Icons.compare_arrows_rounded),
                label:
                    Text('Seçilen ilanları karşılaştır (${selected.length}/3)'),
              ),
            ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(listingsProvider);
            await ref.read(listingsProvider.future);
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                  child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: MarketplaceSearch(
                    value: query.q ?? '',
                    onSearch: (value) {
                      ref.read(listingsQueryProvider.notifier).state =
                          query.copyWith(q: value.isEmpty ? null : value);
                    }),
              )),
              SliverToBoxAdapter(
                  child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Wrap(spacing: 8, runSpacing: 8, children: [
                  if (query.city != null)
                    InputChip(
                        label: const Text('İstanbul'),
                        onDeleted: () => ref
                            .read(listingsQueryProvider.notifier)
                            .state = query.copyWith(city: null)),
                  if (query.q != null)
                    InputChip(
                        label: Text(query.q!),
                        onDeleted: () => ref
                            .read(listingsQueryProvider.notifier)
                            .state = query.copyWith(q: null)),
                  if (query.brand != null)
                    InputChip(
                        label: Text(query.brand!),
                        onDeleted: () => ref
                            .read(listingsQueryProvider.notifier)
                            .state = query.copyWith(brand: null)),
                  ActionChip(
                      avatar: const Icon(Icons.tune_rounded, size: 16),
                      label: const Text('Filtrele'),
                      onPressed: filters),
                  ActionChip(
                      label: const Text('Sıfırla'),
                      onPressed: () => ref
                          .read(listingsQueryProvider.notifier)
                          .state = ListingsQuery()),
                ]),
              )),
              SliverToBoxAdapter(
                  child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                child: Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 16, runSpacing: 8,
                    children: [
                      Text('Sonuçlar',
                          style: Theme.of(context).textTheme.headlineSmall),
                      Text(
                          asyncListings.hasValue
                              ? '${asyncListings.requireValue.length} ilan bulundu'
                              : 'İlanlar yükleniyor',
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textSecondary)),
                    ]),
              )),
              if (query.offset > 0 || (asyncListings.valueOrNull?.length ?? 0) >= 50)
                SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  TextButton(onPressed: query.offset == 0 ? null : () => ref.read(listingsQueryProvider.notifier).state = query.copyWith(offset: query.offset - 50), child: const Text('Önceki')),
                  Text('Sayfa ${query.offset ~/ 50 + 1}'),
                  TextButton(onPressed: (asyncListings.valueOrNull?.length ?? 0) < 50 ? null : () => ref.read(listingsQueryProvider.notifier).state = query.copyWith(offset: query.offset + 50), child: const Text('Sonraki')),
                ]))),
              asyncListings.when(
                data: (items) {
                  if (items.isEmpty) {
                    return SliverFillRemaining(
                      hasScrollBody: false,
                      child: AppEmptyState(
                        title: 'Aradığınız ilan bulunamadı',
                        description:
                            'Başka bir kelimeyle arayın veya filtreleri sıfırlayın.',
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
                          onTap: () =>
                              context.go('/app/listings/${listing.id}'),
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
  bool _needsConfirmationOnly = false;

  @override
  void initState() {
    super.initState();
    _min = TextEditingController(
        text: widget.initial.minPrice?.toStringAsFixed(0) ?? '');
    _max = TextEditingController(
        text: widget.initial.maxPrice?.toStringAsFixed(0) ?? '');
    _district = TextEditingController(text: widget.initial.district ?? '');
    _brand = TextEditingController(text: widget.initial.brand ?? '');
    _model = TextEditingController(text: widget.initial.model ?? '');
    _yearMin =
        TextEditingController(text: widget.initial.yearMin?.toString() ?? '');
    _yearMax =
        TextEditingController(text: widget.initial.yearMax?.toString() ?? '');
    _mileageMin = TextEditingController(
        text: widget.initial.mileageMin?.toString() ?? '');
    _mileageMax = TextEditingController(
        text: widget.initial.mileageMax?.toString() ?? '');
    _transmission = widget.initial.transmission ?? '';
    _fuel = widget.initial.fuel ?? '';
    _sort = widget.initial.sort;
    _needsConfirmationOnly = widget.initial.needsConfirmationOnly;
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
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + pad),
      child: AppGlass(
        radius: 12,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text('Aktiflik onayı bekleyenler', style: TextStyle(fontSize: 14)),
              value: _needsConfirmationOnly,
              onChanged: (value) => setState(() => _needsConfirmationOnly = value),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _district,
              decoration: const InputDecoration(labelText: 'İlçe'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _brand,
                    decoration: const InputDecoration(labelText: 'Marka'),
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
                    isExpanded: true,
                    initialValue: _transmission.isEmpty ? null : _transmission,
                    items: const [
                      DropdownMenuItem(
                          value: 'Automatic', child: Text('Otomatik')),
                      DropdownMenuItem(value: 'Manual', child: Text('Manuel')),
                    ],
                    onChanged: (v) => setState(() => _transmission = v ?? ''),
                    decoration: const InputDecoration(labelText: 'Şanzıman'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    isExpanded: true,
                    initialValue: _fuel.isEmpty ? null : _fuel,
                    items: const [
                      DropdownMenuItem(
                          value: 'Gasoline', child: Text('Benzin')),
                      DropdownMenuItem(value: 'Diesel', child: Text('Dizel')),
                      DropdownMenuItem(value: 'Hybrid', child: Text('Hibrit')),
                      DropdownMenuItem(
                          value: 'Electric', child: Text('Elektrik')),
                      DropdownMenuItem(value: 'LPG', child: Text('LPG')),
                    ],
                    onChanged: (v) => setState(() => _fuel = v ?? ''),
                    decoration: const InputDecoration(labelText: 'Yakıt'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              isExpanded: true,
              initialValue: _sort,
              items: const [
                DropdownMenuItem(value: 'newest', child: Text('Yeni -> Eski')),
                DropdownMenuItem(
                    value: 'price_asc', child: Text('Fiyat (artan)')),
                DropdownMenuItem(
                    value: 'price_desc', child: Text('Fiyat (azalan)')),
                DropdownMenuItem(value: 'year_desc', child: Text('Yil (yeni)')),
                DropdownMenuItem(value: 'year_asc', child: Text('Yil (eski)')),
                DropdownMenuItem(
                    value: 'mileage_asc', child: Text('Km (artan)')),
                DropdownMenuItem(
                    value: 'mileage_desc', child: Text('Km (azalan)')),
              ],
              onChanged: (v) => setState(() => _sort = v ?? 'newest'),
              decoration: const InputDecoration(labelText: 'Sıralama'),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).pop(
                        ListingsQuery(
                            city: widget.initial.city,
                            needsConfirmationOnly:
                                widget.initial.needsConfirmationOnly),
                      );
                    },
                    child: const Text('Sıfırla'),
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
                          needsConfirmationOnly: _needsConfirmationOnly,
                          minPrice: min,
                          maxPrice: max,
                          district: _district.text.trim().isEmpty
                              ? null
                              : _district.text.trim(),
                          brand: _brand.text.trim().isEmpty
                              ? null
                              : _brand.text.trim(),
                          model: _model.text.trim().isEmpty
                              ? null
                              : _model.text.trim(),
                          yearMin: yearMin,
                          yearMax: yearMax,
                          mileageMin: mileageMin,
                          mileageMax: mileageMax,
                          transmission:
                              _transmission.isEmpty ? null : _transmission,
                          fuel: _fuel.isEmpty ? null : _fuel,
                          sort: _sort,
                        ),
                      );
                    },
                    child: const SizedBox(
                        width: double.infinity,
                        child: Center(child: Text('Uygula'))),
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
