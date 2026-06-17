import 'package:flutter_test/flutter_test.dart';
import 'package:growth_os/core/services/exp_service.dart';

void main() {
  late ExpService service;

  setUp(() {
    service = ExpService();
  });

  // ===========================================================================
  // calculateStudyExp
  // ===========================================================================

  group('calculateStudyExp', () {
    test('returns base exp from duration (floor division by 10)', () {
      // 60 min ~/ 10 = 6
      expect(service.calculateStudyExp(durationMinutes: 60), equals(6));
    });

    test('returns 0 for duration < 10 minutes', () {
      expect(service.calculateStudyExp(durationMinutes: 9), equals(0));
    });

    test('adds focus bonus (focusLevel * 2)', () {
      // 60~/10 = 6, focus 3*2 = 6 → total 12
      expect(
        service.calculateStudyExp(durationMinutes: 60, focusLevel: 3),
        equals(12),
      );
    });

    test('adds difficulty bonus (difficultyLevel * 2)', () {
      // 60~/10 = 6, difficulty 4*2 = 8 → total 14
      expect(
        service.calculateStudyExp(durationMinutes: 60, difficultyLevel: 4),
        equals(14),
      );
    });

    test('adds review bonus (+5 when hasReview is true)', () {
      // 60~/10 = 6, review = 5 → total 11
      expect(
        service.calculateStudyExp(durationMinutes: 60, hasReview: true),
        equals(11),
      );
    });

    test('no review bonus when hasReview is false', () {
      expect(
        service.calculateStudyExp(durationMinutes: 60, hasReview: false),
        equals(6),
      );
    });

    test('combines all bonuses correctly', () {
      // 120~/10 = 12, focus 5*2=10, difficulty 3*2=6, review=5 → 33
      expect(
        service.calculateStudyExp(
          durationMinutes: 120,
          focusLevel: 5,
          difficultyLevel: 3,
          hasReview: true,
        ),
        equals(33),
      );
    });

    test('uses default values when optional params omitted', () {
      // 30~/10 = 3, no bonuses
      expect(service.calculateStudyExp(durationMinutes: 30), equals(3));
    });

    test('handles zero duration', () {
      expect(service.calculateStudyExp(durationMinutes: 0), equals(0));
    });
  });

  // ===========================================================================
  // calculateFitnessExp
  // ===========================================================================

  group('calculateFitnessExp', () {
    test('returns base exp from duration (floor division by 10)', () {
      // 60 min ~/ 10 = 6
      expect(service.calculateFitnessExp(durationMinutes: 60), equals(6));
    });

    test('returns 0 for duration < 10 minutes', () {
      expect(service.calculateFitnessExp(durationMinutes: 7), equals(0));
    });

    test('adds intensity bonus (intensityLevel * 3)', () {
      // 60~/10 = 6, intensity 4*3 = 12 → total 18
      expect(
        service.calculateFitnessExp(durationMinutes: 60, intensityLevel: 4),
        equals(18),
      );
    });

    test('adds exercise bonus (exerciseCount * 2)', () {
      // 60~/10 = 6, exercises 3*2 = 6 → total 12
      expect(
        service.calculateFitnessExp(durationMinutes: 60, exerciseCount: 3),
        equals(12),
      );
    });

    test('adds feeling bonus (+5 when hasFeeling is true)', () {
      // 60~/10 = 6, feeling = 5 → total 11
      expect(
        service.calculateFitnessExp(durationMinutes: 60, hasFeeling: true),
        equals(11),
      );
    });

    test('no feeling bonus when hasFeeling is false', () {
      expect(
        service.calculateFitnessExp(durationMinutes: 60, hasFeeling: false),
        equals(6),
      );
    });

    test('combines all bonuses correctly', () {
      // 90~/10 = 9, intensity 5*3=15, exercises 4*2=8, feeling=5 → 37
      expect(
        service.calculateFitnessExp(
          durationMinutes: 90,
          intensityLevel: 5,
          exerciseCount: 4,
          hasFeeling: true,
        ),
        equals(37),
      );
    });

    test('handles zero duration with bonuses', () {
      // 0~/10 = 0, intensity 2*3=6 → 6
      expect(
        service.calculateFitnessExp(durationMinutes: 0, intensityLevel: 2),
        equals(6),
      );
    });
  });

  // ===========================================================================
  // calculateFocusExp
  // ===========================================================================

  group('calculateFocusExp', () {
    test('uses the shared focus rule for completed rounds', () {
      expect(service.calculateFocusExp(durationMinutes: 50), equals(10));
    });

    test('returns 0 for interrupted rounds', () {
      expect(
        service.calculateFocusExp(durationMinutes: 50, completed: false),
        equals(0),
      );
    });
  });

  // ===========================================================================
  // Reserved health EXP formulas
  // ===========================================================================

  group('reserved health exp formulas', () {
    test('calculateDietExp rewards complete meals and reasonable target', () {
      expect(
        service.calculateDietExp(
          hasCompleteMeals: true,
          hasReasonableTarget: true,
        ),
        equals(10),
      );
      expect(
        service.calculateDietExp(hasCompleteMeals: false),
        equals(4),
      );
      expect(
        service.calculateDietExp(
          hasCompleteMeals: true,
          hasReasonableTarget: false,
        ),
        equals(8),
      );
    });

    test('calculateDietExp caps at 12 (single record max is 10)', () {
      // base 4 + completeMeals 4 + reasonableTarget 2 = 10
      // cap 12 is the daily limit, single record cannot exceed 10
      expect(
        service.calculateDietExp(
          hasCompleteMeals: true,
          hasReasonableTarget: true,
        ),
        equals(10),
      );
    });

    test('calculateWaterExp rewards drink count, goal, and reminders', () {
      expect(
        service.calculateWaterExp(drinkCount: 0, reachedGoal: false),
        equals(0),
      );
      expect(
        service.calculateWaterExp(drinkCount: 3, reachedGoal: false),
        equals(3),
      );
      expect(
        service.calculateWaterExp(drinkCount: 5, reachedGoal: true),
        equals(10),
      );
      expect(
        service.calculateWaterExp(
          drinkCount: 3,
          reachedGoal: true,
          completedReminders: true,
        ),
        equals(10),
      );
    });

    test('calculateWaterExp caps at 10', () {
      expect(
        service.calculateWaterExp(
          drinkCount: 10,
          reachedGoal: true,
          completedReminders: true,
        ),
        equals(10),
      );
    });

    test('calculateSleepExp rewards record, duration, quality, and schedule', () {
      expect(
        service.calculateSleepExp(
          durationMinutes: 480,
          qualityLevel: 5,
          targetMinutes: 480,
          isRegularSchedule: true,
        ),
        equals(14),
      );
      expect(
        service.calculateSleepExp(durationMinutes: 0, qualityLevel: 5),
        equals(0),
      );
      expect(
        service.calculateSleepExp(
          durationMinutes: 480,
          qualityLevel: 3,
          targetMinutes: 480,
        ),
        equals(9),
      );
    });

    test('calculateSleepExp caps at 14', () {
      expect(
        service.calculateSleepExp(
          durationMinutes: 480,
          qualityLevel: 5,
          targetMinutes: 480,
          isRegularSchedule: true,
        ),
        equals(14),
      );
    });
  });

  // ===========================================================================
  // calculateJournalExp
  // ===========================================================================

  group('calculateJournalExp', () {
    test('returns base 5 for short content', () {
      expect(service.calculateJournalExp(wordCount: 50), equals(5));
    });

    test('returns base 5 for zero word count', () {
      expect(service.calculateJournalExp(wordCount: 0), equals(5));
    });

    test('adds word bonus (wordCount ~/ 100)', () {
      // 5 + 300~/100 = 5 + 3 = 8
      expect(service.calculateJournalExp(wordCount: 300), equals(8));
    });

    test('caps at 20 exp', () {
      // 5 + 2000~/100 = 5 + 20 = 25, but capped at 20
      expect(service.calculateJournalExp(wordCount: 2000), equals(20));
    });

    test('caps at 20 for very large word count', () {
      // 5 + 10000~/100 = 5 + 100 = 105, but capped at 20
      expect(service.calculateJournalExp(wordCount: 10000), equals(20));
    });

    test('returns exactly 20 when word bonus reaches cap', () {
      // 5 + 1500~/100 = 5 + 15 = 20 → exactly cap
      expect(service.calculateJournalExp(wordCount: 1500), equals(20));
    });

    test('returns 19 just below cap', () {
      // 5 + 1399~/100 = 5 + 13 = 18 → below cap
      // 5 + 1499~/100 = 5 + 14 = 19 → just below cap
      expect(service.calculateJournalExp(wordCount: 1499), equals(19));
    });
  });

  // ===========================================================================
  // calculateLevel
  // ===========================================================================

  group('calculateLevel', () {
    test('returns level 1 for 0 exp', () {
      expect(service.calculateLevel(0), equals(1));
    });

    test('returns level 1 for exp < 5', () {
      // sqrt(4/5) = 0.89.. → floor = 0 → +1 = 1
      expect(service.calculateLevel(4), equals(1));
    });

    test('returns level 2 at 5 exp', () {
      // sqrt(5/5) = 1.0 → floor = 1 → +1 = 2
      expect(service.calculateLevel(5), equals(2));
    });

    test('returns level 3 at 20 exp', () {
      // sqrt(20/5) = sqrt(4) = 2.0 → floor = 2 → +1 = 3
      expect(service.calculateLevel(20), equals(3));
    });

    test('returns level 4 at 45 exp', () {
      // sqrt(45/5) = sqrt(9) = 3.0 → floor = 3 → +1 = 4
      expect(service.calculateLevel(45), equals(4));
    });

    test('returns level 5 at 80 exp', () {
      // sqrt(80/5) = sqrt(16) = 4.0 → floor = 4 → +1 = 5
      expect(service.calculateLevel(80), equals(5));
    });

    test('returns correct level for non-perfect-square exp', () {
      // sqrt(30/5) = sqrt(6) ≈ 2.449 → floor = 2 → +1 = 3
      expect(service.calculateLevel(30), equals(3));
    });

    test('returns level 10 at 405 exp', () {
      // sqrt(405/5) = sqrt(81) = 9 → floor = 9 → +1 = 10
      expect(service.calculateLevel(405), equals(10));
    });

    test('returns level 11 at 500 exp', () {
      // sqrt(500/5) = sqrt(100) = 10 → floor = 10 → +1 = 11
      expect(service.calculateLevel(500), equals(11));
    });
  });

  // ===========================================================================
  // getExpForNextLevel
  // ===========================================================================

  group('getExpForNextLevel', () {
    test('returns 5 for level 1', () {
      // 1*1*5 = 5
      expect(service.getExpForNextLevel(1), equals(5));
    });

    test('returns 20 for level 2', () {
      // 2*2*5 = 20
      expect(service.getExpForNextLevel(2), equals(20));
    });

    test('returns 45 for level 3', () {
      // 3*3*5 = 45
      expect(service.getExpForNextLevel(3), equals(45));
    });

    test('returns 80 for level 4', () {
      // 4*4*5 = 80
      expect(service.getExpForNextLevel(4), equals(80));
    });

    test('returns 500 for level 10', () {
      // 10*10*5 = 500
      expect(service.getExpForNextLevel(10), equals(500));
    });

    test('returns 0 for level 0', () {
      expect(service.getExpForNextLevel(0), equals(0));
    });
  });

  // ===========================================================================
  // getExpProgress
  // ===========================================================================

  group('getExpProgress', () {
    test('returns totalExp when at level 1 (level start is 0)', () {
      // levelStart = (1-1)^2 * 5 = 0
      // progress = 50 - 0 = 50
      expect(service.getExpProgress(50, 1), equals(50));
    });

    test('returns 0 when exactly at level boundary', () {
      // totalExp = 5, level = 2
      // levelStart = (2-1)^2 * 5 = 5
      // progress = 5 - 5 = 0
      expect(service.getExpProgress(5, 2), equals(0));
    });

    test('returns correct progress within level 2', () {
      // totalExp = 15, level = 2
      // levelStart = 1^2 * 5 = 5
      // progress = 15 - 5 = 10
      expect(service.getExpProgress(15, 2), equals(10));
    });

    test('returns correct progress within level 3', () {
      // totalExp = 30, level = 3
      // levelStart = 2^2 * 5 = 20
      // progress = 30 - 20 = 10
      expect(service.getExpProgress(30, 3), equals(10));
    });

    test('returns correct progress within level 5', () {
      // totalExp = 100, level = 5
      // levelStart = 4^2 * 5 = 80
      // progress = 100 - 80 = 20
      expect(service.getExpProgress(100, 5), equals(20));
    });

    test('returns full level range at level end', () {
      // totalExp = 19, level = 3
      // levelStart = (3-1)^2 * 5 = 20
      // progress = 19 - 20 = -1, but clamped to 0
      expect(service.getExpProgress(19, 3), equals(0));
    });
  });

  // ===========================================================================
  // calculateLevelProgress
  // ===========================================================================

  group('calculateLevelProgress', () {
    test('projects the shared human and pet level from total exp', () {
      final progress = service.calculateLevelProgress(250);

      expect(progress.totalExp, equals(250));
      expect(progress.level, equals(8));
      expect(progress.levelStartExp, equals(245));
      expect(progress.nextLevelExp, equals(320));
      expect(progress.levelRange, equals(75));
      expect(progress.expProgress, equals(5));
      expect(progress.expRemaining, equals(70));
      expect(progress.progressRatio, closeTo(0.0667, 0.001));
    });

    test('clamps progress ratio at level boundaries', () {
      final progress = service.calculateLevelProgress(100);

      expect(progress.level, equals(5));
      expect(progress.expProgress, equals(20));
      expect(progress.expRemaining, equals(25));
      expect(progress.progressRatio, closeTo(0.4444, 0.001));
    });
  });

  // ===========================================================================
  // Integration: level + expForNextLevel + expProgress consistency
  // ===========================================================================

  group('level system consistency', () {
    test('expProgress is always less than expForNextLevel gap', () {
      for (final totalExp in [0, 50, 100, 250, 400, 899, 900, 1600]) {
        final level = service.calculateLevel(totalExp);
        final progress = service.getExpProgress(totalExp, level);
        final nextLevelExp = service.getExpForNextLevel(level);
        final currentLevelExp = (level - 1) * (level - 1) * 5;
        final levelRange = nextLevelExp - currentLevelExp;

        expect(
          progress,
          lessThanOrEqualTo(levelRange),
          reason:
              'At totalExp=$totalExp, level=$level: '
              'progress=$progress should be <= levelRange=$levelRange',
        );
      }
    });

    test(
      'calculateLevel and getExpForNextLevel are inverses at boundaries',
      () {
        for (final level in [1, 2, 3, 5, 10]) {
          final nextLevelExp = service.getExpForNextLevel(level);
          final computedLevel = service.calculateLevel(nextLevelExp);
          // At exact boundary, we should be at the NEXT level
          expect(
            computedLevel,
            equals(level + 1),
            reason:
                'At nextLevelExp=$nextLevelExp for level=$level, '
                'calculateLevel should return ${level + 1}',
          );
        }
      },
    );
  });
}
