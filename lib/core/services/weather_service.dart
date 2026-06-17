import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import '../database/app_database.dart';
import '../repositories/api_config_repository.dart';
import '../repositories/weather_repository.dart';
import '../repositories/weather_search_history_repository.dart';

/// 天气服务 - 支持多厂商 API、IP 定位、城市搜索
class WeatherService {
  WeatherService(this._weatherRepo, this._apiConfigRepo, this._historyRepo);
  final WeatherRepository _weatherRepo;
  final ApiConfigRepository _apiConfigRepo;
  final WeatherSearchHistoryRepository _historyRepo;

  // ── 公开方法 ──

  /// 获取今日天气（从缓存）
  Future<DailyWeather?> getTodayWeather() async {
    final result = await _weatherRepo.getTodayWeather();
    debugPrint(
      'getTodayWeather: ${result != null ? "found (city=${result.city}, temp=${result.temperature})" : "null"}',
    );
    return result;
  }

  /// 获取上次存储的位置（经纬度）
  Future<Map<String, double>?> getLastStoredLocation() async {
    final lastWeather = await _weatherRepo.getTodayWeather();
    if (lastWeather?.latitude != null && lastWeather?.longitude != null) {
      return {'lat': lastWeather!.latitude!, 'lon': lastWeather.longitude!};
    }
    return null;
  }

  /// 获取用户选择的城市
  Future<Map<String, dynamic>?> getSelectedCity() async {
    final lastWeather = await _weatherRepo.getTodayWeather();
    if (lastWeather?.city != null &&
        lastWeather?.latitude != null &&
        lastWeather?.longitude != null) {
      return {
        'name': lastWeather!.city!,
        'lat': lastWeather.latitude!,
        'lon': lastWeather.longitude!,
      };
    }
    return null;
  }

  /// 保存用户选择的城市
  Future<void> saveSelectedCity(String cityName, double lat, double lon) async {
    final now = DateTime.now();
    final dateStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    await _weatherRepo.upsertWeather(
      DailyWeatherTableCompanion(
        date: Value(dateStr),
        weatherType: const Value(''),
        weatherCode: const Value('0'),
        temperature: const Value(0),
        humidity: const Value(0),
        city: Value(cityName),
        latitude: Value(lat),
        longitude: Value(lon),
        createdAt: Value(now.millisecondsSinceEpoch),
      ),
    );
  }

  /// 强制定位当前位置（跳过 DB 城市查询）
  /// 优先 GPS → 基站缓存 → IP 兜底
  /// 返回 {lat, lon, city}，失败返回 null
  Future<Map<String, dynamic>?> locateByGps() async {
    final location = await _getLocationByGps();
    if (location != null) {
      await saveSelectedCity(
        location['city'] as String,
        location['lat'] as double,
        location['lon'] as double,
      );
      return location;
    }

    // GPS 失败时用 IP 兜底
    final ip = await _getLocationByIpWho();
    if (ip != null) {
      await saveSelectedCity(
        ip['city'] as String,
        ip['lat'] as double,
        ip['lon'] as double,
      );
    }
    return ip;
  }

  /// 搜索城市（和风天气 GeoAPI）
  Future<List<Map<String, dynamic>>> searchCity(
    String cityName,
    String apiKey,
  ) async {
    final url = Uri.parse(
      'https://geoapi.qweather.com/v2/city/lookup'
      '?location=$cityName&key=$apiKey&number=10',
    );
    final response = await http.get(url);
    if (response.statusCode != 200) return [];

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (data['code'] != '200') return [];

    return (data['location'] as List).map((loc) {
      final m = loc as Map<String, dynamic>;
      return {
        'name': m['name'] as String,
        'lat': (m['lat'] as num).toDouble(),
        'lon': (m['lon'] as num).toDouble(),
        'country': m['country'] as String,
        'admin1': m['admin1'] as String,
      };
    }).toList();
  }

  /// 搜索并返回城市列表（使用当前激活的天气 API Key）
  Future<List<Map<String, dynamic>>> searchAndSaveCity(String cityName) async {
    final config = await _apiConfigRepo.getActiveWeatherConfig();
    if (config?.apiKey == null) return [];
    return searchCity(cityName, config!.apiKey!);
  }

  /// 选择城市并保存到搜索历史
  Future<void> selectCity(Map<String, dynamic> city) async {
    await saveSelectedCity(city['name'], city['lat'], city['lon']);

    await _historyRepo.addHistory(
      cityName: city['name'] as String,
      country: city['country'] as String?,
      admin1: city['admin1'] as String?,
      latitude: city['lat'] as double,
      longitude: city['lon'] as double,
    );
  }

  /// 获取搜索历史
  Future<List<WeatherSearchHistory>> getSearchHistory({int limit = 20}) {
    return _historyRepo.getHistory(limit: limit);
  }

  /// 删除搜索历史条目
  Future<void> deleteSearchHistory(int id) {
    return _historyRepo.deleteHistory(id);
  }

  /// 清空搜索历史
  Future<void> clearSearchHistory() {
    return _historyRepo.clearHistory();
  }

  /// 刷新天气数据（返回完整数据，同时保存基础天气到数据库）
  /// 优先使用用户选择的城市 → IP 定位 → 默认北京
  /// 返回: { weather, air?, indices?, city, lat, lon }
  Future<Map<String, dynamic>?> refreshWeather() async {
    final config = await _apiConfigRepo.getActiveWeatherConfig();

    // 1. 获取用户选择的城市
    final selectedCity = await getSelectedCity();

    // 2. 确定经纬度和城市名
    double? lat;
    double? lon;
    String? cityName;

    if (selectedCity != null) {
      lat = selectedCity['lat'] as double?;
      lon = selectedCity['lon'] as double?;
      cityName = selectedCity['name'] as String?;
    }

    // 3. 没有选择城市时，尝试 GPS 定位
    if (lat == null || lon == null) {
      final gpsLocation = await _getLocationByGps();
      if (gpsLocation != null) {
        lat = gpsLocation['lat'] as double?;
        lon = gpsLocation['lon'] as double?;
        cityName = gpsLocation['city'] as String?;
      }
    }

    // 4. GPS 也失败时，尝试 IP 定位
    if (lat == null || lon == null) {
      final ipLocation = await _getLocationByIpWho();
      if (ipLocation != null) {
        lat = ipLocation['lat'] as double?;
        lon = ipLocation['lon'] as double?;
        cityName = ipLocation['city'] as String?;
      }
    }

    // 4. 获取天气数据
    Map<String, dynamic>? weatherData;
    Map<String, dynamic>? airData;
    List<dynamic>? indicesData;

    if (config != null &&
        config.provider == 'qweather' &&
        config.apiKey != null) {
      // 使用和风天气 API
      debugPrint('使用和风天气 API 获取数据...');
      final result = await _fetchQWeather(
        config.apiKey!,
        host: config.baseUrl ?? 'https://devapi.qweather.com',
        lat: lat,
        lon: lon,
      );
      if (result != null) {
        weatherData = result['weather'] as Map<String, dynamic>?;
        airData = result['air'] as Map<String, dynamic>?;
        indicesData = result['indices'] as List<dynamic>?;
        debugPrint(
          '和风天气返回: weather=${weatherData != null}, air=${airData != null}, indices=${indicesData != null}',
        );
        // 用和风返回的城市名覆盖（如果之前没有）
        cityName ??= result['city'] as String?;
        lat = result['lat'] as double?;
        lon = result['lon'] as double?;
      } else {
        debugPrint('和风天气返回 null，回退到 Open-Meteo');
      }
    }

    // Fallback: 使用 Open-Meteo（无需 API Key）
    if (weatherData == null) {
      final result = await _fetchOpenMeteo(lat: lat, lon: lon);
      if (result != null) {
        weatherData = result['weather'] as Map<String, dynamic>?;
        cityName ??= result['city'] as String?;
        lat = result['lat'] as double?;
        lon = result['lon'] as double?;
      }
    }

    // 如果 Open-Meteo 没有返回城市名，用经纬度反查
    if (cityName == null && lat != null && lon != null) {
      cityName = await _reverseGeocode(lat, lon);
    }

    if (weatherData == null) {
      throw Exception('天气数据获取失败，请检查网络或 API 配置');
    }

    // 5. 保存基础天气到数据库
    final now = DateTime.now();
    final dateStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    try {
      await _weatherRepo.upsertWeather(
        DailyWeatherTableCompanion(
          date: Value(dateStr),
          weatherType: Value(weatherData['text'] as String? ?? '晴'),
          weatherCode: Value(weatherData['code'] as String? ?? '0'),
          temperature: Value(_asInt(weatherData['temp'])),
          humidity: Value(_asInt(weatherData['humidity'])),
          windDir: Value(weatherData['windDir'] as String? ?? ''),
          windScale: Value(_asNullableInt(weatherData['windScale'])),
          city: Value(cityName ?? '未知'),
          latitude: Value(lat),
          longitude: Value(lon),
          createdAt: Value(now.millisecondsSinceEpoch),
        ),
      );
      debugPrint('天气数据已保存到数据库: date=$dateStr, city=$cityName');
    } catch (e) {
      debugPrint('天气数据保存到数据库失败: $e');
      // DB save failed, but still return the data so provider can use it
    }

    return {
      'weather': weatherData,
      'air': airData,
      'indices': indicesData,
      'city': cityName,
      'lat': lat,
      'lon': lon,
    };
  }

  /// 检查 API 配置状态
  Future<String> getApiStatus() async {
    final config = await _apiConfigRepo.getActiveWeatherConfig();
    if (config == null) return '未配置';
    if (config.provider == 'qweather' && config.apiKey == null) {
      return '未配置 Key';
    }
    return '已配置';
  }

  /// 获取可用的 API 列表
  Future<List<ApiConfig>> getAvailableApis() async {
    return _apiConfigRepo.getAllConfigs();
  }

  /// 保存 API 配置
  Future<void> saveApiConfig({
    required String provider,
    String? apiKey,
    String? baseUrl,
    required bool isActive,
  }) async {
    await _apiConfigRepo.upsertConfig(
      provider: provider,
      apiKey: apiKey,
      baseUrl: baseUrl,
      isActive: isActive,
    );
  }

  /// 加载中国城市数据库
  List<Map<String, dynamic>> _allCities = [];
  bool _citiesLoaded = false;

  Future<List<Map<String, dynamic>>> _loadCities() async {
    if (_citiesLoaded) return _allCities;
    try {
      final json = await rootBundle.loadString(
        'assets/data/chinese_cities.json',
      );
      _allCities = (jsonDecode(json) as List).cast<Map<String, dynamic>>();
      _citiesLoaded = true;
    } catch (_) {
      _allCities = [];
    }
    return _allCities;
  }

  /// 从城市数据库中找到离经纬度最近的城市
  Future<String?> _reverseGeocode(double lat, double lon) async {
    final cities = await _loadCities();
    if (cities.isEmpty) return null;

    String nearest = '';
    double minDist = double.infinity;

    for (final city in cities) {
      final clat = city['lat'] as num;
      final clon = city['lon'] as num;
      final d =
          (lat - clat.toDouble()) * (lat - clat.toDouble()) +
          (lon - clon.toDouble()) * (lon - clon.toDouble());
      if (d < minDist) {
        minDist = d;
        nearest = city['name'] as String;
      }
    }
    return nearest;
  }

  // ── 定位 ──

  /// 通过 GPS 获取当前位置
  Future<Map<String, dynamic>?> _getLocationByGps() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      // 请求位置权限
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
          return null;
        }
      }

      // 1. 先取基站/WiFi 缓存（秒出，室内可用）
      final lastPos = await Geolocator.getLastKnownPosition();
      if (lastPos != null) {
        final city = await _reverseGeocode(lastPos.latitude, lastPos.longitude);
        if (city != null) {
          return {
            'lat': lastPos.latitude,
            'lon': lastPos.longitude,
            'city': city,
          };
        }
      }

      // 2. 缓存没有，等 GPS（10秒超时）
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 10),
        ),
      ).timeout(const Duration(seconds: 12));

      final city = await _reverseGeocode(pos.latitude, pos.longitude);
      return {'lat': pos.latitude, 'lon': pos.longitude, 'city': city ?? '未知'};
    } on TimeoutException {
      debugPrint('GPS 定位超时');
      return null;
    } catch (e) {
      debugPrint('GPS 定位失败: $e');
      return null;
    }
  }

  /// 通过免费 ipwho.is 服务获取当前位置
  Future<Map<String, dynamic>?> _getLocationByIpWho() async {
    try {
      final url = Uri.parse('https://ipwho.is/');
      final response = await http.get(url).timeout(const Duration(seconds: 5));
      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['success'] == false) return null;

      final lat = data['latitude'] as num?;
      final lon = data['longitude'] as num?;
      final city = data['city'] as String?;

      if (lat == null || lon == null) return null;

      return {
        'lat': lat.toDouble(),
        'lon': lon.toDouble(),
        'city': city ?? '未知',
      };
    } catch (_) {
      return null;
    }
  }

  // ── 天气 API 调用 ──

  /// 和风天气 API
  Future<Map<String, dynamic>?> _fetchQWeather(
    String apiKey, {
    required String host,
    double? lat,
    double? lon,
  }) async {
    try {
      lat ??= 39.9042;
      lon ??= 116.4074;
      final location = '$lon,$lat';
      final headers = {'X-QW-Api-Key': apiKey};
      final baseUrl = host.endsWith('/')
          ? host.substring(0, host.length - 1)
          : host;

      // 1. 通过坐标获取城市名（本地库反查，不依赖 GeoAPI）
      final cityName = (await _reverseGeocode(lat, lon)) ?? '未知';

      // 2. 获取实时天气
      final weatherUrl = Uri.parse(
        '$baseUrl/v7/weather/now?location=$location',
      );
      final weatherResp = await http.get(weatherUrl, headers: headers);
      if (weatherResp.statusCode != 200) {
        debugPrint(
          'QWeather 天气查询失败: HTTP ${weatherResp.statusCode}, body=${weatherResp.body}',
        );
        return null;
      }

      final weatherBody = jsonDecode(weatherResp.body) as Map<String, dynamic>;
      if (weatherBody['code'] != '200') {
        debugPrint(
          'QWeather 天气查询返回错误: code=${weatherBody['code']}, body=${weatherResp.body}',
        );
        return null;
      }

      final now = weatherBody['now'] as Map<String, dynamic>;

      // 3. 获取空气质量
      Map<String, dynamic>? airData;
      try {
        final airUrl = Uri.parse('$baseUrl/airquality/v1/current/$lat/$lon');
        final airResp = await http.get(airUrl, headers: headers);
        if (airResp.statusCode == 200) {
          final airResult = jsonDecode(airResp.body) as Map<String, dynamic>;
          final indexes = airResult['indexes'] as List<dynamic>?;
          if (indexes != null && indexes.isNotEmpty) {
            final first = indexes[0] as Map<String, dynamic>;
            final category = first['category'] as String?;
            final aqi = (first['aqiDisplay'] ?? first['aqi'])?.toString();
            final primary = first['primaryPollutant'] as String?;
            if (category != null && aqi != null) {
              airData = {
                'category': category,
                'aqi': aqi,
                'primary': primary ?? '',
              };
            }
          } else {
            debugPrint('QWeather 空气质量无 indexes 数据');
          }
        } else {
          debugPrint('QWeather 空气质量失败: HTTP ${airResp.statusCode}');
        }
      } catch (e) {
        debugPrint('QWeather 空气质量异常: $e');
      }

      // 4. 获取天气指数（穿衣指数 type=3）
      List<dynamic>? indicesData;
      try {
        final indicesUrl = Uri.parse(
          '$baseUrl/v7/indices/1d?type=3&location=$location',
        );
        final indicesResp = await http.get(indicesUrl, headers: headers);
        if (indicesResp.statusCode == 200) {
          final indicesResult =
              jsonDecode(indicesResp.body) as Map<String, dynamic>;
          if (indicesResult['code'] == '200' &&
              indicesResult['daily'] != null) {
            indicesData = (indicesResult['daily'] as List)
                .map(
                  (item) => {
                    'name': item['name'],
                    'category': item['category'],
                    'text': item['text'],
                  },
                )
                .toList();
          } else {
            debugPrint('QWeather 指数返回错误: code=${indicesResult['code']}');
          }
        } else {
          debugPrint('QWeather 指数失败: HTTP ${indicesResp.statusCode}');
        }
      } catch (e) {
        debugPrint('QWeather 指数异常: $e');
      }

      return {
        'weather': {
          'temp': now['temp'],
          'text': now['text'],
          'code': now['icon'],
          'humidity': now['humidity'],
          'windDir': now['windDir'],
          'windScale': now['windScale'],
        },
        'air': airData,
        'indices': indicesData,
        'city': cityName,
        'lat': lat,
        'lon': lon,
      };
    } catch (e) {
      debugPrint('QWeather API 整体异常: $e');
      return null;
    }
  }

  /// Open-Meteo API（免费，无需 Key）
  Future<Map<String, dynamic>?> _fetchOpenMeteo({
    double? lat,
    double? lon,
  }) async {
    try {
      lat ??= 39.9042;
      lon ??= 116.4074;

      final url = Uri.parse(
        'https://api.open-meteo.com/v1/forecast'
        '?latitude=$lat&longitude=$lon'
        '&current=temperature_2m,relative_humidity_2m,weather_code,wind_speed_10m,wind_direction_10m'
        '&timezone=Asia/Shanghai',
      );

      final response = await http.get(url);
      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final current = data['current'] as Map<String, dynamic>;

      return {
        'weather': {
          'temp': (current['temperature_2m'] as num).round(),
          'text': _getWeatherTypeFromCode(current['weather_code'].toString()),
          'code': current['weather_code'].toString(),
          'humidity': (current['relative_humidity_2m'] as num).round(),
          'windDir': _getWindDirection(
            (current['wind_direction_10m'] as num).toInt(),
          ),
          'windScale': _getWindScale(
            (current['wind_speed_10m'] as num).toDouble(),
          ),
        },
        'city': null,
        'lat': lat,
        'lon': lon,
      };
    } catch (_) {
      return null;
    }
  }

  // ── 天气代码映射 ──

  static String getWeatherEmoji(String code) {
    switch (code) {
      case '100':
      case '0':
      case '1':
        return '☀️';
      case '101':
      case '2':
        return '⛅';
      case '103':
      case '104':
      case '3':
        return '☁️';
      case '45':
      case '48':
        return '🌫️';
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
        return '🌧️';
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
        return '🌨️';
      case '500':
      case '501':
      case '502':
      case '503':
      case '504':
      case '507':
      case '508':
      case '509':
      case '510':
      case '511':
      case '512':
      case '513':
      case '514':
      case '515':
        return '🌫️';
      case '95':
      case '96':
      case '99':
        return '⛈️';
      default:
        return '🌤️';
    }
  }

  static String getWeatherDescription(String code) {
    switch (code) {
      case '100':
      case '0':
        return '晴';
      case '101':
      case '1':
        return '大部晴';
      case '103':
      case '2':
        return '多云';
      case '104':
      case '3':
        return '阴';
      case '45':
      case '48':
        return '雾';
      case '51':
      case '53':
      case '55':
        return '毛毛雨';
      case '61':
      case '63':
      case '65':
        return '雨';
      case '71':
      case '73':
      case '75':
        return '雪';
      case '80':
      case '81':
      case '82':
        return '阵雨';
      case '95':
        return '雷暴';
      default:
        return '晴';
    }
  }

  String _getWeatherTypeFromCode(String code) {
    return getWeatherDescription(code);
  }

  String _getWindDirection(int degrees) {
    const dirs = ['北', '东北', '东', '东南', '南', '西南', '西', '西北'];
    final index = ((degrees + 22.5) % 360 / 45).floor();
    return '${dirs[index]}风';
  }

  int _getWindScale(double speedKmh) {
    if (speedKmh < 1) return 0;
    if (speedKmh < 6) return 1;
    if (speedKmh < 12) return 2;
    if (speedKmh < 20) return 3;
    if (speedKmh < 29) return 4;
    if (speedKmh < 39) return 5;
    return 6;
  }

  int _asInt(dynamic value, [int fallback = 0]) {
    return _asNullableInt(value) ?? fallback;
  }

  int? _asNullableInt(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.round();
    if (value is String) {
      final direct = num.tryParse(value);
      if (direct != null) return direct.round();
      final match = RegExp(r'\d+').firstMatch(value);
      if (match != null) return int.tryParse(match.group(0)!);
    }
    return null;
  }
}
