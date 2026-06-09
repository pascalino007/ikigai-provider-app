import 'dart:convert';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:ikigai_provider_app/data/dio/app_dio.dart';
import 'package:ikigai_provider_app/domain/entities/auth_user.dart';
import 'package:ikigai_provider_app/domain/repositories/auth_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required FlutterSecureStorage secureStorage,
    required SharedPreferences prefs,
  })  : _secureStorage = secureStorage,
        _prefs = prefs {
    _dio = AppDio(tokenProvider: () => _accessToken).create();
  }

  final FlutterSecureStorage _secureStorage;
  final SharedPreferences _prefs;
  late final Dio _dio;

  static const _kToken = 'ikigai_provider_token';
  static const _kUser = 'ikigai_provider_user';
  static const _kShop = 'ikigai_provider_shop_id';
  static const _kLastLogin = 'ikigai_provider_last_login';

  String? _accessToken;
  AuthUser? _user;
  int? _shopId;
  String? _pendingOtp;
  DateTime? _lastLoginAt;

  @override
  String? get storedToken => _accessToken;

  @override
  AuthUser? get storedUser => _user;

  @override
  int? get storedShopId => _shopId;

  @override
  DateTime? get lastLoginAt => _lastLoginAt;

  @override
  bool get isSessionRecent {
    if (_lastLoginAt == null) return false;
    return DateTime.now().difference(_lastLoginAt!).inMinutes < 5;
  }

  @override
  String? get pendingOtpDebug => kDebugMode ? _pendingOtp : null;

  @override
  Future<void> restoreSession() async {
    _accessToken = await _secureStorage.read(key: _kToken);
    final rawUser = _prefs.getString(_kUser);
    _shopId = _prefs.getInt(_kShop);
    final lastLoginStr = _prefs.getString(_kLastLogin);
    if (lastLoginStr != null) {
      _lastLoginAt = DateTime.tryParse(lastLoginStr);
    }
    if (rawUser != null) {
      _user = AuthUser.fromJson(jsonDecode(rawUser) as Map<String, dynamic>, shopId: _shopId);
    }
  }

  @override
  Future<void> persistSession({
    required String token,
    required AuthUser user,
    int? shopId,
  }) async {
    _accessToken = token;
    _user = shopId != null ? user.copyWith(shopId: shopId) : user;
    _shopId = shopId ?? user.shopId;
    _lastLoginAt = DateTime.now();
    await _secureStorage.write(key: _kToken, value: token);
    await _prefs.setString(_kUser, jsonEncode(_user!.toJson()));
    await _prefs.setString(_kLastLogin, _lastLoginAt!.toIso8601String());
    if (_shopId != null) {
      await _prefs.setInt(_kShop, _shopId!);
    }
  }

  @override
  Future<void> clearSession() async {
    _accessToken = null;
    _user = null;
    _shopId = null;
    _lastLoginAt = null;
    await _secureStorage.delete(key: _kToken);
    await _prefs.remove(_kUser);
    await _prefs.remove(_kLastLogin);
  }

  @override
  Future<void> setShopId(int shopId) async {
    _shopId = shopId;
    if (_user != null) {
      _user = _user!.copyWith(shopId: shopId);
      await _prefs.setString(_kUser, jsonEncode(_user!.toJson()));
    }
    await _prefs.setInt(_kShop, shopId);
  }

  Map<String, dynamic> _readSigninMap(Response response) {
    final data = response.data;
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    throw StateError('Unexpected sign-in payload');
  }

  @override
  Future<AuthResult> signIn({required String email, required String password}) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/auth/signin',
      data: {'email': email, 'password': password},
    );
    final map = _readSigninMap(res);
    final token = '${map['accessToken'] ?? map['access_token'] ?? map['token'] ?? ''}';
    final userMap = map['user'];
    if (token.isEmpty || userMap is! Map) {
      throw DioException(requestOptions: res.requestOptions, message: 'Invalid sign-in response');
    }
    final storedShopId = _prefs.getInt(_kShop);
    final shopMap = map['shop'];
    final shopIdFromResponse = shopMap is Map
        ? (shopMap['id'] is int ? shopMap['id'] as int : int.tryParse('${shopMap['id']}'))
        : null;
    final user = AuthUser.fromJson(
      Map<String, dynamic>.from(userMap),
      shopId: shopIdFromResponse ?? storedShopId,
    );
    return AuthResult(accessToken: token, user: user);
  }

  @override
  Future<AuthResult> signUp({
    required String firstname,
    required String lastname,
    required String phone,
    required String email,
    required String password,
    String role = 'provider',
    String image = '',
  }) async {
    final res = await _dio.post<dynamic>(
      '/auth/signup',
      data: {
        'firstname': firstname,
        'lastname': lastname,
        'phone': phone,
        'email': email,
        'password': password,
        'role': role,
        'image': image,
      },
    );
    final data = res.data;
    if (data is! Map) {
      throw DioException(requestOptions: res.requestOptions, message: 'Invalid signup response');
    }
    // Obtain JWT via sign-in (signup typically returns user payload only).
    return signIn(email: email, password: password);
  }

  @override
  Future<List<AuthUser>> listUsers() async {
    final res = await _dio.get<List<dynamic>>('/auth');
    final list = res.data ?? [];
    return list
        .map((e) => AuthUser.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  @override
  Future<void> resetPasswordByEmail({
    required String email,
    required String newPassword,
  }) async {
    final users = await listUsers();
    final match = users.where((u) => u.email.toLowerCase() == email.toLowerCase()).toList();
    if (match.isEmpty) {
      throw DioException(requestOptions: RequestOptions(path: '/auth'), message: 'Email not found');
    }
    final id = match.first.id;
    await _dio.post<dynamic>('/auth/reset-password/$id', data: {'newPassword': newPassword});
  }

  @override
  Future<void> changePassword(String currentPassword, String newPassword) async {
    final userId = _user?.id;
    if (userId == null) throw StateError('Not authenticated');
    await _dio.post<dynamic>('/auth/$userId/change-password', data: {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
    });
  }

  @override
  void startOtpVerification() {
    _pendingOtp = (100000 + Random().nextInt(900000)).toString();
  }

  @override
  bool verifyOtp(String code) {
    if (_pendingOtp == null) return false;
    final ok = code == _pendingOtp;
    if (ok) _pendingOtp = null;
    return ok;
  }
}
