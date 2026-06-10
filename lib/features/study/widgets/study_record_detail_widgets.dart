part of '../pages/study_record_detail_page.dart';

class _DetailBody extends ConsumerWidget {
  const _DetailBody({required this.record});

  final StudyRecord record;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isProfessional = record.mode == 'professional';
    final startDt = DateTime.fromMillisecondsSinceEpoch(record.startTime);
    final endDt = DateTime.fromMillisecondsSinceEpoch(record.endTime);
    final createdDt = DateTime.fromMillisecondsSinceEpoch(record.createdAt);

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // ── 渐变 Header ──
        SliverToBoxAdapter(child: _buildHeader(context, ref)),

        // ── 正文内容 ──
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.xxxl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── 信息网格 (2x2) ──
                _buildInfoGrid(context),
                const SizedBox(height: AppSpacing.lg),

                // ── 时间信息 ──
                _buildSection(
                  icon: Icons.schedule_rounded,
                  title: '时间信息',
                  child: Column(
                    children: [
                      _InfoRow(
                        icon: Icons.play_circle_outline_rounded,
                        label: '开始',
                        value: _formatDateTime(startDt),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _InfoRow(
                        icon: Icons.stop_circle_outlined,
                        label: '结束',
                        value: _formatDateTime(endDt),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _InfoRow(
                        icon: Icons.access_time_rounded,
                        label: '时长',
                        value: '${record.durationMinutes} 分钟',
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _InfoRow(
                        icon: Icons.calendar_today_rounded,
                        label: '记录于',
                        value: _formatDateTime(createdDt),
                      ),
                    ],
                  ),
                ),

                // ── 专业模式信息 ──
                if (isProfessional) ...[
                  const SizedBox(height: AppSpacing.lg),
                  _buildProfessionalSection(context),
                ],

                // ── 收获 ──
                if (record.gain != null && record.gain!.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.lg),
                  _buildSection(
                    icon: Icons.lightbulb_outline_rounded,
                    title: '收获',
                    child: Text(
                      record.gain!,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textPrimary,
                        height: 1.6,
                      ),
                    ),
                  ),
                ],

                // ── 遗留问题 ──
                if (record.problem != null && record.problem!.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.lg),
                  _buildSection(
                    icon: Icons.help_outline_rounded,
                    title: '遗留问题',
                    child: Text(
                      record.problem!,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textPrimary,
                        height: 1.6,
                      ),
                    ),
                  ),
                ],

                // ── 备注 ──
                if (record.note != null && record.note!.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.lg),
                  _buildSection(
                    icon: Icons.notes_rounded,
                    title: '备注',
                    child: Text(
                      record.note!,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textPrimary,
                        height: 1.6,
                      ),
                    ),
                  ),
                ],

                // ── 学习趋势 ──
                const SizedBox(height: AppSpacing.xl),
                _buildSectionTitle('学习趋势'),
                const SizedBox(height: AppSpacing.md),
                _StudyTrendChart(record: record),
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 渐变 Header
  // ---------------------------------------------------------------------------

  Widget _buildHeader(BuildContext context, WidgetRef ref) {
    final isProfessional = record.mode == 'professional';

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xxl,
        56,
        AppSpacing.xxl,
        AppSpacing.xxl,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.study, AppColors.study.withValues(alpha: 0.78)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Column(
        children: [
          // ── 顶部操作栏 ──
          Row(
            children: [
              GestureDetector(
                onTap: () => context.pop(),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => _confirmDelete(context, ref),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.delete_outline_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ── 图标 ──
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(Icons.menu_book_rounded, color: Colors.white, size: 32),
          ),
          const SizedBox(height: 16),

          // ── 标题 ──
          Text(
            record.title,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 12),

          // ── 标签行 ──
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _HeaderBadge(
                icon: Icons.star_rounded,
                text: '+${record.expGained} EXP',
              ),
              const SizedBox(width: 10),
              _HeaderBadge(
                icon: isProfessional
                    ? Icons.school_rounded
                    : Icons.menu_book_rounded,
                text: isProfessional ? '专业模式' : '简单模式',
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 信息网格 (2x2)
  // ---------------------------------------------------------------------------

  Widget _buildInfoGrid(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _InfoTile(
                icon: Icons.timer_outlined,
                label: '时长',
                value: '${record.durationMinutes}分钟',
                color: AppColors.study,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _InfoTile(
                icon: Icons.book_outlined,
                label: '科目',
                value: record.subject ?? '--',
                color: AppColors.study,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _InfoTile(
                icon: Icons.speed_rounded,
                label: '难度',
                value: record.difficultyLevel != null
                    ? '${record.difficultyLevel}/5'
                    : '--',
                color: AppColors.study,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _InfoTile(
                icon: Icons.check_circle_outline_rounded,
                label: '掌握度',
                value: record.masteryLevel != null
                    ? '${record.masteryLevel}/5'
                    : '--',
                color: AppColors.study,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 专业模式信息
  // ---------------------------------------------------------------------------

  Widget _buildProfessionalSection(BuildContext context) {
    return _buildSection(
      icon: Icons.school_rounded,
      title: '专业信息',
      child: Column(
        children: [
          if (record.chapter != null && record.chapter!.isNotEmpty) ...[
            _InfoRow(
              icon: Icons.bookmark_outline_rounded,
              label: '章节',
              value: record.chapter!,
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          if (record.focusLevel != null) ...[
            _InfoRow(
              icon: Icons.center_focus_strong_rounded,
              label: '专注度',
              value: '${record.focusLevel}/5',
            ),
          ],
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 通用区块
  // ---------------------------------------------------------------------------

  Widget _buildSection({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: AppColors.study.withValues(alpha: 0.06),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.study.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.study.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 15, color: AppColors.study),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 区块标题（无卡片容器）
  // ---------------------------------------------------------------------------

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: AppColors.study,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 工具方法
  // ---------------------------------------------------------------------------

  String _formatDateTime(DateTime dt) {
    return '${dt.year}/${dt.month.toString().padLeft(2, '0')}/${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.delete_outline_rounded,
                color: AppColors.danger,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text('删除确认'),
          ],
        ),
        content: Text(
          '确定要删除学习记录「${record.title}」吗？\n此操作不可撤销。',
          style: const TextStyle(
            fontSize: 14,
            height: 1.5,
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        final repo = ref.read(studyRepositoryProvider);
        await repo.deleteStudyRecord(record.id);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('已删除'),
              backgroundColor: AppColors.textPrimary,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
            ),
          );
          context.pop();
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('删除失败: $e'),
              backgroundColor: AppColors.danger,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
            ),
          );
        }
      }
    }
  }
}

// =============================================================================
// Header 徽章
// =============================================================================

class _HeaderBadge extends StatelessWidget {
  const _HeaderBadge({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 5),
          Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// 信息瓦片 (2x2 网格中的一块)
// =============================================================================

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: color.withValues(alpha: 0.06), width: 1),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 17, color: color),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// 信息行
// =============================================================================

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 15, color: AppColors.textTertiary),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.end,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// 学习趋势图
// =============================================================================
