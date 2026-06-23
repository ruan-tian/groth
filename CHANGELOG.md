# Changelog

## 2026-06-23 Settings write facade stabilization

- Centralized dashboard card ids, daily goals, weekly fitness goal, calorie goal, sleep goal, and focus study mode writes through `SettingsFacade`.
- Removed save-time init-provider invalidation from the facade so user saves do not race with startup hydration and overwrite fresh provider state.
- Updated dashboard, study, fitness, diet, sleep, and focus mode UI entry points to await facade writes before closing sheets where needed.
- Added targeted facade tests for single setting setters, dashboard card ids, and daily goal updates.
- Removed the obsolete dashboard card save helper and routed pet diary auto-toggle writes through the shared pet diary provider path.

## 2026-06-22 设置页目标与主题写入收敛

- `SettingsFacade` 扩展主题模式和成长目标保存能力，统一负责 Provider 状态、KV 写入和初始化 Provider invalidate。
- 设置页主题切换、每日/每周/长期目标保存改走 Facade，减少页面层直接写库和多 Provider 状态漂移。
- 目标保存重建日常目标时使用 Unicode escape 常量，避免脚本/终端编码导致“学习/健身/写日记”等中文目标名被写坏。
- 补充 Facade 测试，覆盖主题保存、目标保存、头像和 AI 开关联动。

## 2026-06-22 音乐启动与设置写入稳定性

- 新增 `MusicSettingsWriteQueue`，将音量、悬浮窗位置、播放集合、当前曲目和播放进度等设置写入合并、去重并串行 flush，减少播放/拖动/切歌时的 SQLite 写锁竞争。
- 音乐播放器接入写入队列：UI 状态仍立即更新，数据库写入延后合并；暂停、seek、dispose 等关键节点会 flush，兼顾流畅性和持久化安全。
- App 启动协调器增加默认白噪音歌单预初始化，让音乐播放器打开时少做一次重写 seed，降低“音乐初始化失败”和白噪音切换卡顿风险。
- 补充音乐设置写入队列测试和启动协调器白噪音 seed 断言。

## 2026-06-22 Knowledge V3 Schema 单一入口

- 新增 `KnowledgeV3SchemaService`，集中维护 Knowledge V3 表结构和卡片补列逻辑，避免数据库迁移与 Repository 各维护一份 DDL。
- `AppDatabase` 迁移入口和 `KnowledgeV3Repository` 测试/运行时兜底入口改为复用同一 schema service，降低 `source_chunk_id` 等列重复添加和测试库/真机库不一致风险。
- Repository 默认空间创建改为参数化 SQL 与 Unicode escape 常量，避免终端编码导致默认空间文案写坏。
- 补充 schema service 测试，覆盖全新 schema 创建、旧表缺列补齐、默认知识空间仍可创建。

## 2026-06-22 设置写入 Facade 第一批

- 新增 `SettingsFacade`，把设置 KV 写入、Riverpod 状态同步和相关 Provider invalidate 收敛到统一入口。
- 个人资料头像保存/删除改走 Facade，确保设置页头像、全局头像 Provider 和问甜甜用户头像读取链路保持一致。
- AI 自动分析和日记上传开关改走 Facade；关闭 AI 自动分析时统一关闭日记上传，减少设置页直接写库导致的状态漂移。
- `GrowthConfirmDialog` 主/副按钮回调改为支持同步或异步确认，降低隐私确认弹窗异步写库和路由关闭时序风险。

## 2026-06-22 启动初始化协调第一步

- 新增 `AppBootstrapCoordinator`，把 Knowledge V3 表准备、数据库索引准备、只读健康检查串成单一启动入口，降低启动期并发写锁和顺序不确定风险。
- `appDatabaseProvider` 不再在下一帧自行创建索引，避免低层 Provider 隐式抢写；App 根节点改为 watch `appBootstrapProvider` 触发基础设施启动。
- 补充启动协调器测试，验证全新内存数据库可以完成 bootstrap，且多次调用复用同一个 Future 结果。

## 2026-06-22 数据库稳定性体检第一步

- 新增只读 `DatabaseHealthService`，用于检查 SQLite integrity、Knowledge V3 表/列、关键索引、孤儿引用、白噪音歌单拆分、头像/日记附件/音乐文件路径缺失等问题。
- 在 `service_providers.dart` 暴露 `databaseHealthServiceProvider`，后续可接入启动诊断、设置页维护工具或 Debug 面板。
- 补充最小服务测试，覆盖健康库无错误、重复知识空间告警、头像路径缺失告警，作为后续数据库治理的安全基线。

## 2026-06-22 热力图修复：月份错位、图例重复

### 修复问题
- **月份错位**：将 `_MonthLabels` 从 `Stack` + `Positioned` 固定布局改为 `Row` 布局，与网格放在同一个 `SingleChildScrollView` 内，确保月份标签跟随网格同步滚动
- **图例重复**：日记页面调用 `HeatmapCalendar` 时传 `showLegend: false`，避免内置图例和页面图例重复显示
- **今日高亮**：今日单元格边框改为主题色 `colors.primary`（原为 `colors.card`，不可见）

### 改进细节
- 单元格大小从 `14px` 增至 `16px`，更易点击
- 跨年边界处显示年份（如 "2024年12月" → "1月"）
- 月份标签使用 `Spacer` 占位对齐，保持与网格列对应

## 2026-06-22 图表增强：目标参考线、触摸指示线、防溢出

### 新增组件
- `ChartGoalLine` 目标参考线工具（`core/utils/chart_goal_line.dart`）
  - 支持虚线目标线 `[6, 4]`，颜色使用 `textTertiary`
  - 支持区间色带（Garmin 风格最佳训练负荷）
- `DualYAxisTransformer` 双Y轴坐标映射器（`core/utils/dual_axis_transformer.dart`）
  - 线性代数映射算法，精确双Y轴数值转换
  - 用于健身趋势（时长/卡路里）和饮食图表（卡路里/饮水）
- `ChartTooltipTheme` 统一Tooltip样式（`shared/widgets/common/chart_tooltip_theme.dart`）
  - 统一背景色、圆角、内边距、文字样式

### 增强的共享组件
- `DurationBarChart` 添加可选 `goalValue` 和 `goalLabel` 参数
- `DurationLineChart` 添加目标参考线、触摸垂直指示线、双层锚点光斑、Tooltip 防溢出

### 增强的页面图表
- 学习趋势图：Tooltip 添加 `fitInsideVertically: true` 防止溢出
- 健身趋势图：添加触摸垂直指示线（Apple Health 风格双层锚点）
- 饮食图表：添加触摸垂直指示线
- 睡眠组合图：添加睡眠目标小时虚线参考线，Tooltip 添加 `fitInside`

### 设计规范
- 目标参考线：虚线 `[6, 4]`，颜色 `textTertiary.withValues(alpha: 0.5)`
- 触摸指示线：虚线 `[4, 4]`，颜色 `border.withValues(alpha: 0.4)`
- 锚点光斑：外层白色 + 内层主题色（Apple Watch 风格）
- 所有颜色和间距保持现有设计系统不变

## 2026-06-22 SQLite lock and dialog pop quick fix

- Added SQLite `busy_timeout`, WAL mode, and `synchronous=NORMAL` on database open to reduce startup write-lock failures.
- Serialized music bootstrap so retry/startup paths do not run multiple default playlist seed transactions at the same time.
- Fixed `GrowthConfirmDialog` secondary action so cancel closes the dialog itself first, then runs the optional callback.
- Removed the settings privacy dialog's page-context `Navigator.pop`, preventing cancel from popping the last GoRouter page.

## 2026-06-22 日记热力图与主页日历交互修复

- 修复日记写作热力图按当前月倒推导致选中年份月份显示不准的问题，改为按选中年份 1 月 1 日到 12 月 31 日展示。
- 修复日记列表记录底部标签、字数、经验值横向挤压导致的溢出，改用可换行布局并限制标签长度。
- 优化主页成长日历为 PageView 月份滑动，左右箭头也走平滑翻页动画。
- 在日历选中日期详情中新增“为这天新建任务”，并让任务弹窗支持传入初始日期。

## 2026-06-22 乱码修复（丢失字符手动修复）

- 手动修复 app_database.dart 中 14 处 `?` 乱码（推断原始中文：表、支持、列等）
- 手动修复 study_page_widgets.dart 中 3 处乱码（柱状图数据模型、柱顶数值气泡、科目名）
- 所有修复基于上下文推断，dart analyze 验证通过

## 2026-06-22 乱码修复（Dart 源文件）

- 修复 8 个 Dart 源文件中的 UTF-8→GBK→UTF-8 双重编码乱码
- 修复 CHANGELOG.md 中 53 行乱码条目
- 修复方法：将乱码文本编码为 GBK 字节，再解码为 UTF-8 还原中文
- 修复的文件：app_database.dart、journal_page_widgets.dart、music_player_provider.dart、music_import_destination_sheet.dart、study_page.dart、study_page_widgets.dart、tiantian_chat_sheet.dart、study_page_test.dart

## 2026-06-22 GrowthConfirmDialog 代码质量修复

- 修复文档注释格式错误，代码块改用三个反引号包裹
- 修复次要图片位置计算问题，移除对屏幕宽度的依赖，改用固定 `right: 10` 定位
- 移除冗余的 `onSecondary` fallback，因 `hasSecondary` 已保证 `onSecondary` 非空

## 2026-06-22 设置页面弹窗风格统一改造

### 新增组件
- 创建 `GrowthConfirmDialog` 通用确认弹窗组件，支持图片、标题、副标题、描述、隐私提示卡片和双按钮
- 支持三种模式：`normal`（蓝色主按钮）、`danger`（红色主按钮）、`info`（单按钮）
- 图片区域带柔和背景光晕，支持主图片+次要图片叠加
- 隐私提示卡片使用黄色警告样式，与 `PetAIDataPreviewSheet` 风格一致

### 图片资源
- 在 `assets/images/dialogs/` 目录下新增弹窗专用图片：
  - `ai_privacy.webp` - AI 自动分析弹窗
  - `journal_writing.webp` - 日记上传分析弹窗
  - `common_happy.webp` - 甜甜自动写日记弹窗
  - `app_icon.webp` - 关于页面弹窗

### 设置页面改造
- `_showPrivacyDialog` 方法改用 `GrowthConfirmDialog`，替代原有 `AlertDialog`
- `_showAboutDialog` 方法改用 `GrowthConfirmDialog`，替代原有 `AlertDialog`
- AI 自动分析、日记上传分析、甜甜自动写日记三个弹窗统一使用新组件
- 弹窗标题去掉 emoji 前缀，改为纯文字标题

### 设计规范
- 弹窗圆角 28px，与项目内 `_FocusIllustrationDialog` 一致
- 按钮圆角 18px，高度 48px，符合触摸目标最小尺寸要求
- 图片大小 100px，带 124px 的柔和背景光晕
- 隐私提示卡片使用 `warning` 色系，带 0.08 透明度背景和 0.18 透明度边框

## 2026-06-22 问甜甜头像、气泡溢出与卡片密度修复
- 个人资料页读取、更新、删除头像时同步刷新 `userAvatarPathProvider`，问甜甜用户头像可立即跟随设置页头像，空路径回退默认图标。
- 问甜甜消息列表改为用户右对齐、甜甜左对齐的独立气泡布局，历史消息、流式消息和思考态共用同一套宽度约束。
- 长文本、URL 和连续字符展示时插入零宽断点，避免聊天气泡横向撑破导致 RenderFlex overflow。
- 卡片生成补卡阈值提升到目标数量 80%，补卡上限提高，并修复自动生成/待复核标签显示为 `????` 的问题。
- 验证定向 `dart analyze` 覆盖问甜甜、个人资料、设置 Provider、知识卡 AI 服务和知识库 Sheet。
## 2026-06-22 知识空间问号、生成数量与手动加卡修复
- 清理知识空间相关页面残留的 `??/????` 可见文案，问甜甜关闭按钮、复习答案/解析、知识库底部操作按钮改为稳定文案。
- 知识卡生成保存策略从“严格不合格直接丢弃”改为“两档保存”：高质量且可追溯的自动通过，题答可用但来源校验不足的保存为 `needs_review`，避免简单 100 问资料只剩极少卡片。
- 生成目标数量对问答型资料更敏感，按问号/选择题数量提高目标卡片数。
- 知识库卡片 Tab 增加“手动添加”入口，可直接录入问题、答案和可选解析。
- 甜甜头像统一优先使用 `assets/pet/ai/ai_daily_summary.webp`，失败时回退到知识卡头像资源。
## 2026-06-22 知识空间 UI 参考图修整
- 参考聊天、主页、复习卡片截图，重排问甜甜头部、资料模式条、空对话引导、建议问题、主页统计/资料/卡片列表和复习卡片主体层级。
- 修复知识空间主页和问甜甜页面部分中文被写成 `????` 的问题，关键文案改用 Unicode 转义，避免本地终端编码链路再次污染 UI。
- 保留现有功能入口和状态逻辑，不改知识库、问答、复习调度和生成流程。
## 2026-06-22 知识卡后台生成进度与知识空间 UI 调整
- 知识卡生成接入后台任务控制器和真实阶段进度，生成 Sheet 显示结构分析、卡片计划、卡片生成、保存、兼容生成等状态，并支持先返回空间继续等待。
- 修复 Knowledge V3 补列迁移遇到 `duplicate column name: source_chunk_id` 时导致页面加载失败的问题，同时补齐 `memory_hint`、`related_concepts_json` 等旧库兼容字段。
- 三阶段生成失败时自动切换兼容生成，不再把“AI 返回的资料结构分析格式不正确”作为最终用户错误优先抛出。
- 问甜甜聊天页接入设置头像作为用户头像，补齐用户消息右侧头像，并用 `ai_daily_summary.png` 转换覆盖甜甜 WebP 头像资源。
- 调整知识空间主页任务卡、欢迎卡、搜索框、快捷入口，以及复习抽卡页进度、问题、答案解析和评分区域的视觉层级。
## 2026-06-22 知识卡三阶生成与问答拆?
- Knowledge V3 卡片表新?`source_chunk_id`、`source_locator_json`、`concept`、`knowledge_point`、`exam_scene`、`common_mistake`、`grounded`、`status` 等兼容字段，并过 schemaVersion 30 ?Repository 幂等补列保护旧库升级?- 资料生成卡改?`outline -> cardPlan -> cards` 三阶段链跼先分析资料结构，再制定卡片划，后按计划生成习卡；若三阶?JSON 失败，会回到旧窗口直生和查漏补卡路径?- 卡片草解析扩展来源片、念知识点、试场景、常见区依捊态和草状，卡片类型兼?`process/trap/choice` 并映射到新类型体系?- 闭轍从单张压缩卡升级?1-5 张智能拆分卡：有资料来源标?`draft + grounded`，无资料闭标?`needs_review + AI草`，旧入口保留 fallback 单卡保存?- 闔甜聊天气泡新增拆成知识卡”操作，叛接把任意甜甜回答轈复习卡，并刷新知识空间数?- 补充并更新知?V3 AI service/repository targeted tests，验证三阶生成元数捁fallback 查漏补卡和问答保存兼容路径?
## 2026-06-22 知识空间菜单统一 + 闔甜空间级对话重构

### 知识空间 UI
- 知识空间、资料知识卡三点菜单从原?`PopupMenuButton` 迁移到系统格底部操作面板，统一图标、危险操作色与边界操作显示规则?- 资料菜单保留查看、续编编辑上移下移删除；知识卡菜单保留查看编辑上移下移删除；空间菜单保留重命名归档?
### 淇濆瓨闂敊淇
- 将资料续编资料编辑知识卡编辑弹窗业 `TextEditingController` 移入狫 Stateful Sheet，避免关闊画期间闷释放 controller 导致矚“渲染失败?- 保存后统通过 `invalidateKnowledgeV3` 刷新知识空间数据，并保留下一帧刷新策略?-  Knowledge V3 测试建表字缺失，补?`memory_hint` ?`related_concepts_json`?
### 闔?- 闔甜入口改为直接打 `TiantianChatSheet`，不再强制先选择资料；无资料空间也可以进入话?- 搜索框提交疑闏会进入同丩间级聊天 Sheet，并把问题作为初始提闏送?- 聊天右上角资料择器作为可选知识库上下文，资料选择与会话身份解耦，出后再进入沿用同一空间新会话?- 闔甜聊?Sheet 重做头像、模式状态条、回答气泡和输入区觉，接入 `tiantian_avatar.webp`?- AI 闭 prompt 拆分?`grounded/general/hybrid` 三模式，有资料时严格基于资料并标注片来源，无资料时明硙通习回答且不伪造资料来源?- 甜甜闭消息在现?`sources_json` 丅容保?`answerMode`、`grounded`、`usedMaterialIds`，为后续闭轍和来源追踿?metadata?
## 2026-06-20 鏀跺熬淇锛堢涓夋壒锛?
### 鍔熻兘 Bug 淇
- **界钟白噟**: 专注页启动声音时使用当前页面传入的声音类型，避免旧持久化状盖；白噪音初始化和播放失败现在会打印 debug 堆栈?- **界钟声音切捿?*: 专注页点击白噟」分段时会自动择并播放默认雨声，不再停留在无」致看似开吽没有声音?- **白噪音播放链跊?*: 专注白噪音改为优先缓存到朜文件撔，并将循玒放改为非阻吊，避?`AudioPlayer.play()` 在循玟频中卡住状更新?- **默白噪音歌单保?*: 默 5 首内罣音改入专注白噟」歌单，兼旧习歌单自动更名；默歌单和默认歌曲不又除，也不能从默歌单移除?- **知识删除刷新补全**: 删除卡片/资料后现在硈新习队列和搜索结果（`knowledge_v3_provider.dart`），卡片详情删除按钮?try-catch 错处理?- **睡眠提醒恢**: 页面打开时自动校验系统知状并重新同（`sleep_reminder_timer_page.dart` initState），首安不再默吝眠提醒?- **饰提醒达标停**: 饰达到盠后取消当天剩余提醒（新 `cancelWaterRemindersForToday` 方法），不再持续提醒?- **页饮水卡片?*: 水追踍片从 `softBlue`（近?近黑）改?`primary`（靛蓝）?2 处色引用全部更新?- **界音乐**: 铃声 asset 不存在时不再崩溃（try-catch），无音乐时显示"请先导入朜音乐"提示?
### 澶囦唤鎭㈠琛ュ叏
- **V3 知识表纳入?*: 6 ?V3 知识衼spaces/materials/cards/review_logs/qa_sessions/qa_messages）过 raw SQL 导出导入，按外键顺序处理?- **AI 聊天记录纳入备份**: `AiChatMessages` 表加?`_tableSpecs`（optional）?
### 姝讳唬鐮佹竻鐞?- 鍒犻櫎 6 涓湭娉ㄥ唽鐨?V3 Drift 琛ㄥ畾涔夛紙`tables_extra.dart` 绾?122 琛岋級
- 鍒犻櫎 9 涓?pet re-export 绌烘枃浠讹紙`features/pet/models/` 鐩綍锛?- 鍒犻櫎鏃犺皟鐢ㄨ€呯殑 `saveWaterIntake()` 鍑芥暟

## 2026-06-20 瀹¤瀹夊叏淇

### P0 淇
- **TF-IDF 搜索索引**:  bigram 空字符串 bug（`knowledge_tfidf_index.dart:226`）和 tokenize 返回 Set 导致 TF 恒为 1 的问题（`knowledge_tfidf_index.dart:159`）中文搜索现在能正确生成 bigram 并算词频?- **斓跔**:  Dashboard 知识库摘要卡点击白屏（`dashboard_knowledge_summary.dart:30`），跔?`/study/knowledge-sources` 改为 `/plan/study/knowledge/sources`?- **加密服务安全**: v2 解密失败时不再返回密文当明文（`encryption_service.dart:159`），改为空串?
### P1 淇
- **经验值删除回?*: 新 `deleteExpLogsForSource` 方法，删除?健身/日//睡眠/专注记录时同步清?`GrowthExpLogs`，等级不再虚高涉?6 ?repository?- **等级兼注释**: 注释?`/100` 改为 `/5`，与代码和测试一致（`exp_service.dart:136`）?- **sleep_goal key 统一**: 设置?key ?`daily_sleep_goal` 改为 `sleep_goal_hours`（`settings_page.dart:535`）?- **音乐列表徎**: `loopAll` 模式撮后一首现在硾玈笸首（`music_player_provider.dart:649`）?- **界钟状态恢?*: `restoreFromPersistence()` 现在?Provider 创建时自动调甼`focus_provider.dart:261`），App 袝后可恢进度?- **?catch 块日志化**: 4 ?`catch (_) {}` 改为 `catch (e) { debugPrint(...); }`（focus_provider、knowledge_card_provider）?
### P2 淇
- **饰数据安全**: JSON 解析失败时不再清空全部历史数捼改为跳过写入（`water_plan_provider.dart:248`）?- **V3 表索?*: ?6 ?V3 知识表添?5 合索引，提升查性能（`app_database.dart`）?- **ensureTables 优化**: `_ensureTables()` 现在叉行一次，不再每方法调用都跑 DDL（`knowledge_v3_repository.dart`）?- **音乐 stop **: `MusicPlayerService.stop()` 现在调用 `_player.stop()` 而非 `_player.pause()`（`music_player_service.dart:37`）?
## 2026-06-19

### Refactor

- **Knowledge Space V3 rebuild**: Replaced the old knowledge-card main flow with a clean space-first workspace: space selection, Tiantian Q&A, one import composer, knowledge library drawer, and flashcard review.
  - Routed `/plan/study/flash-review` and legacy knowledge-card paths into the new workspace/review experience, removing the old three-tab UI from the main product path.
  - Added V3 local SQL-backed knowledge tables, repository/provider layer, review queue, search, import, material/card management, and guarded empty states for due/weak review.
  - Reworked AI card generation prompts to use selected materials internally, avoid user-facing chunks/tokens, and generate core review cards without the old arbitrary small batch experience.
  - Added Tiantian study assets and simplified the Study page entry so users see one clear `知识空间` action instead of template/module/chapter management.
- **Knowledge Space V3 product refinement**: Tightened the workspace around one primary task card and completed the broken loops behind Tiantian Q&A, search, import, generation, and review.
  - The workspace top bar now stays light and full-screen; the main next action is decided by state: import materials, generate cards, start due review, or random review.
  - Tiantian Q&A now opens a real composer with editable question, selectable references, send confirmation, saved Q&A history, source display, and search-result detail.
  - Search now covers materials, knowledge cards, and Tiantian Q&A records; result rows open the matching detail instead of dead taps.
  - Image import now uses the existing AI Vision OCR path when AI is configured, while file/web/text import preserve source metadata and keep chunks/tokens hidden.
  - Card generation now uses a stricter two-step prompt strategy, friendlier JSON parse failures, and quality filtering against prompt-like useless cards.
  - Review scoring now differentiates all four ratings with near-term retry for forgotten cards and longer intervals for confident recall; the review settings button explains the real scheduling rules.
  - Hardened AI result sheets so Tiantian Q&A, summaries, weak-card explanations, and card generation keep a single in-flight request across widget rebuilds, preventing duplicate AI calls or duplicate cards.
  - Added targeted widget/unit coverage for the new workspace, AI parser, Q&A search, review scheduling, and Study page regression.
- **Knowledge Space V3 IA and quality pass**: Moved the real knowledge-card entry to the space selector first, then into a single-space workspace, matching the new space-driven product model.
  - Study page now reads V3 workspace overview data, so its `知识空间` entry reflects imported materials, generated cards, due cards, and weak cards instead of the old target-template stats.
  - Workspace top bar now has clear `导入资料` and `始抽 actions, while the bottom glass dock keeps navigation to `空间 / 闔?/ 知识库` instead of repeating review actions.
  - Card generation now plans target card volume from material length and density, asks AI to cover core knowledge more completely, requires source excerpts, and filters vague or prompt-like cards before saving.
  - Knowledge library card management now supports view, edit, reorder, and delete with confirmation; material deletion also confirms before archiving.
  - V3 repository now maintains card order, ranked search results, safer table/schema guards, and an `order_index` compatibility migration for existing V3 databases.
- **Knowledge Space V3 usability hardening**: Reduced duplicate primary actions and tightened several real-use loops in the new workspace.
  - Workspace top-bar review action is now visually secondary so the state-driven task card remains the main call to action.
  - Web imports now persist the original URL for source traceability, and Tiantian answer-to-card saves now invalidate workspace stats immediately.
  - Import success now returns with `鍥炲埌绌洪棿` instead of the old `绋嶅悗澶勭悊` wording, keeping the flow user-facing and simple.
  - Flashcard review cards now use a sturdier scrollable paper-card layout for long questions, answers, and explanations without pushing the rating buttons away.
  - Added regression coverage for web source URL persistence and simplified import wording.

### Bug Fixes

- **Global calendar detail sheet added**: Added a reusable calendar service/provider/sheet with local lunar dates, common Gregorian and lunar festivals, and per-day growth statistics.
  - The dashboard date chip now opens the detailed calendar sheet with month switching, festival/lunar labels, activity dots, and selected-day study/fitness/focus/journal/EXP/task totals.
  - Left the "鏅氫笂濂斤紝璁ょ湡澶嶇洏" greeting without an easter egg per the current scope.
- **Calendar sheet compact layout fixed**: Made the calendar detail sheet adapt on shorter screens so festival labels and the bottom stats area no longer overflow.
  - The month grid compresses slightly on compact heights, and the selected-day panel can scroll when festival chips or stats need more vertical space.
  - Added a compact-screen widget test to guard against RenderFlex overflow regressions.
- **Image assets WebP cleanup**: Converted remaining app image PNG assets to WebP, updated music/focus/weather/journal asset constants, removed obsolete PNG copies, and deduplicated exact duplicate WebP files.
  - `assets/` now contains 742 image assets, all WebP; audit reports 0 PNG, 0 non-WebP, 0 exact duplicate groups, and 0 missing literal asset references.
  - Kept Android/iOS launcher and launch PNGs untouched because those are platform assets, not Flutter page image assets.
- **Music playback switching stabilized**: Added an in-memory play queue so previous/next follows the visible playlist or filtered track list instead of being reshuffled by recent-play ordering.
  - Migrates legacy `.png` music cover paths in stored tracks/playlists to WebP paths during refresh.
  - Removed the non-transparent player background layer that caused a gray patch in the floating player sheet.
- **Study date attribution fixed**: Study records now use the actual `startTime` for today's totals, range queries, trends, subject distribution, and recent-record ordering so manually added/backfilled sessions appear on the correct day.
- **Study recent records polished**: Recent study records can display local study illustrations, and the empty state now uses a compressed `empty_study.webp` asset.
- **Health reminder text and diet water card polish**: Fixed garbled Chinese text on water/sleep reminder pages and settings sheets, and made the diet water-intake card more solid and consistent with the app style.
- **Health reminder scheduling diagnostics fixed**: Split water/sleep reminder user intent from actual system scheduling state, added Android pending-notification verification, exact-alarm fallback status, and immediate/1-minute test notification actions.
  - Water reminders now verify pending IDs in the `520200...` range; sleep reminders verify pending ID `5204`.
  - Reminder cards show real states such as scheduled count, notification permission missing, schedule failure, no pending notifications, and possible delay when exact alarms are unavailable.
  - The diet page water card now uses the same water plan provider as the drinking plan page, so goal, current intake, reminder window, interval, records, charts, and EXP updates stay in sync.

## 2026-06-20

### Knowledge Space

- Detached the Study page knowledge-space entry from legacy knowledge-card providers/assets and restyled it as a native paper card that matches the new Tiantian workspace.
- Added Study page entry regression coverage for empty, imported-material, existing-card, and due-review states.
- Added dense-material backfill generation: when AI returns too few high-quality cards for a content-heavy source, Tiantian automatically runs one guarded supplemental pass for missed review points.
- Polished shared knowledge-space sheets with a desktop max width and keyboard-aware bottom padding, plus compact-screen coverage for the import composer.
- Made recently used knowledge spaces persist through local `updated_at` touch behavior, so selected/imported/new spaces rise to the top next time.
- Simplified the import composer further: paste content first, auto-name by default, and move optional title editing into `鏇村璁剧疆`.
- Updated the workspace ask box copy to make search and Tiantian Q&A feel like one clear entry.
- Hardened Tiantian card generation so truncated or malformed AI JSON is retried with a smaller repair prompt, while already saved high-quality cards are kept instead of losing the whole generation run.
- Improved long-material context selection for Tiantian Q&A, summaries, and weak-card explanations so prompts pull relevant later sections instead of only sending the beginning of a document.
- Tightened card-generation prompts and quality filters around review-ready cards: concrete question, independent answer, source excerpt, no prompt-like or generic summary cards.
- Made the workspace ask/search box submit naturally: question-like input opens Tiantian with source confirmation, keyword input stays as local search.
- After importing into a different space, the workspace now switches to that target space and refreshes the V3 providers.
- Saving a Tiantian answer as a card now marks the latest assistant message as converted, and Q&A history displays the saved state.

## 2026-06-18

### Bug Fixes

- **Dashboard pet LifeSession assets aligned**: Added missing transparent WebP variants for 33 existing pet PNG assets used by the homepage LifeSession pool, and removed 4 social pool entries whose source images are not present.
  - Preserved the existing time/weekend/social/easter-egg pool logic and probabilities.
  - Verified every LifeSession pool entry now resolves to an existing `assets/pet/.../*.webp` file.
- **Focus noise and study playlist reuse**: Made focus white-noise playback more reliable on desktop with asset-to-cache fallback, and seeded the music module's default study playlist with built-in white-noise tracks.
  - Music player now supports both local files and bundled asset audio.
  - Default study playlist is created idempotently and reuses rain, ocean, forest, cafe, and white-noise tracks.
  - Focus noise playback failures now reset playback state instead of leaving a false playing state.
- **Health reminders restored scheduling**: Reworked water and sleep reminders so enabled reminders are restored at app startup and scheduled through reusable notification scheduler logic.
  - Water reminders now schedule daily repeating slots across the configured reminder window instead of a single page-local reminder.
  - Sleep reminders now schedule as a daily sleep-prep notification.
  - Changing water interval/window/default amount or sleep time/lead minutes reschedules reminders immediately.

### Code Quality

- **Replaced print() with debugPrint()**: Changed 1 remaining print() statement in app_database.dart to debugPrint()
  - Prevents production console output while keeping debug visibility
  - Added flutter/foundation.dart import for debugPrint

### Encoding

- **Unified file encoding**: Fixed 54 .dart files to use UTF-8 without BOM + LF line endings
  - Removed UTF-8 BOM from 6 files (router.dart, flash_review_page.dart, etc.)
  - Converted CRLF to LF line endings in 54 files
  - All files now use standard Dart/Flutter encoding format

### Bug Fixes

- **Database Lock Fix**: Moved `_createPerformanceIndexes()` from `beforeOpen` to background execution
  - Root cause: 43 `CREATE INDEX` statements blocked database initialization while other providers accessed the database concurrently
  - Solution: Index creation now runs after first frame via `addPostFrameCallback`
  - Added `ensureIndexesReady()` method with `Completer` pattern for thread safety
  - Added `databaseReadyProvider` for critical pages to wait if needed
  - This prevents "database is locked" errors on app startup

### Performance Optimizations

- **StatisticsService**: Parallelized 9 sequential DB queries using `Future.wait()` - reduces weekly/monthly stats load from ~9 sequential queries to 1 parallel batch
- **knowledgeBaseOverviewProvider**: Batch chunk fetch - 1 query instead of N (where N = number of sources)
- **knowledge_source_repository**: Added batch methods `getChunksForSources()` and `getCardReferencesForSources()` for bulk operations
- **Composite Indexes**: Added 3 missing indexes for knowledge_cards:
  - `idx_knowledge_cards_mastery` on (archived, mastery_level) - speeds up weak card queries
  - `idx_knowledge_cards_streak` on (archived, correct_streak) - speeds up high-error card queries  
  - `idx_knowledge_cards_due_mastery` on (archived, due_at, mastery_level) - speeds up review queue queries

### Cleanup

- **Removed dead provider**: `dueKnowledgeCardsCountProvider` was never watched (only invalidated) - removed definition + 14 invalidation calls across 11 files

### Files Changed

- `lib/core/services/statistics_service.dart` - Parallel queries
- `lib/core/repositories/knowledge_source_repository.dart` - Batch methods
- `lib/shared/providers/knowledge_source_provider.dart` - Use batch fetch
- `lib/shared/providers/knowledge_card_provider.dart` - Remove dead provider
- `lib/core/database/app_database.dart` - Add composite indexes
- 11 feature files - Remove dead provider invalidation calls

## 2026-06-20 知识空间主流程稳定收?
- 统一导入 Sheet 在测试尺寸下“更多罝底部主按钁挡的，缩矻认粘贴输入区高度，保证标题可选项、文?网页/图片入口和开始入都叧达?- 调整知识空间主页信息顺序，将“最近资料前移到今日主任务后，入后用户能更応到资料并直接打开详情，不必先进知识库抽屉?- 知识空间工作?widget 测试常驻“知识库”底部入口的过斨，补齐最近资料直达情?Sheet 创建空间和移动叔性的回归验证?- 验证知识空间相关 targeted `flutter analyze` ?`flutter test` 通过，盖工作台、AI 生成服务、V3 repository 和习页入口?

## 2026-06-20 学习记录保存删除回归

- 将习录保?+ 写经验日志收口到 `StudyRepository.saveStudyRecordWithExp` 单一事务，避免页面刷?重建?UI 层拼事务产生不一致?- 删除学习记录前同时解除专注录和知识卡来源引甼已生成知识卡后删除习录外键拦截的问题?- 为习录保存失败?列表/详情页删除失败补充本地错诗志，方便真机复现后直接定位?- 补充仓库回归测试，盖事务保存和带知识卡来源引用的删除场?
## 2026-06-20 ???????????
- ???????????? Dock??????????/????????????? / ??? / ??????????????
- ??????????????????????????????????????????????????????
- ?????????????? widget ???????????????????????
- ??????????AI ?????V3 repository???????? targeted tests ? analyze ???


## 2026-06-20 ??????????
- ????? Sheet ???????? Tab ???????????? Tab ??????????????????????????????
- ??????? Tab ???????????????????? Sheet???????????????????
- ?? widget ??????? Tab ????????????????????????????
- ??????????AI ?????V3 repository?????? targeted `flutter test` 40 ?????? `flutter analyze` ????


## 2026-06-20 ?????????
- ????????????????????????????????????????????????????????????????????????
- ????????????????????????????????????????
- ?? AI service ?????????????????????/???????????????????
- ??????????AI ?????V3 repository?????? targeted `flutter test` 41 ?????? `flutter analyze` ????


## 2026-06-20 ?????????
- ??????????????????????????????????????????????????????
- ??????????????????????????????? toast ??????????
- ???????????????????????????????????????????????
- ?? widget ???????????????????????AI ?????V3 repository?????? targeted `flutter test` 42 ?????? `flutter analyze` ????

## 2026-06-20 知识空间导入失败态收?
- 清洗资料导入的失败文案，文件、网页图?OCR 失败时不再把 `FormatException`、网络异常或底层堆栈直接显示给用户，统一提示复制文字粘贴、换文件格式或换清晰图片?- 统一知识空间导入 Sheet 的失?toast 兜底逻辑，避免后三方解析库返回内部异常时污染用户界面?- 补充 `KnowledgeDocumentImporter` 错文测试，盖文件解析网页抓取和图片 OCR 三类内部异常?- 验证知识空间导入测试、工作台/AI/repository/学习页入口回归测试和 targeted `flutter analyze` 通过?
## 2026-06-20 知识空间主界面去?
- 调整空间主页忍功能区：当空间已有资料但还没有知识卡时，叿留主任务卡里?`生成知识，快捷区不再重出现同一入口?- 已有知识卡后，快捷区的生成入口改?`补充知识，义从“主流程下一步变成已有卡片后的补充整理?- 补充工作?widget 测试，盖无卡时不重复生成入口已有卡后显示补充入口?- 验证知识空间 targeted `flutter test` 57 项和 targeted `flutter analyze` 通过?
## 2026-06-20 知识空间顶部栏轻量化

- 将空间主页顶部栏从动作栏收敛为?管理栏，叿留返回空间切捁知识库和理空间?- 移除顶部栏里?`导入资料` ?`始抽，页面主任务卡成为唸主动作来源，减少同页重按钮和知分叉?- 补充工作?widget 测试，验证顶部栏不再重主动作，同时保留知识库和空间管理入口?- 验证知识空间 targeted `flutter test` 58 项和 targeted `flutter analyze` 通过?
## 2026-06-20 知识空间狫跔验证

- 补充真实 `GrowthOSApp` 跔测试，验证普通划页仍显示主底部导航，进?`/plan/study/knowledge` 后知识空间浮?root navigator 上，不再袺部舌压?- 在测试中隔健康提醒吊和宠物编排器，避免全定时?通知初化干扰知识空间路由断?- 验证知识空间 targeted `flutter test` 59 项和 targeted `flutter analyze` 通过?
## 2026-06-20 知识空间创建闎

- 空间选择?`新建空间` 的为：点击 `创建并进 后现在会直接进入新建空间主页，不昁留在空间列表?- 保持导入 Sheet 内的新建空间行为不变：创建后继续留在导入流程，并臊选中新空间?- 补充工作?widget 测试，盖从空间选择页创?`法` 后直接进入空间主页?- 验证知识空间 targeted `flutter test` 60 项和 targeted `flutter analyze` 通过?
## 2026-06-20 知识空间体验收口加固

- 闍复习页从深链或空栈进入时返回不稳定的，回到空间时会同步当前知识空间，避免跳回默空间?- 优化 AI 失败态：朅?AI 时在甜甜闭、结、生成知识卡?Sheet 丘示可行动的去配置 AI”入口，不再叻重试?- 优化复习空状态窄屏布，入资料和生成知识卡按钜小屏臊竖排，减少挤压和溢出风险?- 补充知识空间搜索、习返回AI 朅罅口等 widget 回归测试；验?targeted `flutter test` 63 项和 targeted `flutter analyze` 通过?
## 2026-06-20 知识空间导入流再降?
- 移除导入 Sheet 里的“更多?/ 资料标（可选）”，粘贴文本导入时改为根文行自动命名资料，用户不再要理标题等丗字?- 导入主按钜正文为空时保持不叔，输入内容后才亮起，减少点按钐再报错的挴感?- 补充臊命名与入按钊?widget 测试；验证知识空?targeted `flutter test` 64 项和 targeted `flutter analyze` 通过?
## 2026-06-20 知识卡生成质量门槛加?
- 收紧 AI 生成卡片质量过滤：拒绝目?标式问题缺少回忆意图的，以及过矈不能狫复习的答案，减少“生成了但不好习的废卡?- 优化“甜甜回答转知识卡：长回答会压缩为合卡片复习的答案，完整回答继续保留在问答录中，避免卡片文过长?- 补充 AI 服务回归测试，盖标题式废卡、短答废卡、长回答轍压缩；验证知识空?targeted `flutter test` 66 项和 targeted `flutter analyze` 通过?
## 2026-06-20 知识空间详情视图统一

- 将资料情和知识卡情从系统默 `AlertDialog` 改为知识空间统一的底?Sheet，使用纸卡承载文，保持浅蓝白工具致?- 知识卡情补充状态来源答案解析和来源摘录展示，编?删除/关闭操作在窄屏下臂应排布，避免按钌压?- 补充资料详情、知识卡详情和紧凑屏详情 Sheet 回归测试；验证知识空?targeted `flutter test` 68 项和 targeted `flutter analyze` 通过?
## 2026-06-20 知识卡生成到复习闎验证

- 加强 AI 生成成功跾的服务层回归：AI 返回有效知识卡后会写?V3 仓库，并能 `getReviewQueue(..., all)` 直接取出用于抽卡复习?- 保持页面层盖生成确认无 AI 配置失败态和“去配置 AI”入口；避免?widget 测试丼入加密配罈始化导致测试不稳定?- 验证知识空间 targeted `flutter test` 68 项和 targeted `flutter analyze` 通过?
## 2026-06-20 知识空间导入叝性加?
- Markdown 文件改为直接按纯文本读取并保留原始结构，避免交给通用文档解析库致标题列表和代码块意改写?- 补充图片 OCR 导入成功、无 OCR 配置、OCR 内部异常三类测试，确保图片入成功可进主流程，失败时不暴?`FormatException` 等内部错?- 验证知识空间 targeted `flutter test` 71 项和 targeted `flutter analyze` 通过?
## 2026-06-20 知识空间主路径文案统

- 将习页知识空间入口在有资料待生成状态下的主操作从生成卡片统为生成知识卡”，减少同一动作的不同叫法?- 将空间主页快捷操作里的补充知识卡”统为生成知识卡”，保留内部补充生成能力但不向用户暴露外念?- 复查新知识空间主页面不暴?`AI 导入 / 全部复习 / 盠模板 / token / 切片 / 沉淀 / 草` 等旧主流程术诼验证 targeted `flutter test` 71 项和 targeted `flutter analyze` 通过?
## 2026-06-20 学习记录保存稳定性修?
- 添加学习记录时，时长输入吩格会校验通过但保存抛 `FormatException` 的问题?- 为添加习录页初化默?60 分钟时长，并让简单模式保存的?结束时间与输入时长一致?- 保存失败时在 debug 控制台打印完整异常堆栈；保存成功后刷新习页近期录趋势图和盈布相?Provider?- 学习记录删除袸注录锘止的，删除前会解?`focus_sessions.related_study_id` 引用?- 数据库打时补齐习录经验日志专注录的核心?列，降低?debug 数据库迁移不完整导致保存/删除失败的险?- 补充学习记录保存事务和关联专注录删除回归测试?
## 2026-06-20 知识空间管理弹层统一

- 将知识空间内的网页入资料续编资料编辑知识卡编辑和删除确认从系统 `AlertDialog` 统一为知识空间底?Sheet，保持浅蓝白纸面工具风一致?- 网页导入 Sheet 补充移动竌钇适应，和粘贴/文件/图片导入入口保持同一导入诨?- 补充网页导入使用统一 Sheet ?widget 回归测试；验证知识空?targeted `flutter test` 72 项和 targeted `flutter analyze` 通过?
## 2026-06-20 知识卡删除安全加?
- 知识卡情页点击 `删除` 会直接归档的，现在会先弹出知识空间统 Sheet ，避免删成不信任感?- 补充详情页删除确认回归测试，验证取消删除后知识卡仍保留，并且层不使用系统 `AlertDialog`?- 验证知识空间 targeted `flutter test` 73 项和 targeted `flutter analyze` 通过?
## 2026-06-20 知识卡生成盖率增强

- 提高 AI 生成卡片的密集资料识初重：列表型点、盒带问号的解析会更秞地转化为复习卡，不再对长资料保守少生成?- 将单份资料的盠卡片上限?80 提升?120，单丵料窗口建讕量从?24 提升?30，配题库、义和高考点清单?- 将查漏补卡阈值从?45% 提升到约 65%，并放大资料补卡最低盖封顶，减少“资料很多但卡片夰”的情况?- 补充超密集资料生成划测试，验证上百条明硃点会得到更高目标数量并触发更积极的查漏补卡；验证知识空?targeted `flutter test` 74 项和 targeted `flutter analyze` 通过?
## 2026-06-20 鍏ㄩ」鐩潤鎬佹鏌ユ敹鍙?
- 复查旧知识卡页面、旧?Tab 和旧管理页文件名?`lib/` ?`test/` 丷无残留引甼避免删除旧主体验后留下编译断点?- 清理睡眠记录?3 丆?provider import，全项?`flutter analyze` ?3 ?info 恢?`No issues found`?- 重新验证知识空间 targeted `flutter test` 74 项过，并完成全项?`flutter analyze` 通过?
## 2026-06-20 鏃х煡璇嗗崱璺敱鍥炲綊閿佸畾

- 补充真实 `GrowthOSApp` 跔回归测试，?`/plan/study/knowledge/add`、`import`、`sources`、`archive`、`export`、`templates`、`goal`、`edit/:id`、`onboarding` 等旧跾全部进入新知识空间工作台?- 验证 `/plan/study/flash-review` 进入空间选择页，`/plan/study/knowledge/review` 进入新闪卡习页，且这些 root 跔都不会主底部舌压?- 测试丐步断旧主流程文 `AI 导入 / 全部复习 / 盠模板` 不出现；验证知识空间 targeted `flutter test` 75 项和全项?`flutter analyze` 通过?
## 2026-06-20 知识空间多尺寸觉烟?
- 补充桌面宽屏工作?smoke test，验证空间主页最近资料最近知识卡和知识库抽屉?1280x900 尺下稳定渲染，不触发布异常?- 补充小屏长内容习卡 smoke test，验证长、长答和长解析?360x640 尺下可滚动展示，评分按钻叔?- 重新验证知识空间 targeted `flutter test` 77 项和全项?`flutter analyze` 通过，为后续真实设视 QA 提供更强回归保障?## 2026-06-20 饓推荐卡片笺批接?
- 灏?`picture/鎯冲枬鐐逛粈涔?绗簩鎵筦 鐨?264 寮犻ギ鍝佸崱鐗囨壒閲忚浆鎹负 WebP锛屽苟浠?`鍝佺墝__楗搧.webp` 鍛藉悕鎺ュ叆 `assets/images/drinks/`锛岄伩鍏嶄笉鍚屽搧鐗屽悓鍚嶉ギ鍝佷簰鐩歌鐩栥€?- 閲嶅缓鈥滀粖澶╂兂鍠濈偣浠€涔堚€濋ギ鍝佺洰褰曪紝鎸夊仴搴峰尯銆佸挅鍟°€佹柊鑼堕ギ銆佸嵆楗尪銆佹皵娉°€佹灉姹併€佷钩楗€佸姛鑳藉垎绫诲睍绀猴紱鍋ュ悍鍖哄寘鍚櫧寮€姘淬€佺熆娉夋按銆佹棤绯栧彲涔愩€佽嫃鎵撴按绛夋洿瀹夊叏鐨勪綆璐熸媴閫夋嫨銆?- 鏇存柊楗搧鎺ㄨ崘椤甸潰鍒嗙被鑹插僵鏄犲皠鍜屽搴旀祴璇曪紝楠岃瘉 264 鏉＄洰褰曘€佽祫婧愯矾寰勫拰鍋ュ悍鍖哄垎绫诲彲鐢ㄣ€?## 2026-06-20 鐣寗閽熺櫧鍣煶鎾斁閾捐矾淇

- 绉婚櫎鐣寗閽熺櫧鍣煶璺緞閲岀殑 `JustAudioBackground.init` 鍒濆鍖栵紝閬垮厤涓庡凡鏈夐煶棰戞湇鍔￠噸澶嶅垵濮嬪寲瑙﹀彂 `_cacheManager == null` 鏂█锛屽鑷撮洦澹般€佹捣娴€佹．鏋楃瓑澹伴煶閮芥棤娉曟挱鏀俱€?- 淇濈暀鏈湴璧勬簮缂撳瓨鎾斁涓?asset fallback锛岀櫧鍣煶缁х画浣跨敤鐙珛 `just_audio` 鎾斁鍣ㄥ惊鐜挱鏀撅紝涓嶅啀渚濊禆鍚庡彴閫氱煡闊抽鍒濆鍖栥€?- 楠岃瘉 `focus_audio_service`銆乣focus_audio_provider`銆佷笓娉ㄥ０闊抽潰鏉垮拰涓撴敞浼氳瘽椤?targeted `flutter analyze` 閫氳繃銆?## 2026-06-20 鍚姩杩涘叆鍔ㄧ敾涓?App 鍥炬爣鏇存柊

- 新 Growth OS 吊进入动画：浅蓝白纸面背景、成长环、软基图标浮现玻璃提示条和细进度条，挂载?`MaterialApp.router.builder`，不改变业务跔?- 动画攌系统减少动效设置，并使用 `IgnorePointer` 避免吊蒙层阻底层页面交互或测试点击?- 使用 `picture/APP图标.png` 生成应用内品牌图、Android launcher mipmap、iOS AppIcon ?Windows `app_icon.ico`?- 验证 `flutter analyze lib/app/app.dart lib/app/launch_intro_overlay.dart` ?`flutter test test/widget_test.dart` 通过?- 加固吊性：减少动效模式下改为短品牌定帧而不昛接跳过；动画时长延长并加中心光晕，同时补充 Android/iOS 原生吊静图标，避免冷启动白屏后直接进入首页?


