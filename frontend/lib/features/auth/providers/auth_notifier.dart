import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/api_client.dart';

part 'auth_notifier.g.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthState {
  final AuthStatus status;
  final String? errorMessage;
  final String? userRole;

  const AuthState({required this.status, this.errorMessage, this.userRole});

  factory AuthState.initial() => const AuthState(status: AuthStatus.initial);
  factory AuthState.loading() => const AuthState(status: AuthStatus.loading);
  factory AuthState.authenticated({String? role}) =>
      AuthState(status: AuthStatus.authenticated, userRole: role);
  factory AuthState.unauthenticated() =>
      const AuthState(status: AuthStatus.unauthenticated);
  factory AuthState.error(String message) =>
      AuthState(status: AuthStatus.error, errorMessage: message);
}

@riverpod
class AuthNotifier extends _$AuthNotifier {
  @override
  AuthState build() {
    _loadToken();
    return AuthState.initial();
  }

  Future<void> _loadToken() async {
    final client = ref.read(apiClientProvider);
    await client.loadStoredToken();
    if (client.dio.options.headers.containsKey('Authorization')) {
      state = AuthState.authenticated();
    } else {
      state = AuthState.unauthenticated();
    }
  }

  Future<void> login({
    required String email,
    required String password,
    required String tenantCode,
  }) async {
    state = AuthState.loading();
    try {
      final client = ref.read(apiClientProvider);
      // Set tenant code header
      client.dio.options.headers['X-Tenant-Code'] = tenantCode;

      final response = await client.dio.post(
        '/api/v1/auth/login',
        data: {'email': email, 'password': password},
      );

      final token = response.data['data']['token'] as String;
      final rolesList = response.data['data']['roles'] as List?;
      final role = (rolesList != null && rolesList.isNotEmpty)
          ? rolesList.first as String?
          : null;
      await client.storeToken(token);
      state = AuthState.authenticated(role: role);
    } catch (e) {
      state = AuthState.error(_parseError(e));
    }
  }

  Future<void> logout() async {
    try {
      final client = ref.read(apiClientProvider);
      await client.dio.post('/api/v1/auth/logout');
    } catch (_) {
      // Ignore logout errors
    }
    final client = ref.read(apiClientProvider);
    await client.removeToken();
    state = AuthState.unauthenticated();
  }

  String _parseError(Object error) {
    if (error is Exception) {
      return error.toString().replaceFirst('Exception: ', '');
    }
    return 'An unexpected error occurred';
  }
}
