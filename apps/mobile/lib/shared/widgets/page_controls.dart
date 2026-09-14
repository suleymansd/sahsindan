import 'package:flutter/cupertino.dart';

class PageControls extends StatelessWidget {
  const PageControls({super.key, required this.offset, required this.count, required this.onChange});
  final int offset;
  final int count;
  final ValueChanged<int> onChange;

  @override
  Widget build(BuildContext context) {
    if (offset == 0 && count < 50) return const SizedBox.shrink();
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      CupertinoButton(onPressed: offset == 0 ? null : () => onChange(offset - 50), child: const Text('Önceki')),
      Text('${offset ~/ 50 + 1}'),
      CupertinoButton(onPressed: count < 50 ? null : () => onChange(offset + 50), child: const Text('Sonraki')),
    ]);
  }
}
