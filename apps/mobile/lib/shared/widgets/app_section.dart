import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import 'app_chrome.dart';

class AppSection extends StatelessWidget {
  const AppSection({
    super.key,
    required this.children,
    this.header,
    this.footer,
  });

  final String? header;
  final String? footer;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (header != null) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
            child: Text(
              header!,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppColors.textSecondary, letterSpacing: 0.1),
            ),
          ),
        ],
        AppGlass(
          padding: EdgeInsets.zero,
          radius: 20,
          child: Column(
            children: _withDividers(children),
          ),
        ),
        if (footer != null) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
            child: Text(
              footer!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
          ),
        ],
      ],
    );
  }
}

List<Widget> _withDividers(List<Widget> children) {
  final out = <Widget>[];
  for (var i = 0; i < children.length; i++) {
    out.add(children[i]);
    if (i != children.length - 1) {
      out.add(const Divider(height: 1, color: AppColors.separator));
    }
  }
  return out;
}
