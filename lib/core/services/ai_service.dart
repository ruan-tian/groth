import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../database/app_database.dart';

/// AI 分析服务
///
/// 封装 OpenAI 兼容 API 的调用，提供学习分析、健身分析、周报/月报生成。
/// 支持 OpenAI、DeepSeek、Gemini 等兼容接口。
class AiService {
  AiService();

  static const _defaultTimeout = Duration(seconds: 60);

  // ---------------------------------------------------------------------------
  // 学习分析
  // ---------------------------------------------------------------------------

  /// 分析学习记录，返回 AI 生成的分析文本。
  ///
  /// [records] 为待分析的学习记录列表，通常为最近 7~30 天的数据。
  Future<String> analyzeStudy({
    required String apiKey,
    required String baseUrl,
    required String model,
    required List<StudyRecord> records,
  }) async {
    final prompt = _buildStudyPrompt(records);
    return _callApi(
      apiKey: apiKey,
      baseUrl: baseUrl,
      model: model,
      systemPrompt: _studySystemPrompt,
      userPrompt: prompt,
    );
  }

  // ---------------------------------------------------------------------------
  // 健身分析
  // ---------------------------------------------------------------------------

  /// 分析健身记录，返回 AI 生成的分析文本。
  ///
  /// [records] 为待分析的健身记录列表。
  Future<String> analyzeFitness({
    required String apiKey,
    required String baseUrl,
    required String model,
    required List<FitnessRecord> records,
  }) async {
    final prompt = _buildFitnessPrompt(records);
    return _callApi(
      apiKey: apiKey,
      baseUrl: baseUrl,
      model: model,
      systemPrompt: _fitnessSystemPrompt,
      userPrompt: prompt,
    );
  }

  // ---------------------------------------------------------------------------
  // 饮食分析
  // ---------------------------------------------------------------------------

  /// 分析饮食记录，返回 AI 生成的分析文本。
  ///
  /// [records] 为待分析的饮食记录列表。
  Future<String> analyzeDiet({
    required String apiKey,
    required String baseUrl,
    required String model,
    required List<DietRecord> records,
  }) async {
    final prompt = _buildDietPrompt(records);
    return _callApi(
      apiKey: apiKey,
      baseUrl: baseUrl,
      model: model,
      systemPrompt: _dietSystemPrompt,
      userPrompt: prompt,
    );
  }

  // ---------------------------------------------------------------------------
  // 睡眠分析
  // ---------------------------------------------------------------------------

  /// 分析睡眠记录，返回 AI 生成的分析文本。
  ///
  /// [records] 为待分析的睡眠记录列表。
  Future<String> analyzeSleep({
    required String apiKey,
    required String baseUrl,
    required String model,
    required List<SleepRecord> records,
  }) async {
    final prompt = _buildSleepPrompt(records);
    return _callApi(
      apiKey: apiKey,
      baseUrl: baseUrl,
      model: model,
      systemPrompt: _sleepSystemPrompt,
      userPrompt: prompt,
    );
  }

  // ---------------------------------------------------------------------------
  // 周报
  // ---------------------------------------------------------------------------

  /// 根据周统计数据生成成长周报。
  ///
  /// [weeklyData] 应包含 `studyMinutes`、`fitnessMinutes`、`journalCount`、
  /// `expGained`、`dailyStats` 等字段。
  Future<String> generateWeeklyReport({
    required String apiKey,
    required String baseUrl,
    required String model,
    required Map<String, dynamic> weeklyData,
  }) async {
    final prompt = _buildWeeklyReportPrompt(weeklyData);
    return _callApi(
      apiKey: apiKey,
      baseUrl: baseUrl,
      model: model,
      systemPrompt: _reportSystemPrompt,
      userPrompt: prompt,
    );
  }

  // ---------------------------------------------------------------------------
  // 月报
  // ---------------------------------------------------------------------------

  /// 根据月度统计数据生成成长月报。
  ///
  /// [monthlyData] 应包含 `studyMinutes`、`fitnessMinutes`、`journalCount`、
  /// `expGained`、`dailyStats`、`subjectDistribution` 等字段。
  Future<String> generateMonthlyReport({
    required String apiKey,
    required String baseUrl,
    required String model,
    required Map<String, dynamic> monthlyData,
  }) async {
    final prompt = _buildMonthlyReportPrompt(monthlyData);
    return _callApi(
      apiKey: apiKey,
      baseUrl: baseUrl,
      model: model,
      systemPrompt: _reportSystemPrompt,
      userPrompt: prompt,
    );
  }

  // ---------------------------------------------------------------------------
  // 公开 API 调用
  // ---------------------------------------------------------------------------

  /// 公开的 API 调用方法，供外部 Prompt 构建器使用。
  Future<String> callApi({
    required String apiKey,
    required String baseUrl,
    required String model,
    required String systemPrompt,
    required String userPrompt,
    double temperature = 0.7,
    int maxTokens = 2048,
  }) {
    return _callApi(
      apiKey: apiKey,
      baseUrl: baseUrl,
      model: model,
      systemPrompt: systemPrompt,
      userPrompt: userPrompt,
      temperature: temperature,
      maxTokens: maxTokens,
    );
  }

  /// 流式调用 AI API
  ///
  /// 返回一个 Stream，逐步输出 AI 的回复内容。
  /// 适用于需要实时显示 AI 回复的场景。
  Stream<String> streamApi({
    required String apiKey,
    required String baseUrl,
    required String model,
    required String systemPrompt,
    required String userPrompt,
    double temperature = 0.7,
    int maxTokens = 2048,
  }) async* {
    final normalizedBase = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final url = Uri.parse('$normalizedBase/chat/completions');

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $apiKey',
    };

    final body = jsonEncode({
      'model': model,
      'messages': [
        {'role': 'system', 'content': systemPrompt},
        {'role': 'user', 'content': userPrompt},
      ],
      'temperature': temperature,
      'max_tokens': maxTokens,
      'stream': true,
    });

    try {
      final request = http.Request('POST', url);
      request.headers.addAll(headers);
      request.body = body;

      final client = http.Client();
      final response = await client.send(request);

      if (response.statusCode != 200) {
        final responseBody = await response.stream.bytesToString();
        throw AiServiceException(
          'API 请求失败 (${response.statusCode}): $responseBody',
        );
      }

      String buffer = '';
      await for (final chunk in response.stream.transform(utf8.decoder)) {
        buffer += chunk;

        while (buffer.contains('\n')) {
          final lineEnd = buffer.indexOf('\n');
          final line = buffer.substring(0, lineEnd).trim();
          buffer = buffer.substring(lineEnd + 1);

          if (line.startsWith('data: ')) {
            final data = line.substring(6).trim();
            if (data == '[DONE]') {
              client.close();
              return;
            }

            try {
              final json = jsonDecode(data) as Map<String, dynamic>;
              final choices = json['choices'] as List<dynamic>?;
              if (choices != null && choices.isNotEmpty) {
                final delta =
                    choices[0]['delta'] as Map<String, dynamic>?;
                final content = delta?['content'] as String?;
                if (content != null && content.isNotEmpty) {
                  yield content;
                }
              }
            } catch (_) {
              // 忽略解析错误
            }
          }
        }
      }

      client.close();
    } on http.ClientException catch (e) {
      throw AiServiceException('网络请求失败: ${e.message}');
    } on TimeoutException {
      throw AiServiceException('API 请求超时（${_defaultTimeout.inSeconds}秒）');
    }
  }

  // ---------------------------------------------------------------------------
  // 内部 API 调用
  // ---------------------------------------------------------------------------

  /// 调用 OpenAI 兼容 Chat Completions API。
  ///
  /// 自动处理网络错误、超时、非 200 响应等情况。
  /// 失败时抛出 [AiServiceException]。
  Future<String> _callApi({
    required String apiKey,
    required String baseUrl,
    required String model,
    required String systemPrompt,
    required String userPrompt,
    double temperature = 0.7,
    int maxTokens = 2048,
  }) async {
    // 规范化 baseUrl：移除末尾斜杠
    final normalizedBase = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final url = Uri.parse('$normalizedBase/chat/completions');

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $apiKey',
    };

    final body = jsonEncode({
      'model': model,
      'messages': [
        {'role': 'system', 'content': systemPrompt},
        {'role': 'user', 'content': userPrompt},
      ],
      'temperature': temperature,
      'max_tokens': maxTokens,
    });

    try {
      final response = await http
          .post(url, headers: headers, body: body)
          .timeout(_defaultTimeout);

      if (response.statusCode != 200) {
        throw AiServiceException(
          'API 请求失败 (${response.statusCode}): ${response.body}',
        );
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final choices = json['choices'] as List<dynamic>?;
      if (choices == null || choices.isEmpty) {
        throw AiServiceException('API 返回数据格式异常：无 choices 字段');
      }

      final message = choices[0]['message'] as Map<String, dynamic>?;
      final content = message?['content'] as String?;
      if (content == null || content.isEmpty) {
        throw AiServiceException('API 返回内容为空');
      }

      return content.trim();
    } on http.ClientException catch (e) {
      throw AiServiceException('网络请求失败: ${e.message}');
    } on TimeoutException {
      throw AiServiceException('API 请求超时（${_defaultTimeout.inSeconds}秒）');
    } on FormatException catch (e) {
      throw AiServiceException('响应解析失败: ${e.message}');
    }
  }

  // ---------------------------------------------------------------------------
  // Prompt 构建 — 学习
  // ---------------------------------------------------------------------------

  static const _studySystemPrompt = '''
你是一位专业的学习顾问。请根据用户的学习记录数据，给出以下分析：
1. 学习时间分布与规律性评估
2. 学习效率分析（结合专注度、难度、掌握度）
3. 科目均衡性建议
4. 具体的改进建议（2-3 条可执行的建议）

请用简洁、鼓励的语气回答，使用中文。''';

  String _buildStudyPrompt(List<StudyRecord> records) {
    if (records.isEmpty) return '最近没有学习记录，请给出通用的学习建议。';

    final buffer = StringBuffer('以下是用户最近的学习记录：\n\n');
    for (final r in records) {
      final date = DateTime.fromMillisecondsSinceEpoch(r.createdAt);
      final dateStr =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      buffer.writeln('- 日期: $dateStr');
      buffer.writeln('  标题: ${r.title}');
      if (r.subject != null) buffer.writeln('  科目: ${r.subject}');
      buffer.writeln('  时长: ${r.durationMinutes} 分钟');
      buffer.writeln('  模式: ${r.mode}');
      if (r.focusLevel != null) buffer.writeln('  专注度: ${r.focusLevel}/5');
      if (r.difficultyLevel != null) {
        buffer.writeln('  难度: ${r.difficultyLevel}/5');
      }
      if (r.masteryLevel != null) buffer.writeln('  掌握度: ${r.masteryLevel}/5');
      if (r.gain != null && r.gain!.isNotEmpty) {
        buffer.writeln('  收获: ${r.gain}');
      }
      buffer.writeln();
    }

    final totalMinutes = records.fold<int>(0, (s, r) => s + r.durationMinutes);
    buffer.writeln('共 ${records.length} 条记录，总学习时长 $totalMinutes 分钟。');
    buffer.writeln('\n请给出分析和建议。');

    return buffer.toString();
  }

  // ---------------------------------------------------------------------------
  // Prompt 构建 — 健身
  // ---------------------------------------------------------------------------

  static const _fitnessSystemPrompt = '''
你是一位专业的健身教练。请根据用户的训练记录数据，给出以下分析：
1. 训练频率与规律性评估
2. 训练强度与恢复情况分析
3. 身体部位均衡性建议
4. 具体的改进建议（2-3 条可执行的建议）

请用简洁、专业的语气回答，使用中文。''';

  String _buildFitnessPrompt(List<FitnessRecord> records) {
    if (records.isEmpty) return '最近没有健身记录，请给出通用的健身建议。';

    final buffer = StringBuffer('以下是用户最近的健身记录：\n\n');
    for (final r in records) {
      final date = DateTime.fromMillisecondsSinceEpoch(r.createdAt);
      final dateStr =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      buffer.writeln('- 日期: $dateStr');
      if (r.title != null && r.title!.isNotEmpty) {
        buffer.writeln('  标题: ${r.title}');
      }
      buffer.writeln('  训练部位: ${r.bodyPart}');
      buffer.writeln('  时长: ${r.durationMinutes} 分钟');
      buffer.writeln('  模式: ${r.mode}');
      if (r.intensityLevel != null) {
        buffer.writeln('  强度: ${r.intensityLevel}/5');
      }
      if (r.fatigueLevel != null) {
        buffer.writeln('  疲劳度: ${r.fatigueLevel}/5');
      }
      if (r.feeling != null && r.feeling!.isNotEmpty) {
        buffer.writeln('  感受: ${r.feeling}');
      }
      buffer.writeln();
    }

    final totalMinutes = records.fold<int>(0, (s, r) => s + r.durationMinutes);
    buffer.writeln('共 ${records.length} 条记录，总训练时长 $totalMinutes 分钟。');
    buffer.writeln('\n请给出分析和建议。');

    return buffer.toString();
  }

  // ---------------------------------------------------------------------------
  // Prompt 构建 — 饮食
  // ---------------------------------------------------------------------------

  static const _dietSystemPrompt = '''
你是一位专业的营养顾问。请根据用户的饮食记录数据，给出以下分析：
1. 饮食规律性评估（三餐是否规律）
2. 营养均衡性分析（蛋白质、热量摄入情况）
3. 健康饮食评分趋势分析
4. 具体的改进建议（2-3 条可执行的建议）

请用简洁、友好的语气回答，使用中文。''';

  String _buildDietPrompt(List<DietRecord> records) {
    if (records.isEmpty) return '最近没有饮食记录，请给出通用的健康饮食建议。';

    final buffer = StringBuffer('以下是用户最近的饮食记录：\n\n');
    for (final r in records) {
      buffer.writeln('- 日期: ${r.mealDate}');
      buffer.writeln('  餐次: ${_getMealTypeName(r.mealType)}');
      buffer.writeln('  食物: ${r.foodText}');
      buffer.writeln('  份量: ${_getPortionName(r.portionLevel)}');
      buffer.writeln('  热量: ${_getCalorieName(r.calorieLevel)}');
      buffer.writeln('  蛋白质: ${_getProteinName(r.proteinLevel)}');
      buffer.writeln('  健康评分: ${r.healthScore}/5');
      if (r.note != null && r.note!.isNotEmpty) {
        buffer.writeln('  备注: ${r.note}');
      }
      buffer.writeln();
    }

    final avgScore = records.fold<double>(0, (s, r) => s + r.healthScore) /
        records.length;
    buffer.writeln('共 ${records.length} 条记录，平均健康评分 ${avgScore.toStringAsFixed(1)}/5。');
    buffer.writeln('\n请给出分析和建议。');

    return buffer.toString();
  }

  String _getMealTypeName(String type) {
    switch (type) {
      case 'breakfast':
        return '早餐';
      case 'lunch':
        return '午餐';
      case 'dinner':
        return '晚餐';
      case 'snack':
        return '加餐';
      default:
        return type;
    }
  }

  String _getPortionName(String portion) {
    switch (portion) {
      case 'small':
        return '少量';
      case 'normal':
        return '正常';
      case 'large':
        return '大量';
      default:
        return portion;
    }
  }

  String _getCalorieName(String level) {
    switch (level) {
      case 'low':
        return '低';
      case 'normal':
        return '中';
      case 'high':
        return '高';
      default:
        return level;
    }
  }

  String _getProteinName(String level) {
    switch (level) {
      case 'low':
        return '低';
      case 'medium':
        return '中';
      case 'high':
        return '高';
      default:
        return level;
    }
  }

  // ---------------------------------------------------------------------------
  // Prompt 构建 — 睡眠
  // ---------------------------------------------------------------------------

  static const _sleepSystemPrompt = '''
你是一位专业的睡眠专家。请根据用户的睡眠记录数据，给出以下分析：
1. 睡眠时长是否充足（建议7-9小时）
2. 睡眠质量评估
3. 作息规律性分析（入睡/起床时间是否稳定）
4. 入睡问题分析（入睡耗时、夜醒情况）
5. 具体的改善建议（2-3 条可执行的建议）

请用简洁、关怀的语气回答，使用中文。''';

  String _buildSleepPrompt(List<SleepRecord> records) {
    if (records.isEmpty) return '最近没有睡眠记录，请给出通用的健康睡眠建议。';

    final buffer = StringBuffer('以下是用户最近的睡眠记录：\n\n');
    for (final r in records) {
      buffer.writeln('- 日期: ${r.sleepDate}');
      buffer.writeln('  上床时间: ${r.bedTime}');
      buffer.writeln('  入睡时间: ${r.sleepTime}');
      buffer.writeln('  起床时间: ${r.wakeTime}');
      final hours = r.durationMinutes ~/ 60;
      final minutes = r.durationMinutes % 60;
      buffer.writeln('  睡眠时长: ${hours}小时${minutes}分钟');
      buffer.writeln('  睡眠质量: ${r.qualityLevel}/5');
      buffer.writeln('  入睡耗时: ${r.fallAsleepMinutes}分钟');
      buffer.writeln('  夜醒次数: ${r.wakeCount}次');
      buffer.writeln('  醒后精力: ${r.energyLevel}/5');
      if (r.dreamNote != null && r.dreamNote!.isNotEmpty) {
        buffer.writeln('  梦境: ${r.dreamNote}');
      }
      buffer.writeln();
    }

    final avgDuration =
        records.fold<int>(0, (s, r) => s + r.durationMinutes) / records.length;
    final avgQuality =
        records.fold<double>(0, (s, r) => s + r.qualityLevel) / records.length;
    buffer.writeln(
      '共 ${records.length} 条记录，平均睡眠时长 ${(avgDuration ~/ 60)}小时${(avgDuration % 60).toInt()}分钟，平均质量 ${avgQuality.toStringAsFixed(1)}/5。',
    );
    buffer.writeln('\n请给出分析和建议。');

    return buffer.toString();
  }

  // ---------------------------------------------------------------------------
  // Prompt 构建 — 周报 / 月报
  // ---------------------------------------------------------------------------

  static const _reportSystemPrompt = '''
你是一位成长教练。请根据用户提供的统计数据，生成一份结构清晰的成长报告。

报告应包含：
1. 数据总览（用简洁的数字概括）
2. 亮点与进步（找出做得好的地方）
3. 不足与改进空间
4. 下一周期的具体目标建议

请使用 Markdown 格式，用中文回答，语气积极鼓励。''';

  String _buildWeeklyReportPrompt(Map<String, dynamic> data) {
    final buffer = StringBuffer('以下是用户本周的成长数据：\n\n');

    _appendMapData(buffer, data);

    buffer.writeln('\n请生成一份成长周报。');
    return buffer.toString();
  }

  String _buildMonthlyReportPrompt(Map<String, dynamic> data) {
    final buffer = StringBuffer('以下是用户本月的成长数据：\n\n');

    _appendMapData(buffer, data);

    buffer.writeln('\n请生成一份成长月报，并对比各周的趋势变化。');
    return buffer.toString();
  }

  /// 将 Map 数据格式化为可读文本追加到 buffer。
  void _appendMapData(StringBuffer buffer, Map<String, dynamic> data) {
    data.forEach((key, value) {
      if (value is List) {
        buffer.writeln('$key:');
        for (final item in value) {
          buffer.writeln('  - $item');
        }
      } else if (value is Map) {
        buffer.writeln('$key:');
        value.forEach((k, v) {
          buffer.writeln('  $k: $v');
        });
      } else {
        buffer.writeln('$key: $value');
      }
    });
  }
}

// =============================================================================
// 异常类
// =============================================================================

/// AI 服务异常
class AiServiceException implements Exception {
  const AiServiceException(this.message);

  final String message;

  @override
  String toString() => 'AiServiceException: $message';
}
