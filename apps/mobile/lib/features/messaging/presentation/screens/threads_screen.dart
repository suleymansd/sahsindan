import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/error_text.dart';
import '../../../../core/network/providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/time_utils.dart';
import '../../../../core/utils/url_utils.dart';
import '../../../../shared/widgets/app_chrome.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import '../../../../shared/widgets/app_error_view.dart';
import '../../../../shared/widgets/app_loading.dart';
import '../../../../shared/widgets/verification_required_view.dart';
import '../providers/messaging_providers.dart';

class ThreadsScreen extends ConsumerWidget {
  const ThreadsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncThreads = ref.watch(threadsProvider);

    return CupertinoPageScaffold(
      backgroundColor: Colors.transparent,
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Mesajlar'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => ref.invalidate(threadsProvider),
          child: const Icon(CupertinoIcons.refresh, size: 22),
        ),
        border: const Border(bottom: BorderSide(color: AppColors.separator)),
        backgroundColor: AppColors.navBar,
      ),
      child: SafeArea(
        child: asyncThreads.when(
          data: (threads) {
            if (threads.isEmpty) {
              return const AppEmptyState(
                title: 'Henuz mesaj yok',
                description: 'Ilan detayindan mesaj baslattiginda burada gorunecek.',
                icon: CupertinoIcons.chat_bubble_2,
              );
            }
            return RefreshIndicator(
              onRefresh: () async => ref.invalidate(threadsProvider),
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: threads.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  final t = threads[i];
                  final lastMsg = t.messages.isNotEmpty ? t.messages.last : null;
                  final last = t.lastMessageBody ?? lastMsg?.body ?? 'Mesaj yok';
                  final when = timeAgo(lastMsg?.createdAt ?? t.lastMessageAt);
                  final other = t.otherUser?.name ?? 'Thread #${t.id}';
                  final unread = t.unreadCount ?? 0;
                  final cfg = ref.watch(appConfigProvider);
                  final photo = t.listing?.photoUrl;
                  final thumbUrl = (photo == null) ? null : resolvePublicUrl(publicBaseUrl: cfg.publicBaseUrl, maybeRelative: photo);

                  return AppGlass(
                    padding: EdgeInsets.zero,
                    radius: 18,
                    child: ListTile(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      leading: thumbUrl == null
                          ? const CircleAvatar(child: Icon(CupertinoIcons.car))
                          : ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                thumbUrl,
                                width: 52,
                                height: 52,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const CircleAvatar(child: Icon(CupertinoIcons.car)),
                              ),
                            ),
                      title: Text(other, maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text(last, maxLines: 1, overflow: TextOverflow.ellipsis),
                      trailing: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (when.isNotEmpty)
                            Text(when, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.textSecondary)),
                          if (unread > 0) ...[
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                '$unread',
                                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
                              ),
                            ),
                          ],
                          const SizedBox(height: 6),
                          const Icon(CupertinoIcons.chevron_forward, size: 18, color: AppColors.textSecondary),
                        ],
                      ),
                      onTap: () => context.go('/app/threads/${t.id}'),
                    ),
                  );
                },
              ),
            );
          },
          error: (e, _) {
            if (isForbiddenError(e)) {
              return VerificationRequiredView(
                message: 'Mesaj gondermek icin hesabini dogrulaman gerekiyor.',
                next: '/app/threads',
                onRetry: () => ref.invalidate(threadsProvider),
              );
            }
            return AppErrorView(
              title: 'Mesajlar yuklenemedi',
              description: friendlyErrorText(e),
              onRetry: () => ref.invalidate(threadsProvider),
            );
          },
          loading: () => const AppLoading(),
        ),
      ),
    );
  }
}
