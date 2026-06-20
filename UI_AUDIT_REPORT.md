# Growth OS UI 审计报告

**审计日期**: 2026-06-20
**审计范围**: dashboard, diet, sleep, water, music, calendar sheet
**验证**: `flutter test test/widgets` — 49/49 全部通过 ✅

---

## P0 — 会导致崩溃或功能不可用

### 1. Water ProgressCard 使用绝对定位，窄屏必溢出

- **文件**: `lib/features/health/widgets/water_reminder_timer_widgets.dart:78-175`
- **问题**: `_ProgressCard` 使用 `Positioned(right: 10, top: 18, width: 206, height: 196)` 绝对定位猫咪图片，同时左侧文字用 `Positioned(left: 24, top: 24, right: 172)`。在 360px 宽度设备上，206 + 10 = 216px 仅图片就占 60%，加上左侧文字区域 `right: 172` 仅剩 188-24=164px，大字号 `fontSize: 50` 的 `FittedBox` 虽然能缩放，但进度条 `Positioned(left: 24, right: 206, bottom: 30)` 在窄屏上仅 `360-24-206=130px`，会严重挤压。
- **为什么是问题**: 360px 是 Android 小屏标准宽度，绝对定位无弹性，文字和进度条会重叠或被裁切。
- **建议**: 将 `_ProgressCard` 改为 `Row` + `Expanded` 布局，左侧文字 Expanded 占 flex:1，右侧图片用 `SizedBox(width: constraints.maxWidth * 0.4)` 自适应。
- **验证**: 在 360px 宽度下 `flutter run` 截图检查。

### 2. Water _TodayRecordsCard 的 Row(children: const) 编译问题

- **文件**: `lib/features/health/widgets/water_reminder_timer_widgets.dart:579`
- **问题**: `Row(children: const [` 内含 `Spacer()` — `Spacer` 不是 const 构造。Dart 3.x 可能允许但会导致运行时异常。
- **为什么是问题**: `const Row` 内的 `Spacer()` 在编译期无法正确初始化。
- **建议**: 去掉 `const`，改为 `Row(children: [`。
- **验证**: `flutter analyze lib/features/health/widgets/water_reminder_timer_widgets.dart`

---

## P1 — 视觉明显异常或影响用户体验

### 3. Water _TopBar 标题 fontSize: 28 + fontWeight: w900 在窄屏溢出

- **文件**: `lib/features/health/widgets/water_reminder_timer_widgets.dart:27-36`
- **问题**: `_TopBar` 中标题 `Text` 被 `Expanded` 包裹，`fontSize: 28, fontWeight: w900`，如果标题文字较长（如"饮水提醒设置"6字），在 360px 宽度减去两侧 52px 按钮后仅剩 256px，大字号可能溢出。
- **为什么是问题**: 无 `maxLines` 和 `overflow: TextOverflow.ellipsis` 保护。
- **建议**: 给标题 `Text` 添加 `maxLines: 1, overflow: TextOverflow.ellipsis`。
- **验证**: `flutter run` 在 360px 设备上查看饮水提醒页。

### 4. Sleep _buildEmptyTrend 使用固定高度 180 且无主题色

- **文件**: `lib/features/health/sleep_page.dart:557-577`
- **问题**: `_buildEmptyTrend` 使用 `_lavenderLight` 作为背景色，但 `_lavenderLight` 是 `context.growthColors.softPurple`，在暗色模式下可能与卡片背景对比度不足。且固定 `height: 180` 不适配小屏。
- **为什么是问题**: 暗色模式下 softPurple 作为 Container 背景可能导致文字不可读。
- **建议**: 改用 `colors.card` 背景 + `colors.border` 边框，与有数据时的卡片风格一致；或改用 `constraints` 自适应高度。
- **验证**: 切换暗色模式查看睡眠页空趋势状态。

### 5. Music Float Card 展开卡固定 286px 高度

- **文件**: `lib/features/music/widgets/music_float_card.dart:788`
- **问题**: `_VinylVisualizer` 使用 `SizedBox(height: 286)` 包含 310x310 的唱片图片，`clipBehavior: Clip.none` 允许溢出。在小屏手机上，浮卡展开后可能覆盖底部导航栏。
- **为什么是问题**: 286px 高度 + 底部 padding 在 667px 高度的 iPhone SE 上几乎占满屏幕。
- **建议**: 将唱片区域高度改为 `MediaQuery.sizeOf(context).height * 0.35`，并确保展开卡总高度不超过屏幕 50%。
- **验证**: 在 iPhone SE (667px) 上展开音乐浮卡。

### 6. Water _AmountChip 固定 height: 72 + fontSize: 21

- **文件**: `lib/features/health/widgets/water_reminder_timer_widgets.dart:335, 365`
- **问题**: `_AmountChip` 固定 `height: 72`，内部文字 `fontSize: 21, fontWeight: w900`。三个 chip 在 Row 中各占 `Expanded`，在 360px 宽度下每个仅约 100px 宽，大字号 + 图标可能溢出。
- **为什么是问题**: 已有 `FittedBox(fit: BoxFit.scaleDown)` 保护，但 `fontSize: 21` 起始值过大，缩放后可能变得过小影响可读性。
- **建议**: 将 `fontSize` 从 21 降为 17，减少缩放幅度。
- **验证**: 在 360px 设备上查看快速打卡区。

### 7. Sleep chart 固定 height: 260 不适配小屏

- **文件**: `lib/features/health/sleep_page.dart:395`
- **问题**: 趋势图表 `SizedBox(height: 260)` 固定高度，在小屏设备上加上上方标题、图例、范围选择器和下方平均值，总高度可能超出可视区域。
- **为什么是问题**: 用户需要滚动才能看到图表下方的平均值数据。
- **建议**: 改为 `MediaQuery.sizeOf(context).height * 0.3`，最小 200px。
- **验证**: 在 667px 高度设备上查看睡眠趋势。

### 8. Diet chart 固定 height: 220

- **文件**: `lib/features/health/diet_page.dart:846`
- **问题**: 卡路里/饮水量图表 `SizedBox(height: 220)` 固定高度，与睡眠图表类似的小屏适配问题。
- **为什么是问题**: 同上。
- **建议**: 同上，改为相对高度。
- **验证**: 在 667px 高度设备上查看饮食趋势。

---

## P2 — 视觉一致性或代码质量

### 9. Water 页面使用硬编码颜色而非主题色

- **文件**: `lib/features/health/widgets/water_reminder_timer_widgets.dart:3-8, 60, 140, 148, 161, 225, 264, 300, 337, 341, 529, 553, 592, 596, 646, 651, 738, 825, 831, 934, 940, 981, 993, 1019, 1074`
- **问题**: `_WaterColors` 定义了 4 个硬编码颜色 (`#63BE5A`, `#294527`, `#40533B`, `#8A9387`)，整个文件大量使用 `Color(0xFF...)` 硬编码，未接入 `context.growthColors` 主题系统。
- **为什么是问题**: 暗色模式下这些硬编码颜色（深绿背景 `#294527`、绿色文字 `#40533B`）会完全不可读。与全局主题不一致。
- **建议**: 将 `_WaterColors` 映射到 `context.growthColors` 的对应语义色（`colors.success` → primary, `colors.textPrimary` → dark, `colors.textSecondary` → muted）。
- **验证**: 切换暗色模式查看饮水提醒页。

### 10. Sleep 页面 _lavenderLight 用于 Container 背景对比度不足

- **文件**: `lib/features/health/sleep_page.dart:558-560, 590-594`
- **问题**: `_buildEmptyTrend` 和 `_buildSleepSuggestions` 使用 `_lavenderLight` (`context.growthColors.softPurple`) 作为容器背景色，但未设置边框，在浅色模式下与页面背景 `colors.paper` 对比度可能不足。
- **为什么是问题**: 低对比度导致用户难以区分内容区域边界。
- **建议**: 添加 `border: Border.all(color: colors.sleep.withValues(alpha: 0.14))` 与趋势图表卡片保持一致。
- **验证**: 肉眼检查睡眠页空趋势和建议区域。

### 11. Dashboard FAB 嵌套过深 (6 层 Container)

- **文件**: `lib/features/dashboard/dashboard_page.dart:95-156`
- **问题**: FAB 使用 `Container` → `ClipOval` → `BackdropFilter` → `Container` → `Container` → `Center` → `Icon`，共 7 层嵌套实现液态玻璃效果。
- **为什么是问题**: 过深嵌套增加布局计算开销，`BackdropFilter` 在低端设备上可能导致掉帧。且三层 `Container` 的渐变叠加效果在暗色模式下可能不明显。
- **建议**: 合并三层 `Container` 为一个，使用 `BoxDecoration` 的 `gradient` + `border` 一次性完成。
- **验证**: `flutter run --profile` 在低端设备上检查 FAB 点击帧率。

### 12. Calendar Sheet 网格 childAspectRatio: 0.86 可能导致文字截断

- **文件**: `lib/shared/widgets/common/growth_calendar_sheet.dart:312`
- **问题**: 日历网格 `childAspectRatio: 0.86`，单元格内包含日期数字 (14px)、农历/节日标签 (9.5px)、活动点 (5px) 和间距，在窄屏下每个单元格宽度约 `(360-40-36)/7 ≈ 40.6px`，高度约 `40.6/0.86 ≈ 47.2px`，农历标签可能被截断。
- **为什么是问题**: 节日名称较长时（如"中秋节"3字）在 9.5px 字号下约 28.5px，加上 padding 后可能溢出 40.6px 宽度。
- **建议**: 已有 `overflow: TextOverflow.ellipsis` 保护，但建议将 `fontSize` 从 9.5 降为 9，或增大 `crossAxisSpacing` 减少单元格数量。
- **验证**: 查看包含长节日名的月份。

### 13. Music Float Card 唱片 310x310 溢出父容器

- **文件**: `lib/features/music/widgets/music_float_card.dart:821-823`
- **问题**: `_VinylVisualizer` 使用 `SizedBox(height: 286)` 包含 `Image(width: 310, height: 310)` 的唱片光晕图片，配合 `clipBehavior: Clip.none`。310px 超出父容器 286px，会在上下各溢出 12px。
- **为什么是问题**: `Clip.none` 允许溢出，但溢出部分可能被其他组件遮挡或导致触摸区域异常。
- **建议**: 将光晕图片尺寸缩小为 280px，与父容器对齐；或使用 `OverflowBox` 显式控制溢出。
- **验证**: 展开音乐浮卡后检查唱片边缘是否被裁切。

### 14. Water _ProgressCard 内 FittedBox 缩放后文字可读性

- **文件**: `lib/features/health/widgets/water_reminder_timer_widgets.dart:131-156`
- **问题**: `FittedBox(fit: BoxFit.scaleDown)` 包裹 `fontSize: 50` 的水量数字，在 360px 窄屏上可能缩放到 24px 以下，与旁边 `fontSize: 25` 的 `/ xxx ml` 比例失调。
- **为什么是问题**: 缩放后主数字和单位文字大小接近，视觉层次消失。
- **建议**: 将 `fontSize: 50` 降为 36，`fontSize: 25` 降为 18，减少缩放依赖。
- **验证**: 在 360px 设备上查看饮水进度卡。

---

## P3 — 代码风格与可维护性

### 15. Sleep 页面大量中文 Unicode 转义

- **文件**: `lib/features/health/widgets/water_reminder_timer_widgets.dart:589, 621, 642, 661` 和多处
- **问题**: 部分中文字符串使用 Unicode 转义 (`\u996e\u6c34\u91cf` = "饮水量")，可读性差。
- **为什么是问题**: 后续维护者难以理解转义后的字符串含义。
- **建议**: 统一使用直接中文字符串（确保文件编码为 UTF-8）。
- **验证**: 无功能影响，纯代码质量。

### 16. Diet 页面 `_buildTodayStats` 重复读取 ref.watch

- **文件**: `lib/features/health/diet_page.dart:517-526`
- **问题**: `_buildTodayStats` 接收 `todayRecords`, `todayCount`, `todayScore` 参数，但内部又通过 `whenOrNull` 提取值，与直接在 build 中 `ref.watch` 无异。
- **为什么是问题**: 传参 + whenOrNull 双重解包，代码冗余。
- **建议**: 直接在方法内 `ref.watch` 或去掉 `AsyncValue` 包装。
- **验证**: 无功能影响。

### 17. Water _SettingRow 使用 `const Color(0xFFEAF7DE)` 硬编码

- **文件**: `lib/features/health/widgets/water_reminder_timer_widgets.dart:529`
- **问题**: 图标背景色 `const Color(0xFFEAF7DE)` 是硬编码的浅绿色，在暗色模式下会显得突兀。
- **为什么是问题**: 暗色模式下浅绿色背景与深色卡片不协调。
- **建议**: 改为 `colors.success.withValues(alpha: 0.12)`。
- **验证**: 切换暗色模式查看设置行。

---

## 验证命令清单

```bash
# 1. 运行 widget 测试
cd F:\opencode\GROS\growth_os && flutter test test/widgets

# 2. 静态分析
flutter analyze lib/features/health/ lib/features/music/ lib/features/dashboard/ lib/shared/widgets/common/

# 3. 窄屏溢出检查 (需真机或模拟器)
flutter run -d <device> --dart-define=SCREEN_WIDTH=360

# 4. 暗色模式检查
flutter run -d <device> --dart-define=THEME=dark

# 5. 资源冗余扫描
find assets/ -name "*.png" -size +500k | head -20
```

---

## 总结

| 等级 | 数量 | 关键项 |
|------|------|--------|
| P0 | 2 | Water ProgressCard 绝对定位溢出, const Row 内 Spacer |
| P1 | 6 | 窄屏大字号溢出, 固定高度不适配, 浮卡覆盖导航栏 |
| P2 | 6 | 硬编码颜色/暗色模式, 对比度不足, 嵌套过深, 图片溢出 |
| P3 | 3 | Unicode 转义, 代码冗余 |

**最高优先修复**: Water 进度卡绝对定位 (P0 #1) 和硬编码颜色 (P2 #9)，这两个在暗色模式 + 窄屏设备上会同时触发。
