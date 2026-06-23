import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/providers/repository_providers.dart';
import '../services/knowledge_context_service.dart';

/// 本地知识库上下文 Provider。
final knowledgeContextServiceProvider = Provider<KnowledgeContextService>((
  ref,
) {
  return KnowledgeContextService(ref.watch(knowledgeSourceRepositoryProvider));
});
