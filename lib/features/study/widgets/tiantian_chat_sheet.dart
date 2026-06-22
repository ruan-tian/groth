import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/design/design.dart';
import '../../../core/repositories/knowledge_v3_repository.dart';
import '../services/knowledge_v3_ai_service.dart';
import '../../../shared/providers/knowledge_card_ai_provider.dart';
import '../../../shared/providers/knowledge_v3_provider.dart';
import '../../../shared/providers/repository_providers.dart';
import '../../../shared/providers/settings_provider.dart';

const _tiantianAvatarAsset = 'assets/pet/ai/ai_daily_summary.webp';
const _tiantianAvatarFallbackAsset =
    'assets/images/knowledge_cards/v3/tiantian_avatar.webp';

/// 流式对话弹窗 ?闔?
///
/// 鏀寔锛?
/// - 璧勬枡瑙ｈ€︼紙鍙互涓嶉€夎祫鏂欑洿鎺ユ彁闂級
/// - 流式输出（字显示?
/// - 浼氳瘽鎸佷箙鍖栵紙绌洪棿绾у璇濆巻鍙诧級
/// - 杩介棶锛堝湪鍚屼竴浼氳瘽涓户缁璇濓級
/// - 资料侧边栏（随时叉择/移除参资料）
class TiantianChatSheet extends ConsumerStatefulWidget {
  const TiantianChatSheet({
    super.key,
    required this.space,
    this.initialQuestion,
    this.materials = const [],
    this.sessionId,
  });

  final KnowledgeSpaceV3 space;
  final String? initialQuestion;
  final List<KnowledgeMaterial> materials;
  final int? sessionId;

  @override
  ConsumerState<TiantianChatSheet> createState() => _TiantianChatSheetState();
}

class _TiantianChatSheetState extends ConsumerState<TiantianChatSheet> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  int? _currentSessionId;
  bool _isStreaming = false;
  bool _isLoadingHistory = true;
  bool _sentInitialQuestion = false;
  String _streamingBuffer = '';
  StreamSubscription<String>? _streamSub;
  List<KnowledgeMaterial> _selectedMaterials = [];
  List<_ChatMessage> _messages = [];

  @override
  void initState() {
    super.initState();
    _selectedMaterials = List.from(widget.materials);
    _loadSession();
  }

  Future<void> _loadSession() async {
    final repo = ref.read(knowledgeV3RepositoryProvider);
    try {
      TiantianQaSession session;
      if (widget.sessionId != null) {
        final existing = await repo.getQaSession(widget.sessionId!);
        if (existing != null) {
          session = existing;
        } else {
          session = await repo.getOrCreateSpaceSession(widget.space.id);
        }
      } else {
        session = await repo.getOrCreateSpaceSession(widget.space.id);
      }
      _currentSessionId = session.id;

      final history = await repo.getQaMessages(session.id);
      if (!mounted) return;
      setState(() {
        _messages = history
            .map(
              (m) => _ChatMessage(
                role: m.role,
                content: m.content,
                sources: _parseSourceTitles(m.sourcesJson),
                answerMode: _parseAnswerMode(m.sourcesJson),
                grounded: _parseGrounded(m.sourcesJson),
                savedAsCard: m.savedAsCard,
              ),
            )
            .toList();
        _isLoadingHistory = false;
      });

      final initialQuestion = widget.initialQuestion?.trim();
      if (!_sentInitialQuestion &&
          initialQuestion != null &&
          initialQuestion.isNotEmpty) {
        _sentInitialQuestion = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _sendMessage(initialQuestion);
        });
      } else {
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingHistory = false);
    }
  }

  Object? _decodeSourcesJson(String? json) {
    if (json == null || json.trim().isEmpty) return null;
    try {
      return jsonDecode(json);
    } catch (_) {}
    return null;
  }

  List<String>? _parseSourceTitles(String? json) {
    final decoded = _decodeSourcesJson(json);
    final list = decoded is Map ? decoded['sources'] : decoded;
    if (list is! List) return null;
    final titles = list
        .whereType<Map>()
        .map((m) => m['title']?.toString() ?? '')
        .where((s) => s.isNotEmpty)
        .toList(growable: false);
    return titles.isEmpty ? null : titles;
  }

  String? _parseAnswerMode(String? json) {
    final decoded = _decodeSourcesJson(json);
    if (decoded is Map) return decoded['answerMode']?.toString();
    return null;
  }

  bool? _parseGrounded(String? json) {
    final decoded = _decodeSourcesJson(json);
    if (decoded is Map && decoded['grounded'] is bool) {
      return decoded['grounded'] as bool;
    }
    return null;
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    _streamSub?.cancel();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendMessage(String question) async {
    if (question.trim().isEmpty || _isStreaming) return;

    setState(() {
      _messages.add(_ChatMessage(role: 'user', content: question.trim()));
      _isStreaming = true;
      _streamingBuffer = '';
    });
    _inputController.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

    try {
      final repo = ref.read(knowledgeV3RepositoryProvider);

      if (_currentSessionId == null) {
        final session = await repo.getOrCreateSpaceSession(widget.space.id);
        _currentSessionId = session.id;
      }

      if (_messages.length == 1) {
        final title = question.trim().length > 50
            ? '${question.trim().substring(0, 50)}...'
            : question.trim();
        await repo.updateSessionTitle(_currentSessionId!, title);
      }

      await repo.addQaMessage(
        sessionId: _currentSessionId!,
        role: 'user',
        content: question.trim(),
        sources: _selectedMaterials,
        answerMode: _currentAnswerMode,
        grounded: _selectedMaterials.isNotEmpty,
      );

      await repo.updateSessionMaterials(
        _currentSessionId!,
        _selectedMaterials.map((m) => m.id).toList(),
      );

      final history = await repo.getQaMessages(_currentSessionId!);

      final aiService = ref.read(knowledgeV3AiServiceProvider);
      _streamSub = aiService
          .streamAnswer(
            space: widget.space,
            question: question.trim(),
            materials: _selectedMaterials,
            history: history,
          )
          .listen(
            (chunk) {
              if (mounted) {
                setState(() => _streamingBuffer += chunk);
                _scrollToBottom();
              }
            },
            onDone: () async {
              if (_currentSessionId != null && _streamingBuffer.isNotEmpty) {
                await repo.addQaMessage(
                  sessionId: _currentSessionId!,
                  role: 'assistant',
                  content: _streamingBuffer,
                  sources: _selectedMaterials,
                );
              }
              if (mounted) {
                setState(() {
                  _messages.add(
                    _ChatMessage(
                      role: 'assistant',
                      content: _streamingBuffer,
                      sources: _selectedMaterials.map((m) => m.title).toList(),
                      answerMode: _currentAnswerMode,
                      grounded: _selectedMaterials.isNotEmpty,
                    ),
                  );
                  _isStreaming = false;
                  _streamingBuffer = '';
                });
                _scrollToBottom();
                ref.invalidate(tiantianQaSessionsProvider(widget.space.id));
              }
            },
            onError: (error) {
              if (mounted) {
                setState(() {
                  _messages.add(
                    _ChatMessage(
                      role: 'assistant',
                      content:
                          '\u62b1\u6b49\uff0c\u9047\u5230\u4e86\u95ee\u9898\uff1a$error',
                      isError: true,
                    ),
                  );
                  _isStreaming = false;
                  _streamingBuffer = '';
                });
                _scrollToBottom();
              }
            },
          );
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add(
            _ChatMessage(
              role: 'assistant',
              content:
                  '\u62b1\u6b49\uff0c\u9047\u5230\u4e86\u95ee\u9898\uff1a$e',
              isError: true,
            ),
          );
          _isStreaming = false;
          _streamingBuffer = '';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors =
        Theme.of(context).extension<AppThemeColors>() ?? AppThemeColors.light;
    ref.watch(userAvatarInitProvider);
    final userAvatarPath = ref.watch(userAvatarPathProvider);

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
      ),
      child: Column(
        children: [
          _buildHeader(colors),
          _buildModeBar(colors),
          Expanded(
            child: _isLoadingHistory
                ? Center(child: CircularProgressIndicator(color: colors.study))
                : _messages.isEmpty
                ? _buildEmptyState(colors)
                : _buildMessageList(colors, userAvatarPath),
          ),
          if (_isStreaming && _streamingBuffer.isEmpty)
            _buildThinkingIndicator(colors),
          if (_isStreaming && _streamingBuffer.isNotEmpty)
            _buildStreamingMessage(colors),
          _buildInput(colors),
        ],
      ),
    );
  }

  String get _currentAnswerMode =>
      _selectedMaterials.isEmpty ? 'general' : 'grounded';

  Widget _buildHeader(AppThemeColors colors) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 14, 14, 14),
      decoration: BoxDecoration(color: colors.background),
      child: Column(
        children: [
          Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              color: colors.border,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          Row(
            children: [
              _buildAvatar(colors, size: 54),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '\u95ee\u751c\u751c',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${widget.space.name} \u00b7 AI \u5b66\u4e60\u52a9\u624b',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              _HeaderIconButton(
                tooltip: '\u8d44\u6599\u5e93',
                icon: Icons.library_books_rounded,
                foreground: _selectedMaterials.isEmpty
                    ? colors.textSecondary
                    : colors.study,
                background: _selectedMaterials.isEmpty
                    ? colors.surface
                    : colors.study.withValues(alpha: 0.1),
                badge: _selectedMaterials.isEmpty
                    ? null
                    : _selectedMaterials.length.toString(),
                onTap: _showMaterialPicker,
              ),
              const SizedBox(width: 8),
              _HeaderIconButton(
                tooltip: '\u5173\u95ed',
                icon: Icons.close_rounded,
                foreground: colors.textSecondary,
                background: colors.surface,
                onTap: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModeBar(AppThemeColors colors) {
    final grounded = _selectedMaterials.isNotEmpty;
    final modeColor = grounded ? colors.success : colors.warning;
    final title = grounded
        ? '\u8d44\u6599\u4e25\u683c\u6a21\u5f0f'
        : '\u666e\u901a\u5b66\u4e60\u6a21\u5f0f';
    final description = grounded
        ? '\u5df2\u5f15\u7528 ${_selectedMaterials.length} \u4efd\u8d44\u6599\uff0c\u56de\u7b54\u4f1a\u4f18\u5148\u57fa\u4e8e\u8d44\u6599\u3002'
        : '\u672a\u5f15\u7528\u7a7a\u95f4\u8d44\u6599\uff0c\u53ef\u4ee5\u76f4\u63a5\u63d0\u95ee\uff0c\u4e5f\u53ef\u4ee5\u5148\u9009\u62e9\u8d44\u6599\u3002';
    return Container(
      margin: const EdgeInsets.fromLTRB(18, 0, 18, 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: grounded
            ? colors.success.withValues(alpha: 0.08)
            : const Color(0xFFFFF6DD),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: modeColor.withValues(alpha: 0.16)),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.18),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: modeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  grounded
                      ? Icons.verified_outlined
                      : Icons.chat_bubble_outline_rounded,
                  size: 18,
                  color: modeColor,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.35,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: _showMaterialPicker,
                style: TextButton.styleFrom(
                  foregroundColor: colors.study,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  minimumSize: const Size(0, 36),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(grounded ? '\u8c03\u6574' : '\u9009\u8d44\u6599'),
                    const SizedBox(width: 2),
                    const Icon(Icons.chevron_right_rounded, size: 18),
                  ],
                ),
              ),
            ],
          ),
          if (_selectedMaterials.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final material in _selectedMaterials)
                  InputChip(
                    label: Text(
                      material.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    avatar: Icon(
                      Icons.description_outlined,
                      size: 16,
                      color: colors.study,
                    ),
                    deleteIcon: Icon(
                      Icons.close_rounded,
                      size: 16,
                      color: colors.textSecondary,
                    ),
                    onDeleted: () => setState(
                      () => _selectedMaterials.removeWhere(
                        (m) => m.id == material.id,
                      ),
                    ),
                    backgroundColor: colors.study.withValues(alpha: 0.08),
                    side: BorderSide(
                      color: colors.study.withValues(alpha: 0.1),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                    labelStyle: TextStyle(
                      fontSize: 12,
                      color: colors.textPrimary,
                    ),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState(AppThemeColors colors) {
    final grounded = _selectedMaterials.isNotEmpty;
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAvatar(colors, size: 42),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: colors.border),
                  boxShadow: [
                    BoxShadow(
                      color: colors.shadow.withValues(alpha: 0.22),
                      blurRadius: 22,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      grounded
                          ? '\u6211\u4f1a\u6309\u5df2\u9009\u8d44\u6599\u56de\u7b54\uff5e'
                          : '\u6211\u73b0\u5728\u8fd8\u6ca1\u6709\u5f15\u7528\u7a7a\u95f4\u8d44\u6599\u54e6\uff5e',
                      style: TextStyle(
                        fontSize: 16,
                        height: 1.45,
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      grounded
                          ? '\u4f60\u53ef\u4ee5\u76f4\u63a5\u7ee7\u7eed\u63d0\u95ee\uff0c\u6211\u4f1a\u5c3d\u91cf\u6807\u6ce8\u5173\u952e\u4fe1\u606f\u6765\u81ea\u54ea\u91cc\u3002'
                          : '\u4f60\u53ef\u4ee5\u76f4\u63a5\u95ee\u6211\uff1b\u5982\u679c\u5e0c\u671b\u6211\u4e25\u683c\u6839\u636e\u8d44\u6599\u56de\u7b54\uff0c\u53ef\u4ee5\u5148\u9009\u62e9\u6216\u4e0a\u4f20\u8d44\u6599\u3002',
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.55,
                        color: colors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        OutlinedButton(
                          onPressed: () => _inputController.text =
                              '\u6211\u60f3\u7ee7\u7eed\u63d0\u95ee\uff1a',
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 42),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text('\u7ee7\u7eed\u63d0\u95ee'),
                        ),
                        FilledButton.tonal(
                          onPressed: _showMaterialPicker,
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(0, 42),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text('\u9009\u8d44\u6599'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: colors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _MessageModePill(
                label: grounded
                    ? '\u8d44\u6599\u4e25\u683c\u56de\u7b54'
                    : '\u666e\u901a\u5b66\u4e60\u56de\u7b54',
                icon: grounded
                    ? Icons.verified_outlined
                    : Icons.chat_bubble_outline_rounded,
                color: grounded ? colors.success : colors.warning,
              ),
              const SizedBox(height: 14),
              Text(
                '\u4f60\u53ef\u4ee5\u8bd5\u8bd5\u95ee\u6211\uff1a',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              for (final prompt in const [
                '\u8fd9\u4efd\u8d44\u6599\u7684\u91cd\u70b9\u662f\u4ec0\u4e48\uff1f',
                '\u5e2e\u6211\u6574\u7406\u6210\u8003\u8bd5\u9898\u578b\u601d\u8def\u3002',
                '\u54ea\u4e9b\u5185\u5bb9\u6700\u9002\u5408\u751f\u6210\u77e5\u8bc6\u5361\uff1f',
              ])
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _SuggestedQuestionTile(
                    text: prompt,
                    onTap: () => _sendMessage(prompt),
                    colors: colors,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMessageList(AppThemeColors colors, String? userAvatarPath) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        final isUser = message.role == 'user';
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _buildMessageRow(
            colors,
            message: message,
            userAvatarPath: userAvatarPath,
            onSaveAsCard: !isUser && !message.isError
                ? () => _saveAssistantMessageAsCards(index)
                : null,
          ),
        );
      },
    );
  }

  Widget _buildThinkingIndicator(AppThemeColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: _buildAssistantShell(
        colors,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(colors.study),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '\u601d\u8003\u4e2d...',
              style: TextStyle(fontSize: 14, color: colors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStreamingMessage(AppThemeColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: _buildAssistantShell(
        colors,
        child: _buildMessageBubble(
          colors,
          message: _ChatMessage(
            role: 'assistant',
            content: _streamingBuffer,
            answerMode: _currentAnswerMode,
          ),
          isStreaming: true,
        ),
      ),
    );
  }

  Widget _buildMessageRow(
    AppThemeColors colors, {
    required _ChatMessage message,
    required String? userAvatarPath,
    Future<void> Function()? onSaveAsCard,
  }) {
    final isUser = message.role == 'user';
    if (isUser) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: _messageMaxWidth(context, isUser: true),
                ),
                child: _buildMessageBubble(colors, message: message),
              ),
            ),
          ),
          const SizedBox(width: 10),
          _buildAvatar(colors, isUser: true, userAvatarPath: userAvatarPath),
        ],
      );
    }

    return _buildAssistantShell(
      colors,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMessageBubble(colors, message: message),
          if (message.sources != null && message.sources!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 5, left: 4, right: 4),
              child: Text(
                '\u53c2\u8003\uff1a${_wrapLongTokens(message.sources!.join(', '))}',
                softWrap: true,
                overflow: TextOverflow.visible,
                style: TextStyle(fontSize: 12, color: colors.textHint),
              ),
            ),
          if (onSaveAsCard != null)
            _AnswerCardAction(saved: message.savedAsCard, onSave: onSaveAsCard),
        ],
      ),
    );
  }

  Widget _buildAssistantShell(AppThemeColors colors, {required Widget child}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildAvatar(colors),
        const SizedBox(width: 12),
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: _messageMaxWidth(context, isUser: false),
              ),
              child: child,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMessageBubble(
    AppThemeColors colors, {
    required _ChatMessage message,
    bool isStreaming = false,
  }) {
    final isUser = message.role == 'user';
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: isUser ? colors.study : colors.surface,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(18),
          topRight: const Radius.circular(18),
          bottomLeft: Radius.circular(isUser ? 18 : 6),
          bottomRight: Radius.circular(isUser ? 6 : 18),
        ),
        border: isUser ? null : Border.all(color: colors.border),
        boxShadow: isUser
            ? null
            : [
                BoxShadow(
                  color: colors.shadow.withValues(alpha: 0.18),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            _MessageModePill(
              label: _messageModeLabel(message),
              icon: _messageModeIcon(message),
              color: _messageModeColor(colors, message),
            ),
            const SizedBox(height: 8),
          ],
          SelectableText(
            _wrapLongTokens(message.content),
            textWidthBasis: TextWidthBasis.parent,
            style: TextStyle(
              fontSize: 15,
              height: 1.55,
              color: isUser ? Colors.white : colors.textPrimary,
            ),
          ),
          if (isStreaming)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(colors.study),
                ),
              ),
            ),
        ],
      ),
    );
  }

  double _messageMaxWidth(BuildContext context, {required bool isUser}) {
    final width = MediaQuery.sizeOf(context).width;
    final ratio = isUser ? 0.72 : 0.78;
    return (width * ratio).clamp(220.0, 620.0);
  }

  String _wrapLongTokens(String text) {
    if (text.isEmpty) return text;
    const breakChar = '\u200B';
    const maxRun = 24;
    final out = StringBuffer();
    final token = StringBuffer();

    void flushToken() {
      final value = token.toString();
      token.clear();
      if (value.length <= maxRun) {
        out.write(value);
        return;
      }
      for (var i = 0; i < value.length; i++) {
        final char = value[i];
        out.write(char);
        final atInterval = (i + 1) % maxRun == 0;
        final atDelimiter = '/?&=._-#:%'.contains(char);
        if (i < value.length - 1 && (atInterval || atDelimiter)) {
          out.write(breakChar);
        }
      }
    }

    for (var i = 0; i < text.length; i++) {
      final char = text[i];
      if (char.trim().isEmpty) {
        flushToken();
        out.write(char);
      } else {
        token.write(char);
      }
    }
    flushToken();
    return out.toString();
  }

  Widget _buildAvatar(
    AppThemeColors colors, {
    bool isUser = false,
    double? size,
    String? userAvatarPath,
  }) {
    final dimension = size ?? (isUser ? 34.0 : 40.0);
    final validUserAvatarPath = normalizeUserAvatarPath(userAvatarPath);
    final userFile = validUserAvatarPath == null
        ? null
        : File(validUserAvatarPath);
    final hasUserAvatar = userFile != null;
    return Container(
      width: dimension,
      height: dimension,
      padding: EdgeInsets.all(isUser ? 0 : 2),
      decoration: BoxDecoration(
        color: isUser ? colors.primary : colors.surface,
        borderRadius: BorderRadius.circular(isUser ? 12 : 14),
        border: isUser ? null : Border.all(color: colors.border),
      ),
      child: isUser
          ? hasUserAvatar
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(userFile, fit: BoxFit.cover),
                  )
                : const Icon(
                    Icons.person_rounded,
                    color: Colors.white,
                    size: 18,
                  )
          : ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                _tiantianAvatarAsset,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Image.asset(
                  _tiantianAvatarFallbackAsset,
                  fit: BoxFit.cover,
                ),
              ),
            ),
    );
  }

  Widget _buildInput(AppThemeColors colors) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      decoration: BoxDecoration(
        color: colors.paper,
        border: Border(
          top: BorderSide(color: colors.border.withValues(alpha: 0.5)),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: colors.border),
              ),
              child: TextField(
                controller: _inputController,
                maxLines: 4,
                minLines: 1,
                decoration: InputDecoration(
                  hintText: '\u95ee\u751c\u751c\u4efb\u4f55\u95ee\u9898...',
                  hintStyle: TextStyle(color: colors.textHint),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                onSubmitted: _sendMessage,
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 46,
            height: 46,
            child: FilledButton(
              onPressed: _isStreaming
                  ? null
                  : () => _sendMessage(_inputController.text),
              style: FilledButton.styleFrom(
                padding: EdgeInsets.zero,
                backgroundColor: colors.study,
                disabledBackgroundColor: colors.border,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: _isStreaming
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(
                          colors.textSecondary,
                        ),
                      ),
                    )
                  : const Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  void _showMaterialPicker() async {
    final materials = await ref.read(
      knowledgeMaterialsV3Provider(widget.space.id).future,
    );
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _MaterialPickerSheet(
        materials: materials,
        selectedIds: _selectedMaterials.map((m) => m.id).toSet(),
        onConfirm: (selected) async {
          setState(() => _selectedMaterials = selected);
          final sessionId = _currentSessionId;
          if (sessionId != null) {
            await ref
                .read(knowledgeV3RepositoryProvider)
                .updateSessionMaterials(
                  sessionId,
                  selected.map((m) => m.id).toList(),
                );
            ref.invalidate(tiantianQaSessionsProvider(widget.space.id));
          }
        },
      ),
    );
  }

  String _messageModeLabel(_ChatMessage message) {
    if (message.role == 'user') return '';
    final mode =
        message.answerMode ??
        (message.sources?.isNotEmpty == true ? 'grounded' : 'general');
    return switch (mode) {
      'grounded' => '\u57fa\u4e8e\u8d44\u6599\u56de\u7b54',
      'hybrid' => '\u8d44\u6599\u4f18\u5148\u56de\u7b54',
      _ => '\u666e\u901a\u5b66\u4e60\u56de\u7b54',
    };
  }

  IconData _messageModeIcon(_ChatMessage message) {
    final mode =
        message.answerMode ??
        (message.sources?.isNotEmpty == true ? 'grounded' : 'general');
    return switch (mode) {
      'grounded' => Icons.verified_outlined,
      'hybrid' => Icons.merge_type_rounded,
      _ => Icons.chat_bubble_outline_rounded,
    };
  }

  Color _messageModeColor(AppThemeColors colors, _ChatMessage message) {
    final mode =
        message.answerMode ??
        (message.sources?.isNotEmpty == true ? 'grounded' : 'general');
    return switch (mode) {
      'grounded' => colors.success,
      'hybrid' => colors.study,
      _ => colors.warning,
    };
  }

  Future<void> _saveAssistantMessageAsCards(int index) async {
    final sessionId = _currentSessionId;
    if (sessionId == null || index < 0 || index >= _messages.length) return;
    final assistant = _messages[index];
    if (assistant.role != 'assistant' || assistant.savedAsCard) return;

    String question = '';
    for (var i = index - 1; i >= 0; i--) {
      if (_messages[i].role == 'user') {
        question = _messages[i].content;
        break;
      }
    }
    if (question.trim().isEmpty) return;

    try {
      final answerSources = await _materialsForMessage(assistant);
      final ids = await ref
          .read(knowledgeV3AiServiceProvider)
          .saveAnswerAsCards(
            space: widget.space,
            answer: TiantianAnswer(
              sessionId: sessionId,
              question: question,
              answer: assistant.content,
              sources: answerSources,
            ),
          );
      if (!mounted) return;
      setState(() {
        _messages[index] = assistant.copyWith(savedAsCard: true);
      });
      invalidateKnowledgeV3(ref, spaceId: widget.space.id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '\u5df2\u751f\u6210 ${ids.length} \u5f20\u77e5\u8bc6\u5361',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '\u4fdd\u5b58\u77e5\u8bc6\u5361\u5931\u8d25\uff1a$error',
          ),
        ),
      );
    }
  }

  Future<List<KnowledgeMaterial>> _materialsForMessage(
    _ChatMessage message,
  ) async {
    if (_selectedMaterials.isNotEmpty) return _selectedMaterials;
    final titles = message.sources;
    if (titles == null || titles.isEmpty) return const [];
    final materials = await ref.read(
      knowledgeMaterialsV3Provider(widget.space.id).future,
    );
    final titleSet = titles.toSet();
    return materials
        .where((material) => titleSet.contains(material.title))
        .toList(growable: false);
  }
}

class _SuggestedQuestionTile extends StatelessWidget {
  const _SuggestedQuestionTile({
    required this.text,
    required this.onTap,
    required this.colors,
  });

  final String text;
  final VoidCallback onTap;
  final AppThemeColors colors;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: colors.study.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colors.study,
                  ),
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: colors.study, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.tooltip,
    required this.icon,
    required this.foreground,
    required this.background,
    required this.onTap,
    this.badge,
  });

  final String tooltip;
  final IconData icon;
  final Color foreground;
  final Color background;
  final VoidCallback onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              SizedBox(
                width: 42,
                height: 42,
                child: Icon(icon, size: 22, color: foreground),
              ),
              if (badge != null)
                Positioned(
                  right: 5,
                  top: 5,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: foreground,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      badge!,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MessageModePill extends StatelessWidget {
  const _MessageModePill({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _AnswerCardAction extends StatefulWidget {
  const _AnswerCardAction({required this.saved, required this.onSave});

  final bool saved;
  final Future<void> Function() onSave;

  @override
  State<_AnswerCardAction> createState() => _AnswerCardActionState();
}

class _AnswerCardActionState extends State<_AnswerCardAction> {
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final colors =
        Theme.of(context).extension<AppThemeColors>() ?? AppThemeColors.light;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: TextButton.icon(
        onPressed: widget.saved || _saving
            ? null
            : () async {
                setState(() => _saving = true);
                try {
                  await widget.onSave();
                } finally {
                  if (mounted) setState(() => _saving = false);
                }
              },
        style: TextButton.styleFrom(
          foregroundColor: widget.saved ? colors.textHint : colors.study,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          minimumSize: const Size(0, 34),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        icon: _saving
            ? SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(colors.study),
                ),
              )
            : Icon(
                widget.saved
                    ? Icons.check_circle_outline_rounded
                    : Icons.style_outlined,
                size: 16,
              ),
        label: Text(
          widget.saved
              ? '\u5df2\u751f\u6210\u77e5\u8bc6\u5361'
              : '\u62c6\u6210\u77e5\u8bc6\u5361',
        ),
      ),
    );
  }
}

class _MaterialPickerSheet extends StatefulWidget {
  const _MaterialPickerSheet({
    required this.materials,
    required this.selectedIds,
    required this.onConfirm,
  });

  final List<KnowledgeMaterial> materials;
  final Set<int> selectedIds;
  final FutureOr<void> Function(List<KnowledgeMaterial>) onConfirm;

  @override
  State<_MaterialPickerSheet> createState() => _MaterialPickerSheetState();
}

class _MaterialPickerSheetState extends State<_MaterialPickerSheet> {
  late final Set<int> _selected = Set.from(widget.selectedIds);

  @override
  Widget build(BuildContext context) {
    final colors =
        Theme.of(context).extension<AppThemeColors>() ?? AppThemeColors.light;
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.6,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: colors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
            child: Row(
              children: [
                Text(
                  '\u9009\u62e9\u53c2\u8003\u8d44\u6599',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
                const Spacer(),
                Text(
                  '${_selected.length} \u5df2\u9009',
                  style: TextStyle(fontSize: 13, color: colors.textSecondary),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          if (widget.materials.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                '\u8fd8\u6ca1\u6709\u8d44\u6599\uff0c\u53ef\u4ee5\u5148\u5728\u77e5\u8bc6\u5e93\u4e2d\u5bfc\u5165',
                style: TextStyle(color: colors.textSecondary),
              ),
            )
          else
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                itemCount: widget.materials.length,
                itemBuilder: (context, index) {
                  final material = widget.materials[index];
                  final isSelected = _selected.contains(material.id);
                  return CheckboxListTile(
                    value: isSelected,
                    onChanged: (checked) {
                      setState(() {
                        if (checked == true) {
                          _selected.add(material.id);
                        } else {
                          _selected.remove(material.id);
                        }
                      });
                    },
                    title: Text(
                      material.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      '${material.content.length} \u5b57',
                      style: TextStyle(fontSize: 12, color: colors.textHint),
                    ),
                    activeColor: colors.study,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                  );
                },
              ),
            ),
          Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, bottomPadding + 12),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () async {
                  final selected = widget.materials
                      .where((m) => _selected.contains(m.id))
                      .toList();
                  await widget.onConfirm(selected);
                  if (!context.mounted) return;
                  Navigator.of(context).pop();
                },
                style: FilledButton.styleFrom(
                  backgroundColor: colors.study,
                  minimumSize: const Size(0, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text('\u786e\u8ba4'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatMessage {
  final String role;
  final String content;
  final List<String>? sources;
  final String? answerMode;
  final bool? grounded;
  final bool isError;
  final bool savedAsCard;

  _ChatMessage({
    required this.role,
    required this.content,
    this.sources,
    this.answerMode,
    this.grounded,
    this.isError = false,
    this.savedAsCard = false,
  });

  _ChatMessage copyWith({
    String? role,
    String? content,
    List<String>? sources,
    String? answerMode,
    bool? grounded,
    bool? isError,
    bool? savedAsCard,
  }) {
    return _ChatMessage(
      role: role ?? this.role,
      content: content ?? this.content,
      sources: sources ?? this.sources,
      answerMode: answerMode ?? this.answerMode,
      grounded: grounded ?? this.grounded,
      isError: isError ?? this.isError,
      savedAsCard: savedAsCard ?? this.savedAsCard,
    );
  }
}
