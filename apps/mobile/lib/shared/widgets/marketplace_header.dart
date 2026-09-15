import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/l10n/strings.dart';

class MarketplaceHeader extends StatelessWidget implements PreferredSizeWidget {
  const MarketplaceHeader({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) => AppBar(
        toolbarHeight: 64,
        leading: PopupMenuButton<String>(
          tooltip: 'Menü',
          icon: const Icon(Icons.menu_rounded),
          onSelected: (route) => context.push(route),
          itemBuilder: (_) => const [
            PopupMenuItem(
                value: '/app/listings/mine', child: Text('İlanlarım')),
            PopupMenuItem(
                value: '/app/listings/favorites', child: Text('Favorilerim')),
            PopupMenuItem(
                value: '/app/appointments', child: Text('Randevularım')),
          ],
        ),
        title: const Text(S.appName,
            style: TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.7)),
        actions: [
          IconButton(
              tooltip: 'Profil',
              onPressed: () => context.go('/app/profile'),
              icon: const Icon(Icons.account_circle_outlined))
        ],
        bottom: const PreferredSize(
            preferredSize: Size.fromHeight(1), child: Divider(height: 1)),
      );
}

class MarketplaceSearch extends StatefulWidget {
  const MarketplaceSearch(
      {super.key, this.value = '', required this.onSearch, this.hero = false});
  final String value;
  final ValueChanged<String> onSearch;
  final bool hero;

  @override
  State<MarketplaceSearch> createState() => _MarketplaceSearchState();
}

class _MarketplaceSearchState extends State<MarketplaceSearch> {
  late final _controller = TextEditingController(text: widget.value);

  @override
  void didUpdateWidget(covariant MarketplaceSearch oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value && widget.value != _controller.text) {
      _controller.text = widget.value;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    widget.onSearch(_controller.text.trim());
  }

  @override
  Widget build(BuildContext context) => Container(
        padding: EdgeInsets.all(widget.hero ? 12 : 8),
        decoration: BoxDecoration(
            color: AppColors.surfaceMuted,
            borderRadius: BorderRadius.circular(widget.hero ? 16 : 12),
            border: Border.all(color: AppColors.separator)),
        child: Row(children: [
          const SizedBox(width: 4),
          const Icon(Icons.search_rounded,
              size: 22, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Expanded(
              child: TextField(
            controller: _controller,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _submit(),
            decoration: const InputDecoration(
                hintText: 'Marka, model veya ilan ara',
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 12),
                isDense: true),
          )),
          const SizedBox(width: 8),
          IconButton.filled(
            tooltip: 'İlan ara',
            onPressed: _submit,
            style: IconButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                fixedSize: const Size(48, 48),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8))),
            icon: const Icon(Icons.arrow_forward_rounded),
          ),
        ]),
      );
}
