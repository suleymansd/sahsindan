import 'dart:async';

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
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    _poll = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted && WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed && (ModalRoute.of(context)?.isCurrent ?? false)) {
        ref.invalidate(threadProvider(widget.threadId));
      }
    });
    Future.microtask(() async {
      try {
        await ref.read(messagingRepositoryProvider).markRead(threadId: widget.threadId);
      } catch (_) {}
    });
  }

  @override
  void dispose() {
    _poll?.cancel();
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
      if (!mounted) return;
      _controller.clear();
      ref.read(threadBeforeProvider(widget.threadId).notifier).state = null;
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
    final beforeId = ref.watch(threadBeforeProvider(widget.threadId));
    final myId = ref.watch(authControllerProvider).user?.id;

    return Scaffold(
      appBar: AppBar(title: Text(asyncThread.valueOrNull?.otherUser?.name ?? 'Sohbet')),
      body: SafeArea(
        child: Column(
          children: [
            if (beforeId != null || (asyncThread.valueOrNull?.messages.length ?? 0) >= 100)
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                TextButton(onPressed: asyncThread.isLoading || (asyncThread.valueOrNull?.messages.isEmpty ?? true) ? null : () {
                  ref.read(threadBeforeProvider(widget.threadId).notifier).state = asyncThread.valueOrNull!.messages.first.id;
                }, child: const Text('Önceki mesajlar')),
                if (beforeId != null) TextButton(onPressed: () => ref.read(threadBeforeProvider(widget.threadId).notifier).state = null, child: const Text('Son mesajlar')),
              ]),
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
                          child: Container(
                            decoration: BoxDecoration(color: isMine ? AppColors.primary : const Color(0xFFE9ECEF), borderRadius: BorderRadius.only(topLeft: Radius.circular(isMine ? 20 : 4), topRight: Radius.circular(isMine ? 4 : 20), bottomLeft: const Radius.circular(20), bottomRight: const Radius.circular(20))),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            child: Text(
                              m.body,
                              style: TextStyle(
                                color: isMine ? Colors.white : AppColors.textPrimary,
                                fontSize: 16, height: 1.5,
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
                  title: 'Sohbet yüklenemedi',
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
                        decoration: const InputDecoration(hintText: 'Mesajınızı yazın…'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      tooltip: 'Mesaj gönder',
                      style: IconButton.styleFrom(backgroundColor: AppColors.success, foregroundColor: Colors.white, minimumSize: const Size(48, 48)),
                      onPressed: _sending ? null : _send,
                      icon: const Icon(Icons.send_outlined),
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
