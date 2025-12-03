import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/page_cache_service.dart';

final pageCacheServiceProvider = Provider<PageCacheService>((ref) {
  return PageCacheService.create();
});
