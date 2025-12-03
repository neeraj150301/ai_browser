import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../../../../core/storage/hive_init.dart';
import '../../../browser/domain/entities/page_cache.dart';
import '../../../browser/presentation/providers/page_cache_provider.dart';
import '../../../summary/domain/entities/summary.dart';

final pageHistoryProvider = StreamProvider<List<PageCache>>((ref) async* {
  final service = ref.read(pageCacheServiceProvider);

  List<PageCache> readAll() => service
      .getAllPages()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

  final box = Hive.box(HiveBoxes.pageCache);

  yield readAll();

  await for (final _ in box.watch()) {
    yield readAll();
  }
});

final summaryHistoryProvider = StreamProvider<List<Summary>>((ref) async* {
  final box = Hive.box(HiveBoxes.summaries);

  List<Summary> readAll() {
    return box.values
        .where((e) => e is Map)
        .map((e) => Summary.fromMap(e as Map))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  yield readAll();

  await for (final _ in box.watch()) {
    yield readAll();
  }
});
