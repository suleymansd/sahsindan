import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/providers.dart';
import '../../../../core/network/session_invalidator.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../../../core/errors/app_error.dart';
import '../../../../shared/models/user.dart';
import '../../../../shared/models/verification.dart';
import '../../data/auth_repository.dart';

part 'auth_controller.freezed.dart';

enum AuthStage {
  bootstrapping,
  unauthenticated,
  banned,
  authenticated,
}

@freezed
class AuthState with _$AuthState {
  const factory AuthState({
    required AuthStage stage,
    UserSummary? user,
    VerificationStatus? verification,
    AppError? lastError,
  }) = _AuthState;
}

extension AuthStateX on AuthState {
  bool get isLoggedIn => stage == AuthStage.authenticated;

  bool get isVerified {
    final u = user;
    if (u == null) return false;
    if (u.isVerified) return true; // includes admin/moderator
    final vs = verification?.status.toUpperCase().trim();
    return vs == 'APPROVED' || vs == 'VERIFIED';
  }
}

class AuthController extends StateNotifier<AuthState> {
  AuthController(this._ref)
      : super(const AuthState(stage: AuthStage.bootstrapping)) {
    // If the HTTP layer decides the session is invalid, force logout locally.
    _ref.listen<int>(sessionInvalidatorProvider, (prev, next) {
      if (prev != next) {
        setUnauthenticated();
      }
    });
  }

  final Ref _ref;

  AuthRepository get _repo => AuthRepository(
        dio: _ref.read(dioProvider),
        tokenStore: _ref.read(tokenStoreProvider),
      );

  Future<void> bootstrap() async {
    state = const AuthState(stage: AuthStage.bootstrapping);
    try {
      await _repo.refresh();
      final user = await _repo.me();
      final verification = await _loadVerificationIfNeeded(user);
      state = AuthState(stage: _stageFromUser(user), user: user, verification: verification);
    } catch (e) {
      // No valid session.
      state = const AuthState(stage: AuthStage.unauthenticated);
    }
  }

  Future<void> login(String email, String password) async {
    try {
      final user = await _repo.login(email: email, password: password);
      final verification = await _loadVerificationIfNeeded(user);
      state = AuthState(stage: _stageFromUser(user), user: user, verification: verification);
    } catch (e) {
      state = state.copyWith(lastError: ErrorMapper.fromDio(e));
      rethrow;
    }
  }

  Future<void> register({
    required String email,
    required String phone,
    required String password,
    required String name,
    required String city,
    String? professionCategory,
  }) async {
    try {
      final user = await _repo.register(
        email: email,
        phone: phone,
        password: password,
        name: name,
        city: city,
        professionCategory: professionCategory,
      );
      final verification = await _loadVerificationIfNeeded(user);
      state = AuthState(stage: _stageFromUser(user), user: user, verification: verification);
    } catch (e) {
      state = state.copyWith(lastError: ErrorMapper.fromDio(e));
      rethrow;
    }
  }

  Future<String?> forgotPassword(String email) async {
    try {
      return await _repo.forgotPassword(email: email);
    } catch (e) {
      state = state.copyWith(lastError: ErrorMapper.fromDio(e));
      rethrow;
    }
  }

  Future<void> resetPassword({required String token, required String newPassword}) async {
    try {
      await _repo.resetPassword(token: token, newPassword: newPassword);
    } catch (e) {
      state = state.copyWith(lastError: ErrorMapper.fromDio(e));
      rethrow;
    }
  }

  Future<void> refreshMe() async {
    try {
      final user = await _repo.me();
      final verification = await _loadVerificationIfNeeded(user);
      state = state.copyWith(stage: _stageFromUser(user), user: user, verification: verification);
    } catch (e) {
      // If /me fails, keep current stage.
      state = state.copyWith(lastError: ErrorMapper.fromDio(e));
    }
  }

  Future<void> refreshVerificationStatus() async {
    final user = state.user;
    if (user == null) return;
    if (user.isVerified) {
      // Still keep a fresh copy for guard logic (harmless).
      state = state.copyWith(verification: null);
      return;
    }
    try {
      final v = await _repo.verificationStatus();
      state = state.copyWith(verification: v);
    } catch (e) {
      state = state.copyWith(lastError: ErrorMapper.fromDio(e));
    }
  }

  Future<void> logout() async {
    await _repo.logout();
    state = const AuthState(stage: AuthStage.unauthenticated);
  }

  void setUnauthenticated() {
    _ref.read(tokenStoreProvider).clear();
    state = const AuthState(stage: AuthStage.unauthenticated);
  }

  AuthStage _stageFromUser(UserSummary user) {
    if (user.isBanned) return AuthStage.banned;
    return AuthStage.authenticated;
  }

  Future<VerificationStatus?> _loadVerificationIfNeeded(UserSummary user) async {
    if (user.isVerified) return null;
    try {
      return await _repo.verificationStatus();
    } catch (_) {
      return null;
    }
  }
}

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(ref);
});
