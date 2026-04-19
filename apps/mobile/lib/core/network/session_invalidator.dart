import 'package:flutter_riverpod/flutter_riverpod.dart';

class SessionInvalidator extends StateNotifier<int> {
  SessionInvalidator() : super(0);

  void invalidate() {
    state = state + 1;
  }
}

final sessionInvalidatorProvider = StateNotifierProvider<SessionInvalidator, int>((ref) {
  return SessionInvalidator();
});
