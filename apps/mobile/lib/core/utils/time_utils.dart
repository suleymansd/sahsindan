String timeAgo(DateTime? input) {
  if (input == null) return '';
  final dt = input.toLocal();
  final now = DateTime.now();
  final diff = now.difference(dt);

  if (diff.inSeconds < 60) return 'Az once';
  if (diff.inMinutes < 60) return '${diff.inMinutes} dk';
  if (diff.inHours < 24) return '${diff.inHours} sa';
  if (diff.inDays < 7) return '${diff.inDays} gun';

  final weeks = (diff.inDays / 7).floor();
  if (weeks < 4) return '$weeks hf';

  final months = (diff.inDays / 30).floor();
  if (months < 12) return '$months ay';

  final years = (diff.inDays / 365).floor();
  return '$years yil';
}
