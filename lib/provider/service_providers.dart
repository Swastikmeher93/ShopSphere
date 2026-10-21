import 'package:ecommerce_app/api/api_services.dart';
import 'package:ecommerce_app/provider/auth_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final apiServicesProvider = Provider<ApiServices>((ref) {
  final api = ApiServices(
    accessTokenReader: () => ref.read(authProvider).accessToken,
    accessTokenRefresher: () =>
        ref.read(authProvider.notifier).refreshAccessToken(),
    onRefreshFailure: () => ref.read(authProvider.notifier).signOut(),
  );
  ref.onDispose(api.close);
  return api;
});
