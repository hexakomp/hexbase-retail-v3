import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'config.dart';
import 'tenant_provider.dart';

const _tokenKey = 'auth_token';

final apiClientProvider = Provider<ApiClient>((ref) {
  final tenantCode = ref.watch(tenantCodeProvider);
  return ApiClient(tenantCode: tenantCode);
});

class ApiClient {
  final Dio _dio;

  ApiClient({required String tenantCode}) : _dio = _buildDio(tenantCode);

  static Dio _buildDio(String tenantCode) {
    final dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.apiBaseUrl,
        connectTimeout: AppConfig.connectTimeout,
        receiveTimeout: AppConfig.receiveTimeout,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          if (tenantCode.isNotEmpty) 'X-Tenant-Code': tenantCode,
        },
      ),
    );

    dio.interceptors.add(AuthInterceptor(dio));
    return dio;
  }

  Dio get dio => _dio;

  void setAuthToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  void clearAuthToken() {
    _dio.options.headers.remove('Authorization');
  }

  Future<void> loadStoredToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    if (token != null) {
      setAuthToken(token);
    }
  }

  Future<void> storeToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    setAuthToken(token);
  }

  Future<void> removeToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    clearAuthToken();
  }
}

class AuthInterceptor extends Interceptor {
  final Dio dio;
  AuthInterceptor(this.dio);

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      // Token expired — clear stored token
      SharedPreferences.getInstance().then((prefs) => prefs.remove(_tokenKey));
    }
    handler.next(err);
  }
}
