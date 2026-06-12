/// 番茄钟学习模式
///
/// 每种模式对应一组预设科目，用户可在设置中切换。
/// 所有模式都包含「读书」和「其他」。
enum StudyMode {
  middleSchool('初中生', '📚'),
  highSchool('高中生', '📖'),
  college('大学生', '🎓'),
  gradCS('考研·计算机', '💻'),
  gradFinance('考研·金融', '💰'),
  gradLaw('考研·法学', '⚖️'),
  gradMed('考研·医学', '🏥'),
  gradEducation('考研·教育', '🎓'),
  gradLiterature('考研·文学', '📰'),
  gradManagement('考研·管理联考', '📊'),
  civilService('考公', '🏛️'),
  publicInstitution('考编', '📋');

  const StudyMode(this.label, this.icon);

  /// 模式显示名称
  final String label;

  /// 模式图标 emoji
  final String icon;

  /// 该模式下的预设科目列表
  List<String> get subjects => switch (this) {
    middleSchool => _middleSchoolSubjects,
    highSchool => _highSchoolSubjects,
    college => _collegeSubjects,
    gradCS => _gradCSSubjects,
    gradFinance => _gradFinanceSubjects,
    gradLaw => _gradLawSubjects,
    gradMed => _gradMedSubjects,
    gradEducation => _gradEducationSubjects,
    gradLiterature => _gradLiteratureSubjects,
    gradManagement => _gradManagementSubjects,
    civilService => _civilServiceSubjects,
    publicInstitution => _publicInstitutionSubjects,
  };

  /// 从字符串反序列化
  static StudyMode fromName(String? name) {
    if (name == null) return StudyMode.highSchool;
    for (final mode in StudyMode.values) {
      if (mode.name == name) return mode;
    }
    return StudyMode.highSchool;
  }

  // ── 各模式科目定义 ──

  static const _commonTail = ['读书', '其他'];

  static const _middleSchoolSubjects = [
    '语文', '数学', '英语', '物理', '化学',
    '生物', '历史', '地理', '政治',
    ..._commonTail,
  ];

  static const _highSchoolSubjects = [
    '语文', '数学', '英语', '物理', '化学',
    '生物', '历史', '地理', '政治',
    ..._commonTail,
  ];

  static const _collegeSubjects = [
    '高数', '线代', '概率论', '英语', '编程',
    '专业课', '论文',
    ..._commonTail,
  ];

  static const _gradCSSubjects = [
    '数据结构', '操作系统', '计算机网络', '组成原理',
    '数学', '英语', '政治',
    ..._commonTail,
  ];

  static const _gradFinanceSubjects = [
    '西方经济学', '货币银行学', '国际金融', '投资学',
    '数学', '英语', '政治',
    ..._commonTail,
  ];

  static const _gradLawSubjects = [
    '民法', '刑法', '宪法', '法理学', '法制史',
    '数学', '英语', '政治',
    ..._commonTail,
  ];

  static const _gradMedSubjects = [
    '生理', '生化', '病理', '诊断', '内科', '外科',
    '数学', '英语', '政治',
    ..._commonTail,
  ];

  static const _gradEducationSubjects = [
    '教育学原理', '中外教育史', '教育心理学', '教育研究方法',
    '数学', '英语', '政治',
    ..._commonTail,
  ];

  static const _gradLiteratureSubjects = [
    '现代汉语', '古代汉语', '文学理论', '新闻学', '传播学',
    '数学', '英语', '政治',
    ..._commonTail,
  ];

  static const _gradManagementSubjects = [
    '数学基础', '逻辑推理', '写作',
    '英语',
    ..._commonTail,
  ];

  static const _civilServiceSubjects = [
    '行测·言语', '行测·判断', '行测·数量', '行测·资料',
    '申论', '面试',
    ..._commonTail,
  ];

  static const _publicInstitutionSubjects = [
    '公共基础', '职业能力', '专业知识', '写作', '面试',
    ..._commonTail,
  ];
}
