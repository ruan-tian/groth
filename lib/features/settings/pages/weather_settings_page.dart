import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/design/design.dart';
import '../../../core/database/app_database.dart';
import '../../../core/services/weather_service.dart';
import '../../../shared/providers/weather_provider.dart';
import '../../../shared/providers/repository_providers.dart';

// ── Providers ───────────────────────────────────────────────────────────────

final _activeWeatherApiProvider = FutureProvider<ApiConfig?>((ref) async {
  final repo = ref.watch(apiConfigRepositoryProvider);
  return repo.getActiveWeatherConfig();
});

final _allApiConfigsProvider = FutureProvider<List<ApiConfig>>((ref) async {
  final repo = ref.watch(apiConfigRepositoryProvider);
  return repo.getAllConfigs();
});

final _searchHistoryProvider =
    FutureProvider<List<WeatherSearchHistory>>((ref) async {
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
  final _qweatherHostController = TextEditingController(text: 'https://devapi.qweather.com');
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

    final qweatherConfig =
        configs.where((c) => c.provider == 'qweather').firstOrNull;
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
    final qweatherConfig =
        configs.where((c) => c.provider == 'qweather').firstOrNull;
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
          _buildCurrentWeatherCard(weatherAsync),
          // ── 空气 + 指数 — 直接 inline watch，确保重建 ──
          if (extra?.aqiLabel != null || extra?.clothingSuggestion != null)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.md),
              child: Row(
                children: [
                  if (extra?.aqiLabel != null)
                    Expanded(child: _buildExtraChip(Icons.air_rounded, '空气', extra!.aqiLabel!)),
                  if (extra?.aqiLabel != null && extra?.clothingSuggestion != null)
                    const SizedBox(width: AppSpacing.sm),
                  if (extra?.clothingSuggestion != null)
                    Expanded(child: _buildExtraChip(Icons.checkroom_rounded, '穿衣', extra!.clothingSuggestion!)),
                ],
              ),
            ),
          const SizedBox(height: AppSpacing.xxl),

          // ── 2. City Selector ──────────────────────────────────────────
          _buildSectionHeader('定位设置', Icons.location_on_outlined),
          const SizedBox(height: AppSpacing.md),
          _buildCitySelector(weatherAsync.valueOrNull),
          const SizedBox(height: AppSpacing.xxl),

          // ── 3. Weather API Services ───────────────────────────────────
          _buildSectionHeader('天气 API 服务', Icons.cloud_outlined),
          const SizedBox(height: AppSpacing.md),
          _buildWeatherApiCard(
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
            onToggleObscure: () =>
                setState(() => _isObscureQweatherKey = !_isObscureQweatherKey),
            onSave: () => _saveQweatherKey(),
            hostController: _qweatherHostController,
          ),
          const SizedBox(height: AppSpacing.md),
          _buildWeatherApiCard(
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
            onToggleObscure: null,
            onSave: null,
          ),
          const SizedBox(height: AppSpacing.xxl),

          // ── 5. Search History ─────────────────────────────────────────
          _buildSectionHeader('搜索历史', Icons.history_rounded),
          const SizedBox(height: AppSpacing.md),
          _buildSearchHistorySection(searchHistoryAsync),
          const SizedBox(height: AppSpacing.xxl),

          // ── 6. API Key Guide ──────────────────────────────────────────
          _buildApiKeyGuide(),
          const SizedBox(height: AppSpacing.xxxl),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Section Header
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: AppColors.primary),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(title, style: AppTextStyles.sectionTitle),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Current Weather Card
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildCurrentWeatherCard(AsyncValue<DailyWeather?> weatherAsync) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF7C6BF0), Color(0xFF5A4BD4)],
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: weatherAsync.when(
        data: (weather) {
          if (weather == null) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(
                    Icons.cloud_off_rounded,
                    size: 40,
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    '暂无天气数据',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '点击右上角刷新获取',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            );
          }

          final emoji =
              WeatherService.getWeatherEmoji(weather.weatherCode);
          final now = DateTime.now();
          final timeStr =
              '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Top row: emoji + temp + weather type
                Row(
                  children: [
                    Text(emoji, style: const TextStyle(fontSize: 52)),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${weather.temperature}°C',
                            style: const TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            weather.weatherType,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white.withValues(alpha: 0.85),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Weather details chips
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _WeatherDetailChip(
                          icon: Icons.water_drop_rounded,
                          label: '湿度',
                          value: '${weather.humidity}%',
                        ),
                        const SizedBox(height: 8),
                        if (weather.windDir?.isNotEmpty == true)
                          _WeatherDetailChip(
                            icon: Icons.air_rounded,
                            label: '风向',
                            value: weather.windDir!,
                          ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Bottom row: city + time
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.location_on_rounded,
                        size: 14,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        weather.city ?? '未知城市',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.access_time_rounded,
                        size: 14,
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '更新于 $timeStr',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Padding(
          padding: EdgeInsets.all(40),
          child: Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
        ),
        error: (_, __) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 40,
                color: Colors.white.withValues(alpha: 0.6),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                '加载失败',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // City Selector
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildCitySelector(DailyWeather? weather) {
    final city = weather?.city ?? '未获取';

    return _SettingsCard(
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.danger.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: const Icon(
              Icons.location_on_rounded,
              color: AppColors.danger,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: GestureDetector(
              onTap: () => _showCitySearchSheet(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('当前城市', style: AppTextStyles.caption),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(city, style: AppTextStyles.cardTitle),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 16,
                        color: AppColors.textTertiary,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Container(
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: IconButton(
              icon: const Icon(Icons.my_location_rounded, size: 20),
              color: AppColors.primary,
              tooltip: '自动定位',
              onPressed: () => _locateByGps(),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // IP Service Card
  // ─────────────────────────────────────────────────────────────────────────

// ─────────────────────────────────────────────────────────────────────────
// Extra Data Chip
// ─────────────────────────────────────────────────────────────────────────

  Widget _buildExtraChip(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white.withValues(alpha: 0.8)),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withValues(alpha: 0.9),
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

// ─────────────────────────────────────────────────────────────────────────
// Weather API Card
// ─────────────────────────────────────────────────────────────────────────

  Widget _buildWeatherApiCard({
    required IconData icon,
    required Color iconColor,
    required String name,
    required String description,
    required bool isRecommended,
    required String provider,
    required String currentProvider,
    required bool hasApiKey,
    required TextEditingController? controller,
    required bool isObscure,
    required bool isSaving,
    required VoidCallback? onToggleObscure,
    required VoidCallback? onSave,
    TextEditingController? hostController,
  }) {
    final isSelected = currentProvider == provider;
    final isQweather = provider == 'qweather';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: isSelected ? AppColors.primary : AppColors.border,
          width: isSelected ? 1.5 : 1,
        ),
        boxShadow: isSelected ? AppColors.elevatedShadow : AppColors.cardShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(name, style: AppTextStyles.cardTitle),
                          if (isRecommended) ...[
                            const SizedBox(width: 8),
                            _RecommendedBadge(),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(description, style: AppTextStyles.caption),
                    ],
                  ),
                ),
                // Radio
                Radio<String>(
                  value: provider,
                  groupValue: currentProvider,
                  activeColor: AppColors.primary,
                  onChanged: (v) => _switchProvider(v!),
                ),
              ],
            ),

            // QWeather: Host + Key input + status
            if (isQweather && isSelected && controller != null) ...[
              const SizedBox(height: AppSpacing.md),
              Divider(color: AppColors.divider, height: 1),
              const SizedBox(height: AppSpacing.md),
              _StatusBadge(isConfigured: hasApiKey),
              const SizedBox(height: AppSpacing.md),
              if (hostController != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: TextField(
                    controller: hostController,
                    decoration: InputDecoration(
                      labelText: 'API Host',
                      hintText: 'https://devapi.qweather.com',
                      helperText: '在 QWeather 控制台复制专属 Host',
                      helperMaxLines: 2,
                      prefixIcon: Icon(Icons.link_rounded, color: AppColors.textTertiary),
                      filled: true,
                      fillColor: AppColors.surfaceVariant,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
              _ApiKeyInput(
                controller: controller,
                isObscure: isObscure,
                hintText: '输入和风天气 API Key',
                onToggleObscure: onToggleObscure!,
                onSave: onSave!,
                isSaving: isSaving,
              ),
            ],

            // Open-Meteo: always available
            if (!isQweather) ...[
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    size: 16,
                    color: AppColors.success,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '始终可用，无需配置',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.success,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Search History Section
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildSearchHistorySection(
      AsyncValue<List<WeatherSearchHistory>> historyAsync) {
    return historyAsync.when(
      data: (history) {
        if (history.isEmpty) {
          return _SettingsCard(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.history_rounded,
                  size: 18,
                  color: AppColors.textTertiary,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  '暂无搜索历史',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          );
        }

        return _SettingsCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              ...history.asMap().entries.map((entry) {
                final item = entry.value;
                final isLast = entry.key == history.length - 1;

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.md,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.location_on_rounded,
                            size: 18,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.cityName,
                                  style: AppTextStyles.body.copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                if (item.admin1?.isNotEmpty == true)
                                  Text(
                                    '${item.admin1}${item.country?.isNotEmpty == true ? ' · ${item.country}' : ''}',
                                    style: AppTextStyles.caption,
                                  ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => _deleteHistoryItem(item.id),
                            icon: Icon(
                              Icons.close_rounded,
                              size: 18,
                              color: AppColors.textTertiary,
                            ),
                            style: IconButton.styleFrom(
                              minimumSize: const Size(32, 32),
                              padding: EdgeInsets.zero,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!isLast)
                      Divider(
                        color: AppColors.divider,
                        height: 1,
                        indent: AppSpacing.lg + 26,
                      ),
                  ],
                );
              }),
              // Clear all button
              if (history.length > 1) ...[
                Divider(color: AppColors.divider, height: 1),
                InkWell(
                  onTap: _clearSearchHistory,
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(AppRadius.lg),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.md,
                    ),
                    child: Center(
                      child: Text(
                        '清空历史',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.danger,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
      loading: () => const _SettingsCard(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.lg),
            child: CircularProgressIndicator(),
          ),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // API Key Guide
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildApiKeyGuide() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.softPurple,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.xs,
          ),
          childrenPadding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          leading: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: const Icon(
              Icons.lightbulb_rounded,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          title: const Text(
            '如何获取 API Key？',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          iconColor: AppColors.primary,
          collapsedIconColor: AppColors.textTertiary,
          children: [
            _GuideSection(
              icon: Icons.cloud_rounded,
              title: '和风天气',
              steps: [
                '访问 dev.qweather.com',
                '注册账号并登录',
                '创建项目获取 API Key',
              ],
            ),
          ],
        ),
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
                            debounce = Timer(const Duration(milliseconds: 300), () {
                              _searchCities(query, searchResults, isSearching);
                            });
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
                              List<Map<String, dynamic>>>(
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
                                    return _CitySearchResultTile(
                                      city: city,
                                      onTap: () =>
                                          _selectCity(city, context),
                                    );
                                  },
                                );
                              }

                              // Show search history
                              return ref.watch(_searchHistoryProvider).when(
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
                                                  height: AppSpacing.md),
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
                                            subtitle: item.admin1?.isNotEmpty ==
                                                    true
                                                ? Text(
                                                    '${item.admin1}${item.country?.isNotEmpty == true ? ' · ${item.country}' : ''}',
                                                    style:
                                                        AppTextStyles.caption,
                                                  )
                                                : null,
                                            onTap: () => _selectCity(
                                              {
                                                'name': item.cityName,
                                                'admin1': item.admin1 ?? '',
                                                'country': item.country ?? '',
                                                'latitude': item.latitude,
                                                'longitude': item.longitude,
                                              },
                                              context,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(
                                                      AppRadius.sm),
                                            ),
                                          );
                                        },
                                      );
                                    },
                                    loading: () => const Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                    error: (_, __) => const SizedBox.shrink(),
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
      final json = await rootBundle.loadString('assets/data/chinese_cities.json');
      final allCities = (jsonDecode(json) as List).cast<Map<String, dynamic>>();
      final q = query.toLowerCase();

      results.value = allCities
          .where((c) =>
              (c['name'] as String).toLowerCase().contains(q) ||
              (c['admin1'] as String).toLowerCase().contains(q))
          .take(20)
          .map((c) => {
                'name': c['name'] as String,
                'admin1': c['admin1'] as String,
                'country': c['country'] as String? ?? '中国',
                'latitude': (c['lat'] as num).toDouble(),
                'longitude': (c['lon'] as num).toDouble(),
              })
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

    // Refresh providers
    if (extraData != null) {
      ref.read(weatherExtraProvider.notifier).state = WeatherExtraState(extraData);
    }
    ref.invalidate(todayWeatherProvider);
    ref.invalidate(weatherExtraAutoProvider);
    ref.invalidate(_searchHistoryProvider);
    ref.invalidate(apiStatusProvider);

    if (mounted) {
      Navigator.pop(sheetContext);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('已切换到 $name'),
          backgroundColor: AppColors.success,
        ),
      );
    }
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
      final qweatherConfig =
          configs.where((c) => c.provider == 'qweather').firstOrNull;
      await service.saveApiConfig(
        provider: 'qweather',
        apiKey: qweatherConfig?.apiKey,
        baseUrl: qweatherConfig?.baseUrl,
        isActive: true,
      );
      final openMeteoConfig =
          configs.where((c) => c.provider == 'open_meteo').firstOrNull;
      if (openMeteoConfig != null) {
        await service.saveApiConfig(provider: 'open_meteo', isActive: false);
      }
    } else {
      await service.saveApiConfig(provider: 'open_meteo', isActive: true);
      final qweatherConfig =
          configs.where((c) => c.provider == 'qweather').firstOrNull;
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
          ref.read(weatherExtraProvider.notifier).state = WeatherExtraState(extraData);
        }
        ref.invalidate(todayWeatherProvider);
        ref.invalidate(weatherExtraAutoProvider);
        if (mounted) {
          final city = result['city'] as String;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('已定位到: $city'), backgroundColor: AppColors.success),
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
          SnackBar(content: Text('定位出错: $e'), backgroundColor: AppColors.danger),
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
      debugPrint('refreshWeather 返回: ${extraData != null}, air=${extraData?['air'] != null}, indices=${extraData?['indices'] != null}');
      if (extraData != null) {
        ref.read(weatherExtraProvider.notifier).state = WeatherExtraState(extraData);
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
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      _refreshAnimController.stop();
      _refreshAnimController.reset();
      if (mounted) setState(() => _isRefreshing = false);
    }
  }
}

// ── Reusable Widgets ────────────────────────────────────────────────────────

/// Settings card wrapper
class _SettingsCard extends StatelessWidget {
  const _SettingsCard({
    required this.child,
    this.onTap,
    this.padding,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
        boxShadow: AppColors.cardShadow,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          onTap: onTap,
          child: Padding(
            padding: padding ??
                const EdgeInsets.all(AppSpacing.lg),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Weather detail chip for the weather card
class _WeatherDetailChip extends StatelessWidget {
  const _WeatherDetailChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white.withValues(alpha: 0.8)),
          const SizedBox(width: 4),
          Text(
            value,
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

/// Recommended badge
class _RecommendedBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '推荐',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

/// Status badge (configured / not configured)
class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.isConfigured});

  final bool isConfigured;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isConfigured
            ? AppColors.success.withValues(alpha: 0.1)
            : AppColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isConfigured ? Icons.check_circle_rounded : Icons.info_outline_rounded,
            size: 14,
            color: isConfigured ? AppColors.success : AppColors.warning,
          ),
          const SizedBox(width: 4),
          Text(
            isConfigured ? '已配置' : '未配置',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isConfigured ? AppColors.success : AppColors.warning,
            ),
          ),
        ],
      ),
    );
  }
}

/// API Key input field with visibility toggle and save button
class _ApiKeyInput extends StatelessWidget {
  const _ApiKeyInput({
    required this.controller,
    required this.isObscure,
    required this.hintText,
    required this.onToggleObscure,
    required this.onSave,
    required this.isSaving,
  });

  final TextEditingController controller;
  final bool isObscure;
  final String hintText;
  final VoidCallback onToggleObscure;
  final VoidCallback onSave;
  final bool isSaving;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            obscureText: isObscure,
            style: const TextStyle(fontSize: 14),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: TextStyle(
                color: AppColors.textHint,
                fontSize: 13,
              ),
              prefixIcon: Icon(
                Icons.key_rounded,
                size: 18,
                color: AppColors.textTertiary,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  isObscure
                      ? Icons.visibility_off_rounded
                      : Icons.visibility_rounded,
                  size: 18,
                  color: AppColors.textTertiary,
                ),
                onPressed: onToggleObscure,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.sm),
                borderSide: BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.sm),
                borderSide: BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.sm),
                borderSide: BorderSide(
                  color: AppColors.primary,
                  width: 1.5,
                ),
              ),
              filled: true,
              fillColor: AppColors.surfaceVariant,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        SizedBox(
          height: 44,
          child: FilledButton(
            onPressed: isSaving ? null : onSave,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            child: isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('保存', style: TextStyle(fontSize: 13)),
          ),
        ),
      ],
    );
  }
}

/// City search result tile
class _CitySearchResultTile extends StatelessWidget {
  const _CitySearchResultTile({
    required this.city,
    required this.onTap,
  });

  final Map<String, dynamic> city;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final name = city['name'] as String;
    final admin1 = city['admin1'] as String? ?? '';
    final country = city['country'] as String? ?? '';

    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: const Icon(
          Icons.location_city_rounded,
          color: AppColors.primary,
          size: 18,
        ),
      ),
      title: Text(
        name,
        style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w500),
      ),
      subtitle: [admin1, country]
              .where((s) => s.isNotEmpty)
              .join(' · ')
              .isNotEmpty
          ? Text(
              [admin1, country].where((s) => s.isNotEmpty).join(' · '),
              style: AppTextStyles.caption,
            )
          : null,
      trailing: Icon(
        Icons.arrow_forward_ios_rounded,
        size: 14,
        color: AppColors.textTertiary,
      ),
      onTap: onTap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
    );
  }
}

/// Guide section for API Key instructions
class _GuideSection extends StatelessWidget {
  const _GuideSection({
    required this.icon,
    required this.title,
    required this.steps,
  });

  final IconData icon;
  final String title;
  final List<String> steps;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: AppColors.primary),
            const SizedBox(width: 6),
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
        const SizedBox(height: 8),
        ...steps.asMap().entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(left: 22, bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${entry.key + 1}. ',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textTertiary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        entry.value,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
      ],
    );
  }
}
