import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:hive/hive.dart';
import '../../domain/entities/browser_tab.dart';
import '../../../../core/storage/hive_init.dart';

const _uuid = Uuid();

class TabManager extends StateNotifier<List<BrowserTab>> {
  final Box _box;
  TabManager(this._box) : super(const []) {
    _loadTabsFromStorage();
  }
  BrowserTab? get activeTab {
    if (state.isEmpty) return null;
    final active = state.where((t) => t.isActive).toList();
    if (active.isNotEmpty) return active.first;
    return state.first;
  }

  void _loadTabsFromStorage() {
    if (_box.isEmpty) {
      final initialTab = BrowserTab(
        id: _uuid.v4(),
        url: 'https://flutter.dev',
        title: 'Flutter',
        isActive: true,
      );
      state = [initialTab];
      _persistTabs();
      return;
    }

    final tabs = _box.values
        .where((e) => e is Map)
        .map((e) => BrowserTab.fromMap(e as Map))
        .toList();

    if (tabs.isNotEmpty && !tabs.any((t) => t.isActive)) {
      final first = tabs.first;
      final fixed = [
        first.copyWith(isActive: true),
        ...tabs.skip(1).map((t) => t.copyWith(isActive: false)),
      ];
      state = fixed;
      _persistTabs();
    } else {
      state = tabs;
    }
  }

  Future<void> _persistTabs() async {
    await _box.clear();
    for (final tab in state) {
      await _box.put(tab.id, tab.toMap());
    }
  }
  Future<void> _updateState(List<BrowserTab> tabs) async {
    state = tabs;
    await _persistTabs();
  }


Future<void> openNewTab(String url, {String? title}) async {
    final newTab = BrowserTab(
      id: _uuid.v4(),
      url: url,
      title: title,
      isActive: true,
    );

    final updated = state
        .map((t) => t.copyWith(isActive: false))
        .toList()
      ..add(newTab);

    await _updateState(updated);
  }
   Future<void> closeTab(String id) async {
    if (state.length == 1) return;

    final isClosingActive =
        state.firstWhere((t) => t.id == id).isActive;

    var updated = [...state]..removeWhere((t) => t.id == id);

    if (isClosingActive && updated.isNotEmpty) {
      final last = updated.last;
      updated = updated
          .map((t) =>
              t.id == last.id ? t.copyWith(isActive: true) : t.copyWith(isActive: false))
          .toList();
    }

    await _updateState(updated);
  }

  Future<void> setActiveTab(String id) async {
    final updated = state
        .map((t) => t.copyWith(isActive: t.id == id))
        .toList();
    await _updateState(updated);
  }

  Future<void> updateUrl(String id, String url) async {
    final updated = state
        .map((t) =>
            t.id == id ? t.copyWith(url: url, hasError: false) : t)
        .toList();
    await _updateState(updated);
  }

  Future<void> updateTitle(String id, String? title) async {
    if (title == null || title.isEmpty) return;
    final updated = state
        .map((t) => t.id == id ? t.copyWith(title: title) : t)
        .toList();
    await _updateState(updated);
  }

  Future<void> setLoading(String id, bool isLoading) async {
    final updated = state
        .map((t) => t.id == id ? t.copyWith(isLoading: isLoading) : t)
        .toList();
    await _updateState(updated);
  }

  Future<void> setError(String id, bool hasError) async {
    final updated = state
        .map((t) => t.id == id ? t.copyWith(hasError: hasError) : t)
        .toList();
    await _updateState(updated);
  }
}

final tabManagerProvider =
    StateNotifierProvider<TabManager, List<BrowserTab>>((ref) {
  final box = Hive.box(HiveBoxes.tabs);
  return TabManager(box);
});
