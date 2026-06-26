import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/sleep_provider.dart';
import 'add_sleep_record_sheet.dart';

/// 睡眠记录入口页
///
/// 睡眠记录只保留底部弹窗表单；路由进入时立即打开同一套弹窗，关闭后返回。
class AddSleepRecordPage extends ConsumerStatefulWidget {
  const AddSleepRecordPage({super.key});

  @override
  ConsumerState<AddSleepRecordPage> createState() => _AddSleepRecordPageState();
}

class _AddSleepRecordPageState extends ConsumerState<AddSleepRecordPage> {
  bool _opened = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_opened) return;
    _opened = true;
    WidgetsBinding.instance.addPostFrameCallback((_) => _openSheet());
  }

  Future<void> _openSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddSleepRecordSheet(
        onSave: () {
          ref.invalidate(lastNightSleepRecordProvider);
          ref.invalidate(recentSleepRecordsProvider(5));
          ref.invalidate(recentSleepRecordsProvider(10));
          ref.invalidate(weeklySleepDurationProvider);
          ref.invalidate(weeklySleepQualityProvider);
          ref.invalidate(monthlySleepDurationProvider);
          ref.invalidate(monthlySleepQualityProvider);
          ref.invalidate(yearlySleepDurationProvider);
          ref.invalidate(yearlySleepQualityProvider);
        },
      ),
    );
    if (mounted && context.canPop()) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F6FF),
      body: const Center(
        child: CircularProgressIndicator(color: Color(0xFF7A6FF0)),
      ),
    );
  }
}
