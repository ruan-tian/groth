import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/app_database.dart';
import '../../core/services/weather_service.dart';
import 'repository_providers.dart';

final weatherServiceProvider = Provider<WeatherService>((ref) {
  return WeatherService(
    ref.watch(weatherRepositoryProvider),
    ref.watch(apiConfigRepositoryProvider),
    ref.watch(weatherSearchHistoryRepositoryProvider),
  );
});

final todayWeatherProvider = FutureProvider<DailyWeather?>((ref) async {
  final service = ref.watch(weatherServiceProvider);
  return service.getTodayWeather();
});

final apiStatusProvider = FutureProvider<String>((ref) async {
  final service = ref.watch(weatherServiceProvider);
  return service.getApiStatus();
});

/// 额外天气数据（空气质量、指数），刷新后缓存在内存中。
final weatherExtraProvider = StateProvider<WeatherExtraState?>((ref) => null);

/// 首次进入 Dashboard / 天气弹窗时自动补齐空气质量和指数数据。
final weatherExtraAutoProvider = FutureProvider<WeatherExtraState?>((
  ref,
) async {
  final cached = ref.read(weatherExtraProvider);
  if (cached != null) return cached;

  final service = ref.watch(weatherServiceProvider);
  try {
    final data = await service.refreshWeather();
    if (data == null) {
      debugPrint('weatherExtraAutoProvider: refreshWeather returned null');
      return null;
    }

    final state = WeatherExtraState(data);
    ref.read(weatherExtraProvider.notifier).state = state;
    ref.invalidate(todayWeatherProvider);
    debugPrint(
      'weatherExtraAutoProvider: success, invalidated todayWeatherProvider',
    );
    return state;
  } catch (e, st) {
    debugPrint('weatherExtraAutoProvider error: $e');
    debugPrint('stack: $st');
    rethrow;
  }
});

class WeatherExtraState {
  const WeatherExtraState(this.data);
  final Map<String, dynamic> data;

  Map<String, dynamic>? get air => data['air'] as Map<String, dynamic>?;
  List<dynamic>? get indices => data['indices'] as List<dynamic>?;

  String? get aqiLabel {
    final a = air;
    if (a == null) return null;
    final category = a['category']?.toString();
    final aqi = a['aqi']?.toString();
    if (category == null || aqi == null) return null;
    return '$category · $aqi';
  }

  String? get clothingSuggestion {
    final item = _clothingIndex;
    if (item == null) return null;
    final category = item['category']?.toString();
    final text = item['text']?.toString();
    if (category == null || text == null) return null;
    return '$category，$text';
  }

  String? get clothingBadgeLabel {
    final item = _clothingIndex;
    if (item == null) return null;
    return '穿衣建议';
  }

  Map<String, dynamic>? get _clothingIndex {
    final items = indices;
    if (items == null || items.isEmpty) return null;
    final maps = items.whereType<Map<String, dynamic>>().toList();
    if (maps.isEmpty) return null;
    for (final item in maps) {
      if (item['name']?.toString().contains('穿衣') == true) return item;
    }
    return maps.first;
  }
}
