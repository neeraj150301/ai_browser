import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'ai_service.dart';

final aiProvider = Provider<AiService>((ref) => AiService());
