import 'package:ecommerce_app/api/api_services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final apiServicesProvider = Provider<ApiServices>((ref) {
  final api = ApiServices();
  ref.onDispose(api.close);
  return api;
});
