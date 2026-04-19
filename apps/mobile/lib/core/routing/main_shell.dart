import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_colors.dart';
import '../../shared/widgets/app_chrome.dart';

class MainShell extends ConsumerWidget {
  const MainShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void goBranch(int index) {
      navigationShell.goBranch(index, initialLocation: index == navigationShell.currentIndex);
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: navigationShell,
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
          child: AppGlass(
            radius: 24,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
            child: Row(
              children: [
                _TabItem(
                  label: 'Ilanlar',
                  icon: CupertinoIcons.car_detailed,
                  active: navigationShell.currentIndex == 0,
                  onTap: () => goBranch(0),
                ),
                _TabItem(
                  label: 'Mesajlar',
                  icon: CupertinoIcons.chat_bubble_2,
                  active: navigationShell.currentIndex == 1,
                  onTap: () => goBranch(1),
                ),
                _TabItem(
                  label: 'Randevu',
                  icon: CupertinoIcons.calendar,
                  active: navigationShell.currentIndex == 2,
                  onTap: () => goBranch(2),
                ),
                _TabItem(
                  label: 'Profil',
                  icon: CupertinoIcons.person,
                  active: navigationShell.currentIndex == 3,
                  onTap: () => goBranch(3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem({required this.label, required this.icon, required this.active, required this.onTap});

  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: CupertinoButton(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        onPressed: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
          decoration: BoxDecoration(
            color: active ? AppColors.primary.withValues(alpha: 0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: active ? AppColors.primary.withValues(alpha: 0.20) : Colors.transparent,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              active
                  ? AppHeroBadgeIcon(icon: icon, size: 30, primary: AppColors.primary, secondary: AppColors.secondary)
                  : Icon(icon, size: 20, color: AppColors.textSecondary),
              const SizedBox(height: 5),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: active ? AppColors.primaryDeep : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
