import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/design/design.dart';
import '../../../core/database/app_database.dart';
import '../../../core/services/weather_service.dart';
import '../../../shared/widgets/common/error_retry_widget.dart';

class WeatherSettingsSectionHeader extends StatelessWidget {
  const WeatherSettingsSectionHeader({
    required this.title,
    required this.icon,
    super.key,
  });

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: colors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: colors.primary),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(title, style: AppTextStyles.sectionTitle),
      ],
    );
  }
}

class WeatherCurrentCard extends StatelessWidget {
  const WeatherCurrentCard({required this.weatherAsync, super.key});

  final AsyncValue<DailyWeather?> weatherAsync;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colors.primaryLight, colors.primaryDark],
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
            color: colors.primary.withValues(alpha: 0.3),
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
                    color: colors.textOnAccent.withValues(alpha: 0.6),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    '暂无天气数据',
                    style: TextStyle(
                      color: colors.textOnAccent.withValues(alpha: 0.8),
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '点击右上角刷新获取',
                    style: TextStyle(
                      color: colors.textOnAccent.withValues(alpha: 0.5),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            );
          }

          final emoji = WeatherService.getWeatherEmoji(weather.weatherCode);
          final now = DateTime.now();
          final timeStr =
              '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
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
                            style: TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.w700,
                              color: colors.textOnAccent,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            weather.weatherType,
                            style: TextStyle(
                              fontSize: 16,
                              color: colors.textOnAccent.withValues(
                                alpha: 0.85,
                              ),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
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
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: colors.textOnAccent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.location_on_rounded,
                        size: 14,
                        color: colors.textOnAccent.withValues(alpha: 0.8),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        weather.city ?? '未知城市',
                        style: TextStyle(
                          fontSize: 13,
                          color: colors.textOnAccent.withValues(alpha: 0.8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.access_time_rounded,
                        size: 14,
                        color: colors.textOnAccent.withValues(alpha: 0.6),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '更新于 $timeStr',
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.textOnAccent.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => Padding(
          padding: const EdgeInsets.all(40),
          child: Center(
            child: CircularProgressIndicator(color: colors.textOnAccent),
          ),
        ),
        error: (_, _) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 40,
                color: colors.textOnAccent.withValues(alpha: 0.6),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                '加载失败',
                style: TextStyle(
                  color: colors.textOnAccent.withValues(alpha: 0.8),
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class WeatherExtraChip extends StatelessWidget {
  const WeatherExtraChip({
    required this.icon,
    required this.value,
    this.label,
    super.key,
  });

  final IconData icon;
  final String? label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colors.textOnAccent.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: colors.textOnAccent.withValues(alpha: 0.8),
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                color: colors.textOnAccent.withValues(alpha: 0.9),
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
}

class WeatherCitySelectorCard extends StatelessWidget {
  const WeatherCitySelectorCard({
    required this.weather,
    required this.onShowCitySearch,
    required this.onLocateByGps,
    super.key,
  });

  final DailyWeather? weather;
  final VoidCallback onShowCitySearch;
  final VoidCallback onLocateByGps;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    final city = weather?.city ?? '未获取';

    return WeatherSettingsCard(
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: colors.danger.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(
              Icons.location_on_rounded,
              color: colors.danger,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: GestureDetector(
              onTap: onShowCitySearch,
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
                        color: colors.textTertiary,
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
              color: colors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: IconButton(
              icon: const Icon(Icons.my_location_rounded, size: 20),
              color: colors.primary,
              tooltip: '自动定位',
              onPressed: onLocateByGps,
            ),
          ),
        ],
      ),
    );
  }
}

class WeatherApiCard extends StatelessWidget {
  const WeatherApiCard({
    required this.icon,
    required this.iconColor,
    required this.name,
    required this.description,
    required this.isRecommended,
    required this.provider,
    required this.currentProvider,
    required this.hasApiKey,
    required this.controller,
    required this.isObscure,
    required this.isSaving,
    required this.onProviderChanged,
    required this.onToggleObscure,
    required this.onSave,
    this.hostController,
    super.key,
  });

  final IconData icon;
  final Color iconColor;
  final String name;
  final String description;
  final bool isRecommended;
  final String provider;
  final String currentProvider;
  final bool hasApiKey;
  final TextEditingController? controller;
  final bool isObscure;
  final bool isSaving;
  final ValueChanged<String> onProviderChanged;
  final VoidCallback? onToggleObscure;
  final VoidCallback? onSave;
  final TextEditingController? hostController;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    final isSelected = currentProvider == provider;
    final isQweather = provider == 'qweather';
    final keyController = controller;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: isSelected ? colors.primary : colors.border,
          width: isSelected ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: isSelected ? 0.22 : 0.12),
            blurRadius: isSelected ? 24 : 14,
            offset: Offset(0, isSelected ? 10 : 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                            const _RecommendedBadge(),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(description, style: AppTextStyles.caption),
                    ],
                  ),
                ),
                RadioGroup<String>(
                  groupValue: currentProvider,
                  onChanged: (value) {
                    if (value != null) onProviderChanged(value);
                  },
                  child: Radio<String>(
                    value: provider,
                    activeColor: colors.primary,
                  ),
                ),
              ],
            ),
            if (isQweather && isSelected && keyController != null) ...[
              const SizedBox(height: AppSpacing.md),
              Divider(color: colors.divider, height: 1),
              const SizedBox(height: AppSpacing.md),
              _StatusBadge(isConfigured: hasApiKey),
              const SizedBox(height: AppSpacing.md),
              if (hostController != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: TextField(
                    controller: hostController,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: 'API Host',
                      hintText: 'https://devapi.qweather.com',
                      helperText: '在 QWeather 控制台复制专属 Host',
                      helperMaxLines: 2,
                      prefixIcon: Icon(
                        Icons.link_rounded,
                        color: colors.textTertiary,
                      ),
                      filled: true,
                      fillColor: colors.surfaceVariant,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
              _ApiKeyInput(
                controller: keyController,
                isObscure: isObscure,
                hintText: '输入和风天气 API Key',
                onToggleObscure: onToggleObscure!,
                onSave: onSave!,
                isSaving: isSaving,
              ),
            ],
            if (!isQweather) ...[
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    size: 16,
                    color: colors.success,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '始终可用，无需配置',
                    style: TextStyle(
                      fontSize: 13,
                      color: colors.success,
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
}

class WeatherSearchHistorySection extends StatelessWidget {
  const WeatherSearchHistorySection({
    required this.historyAsync,
    required this.onDeleteHistoryItem,
    required this.onClearSearchHistory,
    super.key,
  });

  final AsyncValue<List<WeatherSearchHistory>> historyAsync;
  final ValueChanged<int> onDeleteHistoryItem;
  final VoidCallback onClearSearchHistory;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return historyAsync.when(
      data: (history) {
        if (history.isEmpty) {
          return WeatherSettingsCard(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.history_rounded,
                  size: 18,
                  color: colors.textTertiary,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  '暂无搜索历史',
                  style: TextStyle(fontSize: 14, color: colors.textTertiary),
                ),
              ],
            ),
          );
        }

        return WeatherSettingsCard(
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
                            color: colors.primary,
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
                            onPressed: () => onDeleteHistoryItem(item.id),
                            icon: Icon(
                              Icons.close_rounded,
                              size: 18,
                              color: colors.textTertiary,
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
                        color: colors.divider,
                        height: 1,
                        indent: AppSpacing.lg + 26,
                      ),
                  ],
                );
              }),
              if (history.length > 1) ...[
                Divider(color: colors.divider, height: 1),
                InkWell(
                  onTap: onClearSearchHistory,
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
                          color: colors.danger,
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
      loading: () => const WeatherSettingsCard(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.lg),
            child: CircularProgressIndicator(),
          ),
        ),
      ),
      error: (_, _) => const ErrorRetryWidget(),
    );
  }
}

class WeatherApiKeyGuide extends StatelessWidget {
  const WeatherApiKeyGuide({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return Container(
      decoration: BoxDecoration(
        color: colors.softPurple,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colors.primary.withValues(alpha: 0.15)),
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
              color: colors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(
              Icons.lightbulb_rounded,
              color: colors.primary,
              size: 20,
            ),
          ),
          title: Text(
            '如何获取 API Key？',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: colors.textPrimary,
            ),
          ),
          iconColor: colors.primary,
          collapsedIconColor: colors.textTertiary,
          children: const [
            _GuideSection(
              icon: Icons.cloud_rounded,
              title: '和风天气',
              steps: ['访问 dev.qweather.com', '注册账号并登录', '创建项目获取 API Key'],
            ),
          ],
        ),
      ),
    );
  }
}

class WeatherCitySearchResultTile extends StatelessWidget {
  const WeatherCitySearchResultTile({
    required this.city,
    required this.onTap,
    super.key,
  });

  final Map<String, dynamic> city;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    final name = city['name'] as String;
    final admin1 = city['admin1'] as String? ?? '';
    final country = city['country'] as String? ?? '';
    final subtitle = [admin1, country].where((s) => s.isNotEmpty).join(' · ');

    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: colors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Icon(
          Icons.location_city_rounded,
          color: colors.primary,
          size: 18,
        ),
      ),
      title: Text(
        name,
        style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w500),
      ),
      subtitle: subtitle.isNotEmpty
          ? Text(subtitle, style: AppTextStyles.caption)
          : null,
      trailing: Icon(
        Icons.arrow_forward_ios_rounded,
        size: 14,
        color: colors.textTertiary,
      ),
      onTap: onTap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
    );
  }
}

class WeatherSettingsCard extends StatelessWidget {
  const WeatherSettingsCard({required this.child, this.padding, super.key});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return Container(
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.14),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Padding(
            padding: padding ?? const EdgeInsets.all(AppSpacing.lg),
            child: child,
          ),
        ),
      ),
    );
  }
}

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
    final colors = context.growthColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colors.textOnAccent.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: colors.textOnAccent.withValues(alpha: 0.8),
          ),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: colors.textOnAccent,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecommendedBadge extends StatelessWidget {
  const _RecommendedBadge();

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '推荐',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: colors.primary,
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.isConfigured});

  final bool isConfigured;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isConfigured
            ? colors.success.withValues(alpha: 0.1)
            : colors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isConfigured
                ? Icons.check_circle_rounded
                : Icons.info_outline_rounded,
            size: 14,
            color: isConfigured ? colors.success : colors.warning,
          ),
          const SizedBox(width: 4),
          Text(
            isConfigured ? '已配置' : '未配置',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isConfigured ? colors.success : colors.warning,
            ),
          ),
        ],
      ),
    );
  }
}

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
    final colors = context.growthColors;
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            textInputAction: TextInputAction.next,
            obscureText: isObscure,
            style: const TextStyle(fontSize: 14),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: TextStyle(color: colors.textHint, fontSize: 13),
              prefixIcon: Icon(
                Icons.key_rounded,
                size: 18,
                color: colors.textTertiary,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  isObscure
                      ? Icons.visibility_off_rounded
                      : Icons.visibility_rounded,
                  size: 18,
                  color: colors.textTertiary,
                ),
                onPressed: onToggleObscure,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.sm),
                borderSide: BorderSide(color: colors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.sm),
                borderSide: BorderSide(color: colors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.sm),
                borderSide: BorderSide(color: colors.primary, width: 1.5),
              ),
              filled: true,
              fillColor: colors.surfaceVariant,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        SizedBox(
          height: 44,
          child: FilledButton(
            onPressed: isSaving ? null : onSave,
            style: FilledButton.styleFrom(
              backgroundColor: colors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            child: isSaving
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colors.textOnAccent,
                    ),
                  )
                : const Text('保存', style: TextStyle(fontSize: 13)),
          ),
        ),
      ],
    );
  }
}

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
    final colors = context.growthColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: colors.primary),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
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
                  '${entry.key + 1}.',
                  style: TextStyle(fontSize: 13, color: colors.primary),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    entry.value,
                    style: TextStyle(fontSize: 13, color: colors.textSecondary),
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
