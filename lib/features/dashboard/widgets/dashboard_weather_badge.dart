import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/design/design.dart';
import '../../../core/services/weather_service.dart';
import '../../health/providers/weather_provider.dart';
import 'weather_pet/weather_pet_sheet.dart';

class DashboardWeatherBadge extends ConsumerWidget {
  const DashboardWeatherBadge({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weatherAsync = ref.watch(todayWeatherProvider);
    ref.watch(weatherExtraAutoProvider);

    return Builder(
      builder: (badgeContext) {
        return GestureDetector(
          onTap: () => WeatherPetSheet.show(badgeContext),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: context.growthColors.card.withValues(alpha: 0.78),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFF0E7DB)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF8B75F6).withValues(alpha: 0.08),
                  blurRadius: 14,
                  offset: const Offset(0, 7),
                ),
              ],
            ),
            child: weatherAsync.when(
              data: (weather) {
                if (weather == null) {
                  // No data - show config prompt
                  return GestureDetector(
                    onTap: () => context.push('/settings/weather'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: context.growthColors.card.withValues(
                          alpha: 0.86,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: context.growthColors.warning.withValues(
                            alpha: 0.3,
                          ),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: context.growthColors.warning.withValues(
                              alpha: 0.08,
                            ),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.wb_sunny_outlined,
                            size: 18,
                            color: context.growthColors.warning,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '配置天气',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: context.growthColors.warning,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                final emoji = WeatherService.getWeatherEmoji(
                  weather.weatherCode,
                );
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(emoji, style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 6),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${weather.temperature}°',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF37314E),
                          ),
                        ),
                        Text(
                          weather.weatherType,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF8D869A),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
              loading: () => const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 1.5),
                  ),
                ],
              ),
              error: (_, _) => const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('🌤️', style: TextStyle(fontSize: 20)),
                  SizedBox(width: 6),
                  Text('--', style: TextStyle(fontSize: 16)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
