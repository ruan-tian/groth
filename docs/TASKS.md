# Growth OS 开发任务清单

> 每个任务完成后标记 `[x]`，开发前先读对应设计文档
>
> **省 token**: 只读当前 Phase 对应的设计文档，不要一次全读

---

## Phase 0 - 项目骨架
> 设计文档: `markDown/markDown1780645408850.md`

- [x] Flutter 项目创建 + 依赖引入 (riverpod, go_router, drift, fl_chart, freezed, json_annotation, shared_preferences, path_provider)
- [x] 目录结构搭建 (lib/app, lib/core, lib/features, lib/shared)
- [x] 主题系统 (亮色/暗色, lib/app/theme.dart)
- [x] 路由系统 (GoRouter + 5 Tab: 首页/学习/健身/日记/我的)
- [x] 5 个空页面 + 底部导航栏连通

## Phase 1 - 数据库层
> 设计文档: `markDown/markDown1780645390737.md` + `markDown/markDown1780645404393.md`

- [x] Drift 数据库入口 (AppDatabase, lib/core/database/)
- [x] study_record 表
- [x] fitness_record 表
- [x] fitness_exercise 表 (1:N 关联 fitness_record)
- [x] body_metric 表
- [x] daily_journal 表
- [x] focus_session 表
- [x] growth_exp_log 表
- [x] app_setting 表 (KV)
- [x] ai_config 表
- [x] backup_record 表
- [x] build_runner 生成代码 + 验证

## Phase 2 - 数据访问层 (Repository)
> 设计文档: `markDown/markDown1780645404393.md`

- [x] StudyRepository (CRUD + 按日期/范围查询 + 总时长统计)
- [x] FitnessRepository (CRUD + 按日期/范围查询 + 总时长统计)
- [x] JournalRepository (CRUD + 按日期查询)
- [x] ExpRepository (插入经验日志 + 总经验查询)
- [x] SettingRepository (KV 读写)
- [x] AiConfigRepository (配置 CRUD)

## Phase 3 - 业务逻辑层 (Service)
> 设计文档: `markDown/markDown1780645390737.md` (经验值公式) + `markDown/markDown1780645404393.md`

- [x] ExpService (学习经验/健身经验/日记经验计算 + 等级计算)
- [x] StatisticsService (今日统计/周统计/月统计/年统计)
- [x] BackupService (JSON 导出/导入)

## Phase 4 - 状态管理层 (Provider)
> 设计文档: `markDown/markDown1780645404393.md`

- [x] Repository Providers
- [x] Service Providers
- [x] Dashboard Provider (今日数据 + 等级 + 经验)
- [x] Study Records Provider
- [x] Fitness Records Provider
- [x] Settings Provider

## Phase 5 - 首页 Dashboard
> 设计文档: `markDown/markDown1780645395947.md` (首页线框图)

- [x] 顶部欢迎区 (问候语 + 日期)
- [x] 成长等级卡片 (等级名 + 经验条 + EXP 数值)
- [x] 今日概览 (学习时长/健身时长/日记状态)
- [x] 今日任务列表
- [x] 7 天成长趋势折线图 (fl_chart)
- [x] 快捷操作按钮 (添加学习/添加健身/写日记)

## Phase 6 - 学习模块
> 设计文档: `markDown/markDown1780645395947.md` + `markDown/markDown1780645384291.md` (UC01)

- [x] 学习首页 (今日学习时长/本周时长/最近记录/科目分布)
- [x] 添加学习记录 - 简单模式 (内容/时长/备注)
- [x] 添加学习记录 - 专业模式 (科目/章节/时间/专注度/难度/掌握度/收获/问题)
- [x] 简单/专业模式切换
- [x] 学习记录列表 + 编辑/删除
- [x] 经验值自动计算 + 写入 growth_exp_log

## Phase 7 - 健身模块
> 设计文档: `markDown/markDown1780645395947.md` + `markDown/markDown1780645384291.md` (UC02)

- [x] 健身首页 (今日训练时长/本周次数/最近训练/体重曲线)
- [x] 添加健身记录 - 简单模式 (部位/时长/备注)
- [x] 添加健身记录 - 专业模式 (标题/部位/时间/强度/疲劳/动作列表/感受)
- [x] 动作列表管理 (名称/重量/组数/次数/休息)
- [x] 健身记录列表 + 编辑/删除
- [x] 身体数据记录 (体重/体脂/胸围/腰围/臀围/臂围/大腿围)
- [x] 经验值自动计算 + 写入 growth_exp_log

## Phase 8 - 日记模块
> 设计文档: `markDown/markDown1780645395947.md` + `markDown/markDown1780645384291.md` (UC04)

- [x] 日记首页 (今日复盘入口/最近日记/标签筛选)
- [x] 写日记页面 (标题/心情/标签/正文)
- [x] 引导问题 (完成了什么/哪里不好/明天最重要的事)
- [x] 日记详情页
- [x] 日记列表 + 编辑/删除
- [x] 经验值自动计算 + 写入 growth_exp_log

## Phase 9 - 基础统计
> 设计文档: `markDown/markDown1780645390737.md` (统计 SQL)

- [x] 日统计 (今日学习时长/健身时长/经验值)
- [x] 周统计 (本周趋势)
- [x] 月统计 (本月趋势)
- [x] 学习热力图 (可选)

## Phase 10 - 设置模块
> 设计文档: `markDown/markDown1780645395947.md` (我的页面)

- [x] 我的页面 (数据管理/AI设置/偏好设置)
- [x] 主题切换 (亮色/暗色)
- [x] 本地备份 (JSON 导出)
- [x] 本地恢复 (JSON 导入)

## Phase 11 - 番茄钟 (第二阶段)
> 设计文档: `markDown/markDown1780645427358.md` (专注模块)

- [x] 番茄钟页面 (25/45/90 分钟 + 自定义)
- [x] 白噪音播放 (雨声/海浪/森林/咖啡馆/白噪声)
- [x] 专注记录写入 focus_session
- [x] 关联学习记录 (可选)

## Phase 12 - AI 模块 (第三阶段)
> 设计文档: `markDown/markDown1780645427358.md` (AI模块) + `markDown/markDown1780645390737.md` (ai_config)

- [x] AI 设置页面 (API地址/Key/模型名称)
- [x] API Key 加密存储 + 脱敏展示
- [x] 学习分析 (读取本地数据 -> 用户确认 -> 调用 AI)
- [x] 健身分析
- [x] 成长周报/月报

## Phase 13 - 优化与测试
> 设计文档: `markDown/markDown1780645427358.md` (非功能需求)

- [x] 启动时间优化 (<=2s)
- [x] 页面切换优化 (<=300ms)
- [x] 列表性能优化 (大数量场景)
- [x] 单元测试 (ExpService / Repository)
- [x] Widget 测试 (关键页面)

## Phase 14 - 排序与分组功能

- [x] 创建通用排序按钮组件 (lib/shared/widgets/sort_button.dart)
  - 支持三种排序方式: 时间最新、时间最早、经验值最高
  - PopupMenuButton 显示当前排序方式
- [x] 创建通用日期分组列表组件 (lib/shared/widgets/date_grouped_list.dart)
  - 按真实系统日期分组
  - 显示日期标题: 今天、昨天、具体日期 (YYYY-MM-DD)
  - 每组显示记录数量
- [x] 学习模块排序功能
  - 添加 SortButton 到学习页面
  - 实现按时间/经验值排序逻辑
- [x] 学习模块日期分组显示
  - 使用 DateGroupedList 显示学习记录
  - 按日期分组显示
- [x] 健身模块排序功能
  - 添加 SortButton 到健身页面
  - 实现按时间/经验值排序逻辑
- [x] 健身模块日期分组显示
  - 使用 DateGroupedList 显示健身记录
  - 按日期分组显示
- [x] 日记模块排序功能
  - 添加 SortButton 到日记页面
  - 实现按时间/经验值排序逻辑
- [x] 日记模块日期分组显示
  - 使用 DateGroupedList 显示日记
  - 按日期分组显示
- [x] flutter analyze 通过

## Phase 15 - UI 改造与视觉优化

- [x] 接入本地宠物图片资源并在 `pubspec.yaml` 声明 `assets/pet/`
- [x] 优化 Dashboard 首屏结构：欢迎区、宠物画布、等级卡、今日概览、趋势图
- [x] 重写通用卡片、指标卡、主按钮、分区标题组件，统一圆角、阴影、间距与响应式表现
- [x] 对齐 Growth OS 色板，弱化单一紫色风格，强化本地成长/自然感
## Phase 16 - 参考图 UI 二次重构

- [x] 识别并提炼 7 张参考图的白底紫橙视觉语言、橘猫陪伴元素、模块卡片结构与底部导航风格
- [x] 将设计系统切换为深海军蓝 + 高饱和紫 + 暖橙点缀，并同步新旧主题色入口
- [x] 新增模块 Hero、功能入口卡、柔和进度条等通用 UI 组件
- [x] 重构 Dashboard 首页：陪伴 Hero、等级卡、今日概览、趋势与功能入口
- [x] 重构学习、健身、成长日记、我的页面首页骨架，保留原有 provider、路由与关键操作
- [x] 同步 Dashboard / Study widget 测试，覆盖新版文案与核心交互
- [x] `flutter analyze` 与 `flutter test` 通过

## Phase 17 - 天气与日记体验修复

- [x] 修复天气刷新成功但提示失败的问题，兼容和风天气字符串数值字段
- [x] Dashboard 天气弹窗自动加载空气质量与穿衣指数
- [x] 重构 WeatherPetCard 为渐变、粒子、气泡与完整小猫插画卡片
- [x] 日记列表点击启用新版沉浸式详情页
- [x] 优化 WeatherPetCard 排版透明度、居中悬浮窗与粒子动画性能

## Phase 18 - 小猫日记

- [x] 新增独立 `pet_diaries` 数据表、PetDiary 仓库与 schema v14 迁移
- [x] 新增 `PetDiaryService.ensureTodayDiary()`，支持早上 6 点后幂等生成、无授权/无 AI 配置 pending 状态
- [x] 新增 `PetDiaryPromptBuilder`，严格 JSON 输出并只发送本地摘要，不发送用户完整日记正文
- [x] 宠物小窝新增“甜甜的小日记”入口，替换旧“悄悄话”模块
- [x] 新增 `/pet-diary` 粉色日记本详情页，包含三格漫画分镜、心情贴纸、横线纸正文与重新生成
- [x] 设置页新增 `pet_diary_auto_enabled` 自动生成开关与隐私确认说明
- [x] 新增 PetDiaryService 单元测试，覆盖 6 点前、幂等、pending 和隐私 prompt 边界
## Phase 19 - 宠物中心视觉与反馈重构

- [x] 新增宠物中心素材批处理脚本 `scripts/process_pet_center_images.py`
- [x] 用 `rembg` 处理 `picture/home` 素材并输出到 `assets/images/pet_center/`
- [x] 声明宠物中心背景、前景、宠物、装饰、粒子和效果资源目录
- [x] 新增 `PetCenterAssets` 集中管理新资源路径
- [x] 重构 `PetSceneHero` 为房间背景、柔光、粒子、地面、阴影、宠物、家具、气泡分层场景
- [x] 接入宠物中心状态投影，支持 wave/read/sleep/happy/think/idle 姿势映射
- [x] 新增宠物中心资源加载测试

## Phase 20 - 宠物中心关联页面精修

- [x] 微调 `PetSceneHero` 气泡到 Hero 顶部侧边，避免遮挡宠物主体
- [x] 重构宠物中心下半页为成长身份卡、今日成长摘要、小日记和小窝行动区
- [x] 明确宠物等级从个人成长经验派生，不新增宠物独立经验系统
- [x] 新增 `/pet-history` 成长档案页，展示模块贡献、连续活跃、升级里程碑和最近经验记录
- [x] 新增顶级 `/pet-ai-analysis`，保留 `/settings/pet-ai-analysis` 兼容入口
- [x] 重设计宠物 AI 分析页为小窝纸感风格，并保留分析前数据预览确认
- [x] 新增 `/pet-settings` 宠物专属设置页，支持宠物名称、自动小日记、AI 配置入口和隐私说明
- [x] 补充 `assets/pet/concerts/` 资源声明并扩展宠物资源加载测试
- [x] 将小窝透明 PNG 图标改为无底悬浮承载，移除黄色/彩色徽章底
- [x] 使用 `bubble_tail.png` 重做宠物气泡尾巴，并加宽气泡避免溢出
- [x] 新增 `/ai-config` 顶级入口并修复宠物设置跳转 API 配置首帧空白问题
## Phase 21 - 番茄钟横竖屏视觉重构

- [x] 新增 `scripts/process_focus_images.py`，处理 `picture/tomato_clock` 素材并输出 `assets/images/focus/`
- [x] 声明番茄钟背景、前景、小猫、图标、光效、粒子与状态弹窗资源目录
- [x] 新增 `FocusAssets` 与专注/白噪音选项数据，集中管理素材路径
- [x] 重构 `FocusPage` 为横屏/竖屏响应式纸感设置页
- [x] 重构 `FocusSessionPage` 为横屏/竖屏响应式夜晚专注计时页
- [x] 接入完成、休息、中断弹窗素材并保留现有计时、音频、落库、EXP 逻辑
- [x] 新增番茄钟资源加载测试与横竖屏核心渲染测试
# 2026-06-08 - Journal writing UI refresh

- [x] Add `scripts/process_journal_images.py` and normalized `assets/images/journal/` assets.
- [x] Add `JournalAssets` constants for journal backgrounds, cats, decor, and status images.
- [x] Rebuild the write journal page as a soft pink paper writing desk with mood cards, tools, tags, summary, and bottom actions.
- [x] Rebuild the full-screen Quill editor as an immersive lined-paper editor with bottom writing tools.
- [x] Restyle the edit journal page while preserving update, EXP, provider refresh, and database behavior.

# 2026-06-08 - Plan module visual headers and reminder timers

- [x] Add `scripts/process_plan_module_images.py` and normalized `assets/images/plan_modules/` assets.
- [x] Add `PlanModuleAssets`, `PlanModuleVisualHeader`, and `PlanModuleActionImageCard`.
- [x] Replace study, fitness, journal, diet, and sleep page top sections with 4-image module carousels plus a main action image card.
- [x] Add full-screen fitness training, water reminder, and sleep reminder timer pages.
- [x] Add reminder timer state/controller and local notification service using existing `app_setting` KV storage.

# 2026-06-09 - Plan module feedback fixes

- [x] Change the 4-image module header to automatic switching instead of manual paging.
- [x] Preserve full artwork in generated plan module images and add speech-bubble copy per image.
- [x] Add clear floating action buttons/copy on the single lower action image.
- [x] Remove duplicate icon-only journal write entry.
- [x] Extend water reminder choices with custom minutes and schedule sleep-time reminders immediately when selected.
