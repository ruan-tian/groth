import 'package:flutter/material.dart';

import 'weather_assets.dart';

enum WeatherType { sunny, cloudy, rainy, heavyRain, snowy, windy, hot, night }

enum WeatherParticleType {
  sparkle,
  cloud,
  raindrop,
  heavyRain,
  snowflake,
  wind,
  heat,
  star,
}

class WeatherCardData {
  const WeatherCardData({
    required this.type,
    required this.temperature,
    required this.weatherText,
    required this.rangeText,
    required this.city,
    required this.timeText,
    required this.tipText,
    required this.petAssetPath,
    required this.sceneAssetPath,
    required this.foregroundAssetPath,
    required this.lightAssetPath,
    required this.particleAssets,
    required this.particleType,
    required this.bgColors,
    required this.accentColor,
    required this.sceneOpacity,
    required this.lightOpacity,
    required this.foregroundOpacity,
  });

  final WeatherType type;
  final int temperature;
  final String weatherText;
  final String rangeText;
  final String city;
  final String timeText;
  final String tipText;
  final String petAssetPath;
  final String sceneAssetPath;
  final String foregroundAssetPath;
  final String lightAssetPath;
  final List<String> particleAssets;
  final WeatherParticleType particleType;
  final List<Color> bgColors;
  final Color accentColor;
  final double sceneOpacity;
  final double lightOpacity;
  final double foregroundOpacity;

  factory WeatherCardData.fromWeatherCode({
    required String code,
    required int temp,
    required String weatherType,
    required String city,
  }) {
    var type = _mapCodeToType(code, temp);
    final now = DateTime.now();
    final hour = now.hour;

    final isNight = hour >= 19 || hour < 6;
    if (isNight) type = WeatherType.night;

    final style = _styleFor(type);

    return WeatherCardData(
      type: type,
      temperature: temp,
      weatherText: weatherType,
      rangeText: '${temp - 3}°C ~ ${temp + 3}°C',
      city: city,
      timeText:
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
      tipText: style.tipText,
      petAssetPath: style.petAssetPath,
      sceneAssetPath: style.sceneAssetPath,
      foregroundAssetPath: style.foregroundAssetPath,
      lightAssetPath: style.lightAssetPath,
      particleAssets: style.particleAssets,
      particleType: style.particleType,
      bgColors: style.bgColors,
      accentColor: style.accentColor,
      sceneOpacity: style.sceneOpacity,
      lightOpacity: style.lightOpacity,
      foregroundOpacity: style.foregroundOpacity,
    );
  }

  static WeatherType _mapCodeToType(String code, int temp) {
    if (temp >= 32) return WeatherType.hot;

    switch (code) {
      case '100':
      case '0':
      case '1':
        return WeatherType.sunny;
      case '101':
      case '2':
      case '103':
      case '104':
      case '3':
        return WeatherType.cloudy;
      case '300':
      case '301':
      case '302':
      case '305':
      case '306':
      case '307':
      case '308':
      case '309':
      case '310':
      case '311':
      case '312':
      case '313':
      case '314':
      case '315':
      case '316':
      case '317':
      case '318':
      case '350':
      case '351':
      case '51':
      case '53':
      case '55':
      case '56':
      case '57':
      case '61':
      case '63':
      case '65':
      case '66':
      case '67':
      case '80':
      case '81':
      case '82':
        return WeatherType.rainy;
      case '303':
      case '304':
      case '356':
      case '357':
      case '58':
      case '59':
      case '62':
      case '64':
      case '95':
      case '96':
      case '99':
        return WeatherType.heavyRain;
      case '400':
      case '401':
      case '402':
      case '403':
      case '404':
      case '405':
      case '406':
      case '407':
      case '408':
      case '409':
      case '410':
      case '456':
      case '457':
      case '71':
      case '73':
      case '75':
      case '77':
      case '85':
      case '86':
        return WeatherType.snowy;
      case '200':
      case '201':
      case '202':
      case '203':
      case '204':
      case '205':
      case '206':
      case '207':
      case '208':
      case '209':
      case '210':
      case '211':
      case '212':
      case '213':
      case '45':
      case '46':
      case '47':
      case '48':
        return WeatherType.windy;
      default:
        return WeatherType.sunny;
    }
  }

  static _WeatherStyle _styleFor(WeatherType type) {
    switch (type) {
      case WeatherType.sunny:
        return const _WeatherStyle(
          tipText: '阳光正好，出门走走吧~',
          petAssetPath: WeatherAssets.catSunny,
          sceneAssetPath: WeatherAssets.bgSunny,
          foregroundAssetPath: WeatherAssets.fgSunnyFlower,
          lightAssetPath: WeatherAssets.sunGlow,
          particleAssets: [
            WeatherAssets.particleSparkle1,
            WeatherAssets.particleSparkle2,
          ],
          particleType: WeatherParticleType.sparkle,
          bgColors: [Color(0xFFFFF7E8), Color(0xFFE8F2FF)],
          accentColor: Color(0xFFFFA94D),
          sceneOpacity: 0.28,
          lightOpacity: 0.34,
          foregroundOpacity: 0.78,
        );
      case WeatherType.cloudy:
        return const _WeatherStyle(
          tipText: '有点阴天，注意保暖~',
          petAssetPath: WeatherAssets.catCloudy,
          sceneAssetPath: WeatherAssets.bgCloudy,
          foregroundAssetPath: WeatherAssets.fgCloudyGrass,
          lightAssetPath: WeatherAssets.lightCloudSoft,
          particleAssets: [
            WeatherAssets.particleCloud1,
            WeatherAssets.particleCloud2,
          ],
          particleType: WeatherParticleType.cloud,
          bgColors: [Color(0xFFF1EDFF), Color(0xFFDDEAFF)],
          accentColor: Color(0xFF8C7AE6),
          sceneOpacity: 0.32,
          lightOpacity: 0.28,
          foregroundOpacity: 0.72,
        );
      case WeatherType.rainy:
        return const _WeatherStyle(
          tipText: '记得带伞，别淋湿了~',
          petAssetPath: WeatherAssets.catRainy,
          sceneAssetPath: WeatherAssets.bgRainy,
          foregroundAssetPath: WeatherAssets.fgRainyPuddle,
          lightAssetPath: WeatherAssets.lightRainGlow,
          particleAssets: [
            WeatherAssets.particleRaindrop1,
            WeatherAssets.particleRaindrop2,
            WeatherAssets.particleRaindrop3,
          ],
          particleType: WeatherParticleType.raindrop,
          bgColors: [Color(0xFFF3EDFF), Color(0xFFD6E7FF)],
          accentColor: Color(0xFF7B7FE8),
          sceneOpacity: 0.36,
          lightOpacity: 0.26,
          foregroundOpacity: 0.82,
        );
      case WeatherType.heavyRain:
        return const _WeatherStyle(
          tipText: '雨太大啦，别出门哦！',
          petAssetPath: WeatherAssets.catHeavyRain,
          sceneAssetPath: WeatherAssets.bgHeavyRain,
          foregroundAssetPath: WeatherAssets.fgHeavyRainWindow,
          lightAssetPath: WeatherAssets.lightStormGlow,
          particleAssets: [
            WeatherAssets.particleRainHeavy1,
            WeatherAssets.particleRainHeavy2,
          ],
          particleType: WeatherParticleType.heavyRain,
          bgColors: [Color(0xFFEBE8FF), Color(0xFFCDDAFF)],
          accentColor: Color(0xFF5B5DC8),
          sceneOpacity: 0.42,
          lightOpacity: 0.18,
          foregroundOpacity: 0.9,
        );
      case WeatherType.snowy:
        return const _WeatherStyle(
          tipText: '好冷呀，多穿点衣服~',
          petAssetPath: WeatherAssets.catSnowy,
          sceneAssetPath: WeatherAssets.bgSnowy,
          foregroundAssetPath: WeatherAssets.fgSnowySnowbank,
          lightAssetPath: WeatherAssets.lightSnowGlow,
          particleAssets: [
            WeatherAssets.particleSnowflake1,
            WeatherAssets.particleSnowflake2,
            WeatherAssets.particleSnowflake3,
          ],
          particleType: WeatherParticleType.snowflake,
          bgColors: [Color(0xFFF7F5FF), Color(0xFFDFF3FF)],
          accentColor: Color(0xFF65B7E8),
          sceneOpacity: 0.34,
          lightOpacity: 0.32,
          foregroundOpacity: 0.86,
        );
      case WeatherType.windy:
        return const _WeatherStyle(
          tipText: '风好大，戴好帽子~',
          petAssetPath: WeatherAssets.catWindy,
          sceneAssetPath: WeatherAssets.bgWindy,
          foregroundAssetPath: WeatherAssets.fgWindyLeafground,
          lightAssetPath: WeatherAssets.lightWindyGlow,
          particleAssets: [
            WeatherAssets.particleWindLine1,
            WeatherAssets.particleWindLine2,
            WeatherAssets.particleLeaf,
          ],
          particleType: WeatherParticleType.wind,
          bgColors: [Color(0xFFF5F7FF), Color(0xFFE8EFFF)],
          accentColor: Color(0xFF7B8CC8),
          sceneOpacity: 0.3,
          lightOpacity: 0.24,
          foregroundOpacity: 0.74,
        );
      case WeatherType.hot:
        return const _WeatherStyle(
          tipText: '太热了，多喝水防暑！',
          petAssetPath: WeatherAssets.catHot,
          sceneAssetPath: WeatherAssets.bgHot,
          foregroundAssetPath: WeatherAssets.fgHotGround,
          lightAssetPath: WeatherAssets.sunGlowHot,
          particleAssets: [
            WeatherAssets.particleHeat1,
            WeatherAssets.particleHeat2,
          ],
          particleType: WeatherParticleType.heat,
          bgColors: [Color(0xFFFFF4E8), Color(0xFFFFE8CC)],
          accentColor: Color(0xFFF08050),
          sceneOpacity: 0.26,
          lightOpacity: 0.42,
          foregroundOpacity: 0.74,
        );
      case WeatherType.night:
        return const _WeatherStyle(
          tipText: '晚安，做个好梦~',
          petAssetPath: WeatherAssets.catNight,
          sceneAssetPath: WeatherAssets.bgNight,
          foregroundAssetPath: WeatherAssets.fgNightWindow,
          lightAssetPath: WeatherAssets.lightMoonGlow,
          particleAssets: [
            WeatherAssets.particleStar1,
            WeatherAssets.particleStar2,
            WeatherAssets.particleMoonDust,
          ],
          particleType: WeatherParticleType.star,
          bgColors: [Color(0xFFDFDBFF), Color(0xFFBFD7FF)],
          accentColor: Color(0xFF6D67C8),
          sceneOpacity: 0.46,
          lightOpacity: 0.24,
          foregroundOpacity: 0.82,
        );
    }
  }
}

class _WeatherStyle {
  const _WeatherStyle({
    required this.tipText,
    required this.petAssetPath,
    required this.sceneAssetPath,
    required this.foregroundAssetPath,
    required this.lightAssetPath,
    required this.particleAssets,
    required this.particleType,
    required this.bgColors,
    required this.accentColor,
    required this.sceneOpacity,
    required this.lightOpacity,
    required this.foregroundOpacity,
  });

  final String tipText;
  final String petAssetPath;
  final String sceneAssetPath;
  final String foregroundAssetPath;
  final String lightAssetPath;
  final List<String> particleAssets;
  final WeatherParticleType particleType;
  final List<Color> bgColors;
  final Color accentColor;
  final double sceneOpacity;
  final double lightOpacity;
  final double foregroundOpacity;
}
