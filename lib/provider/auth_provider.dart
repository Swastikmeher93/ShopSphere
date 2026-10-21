import 'package:ecommerce_app/api/api_services.dart';
import 'package:ecommerce_app/model/auth_user.dart';
import 'package:ecommerce_app/provider/service_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final secureStorageProvider = Provider<FlutterSecureStorage>(
  (ref) => const FlutterSecureStorage(),
);

final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);

class AuthState {
  const AuthState({
    this.isLoading = false,
    this.isRestoringSession = false,
    this.accessToken,
    this.refreshToken,
    this.user,
    this.error,
  });

  final bool isLoading;
  final bool isRestoringSession;
  final String? accessToken;
  final String? refreshToken;
  final AuthUser? user;
  final String? error;

  bool get isAuthenticated => accessToken?.isNotEmpty ?? false;
}

class AuthNotifier extends Notifier<AuthState> {
  static const _accessTokenKey = 'auth_access_token';
  static const _refreshTokenKey = 'auth_refresh_token';

  @override
  AuthState build() => const AuthState(isRestoringSession: true);

  Future<void> restoreSession() async {
    try {
      final storage = ref.read(secureStorageProvider);
      final accessToken = await storage.read(key: _accessTokenKey);
      final refreshToken = await storage.read(key: _refreshTokenKey);
      if (accessToken != null && accessToken.isNotEmpty) {
        state = AuthState(
          accessToken: accessToken,
          refreshToken: refreshToken,
        );
      } else {
        state = const AuthState();
      }
    } catch (_) {
      state = const AuthState(
        error: 'Could not read the saved sign-in session.',
      );
    }
  }

  Future<void> signIn({required String username, required String password}) async {
    state = AuthState(
      isLoading: true,
      accessToken: state.accessToken,
      refreshToken: state.refreshToken,
      user: state.user,
    );

    try {
      final response = await ref.read(apiServicesProvider).post(
        '/auth/login',
        body: {
          'username': username.trim(),
          'password': password,
          'expiresInMins': 30,
        },
      );
      if (response is! Map<String, dynamic>) {
        throw const FormatException('Unexpected sign-in response.');
      }

      final accessToken = response['accessToken'] as String?;
      final refreshToken = response['refreshToken'] as String?;
      if (accessToken == null || accessToken.isEmpty) {
        throw const FormatException('The sign-in response did not include a token.');
      }

      final storage = ref.read(secureStorageProvider);
      await storage.write(key: _accessTokenKey, value: accessToken);
      if (refreshToken != null) {
        await storage.write(key: _refreshTokenKey, value: refreshToken);
      }

      final user = response['id'] is int && response['username'] is String
          ? AuthUser.fromJson(response)
          : null;
      state = AuthState(
        accessToken: accessToken,
        refreshToken: refreshToken,
        user: user,
      );
    } on ApiException catch (error) {
      state = AuthState(error: error.message);
    } catch (_) {
      state = AuthState(error: 'Unable to sign in. Please try again.');
    }
  }

  Future<void> signOut() async {
    final storage = ref.read(secureStorageProvider);
    await storage.delete(key: _accessTokenKey);
    await storage.delete(key: _refreshTokenKey);
    state = const AuthState();
  }
}
