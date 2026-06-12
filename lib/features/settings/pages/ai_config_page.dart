import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/database/app_database.dart';
import '../../../core/services/ai_service.dart';
import '../../../core/services/encryption_service.dart';
import '../../../shared/providers/repository_providers.dart';

/// AI 服务提供商模型
class AIProvider {
  final String id;
  final String name;
  final String icon;
  final String imagePath;
  final String defaultBaseUrl;
  final List<String> models;

  const AIProvider({
    required this.id,
    required this.name,
    required this.icon,
    required this.imagePath,
    required this.defaultBaseUrl,
    required this.models,
  });
}

/// AI 配置页面（褐色渐变风格）
class AiConfigPage extends ConsumerStatefulWidget {
  const AiConfigPage({super.key});

  @override
  ConsumerState<AiConfigPage> createState() => _AiConfigPageState();
}

class _AiConfigPageState extends ConsumerState<AiConfigPage> {
  final _apiAddressController = TextEditingController();
  final _apiKeyController = TextEditingController();

  int? _existingConfigId;
  AIProvider? _selectedProvider;
  String _selectedModel = '';
  String _existingApiKey = '';
  bool _isApiKeyVisible = false;
  bool _isEditingApiKey = false;
  bool _isTesting = false;
  bool _isSaving = false;
  bool _isLoading = true;
  double _temperature = 0.7;
  int _maxTokens = 2048;

  // AI 服务提供商列表（9个 + 自定义）
  static const _providers = <AIProvider>[
    AIProvider(
      id: 'deepseek',
      name: 'DeepSeek',
      icon: '🔮',
      imagePath: 'assets/images/ai_providers/deepseek.webp',
      defaultBaseUrl: 'https://api.deepseek.com/v1',
      models: ['deepseek-chat', 'deepseek-reasoner'],
    ),
    AIProvider(
      id: 'qwen',
      name: '通义千问',
      icon: '☁️',
      imagePath: 'assets/images/ai_providers/qwen.webp',
      defaultBaseUrl: 'https://dashscope.aliyuncs.com/compatible-mode/v1',
      models: ['qwen-max', 'qwen-plus', 'qwen-turbo'],
    ),
    AIProvider(
      id: 'zhipu',
      name: '智谱',
      icon: '🧠',
      imagePath: 'assets/images/ai_providers/zhipu.webp',
      defaultBaseUrl: 'https://open.bigmodel.cn/api/paas/v4',
      models: ['glm-4-plus', 'glm-4-flash', 'glm-4-long'],
    ),
    AIProvider(
      id: 'moonshot',
      name: 'Moonshot',
      icon: '🌙',
      imagePath: 'assets/images/ai_providers/moonshot.webp',
      defaultBaseUrl: 'https://api.moonshot.cn/v1',
      models: ['moonshot-v1-128k', 'moonshot-v1-32k'],
    ),
    AIProvider(
      id: 'spark',
      name: '讯飞星火',
      icon: '🔥',
      imagePath: 'assets/images/ai_providers/spark.webp',
      defaultBaseUrl: 'https://spark-api-open.xf-yun.com/v1',
      models: ['spark-max', 'spark-pro'],
    ),
    AIProvider(
      id: 'baichuan',
      name: '百川',
      icon: '🌊',
      imagePath: 'assets/images/ai_providers/baichuan.webp',
      defaultBaseUrl: 'https://api.baichuan-ai.com/v1',
      models: ['Baichuan4', 'Baichuan3-Turbo'],
    ),
    AIProvider(
      id: 'minimax',
      name: 'MiniMax',
      icon: '🎯',
      imagePath: 'assets/images/ai_providers/minimax.webp',
      defaultBaseUrl: 'https://api.minimax.chat/v1',
      models: ['abab6.5-chat', 'abab6.5s-chat'],
    ),
    AIProvider(
      id: 'openai',
      name: 'OpenAI',
      icon: '🤖',
      imagePath: 'assets/images/ai_providers/openai.webp',
      defaultBaseUrl: 'https://api.openai.com/v1',
      models: ['gpt-4o', 'gpt-4o-mini', 'gpt-4-turbo'],
    ),
    AIProvider(
      id: 'gemini',
      name: 'Gemini',
      icon: '✨',
      imagePath: 'assets/images/ai_providers/gemini.webp',
      defaultBaseUrl: 'https://generativelanguage.googleapis.com/v1',
      models: ['gemini-pro', 'gemini-pro-vision'],
    ),
    AIProvider(
      id: 'custom',
      name: '自定义',
      icon: '⚙️',
      imagePath: 'assets/images/ai_providers/custom.webp',
      defaultBaseUrl: '',
      models: [],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadExistingConfig();
  }

  @override
  void dispose() {
    _apiAddressController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _loadExistingConfig() async {
    try {
      final repo = ref.read(aiConfigRepositoryProvider);
      final config = await repo.getEnabledAiConfig();

      if (config != null && mounted) {
        setState(() {
          _existingConfigId = config.id;
          _existingApiKey = config.apiKey;
          _selectedProvider = _providers.firstWhere(
            (p) => p.id == config.provider,
            orElse: () => _providers.last,
          );
          _apiAddressController.text = config.baseUrl;
          _apiKeyController.text = EncryptionService.maskApiKey(config.apiKey);
          _selectedModel = config.modelName;
          _isLoading = false;
        });
      } else if (mounted) {
        setState(() {
          _selectedProvider = _providers.first;
          _apiAddressController.text = _providers.first.defaultBaseUrl;
          _selectedModel = _providers.first.models.isNotEmpty
              ? _providers.first.models.first
              : '';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _selectProvider(AIProvider provider) {
    setState(() {
      _selectedProvider = provider;
      if (provider.defaultBaseUrl.isNotEmpty) {
        _apiAddressController.text = provider.defaultBaseUrl;
      }
      if (provider.models.isNotEmpty) {
        _selectedModel = provider.models.first;
      } else {
        _selectedModel = '';
      }
    });
  }

  Future<void> _testConnection() async {
    if (_selectedProvider == null) return;

    setState(() => _isTesting = true);

    try {
      final apiKeyInput = _apiKeyController.text.trim();
      final baseUrl = _apiAddressController.text.trim();
      final model = _selectedModel;

      if (apiKeyInput.isEmpty || baseUrl.isEmpty || model.isEmpty) {
        _showSnackBar('请填写完整的 API 配置', isError: true);
        return;
      }

      // 判断使用哪个 API Key
      String apiKey;
      if (_existingApiKey.isNotEmpty &&
          apiKeyInput == EncryptionService.maskApiKey(_existingApiKey)) {
        // 用户没有修改 key，使用已有的（已解密的）
        apiKey = _existingApiKey;
      } else {
        // 用户输入了新 key，检查是否是加密过的
        apiKey = EncryptionService.isEncrypted(apiKeyInput)
            ? EncryptionService.decrypt(apiKeyInput)
            : apiKeyInput;
      }

      final aiService = AiService();
      final result = await aiService.callApi(
        apiKey: apiKey,
        baseUrl: baseUrl,
        model: model,
        systemPrompt: 'You are a helpful assistant.',
        userPrompt: 'Say "连接成功" in 3 words or less.',
      );

      if (mounted) {
        _showSnackBar(
          '连接测试成功！AI 响应: ${result.length > 50 ? "${result.substring(0, 50)}..." : result}',
        );
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('连接测试失败: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isTesting = false);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? const Color(0xFFFF6B6B)
            : const Color(0xFF35C976),
      ),
    );
  }

  Future<void> _saveConfig() async {
    if (_apiAddressController.text.trim().isEmpty) {
      _showSnackBar('请填写 API 地址', isError: true);
      return;
    }

    final apiKeyInput = _apiKeyController.text.trim();
    if (apiKeyInput.isEmpty) {
      _showSnackBar('请填写 API Key', isError: true);
      return;
    }

    // 判断用户是否修改了 API Key
    String apiKeyToSave;
    if (_existingApiKey.isNotEmpty &&
        apiKeyInput == EncryptionService.maskApiKey(_existingApiKey)) {
      // 用户没有修改 key，使用已有的（已解密的）
      apiKeyToSave = _existingApiKey;
    } else {
      // 用户输入了新 key
      apiKeyToSave = apiKeyInput;
    }

    setState(() => _isSaving = true);
    try {
      final repo = ref.read(aiConfigRepositoryProvider);
      final now = DateTime.now().millisecondsSinceEpoch;

      if (_existingConfigId != null) {
        await repo.updateAiConfig(
          AiConfigsCompanion(
            id: Value(_existingConfigId!),
            provider: Value(_selectedProvider?.id ?? 'custom'),
            baseUrl: Value(_apiAddressController.text.trim()),
            apiKey: Value(apiKeyToSave),
            modelName: Value(_selectedModel),
            enabled: const Value(true),
            updatedAt: Value(now),
          ),
        );
      } else {
        final id = await repo.insertAiConfig(
          AiConfigsCompanion(
            provider: Value(_selectedProvider?.id ?? 'custom'),
            baseUrl: Value(_apiAddressController.text.trim()),
            apiKey: Value(apiKeyToSave),
            modelName: Value(_selectedModel),
            enabled: const Value(true),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );
        _existingConfigId = id;
      }

      if (mounted) {
        HapticFeedback.lightImpact();
        _showSnackBar('AI 配置已保存');
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('保存失败: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF5E1),
      appBar: AppBar(
        title: const Text(
          'AI 配置',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF5C3D2E),
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          color: const Color(0xFF5C3D2E),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        top: false,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight - 40,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // ── 说明卡片 ──
                          _buildInfoCard(),
                          const SizedBox(height: 24),

                          // ── 服务提供商选择（3列网格） ──
                          _buildSectionTitle('选择服务商'),
                          const SizedBox(height: 12),
                          _buildProviderGrid(),
                          const SizedBox(height: 24),

                          // ── API 配置 ──
                          _buildSectionTitle('API 配置'),
                          const SizedBox(height: 12),
                          _buildApiConfigForm(),
                          const SizedBox(height: 24),

                          // ── 模型选择 ──
                          if (_selectedProvider != null &&
                              _selectedProvider!.models.isNotEmpty) ...[
                            _buildSectionTitle('模型选择'),
                            const SizedBox(height: 12),
                            _buildModelSelector(),
                            const SizedBox(height: 24),
                          ],

                          // ── 高级参数 ──
                          _buildSectionTitle('高级参数'),
                          const SizedBox(height: 12),
                          _buildAdvancedParams(),
                          const SizedBox(height: 24),

                          // ── 测试连接按钮 ──
                          _buildTestButton(),
                          const SizedBox(height: 12),

                          // ── 保存按钮 ──
                          _buildSaveButton(),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Color(0xFF5C3D2E),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 说明卡片
  // ---------------------------------------------------------------------------

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF1DF), Color(0xFFFFF8F0)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE8C9A0).withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFD4A574).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.info_outline_rounded,
              color: Color(0xFFD4A574),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              '配置 AI 服务后，可使用 AI 分析学习、健身和成长数据，生成个性化建议。',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF8B6F5E),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 服务商网格（3列）
  // ---------------------------------------------------------------------------

  Widget _buildProviderGrid() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE8C9A0).withValues(alpha: 0.3),
        ),
      ),
      padding: const EdgeInsets.all(12),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 1.1,
        ),
        itemCount: _providers.length,
        itemBuilder: (context, index) {
          final provider = _providers[index];
          final isSelected = _selectedProvider?.id == provider.id;
          return _buildProviderItem(provider, isSelected);
        },
      ),
    );
  }

  Widget _buildProviderItem(AIProvider provider, bool isSelected) {
    return Semantics(
      button: true,
      label: '选择${provider.name}服务商',
      selected: isSelected,
      child: GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        _selectProvider(provider);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFF1DF) : const Color(0xFFF8F8F8),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFD4A574)
                : const Color(0xFFE8C9A0).withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  provider.imagePath,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    color: const Color(0xFFF0F0F0),
                    child: Center(
                      child: Text(
                        provider.icon,
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              provider.name,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected
                    ? const Color(0xFF5C3D2E)
                    : const Color(0xFF8B6F5E),
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (isSelected)
              Container(
                margin: const EdgeInsets.only(top: 4),
                width: 16,
                height: 2,
                decoration: BoxDecoration(
                  color: const Color(0xFFD4A574),
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
          ],
        ),
      ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // API 配置表单
  // ---------------------------------------------------------------------------

  Widget _buildApiConfigForm() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE8C9A0).withValues(alpha: 0.3),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // API 地址
          _buildTextField(
            controller: _apiAddressController,
            label: 'API 地址',
            hint: '例如：https://api.openai.com/v1',
            icon: Icons.link_rounded,
          ),
          const SizedBox(height: 16),

          // API Key
          _buildTextField(
            controller: _apiKeyController,
            label: 'API Key',
            hint: '输入你的 API Key',
            icon: Icons.key_rounded,
            isPassword: true,
            textInputAction: TextInputAction.done,
            onTap: () {
              if (!_isEditingApiKey && _existingApiKey.isNotEmpty) {
                setState(() {
                  _isEditingApiKey = true;
                  _apiKeyController.clear();
                });
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    VoidCallback? onTap,
    TextInputAction? textInputAction,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Color(0xFF8B6F5E),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          textInputAction: textInputAction ?? TextInputAction.next,
          onTap: onTap,
          obscureText: isPassword && !_isApiKeyVisible,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFFC9CDD4)),
            prefixIcon: Icon(icon, size: 18, color: const Color(0xFFD4A574)),
            suffixIcon: isPassword
                ? Semantics(
                    button: true,
                    label: _isApiKeyVisible ? '隐藏API Key' : '显示API Key',
                    child: GestureDetector(
                    onTap: () {
                      setState(() => _isApiKeyVisible = !_isApiKeyVisible);
                    },
                    child: Icon(
                      _isApiKeyVisible
                          ? Icons.visibility_off_rounded
                          : Icons.visibility_rounded,
                      size: 18,
                      color: const Color(0xFFB0A09A),
                    ),
                    ),
                  )
                : null,
            filled: true,
            fillColor: const Color(0xFFF8F8F8),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: const Color(0xFFE8C9A0).withValues(alpha: 0.5),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: const Color(0xFFE8C9A0).withValues(alpha: 0.5),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFFD4A574),
                width: 1.5,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 高级参数
  // ---------------------------------------------------------------------------

  Widget _buildAdvancedParams() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE8C9A0).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Temperature
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '温度 (Temperature)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF5C3D2E),
                ),
              ),
              Text(
                _temperature.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFD4A574),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            '控制输出的随机性。0=确定性，2=最大随机',
            style: TextStyle(fontSize: 12, color: Color(0xFFB0A09A)),
          ),
          Slider(
            value: _temperature,
            min: 0.0,
            max: 2.0,
            divisions: 20,
            activeColor: const Color(0xFFD4A574),
            onChanged: (v) => setState(() => _temperature = v),
          ),
          const SizedBox(height: 16),

          // Max Tokens
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '最大 Token 数',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF5C3D2E),
                ),
              ),
              Text(
                '$_maxTokens',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFD4A574),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            '控制 AI 回复的最大长度。1 token ≈ 1.5 个中文字',
            style: TextStyle(fontSize: 12, color: Color(0xFFB0A09A)),
          ),
          Slider(
            value: _maxTokens.toDouble(),
            min: 256,
            max: 8192,
            divisions: 32,
            activeColor: const Color(0xFFD4A574),
            onChanged: (v) => setState(() => _maxTokens = v.round()),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 模型选择
  // ---------------------------------------------------------------------------

  Widget _buildModelSelector() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE8C9A0).withValues(alpha: 0.3),
        ),
      ),
      padding: const EdgeInsets.all(12),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _selectedProvider!.models.map((model) {
          final isSelected = _selectedModel == model;
          return Semantics(
            button: true,
            label: '选择$model模型',
            selected: isSelected,
            child: GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              setState(() => _selectedModel = model);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFFFFF1DF)
                    : const Color(0xFFF8F8F8),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFFD4A574)
                      : const Color(0xFFE8C9A0).withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                model,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected
                      ? const Color(0xFF5C3D2E)
                      : const Color(0xFF8B6F5E),
                ),
              ),
            ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 按钮
  // ---------------------------------------------------------------------------

  Widget _buildTestButton() {
    return Semantics(
      button: true,
      label: '测试连接',
      child: GestureDetector(
      onTap: _isTesting ? null : _testConnection,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFFE8C9A0).withValues(alpha: 0.5),
          ),
        ),
        child: Center(
          child: _isTesting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.wifi_tethering_rounded,
                      size: 18,
                      color: Color(0xFF5D68F2),
                    ),
                    SizedBox(width: 8),
                    Text(
                      '测试连接',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF5D68F2),
                      ),
                    ),
                  ],
                ),
        ),
      ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return Semantics(
      button: true,
      label: '保存配置',
      child: GestureDetector(
      onTap: _isSaving ? null : _saveConfig,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: _isSaving
              ? null
              : const LinearGradient(
                  colors: [Color(0xFFD4A574), Color(0xFFE8C9A0)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          color: _isSaving ? const Color(0xFFE8C9A0) : null,
          borderRadius: BorderRadius.circular(12),
          boxShadow: _isSaving
              ? null
              : [
                  BoxShadow(
                    color: const Color(0xFFD4A574).withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Center(
          child: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text(
                  '保存配置',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
        ),
      ),
      ),
    );
  }
}
