# Growth OS 系统功能详细文档

> 版本: v1.0  
> 更新时间: 2026-06-05  
> 完成度: 80%

---

## 目录

1. [系统概述](#一系统概述)
2. [技术架构](#二技术架构)
3. [首页 Dashboard](#三首页-dashboard)
4. [学习模块](#四学习模块)
5. [健身模块](#五健身模块)
6. [日记模块](#六日记模块)
7. [统计模块](#七统计模块)
8. [设置模块](#八设置模块)
9. [番茄钟模块](#九番茄钟模块)
10. [AI 模块](#十ai-模块)
11. [任务系统](#十一任务系统)
12. [宠物系统](#十二宠物系统)
13. [数据模型](#十三数据模型)
14. [状态管理](#十四状态管理)
15. [路由系统](#十五路由系统)

---

## 一、系统概述

### 1.1 项目定位

Growth OS 是一款**本地化成长管理系统**，帮助用户管理学习、健身、复盘与成长等级。

### 1.2 核心特性

- 无登录、无注册、无云端依赖
- 数据完全本地保存
- 支持 Windows / Android / iOS

### 1.3 技术栈

| 技术 | 用途 |
|------|------|
| Flutter | 跨平台框架 |
| flutter_riverpod | 状态管理 |
| go_router | 路由管理 |
| drift | 本地数据库 (SQLite) |
| fl_chart | 图表组件 |
| freezed + json_annotation | 数据序列化 |

---

## 二、技术架构

### 2.1 项目结构

```
lib/
├── main.dart                    # 应用入口
├── app/                         # 应用配置
│   ├── app.dart                 # MaterialApp 配置
│   ├── router.dart              # GoRouter 路由配置
│   └── theme.dart               # 主题系统 (亮色/暗色)
├── core/                        # 核心层
│   ├── database/                # 数据库
│   │   ├── app_database.dart    # Drift 数据库入口
│   │   ├── tables.dart          # 表定义 (学习/健身/日记等)
│   │   ├── tables_extra.dart    # 表定义 (任务/模板等)
│   │   └── pet_tables.dart      # 表定义 (宠物)
│   ├── repositories/            # 数据访问层
│   │   ├── study_repository.dart
│   │   ├── fitness_repository.dart
│   │   ├── journal_repository.dart
│   │   ├── exp_repository.dart
│   │   ├── setting_repository.dart
│   │   ├── ai_config_repository.dart
│   │   ├── task_repository.dart
│   │   └── focus_repository.dart
│   ├── services/                # 业务逻辑层
│   │   ├── exp_service.dart     # 经验值计算
│   │   ├── statistics_service.dart # 统计服务
│   │   ├── backup_service.dart  # 备份服务
│   │   └── ai_service.dart      # AI 服务
│   └── utils/                   # 工具类
│       ├── performance_utils.dart
│       └── lazy_loader.dart
├── features/                    # 功能模块
│   ├── dashboard/               # 首页
│   ├── study/                   # 学习模块
│   ├── fitness/                 # 健身模块
│   ├── journal/                 # 日记模块
│   ├── statistics/              # 统计模块
│   ├── settings/                # 设置模块
│   ├── focus/                   # 番茄钟模块
│   ├── ai/                      # AI 模块
│   └── pet/                     # 宠物系统
└── shared/                      # 共享层
    ├── providers/               # 状态管理
    ├── widgets/                 # 通用组件
    └── models/                  # 数据模型
```

### 2.2 数据流

```
用户操作 → Widget → Provider → Repository → Database
    ↑                                          ↓
    └──────── UI 更新 ← Provider ← Repository ←┘
```

---

## 三、首页 Dashboard

### 3.1 页面结构

```
┌─────────────────────────────┐
│         PetCanvas           │ ← 宠物画布 (100dp)
├─────────────────────────────┤
│       WelcomeSection        │ ← 欢迎区 (问候语 + 日期)
├─────────────────────────────┤
│        LevelCard            │ ← 成长等级卡片
├─────────────────────────────┤
│      TodayOverview          │ ← 今日概览
├─────────────────────────────┤
│       TodayTasks            │ ← 今日任务 (备忘录风格)
├─────────────────────────────┤
│     GrowthTrendChart        │ ← 7天成长趋势
├─────────────────────────────┤
│      QuickActions           │ ← 快捷操作按钮
└─────────────────────────────┘
```

### 3.2 功能详细说明

#### 3.2.1 PetCanvas (宠物画布)

| 属性 | 说明 |
|------|------|
| 位置 | Dashboard 顶部 |
| 高度 | 100dp |
| 状态 | idle / peek / happy / sleepy |

**操作逻辑**:
- 点击 → 进入成长伙伴中心 (PetCenterSheet)
- 启动时 30% 概率显示 peek 状态 (3秒后回到 idle)
- 完成目标时显示 happy 状态 (3秒后回到 idle)
- 48小时未记录显示 sleepy 状态

**动画效果**:
- `AnimatedSwitcher` 切换状态图片
- `FadeTransition` 淡入淡出
- `SlideTransition` 滑入滑出
- `ScaleTransition` 弹跳效果 (happy 状态)

#### 3.2.2 WelcomeSection (欢迎区)

| 属性 | 说明 |
|------|------|
| 问候语 | 根据时间显示: 早上好/下午好/晚上好 |
| 日期 | 显示今天日期 (X月X日 周X) |

#### 3.2.3 LevelCard (成长等级卡片)

| 属性 | 说明 |
|------|------|
| 等级 | Lv.X 等级名称 |
| 经验条 | 进度条显示当前等级进度 |
| EXP | 显示当前EXP / 升级所需EXP |

**等级名称**:
- Lv1-4: 新手
- Lv5-9: 入门者
- Lv10-19: 学习者
- Lv20-29: 进阶者
- Lv30-49: 高手
- Lv50-79: 大师
- Lv80+: 传奇

**操作逻辑**:
- 点击 → 显示等级详情弹窗 (LevelDetailSheet)

#### 3.2.4 TodayOverview (今日概览)

| 属性 | 说明 |
|------|------|
| 学习时长 | 今日学习总时长 (分钟) |
| 健身时长 | 今日健身总时长 (分钟) |
| 日记状态 | 已完成/未完成 |

#### 3.2.5 TodayTasks (今日任务)

**组件结构**:
```
┌─────────────────────────────┐
│ ✓ 今日任务           2/5  + │ ← 标题 + 统计 + 添加按钮
├─────────────────────────────┤
│ 09:00 ● 学习 Flutter        │ ← 任务列表
│        09:00-11:00      ✓   │
├─────────────────────────────┤
│ 14:00 ● 健身                │
│        14:00-15:00      ○   │
├─────────────────────────────┤
│      还有 3 个任务 >        │ ← 展开按钮
└─────────────────────────────┘
```

**功能**:
- 添加任务 (+ 按钮)
- 完成任务 (点击复选框，带动画)
- 删除任务 (右滑删除)
- 展开/收起任务列表
- 使用模板 (模板按钮)
- 查看历史 (更多按钮)

**任务状态**:
- 进行中 (黄色指示器)
- 待开始 (灰色指示器)
- 已过期 (红色指示器)
- 已完成 (绿色指示器 + 划线)

**排序规则**:
1. 未完成在前，已完成在后
2. 进行中的优先
3. 按开始时间排序

#### 3.2.6 GrowthTrendChart (成长趋势)

| 属性 | 说明 |
|------|------|
| 时间范围 | 最近 7 天 |
| 数据 | 每日经验值 |
| 图表类型 | 折线图 (fl_chart) |

#### 3.2.7 QuickActions (快捷操作)

| 按钮 | 功能 |
|------|------|
| 添加学习 | 跳转到添加学习记录页面 |
| 添加健身 | 跳转到添加健身记录页面 |
| 写日记 | 跳转到写日记页面 |

---

## 四、学习模块

### 4.1 页面结构

#### 4.1.1 学习首页 (StudyPage)

```
┌─────────────────────────────┐
│           学习              │ ← AppBar
├─────────────────────────────┤
│  ┌─────────┐ ┌─────────┐   │
│  │今日学习  │ │本周学习  │   │ ← 统计卡片
│  │ 120min  │ │  8.5h   │   │
│  └─────────┘ └─────────┘   │
├─────────────────────────────┤
│  [开始番茄钟] [添加学习记录] │ ← 快捷操作
├─────────────────────────────┤
│      今日学习进度           │
│  ████████████░░░ 80%        │ ← 进度条
├─────────────────────────────┤
│      科目分布 (近30天)      │
│  数学 ████████ 60%          │ ← 科目分布图
│  英语 ████ 30%              │
│  编程 █ 10%                 │
├─────────────────────────────┤
│        最近记录             │
│  ┌─────────────────────┐   │
│  │ 📚 数据结构 90min   │   │ ← 记录列表
│  │    +18 EXP          │   │
│  └─────────────────────┘   │
│  ┌─────────────────────┐   │
│  │ 📖 操作系统 60min   │   │
│  │    +12 EXP          │   │
│  └─────────────────────┘   │
└─────────────────────────────┘
```

#### 4.1.2 添加学习记录 (AddStudyRecordPage)

```
┌─────────────────────────────┐
│        添加学习记录         │ ← AppBar
├─────────────────────────────┤
│  [简单模式] [专业模式]      │ ← 模式切换
├─────────────────────────────┤
│  ┌─────────────────────┐   │
│  │ 学习内容 *          │   │ ← 标题输入
│  └─────────────────────┘   │
│  ┌─────────────────────┐   │
│  │ 学习时长 (分钟) *   │   │ ← 时长输入
│  └─────────────────────┘   │
│  ┌─────────────────────┐   │
│  │ 备注                │   │ ← 备注输入
│  └─────────────────────┘   │
│                             │
│  [保存记录]                 │ ← 保存按钮
└─────────────────────────────┘
```

**专业模式额外字段**:
- 科目
- 章节
- 开始时间 / 结束时间
- 专注度 (1-5 滑块)
- 难度 (1-5 滑块)
- 掌握度 (1-5 滑块)
- 学习收获
- 遗留问题

#### 4.1.3 学习记录详情 (StudyRecordDetailPage)

```
┌─────────────────────────────┐
│        学习记录详情         │ ← AppBar
│              [编辑] [删除]  │
├─────────────────────────────┤
│  数据结构                   │ ← 标题
│  +18 EXP                    │ ← 经验值
├─────────────────────────────┤
│  模式: 专业                 │
│  科目: 计算机科学           │
│  章节: 第三章 树与二叉树    │
│  时长: 90 分钟              │
├─────────────────────────────┤
│  专注度: ████░ 4/5          │
│  难度:   ███░░ 3/5          │
│  掌握度: ████░ 4/5          │
├─────────────────────────────┤
│  学习收获                   │
│  理解了二叉树的遍历算法...  │
├─────────────────────────────┤
│  遗留问题                   │
│  红黑树的旋转操作还不熟...  │
└─────────────────────────────┘
```

### 4.2 操作逻辑

#### 4.2.1 添加学习记录流程

```
1. 用户点击 "添加学习记录"
2. 跳转到 AddStudyRecordPage
3. 用户选择模式 (简单/专业)
4. 填写表单
5. 点击保存
6. 创建 StudyRecordsCompanion
7. 调用 StudyRepository.insertStudyRecord()
8. 计算经验值:
   - base = durationMinutes ~/ 10
   - focusBonus = focusLevel * 2
   - difficultyBonus = difficultyLevel * 2
   - reviewBonus = hasReview ? 5 : 0
   - total = base + focusBonus + difficultyBonus + reviewBonus
9. 插入经验日志 (ExpRepository.insertExpLog())
10. 更新经验值显示
11. 返回上一页
12. 显示 SnackBar "已保存，获得 X EXP"
```

#### 4.2.2 删除学习记录流程

```
1. 用户右滑记录或点击删除按钮
2. 显示确认对话框 "确定要删除「XXX」吗？"
3. 用户确认删除
4. 调用 StudyRepository.deleteStudyRecord()
5. 刷新列表
6. 显示 SnackBar "已删除"
```

#### 4.2.3 编辑学习记录流程

```
1. 用户点击编辑按钮
2. 跳转到编辑页面 (复用 AddStudyRecordPage)
3. 加载现有数据
4. 用户修改表单
5. 点击保存
6. 调用 StudyRepository.updateStudyRecord()
7. 重新计算经验值
8. 更新经验日志
9. 返回上一页
```

### 4.3 数据模型

**StudyRecord**:
| 字段 | 类型 | 说明 |
|------|------|------|
| id | int | 主键 |
| mode | String | 模式 (simple/professional) |
| title | String | 学习内容 |
| subject | String? | 科目 |
| chapter | String? | 章节 |
| startTime | int | 开始时间戳 |
| endTime | int | 结束时间戳 |
| durationMinutes | int | 学习时长 |
| focusLevel | int? | 专注度 (1-5) |
| difficultyLevel | int? | 难度 (1-5) |
| masteryLevel | int? | 掌握度 (1-5) |
| note | String? | 备注 |
| gain | String? | 学习收获 |
| problem | String? | 遗留问题 |
| expGained | int | 获得经验值 |
| createdAt | int | 创建时间戳 |
| updatedAt | int | 更新时间戳 |

### 4.4 Provider

| Provider | 类型 | 说明 |
|----------|------|------|
| todayStudyMinutesProvider | FutureProvider | 今日学习时长 |
| weeklyStudyMinutesProvider | FutureProvider | 本周学习时长 |
| recentStudyRecordsProvider | FutureProvider | 最近学习记录 |
| subjectDistributionProvider | FutureProvider | 科目分布 |
| studySortProvider | StateProvider | 排序方式 |

---

## 五、健身模块

### 5.1 页面结构

#### 5.1.1 健身首页 (FitnessPage)

```
┌─────────────────────────────┐
│           健身              │ ← AppBar
├─────────────────────────────┤
│  ┌─────────┐ ┌─────────┐   │
│  │今日训练  │ │本周训练  │   │ ← 统计卡片
│  │ 60min   │ │  4次    │   │
│  └─────────┘ └─────────┘   │
├─────────────────────────────┤
│  [添加训练记录] [记录身体数据] │ ← 快捷操作
├─────────────────────────────┤
│      今日健身进度           │
│  ████████████░░░ 80%        │ ← 进度条
├─────────────────────────────┤
│        体重曲线             │
│      📈 (图表区域)          │ ← 体重曲线图
├─────────────────────────────┤
│        最近训练             │
│  ┌─────────────────────┐   │
│  │ 💪 胸+三头 70min    │   │ ← 训练记录列表
│  │    +21 EXP          │   │
│  └─────────────────────┘   │
│  ┌─────────────────────┐   │
│  │ 🏋️ 背+二头 60min   │   │
│  │    +18 EXP          │   │
│  └─────────────────────┘   │
└─────────────────────────────┘
```

#### 5.1.2 添加健身记录 (AddFitnessRecordPage)

**简单模式**:
- 训练部位 (必填)
- 训练时长 (必填)
- 备注

**专业模式**:
- 训练标题
- 训练部位
- 开始时间 / 结束时间
- 强度 (1-5 滑块)
- 疲劳程度 (1-5 滑块)
- 训练感受
- 动作列表 (可添加多个)

**动作列表**:
```
┌─────────────────────────────┐
│  动作 1                     │
│  名称: 卧推                 │
│  重量: 60kg                 │
│  组数: 4                    │
│  次数: 12                   │
│  休息: 90秒                 │
├─────────────────────────────┤
│  动作 2                     │
│  名称: 哑铃飞鸟             │
│  重量: 15kg                 │
│  组数: 3                    │
│  次数: 15                   │
│  休息: 60秒                 │
├─────────────────────────────┤
│       [+ 添加动作]          │
└─────────────────────────────┘
```

### 5.2 操作逻辑

#### 5.2.1 添加健身记录流程

```
1. 用户点击 "添加训练记录"
2. 跳转到 AddFitnessRecordPage
3. 用户选择模式 (简单/专业)
4. 填写表单
5. 如果是专业模式，添加动作列表
6. 点击保存
7. 创建 FitnessRecordsCompanion
8. 调用 FitnessRepository.insertFitnessRecord()
9. 插入动作列表 (如果有)
10. 计算经验值:
    - base = durationMinutes ~/ 10
    - intensityBonus = intensityLevel * 3
    - exerciseBonus = exerciseCount * 2
    - completeBonus = hasFeeling ? 5 : 0
    - total = base + intensityBonus + exerciseBonus + completeBonus
11. 插入经验日志
12. 返回上一页
```

### 5.3 数据模型

**FitnessRecord**:
| 字段 | 类型 | 说明 |
|------|------|------|
| id | int | 主键 |
| mode | String | 模式 |
| title | String? | 训练标题 |
| bodyPart | String | 训练部位 |
| startTime | int | 开始时间戳 |
| endTime | int | 结束时间戳 |
| durationMinutes | int | 训练时长 |
| fatigueLevel | int? | 疲劳程度 (1-5) |
| intensityLevel | int? | 强度 (1-5) |
| feeling | String? | 训练感受 |
| note | String? | 备注 |
| expGained | int | 获得经验值 |
| createdAt | int | 创建时间戳 |
| updatedAt | int | 更新时间戳 |

**FitnessExercise**:
| 字段 | 类型 | 说明 |
|------|------|------|
| id | int | 主键 |
| fitnessRecordId | int | 关联健身记录ID |
| exerciseName | String | 动作名称 |
| sets | int | 组数 |
| reps | int | 次数 |
| weight | double? | 重量 (kg) |
| restSeconds | int? | 组间休息 (秒) |
| note | String? | 备注 |
| createdAt | int | 创建时间戳 |

---

## 六、日记模块

### 6.1 页面结构

#### 6.1.1 日记首页 (JournalPage)

```
┌─────────────────────────────┐
│         成长日记            │ ← AppBar
├─────────────────────────────┤
│  ┌─────────────────────┐   │
│  │ 📖 今日复盘         │   │ ← 今日复盘卡片
│  │ 已写 1 篇           │   │
│  │ [开始写今日复盘]    │   │
│  └─────────────────────┘   │
├─────────────────────────────┤
│      今日日记进度           │
│  ████████████░░░ 100%       │ ← 进度条
├─────────────────────────────┤
│        标签筛选             │
│  [学习] [健身] [情绪] [反思] │ ← 标签筛选
├─────────────────────────────┤
│  排序: 最新 ▼               │ ← 排序按钮
├─────────────────────────────┤
│        最近日记             │
│  ┌─────────────────────┐   │
│  │ 📝 充实的一天       │   │ ← 日记列表
│  │ 😊 学习 · 健身      │   │
│  │ 2024-06-05          │   │
│  └─────────────────────┘   │
│  ┌─────────────────────┐   │
│  │ 📝 今日训练不错     │   │
│  │ 😐 健身             │   │
│  │ 2024-06-04          │   │
│  └─────────────────────┘   │
└─────────────────────────────┘
```

#### 6.1.2 写日记页面 (WriteJournalPage)

```
┌─────────────────────────────┐
│          写日记             │ ← AppBar
├─────────────────────────────┤
│  ┌─────────────────────┐   │
│  │ 标题 *              │   │ ← 标题输入
│  │ 例如：充实的一天    │   │
│  └─────────────────────┘   │
├─────────────────────────────┤
│        今天心情             │
│  😊    😐    😢    😡    🤔  │ ← 心情选择器
│  开心  平静  难过  生气  思考│
├─────────────────────────────┤
│          标签               │
│  [学习] [健身] [情绪]       │ ← 标签选择器
│  [反思] [感恩] [目标]       │
├─────────────────────────────┤
│        引导问题             │
│  ┌─────────────────────┐   │
│  │ 今天完成了什么？ +  │   │ ← 引导问题
│  └─────────────────────┘   │
│  ┌─────────────────────┐   │
│  │ 今天哪里做得不好？ +│   │
│  └─────────────────────┘   │
│  ┌─────────────────────┐   │
│  │ 明天最重要的一件事？+│   │
│  └─────────────────────┘   │
├─────────────────────────────┤
│  ┌─────────────────────┐   │
│  │ 正文 *              │   │ ← 正文输入
│  │ 写下今天的复盘...   │   │
│  │                     │   │
│  │                     │   │
│  └─────────────────────┘   │
├─────────────────────────────┤
│        [保存日记]           │ ← 保存按钮
└─────────────────────────────┘
```

#### 6.1.3 日记详情页 (JournalDetailPage)

```
┌─────────────────────────────┐
│         日记详情            │ ← AppBar
│            [编辑] [删除]    │
├─────────────────────────────┤
│  充实的一天                 │ ← 标题
│  😊                         │ ← 心情
├─────────────────────────────┤
│  +10 EXP                    │ ← 经验值
├─────────────────────────────┤
│  标签                       │
│  [学习] [健身]              │ ← 标签
├─────────────────────────────┤
│  基础信息                   │
│  日期: 2024-06-05           │
│  字数: 350 字               │
│  记录时间: 2024/06/05 22:30 │
├─────────────────────────────┤
│  正文                       │
│  ┌─────────────────────┐   │
│  │ 今天完成了 Flutter  │   │ ← 正文内容
│  │ 第三章的学习...     │   │
│  └─────────────────────┘   │
└─────────────────────────────┘
```

### 6.2 操作逻辑

#### 6.2.1 写日记流程

```
1. 用户点击 "开始写今日复盘"
2. 跳转到 WriteJournalPage
3. 填写标题 (必填)
4. 选择心情 (可选)
5. 选择标签 (可选)
6. 点击引导问题插入到正文 (可选)
7. 填写正文 (必填)
8. 点击保存
9. 计算字数
10. 计算经验值:
    - base = 5
    - wordBonus = wordCount ~/ 100
    - total = min(base + wordBonus, 20)  // 每日上限20
11. 创建 DailyJournalsCompanion
12. 调用 JournalRepository.insertJournal()
13. 插入经验日志
14. 返回上一页
```

### 6.3 数据模型

**DailyJournal**:
| 字段 | 类型 | 说明 |
|------|------|------|
| id | int | 主键 |
| journalDate | String | 日记日期 (YYYY-MM-DD) |
| title | String | 标题 |
| content | String | 正文内容 |
| mood | String? | 心情 (happy/neutral/sad/angry/thinking) |
| tags | String? | 标签 (JSON数组) |
| wordCount | int | 字数 |
| expGained | int | 获得经验值 |
| createdAt | int | 创建时间戳 |
| updatedAt | int | 更新时间戳 |

### 6.4 心情映射

| Key | Emoji | 中文 |
|-----|-------|------|
| happy | 😊 | 开心 |
| neutral | 😐 | 平静 |
| sad | 😢 | 难过 |
| angry | 😡 | 生气 |
| thinking | 🤔 | 思考 |

### 6.5 预设标签

- 学习
- 健身
- 情绪
- 反思
- 感恩
- 目标
- 阅读
- 工作

---

## 七、统计模块

### 7.1 页面结构

```
┌─────────────────────────────┐
│           统计              │ ← AppBar
├─────────────────────────────┤
│  [日统计] [周统计] [月统计] │ ← TabBar
├─────────────────────────────┤
│                             │
│       统计内容区域          │ ← TabBarView
│                             │
└─────────────────────────────┘
```

### 7.2 日统计 (DailyStatsPage)

```
┌─────────────────────────────┐
│  ┌───────┐ ┌───────┐       │
│  │学习时长│ │健身时长│       │ ← 统计卡片
│  │120min │ │ 60min │       │
│  └───────┘ └───────┘       │
│  ┌───────┐ ┌───────┐       │
│  │日记篇数│ │获得经验│       │
│  │  1篇  │ │ +50   │       │
│  └───────┘ └───────┘       │
├─────────────────────────────┤
│        今日评价             │
│  "今天表现不错，继续保持！" │
└─────────────────────────────┘
```

### 7.3 周统计 (WeeklyStatsPage)

```
┌─────────────────────────────┐
│  ┌───────┐ ┌───────┐       │
│  │总学习  │ │总健身  │       │ ← 汇总卡片
│  │ 8.5h  │ │ 4.2h  │       │
│  └───────┘ └───────┘       │
│  ┌───────┐                  │
│  │总经验  │                  │
│  │ +350  │                  │
│  └───────┘                  │
├─────────────────────────────┤
│        7天趋势              │
│      📈 (折线图)            │ ← 趋势图表
├─────────────────────────────┤
│        每日明细             │
│  06/05 周三 120min +50 EXP  │ ← 每日明细列表
│  06/04 周二  90min +35 EXP  │
│  06/03 周一  60min +25 EXP  │
└─────────────────────────────┘
```

### 7.4 月统计 (MonthlyStatsPage)

```
┌─────────────────────────────┐
│  ┌───────┐ ┌───────┐       │
│  │总学习  │ │总健身  │       │ ← 汇总卡片
│  │ 32h   │ │ 18h   │       │
│  └───────┘ └───────┘       │
│  ┌───────┐                  │
│  │总经验  │                  │
│  │+1200  │                  │
│  └───────┘                  │
├─────────────────────────────┤
│        12个月趋势           │
│      📊 (柱状图)            │ ← 趋势图表
├─────────────────────────────┤
│  ◀ 2024年6月 ▶              │ ← 月份选择器
│  本月详情:                   │
│  学习: 32h | 健身: 18h      │
│  经验: +1200                │
└─────────────────────────────┘
```

---

## 八、设置模块

### 8.1 页面结构

```
┌─────────────────────────────┐
│           设置              │ ← AppBar
├─────────────────────────────┤
│        数据管理             │
│  ┌─────────────────────┐   │
│  │ 📦 本地备份         │   │
│  │    将数据导出到本地 │   │
│  └─────────────────────┘   │
│  ┌─────────────────────┐   │
│  │ 📥 本地恢复         │   │
│  │    从本地文件恢复   │   │
│  └─────────────────────┘   │
├─────────────────────────────┤
│        AI 设置              │
│  ┌─────────────────────┐   │
│  │ 🤖 AI 配置          │   │
│  │    设置API地址/Key  │   │
│  └─────────────────────┘   │
│  ┌─────────────────────┐   │
│  │ 📊 AI 分析          │   │
│  │    学习/健身/成长   │   │
│  └─────────────────────┘   │
├─────────────────────────────┤
│        偏好设置             │
│  ┌─────────────────────┐   │
│  │ 🌙 主题模式         │   │
│  │    跟随系统         │   │
│  └─────────────────────┘   │
│  ┌─────────────────────┐   │
│  │ ⚙️ 默认记录模式     │   │
│  │    简单             │   │
│  └─────────────────────┘   │
│  ┌─────────────────────┐   │
│  │ 📋 今日目标         │   │
│  │    学习120min...    │   │
│  └─────────────────────┘   │
├─────────────────────────────┤
│      Growth OS v0.1.0       │
└─────────────────────────────┘
```

### 8.2 功能详细说明

#### 8.2.1 本地备份

**操作流程**:
```
1. 用户点击 "本地备份"
2. 跳转到备份页面
3. 点击 "立即备份" 按钮
4. 系统调用 BackupService.saveBackupToFile()
5. 导出所有数据为 JSON 文件
6. 保存到本地存储
7. 记录备份信息到数据库
8. 显示成功提示
```

**备份内容**:
- 学习记录
- 健身记录
- 健身动作
- 身体数据
- 日记
- 专注记录
- 经验日志
- 系统设置
- AI 配置
- 任务
- 任务模板

#### 8.2.2 本地恢复

**操作流程**:
```
1. 用户点击 "本地恢复"
2. 跳转到恢复页面
3. 点击 "从文件恢复" 按钮
4. 打开文件选择器 (仅 .json 文件)
5. 用户选择备份文件
6. 系统验证文件格式
7. 显示确认对话框 "恢复将覆盖现有数据"
8. 用户确认
9. 系统调用 BackupService.importFromJson()
10. 恢复所有数据
11. 显示成功提示
```

#### 8.2.3 AI 配置

**支持的 AI 厂商**:

| 厂商 | 默认模型 | 默认 API 地址 |
|------|----------|---------------|
| OpenAI | gpt-4o-mini | https://api.openai.com/v1 |
| DeepSeek | deepseek-chat | https://api.deepseek.com/v1 |
| Gemini | gemini-pro | https://generativelanguage.googleapis.com/v1 |
| 通义千问 | qwen-turbo | https://dashscope.aliyuncs.com/compatible-mode/v1 |
| 智谱 AI | glm-4-flash | https://open.bigmodel.cn/api/paas/v4 |
| 百川智能 | Baichuan4 | https://api.baichuan-ai.com/v1 |
| Moonshot | moonshot-v1-8k | https://api.moonshot.cn/v1 |
| MiniMax | abab6.5-chat | https://api.minimax.chat/v1 |
| 讯飞星火 | generalv3.5 | https://spark-api-open.xf-yun.com/v1 |
| 文心一言 | ernie-speed-128k | https://aip.baidubce.com/rpc/2.0/ai_custom/v1 |
| 自定义 | - | - |

**操作流程**:
```
1. 用户点击 "AI 配置"
2. 跳转到 AI 配置页面
3. 选择服务提供商
4. 填写 API 地址 (自动填充)
5. 填写 API Key
6. 填写模型名称 (自动填充)
7. 点击 "测试连接" (可选)
8. 点击 "保存配置"
9. 配置保存到数据库
```

#### 8.2.4 主题切换

**主题模式**:
- 亮色模式
- 暗色模式
- 跟随系统

**操作流程**:
```
1. 用户点击 "主题模式"
2. 显示底部弹窗选择器
3. 用户选择主题模式
4. 更新 themeModeProvider
5. 持久化到数据库
6. 主题立即切换
```

#### 8.2.5 默认记录模式

**模式选项**:
- 简单模式: 快速记录，只需填写基本内容
- 专业模式: 详细记录，包含更多字段和选项

#### 8.2.6 今日目标

**默认目标**:
- 学习: 120 分钟
- 健身: 45 分钟
- 写日记: 1 篇

**操作流程**:
```
1. 用户点击 "今日目标"
2. 显示目标编辑对话框
3. 用户修改目标值
4. 保存到数据库
5. 更新 dashboardProvider
```

---

## 九、番茄钟模块

### 9.1 页面结构

#### 9.1.1 番茄钟首页 (FocusPage)

```
┌─────────────────────────────┐
│          番茄钟             │ ← AppBar
├─────────────────────────────┤
│        选择时长             │
│  [25分钟] [45分钟] [90分钟] │ ← 时长选择
│  [自定义]                   │
├─────────────────────────────┤
│  ┌─────────────────────┐   │
│  │      任务标题       │   │ ← 任务标题输入
│  └─────────────────────┘   │
├─────────────────────────────┤
│        白噪音选择           │
│  [雨声] [海浪] [森林]       │ ← 声音选择
│  [咖啡馆] [白噪声] [无]     │
├─────────────────────────────┤
│      [开始专注]             │ ← 开始按钮
├─────────────────────────────┤
│      今日专注               │
│      45 分钟                │ ← 今日统计
├─────────────────────────────┤
│        最近记录             │
│  ┌─────────────────────┐   │
│  │ 🍅 学习 Flutter     │   │ ← 记录列表
│  │    25min ✓          │   │
│  └─────────────────────┘   │
└─────────────────────────────┘
```

#### 9.1.2 专注会话页面 (FocusSessionPage)

```
┌─────────────────────────────┐
│          专注中             │ ← AppBar
├─────────────────────────────┤
│                             │
│        ┌─────────┐         │
│        │  25:00  │         │ ← 倒计时显示
│        │ ██████░ │         │
│        └─────────┘         │
│                             │
├─────────────────────────────┤
│        [暂停] [取消]        │ ← 控制按钮
├─────────────────────────────┤
│        🌧️ 雨声播放中        │ ← 白噪音状态
└─────────────────────────────┘
```

### 9.2 操作逻辑

#### 9.2.1 开始专注流程

```
1. 用户选择时长 (25/45/90/自定义)
2. 输入任务标题 (可选)
3. 选择白噪音 (可选)
4. 点击 "开始专注"
5. 跳转到 FocusSessionPage
6. 开始倒计时
7. 播放白噪音 (如果选择了)
8. 倒计时结束
9. 保存专注记录到数据库
10. 计算经验值
11. 显示完成对话框
12. 询问是否关联学习记录
```

### 9.3 数据模型

**FocusSession**:
| 字段 | 类型 | 说明 |
|------|------|------|
| id | int | 主键 |
| type | String | 类型 (pomodoro/deep/custom) |
| title | String | 专注主题 |
| relatedStudyId | int? | 关联学习记录ID |
| startTime | int | 开始时间戳 |
| endTime | int | 结束时间戳 |
| durationMinutes | int | 专注时长 |
| completed | bool | 是否完成 |
| soundType | String? | 白噪音类型 |
| createdAt | int | 创建时间戳 |

---

## 十、AI 模块

### 10.1 页面结构

```
┌─────────────────────────────┐
│          AI 分析            │ ← AppBar
├─────────────────────────────┤
│  [学习分析] [健身分析] [成长报告] │ ← TabBar
├─────────────────────────────┤
│                             │
│        分析内容区域         │ ← TabBarView
│                             │
└─────────────────────────────┘
```

### 10.2 学习分析

```
┌─────────────────────────────┐
│        数据预览             │
│  ┌─────────────────────┐   │
│  │ 最近 7 天学习记录   │   │
│  │ 总时长: 8.5 小时    │   │
│  │ 记录数: 12 条       │   │
│  └─────────────────────┘   │
├─────────────────────────────┤
│      [开始分析]             │ ← 分析按钮
├─────────────────────────────┤
│        分析结果             │
│  ┌─────────────────────┐   │
│  │ 📊 学习分析报告     │   │ ← AI 分析结果
│  │                     │   │
│  │ 1. 学习时间分布...  │   │
│  │ 2. 科目覆盖情况...  │   │
│  │ 3. 建议...          │   │
│  └─────────────────────┘   │
└─────────────────────────────┘
```

### 10.3 健身分析

类似学习分析，但分析健身数据。

### 10.4 成长报告

```
┌─────────────────────────────┐
│  选择报告类型               │
│  [周报] [月报]              │
├─────────────────────────────┤
│        数据预览             │
│  ┌─────────────────────┐   │
│  │ 本周成长数据        │   │
│  │ 学习: 8.5h          │   │
│  │ 健身: 4.2h          │   │
│  │ 日记: 5 篇          │   │
│  │ 经验: +350          │   │
│  └─────────────────────┘   │
├─────────────────────────────┤
│      [生成报告]             │
├─────────────────────────────┤
│        报告内容             │
│  ┌─────────────────────┐   │
│  │ 📋 成长周报         │   │
│  │                     │   │
│  │ 本周总结...         │   │
│  │ 亮点...             │   │
│  │ 建议...             │   │
│  └─────────────────────┘   │
└─────────────────────────────┘
```

---

## 十一、任务系统

### 11.1 数据模型

**DailyTask**:
| 字段 | 类型 | 说明 |
|------|------|------|
| id | int | 主键 |
| title | String | 任务名称 |
| description | String? | 详细描述 |
| taskDate | String | 任务日期 (YYYY-MM-DD) |
| startHour | int | 开始时间 (小时) |
| startMinute | int | 开始时间 (分钟) |
| endHour | int | 结束时间 (小时) |
| endMinute | int | 结束时间 (分钟) |
| isCompleted | bool | 是否完成 |
| templateId | int? | 关联模板ID |
| sortOrder | int | 排序顺序 |
| createdAt | int | 创建时间戳 |
| updatedAt | int | 更新时间戳 |

**TaskTemplate**:
| 字段 | 类型 | 说明 |
|------|------|------|
| id | int | 主键 |
| name | String | 模板名称 |
| description | String? | 模板描述 |
| defaultStartHour | int | 默认开始时间 (小时) |
| defaultStartMinute | int | 默认开始时间 (分钟) |
| defaultEndHour | int | 默认结束时间 (小时) |
| defaultEndMinute | int | 默认结束时间 (分钟) |
| usageCount | int | 使用次数 |
| createdAt | int | 创建时间戳 |
| updatedAt | int | 更新时间戳 |

### 11.2 Provider

| Provider | 类型 | 说明 |
|----------|------|------|
| todayTasksProvider | FutureProvider | 今天的任务列表 |
| allTasksProvider | FutureProvider | 所有任务列表 |
| taskTemplatesProvider | FutureProvider | 任务模板列表 |
| taskExpandedProvider | StateProvider | 任务展开状态 |
| dailyGoalsProvider | StateProvider | 每日目标 |

---

## 十二、宠物系统

### 12.1 数据模型

**PetProfile**:
| 字段 | 类型 | 说明 |
|------|------|------|
| id | int | 主键 |
| name | String | 宠物名称 (默认: 添添) |
| level | int | 等级 |
| createdAt | int | 创建时间戳 |
| updatedAt | int | 更新时间戳 |

**PetState**:
| 字段 | 类型 | 说明 |
|------|------|------|
| id | int | 主键 |
| currentState | String | 当前状态 |
| lastInteractionTime | int | 最后互动时间戳 |
| lastHappyTime | int? | 最后开心时间戳 |
| createdAt | int | 创建时间戳 |
| updatedAt | int | 更新时间戳 |

### 12.2 状态系统

| 状态 | 说明 | 触发条件 |
|------|------|----------|
| idle | 默认状态 | 默认 |
| peek | 探头状态 | 启动时30%概率 |
| happy | 开心状态 | 完成学习/健身/日记目标 |
| sleepy | 困倦状态 | 48小时未记录 |

### 12.3 等级系统

| 等级 | 名称 |
|------|------|
| Lv1-9 | 普通添添 |
| Lv10-19 | 书包添添 |
| Lv20-49 | 眼镜添添 |
| Lv50+ | 围巾添添 |

### 12.4 提示文案

| 状态 | 文案 |
|------|------|
| idle | 今天也要加油哦～ |
| peek | 好久没记录了，来写点什么吧？ |
| happy | 太棒了！目标完成啦～ |
| sleepy | 好困...好久没见到你了... |

---

## 十三、数据模型

### 13.1 数据库表总览

| 表名 | 用途 | 记录数 |
|------|------|--------|
| study_records | 学习记录 | 动态 |
| fitness_records | 健身记录 | 动态 |
| fitness_exercises | 健身动作 | 动态 |
| body_metrics | 身体数据 | 动态 |
| daily_journals | 成长日记 | 动态 |
| focus_sessions | 专注记录 | 动态 |
| growth_exp_logs | 经验日志 | 动态 |
| app_settings | 系统设置 | KV |
| ai_configs | AI 配置 | 配置 |
| backup_records | 备份记录 | 动态 |
| daily_tasks | 每日任务 | 动态 |
| task_templates | 任务模板 | 动态 |
| pet_profiles | 宠物档案 | 1 |
| pet_states | 宠物状态 | 1 |

### 13.2 经验值计算公式

**学习经验**:
```
base = durationMinutes ~/ 10
focusBonus = focusLevel * 2
difficultyBonus = difficultyLevel * 2
reviewBonus = hasReview ? 5 : 0
total = base + focusBonus + difficultyBonus + reviewBonus
```

**健身经验**:
```
base = durationMinutes ~/ 10
intensityBonus = intensityLevel * 3
exerciseBonus = exerciseCount * 2
completeBonus = hasFeeling ? 5 : 0
total = base + intensityBonus + exerciseBonus + completeBonus
```

**日记经验**:
```
base = 5
wordBonus = wordCount ~/ 100
total = min(base + wordBonus, 20)  // 每日上限20
```

**等级计算**:
```
level = floor(sqrt(totalExp / 100)) + 1
```

---

## 十四、状态管理

### 14.1 Provider 总览

| Provider | 类型 | 说明 |
|----------|------|------|
| databaseProvider | Provider | AppDatabase 单例 |
| studyRepositoryProvider | Provider | 学习仓库 |
| fitnessRepositoryProvider | Provider | 健身仓库 |
| journalRepositoryProvider | Provider | 日记仓库 |
| expRepositoryProvider | Provider | 经验仓库 |
| settingRepositoryProvider | Provider | 设置仓库 |
| aiConfigRepositoryProvider | Provider | AI配置仓库 |
| dailyTaskRepositoryProvider | Provider | 任务仓库 |
| taskTemplateRepositoryProvider | Provider | 模板仓库 |
| expServiceProvider | Provider | 经验值服务 |
| statisticsServiceProvider | Provider | 统计服务 |
| backupServiceProvider | Provider | 备份服务 |
| aiServiceProvider | Provider | AI 服务 |
| themeModeProvider | StateProvider | 主题模式 |
| defaultRecordModeProvider | StateProvider | 默认记录模式 |
| dailyGoalsProvider | StateProvider | 每日目标 |
| dashboardProvider | FutureProvider | Dashboard 数据 |
| todayStudyMinutesProvider | FutureProvider | 今日学习时长 |
| weeklyStudyMinutesProvider | FutureProvider | 本周学习时长 |
| todayFitnessMinutesProvider | FutureProvider | 今日健身时长 |
| weeklyFitnessCountProvider | FutureProvider | 本周健身次数 |
| recentJournalsProvider | FutureProvider | 最近日记 |
| todayJournalCountProvider | FutureProvider | 今日日记数 |
| todayTasksProvider | FutureProvider | 今日任务 |
| allTasksProvider | FutureProvider | 所有任务 |
| taskTemplatesProvider | FutureProvider | 任务模板 |
| petProfileProvider | FutureProvider | 宠物档案 |
| petStateProvider | FutureProvider | 宠物状态 |
| petStateTypeProvider | StateProvider | 宠物状态类型 |

---

## 十五、路由系统

### 15.1 路由结构

```
/ (GoRouter)
├── /dashboard (StatefulShellBranch)
│   └── DashboardPage
├── /study (StatefulShellBranch)
│   ├── StudyPage
│   ├── /study/add → AddStudyRecordPage
│   └── /study/detail/:id → StudyRecordDetailPage
├── /fitness (StatefulShellBranch)
│   ├── FitnessPage
│   ├── /fitness/add → AddFitnessRecordPage
│   ├── /fitness/detail/:id → FitnessRecordDetailPage
│   └── /fitness/body-metric/add → AddBodyMetricPage
├── /journal (StatefulShellBranch)
│   ├── JournalPage
│   ├── /journal/write → WriteJournalPage
│   ├── /journal/edit/:id → EditJournalPage
│   └── /journal/detail/:id → JournalDetailPage
├── /settings (StatefulShellBranch)
│   ├── SettingsPage
│   ├── /settings/ai-config → AiConfigPage
│   └── /settings/ai-analysis → AiAnalysisPage
├── /focus (RootRoute)
│   ├── FocusPage
│   └── /focus/session → FocusSessionPage
└── /task-history (RootRoute)
    └── TaskHistoryPage
```

### 15.2 导航栏 Tab

| Tab | 图标 | 标签 | 路由 |
|-----|------|------|------|
| 0 | dashboard | 首页 | /dashboard |
| 1 | menu_book | 学习 | /study |
| 2 | fitness_center | 健身 | /fitness |
| 3 | edit_note | 日记 | /journal |
| 4 | settings | 我的 | /settings |

---

## 附录

### A. 通用组件

| 组件 | 说明 |
|------|------|
| SwipeDeleteTile | 右滑删除组件 |
| DateGroupedList | 按日期分组列表 |
| SortButton | 排序按钮 |
| ModuleProgressBar | 模块进度条 |
| LazyLoadWidget | 懒加载组件 |
| OptimizedList | 优化列表 |

### B. 工具类

| 工具 | 说明 |
|------|------|
| PerformanceUtils | 性能优化工具 |
| Debouncer | 防抖工具 |
| Throttle | 节流工具 |
| BatchScheduler | 批量调度工具 |
| LazyLoader | 懒加载工具 |

---

> 文档完成时间: 2026-06-05
> 
> 如有疑问，请参考源代码或设计文档。
