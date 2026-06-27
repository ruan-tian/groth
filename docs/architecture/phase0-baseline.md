# Phase 0: 安全基线记录

> 记录时间：2026-06-23
> 分支：refactor/architecture-upgrade

---

## 1. dart analyze 状态

```
3 issues found:
- 2 errors: StudyRecord 类未定义
  - features/study/widgets/study_record_detail_chart.dart:6:9
  - features/study/widgets/study_record_detail_widgets.dart:6:9
- 1 info: 不必要的多个下划线
  - app/launch_intro_overlay.dart:107:26
```

**结论**：2个error是已有的编译问题，不是本次重构引入的。

---

## 2. flutter test 状态

```
314 tests passed
2 tests skipped
28 tests failed
```

**失败原因分类**：
- `ProviderContainer already disposed` 错误（多个测试）
- `StudyRecord` 类未定义（2个文件编译失败）

**结论**：28个失败是已有的测试问题，不是本次重构引入的。

---

## 3. 依赖违规清单

### 3.1 core → features（4处）

| 文件 | 违规依赖 |
|------|----------|
| `core/repositories/music_repository.dart:4` | `features/music/utils/default_music_seed.dart` |
| `core/repositories/knowledge_source_repository.dart:5` | `features/study/utils/knowledge_source_chunker.dart` |
| `core/repositories/knowledge_source_repository.dart:6` | `features/study/utils/knowledge_tfidf_index.dart` |
| `core/repositories/knowledge_source_repository.dart:7` | `features/study/utils/knowledge_synonyms.dart` |

### 3.2 shared → features（10处）

| 文件 | 违规依赖 |
|------|----------|
| `shared/providers/service_providers.dart:9` | `features/ai/services/ai_analysis_card_service.dart` |
| `shared/providers/service_providers.dart:10` | `features/ai/services/knowledge_context_service.dart` |
| `shared/providers/settings_provider.dart:7` | `features/focus/models/study_mode.dart` |
| `shared/providers/settings_facade.dart:6` | `features/focus/models/study_mode.dart` |
| `shared/providers/knowledge_card_provider.dart:7` | `features/study/utils/knowledge_card_assets.dart` |
| `shared/widgets/common/growth_calendar_sheet.dart:10` | `features/dashboard/widgets/add_task_dialog.dart` |
| `shared/providers/knowledge_card_ai_provider.dart:4` | `features/study/services/knowledge_card_ai_service.dart` |
| `shared/providers/knowledge_card_ai_provider.dart:5` | `features/study/services/knowledge_v3_ai_service.dart` |
| `shared/providers/focus_provider.dart:10` | `features/plan/services/reminder_notification_service.dart` |
| `shared/providers/pet_diary_provider.dart:2` | 注释引用 features/pet |

**总计**：14处依赖违规

---

## 4. 页面直连数据库清单（34处）

| 文件 | 导入路径 |
|------|----------|
| `features/journal/pages/edit_journal_page.dart:10` | `core/database/app_database.dart` |
| `features/journal/pages/write_journal_page.dart:10` | `core/database/app_database.dart` |
| `features/health/pages/add_sleep_record_page.dart:7` | `core/database/app_database.dart` |
| `features/health/pages/add_diet_record_page.dart:8` | `core/database/app_database.dart` |
| `features/fitness/pages/add_fitness_record_page.dart:8` | `core/database/app_database.dart` |
| `features/study/pages/add_study_record_page.dart:7` | `core/database/app_database.dart` |
| `features/fitness/pages/add_body_metric_page.dart:8` | `core/database/app_database.dart` |
| `features/settings/pages/backup_page.dart:10` | `core/database/app_database.dart` |
| `features/settings/pages/ai_config_page.dart:8` | `core/database/app_database.dart` |
| `features/settings/pages/profile_page.dart:12` | `core/database/app_database.dart` |
| `features/fitness/fitness_page.dart:8` | `core/database/app_database.dart` |
| `features/study/study_page.dart:7` | `core/database/app_database.dart` |
| `features/health/sleep_page.dart:6` | `core/database/app_database.dart` |
| `features/health/diet_page.dart:10` | `core/database/app_database.dart` |
| `features/fitness/pages/weekly_fitness_page.dart:6` | `core/database/app_database.dart` |
| `features/focus/pages/focus_session_page.dart:10` | `core/database/app_database.dart` |
| `features/study/pages/recent_records_page.dart:6` | `core/database/app_database.dart` |
| `features/journal/pages/journal_detail_page.dart:9` | `core/database/app_database.dart` |
| `features/journal/journal_page.dart:9` | `core/database/app_database.dart` |
| `features/health/pages/all_diet_records_page.dart:5` | `core/database/app_database.dart` |
| `features/fitness/pages/fitness_training_timer_page.dart:7` | `core/database/app_database.dart` |
| `features/fitness/pages/fitness_record_detail_page.dart:6` | `core/database/app_database.dart` |
| `features/fitness/pages/all_fitness_records_page.dart:6` | `core/database/app_database.dart` |
| `features/ai/pages/ai_analysis_page.dart:5` | `core/database/app_database.dart` |
| `features/health/pages/sleep_reminder_timer_page.dart:7` | `core/database/app_database.dart` |
| `features/music/pages/music_playlist_page.dart:5` | `core/database/app_database.dart` |
| `features/settings/pages/weather_settings_page.dart:8` | `core/database/app_database.dart` |
| `features/dashboard/pages/task_history_page.dart:5` | `core/database/app_database.dart` |
| `features/fitness/pages/body_metric_detail_page.dart:7` | `core/database/app_database.dart` |
| `features/music/pages/music_favorites_page.dart:5` | `core/database/app_database.dart` |
| `features/health/pages/sleep_history_page.dart:5` | `core/database/app_database.dart` |
| `features/focus/focus_page.dart:6` | `core/database/app_database.dart` |
| `features/pet/pages/pet_diary_page.dart:8` | `core/database/app_database.dart` |
| `features/pet/pages/pet_history_page.dart:8` | `core/database/app_database.dart` |

---

## 5. 核心功能手动测试清单

| 功能 | 状态 | 备注 |
|------|------|------|
| 首页 Dashboard | 待验证 | |
| 学习模块 | 待验证 | |
| 健身模块 | 待验证 | |
| 日记模块 | 待验证 | |
| 设置模块 | 待验证 | |

---

## 6. 基线总结

| 指标 | 数值 |
|------|------|
| dart analyze errors | 2 |
| dart analyze info | 1 |
| flutter test passed | 314 |
| flutter test failed | 28 |
| 依赖违规（core→features） | 4 |
| 依赖违规（shared→features） | 10 |
| 页面直连数据库 | 34 |

**下一步**：开始 Phase A - 依赖规则修复
