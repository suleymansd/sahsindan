import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/marketplace_header.dart';
import '../providers/listings_providers.dart';

class MarketplaceHomeScreen extends ConsumerWidget {
  const MarketplaceHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void search(String value) {
      ref.read(listingsQueryProvider.notifier).state =
          ListingsQuery(city: 'ISTANBUL', q: value.isEmpty ? null : value);
      context.go('/app/listings');
    }

    return Scaffold(
      appBar: const MarketplaceHeader(),
      body: SafeArea(
        child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ConstrainedBox(
                    constraints:
                        BoxConstraints(minHeight: constraints.maxHeight),
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 32),
                          Text.rich(
                            const TextSpan(children: [
                              TextSpan(text: 'Ne arıyorsunuz?\n'),
                              TextSpan(
                                  text: 'Aradığınız araç',
                                  style: TextStyle(color: AppColors.secondary)),
                              TextSpan(text: '\nburada sizi\nbekliyor.'),
                            ]),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: constraints.maxWidth < 370 ? 39 : 45,
                                height: 1.13,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -1.8,
                                color: AppColors.primary),
                          ),
                          const SizedBox(height: 36),
                          MarketplaceSearch(hero: true, onSearch: search),
                          const SizedBox(height: 32),
                          Wrap(
                              alignment: WrapAlignment.center,
                              spacing: 12,
                              runSpacing: 12,
                              children: [
                                _Category(
                                    icon: Icons.apartment_rounded,
                                    title: 'Emlak',
                                    onTap: () => _comingSoon(context, 'Emlak')),
                                _Category(
                                    icon: Icons.directions_car_outlined,
                                    title: 'Vasıta',
                                    onTap: () => search('')),
                                _Category(
                                    icon: Icons.devices_outlined,
                                    title: 'İkinci El',
                                    onTap: () =>
                                        _comingSoon(context, 'İkinci el')),
                              ]),
                          const SizedBox(height: 32),
                        ]),
                  ),
                )),
      ),
    );
  }

  void _comingSoon(BuildContext context, String category) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            '$category ilanları yakında. Şimdilik araç ilanlarını keşfedebilirsiniz.')));
  }
}

class _Category extends StatelessWidget {
  const _Category(
      {required this.icon, required this.title, required this.onTap});
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 20),
        label: Text(title),
        style: OutlinedButton.styleFrom(
            backgroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            textStyle:
                const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
            shape: const StadiumBorder()),
      );
}
