import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../storage/hive_init.dart';

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  final box = Hive.box(HiveBoxes.settings);
  return ThemeNotifier(box);
});

class ThemeNotifier extends StateNotifier<ThemeMode> {
  final Box box;
  static const _key = 'theme_mode';

  ThemeNotifier(this.box) : super(_loadTheme(box));

  static ThemeMode _loadTheme(Box box) {
    final saved = box.get(_key);
    if (saved == 'dark') return ThemeMode.dark;
    if (saved == 'light') return ThemeMode.light;
    return ThemeMode.system;
  }

  void toggleTheme(bool isDark) {
    state = isDark ? ThemeMode.dark : ThemeMode.light;
    box.put(_key, isDark ? 'dark' : 'light');
  }

  void setSystem() {
    state = ThemeMode.system;
    box.delete(_key);
  }
}
