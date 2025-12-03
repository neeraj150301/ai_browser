import 'package:hive_flutter/hive_flutter.dart';

class HiveBoxes {
  static const downloadedFiles = 'downloaded_files';
  static const summaries = 'summaries';
  static const tabs = 'tabs';
  static const pageCache = 'page_cache';
  static const settings = 'settings';
}

Future<void> initHive() async {
  await Hive.initFlutter();

  await Hive.openBox(HiveBoxes.downloadedFiles);
  await Hive.openBox(HiveBoxes.summaries);
  await Hive.openBox(HiveBoxes.tabs);
  await Hive.openBox(HiveBoxes.pageCache);
  await Hive.openBox(HiveBoxes.settings);
}
