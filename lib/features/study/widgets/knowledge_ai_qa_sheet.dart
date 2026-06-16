import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;

import '../../../app/design/design.dart';
import '../../../core/database/app_database.dart';
import '../../../core/services/ai_service.dart';
import '../../../shared/providers/repository_providers.dart';
import '../../../shared/providers/service_providers.dart';

/// 复习页底部 AI 问答抽屉。
///
/// 点击"问 AI"按钮后从底部滑出，支持基于当前卡片上下文的多轮对话。
class KnowledgeAiQaSheet extends ConsumerStatefulWidget {
  const KnowledgeAiQaSheet({super.key, required this.card});

  final KnowledgeCard card;

  @override
  ConsumerState<KnowledgeAiQaSheet> createState() =>
      _KnowledgeAiQaSheetState();
}

class _KnowledgeAiQaSheetState extends ConsumerState<KnowledgeAiQaSheet> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();

  /// 聊天历史：role = 'user' | 'assistant'
  final List<Map<String, String>> _messages = [];

  bool _loading = false;
  String? _error;

  StreamSubscription<String>? _subscription;
  String? _sessionId;
  String _streamingBuffer = '';
  bool _streaming = false;

  KnowledgeCard get _card => widget.card;

  @override
  void initState() {
    super.initState();
    _sessionId = 'card_${_card.id}';
    _loadHistory();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  String get _systemPrompt {
    final buffer = StringBuffer();
    buffer.writeln('你是 Growth OS 的知识卡片辅导助手。');
    buffer.writeln('用户正在复习一张知识卡片，以下是卡片内容：');
    buffer.writeln();
    buffer.writeln('【标题】${_card.title}');
    buffer.writeln('【问题】${_card.question}');
    buffer.writeln('【答案】${_card.answer}');
    if (_card.explanation != null && _card.explanation!.trim().isNotEmpty) {
      buffer.writeln('【解释】${_card.explanation}');
    }
    buffer.writeln();
    buffer.writeln('规则：');
    buffer.writeln('1. 围绕这张卡片的知识点回答用户问题。');
    buffer.writeln('2. 如果用户问的内容与卡片无关，可以适当回答但要引导回知识点。');
    buffer.writeln('3. 回答要简洁、准确、适合复习场景。');
    buffer.writeln('4. 可以用例子、类比来帮助理解。');
    buffer.writeln('5. 使用 Markdown 格式回答。');
    return buffer.toString();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _loadHistory() async {
    if (_sessionId == null) return;
    final repo = ref.read(aiChatRepositoryProvider);
    final history = await repo.getMessagesBySession(_sessionId!);
    if (history.isNotEmpty && mounted) {
      setState(() {
        _messages.clear();
        for (final msg in history) {
          _messages.add({'role': msg.role, 'content': msg.content});
        }
      });
    }
  }

  void _cancelStream() {
    _subscription?.cancel();
    setState(() {
      _streaming = false;
      if (_streamingBuffer.isNotEmpty) {
        _messages.add({'role': 'assistant', 'content': _streamingBuffer});
        _streamingBuffer = '';
      }
    });
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _loading || _streaming) return;

    _controller.clear();
    setState(() {
      _messages.add({'role': 'user', 'content': text});
      _loading = true;
      _streaming = false;
      _streamingBuffer = '';
      _error = null;
    });
    _scrollToBottom();

    // Save user message to DB
    final repo = ref.read(aiChatRepositoryProvider);
    await repo.saveMessage(
      sessionId: _sessionId!,
      cardId: _card.id,
      role: 'user',
      content: text,
    );

    try {
      final aiConfigRepo = ref.read(aiConfigRepositoryProvider);
      final aiConfig = await aiConfigRepo.getEnabledAiConfig();

      if (aiConfig == null) {
        setState(() {
          _error = '请先在设置中配置 AI 服务（API Key）';
          _loading = false;
        });
        return;
      }

      final aiService = ref.read(aiServiceProvider);
      final stream = aiService.chatStream(
        apiKey: aiConfig.apiKey,
        baseUrl: aiConfig.baseUrl,
        model: aiConfig.modelName,
        systemPrompt: _systemPrompt,
        messages: _messages.where((m) => m['role'] != null).toList(),
      );

      setState(() {
        _loading = false;
        _streaming = true;
      });

      _subscription = stream.listen(
        (delta) {
          if (!mounted) return;
          setState(() {
            _streamingBuffer += delta;
          });
          _scrollToBottom();
        },
        onError: (Object error) {
          if (!mounted) return;
          setState(() {
            _error = error is AiServiceException
                ? error.message
                : '请求失败：$error';
            _streaming = false;
            _loading = false;
          });
        },
        onDone: () async {
          if (!mounted) return;
          final fullResponse = _streamingBuffer;
          setState(() {
            if (fullResponse.isNotEmpty) {
              _messages.add({'role': 'assistant', 'content': fullResponse});
            }
            _streaming = false;
            _streamingBuffer = '';
          });
          _scrollToBottom();

          // Save assistant message to DB
          if (fullResponse.isNotEmpty) {
            await repo.saveMessage(
              sessionId: _sessionId!,
              cardId: _card.id,
              role: 'assistant',
              content: fullResponse,
            );
          }
        },
        cancelOnError: false,
      );
    } on AiServiceException catch (e) {
      if (mounted) {
        setState(() {
          _error = e.message;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = '请求失败：$e';
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;

    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: colors.paper,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppRadius.xxxl),
            ),
          ),
          child: Column(
            children: [
              // 拖拽指示条
              Container(
                margin: const EdgeInsets.only(top: 10, bottom: 6),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // 标题栏
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      size: 20,
                      color: colors.study,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'AI 问答',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: colors.textPrimary,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(
                        Icons.close_rounded,
                        size: 20,
                        color: colors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),

              Divider(height: 1, color: colors.border),

              // 聊天消息列表
              Expanded(
                child: _messages.isEmpty && !_loading && !_streaming
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.chat_bubble_outline,
                              size: 48,
                              color: colors.textTertiary.withValues(alpha: 0.4),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              '有什么想问的？',
                              style: TextStyle(
                                color: colors.textTertiary,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.sm,
                        ),
                        itemCount: _messages.length +
                            (_streaming ? 1 : 0) +
                            (_loading ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index < _messages.length) {
                            final msg = _messages[index];
                            return _ChatBubble(
                              isUser: msg['role'] == 'user',
                              content: msg['content'] ?? '',
                              colors: colors,
                            );
                          }

                          // Streaming bubble
                          if (_streaming && index == _messages.length) {
                            return _ChatBubble(
                              isUser: false,
                              content: _streamingBuffer,
                              colors: colors,
                            );
                          }

                          // Loading indicator
                          return _LoadingIndicator(color: colors.study);
                        },
                      ),
              ),

              // 错误提示
              if (_error != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.xs,
                  ),
                  color: colors.danger.withValues(alpha: 0.08),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 16,
                        color: colors.danger,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _error!,
                          style: TextStyle(
                            color: colors.danger,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // 输入栏
              Container(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.sm,
                  AppSpacing.md,
                  MediaQuery.of(context).padding.bottom + AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: colors.paper,
                  border: Border(
                    top: BorderSide(color: colors.border),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: colors.surface,
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                          border: Border.all(color: colors.border),
                        ),
                        child: TextField(
                          controller: _controller,
                          focusNode: _focusNode,
                          maxLines: 3,
                          minLines: 1,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _send(),
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontSize: 14,
                          ),
                          decoration: InputDecoration(
                            hintText: '输入你的问题…',
                            hintStyle: TextStyle(
                              color: colors.textTertiary,
                              fontSize: 14,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Material(
                      color: _loading || _streaming
                          ? colors.surface
                          : colors.study,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      child: InkWell(
                        onTap: _loading
                            ? null
                            : _streaming
                                ? _cancelStream
                                : _send,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        child: SizedBox(
                          width: 38,
                          height: 38,
                          child: Center(
                            child: _loading
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : _streaming
                                    ? Icon(
                                        Icons.stop_rounded,
                                        size: 18,
                                        color: colors.danger,
                                      )
                                    : const Icon(
                                        Icons.send_rounded,
                                        size: 18,
                                      ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// =============================================================================
// 辅助组件
// =============================================================================

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({
    required this.isUser,
    required this.content,
    required this.colors,
  });

  final bool isUser;
  final String content;
  final AppThemeColors colors;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: isUser
              ? colors.study.withValues(alpha: 0.15)
              : colors.card,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(AppRadius.lg),
            topRight: const Radius.circular(AppRadius.lg),
            bottomLeft: Radius.circular(isUser ? AppRadius.lg : 4),
            bottomRight: Radius.circular(isUser ? 4 : AppRadius.lg),
          ),
          border: Border.all(
            color: isUser
                ? colors.study.withValues(alpha: 0.2)
                : colors.border,
          ),
        ),
        child: isUser
            ? Text(
                content,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 14,
                  height: 1.5,
                ),
              )
            : MarkdownBody(
                data: content,
                selectable: true,
                extensionSet: md.ExtensionSet.gitHubFlavored,
                styleSheet: MarkdownStyleSheet(
                  p: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 14,
                    height: 1.5,
                  ),
                  code: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 13,
                    backgroundColor: colors.surface,
                  ),
                  codeblockDecoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  listBullet: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 14,
                  ),
                ),
              ),
      ),
    );
  }
}

class _LoadingIndicator extends StatelessWidget {
  const _LoadingIndicator({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: context.growthColors.card,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(AppRadius.lg),
            topRight: Radius.circular(AppRadius.lg),
            bottomRight: Radius.circular(AppRadius.lg),
            bottomLeft: Radius.circular(4),
          ),
          border: Border.all(color: context.growthColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: color,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '思考中…',
              style: TextStyle(
                color: context.growthColors.textTertiary,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}