import 'package:flutter_dotenv/flutter_dotenv.dart';

class Env {
  static String get apiKey => dotenv.env['GEMINI_API_KEY'] ?? '';
}
