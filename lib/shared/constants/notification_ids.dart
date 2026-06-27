/// 通知 ID 常量
///
/// 集中管理所有本地通知 ID，避免硬编码冲突。
class NotificationIds {
  NotificationIds._();

  /// 番茄钟/专注计时器
  static const focusSession = 5205;

  /// 健身训练计时器
  static const fitnessTraining = 5206;

  /// 系统提醒（主要）
  static const systemReminder = 529998;

  /// 系统提醒（备用）
  static const systemReminderAlt = 529999;
}
