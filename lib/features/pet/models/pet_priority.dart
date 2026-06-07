/// 宠物展示优先级（重构版）
///
/// 5级优先级系统。高优先级不能被低优先级覆盖。
enum PetPriority {
  /// 生活状态（Dashboard 默认）
  life(0),

  /// 待机/环境状态（模块页默认）
  ambient(1),

  /// 用户反馈（完成记录、升级等）
  feedback(2),

  /// 系统状态（AI分析、隐私确认、提醒）
  system(3),

  /// 紧急状态（错误、API缺失）
  urgent(4);

  const PetPriority(this.level);
  final int level;

  bool operator >(PetPriority other) => level > other.level;
  bool operator <(PetPriority other) => level < other.level;
  bool operator >=(PetPriority other) => level >= other.level;
  bool operator <=(PetPriority other) => level <= other.level;
}
