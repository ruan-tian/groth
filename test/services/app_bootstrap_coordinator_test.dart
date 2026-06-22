import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:growth_os/core/database/app_database.dart';
import 'package:growth_os/core/repositories/knowledge_v3_repository.dart';
import 'package:growth_os/core/repositories/music_repository.dart';
import 'package:growth_os/core/services/app_bootstrap_coordinator.dart';
import 'package:growth_os/core/services/database_health_service.dart';
import 'package:growth_os/features/music/utils/default_music_seed.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  test('bootstraps a fresh database without schema errors', () async {
    final coordinator = AppBootstrapCoordinator(
      database: db,
      knowledgeV3Repository: KnowledgeV3Repository(db),
      musicRepository: MusicRepository(db),
      databaseHealthService: DatabaseHealthService(db),
    );

    final result = await coordinator.bootstrap();
    final second = await coordinator.bootstrap();

    expect(result.isHealthy, isTrue);
    expect(second, same(result));
    expect(result.databaseHealthReport.errors, isEmpty);

    final musicRepo = MusicRepository(db);
    final playlists = await musicRepo.getPlaylists();
    final tracks = await musicRepo.getTracks();
    expect(
      playlists.any(
        (playlist) => playlist.name == DefaultMusicSeeds.playlistName,
      ),
      isTrue,
    );
    expect(
      tracks.where(DefaultMusicSeeds.isSeedTrack),
      hasLength(DefaultMusicSeeds.seeds.length),
    );
  });
}
