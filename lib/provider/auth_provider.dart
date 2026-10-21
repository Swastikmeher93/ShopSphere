import 'dart:convert';

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
  static const _userKey = 'auth_user';

  @override
  AuthState build() => const AuthState(isRestoringSession: true);

  Future<void> restoreSession() async {
    try {
      final storage = ref.read(secureStorageProvider);
      final accessToken = await storage.read(key: _accessTokenKey);
      final refreshToken = await storage.read(key: _refreshTokenKey);
      if (accessToken != null && accessToken.isNotEmpty) {
        AuthUser? user = _readSavedUser(await storage.read(key: _userKey));
        try {
          final response = await ref.read(apiServicesProvider).get(
                '/auth/me',
                headers: {'Authorization': 'Bearer $accessToken'},
              );
          if (response is Map<String, dynamic> &&
              response['id'] is int &&
              response['username'] is String) {
            user = AuthUser.fromJson(response);
          }
        } catch (_) {
          // Keep the saved session usable if profile lookup is temporarily down.
        }
        final restoredAccessToken = await storage.read(key: _accessTokenKey);
        if (restoredAccessToken == null || restoredAccessToken.isEmpty) {
          state = const AuthState();
          return;
        }
        state = AuthState(
          accessToken: restoredAccessToken,
          refreshToken: await storage.read(key: _refreshTokenKey) ?? refreshToken,
          user: user,
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

      AuthUser? user = response['id'] is int && response['username'] is String
          ? AuthUser.fromJson(response)
          : null;
      if (user != null) {
        try {
          final profileResponse = await ref.read(apiServicesProvider).get(
                '/auth/me',
                headers: {'Authorization': 'Bearer $accessToken'},
              );
          if (profileResponse is Map<String, dynamic> &&
              profileResponse['id'] is int &&
              profileResponse['username'] is String) {
            user = AuthUser.fromJson(profileResponse);
          }
        } catch (_) {
          // Keep the basic login profile if the full profile request fails.
        }
      }
      final activeAccessToken = await storage.read(key: _accessTokenKey);
      if (activeAccessToken == null || activeAccessToken.isEmpty) {
        state = const AuthState(error: 'Your sign-in session expired. Please sign in again.');
        return;
      }
      if (user != null) {
        await storage.write(
          key: _userKey,
          value: jsonEncode(user.toJson()),
        );
      }
      state = AuthState(
        accessToken: activeAccessToken,
        refreshToken: await storage.read(key: _refreshTokenKey) ?? refreshToken,
        user: user,
      );
    } on ApiException catch (error) {
      state = AuthState(error: error.message);
    } catch (_) {
      state = AuthState(error: 'Unable to sign in. Please try again.');
    }
  }

  Future<String?> refreshAccessToken() async {
    final storage = ref.read(secureStorageProvider);
    final refreshToken =
        state.refreshToken ?? await storage.read(key: _refreshTokenKey);
    if (refreshToken == null || refreshToken.isEmpty) return null;

    final response = await ref.read(apiServicesProvider).post(
      '/auth/refresh',
      body: {'refreshToken': refreshToken, 'expiresInMins': 30},
    );
    if (response is! Map<String, dynamic>) return null;

    final accessToken = response['accessToken'] as String?;
    if (accessToken == null || accessToken.isEmpty) return null;
    final nextRefreshToken = response['refreshToken'] as String? ?? refreshToken;

    await storage.write(key: _accessTokenKey, value: accessToken);
    await storage.write(key: _refreshTokenKey, value: nextRefreshToken);
    final currentState = state;
    state = AuthState(
      isLoading: currentState.isLoading,
      isRestoringSession: currentState.isRestoringSession,
      accessToken: accessToken,
      refreshToken: nextRefreshToken,
      user: currentState.user,
    );
    return accessToken;
  }

  Future<void> signOut() async {
    final storage = ref.read(secureStorageProvider);
    await storage.delete(key: _accessTokenKey);
    await storage.delete(key: _refreshTokenKey);
    await storage.delete(key: _userKey);
    state = const AuthState();
  }
}

AuthUser? _readSavedUser(String? json) {
  if (json == null) return null;
  try {
    final value = jsonDecode(json);
    return value is Map<String, dynamic> &&
            value['id'] is int &&
            value['username'] is String
        ? AuthUser.fromJson(value)
        : null;
  } catch (_) {
    return null;
  }
}
