import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/providers/pet_ai_result_provider.dart';
import '../../../shared/providers/pet_orchestrator_provider.dart';
import '../../../shared/providers/pet_projection_provider.dart';
import '../../../shared/providers/pet_scene_provider.dart';
import '../../../core/domain/pet/pet_ai_result.dart';
import '../../../core/domain/pet/pet_scene_model.dart';
import '../../../core/constants/pet_assets.dart';

/// 宠物场景画框组件
///
/// 统一的宠物展示区域，用于学习、健身、日记、饮食、睡眠 5 个页面顶部。
/// 包含：宠物 PNG（带柔光背景）+ 气泡说话框 + 浮动动画。
class PetSceneBanner extends ConsumerStatefulWidget {
  const PetSceneBanner({
    super.key,
    required this.module,
    required this.hasRecords,
    this.justCompleted = false,
    this.height = 130,
    this.petSize = 100,
    this.onTap,
  });

  /// 当前模块
  final PetModuleType module;

  /// 今日是否有记录
  final bool hasRecords;

  /// 是否刚完成记录
  final bool justCompleted;

  /// 画框高度
  final double height;

  /// 宠物图片尺寸
  final double petSize;

  /// 点击回调
  final VoidCallback? onTap;

  @override
  ConsumerState<PetSceneBanner> createState() => _PetSceneBannerState();
}

class _PetSceneBannerState extends ConsumerState<PetSceneBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _floatController;
  late Animation<double> _floatAnimation;
  bool _imageExists = true;
  bool _isReportExpanded = false;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _floatAnimation = Tween<double>(begin: -4, end: 4).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    // Register module ambient with v2 orchestrator
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(petOrchestratorProvider.notifier).setModuleAmbient(
        widget.module.name,
        _getDefaultImagePath(widget.module.name),
        _getDefaultMessages(widget.module.name),
      );
    });
  }

  @override
  void dispose() {
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final runtimeState = ref.watch(petOrchestratorProvider);
    final intent = runtimeState.activeIntent;
    final projection = ref.watch(modulePetViewProvider(widget.module.name));
    final latestAnalysis = ref.watch(latestPetAnalysisProvider(widget.module.name));

    // 解析颜色
    final bgColor = _parseColor(widget.module.softColorHex);
    final bgColorDeep = _parseColor(widget.module.primaryColorHex);
    final primaryColor = _parseColor(widget.module.primaryColorHex);

    final visibleIntent =
        (intent?.module == null || intent?.module == widget.module.name)
            ? intent
            : null;
    final imagePath =
        visibleIntent?.imagePath ??
        projection?.imagePath ??
        _getDefaultImagePath(widget.module.name);
    final defaultMessage =
        visibleIntent?.displayMessage ??
        projection?.bubbleText ??
        _getDefaultMessages(widget.module.name).first;
    // Prefer latest analysis petMessage over default
    final message = latestAnalysis.valueOrNull?.petMessage ?? defaultMessage;

    return Semantics(
      button: widget.onTap != null,
      label: '宠物场景',
      child: GestureDetector(
      onTap: widget.onTap,
      child: Container(
        height: widget.height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              bgColor,
              bgColor.withValues(alpha: 0.6),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: bgColorDeep.withValues(alpha: 0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: _buildContent(imagePath, message, bgColorDeep, primaryColor, latestAnalysis.valueOrNull),
      ),
      ),
    );
  }

  Widget _buildContent(
    String imagePath,
    String message,
    Color glowColor,
    Color primaryColor,
    PetAIResult? latestAnalysis,
  ) {
    final sceneState = ref.watch(petSceneProvider(widget.module));

    // Merge scene state with latest analysis for report display
    final showReport = sceneState.showReport || latestAnalysis != null;
    final reportTitle = sceneState.reportTitle ?? latestAnalysis?.title;
    final reportHighlights = sceneState.reportHighlights.isNotEmpty
        ? sceneState.reportHighlights
        : latestAnalysis?.highlights ?? [];
    final reportSuggestions = sceneState.reportSuggestions.isNotEmpty
        ? sceneState.reportSuggestions
        : latestAnalysis?.suggestions ?? [];

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              _buildPetImage(imagePath, glowColor),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSpeechBubble(
                  message,
                  primaryColor,
                  glowColor,
                  sceneState: sceneState.copyWith(
                    showReport: showReport,
                    reportTitle: reportTitle,
                    reportHighlights: reportHighlights,
                    reportSuggestions: reportSuggestions,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 构建宠物图片（白色底衬 + 柔光 + 浮动动画 + 阴影 + 边缘渐变）
  Widget _buildPetImage(String imagePath, Color glowColor) {
    return AnimatedBuilder(
      animation: _floatAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _floatAnimation.value),
          child: child,
        );
      },
      child: SizedBox(
        width: widget.petSize + 32,
        height: widget.petSize + 32,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 外层柔光
            Container(
              width: widget.petSize + 28,
              height: widget.petSize + 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.35),
                    Colors.white.withValues(alpha: 0.15),
                    Colors.white.withValues(alpha: 0.0),
                  ],
                  stops: const [0.4, 0.7, 1.0],
                ),
              ),
            ),
            // 白色底衬圆（带羽化边缘）
            Container(
              width: widget.petSize + 10,
              height: widget.petSize + 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.white,
                    Colors.white,
                    Colors.white.withValues(alpha: 0.8),
                    Colors.white.withValues(alpha: 0.0),
                  ],
                  stops: const [0.0, 0.75, 0.9, 1.0],
                ),
                boxShadow: [
                  BoxShadow(
                    color: glowColor.withValues(alpha: 0.12),
                    blurRadius: 14,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
            ),
            // 宠物图片（带边缘柔化）
            ShaderMask(
              shaderCallback: (Rect bounds) {
                return RadialGradient(
                  colors: [
                    Colors.white,
                    Colors.white,
                    Colors.white.withValues(alpha: 0.7),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.7, 0.85, 1.0],
                ).createShader(bounds);
              },
              blendMode: BlendMode.dstIn,
              child: _buildImageWithFallback(imagePath),
            ),
          ],
        ),
      ),
    );
  }

  /// 带 fallback 的图片加载
  Widget _buildImageWithFallback(String assetPath) {
    const fallbackPath = PetAssets.commonFallback;

    if (_imageExists) {
      return Image.asset(
        assetPath,
        width: widget.petSize,
        height: widget.petSize,
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _imageExists = false);
          });
          return _buildFallbackImage(fallbackPath);
        },
      );
    }
    return _buildFallbackImage(fallbackPath);
  }

  Widget _buildFallbackImage(String path) {
    return Image.asset(
      path,
      width: widget.petSize,
      height: widget.petSize,
      fit: BoxFit.contain,
      errorBuilder: (_, _, _) {
        return Container(
          width: widget.petSize,
          height: widget.petSize,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Center(
            child: Text('🐱', style: TextStyle(fontSize: 40)),
          ),
        );
      },
    );
  }

  /// 构建气泡说话框
  Widget _buildSpeechBubble(
    String message,
    Color primaryColor,
    Color accentColor, {
    PetSceneState? sceneState,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 主气泡（petMessage）
        CustomPaint(
          painter: _BubbleTailPainter(),
          child: Container(
            padding: const EdgeInsets.only(left: 14, right: 14, top: 8, bottom: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: accentColor.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '甜甜',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: primaryColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    color: primaryColor.withValues(alpha: 0.6),
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),

        // 标题气泡（AI 分析完成时显示）
        if (sceneState != null &&
            sceneState.showReport &&
            sceneState.reportTitle != null) ...[
          const SizedBox(height: 4),
          Semantics(
            button: true,
            label: '展开AI分析报告',
            child: GestureDetector(
            onTap: () {
              setState(() => _isReportExpanded = !_isReportExpanded);
              widget.onTap?.call();
            },
            child: AnimatedOpacity(
              opacity: sceneState.showReport ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      sceneState.reportTitle!,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: primaryColor.withValues(alpha: 0.8),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      _isReportExpanded
                          ? Icons.expand_less_rounded
                          : Icons.chevron_right_rounded,
                      size: 14,
                      color: primaryColor.withValues(alpha: 0.6),
                    ),
                  ],
                ),
              ),
            ),
            ),
          ),
        ],

        // 标签行（亮点 + 建议）
        if (sceneState != null &&
            sceneState.showReport &&
            (sceneState.reportHighlights.isNotEmpty ||
                sceneState.reportSuggestions.isNotEmpty)) ...[
          const SizedBox(height: 4),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            child: _isReportExpanded
                ? Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      if (sceneState.reportHighlights.isNotEmpty)
                        _buildChip(
                          '✨ ${sceneState.reportHighlights.first}',
                          const Color(0xFF10B981),
                          widget.onTap,
                        ),
                      if (sceneState.reportSuggestions.isNotEmpty)
                        _buildChip(
                          '💡 ${sceneState.reportSuggestions.first}',
                          const Color(0xFF6366F1),
                          widget.onTap,
                        ),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ],
    );
  }

  String _getDefaultImagePath(String module) {
    return PetModuleDefinitions.maybeByName(module)?.defaultImagePath ??
        PetAssets.commonFallback;
  }

  List<String> _getDefaultMessages(String module) {
    return PetModuleDefinitions.maybeByName(module)?.ambientMessages ??
        const ['甜甜在这里陪你～'];
  }

  /// 构建标签
  Widget _buildChip(String text, Color color, VoidCallback? onTap) {
    return Semantics(
      button: onTap != null,
      label: text,
      child: GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: color.withValues(alpha: 0.8),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      ),
    );
  }

  /// 解析颜色字符串
  Color _parseColor(String hex) {
    final buffer = StringBuffer();
    if (hex.length == 7 || hex.length == 9) buffer.write(hex);
    return Color(int.parse(buffer.toString().replaceFirst('#', '0xFF')));
  }
}

// =============================================================================
// 气泡尾巴画笔
// =============================================================================

/// 绘制气泡左侧的小三角尾巴
class _BubbleTailPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    // 小三角位置：左侧中间偏下
    final path = Path()
      ..moveTo(0, size.height * 0.6)
      ..lineTo(-8, size.height * 0.65)
      ..lineTo(0, size.height * 0.75)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
