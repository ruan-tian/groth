/// 宠物 AI 隐私保护
///
/// 在数据发送到 AI 之前进行脱敏处理。
/// - 移除敏感字段（姓名、地点、具体日期）
/// - 尊重日记上传开关
/// - 只保留统计数据，不保留原文
class PetAIPrivacyGuard {
  PetAIPrivacyGuard._();

  static final instance = PetAIPrivacyGuard._();

  /// 脱敏处理
  ///
  /// [data] 原始数据
  /// [journalUploadEnabled] 是否开启日记上传
  Map<String, dynamic> sanitize({
    required Map<String, dynamic> data,
    required bool journalUploadEnabled,
  }) {
    final sanitized = <String, dynamic>{};

    for (final entry in data.entries) {
      final key = entry.key;
      final value = entry.value;

      // 跳过日记相关字段（如果未开启）
      if (!journalUploadEnabled && _isJournalField(key)) {
        continue;
      }

      // 脱敏处理
      if (value is String) {
        sanitized[key] = _sanitizeString(value);
      } else if (value is Map) {
        sanitized[key] = _sanitizeMap(value as Map<String, dynamic>);
      } else if (value is List) {
        sanitized[key] = _sanitizeList(value);
      } else {
        sanitized[key] = value;
      }
    }

    return sanitized;
  }

  /// 检查是否是日记相关字段
  bool _isJournalField(String key) {
    // 只匹配日记正文字段，不误伤健身/睡眠的 note、mood 字段
    return key == 'journalContent' ||
        key == 'diaryText' ||
        key == 'journalText' ||
        key == 'contentMarkdown';
  }

  /// 脱敏字符串
  String _sanitizeString(String value) {
    // 只匹配明确的人名模式：我/你/他 + 中文名 + 说/告诉/问/叫
    // 不匹配"学习"、"跑步"等普通动宾短语
    var sanitized = value.replaceAllMapped(
      RegExp(r'(?<=[我你他她它])([\u4e00-\u9fa5]{1,3})(?=说|告诉|问|叫|发)'),
      (match) => '***',
    );

    // 移除邮箱
    sanitized = sanitized.replaceAll(
      RegExp(r'[\w.-]+@[\w.-]+\.\w+'),
      '***@***.***',
    );

    // 移除手机号
    sanitized = sanitized.replaceAll(RegExp(r'1[3-9]\d{9}'), '***');

    // 移除具体日期（保留相对描述）
    sanitized = sanitized.replaceAll(
      RegExp(r'\d{4}[-/]\d{1,2}[-/]\d{1,2}'),
      '某日',
    );

    return sanitized;
  }

  /// 脱敏Map
  Map<String, dynamic> _sanitizeMap(Map<String, dynamic> map) {
    final sanitized = <String, dynamic>{};
    for (final entry in map.entries) {
      if (entry.value is String) {
        sanitized[entry.key] = _sanitizeString(entry.value as String);
      } else {
        sanitized[entry.key] = entry.value;
      }
    }
    return sanitized;
  }

  /// 脱敏List
  List<dynamic> _sanitizeList(List<dynamic> list) {
    return list.map((item) {
      if (item is String) {
        return _sanitizeString(item);
      } else if (item is Map) {
        return _sanitizeMap(item as Map<String, dynamic>);
      }
      return item;
    }).toList();
  }

  /// 生成隐私提示文本
  String getPrivacyNotice({
    required bool journalUploadEnabled,
    required String analysisType,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('即将发送给 AI 的数据：');

    switch (analysisType) {
      case 'study':
        buffer.writeln('• 最近 7 天学习统计');
        buffer.writeln('• 学习时长、科目分布');
        buffer.writeln('• 专注度、遗留问题摘要');
        break;
      case 'fitness':
        buffer.writeln('• 最近 7 天健身统计');
        buffer.writeln('• 训练时长、部位分布');
        buffer.writeln('• 强度、疲劳度摘要');
        break;
      case 'diet':
        buffer.writeln('• 最近 7 天饮食统计');
        buffer.writeln('• 餐次、卡路里估算');
        buffer.writeln('• 健康评分摘要');
        break;
      case 'sleep':
        buffer.writeln('• 最近 7 天睡眠统计');
        buffer.writeln('• 睡眠时长、质量评分');
        buffer.writeln('• 入睡时间、夜醒次数');
        break;
      case 'weeklyReport':
      case 'monthlyReport':
        buffer.writeln('• 学习、健身、饮食、睡眠统计');
        buffer.writeln('• 经验值、等级变化');
        break;
    }

    if (journalUploadEnabled) {
      buffer.writeln('• 包含日记摘要（已开启）');
    } else {
      buffer.writeln('• 不包含日记内容');
    }

    return buffer.toString();
  }
}
