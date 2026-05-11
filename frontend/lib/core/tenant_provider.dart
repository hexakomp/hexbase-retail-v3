import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'config.dart';

final tenantCodeProvider = Provider<String>((ref) {
  // Tenant code comes from compile-time env var or can be overridden
  // at runtime (e.g. from URL subdomain in web context).
  return AppConfig.tenantCode;
});
