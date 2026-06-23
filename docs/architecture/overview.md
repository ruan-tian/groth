# Growth OS 架构规范

## 一、目录职责

```
lib/
├── app/           # 启动、路由、根布局、全局初始化
├── core/          # 纯底层能力（不依赖 features）
├── shared/        # 通用 UI + 全局轻状态（不依赖 features）
└── features/      # 业务模块（自包含）
```

### core/ 职责
- 数据库定义、表、迁移、database_provider
- 纯算法工具（text_processing）
- 全局服务（ai、audio、backup、notification、logger）
- 全局 Repository（setting_repository）
- 纯工具函数（date_utils、stats_formatters）

### shared/ 职责
- 设计系统（design/）
- 通用组件（widgets/）
- 全局轻状态 Provider（database、settings、theme）
- 扩展方法（extensions/）

### features/ 职责
- 每个 feature 自包含：pages、widgets、providers、repositories、models、services、constants
- 业务逻辑全部在 features 中
- feature 之间不直接依赖

---

## 二、依赖规则

### 正确依赖方向
```
app → features, core, shared
features → core, shared
shared → 不依赖 features
core → 不依赖 features
```

### 禁止依赖
```
core → features        ❌ 禁止
shared → features      ❌ 禁止
feature A → feature B  ❌ 尽量禁止
pages → database       ❌ 禁止
```

### 跨模块通信
- 数据聚合 → 通过数据库查询
- 即时反馈 → 通过 AppEvent
- 通用 UI → 才能进入 shared

---

## 三、feature 内部结构

```
features/xxx/
├── pages/           # 页面
├── widgets/         # 当前模块组件
├── providers/       # 状态管理
├── repositories/    # 数据访问
├── models/          # 数据模型
├── services/        # 业务逻辑
└── constants/       # 业务常量
```

---

## 四、架构守卫规则

1. core 不允许 import features
2. shared 不允许 import features
3. pages 不允许 import core/database
4. shared/widgets 不允许 import feature provider/model
5. 业务 Provider 不允许放 shared/providers
6. 业务 Repository 不允许放 core/repositories
7. feature A 不允许直接 import feature B 内部文件

---

## 五、剩余待处理项

1. **Drift 类型 import（30 个页面）**：页面 import `app_database.dart` 仅用于 Drift 类型定义（如 `DailyTask`、`StudyRecord`、`FitnessRecordsCompanion`），非直接 DB 操作。作为 warning inventory，后续通过 DTO/feature models 消除。
2. **Provider DB access（5 个 provider）**：provider 创建 Repository 实例时使用 `databaseProvider`，这是正常模式，作为 warning inventory。
3. **知识空间页面迁移**：✅ 已完成（10 个文件从 `study/pages/` → `knowledge/pages/`）
4. **AI 分析页 Facade**：✅ 已创建 `AiAnalysisInputFacade`，part 文件仍使用直接 import（legacy exception）
5. **跨 feature 白名单**：ai→knowledge, focus→music, dashboard→fitness/health, settings→fitness

### Drift 类型 import 清单（30 个页面）

| 模块 | 页面数 | 主要使用类型 |
|------|--------|--------------|
| fitness | 7 | `FitnessRecord`, `FitnessExercisesCompanion`, `BodyMetric` |
| health | 6 | `DietRecord`, `SleepRecord`, `SleepReminderScheduleStatus` |
| study | 3 | `StudyRecord`, `StudyRecordsCompanion` |
| journal | 3 | `DailyJournal`, `JournalFolder`, `JournalAsset` |
| settings | 3 | `AiConfig`, `BackupRecord` |
| music | 2 | `MusicTrack`, `MusicPlaylist` |
| pet | 2 | `PetMessage`, `PetProfile`, `PetState` |
| focus | 1 | `FocusSession` |
| dashboard | 1 | `DailyTask` |
| ai | 1 | `KnowledgeChunkSearchResult` |
| knowledge | 1 | `KnowledgeSpaceV3`, `KnowledgeMaterial` |

### 后续优化路径

1. **Phase 1**：为每个 feature 创建 `models/` 目录，定义 feature-specific DTOs
2. **Phase 2**：在 Repository 层添加 `toDTO()` / `fromDTO()` 转换方法
3. **Phase 3**：逐步替换页面中的 Drift 类型为 feature DTOs
4. **Phase 4**：移除页面对 `app_database.dart` 的 import

---

## 六、架构守卫

运行架构检查：
```bash
dart scripts/check_architecture.dart
```

---

## 六、AI 模块边界

| 模块 | 职责 |
|------|------|
| core/ai | AI 底层调用、API Key、模型配置、错误处理 |
| features/ai | 通用 AI 分析页面、AI 对话 |
| features/knowledge | 知识库上下文、资料问答、知识卡片生成和复习 |
