import 'package:google_generative_ai/google_generative_ai.dart';
import '../env/env.dart';

class AiService {
  late final GenerativeModel model;

  AiService() {
    model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: Env.apiKey,
    );
  }

  Future<String> summarize(String text) async {
    final prompt = """
You are a professional summarizer.
Summarize the following content in simple English:

$text
""";

    final response = await model.generateContent([Content.text(prompt)]);
    return response.text ?? "No summary generated.";
  }

  Future<String> translate(String text, String language) async {
    final prompt = """
Translate the following text to $language.
Only give translated output without explanation.

$text
""";

    final response = await model.generateContent([Content.text(prompt)]);
    return response.text ?? "No translation generated.";
  }

  Future<String> detectLanguage(String text) async {
    final prompt = """
Detect the language of the following text and reply ONLY with language name:

$text
""";

    final response = await model.generateContent([Content.text(prompt)]);
    return response.text ?? "Unknown";
  }
}
