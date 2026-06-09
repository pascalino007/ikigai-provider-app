import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ikigai_provider_app/domain/entities/auth_user.dart';
import 'package:ikigai_provider_app/domain/repositories/auth_repository.dart';

part 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit(this._authRepository) : super(const AuthInitial());

  final AuthRepository _authRepository;

  AuthRepository get authRepository => _authRepository;

  Future<void> init() async {
    emit(const AuthLoading());
    await _authRepository.restoreSession();
    final token = _authRepository.storedToken;
    final user = _authRepository.storedUser;
    if (token != null && user != null) {
      emit(AuthAuthenticated(user: user, token: token));
    } else {
      emit(const AuthUnauthenticated());
    }
  }

  Future<void> login({required String email, required String password}) async {
    emit(const AuthLoading());
    try {
      final result = await _authRepository.signIn(email: email, password: password);
      await _authRepository.persistSession(token: result.accessToken, user: result.user);
      emit(AuthAuthenticated(user: result.user, token: result.accessToken));
    } catch (e, st) {
      print('❌ Login Error: $e');
      print('Stack trace: $st');
      emit(AuthFailure(_humanMessage(e)));
    }
  }

  Future<void> register({
    required String firstname,
    required String lastname,
    required String phone,
    required String email,
    required String password,
  }) async {
    emit(const AuthLoading());
    try {
      final result = await _authRepository.signUp(
        firstname: firstname,
        lastname: lastname,
        phone: phone,
        email: email,
        password: password,
        role: 'provider',
      );
      _authRepository.startOtpVerification();
      await _authRepository.persistSession(token: result.accessToken, user: result.user);
      emit(AuthAuthenticated(user: result.user, token: result.accessToken));
    } catch (e, st) {
      print('❌ Register Error: $e');
      print('Stack trace: $st');
      emit(AuthFailure(_humanMessage(e)));
    }
  }

  Future<void> refreshFromStorage() async {
    await _authRepository.restoreSession();
    final token = _authRepository.storedToken;
    final user = _authRepository.storedUser;
    if (token != null && user != null) {
      emit(AuthAuthenticated(user: user, token: token));
    }
  }

  Future<void> logout() async {
    await _authRepository.clearSession();
    emit(const AuthUnauthenticated());
  }

  Future<void> attachShop(int shopId) async {
    await _authRepository.setShopId(shopId);
    await refreshFromStorage();
  }

  String _humanMessage(Object e) {
    final s = e.toString();
    if (s.contains('SocketException') || s.contains('Connection refused')) {
      return 'Cannot reach the server. Check API_BASE_URL / device network.';
    }
    return s.replaceAll('Exception: ', '').replaceAll('DioException [', 'HTTP ');
  }
}
