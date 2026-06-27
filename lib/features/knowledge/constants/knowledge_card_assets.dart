class KnowledgeCardAssets {
  KnowledgeCardAssets._();

  static const root = 'assets/images/knowledge_cards';

  static const entryWide = '$root/knowledge_review_entry_wide.webp';
  static const goalEntryWide = '$root/knowledge_goal_entry_wide.webp';
  static const emptyCards = '$root/knowledge_empty_cards.webp';
  static const emptyReviewGoals = '$root/empty_review_goals.webp';
  static const emptyGoalModules = '$root/empty_goal_modules.webp';
  static const emptyCustomTemplates = '$root/empty_custom_templates.webp';
  static const reviewComplete = '$root/knowledge_review_complete.webp';
  static const goalReviewComplete = '$root/goal_review_complete.webp';
  static const noDueCards = '$root/knowledge_no_due_cards.webp';
  static const goalSetupComplete = '$root/goal_setup_complete.webp';
  static const customTemplateBuilderWide =
      '$root/custom_template_builder_wide.webp';
  static const customTemplateCover = '$root/custom_template_cover.webp';
  static const customTemplateComplete = '$root/custom_template_complete.webp';

  static const badgeDueCards = '$root/badge_due_cards.webp';
  static const badgeMastered = '$root/badge_mastered.webp';
  static const badgeWeakPoints = '$root/badge_weak_points.webp';
  static const badgeStreak = '$root/badge_streak.webp';
  static const badgeCustomGoal = '$root/badge_custom_goal.webp';

  static const goalTemplates = <KnowledgeGoalVisual>[
    KnowledgeGoalVisual(
      key: 'kaoyan_general',
      name: '考研通用',
      subtitle: '政治、英语、数学、专业课',
      asset: '$root/goal_kaoyan_general_cover.webp',
      modules: [
        KnowledgeGoalModuleVisual(
          key: 'politics',
          name: '政治',
          deckKey: 'politics',
          subtitle: '考研政治、公基理论',
        ),
        KnowledgeGoalModuleVisual(
          key: 'english',
          name: '英语',
          deckKey: 'english',
          subtitle: '词汇、语法、阅读',
        ),
        KnowledgeGoalModuleVisual(
          key: 'math',
          name: '数学',
          deckKey: 'math',
          subtitle: '高数、线代、概率',
        ),
        KnowledgeGoalModuleVisual(
          key: 'major',
          name: '专业课',
          deckKey: 'custom',
          subtitle: '自定义专业课模块',
        ),
      ],
    ),
    KnowledgeGoalVisual(
      key: 'kaoyan_computer',
      name: '考研·计算机',
      subtitle: '408 四科 + 公共课',
      asset: '$root/goal_kaoyan_computer_cover.webp',
      modules: [
        KnowledgeGoalModuleVisual(
          key: 'politics',
          name: '政治',
          deckKey: 'politics',
          subtitle: '政治理论',
        ),
        KnowledgeGoalModuleVisual(
          key: 'english',
          name: '英语',
          deckKey: 'english',
          subtitle: '英语复习',
        ),
        KnowledgeGoalModuleVisual(
          key: 'math',
          name: '数学',
          deckKey: 'math',
          subtitle: '数学基础',
        ),
        KnowledgeGoalModuleVisual(
          key: 'data_structure',
          name: '数据结构',
          deckKey: 'computer',
          subtitle: '线性表、树、图、排序',
        ),
        KnowledgeGoalModuleVisual(
          key: 'operating_system',
          name: '操作系统',
          deckKey: 'computer',
          subtitle: '进程、内存、文件系统',
        ),
        KnowledgeGoalModuleVisual(
          key: 'computer_network',
          name: '计算机网络',
          deckKey: 'computer',
          subtitle: '协议、分层、传输网络',
        ),
        KnowledgeGoalModuleVisual(
          key: 'computer_org',
          name: '组成原理',
          deckKey: 'computer',
          subtitle: 'CPU、存储、指令系统',
        ),
      ],
    ),
    KnowledgeGoalVisual(
      key: 'kaoyan_finance',
      name: '考研·金融',
      subtitle: '金融专业课 + 公共课',
      asset: '$root/goal_kaoyan_finance_cover.webp',
      modules: [
        KnowledgeGoalModuleVisual(
          key: 'politics',
          name: '政治',
          deckKey: 'politics',
          subtitle: '政治理论',
        ),
        KnowledgeGoalModuleVisual(
          key: 'english',
          name: '英语',
          deckKey: 'english',
          subtitle: '英语复习',
        ),
        KnowledgeGoalModuleVisual(
          key: 'math',
          name: '数学',
          deckKey: 'math',
          subtitle: '数学基础',
        ),
        KnowledgeGoalModuleVisual(
          key: 'economics',
          name: '西方经济学',
          deckKey: 'finance',
          subtitle: '微观、宏观、模型',
        ),
        KnowledgeGoalModuleVisual(
          key: 'finance',
          name: '金融学',
          deckKey: 'finance',
          subtitle: '货币银行、国际金融、投资',
        ),
      ],
    ),
    KnowledgeGoalVisual(
      key: 'kaoyan_law',
      name: '考研·法学',
      subtitle: '法学专业课 + 公共课',
      asset: '$root/goal_kaoyan_law_cover.webp',
      modules: [
        KnowledgeGoalModuleVisual(
          key: 'politics',
          name: '政治',
          deckKey: 'politics',
          subtitle: '政治理论',
        ),
        KnowledgeGoalModuleVisual(
          key: 'english',
          name: '英语',
          deckKey: 'english',
          subtitle: '英语复习',
        ),
        KnowledgeGoalModuleVisual(
          key: 'civil_law',
          name: '民法',
          deckKey: 'law',
          subtitle: '民事法律体系',
        ),
        KnowledgeGoalModuleVisual(
          key: 'criminal_law',
          name: '刑法',
          deckKey: 'law',
          subtitle: '犯罪构成与刑罚',
        ),
        KnowledgeGoalModuleVisual(
          key: 'constitutional_law',
          name: '宪法',
          deckKey: 'law',
          subtitle: '宪法与法理基础',
        ),
        KnowledgeGoalModuleVisual(
          key: 'legal_history',
          name: '法制史',
          deckKey: 'history',
          subtitle: '制度沿革与历史脉络',
        ),
      ],
    ),
    KnowledgeGoalVisual(
      key: 'kaoyan_medicine',
      name: '考研·医学',
      subtitle: '医学专业课 + 公共课',
      asset: '$root/goal_kaoyan_medicine_cover.webp',
      modules: [
        KnowledgeGoalModuleVisual(
          key: 'politics',
          name: '政治',
          deckKey: 'politics',
          subtitle: '政治理论',
        ),
        KnowledgeGoalModuleVisual(
          key: 'english',
          name: '英语',
          deckKey: 'english',
          subtitle: '英语复习',
        ),
        KnowledgeGoalModuleVisual(
          key: 'physiology',
          name: '生理',
          deckKey: 'biology',
          subtitle: '人体机能',
        ),
        KnowledgeGoalModuleVisual(
          key: 'biochemistry',
          name: '生化',
          deckKey: 'chemistry',
          subtitle: '生化基础',
        ),
        KnowledgeGoalModuleVisual(
          key: 'pathology',
          name: '病理',
          deckKey: 'medicine',
          subtitle: '疾病机制',
        ),
        KnowledgeGoalModuleVisual(
          key: 'diagnosis',
          name: '诊断',
          deckKey: 'medicine',
          subtitle: '诊断学',
        ),
        KnowledgeGoalModuleVisual(
          key: 'clinical',
          name: '内外科',
          deckKey: 'medicine',
          subtitle: '临床综合',
        ),
      ],
    ),
    KnowledgeGoalVisual(
      key: 'kaoyan_education',
      name: '考研·教育',
      subtitle: '教育学、心理学、研究方法',
      asset: '$root/goal_kaoyan_education_cover.webp',
      modules: [
        KnowledgeGoalModuleVisual(
          key: 'politics',
          name: '政治',
          deckKey: 'politics',
          subtitle: '政治理论',
        ),
        KnowledgeGoalModuleVisual(
          key: 'english',
          name: '英语',
          deckKey: 'english',
          subtitle: '英语复习',
        ),
        KnowledgeGoalModuleVisual(
          key: 'education_principle',
          name: '教育学原理',
          deckKey: 'education',
          subtitle: '教育学基础',
        ),
        KnowledgeGoalModuleVisual(
          key: 'education_history',
          name: '教育史',
          deckKey: 'history',
          subtitle: '中外教育史',
        ),
        KnowledgeGoalModuleVisual(
          key: 'education_psychology',
          name: '教育心理学',
          deckKey: 'education',
          subtitle: '心理与学习',
        ),
        KnowledgeGoalModuleVisual(
          key: 'research_method',
          name: '研究方法',
          deckKey: 'education',
          subtitle: '教育研究方法',
        ),
      ],
    ),
    KnowledgeGoalVisual(
      key: 'kaoyan_literature',
      name: '考研·文学新传',
      subtitle: '文学、新闻、传播',
      asset: '$root/goal_kaoyan_literature_cover.webp',
      modules: [
        KnowledgeGoalModuleVisual(
          key: 'politics',
          name: '政治',
          deckKey: 'politics',
          subtitle: '政治理论',
        ),
        KnowledgeGoalModuleVisual(
          key: 'english',
          name: '英语',
          deckKey: 'english',
          subtitle: '英语复习',
        ),
        KnowledgeGoalModuleVisual(
          key: 'modern_chinese',
          name: '现代汉语',
          deckKey: 'chinese_writing',
          subtitle: '语言文字基础',
        ),
        KnowledgeGoalModuleVisual(
          key: 'ancient_chinese',
          name: '古代汉语',
          deckKey: 'history',
          subtitle: '古汉语基础',
        ),
        KnowledgeGoalModuleVisual(
          key: 'literary_theory',
          name: '文学理论',
          deckKey: 'chinese_writing',
          subtitle: '文学概念与理论',
        ),
        KnowledgeGoalModuleVisual(
          key: 'journalism',
          name: '新闻传播',
          deckKey: 'media',
          subtitle: '新闻学、传播学',
        ),
      ],
    ),
    KnowledgeGoalVisual(
      key: 'kaoyan_management',
      name: '管理联考',
      subtitle: '数学、逻辑、写作、英语',
      asset: '$root/goal_kaoyan_management_cover.webp',
      modules: [
        KnowledgeGoalModuleVisual(
          key: 'math_basic',
          name: '数学基础',
          deckKey: 'math',
          subtitle: '管综数学',
        ),
        KnowledgeGoalModuleVisual(
          key: 'logic',
          name: '逻辑推理',
          deckKey: 'logic',
          subtitle: '形式逻辑与论证',
        ),
        KnowledgeGoalModuleVisual(
          key: 'writing',
          name: '写作',
          deckKey: 'chinese_writing',
          subtitle: '论证有效性与论说文',
        ),
        KnowledgeGoalModuleVisual(
          key: 'english',
          name: '英语',
          deckKey: 'english',
          subtitle: '英语二复习',
        ),
      ],
    ),
    KnowledgeGoalVisual(
      key: 'civil_service',
      name: '考公',
      subtitle: '行测、申论、面试',
      asset: '$root/goal_civil_service_cover.webp',
      modules: [
        KnowledgeGoalModuleVisual(
          key: 'verbal',
          name: '行测·言语',
          deckKey: 'chinese_writing',
          subtitle: '言语理解',
        ),
        KnowledgeGoalModuleVisual(
          key: 'judgement',
          name: '行测·判断',
          deckKey: 'logic',
          subtitle: '图推、逻辑、类比',
        ),
        KnowledgeGoalModuleVisual(
          key: 'quantity',
          name: '行测·数量',
          deckKey: 'math',
          subtitle: '数量关系',
        ),
        KnowledgeGoalModuleVisual(
          key: 'data_analysis',
          name: '行测·资料',
          deckKey: 'civil_service',
          subtitle: '资料分析',
        ),
        KnowledgeGoalModuleVisual(
          key: 'essay',
          name: '申论',
          deckKey: 'chinese_writing',
          subtitle: '材料分析与写作',
        ),
        KnowledgeGoalModuleVisual(
          key: 'common_knowledge',
          name: '常识政治',
          deckKey: 'politics',
          subtitle: '常识、公基、时政',
        ),
        KnowledgeGoalModuleVisual(
          key: 'interview',
          name: '面试',
          deckKey: 'interview',
          subtitle: '结构化面试',
        ),
      ],
    ),
    KnowledgeGoalVisual(
      key: 'public_institution',
      name: '考编',
      subtitle: '公基、职测、专业知识',
      asset: '$root/goal_public_institution_cover.webp',
      modules: [
        KnowledgeGoalModuleVisual(
          key: 'public_basic',
          name: '公共基础',
          deckKey: 'politics',
          subtitle: '公基与常识',
        ),
        KnowledgeGoalModuleVisual(
          key: 'career_aptitude',
          name: '职业能力',
          deckKey: 'logic',
          subtitle: '职测能力',
        ),
        KnowledgeGoalModuleVisual(
          key: 'major_knowledge',
          name: '专业知识',
          deckKey: 'custom',
          subtitle: '岗位专业知识',
        ),
        KnowledgeGoalModuleVisual(
          key: 'writing',
          name: '写作',
          deckKey: 'chinese_writing',
          subtitle: '综合写作',
        ),
        KnowledgeGoalModuleVisual(
          key: 'interview',
          name: '面试',
          deckKey: 'interview',
          subtitle: '面试表达',
        ),
      ],
    ),
    KnowledgeGoalVisual(
      key: 'high_school',
      name: '高中学习',
      subtitle: '语数英与选科复习',
      asset: '$root/goal_high_school_cover.webp',
      modules: _schoolModules,
    ),
    KnowledgeGoalVisual(
      key: 'middle_school',
      name: '初中学习',
      subtitle: '语数英与基础学科',
      asset: '$root/goal_middle_school_cover.webp',
      modules: _schoolModules,
    ),
    KnowledgeGoalVisual(
      key: 'college',
      name: '大学课程',
      subtitle: '公共课、专业课、论文',
      asset: '$root/goal_college_cover.webp',
      modules: [
        KnowledgeGoalModuleVisual(
          key: 'advanced_math',
          name: '高数',
          deckKey: 'math',
          subtitle: '高等数学',
        ),
        KnowledgeGoalModuleVisual(
          key: 'linear_algebra',
          name: '线代',
          deckKey: 'math',
          subtitle: '线性代数',
        ),
        KnowledgeGoalModuleVisual(
          key: 'probability',
          name: '概率论',
          deckKey: 'math',
          subtitle: '概率统计',
        ),
        KnowledgeGoalModuleVisual(
          key: 'english',
          name: '英语',
          deckKey: 'english',
          subtitle: '大学英语',
        ),
        KnowledgeGoalModuleVisual(
          key: 'programming',
          name: '编程',
          deckKey: 'computer',
          subtitle: '编程与项目',
        ),
        KnowledgeGoalModuleVisual(
          key: 'major',
          name: '专业课',
          deckKey: 'custom',
          subtitle: '自定义专业课',
        ),
        KnowledgeGoalModuleVisual(
          key: 'paper',
          name: '论文',
          deckKey: 'chinese_writing',
          subtitle: '论文写作',
        ),
      ],
    ),
    KnowledgeGoalVisual(
      key: 'interview_job',
      name: '就业面试',
      subtitle: '八股、算法、项目表达',
      asset: '$root/goal_interview_job_cover.webp',
      modules: [
        KnowledgeGoalModuleVisual(
          key: 'cs_basics',
          name: '计算机基础',
          deckKey: 'computer',
          subtitle: '基础八股',
        ),
        KnowledgeGoalModuleVisual(
          key: 'algorithm',
          name: '算法',
          deckKey: 'logic',
          subtitle: '算法与题型',
        ),
        KnowledgeGoalModuleVisual(
          key: 'project',
          name: '项目经历',
          deckKey: 'interview',
          subtitle: '项目表达',
        ),
        KnowledgeGoalModuleVisual(
          key: 'resume',
          name: '简历表达',
          deckKey: 'interview',
          subtitle: '简历与面试',
        ),
      ],
    ),
    KnowledgeGoalVisual(
      key: 'certificate',
      name: '证书考试',
      subtitle: '证书、资格、专项备考',
      asset: '$root/goal_certificate_cover.webp',
      modules: [
        KnowledgeGoalModuleVisual(
          key: 'theory',
          name: '理论知识',
          deckKey: 'politics',
          subtitle: '概念与规则',
        ),
        KnowledgeGoalModuleVisual(
          key: 'practice',
          name: '实务题',
          deckKey: 'logic',
          subtitle: '案例与实务',
        ),
        KnowledgeGoalModuleVisual(
          key: 'custom',
          name: '自定义模块',
          deckKey: 'custom',
          subtitle: '按证书自定义',
        ),
      ],
    ),
    KnowledgeGoalVisual(
      key: 'reading',
      name: '读书成长',
      subtitle: '读书笔记、概念摘录',
      asset: '$root/goal_reading_cover.webp',
      modules: [
        KnowledgeGoalModuleVisual(
          key: 'concepts',
          name: '概念摘录',
          deckKey: 'custom',
          subtitle: '关键概念',
        ),
        KnowledgeGoalModuleVisual(
          key: 'quotes',
          name: '摘录金句',
          deckKey: 'chinese_writing',
          subtitle: '观点与表达',
        ),
        KnowledgeGoalModuleVisual(
          key: 'reflection',
          name: '复盘思考',
          deckKey: 'education',
          subtitle: '启发与行动',
        ),
      ],
    ),
    KnowledgeGoalVisual(
      key: 'custom',
      name: '自定义目标',
      subtitle: '自己搭建目标和模块',
      asset: '$root/custom_template_cover.webp',
      modules: [
        KnowledgeGoalModuleVisual(
          key: 'custom',
          name: '自定义模块',
          deckKey: 'custom',
          subtitle: '自由创建模块',
        ),
      ],
    ),
  ];

  static const _schoolModules = [
    KnowledgeGoalModuleVisual(
      key: 'chinese',
      name: '语文',
      deckKey: 'chinese_writing',
      subtitle: '阅读、作文、古诗文',
    ),
    KnowledgeGoalModuleVisual(
      key: 'math',
      name: '数学',
      deckKey: 'math',
      subtitle: '数学知识点',
    ),
    KnowledgeGoalModuleVisual(
      key: 'english',
      name: '英语',
      deckKey: 'english',
      subtitle: '英语知识点',
    ),
    KnowledgeGoalModuleVisual(
      key: 'physics',
      name: '物理',
      deckKey: 'physics',
      subtitle: '物理知识点',
    ),
    KnowledgeGoalModuleVisual(
      key: 'chemistry',
      name: '化学',
      deckKey: 'chemistry',
      subtitle: '化学知识点',
    ),
    KnowledgeGoalModuleVisual(
      key: 'biology',
      name: '生物',
      deckKey: 'biology',
      subtitle: '生物知识点',
    ),
    KnowledgeGoalModuleVisual(
      key: 'history',
      name: '历史',
      deckKey: 'history',
      subtitle: '历史知识点',
    ),
    KnowledgeGoalModuleVisual(
      key: 'geography',
      name: '地理',
      deckKey: 'geography',
      subtitle: '地理知识点',
    ),
    KnowledgeGoalModuleVisual(
      key: 'politics',
      name: '政治',
      deckKey: 'politics',
      subtitle: '政治知识点',
    ),
  ];

  static const decks = <KnowledgeDeckVisual>[
    KnowledgeDeckVisual(
      key: 'chinese_writing',
      name: '中文写作',
      subtitle: '语文、写作、申论、论文',
      asset: '$root/deck_chinese_writing_cover.webp',
      keywords: ['语文', '写作', '申论', '论文', '现代汉语', '古代汉语', '文学理论'],
    ),
    KnowledgeDeckVisual(
      key: 'math',
      name: '数学',
      subtitle: '数学、高数、线代、概率',
      asset: '$root/deck_math_cover.webp',
      keywords: ['数学', '高数', '线代', '概率论', '数学基础', '数量'],
    ),
    KnowledgeDeckVisual(
      key: 'english',
      name: '英语',
      subtitle: '单词、语法、阅读',
      asset: '$root/deck_english_cover.webp',
      keywords: ['英语', '单词', '语法', '阅读'],
    ),
    KnowledgeDeckVisual(
      key: 'physics',
      name: '物理',
      subtitle: '力学、电学、实验',
      asset: '$root/deck_physics_cover.webp',
      keywords: ['物理', '力学', '电学'],
    ),
    KnowledgeDeckVisual(
      key: 'chemistry',
      name: '化学',
      subtitle: '化学、生化、实验',
      asset: '$root/deck_chemistry_cover.webp',
      keywords: ['化学', '生化', '有机', '无机'],
    ),
    KnowledgeDeckVisual(
      key: 'biology',
      name: '生物',
      subtitle: '生物、生理、病理',
      asset: '$root/deck_biology_cover.webp',
      keywords: ['生物', '生理', '病理', '细胞'],
    ),
    KnowledgeDeckVisual(
      key: 'history',
      name: '历史',
      subtitle: '历史、法制史、教育史',
      asset: '$root/deck_history_cover.webp',
      keywords: ['历史', '法制史', '教育史', '中外教育史'],
    ),
    KnowledgeDeckVisual(
      key: 'geography',
      name: '地理',
      subtitle: '地图、区域、自然地理',
      asset: '$root/deck_geography_cover.webp',
      keywords: ['地理', '地图', '区域'],
    ),
    KnowledgeDeckVisual(
      key: 'politics',
      name: '政治公基',
      subtitle: '政治、公共基础',
      asset: '$root/deck_politics_cover.webp',
      keywords: ['政治', '公共基础', '公基'],
    ),
    KnowledgeDeckVisual(
      key: 'computer',
      name: '计算机',
      subtitle: '编程、408、计网',
      asset: '$root/deck_computer_cover.webp',
      keywords: ['编程', '数据结构', '操作系统', '计算机网络', '组成原理', '计算机', '代码'],
    ),
    KnowledgeDeckVisual(
      key: 'finance',
      name: '经济金融',
      subtitle: '经济学、金融、投资',
      asset: '$root/deck_finance_cover.webp',
      keywords: ['经济', '金融', '投资', '货币银行', '国际金融'],
    ),
    KnowledgeDeckVisual(
      key: 'law',
      name: '法学',
      subtitle: '民法、刑法、宪法、法理学',
      asset: '$root/deck_law_cover.webp',
      keywords: ['民法', '刑法', '宪法', '法理学', '法律', '法学'],
    ),
    KnowledgeDeckVisual(
      key: 'medicine',
      name: '医学',
      subtitle: '诊断、内科、外科',
      asset: '$root/deck_medicine_cover.webp',
      keywords: ['医学', '诊断', '内科', '外科', '病理', '生理'],
    ),
    KnowledgeDeckVisual(
      key: 'education',
      name: '教育学',
      subtitle: '教育原理、心理学、研究方法',
      asset: '$root/deck_education_cover.webp',
      keywords: ['教育学', '教育心理学', '教育研究方法'],
    ),
    KnowledgeDeckVisual(
      key: 'media',
      name: '新闻传播',
      subtitle: '新闻学、传播学',
      asset: '$root/deck_media_cover.webp',
      keywords: ['新闻学', '传播学', '媒体'],
    ),
    KnowledgeDeckVisual(
      key: 'logic',
      name: '逻辑能力',
      subtitle: '逻辑、判断、职业能力',
      asset: '$root/deck_logic_cover.webp',
      keywords: ['逻辑', '判断', '职业能力', '推理'],
    ),
    KnowledgeDeckVisual(
      key: 'civil_service',
      name: '考公考编',
      subtitle: '行测、申论、资料分析',
      asset: '$root/deck_civil_service_cover.webp',
      keywords: ['行测', '申论', '资料', '考公', '考编'],
    ),
    KnowledgeDeckVisual(
      key: 'interview',
      name: '面试就业',
      subtitle: '面试、表达、就业复习',
      asset: '$root/deck_interview_cover.webp',
      keywords: ['面试', '就业', '简历', '八股'],
    ),
    KnowledgeDeckVisual(
      key: 'custom',
      name: '自定义',
      subtitle: '其他知识卡组',
      asset: '$root/deck_custom_cover.webp',
      keywords: ['专业课', '专业知识', '读书', '其他', '自定义'],
    ),
  ];

  static KnowledgeGoalVisual goalForKey(String? key) {
    for (final goal in goalTemplates) {
      if (goal.key == key) return goal;
    }
    return goalTemplates.last;
  }

  static KnowledgeDeckVisual visualForKey(String? key) {
    for (final deck in decks) {
      if (deck.key == key) return deck;
    }
    return decks.last;
  }

  static KnowledgeGoalModuleVisual moduleForKeys(
    String? goalKey,
    String? moduleKey,
  ) {
    final goal = goalForKey(goalKey);
    for (final module in goal.modules) {
      if (module.key == moduleKey) return module;
    }
    return goal.modules.first;
  }

  static String keyForSubject(String? subject) {
    final text = subject?.trim();
    if (text == null || text.isEmpty) return 'custom';

    for (final deck in decks) {
      if (deck.key == 'custom') continue;
      for (final keyword in deck.keywords) {
        if (text.contains(keyword)) return deck.key;
      }
    }
    return 'custom';
  }
}

class KnowledgeGoalVisual {
  const KnowledgeGoalVisual({
    required this.key,
    required this.name,
    required this.subtitle,
    required this.asset,
    required this.modules,
  });

  final String key;
  final String name;
  final String subtitle;
  final String asset;
  final List<KnowledgeGoalModuleVisual> modules;
}

class KnowledgeGoalModuleVisual {
  const KnowledgeGoalModuleVisual({
    required this.key,
    required this.name,
    required this.deckKey,
    required this.subtitle,
  });

  final String key;
  final String name;
  final String deckKey;
  final String subtitle;
}

class KnowledgeDeckVisual {
  const KnowledgeDeckVisual({
    required this.key,
    required this.name,
    required this.subtitle,
    required this.asset,
    required this.keywords,
  });

  final String key;
  final String name;
  final String subtitle;
  final String asset;
  final List<String> keywords;
}
