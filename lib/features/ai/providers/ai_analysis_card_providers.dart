import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/ai_analysis_card_service.dart';

/// AI 分析结果转知识卡服务 Provider。
final aiAnalysisCardServiceProvider = Provider<AiAnalysisCardService>((ref) {
  return const AiAnalysisCardService();
});
