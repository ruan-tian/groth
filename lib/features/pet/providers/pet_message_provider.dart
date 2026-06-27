import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/providers/database_provider.dart';
import '../repositories/pet_message_repository.dart';

/// 宠物消息仓库 Provider
final petMessageRepositoryProvider = Provider<PetMessageRepository>((ref) {
  return PetMessageRepository(ref.watch(databaseProvider));
});
