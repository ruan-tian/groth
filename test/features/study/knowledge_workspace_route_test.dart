import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:growth_os/app/app.dart';
import 'package:growth_os/app/router.dart';
import 'package:growth_os/core/database/app_database.dart';
import 'package:growth_os/features/pet/repositories/exp_repository.dart';
import 'package:growth_os/features/pet/repositories/pet_repository.dart';
import 'package:growth_os/features/health/services/health_reminder_scheduler.dart';
import 'package:growth_os/features/pet/services/pet_orchestrator.dart';
import 'package:growth_os/features/study/pages/knowledge_workspace_page.dart';
import 'package:growth_os/shared/providers/database_provider.dart';
import 'package:growth_os/features/pet/providers/pet_orchestrator_provider.dart';
import 'package:growth_os/shared/widgets/common/advanced_bottom_nav.dart';

class _NoopPetOrchestrator extends PetOrchestrator {
  _NoopPetOrchestrator(AppDatabase db)
    : super(expRepository: ExpRepository(db), petRepository: PetRepository(db));

  @override
  void init() {}

  @override
  void setModuleAmbient(
    String module,
    String imagePath,
    List<String> messages,
  ) {}
}

void main() {
  testWidgets('knowledge space opens above the main bottom navigation', (
    tester,
  ) async {
    goRouter.go('/plan');
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          healthReminderBootstrapProvider.overrideWith((_) async {}),
          petOrchestratorProvider.overrideWith((_) => _NoopPetOrchestrator(db)),
        ],
        child: const GrowthOSApp(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(AdvancedBottomNav), findsOneWidget);

    goRouter.go('/plan/study/knowledge');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(KnowledgeSpaceSelectPage), findsOneWidget);
    expect(find.byType(AdvancedBottomNav), findsNothing);
  });

  testWidgets('legacy knowledge routes stay in the new root experience', (
    tester,
  ) async {
    goRouter.go('/plan');
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          healthReminderBootstrapProvider.overrideWith((_) async {}),
          petOrchestratorProvider.overrideWith((_) => _NoopPetOrchestrator(db)),
        ],
        child: const GrowthOSApp(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    final workspaceRoutes = [
      '/plan/study/knowledge/add',
      '/plan/study/knowledge/import',
      '/plan/study/knowledge/sources',
      '/plan/study/knowledge/sources/1',
      '/plan/study/knowledge/archive',
      '/plan/study/knowledge/export',
      '/plan/study/knowledge/templates',
      '/plan/study/knowledge/goal',
      '/plan/study/knowledge/edit/1',
      '/plan/study/knowledge/onboarding',
    ];

    for (final route in workspaceRoutes) {
      goRouter.go(route);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(KnowledgeWorkspacePage), findsOneWidget);
      expect(find.byType(AdvancedBottomNav), findsNothing);
      expect(find.text('AI 瀵煎叆'), findsNothing);
      expect(find.text('鍏ㄩ儴澶嶄範'), findsNothing);
      expect(find.text('鐩爣妯℃澘'), findsNothing);
    }

    goRouter.go('/plan/study/flash-review');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(KnowledgeSpaceSelectPage), findsOneWidget);
    expect(find.byType(AdvancedBottomNav), findsNothing);

    goRouter.go('/plan/study/knowledge/review?spaceId=1');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(KnowledgeFlashReviewPage), findsOneWidget);
    expect(find.byType(AdvancedBottomNav), findsNothing);
    expect(find.textContaining('娓叉煋澶辫触'), findsNothing);
  });
}

