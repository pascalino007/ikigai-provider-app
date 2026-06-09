import 'package:dio/dio.dart';
import 'package:ikigai_provider_app/core/constants/api_constants.dart';

class AppDio {
  AppDio({required this.tokenProvider});

  final String? Function() tokenProvider;

  Dio create() {
    final dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 25),
        receiveTimeout: const Duration(seconds: 25),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          // Avoid ngrok free-tier HTML interstitial on API requests
          'ngrok-skip-browser-warning': '1',
        },
      ),
    );
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final t = tokenProvider();
          if (t != null && t.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $t';
          }
          print('➡️ API REQUEST: ${options.method} ${options.path}');
          handler.next(options);
        },
        onResponse: (response, handler) {
          print('✅ API RESPONSE [${response.statusCode}]: ${response.requestOptions.path}');
          handler.next(response);
        },
        onError: (error, handler) {
          print('❌ API ERROR [${error.response?.statusCode}]: ${error.requestOptions.path}');
          print('   Error: ${error.message}');
          print('   Response: ${error.response?.data}');
          handler.next(error);
        },
      ),
    );
    return dio;
  }
}
