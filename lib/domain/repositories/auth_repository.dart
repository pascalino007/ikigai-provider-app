import 'package:ikigai_provider_app/domain/entities/auth_user.dart';

class AuthResult {
  AuthResult({required this.accessToken, required this.user});

  final String accessToken;
  final AuthUser user;
}

abstract class AuthRepository {
  Future<AuthResult> signIn({required String email, required String password});

  Future<AuthResult> signUp({
    required String firstname,
    required String lastname,
    required String phone,
    required String email,
    required String password,
    String role,
    String image,
  });

  /// Uses `GET /auth` + `POST /auth/reset-password/:id` — secure this on the server for production.
  Future<void> resetPasswordByEmail({
    required String email,
    required String newPassword,
  });

  Future<void> changePassword(String currentPassword, String newPassword);

  Future<List<AuthUser>> listUsers();

  String? get storedToken;
  AuthUser? get storedUser;
  int? get storedShopId;

  Future<void> persistSession({
    required String token,
    required AuthUser user,
    int? shopId,
  });

  Future<void> clearSession();
  Future<void> restoreSession();

  void startOtpVerification();
  bool verifyOtp(String code);
  String? get pendingOtpDebug;

  Future<void> setShopId(int shopId);

  DateTime? get lastLoginAt;
  bool get isSessionRecent;
}
