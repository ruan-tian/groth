# Changelog

## 2026-06-20 审计安全修复

### P0 修复
- **TF-IDF 搜索索引修复**: 修复 bigram 空字符串 bug（`knowledge_tfidf_index.dart:226`）和 tokenize 返回 Set 导致 TF 恒为 1 的问题（`knowledge_tfidf_index.dart:159`）。中文搜索现在能正确生成 bigram 并计算词频。
- **断链路由修复**: 修复 Dashboard 知识库摘要卡点击白屏问题（`dashboard_knowledge_summary.dart:30`），路由从 `/study/knowledge-sources` 改为 `/plan/study/knowledge/sources`。
- **加密服务安全修复**: v2 解密失败时不再返回密文当明文（`encryption_service.dart:159`），改为空串。

### P1 修复
- **经验值删除回滚**: 新增 `deleteExpLogsForSource` 方法，删除学习/健身/日记/饮食/睡眠/专注记录时同步清理 `GrowthExpLogs`，等级不再虚高。涉及 6 个 repository。
- **等级公式注释修正**: 注释从 `/100` 改为 `/5`，与代码和测试一致（`exp_service.dart:136`）。
- **sleep_goal key 统一**: 设置页 key 从 `daily_sleep_goal` 改为 `sleep_goal_hours`（`settings_page.dart:535`）。
- **音乐列表循环修复**: `loopAll` 模式播完最后一首现在正确循环到第一首（`music_player_provider.dart:649`）。
- **番茄钟状态恢复**: `restoreFromPersistence()` 现在在 Provider 创建时自动调用（`focus_provider.dart:261`），App 被杀后可恢复进度。
- **空 catch 块日志化**: 4 处 `catch (_) {}` 改为 `catch (e) { debugPrint(...); }`（focus_provider、knowledge_card_provider）。

### P2 修复
- **饮水数据安全**: JSON 解析失败时不再清空全部历史数据，改为跳过本次写入（`water_plan_provider.dart:248`）。
- **V3 表索引**: 为 6 张 V3 知识表添加 5 个复合索引，提升查询性能（`app_database.dart`）。
- **ensureTables 优化**: `_ensureTables()` 现在只执行一次，不再每次方法调用都跑 DDL（`knowledge_v3_repository.dart`）。
- **音乐 stop 修复**: `MusicPlayerService.stop()` 现在调用 `_player.stop()` 而非 `_player.pause()`（`music_player_service.dart:37`）。

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
  - Workspace top bar now has clear `导入资料` and `开始抽卡` actions, while the bottom glass dock keeps navigation to `空间 / 问甜甜 / 知识库` instead of repeating review actions.
  - Card generation now plans target card volume from material length and density, asks AI to cover core knowledge more completely, requires source excerpts, and filters vague or prompt-like cards before saving.
  - Knowledge library card management now supports view, edit, reorder, and delete with confirmation; material deletion also confirms before archiving.
  - V3 repository now maintains card order, ranked search results, safer table/schema guards, and an `order_index` compatibility migration for existing V3 databases.
- **Knowledge Space V3 usability hardening**: Reduced duplicate primary actions and tightened several real-use loops in the new workspace.
  - Workspace top-bar review action is now visually secondary so the state-driven task card remains the main call to action.
  - Web imports now persist the original URL for source traceability, and Tiantian answer-to-card saves now invalidate workspace stats immediately.
  - Import success now returns with `回到空间` instead of the old `稍后处理` wording, keeping the flow user-facing and simple.
  - Flashcard review cards now use a sturdier scrollable paper-card layout for long questions, answers, and explanations without pushing the rating buttons away.
  - Added regression coverage for web source URL persistence and simplified import wording.

### Bug Fixes

- **Global calendar detail sheet added**: Added a reusable calendar service/provider/sheet with local lunar dates, common Gregorian and lunar festivals, and per-day growth statistics.
  - The dashboard date chip now opens the detailed calendar sheet with month switching, festival/lunar labels, activity dots, and selected-day study/fitness/focus/journal/EXP/task totals.
  - Left the "晚上好，认真复盘" greeting without an easter egg per the current scope.
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
- Simplified the import composer further: paste content first, auto-name by default, and move optional title editing into `更多设置`.
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

## 2026-06-20 知识空间主流程稳定性收口

- 修复统一导入 Sheet 在测试尺寸下“更多设置”被底部主按钮遮挡的问题，缩短默认粘贴输入区高度，保证标题可选项、文件/网页/图片入口和“开始导入”都可触达。
- 调整知识空间主页信息顺序，将“最近资料”前移到今日主任务后，导入后用户能更快看到资料并直接打开详情，不必先进知识库抽屉。
- 修正知识空间工作台 widget 测试中对常驻“知识库”底部入口的过宽断言，补齐最近资料直达详情、导入 Sheet 创建空间和移动端可用性的回归验证。
- 验证知识空间相关 targeted `flutter analyze` 与 `flutter test` 通过，覆盖工作台、AI 生成服务、V3 repository 和学习页入口。


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

## 2026-06-20 知识空间导入失败态收口

- 清洗资料导入的失败文案，文件、网页、图片 OCR 失败时不再把 `FormatException`、网络异常或底层堆栈直接显示给用户，统一提示复制文字粘贴、换文件格式或换清晰图片。
- 统一知识空间导入 Sheet 的失败 toast 兜底逻辑，避免后续第三方解析库返回内部异常时污染用户界面。
- 补充 `KnowledgeDocumentImporter` 错误文案测试，覆盖文件解析、网页抓取和图片 OCR 三类内部异常。
- 验证知识空间导入测试、工作台/AI/repository/学习页入口回归测试和 targeted `flutter analyze` 通过。

## 2026-06-20 知识空间主界面去重

- 调整空间主页快捷功能区：当空间已有资料但还没有知识卡时，只保留主任务卡里的 `生成知识卡`，快捷区不再重复出现同一入口。
- 已有知识卡后，快捷区的生成入口改为 `补充知识卡`，语义从“主流程下一步”变成“已有卡片后的补充整理”。
- 补充工作台 widget 测试，覆盖无卡时不重复生成入口、已有卡后显示补充入口。
- 验证知识空间 targeted `flutter test` 57 项和 targeted `flutter analyze` 通过。

## 2026-06-20 知识空间顶部栏轻量化

- 将空间主页顶部栏从动作栏收敛为导航/管理栏，只保留返回、空间切换、知识库和管理空间。
- 移除顶部栏里的 `导入资料` 与 `开始抽卡`，让页面主任务卡成为唯一主动作来源，减少同页重复按钮和认知分叉。
- 补充工作台 widget 测试，验证顶部栏不再重复主动作，同时保留知识库和空间管理入口。
- 验证知识空间 targeted `flutter test` 58 项和 targeted `flutter analyze` 通过。

## 2026-06-20 知识空间独立路由验证

- 补充真实 `GrowthOSApp` 路由测试，验证普通计划页仍显示主底部导航，而进入 `/plan/study/knowledge` 后知识空间浮在 root navigator 上，不再被底部导航挤压。
- 在测试中隔离健康提醒启动和宠物编排器，避免全局定时器/通知初始化干扰知识空间路由断言。
- 验证知识空间 targeted `flutter test` 59 项和 targeted `flutter analyze` 通过。

## 2026-06-20 知识空间创建闭环修复

- 修复空间选择页 `新建空间` 的行为：点击 `创建并进入` 后现在会直接进入新建空间主页，而不是停留在空间列表。
- 保持导入 Sheet 内的新建空间行为不变：创建后继续留在导入流程，并自动选中新空间。
- 补充工作台 widget 测试，覆盖从空间选择页创建 `法考` 后直接进入空间主页。
- 验证知识空间 targeted `flutter test` 60 项和 targeted `flutter analyze` 通过。

## 2026-06-20 知识空间体验收口加固

- 修复闪卡复习页从深链或空栈进入时返回不稳定的问题，回到空间时会同步当前知识空间，避免跳回默认空间。
- 优化 AI 失败态：未配置 AI 时在甜甜问答、总结、生成知识卡等 Sheet 中显示可行动的“去配置 AI”入口，不再只给重试。
- 优化复习空状态窄屏布局，导入资料和生成知识卡按钮在小屏自动竖排，减少挤压和溢出风险。
- 补充知识空间搜索、复习返回、AI 未配置入口等 widget 回归测试；验证 targeted `flutter test` 63 项和 targeted `flutter analyze` 通过。

## 2026-06-20 知识空间导入流再降复杂

- 移除导入 Sheet 里的“更多设置 / 资料标题（可选）”，粘贴文本导入时改为根据正文第一行自动命名资料，用户不再需要处理标题等中间字段。
- 导入主按钮在正文为空时保持不可用，输入内容后才亮起，减少点按钮后再报错的挫败感。
- 补充自动命名与导入按钮状态 widget 测试；验证知识空间 targeted `flutter test` 64 项和 targeted `flutter analyze` 通过。

## 2026-06-20 知识卡生成质量门槛加固

- 收紧 AI 生成卡片质量过滤：拒绝目录/标题式问题、缺少回忆意图的问题，以及过短到不能独立复习的答案，减少“生成了但不好复习”的废卡。
- 优化“甜甜回答转知识卡”：长回答会压缩为适合卡片复习的答案，完整回答继续保留在问答记录中，避免卡片正文过长。
- 补充 AI 服务回归测试，覆盖标题式废卡、短答案废卡、长回答转卡压缩；验证知识空间 targeted `flutter test` 66 项和 targeted `flutter analyze` 通过。

## 2026-06-20 知识空间详情视图统一

- 将资料详情和知识卡详情从系统默认 `AlertDialog` 改为知识空间统一的底部 Sheet，使用纸卡承载正文，保持浅蓝白工具风一致。
- 知识卡详情补充状态、来源、答案、解析和来源摘录展示，编辑/删除/关闭操作在窄屏下自适应排布，避免按钮挤压。
- 补充资料详情、知识卡详情和紧凑屏详情 Sheet 回归测试；验证知识空间 targeted `flutter test` 68 项和 targeted `flutter analyze` 通过。

## 2026-06-20 知识卡生成到复习闭环验证

- 加强 AI 生成成功路径的服务层回归：AI 返回有效知识卡后会写入 V3 仓库，并能被 `getReviewQueue(..., all)` 直接取出用于抽卡复习。
- 保持页面层覆盖生成确认、无 AI 配置失败态和“去配置 AI”入口；避免在 widget 测试中引入加密配置初始化导致测试不稳定。
- 验证知识空间 targeted `flutter test` 68 项和 targeted `flutter analyze` 通过。

## 2026-06-20 知识空间导入可靠性加固

- Markdown 文件改为直接按纯文本读取并保留原始结构，避免交给通用文档解析库导致标题、列表和代码块被意外改写。
- 补充图片 OCR 导入成功、无 OCR 配置、OCR 内部异常三类测试，确保图片导入成功可进主流程，失败时不暴露 `FormatException` 等内部错误。
- 验证知识空间 targeted `flutter test` 71 项和 targeted `flutter analyze` 通过。

## 2026-06-20 知识空间主路径文案统一

- 将学习页知识空间入口在“有资料待生成”状态下的主操作从“生成卡片”统一为“生成知识卡”，减少同一动作的不同叫法。
- 将空间主页快捷操作里的“补充知识卡”统一为“生成知识卡”，保留内部补充生成能力但不向用户暴露额外概念。
- 复查新知识空间主页面不暴露 `AI 导入 / 全部复习 / 目标模板 / token / 切片 / 沉淀 / 草稿` 等旧主流程术语；验证 targeted `flutter test` 71 项和 targeted `flutter analyze` 通过。

## 2026-06-20 知识空间管理弹层统一

- 将知识空间内的网页导入、资料续编、资料编辑、知识卡编辑和删除确认从系统 `AlertDialog` 统一为知识空间底部 Sheet，保持浅蓝白纸面工具风一致。
- 网页导入 Sheet 补充移动端按钮自适应，和粘贴/文件/图片导入入口保持同一导入语言。
- 补充网页导入使用统一 Sheet 的 widget 回归测试；验证知识空间 targeted `flutter test` 72 项和 targeted `flutter analyze` 通过。

## 2026-06-20 知识卡删除安全加固

- 修复知识卡详情页点击 `删除` 会直接归档的问题，现在会先弹出知识空间统一 Sheet 确认，避免误删造成不信任感。
- 补充详情页删除确认回归测试，验证取消删除后知识卡仍保留，并且确认层不使用系统 `AlertDialog`。
- 验证知识空间 targeted `flutter test` 73 项和 targeted `flutter analyze` 通过。

## 2026-06-20 知识卡生成覆盖率增强

- 提高 AI 生成卡片的密集资料识别权重：列表型考点、题目和带问号的解析会更积极地转化为复习卡，不再对长资料保守少生成。
- 将单份资料的目标卡片上限从 80 提升到 120，单个资料窗口建议数量从最多 24 提升到 30，适配题库、讲义和高频考点清单。
- 将查漏补卡阈值从约 45% 提升到约 65%，并放宽大资料补卡最低覆盖封顶，减少“资料很多但卡片太少”的情况。
- 补充超密集资料生成计划测试，验证上百条明确考点会得到更高目标数量并触发更积极的查漏补卡；验证知识空间 targeted `flutter test` 74 项和 targeted `flutter analyze` 通过。

## 2026-06-20 全项目静态检查收口

- 复查旧知识卡页面、旧三 Tab 和旧管理页文件名在 `lib/` 与 `test/` 中已无残留引用，避免删除旧主体验后留下编译断点。
- 清理睡眠记录页 3 个冗余 provider import，让全项目 `flutter analyze` 从 3 条 info 恢复到 `No issues found`。
- 重新验证知识空间 targeted `flutter test` 74 项通过，并完成全项目 `flutter analyze` 通过。

## 2026-06-20 旧知识卡路由回归锁定

- 补充真实 `GrowthOSApp` 路由回归测试，覆盖 `/plan/study/knowledge/add`、`import`、`sources`、`archive`、`export`、`templates`、`goal`、`edit/:id`、`onboarding` 等旧路径全部进入新知识空间工作台。
- 验证 `/plan/study/flash-review` 进入空间选择页，`/plan/study/knowledge/review` 进入新闪卡复习页，且这些 root 路由都不会被主底部导航挤压。
- 测试中同步断言旧主流程文案 `AI 导入 / 全部复习 / 目标模板` 不出现；验证知识空间 targeted `flutter test` 75 项和全项目 `flutter analyze` 通过。

## 2026-06-20 知识空间多尺寸视觉烟测

- 补充桌面宽屏工作台 smoke test，验证空间主页、最近资料、最近知识卡和知识库抽屉在 1280x900 尺寸下稳定渲染，不触发布局异常。
- 补充小屏长内容复习卡 smoke test，验证长问题、长答案和长解析在 360x640 尺寸下可滚动展示，评分按钮仍可用。
- 重新验证知识空间 targeted `flutter test` 77 项和全项目 `flutter analyze` 通过，为后续真实设备视觉 QA 提供更强回归保障。
