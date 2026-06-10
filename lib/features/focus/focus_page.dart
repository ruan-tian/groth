import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/database/app_database.dart';
import '../../shared/providers/focus_provider.dart';
import 'utils/focus_assets.dart';
import 'utils/focus_options.dart';
import 'widgets/sound_selector.dart';

part 'widgets/focus_setup_helpers.dart';
part 'widgets/focus_setup_widgets.dart';

const _focusMint = Color(0xFF4CBDAE);
const _focusMintDark = Color(0xFF188C83);
const _focusInk = Color(0xFF2D3333);
const _focusLine = Color(0xFFE8DDD1);

class FocusPage extends ConsumerStatefulWidget {
  const FocusPage({super.key});

  @override
  ConsumerState<FocusPage> createState() => _FocusPageState();
}

class _FocusPageState extends ConsumerState<FocusPage> {
  final _customController = TextEditingController(text: '30');
  final _titleController = TextEditingController();
  final _subjectController = TextEditingController();

  @override
  void dispose() {
    _customController.dispose();
    _titleController.dispose();
    _subjectController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final setup = ref.watch(focusSetupProvider);
    final todayMinutes = ref.watch(todayFocusMinutesProvider);
    final recentSessions = ref.watch(recentFocusSessionsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFFFCF6),
      body: SafeArea(
        child: RefreshIndicator(
          color: _focusMint,
          onRefresh: () async {
            ref.invalidate(todayFocusMinutesProvider);
            ref.invalidate(recentFocusSessionsProvider);
          },
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isLandscape =
                  constraints.maxWidth >= constraints.maxHeight &&
                  constraints.maxWidth >= 900;
              if (isLandscape) {
                return _LandscapeFocusSetup(
                  setup: setup,
                  todayMinutes: todayMinutes,
                  recentSessions: recentSessions,
                  titleController: _titleController,
                  subjectController: _subjectController,
                  customController: _customController,
                  onStart: () => _startFocus(setup),
                );
              }
              return _PortraitFocusSetup(
                setup: setup,
                todayMinutes: todayMinutes,
                recentSessions: recentSessions,
                titleController: _titleController,
                subjectController: _subjectController,
                customController: _customController,
                onStart: () => _startFocus(setup),
              );
            },
          ),
        ),
      ),
    );
  }

  void _startFocus(FocusSetupState setup) {
    final duration = setup.type == 'custom'
        ? (int.tryParse(_customController.text) ?? 30)
        : setup.durationMinutes;
    final title = _titleController.text.trim();
    final subject = setup.subject ?? _subjectController.text.trim();

    if (duration <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请输入有效的专注时长')));
      return;
    }

    context.push(
      '/focus/session'
      '?duration=$duration'
      '&type=${setup.type}'
      '&rounds=${setup.totalRounds}'
      '&title=${Uri.encodeComponent(title)}'
      '&subject=${Uri.encodeComponent(subject)}'
      '${setup.soundType != null ? "&sound=${setup.soundType}" : ""}',
    );
  }
}
