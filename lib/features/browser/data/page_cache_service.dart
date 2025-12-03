import 'package:hive/hive.dart';
import '../../../core/storage/hive_init.dart';
import '../domain/entities/page_cache.dart';

class PageCacheService {
  final Box _box;

  PageCacheService(this._box);

  static PageCacheService create() {
    final box = Hive.box(HiveBoxes.pageCache);
    return PageCacheService(box);
  }

  String _normalize(String url) {
    final uri = Uri.parse(url);
    final normalized = uri.normalizePath();
    final noFragment = normalized.replace(fragment: '');
    return noFragment.toString().replaceAll(RegExp(r'/$'), '');
  }

  String _key(String url) => _normalize(url.hashCode.toString());
  Future<void> savePage({
    required String url,
    required String html,
    String? title,
  }) async {
    final cache = PageCache(
      url: url,
      html: html,
      title: title,
      updatedAt: DateTime.now(),
    );
    await _box.put(_key(url), cache.toMap());
  }

  PageCache? getPage(String url) {
    final data = _box.get(_key(url));
    if (data == null) return null;
    return PageCache.fromMap(data as Map);
  }

  List<PageCache> getAllPages() {
    return _box.values
        .where((e) => e is Map)
        .map((e) => PageCache.fromMap(e as Map))
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }
}
