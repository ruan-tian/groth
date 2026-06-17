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
    String? knowledgeContext,
  }) async {
    final prompt = _buildStudyPrompt(
      records,
      knowledgeContext: knowledgeContext,
    );
    return _callApiWithRetry(
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
    String? knowledgeContext,
  }) async {
    final prompt = _buildFitnessPrompt(
      records,
      knowledgeContext: knowledgeContext,
    );
    return _callApiWithRetry(
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
    String? knowledgeContext,
  }) async {
    final prompt = _buildDietPrompt(
      records,
      knowledgeContext: knowledgeContext,
    );
    return _callApiWithRetry(
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
    String? knowledgeContext,
  }) async {
    final prompt = _buildSleepPrompt(
      records,
      knowledgeContext: knowledgeContext,
    );
    return _callApiWithRetry(
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
    String? knowledgeContext,
  }) async {
    final prompt = _buildWeeklyReportPrompt(
      weeklyData,
      knowledgeContext: knowledgeContext,
    );
    return _callApiWithRetry(
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
    String? knowledgeContext,
  }) async {
    final prompt = _buildMonthlyReportPrompt(
      monthlyData,
      knowledgeContext: knowledgeContext,
    );
    return _callApiWithRetry(
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
    return _callApiWithRetry(
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

    final client = http.Client();
    try {
      final request = http.Request('POST', url);
      request.headers.addAll(headers);
      request.body = body;

      final response = await client.send(request);

      if (response.statusCode != 200) {
        final responseBody = await response.stream.bytesToString();
        throw AiServiceException(
          'API 请求失败 (${response.statusCode}): $responseBody',
        );
      }

      String buffer = '';
      await for (final chunk in response.stream.transform(utf8.decoder).timeout(
        const Duration(seconds: 120),
        onTimeout: (sink) {
          sink.addError(AiServiceException('AI 流式响应超时（120秒未收到数据）'));
          sink.close();
        },
      )) {
        buffer += chunk;

        while (buffer.contains('\n')) {
          final lineEnd = buffer.indexOf('\n');
          final line = buffer.substring(0, lineEnd).trim();
          buffer = buffer.substring(lineEnd + 1);

          if (line.startsWith('data: ')) {
            final data = line.substring(6).trim();
            if (data == '[DONE]') {
              return;
            }

            try {
              final json = jsonDecode(data) as Map<String, dynamic>;
              final choices = json['choices'] as List<dynamic>?;
              if (choices != null && choices.isNotEmpty) {
                final delta = choices[0]['delta'] as Map<String, dynamic>?;
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
    } on http.ClientException catch (e) {
      throw AiServiceException('网络请求失败: ${e.message}');
    } on TimeoutException {
      throw AiServiceException('API 请求超时（${_defaultTimeout.inSeconds}秒）');
    } finally {
      client.close();
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
  // 重试逻辑
  // ---------------------------------------------------------------------------

  /// 判断异常是否可重试。
  ///
  /// 可重试的错误类型：
  /// - 网络请求失败 (http.ClientException)
  /// - HTTP 429 (请求过多)
  /// - HTTP 500/502/503 (服务端错误)
  static bool _isRetryableError(AiServiceException e) {
    final msg = e.message;
    // 网络错误
    if (msg.contains('网络请求失败')) return true;
    // 解析 HTTP 状态码
    final statusCodeMatch = RegExp(r'请求失败 \((\d+)\)').firstMatch(msg);
    if (statusCodeMatch != null) {
      final statusCode = int.tryParse(statusCodeMatch.group(1)!);
      if (statusCode != null) {
        return statusCode == 429 ||
            statusCode == 500 ||
            statusCode == 502 ||
            statusCode == 503;
      }
    }
    return false;
  }

  /// 带重试的 API 调用。
  ///
  /// 最多重试 2 次（共 3 次尝试），指数退避：
  /// 第 1 次失败后等 1 秒，第 2 次失败后等 3 秒。
  Future<String> _callApiWithRetry({
    required String apiKey,
    required String baseUrl,
    required String model,
    required String systemPrompt,
    required String userPrompt,
    double temperature = 0.7,
    int maxTokens = 2048,
  }) async {
    const maxRetries = 2;
    const backoffDelays = [1, 3]; // 秒

    for (var attempt = 0; attempt <= maxRetries; attempt++) {
      try {
        return await _callApi(
          apiKey: apiKey,
          baseUrl: baseUrl,
          model: model,
          systemPrompt: systemPrompt,
          userPrompt: userPrompt,
          temperature: temperature,
          maxTokens: maxTokens,
        );
      } on AiServiceException catch (e) {
        if (attempt < maxRetries && _isRetryableError(e)) {
          await Future.delayed(Duration(seconds: backoffDelays[attempt]));
          continue;
        }
        rethrow;
      }
    }
    // 不会执行到这里，但为了编译器不报错
    throw const AiServiceException('重试次数已用尽');
  }

  // ---------------------------------------------------------------------------
  // Prompt 构建 — 学习
  // ---------------------------------------------------------------------------

  static const _studySystemPrompt = '''
你是一位专业的学习顾问。请根据用户的学习记录数据，给出分析和建议。

分析维度：
1. 学习时间分布与规律性
2. 学习效率（结合专注度、难度）
3. 科目均衡性

输出要求：
- 使用 Markdown 格式
- 分为「数据概览」「分析」「建议」三个部分
- 建议部分给出 2-3 条具体可执行的建议
- 每条建议用 "- [ ]" 任务清单格式
- 总字数控制在 300 字以内
- 使用中文，语气简洁鼓励，不说教''';

  String _buildStudyPrompt(
    List<StudyRecord> records, {
    String? knowledgeContext,
  }) {
    if (records.isEmpty) {
      return '用户最近 7 天没有学习记录。请给出鼓励性建议：1) 可能正在休息，鼓励适度休息后重新开始；2) 建议尝试简单模式快速记录；3) 给一个今天可执行的 10 分钟学习小任务。';
    }

    // 截取最近 15 条，避免 token 溢出
    final recent = records.length > 15
        ? records.sublist(records.length - 15)
        : records;

    final buffer = StringBuffer('用户最近 ${records.length} 条学习记录');
    if (records.length > 15) buffer.write('（已截取最近 15 条）');
    buffer.writeln('：\n');

    for (final r in recent) {
      final date = DateTime.fromMillisecondsSinceEpoch(r.createdAt);
      buffer.write(
        '${date.month}/${date.day} | ${r.title} | ${r.durationMinutes}min',
      );
      if (r.subject != null) buffer.write(' | ${r.subject}');
      if (r.focusLevel != null) buffer.write(' | 专注${r.focusLevel}/5');
      if (r.difficultyLevel != null) {
        buffer.write(' | 难度${r.difficultyLevel}/5');
      }
      buffer.writeln();
    }

    final totalMinutes = records.fold<int>(0, (s, r) => s + r.durationMinutes);
    final avgMinutes = (totalMinutes / records.length).round();
    final studyDays = records
        .map((r) {
          final dt = DateTime.fromMillisecondsSinceEpoch(r.createdAt);
          return '${dt.year}-${dt.month}-${dt.day}';
        })
        .toSet()
        .length;
    final recordsLength = records.length;
    buffer.writeln(
      '\n汇总: $recordsLength次, $studyDays天, 共${totalMinutes}min, 平均${avgMinutes}min/次',
    );

    _appendKnowledgeContext(buffer, knowledgeContext);

    return buffer.toString();
  }

  // ---------------------------------------------------------------------------
  // Prompt 构建 — 健身
  // ---------------------------------------------------------------------------

  static const _fitnessSystemPrompt = '''
你是一位专业的健身教练。请根据用户的训练记录数据，给出分析和建议。

分析维度：
1. 训练频率与规律性
2. 训练强度与恢复情况
3. 身体部位均衡性

输出要求：
- 使用 Markdown 格式
- 分为「数据概览」「分析」「建议」三个部分
- 建议 2-3 条，用 "- [ ]" 任务清单格式
- 总字数控制在 300 字以内
- 使用中文，语气专业鼓励，不说教''';

  String _buildFitnessPrompt(
    List<FitnessRecord> records, {
    String? knowledgeContext,
  }) {
    if (records.isEmpty) {
      return '用户最近 7 天没有健身记录。请给出鼓励性建议：1) 可能需要休息日；2) 建议从轻量训练开始恢复；3) 给一个今天可执行的 10 分钟拉伸任务。';
    }

    final recent = records.length > 15
        ? records.sublist(records.length - 15)
        : records;

    final buffer = StringBuffer('用户最近 ${records.length} 条健身记录');
    if (records.length > 15) buffer.write('（已截取最近 15 条）');
    buffer.writeln('：\n');

    for (final r in recent) {
      final date = DateTime.fromMillisecondsSinceEpoch(r.createdAt);
      buffer.write(
        '${date.month}/${date.day} | ${r.bodyPart} | ${r.durationMinutes}min',
      );
      if (r.title != null && r.title!.isNotEmpty) buffer.write(' | ${r.title}');
      if (r.intensityLevel != null) buffer.write(' | 强度${r.intensityLevel}/5');
      buffer.writeln();
    }

    final totalMinutes = records.fold<int>(0, (s, r) => s + r.durationMinutes);
    final bodyParts = <String, int>{};
    for (final r in records) {
      bodyParts[r.bodyPart] = (bodyParts[r.bodyPart] ?? 0) + 1;
    }
    final partSummary = bodyParts.entries
        .map((e) => '${e.key}${e.value}次')
        .join(', ');
    buffer.writeln(
      '\n汇总: ${records.length}次, 共${totalMinutes}min | 部位: $partSummary',
    );
    _appendKnowledgeContext(buffer, knowledgeContext);

    return buffer.toString();
  }

  // ---------------------------------------------------------------------------
  // Prompt 构建 — 饮食
  // ---------------------------------------------------------------------------

  static const _dietSystemPrompt = '''
你是一位专业的营养顾问。请根据用户的饮食记录数据，给出分析和建议。

分析维度：
1. 饮食规律性（三餐是否规律）
2. 营养均衡性（蛋白质、热量摄入）
3. 健康评分趋势

输出要求：
- 使用 Markdown 格式
- 分为「数据概览」「分析」「建议」三个部分
- 建议 2-3 条，用 "- [ ]" 任务清单格式
- 总字数控制在 300 字以内
- 使用中文，语气友好鼓励，不说教''';

  String _buildDietPrompt(
    List<DietRecord> records, {
    String? knowledgeContext,
  }) {
    if (records.isEmpty) {
      return '用户最近 7 天没有饮食记录。请给出鼓励性建议：1) 建议从记录一顿早餐开始；2) 简单记录比完美记录更重要；3) 给一个今天可以尝试的健康饮食小建议。';
    }

    final recent = records.length > 20
        ? records.sublist(records.length - 20)
        : records;

    final buffer = StringBuffer('用户最近 ${records.length} 条饮食记录');
    if (records.length > 20) buffer.write('（已截取最近 20 条）');
    buffer.writeln('：\n');

    for (final r in recent) {
      buffer.write(
        '${r.mealDate} | ${_getMealTypeName(r.mealType)} | ${r.foodText}',
      );
      buffer.write(
        ' | ${_getPortionName(r.portionLevel)} | ${_getCalorieName(r.calorieLevel)}',
      );
      buffer.writeln(' | 评分${r.healthScore}/5');
    }

    final avgScore =
        records.fold<double>(0, (s, r) => s + r.healthScore) / records.length;
    final mealTypes = <String, int>{};
    for (final r in records) {
      mealTypes[r.mealType] = (mealTypes[r.mealType] ?? 0) + 1;
    }
    final mealSummary = mealTypes.entries
        .map((e) => '${_getMealTypeName(e.key)}${e.value}次')
        .join(', ');
    buffer.writeln(
      '\n汇总: ${records.length}条, 平均评分${avgScore.toStringAsFixed(1)}/5 | $mealSummary',
    );
    _appendKnowledgeContext(buffer, knowledgeContext);

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

  // ---------------------------------------------------------------------------
  // Prompt 构建 — 睡眠
  // ---------------------------------------------------------------------------

  static const _sleepSystemPrompt = '''
你是一位专业的睡眠专家。请根据用户的睡眠记录数据，给出分析和建议。

分析维度：
1. 睡眠时长是否充足（建议 7-9 小时）
2. 睡眠质量评估
3. 作息规律性（入睡/起床时间是否稳定）
4. 入睡问题（入睡耗时、夜醒情况）

输出要求：
- 使用 Markdown 格式
- 分为「数据概览」「分析」「建议」三个部分
- 建议 2-3 条，用 "- [ ]" 任务清单格式
- 总字数控制在 300 字以内
- 使用中文，语气关怀鼓励，不说教''';

  String _buildSleepPrompt(
    List<SleepRecord> records, {
    String? knowledgeContext,
  }) {
    if (records.isEmpty) {
      return '用户最近 7 天没有睡眠记录。请给出鼓励性建议：1) 建议设置固定的就寝提醒；2) 记录睡眠可以帮助发现规律；3) 给一个今天可以尝试的助眠小建议。';
    }

    final recent = records.length > 14
        ? records.sublist(records.length - 14)
        : records;

    final buffer = StringBuffer('用户最近 ${records.length} 条睡眠记录');
    if (records.length > 14) buffer.write('（已截取最近 14 条）');
    buffer.writeln('：\n');

    for (final r in recent) {
      final hours = r.durationMinutes ~/ 60;
      final minutes = r.durationMinutes % 60;
      buffer.write(
        '${r.sleepDate} | ${r.bedTime}-${r.wakeTime} | ${hours}h${minutes}m',
      );
      buffer.write(' | 质量${r.qualityLevel}/5 | 入睡${r.fallAsleepMinutes}min');
      if (r.wakeCount > 0) buffer.write(' | 夜醒${r.wakeCount}次');
      buffer.writeln();
    }

    final avgDuration =
        records.fold<int>(0, (s, r) => s + r.durationMinutes) / records.length;
    final avgQuality =
        records.fold<double>(0, (s, r) => s + r.qualityLevel) / records.length;
    final avgFallAsleep =
        records.fold<int>(0, (s, r) => s + r.fallAsleepMinutes) /
        records.length;
    buffer.writeln(
      '\n汇总: ${records.length}条 | 平均${(avgDuration ~/ 60)}h${(avgDuration % 60).toInt()}m | 质量${avgQuality.toStringAsFixed(1)}/5 | 入睡${avgFallAsleep.toStringAsFixed(0)}min',
    );
    _appendKnowledgeContext(buffer, knowledgeContext);

    return buffer.toString();
  }

  // ---------------------------------------------------------------------------
  // Prompt 构建 — 周报 / 月报
  // ---------------------------------------------------------------------------

  static const _reportSystemPrompt = '''
你是一位成长教练。请根据用户提供的统计数据，生成一份结构清晰的成长报告。

报告结构：
1. 数据总览（用简洁的数字概括）
2. 亮点与进步（找出做得好的地方）
3. 不足与改进空间
4. 下一周期的具体目标建议（用 "- [ ]" 任务清单格式）

输出要求：
- 使用 Markdown 格式
- 总字数控制在 400 字以内
- 使用中文，语气积极鼓励''';

  String _buildWeeklyReportPrompt(
    Map<String, dynamic> data, {
    String? knowledgeContext,
  }) {
    final buffer = StringBuffer('以下是用户本周的成长数据：\n\n');

    _appendMapData(buffer, data);
    _appendKnowledgeContext(buffer, knowledgeContext);

    buffer.writeln('\n请生成一份成长周报。');
    return buffer.toString();
  }

  String _buildMonthlyReportPrompt(
    Map<String, dynamic> data, {
    String? knowledgeContext,
  }) {
    final buffer = StringBuffer('以下是用户本月的成长数据：\n\n');

    _appendMapData(buffer, data);
    _appendKnowledgeContext(buffer, knowledgeContext);

    buffer.writeln('\n请生成一份成长月报，并对比各周的趋势变化。');
    return buffer.toString();
  }

  void _appendKnowledgeContext(StringBuffer buffer, String? knowledgeContext) {
    final context = knowledgeContext?.trim();
    if (context == null || context.isEmpty) return;
    buffer
      ..writeln()
      ..writeln(context)
      ..writeln('请优先参考本地知识库片段，让建议更贴合用户记录；如果片段与当前分析无关，请明确忽略。')
      ..writeln('当建议基于某个本地片段时，请在句末标注对应编号，例如【片段 1】。');
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

  // ---------------------------------------------------------------------------
  // ---------------------------------------------------------------------------
  // 通用对话（知识卡 QA）
  // ---------------------------------------------------------------------------

  /// 通用 AI 对话，返回回复文本。
  ///
  /// 用于知识卡复习页的 AI 问答功能，支持多轮对话上下文。
  Future<String> chat({
    required String apiKey,
    required String baseUrl,
    required String model,
    required String systemPrompt,
    required List<Map<String, String>> messages,
    double temperature = 0.7,
    int maxTokens = 2048,
  }) async {
    final normalizedBase = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final url = Uri.parse('$normalizedBase/chat/completions');

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $apiKey',
    };

    final allMessages = <Map<String, String>>[
      {'role': 'system', 'content': systemPrompt},
      ...messages,
    ];

    final body = jsonEncode({
      'model': model,
      'messages': allMessages,
      'temperature': temperature,
      'max_tokens': maxTokens,
    });

    try {
      final response = await http
          .post(url, headers: headers, body: body)
          .timeout(_defaultTimeout);

      if (response.statusCode != 200) {
        throw AiServiceException(
          'API 请求失败 (${response.statusCode}): ${response.body.length > 300 ? response.body.substring(0, 300) : response.body}',
        );
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final choices = json['choices'] as List<dynamic>?;
      if (choices == null || choices.isEmpty) {
        throw const AiServiceException('API 返回数据格式异常：无 choices 字段');
      }

      final message = choices[0]['message'] as Map<String, dynamic>?;
      final content = message?['content'] as String?;
      if (content == null || content.isEmpty) {
        throw const AiServiceException('API 返回内容为空');
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
  // 流式对话
  // ---------------------------------------------------------------------------

  /// 流式 AI 对话，返回逐步输出的 Stream。
  ///
  /// 用于知识卡复习页的 AI 问答功能，支持多轮对话上下文的流式输出。
  Stream<String> chatStream({
    required String apiKey,
    required String baseUrl,
    required String model,
    required String systemPrompt,
    required List<Map<String, String>> messages,
    double temperature = 0.7,
    int maxTokens = 2048,
  }) async* {
    final allMessages = <Map<String, String>>[
      {'role': 'system', 'content': systemPrompt},
      ...messages,
    ];

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
      'messages': allMessages,
      'temperature': temperature,
      'max_tokens': maxTokens,
      'stream': true,
    });

    final client = http.Client();
    try {
      final request = http.Request('POST', url);
      request.headers.addAll(headers);
      request.body = body;

      final response = await client.send(request);

      if (response.statusCode != 200) {
        final responseBody = await response.stream.bytesToString();
        throw AiServiceException(
          'API 请求失败 (${response.statusCode}): $responseBody',
        );
      }

      String buffer = '';
      await for (final chunk in response.stream.transform(utf8.decoder).timeout(
        const Duration(seconds: 120),
        onTimeout: (sink) {
          sink.addError(AiServiceException('AI 流式响应超时（120秒未收到数据）'));
          sink.close();
        },
      )) {
        buffer += chunk;

        while (buffer.contains('\n')) {
          final lineEnd = buffer.indexOf('\n');
          final line = buffer.substring(0, lineEnd).trim();
          buffer = buffer.substring(lineEnd + 1);

          if (line.startsWith('data: ')) {
            final data = line.substring(6).trim();
            if (data == '[DONE]') {
              return;
            }
            try {
              final json = jsonDecode(data) as Map<String, dynamic>;
              final choices = json['choices'] as List<dynamic>?;
              if (choices != null && choices.isNotEmpty) {
                final delta = choices[0]['delta'] as Map<String, dynamic>?;
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
    } on http.ClientException catch (e) {
      throw AiServiceException('网络请求失败: ${e.message}');
    } on TimeoutException {
      throw AiServiceException('API 请求超时（${_defaultTimeout.inSeconds}秒）');
    } finally {
      client.close();
    }
  }

  // ---------------------------------------------------------------------------
  // 流式分析方法
  // ---------------------------------------------------------------------------

  /// 流式分析学习记录。
  Stream<String> analyzeStudyStream({
    required String apiKey,
    required String baseUrl,
    required String model,
    required List<StudyRecord> records,
    String? knowledgeContext,
  }) {
    final prompt = _buildStudyPrompt(
      records,
      knowledgeContext: knowledgeContext,
    );
    return streamApi(
      apiKey: apiKey,
      baseUrl: baseUrl,
      model: model,
      systemPrompt: _studySystemPrompt,
      userPrompt: prompt,
    );
  }

  /// 流式分析健身记录。
  Stream<String> analyzeFitnessStream({
    required String apiKey,
    required String baseUrl,
    required String model,
    required List<FitnessRecord> records,
    String? knowledgeContext,
  }) {
    final prompt = _buildFitnessPrompt(
      records,
      knowledgeContext: knowledgeContext,
    );
    return streamApi(
      apiKey: apiKey,
      baseUrl: baseUrl,
      model: model,
      systemPrompt: _fitnessSystemPrompt,
      userPrompt: prompt,
    );
  }

  /// 流式分析饮食记录。
  Stream<String> analyzeDietStream({
    required String apiKey,
    required String baseUrl,
    required String model,
    required List<DietRecord> records,
    String? knowledgeContext,
  }) {
    final prompt = _buildDietPrompt(
      records,
      knowledgeContext: knowledgeContext,
    );
    return streamApi(
      apiKey: apiKey,
      baseUrl: baseUrl,
      model: model,
      systemPrompt: _dietSystemPrompt,
      userPrompt: prompt,
    );
  }

  /// 流式分析睡眠记录。
  Stream<String> analyzeSleepStream({
    required String apiKey,
    required String baseUrl,
    required String model,
    required List<SleepRecord> records,
    String? knowledgeContext,
  }) {
    final prompt = _buildSleepPrompt(
      records,
      knowledgeContext: knowledgeContext,
    );
    return streamApi(
      apiKey: apiKey,
      baseUrl: baseUrl,
      model: model,
      systemPrompt: _sleepSystemPrompt,
      userPrompt: prompt,
    );
  }

  /// 流式生成周报。
  Stream<String> generateWeeklyReportStream({
    required String apiKey,
    required String baseUrl,
    required String model,
    required Map<String, dynamic> weeklyData,
    String? knowledgeContext,
  }) {
    final prompt = _buildWeeklyReportPrompt(
      weeklyData,
      knowledgeContext: knowledgeContext,
    );
    return streamApi(
      apiKey: apiKey,
      baseUrl: baseUrl,
      model: model,
      systemPrompt: _reportSystemPrompt,
      userPrompt: prompt,
    );
  }

  /// 流式生成月报。
  Stream<String> generateMonthlyReportStream({
    required String apiKey,
    required String baseUrl,
    required String model,
    required Map<String, dynamic> monthlyData,
    String? knowledgeContext,
  }) {
    final prompt = _buildMonthlyReportPrompt(
      monthlyData,
      knowledgeContext: knowledgeContext,
    );
    return streamApi(
      apiKey: apiKey,
      baseUrl: baseUrl,
      model: model,
      systemPrompt: _reportSystemPrompt,
      userPrompt: prompt,
    );
  }

  // Vision OCR — 图片文字提取
  // ---------------------------------------------------------------------------

  // ---------------------------------------------------------------------------
  // Vision OCR — 图片文字提取
  // ---------------------------------------------------------------------------

  /// 从图片中提取文字（OCR），使用 AI Vision API。
  ///
  /// 发送 base64 编码的图片到 Vision API，返回识别出的文字内容。
  /// 支持 OpenAI、DeepSeek、Gemini 等兼容 Vision 接口。
  ///
  /// [imageBytes] 为图片文件的原始字节。
  /// [mimeType] 为图片 MIME 类型，如 `image/png`、`image/jpeg`。
  /// [prompt] 可选的自定义 prompt，默认提示提取全部文字。
  Future<String> ocrImage({
    required String apiKey,
    required String baseUrl,
    required String model,
    required List<int> imageBytes,
    required String mimeType,
    String? prompt,
  }) async {
    final base64Image = base64Encode(imageBytes);
    final dataUrl = 'data:$mimeType;base64,$base64Image';
    final ocrPrompt = prompt?.trim().isNotEmpty == true
        ? prompt!.trim()
        : '请提取图片中的所有文字内容，保持原文格式和段落结构。只输出识别到的文字，不要添加任何解释或说明。';

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
        {
          'role': 'user',
          'content': [
            {'type': 'text', 'text': ocrPrompt},
            {
              'type': 'image_url',
              'image_url': {'url': dataUrl},
            },
          ],
        },
      ],
      'temperature': 0.1,
      'max_tokens': 4096,
    });

    try {
      final response = await http
          .post(url, headers: headers, body: body)
          .timeout(_defaultTimeout);

      if (response.statusCode != 200) {
        throw AiServiceException(
          'Vision API 请求失败 (${response.statusCode}): '
          '${response.body.length > 200 ? response.body.substring(0, 200) : response.body}',
        );
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final choices = json['choices'] as List<dynamic>?;
      if (choices == null || choices.isEmpty) {
        throw const AiServiceException('Vision API 返回空结果');
      }

      final message = choices[0]['message'] as Map<String, dynamic>?;
      final content = message?['content'] as String?;
      if (content == null || content.trim().isEmpty) {
        throw const AiServiceException('Vision API 未识别到文字');
      }

      return content.trim();
    } on AiServiceException {
      rethrow;
    } on TimeoutException {
      throw const AiServiceException('Vision API 请求超时，请检查网络连接');
    } on Exception catch (e) {
      throw AiServiceException(
        'Vision API 调用失败: ${e.toString().split('\n').first}',
      );
    }
  }
}

// 异常类
// =============================================================================

/// AI 服务异常
class AiServiceException implements Exception {
  const AiServiceException(this.message);

  final String message;

  @override
  String toString() => 'AiServiceException: $message';
}
