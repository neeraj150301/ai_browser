import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:path/path.dart' as p;
import '../../../files/domain/entities/downloaded_file.dart';
import '../../../../core/storage/hive_init.dart';


const _uuid = Uuid();

class FileNotifier extends StateNotifier<List<DownloadedFile>> {
  FileNotifier() : super([]) {
    _loadFiles();
  }

  Box get _box => Hive.box(HiveBoxes.downloadedFiles);

  Future<void> _loadFiles() async {
    final files = _box.values
        .where((e) => e is Map)
        .map((e) => DownloadedFile.fromMap(e as Map))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    state = files;
  }

  Future<void> addFileFromPath(String sourcePath, String name) async {
    final file = File(sourcePath);
    if (!await file.exists()) return;

    final appDir = await getApplicationDocumentsDirectory();
    final extension = p.extension(name).replaceFirst('.', '');
    final newPath = p.join(appDir.path, name);

    // Copy file into app directory
    final copied = await file.copy(newPath);
    final size = await copied.length();

    final downloaded = DownloadedFile(
      id: _uuid.v4(),
      name: name,
      path: copied.path,
      extension: extension,
      sizeBytes: size,
      createdAt: DateTime.now(),
    );

    await _box.put(downloaded.id, downloaded.toMap());
    await _loadFiles();
  }

  Future<void> addExistingFile(String path, {String? name}) async {
    final file = File(path);
    if (!await file.exists()) return;

    final size = await file.length();
    final fileName = name ?? p.basename(path);
    final extension = p.extension(fileName).replaceFirst('.', '');

    final downloaded = DownloadedFile(
      id: _uuid.v4(),
      name: fileName,
      path: path,
      extension: extension,
      sizeBytes: size,
      createdAt: DateTime.now(),
    );

    await _box.put(downloaded.id, downloaded.toMap());
    await _loadFiles();
  }

  Future<void> removeFile(String id) async {
    final file = state.firstWhere((f) => f.id == id, orElse: () => throw Exception('Not found'));
    final fsFile = File(file.path);
    if (await fsFile.exists()) {
      await fsFile.delete();
    }
    await _box.delete(id);
    await _loadFiles();
  }
}

final fileProvider =
    StateNotifierProvider<FileNotifier, List<DownloadedFile>>((ref) {
  return FileNotifier();
});
