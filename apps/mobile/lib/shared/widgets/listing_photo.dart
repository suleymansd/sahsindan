import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class ListingPhotoView extends StatelessWidget {
  const ListingPhotoView({super.key, this.url});
  final String? url;

  @override
  Widget build(BuildContext context) {
    const fallback = ColoredBox(
        color: AppColors.surfaceMuted,
        child: Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.directions_car_outlined,
              size: 52, color: AppColors.textTertiary),
          SizedBox(height: 8),
          Text('Fotoğraf bulunmuyor',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        ])));
    return url == null
        ? fallback
        : Image.network(url!,
            fit: BoxFit.cover,
            width: double.infinity,
            errorBuilder: (_, __, ___) => fallback);
  }
}
