import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/design/app_colors.dart';
import '../../../core/services/weather_service.dart';
import '../../../shared/providers/weather_provider.dart';
import 'weather_pet/weather_pet_sheet.dart';

class DashboardWeatherBadge extends ConsumerWidget {
  const DashboardWeatherBadge({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weatherAsync = ref.watch(todayWeatherProvider);
    ref.watch(weatherExtraAutoProvider);

    return GestureDetector(
      onTap: () => WeatherPetSheet.show(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
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
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.wb_sunny_outlined, size: 18, color: AppColors.warning),
                      const SizedBox(width: 6),
                      Text(
                        '配置天气',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.warning,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
            final emoji = WeatherService.getWeatherEmoji(weather.weatherCode);
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
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1F2329)),
                    ),
                    Text(
                      weather.weatherType,
                      style: const TextStyle(fontSize: 11, color: Color(0xFF86909C)),
                    ),
                  ],
                ),
              ],
            );
          },
          loading: () => const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 1.5)),
            ],
          ),
          error: (_, __) => const Row(
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
  }
}
