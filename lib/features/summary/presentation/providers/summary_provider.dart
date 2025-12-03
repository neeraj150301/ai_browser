import 'package:browser_lite/features/summary/domain/entities/summary.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/ai/ai_provider.dart';
import '../../../../core/storage/hive_init.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

final summaryProvider =
    StateNotifierProvider<SummaryNotifier, AsyncValue<Summary?>>((ref) {
      final ai = ref.read(aiProvider);
      final box = Hive.box(HiveBoxes.summaries);
      return SummaryNotifier(ai: ai, box: box);
    });

class SummaryNotifier extends StateNotifier<AsyncValue<Summary?>> {
  final dynamic ai;
  final Box box;
  final _uuid = const Uuid();

  SummaryNotifier({required this.ai, required this.box})
    : super(const AsyncValue.data(null));

  Future<void> clear() async {
    state = const AsyncValue.data(null);
  }

  Future<void> summarizePlainText({
    required String url,
    required String sourceType,
    required String html,
  }) async {
    state = const AsyncValue.loading();
    try {
      final text = _cleanHtml(html);
      final hash = text.hashCode.toString();
      final key = (url + hash).hashCode.toString();
      // final key = '${url}_$hash';

      if (box.containsKey(key)) {
        final cached = Summary.fromMap(box.get(key));
        state = AsyncValue.data(cached);
        return;
      }
      final summaryText = await ai.summarize(text);
      final summary = Summary(
        id: _uuid.v4(),
        sourceId: url,
        sourceType: 'web',
        originalTextHash: hash,
        summaryText: summaryText,
        originalWordCount: text.split(' ').length,
        summaryWordCount: summaryText.split(' ').length,
        translations: {},
      );
      await box.put(key, summary.toMap());
      state = AsyncValue.data(summary);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> summarizeWebPage({
    required String url,
    required String html,
  }) async {
    final text = _cleanHtml(html);
    await summarizePlainText(url: url, sourceType: 'web', html: text);
  }

  Future<void> translate(String languageCode) async {
    final current = state.value;
    if (current == null) return;

    try {
      final translatedText = await ai.translate(
        current.summaryText,
        languageCode,
      );
      final updated = Summary(
        id: current.id,
        sourceId: current.sourceId,
        sourceType: current.sourceType,
        originalTextHash: current.originalTextHash,
        summaryText: current.summaryText,
        originalWordCount: current.originalWordCount,
        summaryWordCount: current.summaryWordCount,
        translations: {...current.translations, languageCode: translatedText},
      );
      final key = (current.sourceId + current.originalTextHash).hashCode
          .toString();
      await box.put(key, updated.toMap());
      state = AsyncValue.data(updated);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  String _cleanHtml(String html) {
    return html
        .replaceAll(RegExp(r'<script[\s\S]*?<\/script>'), '')
        .replaceAll(RegExp(r'<style[\s\S]*?<\/style>'), '')
        .replaceAll(RegExp(r'<[^>]+>'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
