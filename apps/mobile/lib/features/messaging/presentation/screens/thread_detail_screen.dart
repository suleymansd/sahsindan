import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/error_mapper.dart';
import '../../../../core/errors/error_text.dart';
import '../../../../core/routing/verification_gate.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_chrome.dart';
import '../../../../shared/widgets/app_error_view.dart';
import '../../../../shared/widgets/app_loading.dart';
import '../../../auth/presentation/providers/auth_controller.dart';
import '../providers/messaging_providers.dart';

class ThreadDetailScreen extends ConsumerStatefulWidget {
  const ThreadDetailScreen({super.key, required this.threadId});

  final int threadId;

  @override
  ConsumerState<ThreadDetailScreen> createState() => _ThreadDetailScreenState();
}

class _ThreadDetailScreenState extends ConsumerState<ThreadDetailScreen> {
  final _controller = TextEditingController();
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      try {
        await ref.read(messagingRepositoryProvider).markRead(threadId: widget.threadId);
      } catch (_) {}
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    if (!VerificationGate.ensureVerified(
      context: context,
      ref: ref,
      message: 'Mesaj gondermek icin hesabini dogrulaman gerekiyor.',
    )) {
      return;
    }
    setState(() => _sending = true);
    try {
      await ref.read(messagingRepositoryProvider).sendMessage(threadId: widget.threadId, body: text);
      _controller.clear();
      ref.invalidate(threadProvider(widget.threadId));
      ref.invalidate(threadsProvider);
    } catch (e) {
      final err = ErrorMapper.fromDio(e);
      final msg = err.when(
        network: (m) => m,
        unauthorized: () => 'Oturum suresi doldu',
        forbidden: (m) => m ?? 'Erisim engellendi',
        rateLimited: (m) => 'Cok hizli mesaj attiniz. Biraz yavaslayin.',
        validation: (m, _) => m ?? 'Gecersiz mesaj',
        server: (m) => m,
        unknown: (m) => m,
      );
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncThread = ref.watch(threadProvider(widget.threadId));
    final myId = ref.watch(authControllerProvider).user?.id;

    return Scaffold(
      appBar: AppBar(title: Text('Thread #${widget.threadId}')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: asyncThread.when(
                data: (thread) {
                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: thread.messages.length,
                    itemBuilder: (context, i) {
                      final m = thread.messages[i];
                      final isMine = myId != null && m.senderId == myId;
                      return Align(
                        alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 320),
                          margin: const EdgeInsets.only(bottom: 8),
                          child: AppGlass(
                            radius: 16,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            child: Text(
                              m.body,
                              style: TextStyle(
                                color: isMine ? AppColors.primaryDeep : AppColors.textPrimary,
                                fontWeight: isMine ? FontWeight.w600 : FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
                error: (e, _) => AppErrorView(
                  title: 'Thread yuklenemedi',
                  description: friendlyErrorText(e),
                  onRetry: () => ref.invalidate(threadProvider(widget.threadId)),
                ),
                loading: () => const AppLoading(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: AppGlass(
                radius: 18,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        minLines: 1,
                        maxLines: 4,
                        decoration: const InputDecoration(hintText: 'Mesaj yaz...'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      onPressed: _sending ? null : _send,
                      icon: const Icon(Icons.send),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
