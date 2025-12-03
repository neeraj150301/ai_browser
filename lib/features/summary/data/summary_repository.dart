import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import '../../../core/storage/hive_init.dart';
import '../domain/entities/summary.dart';

const _uuid = Uuid();

class SummaryRepository {
  final Box _box;

  SummaryRepository(this._box);

  static SummaryRepository create() {
    final box = Hive.box(HiveBoxes.summaries);
    return SummaryRepository(box);
  }

  String _key(String sourceId, String hash) => '${sourceId}_$hash';

  Future<Summary?> getCached(String sourceId, String textHash) async {
    final key = _key(sourceId, textHash);
    final data = _box.get(key);
    if (data == null) return null;
    return Summary.fromMap(data as Map);
  }

  Future<void> _cache(Summary summary) async {
    final key = _key(summary.sourceId, summary.originalTextHash);
    await _box.put(key, summary.toMap());
  }

  Future<Summary> summarizeText({
    required String sourceId,
    required String sourceType,
    required String text,
  }) async {
    final hash = text.hashCode.toString();

    final cached = await getCached(sourceId, hash);
    if (cached != null) return cached;

    final words = text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    final originalCount = words.length;
    final int summaryLen = (originalCount * 0.3).clamp(10, 200).toInt();
    final summaryWords = words.take(summaryLen).toList();
    final summaryText = summaryWords.join(' ');

    final summary = Summary(
      id: _uuid.v4(),
      sourceId: sourceId,
      sourceType: sourceType,
      originalTextHash: hash,
      summaryText: summaryText,
      originalWordCount: originalCount,
      summaryWordCount: summaryWords.length,
      translations: {},
    );

    await _cache(summary);
    return summary;
  }

  Future<Summary> translate({
    required Summary summary,
    required String languageCode,
  }) async {
    if (summary.translations.containsKey(languageCode)) {
      return summary;
    }

    final translated =
        '[${languageCode.toUpperCase()} TRANSLATION]\n${summary.summaryText}';

    final updated = Summary(
      id: summary.id,
      sourceId: summary.sourceId,
      sourceType: summary.sourceType,
      originalTextHash: summary.originalTextHash,
      summaryText: summary.summaryText,
      originalWordCount: summary.originalWordCount,
      summaryWordCount: summary.summaryWordCount,
      translations: {
        ...summary.translations,
        languageCode: translated,
      },
    );

    await _cache(updated);
    return updated;
  }
}
