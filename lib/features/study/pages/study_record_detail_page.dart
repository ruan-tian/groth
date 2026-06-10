import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';

import '../../../app/design/design.dart';
import '../../../core/database/app_database.dart';
import '../../../core/utils/chart_scale_utils.dart';
import '../../../shared/providers/database_provider.dart';
import '../../../shared/providers/repository_providers.dart';
import '../../../shared/providers/study_provider.dart';

part '../widgets/study_record_detail_widgets.dart';
part '../widgets/study_record_detail_chart.dart';

/// 学习记录详情页
///
/// 展示单条学习记录的完整信息，支持删除操作。
class StudyRecordDetailPage extends ConsumerWidget {
  const StudyRecordDetailPage({super.key, required this.recordId});

  final int recordId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordAsync = ref.watch(_studyRecordByIdProvider(recordId));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: recordAsync.when(
        data: (record) => _DetailBody(record: record),
        loading: () => Center(
          child: SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: AppColors.study,
            ),
          ),
        ),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.danger.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.error_outline_rounded,
                  size: 36,
                  color: AppColors.danger.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('加载失败', style: AppTextStyles.sectionTitle),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '$e',
                style: AppTextStyles.caption,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xl),
              TextButton.icon(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.arrow_back_rounded, size: 18),
                label: const Text('返回'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// 根据 ID 查询单条记录的 Provider
// =============================================================================

final _studyRecordByIdProvider = FutureProvider.family<StudyRecord, int>((
  ref,
  id,
) async {
  final db = ref.watch(appDatabaseProvider);
  final query = db.select(db.studyRecords)..where((t) => t.id.equals(id));
  return query.getSingle();
});

// =============================================================================
// 详情内容
// =============================================================================
