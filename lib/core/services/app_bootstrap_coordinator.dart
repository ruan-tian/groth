import 'dart:async';

import '../database/app_database.dart';
import '../../features/knowledge/repositories/knowledge_v3_repository.dart';
import '../../features/music/repositories/music_repository.dart';
import 'database_health_service.dart';

class AppBootstrapResult {
  const AppBootstrapResult({required this.databaseHealthReport});

  final DatabaseHealthReport databaseHealthReport;

  bool get isHealthy => databaseHealthReport.isHealthy;
}

class AppBootstrapCoordinator {
  AppBootstrapCoordinator({
    required AppDatabase database,
    required KnowledgeV3Repository knowledgeV3Repository,
    required MusicRepository musicRepository,
    required DatabaseHealthService databaseHealthService,
  }) : _database = database,
       _knowledgeV3Repository = knowledgeV3Repository,
       _musicRepository = musicRepository,
       _databaseHealthService = databaseHealthService;

  final AppDatabase _database;
  final KnowledgeV3Repository _knowledgeV3Repository;
  final MusicRepository _musicRepository;
  final DatabaseHealthService _databaseHealthService;

  Future<AppBootstrapResult>? _bootstrapFuture;

  Future<AppBootstrapResult> bootstrap() {
    final running = _bootstrapFuture;
    if (running != null) return running;

    final future = _runBootstrap();
    _bootstrapFuture = future;
    return future;
  }

  Future<AppBootstrapResult> _runBootstrap() async {
    await _knowledgeV3Repository.ensureDefaultSpace();
    await _musicRepository.ensureDefaultFocusNoisePlaylist();
    await _database.ensureIndexesReady();
    final report = await _databaseHealthService.inspect();
    return AppBootstrapResult(databaseHealthReport: report);
  }
}
