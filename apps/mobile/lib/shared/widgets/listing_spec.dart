import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';

String listingNumber(num value) =>
    NumberFormat.decimalPattern('tr_TR').format(value);
String carLabel(String value) =>
    const {
      'Automatic': 'Otomatik',
      'Manual': 'Manuel',
      'Gasoline': 'Benzin',
      'Diesel': 'Dizel',
      'Hybrid': 'Hibrit',
      'Electric': 'Elektrik',
      'Black': 'Siyah',
      'White': 'Beyaz'
    }[value] ??
    value;

class ListingSpec extends StatelessWidget {
  const ListingSpec({super.key, required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: AppColors.surfaceMuted,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.separator)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 11, color: AppColors.textSecondary)),
          const SizedBox(height: 4),
          Text(value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary)),
        ]),
      );
}
