import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_colors.dart';

class MainShell extends ConsumerWidget {
  const MainShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void goBranch(int index) {
      navigationShell.goBranch(index,
          initialLocation: index == navigationShell.currentIndex);
    }

    final location = GoRouterState.of(context).uri.path;
    final isDetail = RegExp(r'^/app/listings/\d+').hasMatch(location);
    final isEditor = location == '/app/listings/new';
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: isDetail || isEditor
          ? null
          : DecoratedBox(
              decoration: const BoxDecoration(
                  color: AppColors.background,
                  border: Border(top: BorderSide(color: AppColors.separator))),
              child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(children: [
                      _TabItem(
                          label: 'Ana Sayfa',
                          icon: CupertinoIcons.house,
                          active: navigationShell.currentIndex == 4,
                          onTap: () => goBranch(4)),
                      _TabItem(
                          label: 'Ara',
                          icon: CupertinoIcons.search,
                          active: navigationShell.currentIndex == 0,
                          onTap: () => goBranch(0)),
                      _TabItem(
                          label: 'İlan Ver',
                          icon: CupertinoIcons.add_circled,
                          active: false,
                          onTap: () => context.push('/app/listings/new')),
                      _TabItem(
                          label: 'Mesajlar',
                          icon: CupertinoIcons.chat_bubble_2,
                          active: navigationShell.currentIndex == 1,
                          onTap: () => goBranch(1)),
                      _TabItem(
                          label: 'Profil',
                          icon: CupertinoIcons.person,
                          active: navigationShell.currentIndex == 3,
                          onTap: () => goBranch(3)),
                    ]),
                  )),
            ),
    );
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem(
      {required this.label,
      required this.icon,
      required this.active,
      required this.onTap});

  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Semantics(
          selected: active,
          button: true,
          child: CupertinoButton(
            padding: const EdgeInsets.symmetric(vertical: 6),
            onPressed: onTap,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(icon,
                  size: 25,
                  color: active ? AppColors.success : AppColors.textSecondary),
              const SizedBox(height: 5),
              Text(label,
                  maxLines: 1,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                      color: active
                          ? AppColors.success
                          : AppColors.textSecondary)),
            ]),
          )),
    );
  }
}
