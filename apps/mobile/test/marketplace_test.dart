import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:trustmarket_mobile/core/theme/app_theme.dart';
import 'package:trustmarket_mobile/features/listings/presentation/providers/comparison_provider.dart';
import 'package:trustmarket_mobile/features/listings/presentation/providers/listings_providers.dart';
import 'package:trustmarket_mobile/features/listings/presentation/screens/listings_screen.dart';
import 'package:trustmarket_mobile/features/listings/presentation/screens/listing_comparison_screen.dart';
import 'package:trustmarket_mobile/features/listings/presentation/screens/marketplace_home_screen.dart';
import 'package:trustmarket_mobile/shared/models/listing.dart';
import 'package:trustmarket_mobile/shared/widgets/marketplace_header.dart';

Listing listing(int id) => Listing(
  id: id, state: 'PUBLISHED', title: 'Araç $id', description: 'Test ilanı', price: 100000,
  city: 'ISTANBUL', district: 'Kadıköy', lastConfirmedAt: DateTime(2026),
  owner: const ListingOwner(id: 1, name: 'Satıcı', trustScore: 80, lastActiveBucket: 'today'),
  carDetails: const CarDetail(brand: 'Fiat', model: 'Egea', year: 2020, mileage: 10000, transmission: 'Automatic', fuel: 'Gasoline', color: 'White'),
);

void main() {
  test('Changing filters returns to page one while page navigation preserves filters', () {
    final query = ListingsQuery(q: 'Audi', brand: 'Audi', offset: 100);
    expect(query.copyWith(q: 'Volvo').offset, 0);
    expect(query.copyWith(offset: 150).offset, 150);
    expect(query.copyWith(offset: 150).brand, 'Audi');
  });

  test('Clearing a search preserves other filters, explicit null clears each filter', () {
    final query = ListingsQuery(q: 'Fiat', brand: 'Fiat', minPrice: 100, yearMin: 2020);
    expect(query.copyWith(q: null).q, isNull);
    expect(query.copyWith(q: null).brand, 'Fiat');
    expect(query.copyWith().q, 'Fiat');
    expect(query.copyWith(brand: null, minPrice: null, yearMin: null).brand, isNull);
    expect(query.copyWith(minPrice: null).minPrice, isNull);
    expect(query.copyWith(yearMin: null).yearMin, isNull);
  });

  test('Comparison caps at three unique listings and frees slots when removed', () {
    final controller = ComparisonController();
    addTearDown(controller.dispose);
    for (var i = 1; i <= 3; i++) { expect(controller.toggle(listing(i)), isTrue); }
    expect(controller.toggle(listing(4)), isFalse);
    expect(controller.state.length, 3);
    expect(controller.toggle(listing(2)), isTrue);
    expect(controller.state.map((item) => item.id), [1, 3]);
    expect(controller.toggle(listing(4)), isTrue);
  });

  testWidgets('Search submits trimmed text and accepts an empty search', (tester) async {
    final queries = <String>[];
    await tester.pumpWidget(MaterialApp(theme: AppTheme.light(), home: Scaffold(body: MarketplaceSearch(onSearch: queries.add))));
    await tester.enterText(find.byType(TextField), '  Fiat  ');
    await tester.tap(find.byTooltip('İlan ara'));
    await tester.pump();
    await tester.enterText(find.byType(TextField), '');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    expect(queries, ['Fiat', '']);
  });

  testWidgets('Removing the last comparison shows the recovery action on a small phone', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(comparisonProvider.notifier).toggle(listing(1));
    final router = GoRouter(routes: [GoRoute(path: '/', builder: (_, __) => const ListingComparisonScreen())]);
    addTearDown(router.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(container: container, child: MaterialApp.router(theme: AppTheme.light(), routerConfig: router)));
    await tester.pumpAndSettle();
    expect(find.text('Araç 1'), findsOneWidget);
    await tester.ensureVisible(find.text('Karşılaştırmadan çıkar'));
    await tester.tap(find.text('Karşılaştırmadan çıkar'));
    await tester.pumpAndSettle();
    expect(find.text('Karşılaştırmak için ilan seçin'), findsOneWidget);
    expect(find.text('İlanları keşfet'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Home search navigates with query; unsupported category stays on home', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final router = GoRouter(initialLocation: '/app/home', routes: [
      GoRoute(path: '/app/home', builder: (_, __) => const MarketplaceHomeScreen()),
      GoRoute(path: '/app/listings', builder: (_, __) => const Scaffold(body: Text('Sonuç sayfası'))),
    ]);
    addTearDown(router.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(container: container, child: MaterialApp.router(theme: AppTheme.light(), routerConfig: router)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Emlak'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Emlak ilanları yakında'), findsOneWidget);
    expect(router.routeInformationProvider.value.uri.path, '/app/home');
    await tester.enterText(find.byType(TextField), 'Fiat');
    await tester.tap(find.byTooltip('İlan ara'));
    await tester.pumpAndSettle();
    expect(container.read(listingsQueryProvider).q, 'Fiat');
    expect(find.text('Sonuç sayfası'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Filters remain usable with keyboard on a narrow phone and reset the query', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final container = ProviderContainer(overrides: [listingsProvider.overrideWith((ref) async => [])]);
    addTearDown(container.dispose);
    container.read(listingsQueryProvider.notifier).state = ListingsQuery(q: 'Fiat', minPrice: 500, fuel: 'Diesel');
    final router = GoRouter(routes: [GoRoute(path: '/', builder: (_, __) => const ListingsScreen())]);
    addTearDown(router.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(container: container, child: MaterialApp.router(theme: AppTheme.light(), routerConfig: router)));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull, reason: 'results screen');
    expect(find.text('Aradığınız ilan bulunamadı'), findsOneWidget);
    await tester.tap(find.text('Filtrele'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull, reason: 'filter sheet');
    await tester.tap(find.widgetWithText(TextField, 'İlçe'));
    tester.view.viewInsets = const FakeViewPadding(bottom: 280);
    addTearDown(tester.view.resetViewInsets);
    await tester.pump();
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.text('Uygula'));
    await tester.tap(find.text('Uygula'));
    tester.view.resetViewInsets();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sıfırla'));
    await tester.pumpAndSettle();
    expect(container.read(listingsQueryProvider).q, isNull);
    expect(container.read(listingsQueryProvider).minPrice, isNull);
    expect(container.read(listingsQueryProvider).fuel, isNull);
    expect(tester.takeException(), isNull);
  });
}
