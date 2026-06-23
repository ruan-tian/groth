import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/design/design.dart';
import '../../../health/providers/weather_provider.dart';
import 'weather_assets.dart';
import 'weather_card_data.dart';
import 'weather_particle_layer.dart';
import 'weather_style_config.dart';

class WeatherPetCard extends ConsumerWidget {
  const WeatherPetCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weatherAsync = ref.watch(todayWeatherProvider);
    final extraAsync = ref.watch(weatherExtraAutoProvider);
    final extra = ref.watch(weatherExtraProvider) ?? extraAsync.valueOrNull;

    final child = weatherAsync.when(
      data: (weather) {
        if (weather == null) return const _WeatherEmptyCard();
        final data = WeatherCardData.fromWeatherCode(
          code: weather.weatherCode,
          temp: weather.temperature,
          weatherType: weather.weatherType,
          city: weather.city ?? '未知',
        );
        return _WeatherScene(
          key: ValueKey('${data.type}-${weather.weatherCode}-${weather.city}'),
          data: data,
          extra: extra,
        );
      },
      loading: () => const _WeatherLoadingCard(),
      error: (_, _) => const _WeatherEmptyCard(),
    );

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 360),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        final scale = Tween<double>(begin: 0.985, end: 1).animate(animation);
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(scale: scale, child: child),
        );
      },
      child: child,
    );
  }
}

class _WeatherScene extends StatelessWidget {
  const _WeatherScene({super.key, required this.data, required this.extra});

  final WeatherCardData data;
  final WeatherExtraState? extra;

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    return AspectRatio(
      aspectRatio: WeatherStyleConfig.aspectRatio,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(WeatherStyleConfig.cardRadius),
          boxShadow: WeatherStyleConfig.shadowFor(data.accentColor),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(WeatherStyleConfig.cardRadius),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final w = constraints.maxWidth;
              final compact = w < 420;
              final layout = _WeatherLayout.forType(data.type, compact);

              return Stack(
                fit: StackFit.expand,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: data.bgColors.length >= 3
                            ? data.bgColors
                            : [
                                data.bgColors.first,
                                Color.lerp(
                                  data.bgColors.first,
                                  data.bgColors.last,
                                  0.48,
                                )!,
                                data.bgColors.last,
                              ],
                      ),
                      border: Border.all(
                        color: context.growthColors.card.withValues(alpha: 0.7),
                        width: 1.2,
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: Image.asset(
                      data.sceneAssetPath,
                      fit: BoxFit.cover,
                      opacity: AlwaysStoppedAnimation(data.sceneOpacity),
                      filterQuality: FilterQuality.medium,
                      errorBuilder: (_, _, _) => const SizedBox.shrink(),
                    ),
                  ),
                  Positioned.fill(
                    child: Image.asset(
                      WeatherAssets.highlightOverlay,
                      fit: BoxFit.cover,
                      opacity: const AlwaysStoppedAnimation(0.34),
                      filterQuality: FilterQuality.low,
                      errorBuilder: (_, _, _) => const SizedBox.shrink(),
                    ),
                  ),
                  Positioned(
                    top: layout.lightTop * constraints.maxHeight,
                    right: layout.lightRight * w,
                    width: layout.lightWidth * w,
                    child: Image.asset(
                      data.lightAssetPath,
                      fit: BoxFit.contain,
                      opacity: AlwaysStoppedAnimation(data.lightOpacity),
                      filterQuality: FilterQuality.medium,
                      errorBuilder: (_, _, _) => const SizedBox.shrink(),
                    ),
                  ),
                  Positioned.fill(
                    child: WeatherParticleLayer(
                      type: data.particleType,
                      accentColor: data.accentColor,
                      enabled: !reduceMotion,
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: layout.foregroundBottom * constraints.maxHeight,
                    child: Image.asset(
                      data.foregroundAssetPath,
                      fit: BoxFit.fitWidth,
                      opacity: AlwaysStoppedAnimation(data.foregroundOpacity),
                      filterQuality: FilterQuality.medium,
                      errorBuilder: (_, _, _) => const SizedBox.shrink(),
                    ),
                  ),
                  Positioned(
                    right: layout.petRight * w,
                    bottom: layout.petBottom * constraints.maxHeight,
                    width: layout.petWidth * w,
                    child: RepaintBoundary(
                      child: Image.asset(
                        data.petAssetPath,
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.medium,
                        errorBuilder: (_, _, _) => Icon(
                          Icons.pets_rounded,
                          size: w * 0.3,
                          color: data.accentColor,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: compact ? 16 : 22,
                    top: compact ? 14 : 18,
                    width: layout.infoWidth * w,
                    child: _WeatherInfoBlock(
                      data: data,
                      extra: extra,
                      compact: compact,
                    ),
                  ),
                  Positioned(
                    left: layout.bubbleLeft * w,
                    top: layout.bubbleTop * constraints.maxHeight,
                    width: layout.bubbleWidth * w,
                    child: _TipBubble(
                      text: extra?.clothingSuggestion ?? data.tipText,
                      accentColor: data.accentColor,
                      tailAlignment: layout.bubbleTailAlignment,
                      compact: compact,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _WeatherInfoBlock extends StatelessWidget {
  const _WeatherInfoBlock({
    required this.data,
    required this.extra,
    required this.compact,
  });

  final WeatherCardData data;
  final WeatherExtraState? extra;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final aqi = extra?.aqiLabel;
    final clothing = extra?.clothingBadgeLabel;

    return DefaultTextStyle(
      style: const TextStyle(color: Color(0xFF4B4D83)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${data.temperature}',
                style: TextStyle(
                  fontSize: compact ? 52 : 66,
                  height: 0.92,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0,
                  color: data.accentColor,
                ),
              ),
              Padding(
                padding: EdgeInsets.only(top: compact ? 5 : 8, left: 3),
                child: Text(
                  '°C',
                  style: TextStyle(
                    fontSize: compact ? 18 : 24,
                    fontWeight: FontWeight.w800,
                    color: data.accentColor.withValues(alpha: 0.86),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: EdgeInsets.only(top: compact ? 8 : 12),
                child: Icon(
                  _weatherIcon(data.type),
                  size: compact ? 26 : 34,
                  color: data.accentColor.withValues(alpha: 0.72),
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          Text(
            data.weatherText,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: compact ? 24 : 30,
              height: 1.05,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF4B4D83),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: compact ? 130 : 168,
            height: 1,
            color: data.accentColor.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 8),
          Text(
            data.rangeText,
            style: TextStyle(
              fontSize: compact ? 14 : 17,
              fontWeight: FontWeight.w700,
              color: data.accentColor.withValues(alpha: 0.82),
            ),
          ),
          const SizedBox(height: 11),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              if (aqi != null)
                _ExtraChip(icon: '🌬️', label: aqi, color: data.accentColor),
              if (clothing != null)
                _ExtraChip(
                  icon: '👔',
                  label: clothing,
                  color: data.accentColor,
                ),
            ],
          ),
          const SizedBox(height: 13),
          Wrap(
            spacing: compact ? 8 : 12,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _MetaRow(icon: Icons.location_on_rounded, text: data.city),
              _MetaRow(icon: Icons.schedule_rounded, text: data.timeText),
            ],
          ),
        ],
      ),
    );
  }

  static IconData _weatherIcon(WeatherType type) {
    switch (type) {
      case WeatherType.sunny:
      case WeatherType.hot:
        return Icons.wb_sunny_rounded;
      case WeatherType.cloudy:
        return Icons.cloud_rounded;
      case WeatherType.rainy:
      case WeatherType.heavyRain:
        return Icons.water_drop_rounded;
      case WeatherType.snowy:
        return Icons.ac_unit_rounded;
      case WeatherType.windy:
        return Icons.air_rounded;
      case WeatherType.night:
        return Icons.nights_stay_rounded;
    }
  }
}

class _ExtraChip extends StatelessWidget {
  const _ExtraChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final String icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 152),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: context.growthColors.card.withValues(alpha: 0.68),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: context.growthColors.card.withValues(alpha: 0.78),
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        '$icon $label',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 12,
          height: 1.1,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: const Color(0xFF7B78C8)),
        const SizedBox(width: 4),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 116),
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              height: 1.1,
              fontWeight: FontWeight.w700,
              color: Color(0xFF7774B8),
            ),
          ),
        ),
      ],
    );
  }
}

class _TipBubble extends StatelessWidget {
  const _TipBubble({
    required this.text,
    required this.accentColor,
    required this.tailAlignment,
    required this.compact,
  });

  final String text;
  final Color accentColor;
  final Alignment tailAlignment;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _BubbleTailPainter(
        color: context.growthColors.card.withValues(alpha: 0.78),
        borderColor: context.growthColors.card.withValues(alpha: 0.88),
        alignment: tailAlignment,
      ),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 11 : 15,
          vertical: compact ? 8 : 11,
        ),
        decoration: BoxDecoration(
          color: context.growthColors.card.withValues(alpha: 0.78),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: context.growthColors.card.withValues(alpha: 0.88),
          ),
          boxShadow: [
            BoxShadow(
              color: accentColor.withValues(alpha: 0.12),
              blurRadius: 18,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: Text(
          text,
          maxLines: compact ? 2 : 3,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 12,
            height: 1.45,
            fontWeight: FontWeight.w800,
            color: Color(0xFF4B4D83),
          ),
        ),
      ),
    );
  }
}

class _BubbleTailPainter extends CustomPainter {
  const _BubbleTailPainter({
    required this.color,
    required this.borderColor,
    required this.alignment,
  });

  final Color color;
  final Color borderColor;
  final Alignment alignment;

  @override
  void paint(Canvas canvas, Size size) {
    final tailX = size.width * (alignment.x > 0 ? 0.76 : 0.24);
    final tailTop = size.height - 2;
    final path = Path()
      ..moveTo(tailX - 8, tailTop)
      ..quadraticBezierTo(
        tailX,
        tailTop + 15,
        tailX + 16 * alignment.x,
        tailTop + 18,
      )
      ..quadraticBezierTo(
        tailX + 5 * alignment.x,
        tailTop + 8,
        tailX + 8,
        tailTop,
      )
      ..close();

    canvas.drawPath(path, Paint()..color = color);
    canvas.drawPath(
      path,
      Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(covariant _BubbleTailPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.borderColor != borderColor ||
        oldDelegate.alignment != alignment;
  }
}

class _WeatherLayout {
  const _WeatherLayout({
    required this.infoWidth,
    required this.petWidth,
    required this.petRight,
    required this.petBottom,
    required this.bubbleLeft,
    required this.bubbleTop,
    required this.bubbleWidth,
    required this.bubbleTailAlignment,
    required this.lightTop,
    required this.lightRight,
    required this.lightWidth,
    required this.foregroundBottom,
  });

  final double infoWidth;
  final double petWidth;
  final double petRight;
  final double petBottom;
  final double bubbleLeft;
  final double bubbleTop;
  final double bubbleWidth;
  final Alignment bubbleTailAlignment;
  final double lightTop;
  final double lightRight;
  final double lightWidth;
  final double foregroundBottom;

  factory _WeatherLayout.forType(WeatherType type, bool compact) {
    final baseInfo = compact ? 0.52 : 0.49;
    switch (type) {
      case WeatherType.rainy:
      case WeatherType.heavyRain:
        return _WeatherLayout(
          infoWidth: baseInfo,
          petWidth: compact ? 0.44 : 0.43,
          petRight: compact ? 0.02 : 0.04,
          petBottom: 0.02,
          bubbleLeft: compact ? 0.36 : 0.35,
          bubbleTop: compact ? 0.31 : 0.32,
          bubbleWidth: compact ? 0.34 : 0.31,
          bubbleTailAlignment: Alignment.centerRight,
          lightTop: -0.06,
          lightRight: 0.12,
          lightWidth: 0.48,
          foregroundBottom: -0.02,
        );
      case WeatherType.snowy:
        return _WeatherLayout(
          infoWidth: baseInfo,
          petWidth: compact ? 0.43 : 0.42,
          petRight: compact ? 0.04 : 0.06,
          petBottom: 0.03,
          bubbleLeft: compact ? 0.36 : 0.37,
          bubbleTop: 0.29,
          bubbleWidth: compact ? 0.34 : 0.3,
          bubbleTailAlignment: Alignment.centerRight,
          lightTop: -0.08,
          lightRight: 0.08,
          lightWidth: 0.52,
          foregroundBottom: -0.01,
        );
      case WeatherType.hot:
      case WeatherType.sunny:
        return _WeatherLayout(
          infoWidth: baseInfo,
          petWidth: compact ? 0.42 : 0.4,
          petRight: compact ? 0.02 : 0.06,
          petBottom: 0.01,
          bubbleLeft: compact ? 0.35 : 0.38,
          bubbleTop: compact ? 0.3 : 0.31,
          bubbleWidth: compact ? 0.34 : 0.29,
          bubbleTailAlignment: Alignment.centerRight,
          lightTop: -0.14,
          lightRight: 0.04,
          lightWidth: 0.52,
          foregroundBottom: -0.02,
        );
      case WeatherType.windy:
      case WeatherType.cloudy:
        return _WeatherLayout(
          infoWidth: baseInfo,
          petWidth: compact ? 0.43 : 0.41,
          petRight: compact ? 0.02 : 0.05,
          petBottom: 0.02,
          bubbleLeft: compact ? 0.34 : 0.37,
          bubbleTop: compact ? 0.28 : 0.29,
          bubbleWidth: compact ? 0.36 : 0.31,
          bubbleTailAlignment: Alignment.centerRight,
          lightTop: -0.08,
          lightRight: 0.06,
          lightWidth: 0.5,
          foregroundBottom: -0.02,
        );
      case WeatherType.night:
        return _WeatherLayout(
          infoWidth: baseInfo,
          petWidth: compact ? 0.43 : 0.4,
          petRight: compact ? 0.03 : 0.07,
          petBottom: 0.02,
          bubbleLeft: compact ? 0.35 : 0.39,
          bubbleTop: compact ? 0.27 : 0.28,
          bubbleWidth: compact ? 0.36 : 0.3,
          bubbleTailAlignment: Alignment.centerRight,
          lightTop: -0.04,
          lightRight: 0.12,
          lightWidth: 0.45,
          foregroundBottom: -0.01,
        );
    }
  }
}

class _WeatherEmptyCard extends StatelessWidget {
  const _WeatherEmptyCard();

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: WeatherStyleConfig.aspectRatio,
      child: Container(
        decoration: WeatherStyleConfig.emptyDecoration,
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.cloud_outlined, size: 42, color: Color(0xFF8C7AE6)),
              SizedBox(height: 12),
              Text(
                '暂无天气数据',
                style: TextStyle(fontSize: 16, color: Color(0xFF6C6F8F)),
              ),
              SizedBox(height: 4),
              Text(
                '点击配置天气 API',
                style: TextStyle(fontSize: 12, color: Color(0xFFA7ABC2)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WeatherLoadingCard extends StatelessWidget {
  const _WeatherLoadingCard();

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: WeatherStyleConfig.aspectRatio,
      child: Container(
        decoration: WeatherStyleConfig.emptyDecoration,
        child: const Center(
          child: CircularProgressIndicator(color: Color(0xFF8C7AE6)),
        ),
      ),
    );
  }
}
