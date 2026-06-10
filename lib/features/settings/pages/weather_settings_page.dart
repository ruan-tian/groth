import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/design/design.dart';
import '../../../core/database/app_database.dart';
import '../../../shared/providers/weather_provider.dart';
import '../../../shared/providers/repository_providers.dart';
import '../widgets/weather_settings_widgets.dart';

// ── Data Assets ─────────────────────────────────────────────────────────────

const _chineseCitiesData = 'assets/data/chinese_cities.json';

// ── Providers ───────────────────────────────────────────────────────────────

final _activeWeatherApiProvider = FutureProvider<ApiConfig?>((ref) async {
  final repo = ref.watch(apiConfigRepositoryProvider);
  return repo.getActiveWeatherConfig();
});

final _allApiConfigsProvider = FutureProvider<List<ApiConfig>>((ref) async {
  final repo = ref.watch(apiConfigRepositoryProvider);
  return repo.getAllConfigs();
});

final _searchHistoryProvider = FutureProvider<List<WeatherSearchHistory>>((
  ref,
) async {
  final repo = ref.watch(weatherSearchHistoryRepositoryProvider);
  return repo.getHistory(limit: 10);
});

// ── Page ────────────────────────────────────────────────────────────────────

class WeatherSettingsPage extends ConsumerStatefulWidget {
  const WeatherSettingsPage({super.key});

  @override
  ConsumerState<WeatherSettingsPage> createState() =>
      _WeatherSettingsPageState();
}

class _WeatherSettingsPageState extends ConsumerState<WeatherSettingsPage>
    with SingleTickerProviderStateMixin {
  bool _isRefreshing = false;

  // QWeather API
  final _qweatherHostController = TextEditingController(
    text: 'https://devapi.qweather.com',
  );
  final _qweatherKeyController = TextEditingController();
  bool _isObscureQweatherKey = true;
  bool _isSavingQweatherKey = false;

  late AnimationController _refreshAnimController;

  @override
  void initState() {
    super.initState();
    _refreshAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _prefillApiKeys();
  }

  Future<void> _prefillApiKeys() async {
    final configs = await ref.read(_allApiConfigsProvider.future);
    if (!mounted) return;

    final qweatherConfig = configs
        .where((c) => c.provider == 'qweather')
        .firstOrNull;
    if (qweatherConfig?.apiKey?.isNotEmpty == true) {
      _qweatherKeyController.text = qweatherConfig!.apiKey!;
    }
    if (qweatherConfig?.baseUrl?.isNotEmpty == true) {
      _qweatherHostController.text = qweatherConfig!.baseUrl!;
    }
  }

  @override
  void dispose() {
    _qweatherHostController.dispose();
    _qweatherKeyController.dispose();
    _refreshAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final weatherAsync = ref.watch(todayWeatherProvider);
    final extraAsync = ref.watch(weatherExtraAutoProvider);
    final extra = ref.watch(weatherExtraProvider) ?? extraAsync.valueOrNull;
    final allConfigsAsync = ref.watch(_allApiConfigsProvider);
    final searchHistoryAsync = ref.watch(_searchHistoryProvider);

    final configs = allConfigsAsync.valueOrNull ?? [];
    final qweatherConfig = configs
        .where((c) => c.provider == 'qweather')
        .firstOrNull;
    final activeConfig = configs.where((c) => c.isActive).firstOrNull;

    final hasQweatherKey = qweatherConfig?.apiKey?.isNotEmpty == true;
    final activeProvider = activeConfig?.provider ?? 'open_meteo';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('天气设置', style: AppTextStyles.pageTitle),
        centerTitle: false,
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              onPressed: _isRefreshing ? null : _refreshWeather,
              icon: RotationTransition(
                turns: _refreshAnimController,
                child: Icon(
                  Icons.refresh_rounded,
                  color: _isRefreshing
                      ? AppColors.textTertiary
                      : AppColors.primary,
                ),
              ),
              style: IconButton.styleFrom(
                backgroundColor: AppColors.softPurple,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.lg,
        ),
        children: [
          // ── 1. Current Weather Card ───────────────────────────────────
          WeatherCurrentCard(weatherAsync: weatherAsync),
          // ── 空气 + 指数 — 直接 inline watch，确保重建 ──
          if (extra?.aqiLabel != null || extra?.clothingSuggestion != null)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.md),
              child: Row(
                children: [
                  if (extra?.aqiLabel != null)
                    Expanded(
                      child: WeatherExtraChip(
                        icon: Icons.air_rounded,
                        label: '空气',
                        value: extra!.aqiLabel!,
                      ),
                    ),
                  if (extra?.aqiLabel != null &&
                      extra?.clothingSuggestion != null)
                    const SizedBox(width: AppSpacing.sm),
                  if (extra?.clothingSuggestion != null)
                    Expanded(
                      child: WeatherExtraChip(
                        icon: Icons.checkroom_rounded,
                        label: '穿衣',
                        value: extra!.clothingSuggestion!,
                      ),
                    ),
                ],
              ),
            ),
          const SizedBox(height: AppSpacing.xxl),

          // ── 2. City Selector ──────────────────────────────────────────
          const WeatherSettingsSectionHeader(
            title: '定位设置',
            icon: Icons.location_on_outlined,
          ),
          const SizedBox(height: AppSpacing.md),
          WeatherCitySelectorCard(
            weather: weatherAsync.valueOrNull,
            onShowCitySearch: _showCitySearchSheet,
            onLocateByGps: _locateByGps,
          ),
          const SizedBox(height: AppSpacing.xxl),

          // ── 3. Weather API Services ───────────────────────────────────
          const WeatherSettingsSectionHeader(
            title: '天气 API 服务',
            icon: Icons.cloud_outlined,
          ),
          const SizedBox(height: AppSpacing.md),
          WeatherApiCard(
            icon: Icons.cloud_rounded,
            iconColor: AppColors.primary,
            name: '和风天气',
            description: '国内最稳定，免费 1000 次/天',
            isRecommended: true,
            provider: 'qweather',
            currentProvider: activeProvider,
            hasApiKey: hasQweatherKey,
            controller: _qweatherKeyController,
            isObscure: _isObscureQweatherKey,
            isSaving: _isSavingQweatherKey,
            onProviderChanged: _switchProvider,
            onToggleObscure: () =>
                setState(() => _isObscureQweatherKey = !_isObscureQweatherKey),
            onSave: () => _saveQweatherKey(),
            hostController: _qweatherHostController,
          ),
          const SizedBox(height: AppSpacing.md),
          WeatherApiCard(
            icon: Icons.public_rounded,
            iconColor: const Color(0xFF36CFC9),
            name: 'Open-Meteo',
            description: '免费无需 Key，国外服务（备选）',
            isRecommended: false,
            provider: 'open_meteo',
            currentProvider: activeProvider,
            hasApiKey: false,
            controller: null,
            isObscure: false,
            isSaving: false,
            onProviderChanged: _switchProvider,
            onToggleObscure: null,
            onSave: null,
          ),
          const SizedBox(height: AppSpacing.xxl),

          // ── 5. Search History ─────────────────────────────────────────
          const WeatherSettingsSectionHeader(
            title: '搜索历史',
            icon: Icons.history_rounded,
          ),
          const SizedBox(height: AppSpacing.md),
          WeatherSearchHistorySection(
            historyAsync: searchHistoryAsync,
            onDeleteHistoryItem: _deleteHistoryItem,
            onClearSearchHistory: _clearSearchHistory,
          ),
          const SizedBox(height: AppSpacing.xxl),

          // ── 6. API Key Guide ──────────────────────────────────────────
          const WeatherApiKeyGuide(),
          const SizedBox(height: AppSpacing.xxxl),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // City Search Bottom Sheet
  // ─────────────────────────────────────────────────────────────────────────

  void _showCitySearchSheet() {
    final searchController = TextEditingController();
    final searchResults = ValueNotifier<List<Map<String, dynamic>>>([]);
    final isSearching = ValueNotifier<bool>(false);
    Timer? debounce;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          return DraggableScrollableSheet(
            initialChildSize: 0.7,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            builder: (context, scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(AppRadius.xl),
                  ),
                ),
                child: Column(
                  children: [
                    // Handle bar
                    Container(
                      margin: const EdgeInsets.only(top: 12),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.textHint,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),

                    // Title
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.xl,
                        AppSpacing.lg,
                        AppSpacing.xl,
                        AppSpacing.md,
                      ),
                      child: Row(
                        children: [
                          const Text('搜索城市', style: AppTextStyles.sectionTitle),
                          const Spacer(),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: Icon(
                              Icons.close_rounded,
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Search input
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xl,
                      ),
                      child: TextField(
                        controller: searchController,
                        textInputAction: TextInputAction.search,
                        autofocus: true,
                        decoration: InputDecoration(
                          hintText: '输入城市名称...',
                          hintStyle: TextStyle(color: AppColors.textHint),
                          prefixIcon: Icon(
                            Icons.search_rounded,
                            color: AppColors.textTertiary,
                          ),
                          suffixIcon: ValueListenableBuilder<TextEditingValue>(
                            valueListenable: searchController,
                            builder: (context, value, _) {
                              if (value.text.isEmpty) {
                                return const SizedBox.shrink();
                              }
                              return IconButton(
                                onPressed: () {
                                  searchController.clear();
                                  searchResults.value = [];
                                },
                                icon: Icon(
                                  Icons.close_rounded,
                                  size: 18,
                                  color: AppColors.textTertiary,
                                ),
                              );
                            },
                          ),
                          filled: true,
                          fillColor: AppColors.surfaceVariant,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                            vertical: AppSpacing.md,
                          ),
                        ),
                        onChanged: (query) {
                          debounce?.cancel();
                          if (query.length >= 2) {
                            debounce = Timer(
                              const Duration(milliseconds: 300),
                              () {
                                _searchCities(
                                  query,
                                  searchResults,
                                  isSearching,
                                );
                              },
                            );
                          } else {
                            searchResults.value = [];
                          }
                        },
                      ),
                    ),

                    const SizedBox(height: AppSpacing.md),

                    // Results or history
                    Expanded(
                      child: ValueListenableBuilder<bool>(
                        valueListenable: isSearching,
                        builder: (context, searching, _) {
                          if (searching) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          return ValueListenableBuilder<
                            List<Map<String, dynamic>>
                          >(
                            valueListenable: searchResults,
                            builder: (context, results, _) {
                              if (results.isNotEmpty) {
                                return ListView.builder(
                                  controller: scrollController,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.xl,
                                  ),
                                  itemCount: results.length,
                                  itemBuilder: (context, index) {
                                    final city = results[index];
                                    return WeatherCitySearchResultTile(
                                      city: city,
                                      onTap: () => _selectCity(city, context),
                                    );
                                  },
                                );
                              }

                              // Show search history
                              return ref
                                  .watch(_searchHistoryProvider)
                                  .when(
                                    data: (history) {
                                      if (history.isEmpty) {
                                        return Center(
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.search_rounded,
                                                size: 48,
                                                color: AppColors.textHint,
                                              ),
                                              const SizedBox(
                                                height: AppSpacing.md,
                                              ),
                                              Text(
                                                '输入城市名称搜索',
                                                style: TextStyle(
                                                  fontSize: 15,
                                                  color: AppColors.textTertiary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }

                                      return ListView.builder(
                                        controller: scrollController,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: AppSpacing.xl,
                                        ),
                                        itemCount: history.length,
                                        itemBuilder: (context, index) {
                                          final item = history[index];
                                          return ListTile(
                                            leading: Icon(
                                              Icons.history_rounded,
                                              color: AppColors.textTertiary,
                                              size: 20,
                                            ),
                                            title: Text(
                                              item.cityName,
                                              style: AppTextStyles.body
                                                  .copyWith(
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                            ),
                                            subtitle:
                                                item.admin1?.isNotEmpty == true
                                                ? Text(
                                                    '${item.admin1}${item.country?.isNotEmpty == true ? ' · ${item.country}' : ''}',
                                                    style:
                                                        AppTextStyles.caption,
                                                  )
                                                : null,
                                            onTap: () => _selectCity({
                                              'name': item.cityName,
                                              'admin1': item.admin1 ?? '',
                                              'country': item.country ?? '',
                                              'latitude': item.latitude,
                                              'longitude': item.longitude,
                                            }, context),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(
                                                    AppRadius.sm,
                                                  ),
                                            ),
                                          );
                                        },
                                      );
                                    },
                                    loading: () => const Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                    error: (_, _) => const SizedBox.shrink(),
                                  );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _searchCities(
    String query,
    ValueNotifier<List<Map<String, dynamic>>> results,
    ValueNotifier<bool> isSearching,
  ) async {
    isSearching.value = true;
    try {
      final json = await rootBundle.loadString(_chineseCitiesData);
      final allCities = (jsonDecode(json) as List).cast<Map<String, dynamic>>();
      final q = query.toLowerCase();

      results.value = allCities
          .where(
            (c) =>
                (c['name'] as String).toLowerCase().contains(q) ||
                (c['admin1'] as String).toLowerCase().contains(q),
          )
          .take(20)
          .map(
            (c) => {
              'name': c['name'] as String,
              'admin1': c['admin1'] as String,
              'country': c['country'] as String? ?? '中国',
              'latitude': (c['lat'] as num).toDouble(),
              'longitude': (c['lon'] as num).toDouble(),
            },
          )
          .toList();
    } catch (e) {
      debugPrint('City search failed: $e');
      results.value = [];
    } finally {
      isSearching.value = false;
    }
  }

  Future<void> _selectCity(
    Map<String, dynamic> city,
    BuildContext sheetContext,
  ) async {
    final name = city['name'] as String;
    final admin1 = city['admin1'] as String? ?? '';
    final country = city['country'] as String? ?? '';
    final lat = city['latitude'] as double;
    final lon = city['longitude'] as double;

    // Save to search history
    final historyRepo = ref.read(weatherSearchHistoryRepositoryProvider);
    await historyRepo.addHistory(
      cityName: name,
      country: country,
      admin1: admin1,
      latitude: lat,
      longitude: lon,
    );

    // Save city and refresh weather
    final service = ref.read(weatherServiceProvider);
    await service.saveSelectedCity(name, lat, lon);
    Map<String, dynamic>? extraData;
    try {
      extraData = await service.refreshWeather();
    } catch (e) {
      debugPrint('刷新天气失败: $e');
    }

    if (!mounted) return;

    // Refresh providers
    if (extraData != null) {
      ref.read(weatherExtraProvider.notifier).state = WeatherExtraState(
        extraData,
      );
    }
    ref.invalidate(todayWeatherProvider);
    ref.invalidate(weatherExtraAutoProvider);
    ref.invalidate(_searchHistoryProvider);
    ref.invalidate(apiStatusProvider);

    if (sheetContext.mounted) {
      Navigator.pop(sheetContext);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('已切换到 $name'), backgroundColor: AppColors.success),
    );
  }

  Future<void> _deleteHistoryItem(int id) async {
    final repo = ref.read(weatherSearchHistoryRepositoryProvider);
    await repo.deleteHistory(id);
    ref.invalidate(_searchHistoryProvider);
  }

  Future<void> _clearSearchHistory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清空搜索历史'),
        content: const Text('确定要清空所有搜索历史吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('清空'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final repo = ref.read(weatherSearchHistoryRepositoryProvider);
      await repo.clearHistory();
      ref.invalidate(_searchHistoryProvider);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Switch API Provider
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _switchProvider(String provider) async {
    final service = ref.read(weatherServiceProvider);
    final repo = ref.read(apiConfigRepositoryProvider);
    final configs = await repo.getAllConfigs();

    if (provider == 'qweather') {
      final qweatherConfig = configs
          .where((c) => c.provider == 'qweather')
          .firstOrNull;
      await service.saveApiConfig(
        provider: 'qweather',
        apiKey: qweatherConfig?.apiKey,
        baseUrl: qweatherConfig?.baseUrl,
        isActive: true,
      );
      final openMeteoConfig = configs
          .where((c) => c.provider == 'open_meteo')
          .firstOrNull;
      if (openMeteoConfig != null) {
        await service.saveApiConfig(provider: 'open_meteo', isActive: false);
      }
    } else {
      await service.saveApiConfig(provider: 'open_meteo', isActive: true);
      final qweatherConfig = configs
          .where((c) => c.provider == 'qweather')
          .firstOrNull;
      if (qweatherConfig != null) {
        await service.saveApiConfig(
          provider: 'qweather',
          apiKey: qweatherConfig.apiKey,
          baseUrl: qweatherConfig.baseUrl,
          isActive: false,
        );
      }
    }

    ref.invalidate(_activeWeatherApiProvider);
    ref.invalidate(_allApiConfigsProvider);
    ref.invalidate(apiStatusProvider);

    if (mounted) {
      final label = provider == 'qweather' ? '和风天气' : 'Open-Meteo';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('已切换到 $label'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Save API Key
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _saveQweatherKey() async {
    final key = _qweatherKeyController.text.trim();
    if (key.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('请输入 API Key'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() => _isSavingQweatherKey = true);
    try {
      final host = _qweatherHostController.text.trim();
      final service = ref.read(weatherServiceProvider);
      await service.saveApiConfig(
        provider: 'qweather',
        apiKey: key,
        baseUrl: host.isEmpty ? null : host,
        isActive: true,
      );
      await service.saveApiConfig(provider: 'open_meteo', isActive: false);

      ref.invalidate(_activeWeatherApiProvider);
      ref.invalidate(_allApiConfigsProvider);
      ref.invalidate(apiStatusProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('API Key 已保存，已切换到和风天气'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('保存失败: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSavingQweatherKey = false);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Refresh Weather
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _locateByGps() async {
    setState(() => _isRefreshing = true);
    try {
      final service = ref.read(weatherServiceProvider);
      final result = await service.locateByGps();

      if (result != null) {
        final extraData = await service.refreshWeather();
        if (extraData != null) {
          ref.read(weatherExtraProvider.notifier).state = WeatherExtraState(
            extraData,
          );
        }
        ref.invalidate(todayWeatherProvider);
        ref.invalidate(weatherExtraAutoProvider);
        if (mounted) {
          final city = result['city'] as String;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('已定位到: $city'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('定位失败，请允许位置权限或手动搜索城市'),
              backgroundColor: AppColors.warning,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('定位出错: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  Future<void> _refreshWeather() async {
    setState(() => _isRefreshing = true);
    _refreshAnimController.repeat();

    try {
      final service = ref.read(weatherServiceProvider);
      final extraData = await service.refreshWeather();
      debugPrint(
        'refreshWeather 返回: ${extraData != null}, air=${extraData?['air'] != null}, indices=${extraData?['indices'] != null}',
      );
      if (extraData != null) {
        ref.read(weatherExtraProvider.notifier).state = WeatherExtraState(
          extraData,
        );
      }
      ref.invalidate(todayWeatherProvider);
      ref.invalidate(weatherExtraAutoProvider);
      ref.invalidate(apiStatusProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('天气已更新'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final errorMsg = e.toString().contains('天气')
            ? '天气数据获取失败，请检查网络或 API 配置'
            : '更新失败';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg), backgroundColor: AppColors.danger),
        );
      }
    } finally {
      _refreshAnimController.stop();
      _refreshAnimController.reset();
      if (mounted) setState(() => _isRefreshing = false);
    }
  }
}
