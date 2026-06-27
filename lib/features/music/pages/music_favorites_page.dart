import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/design/design.dart';
import '../models/music_data.dart';
import '../models/music_player_state.dart';
import '../providers/music_player_provider.dart';
import '../utils/music_assets.dart';
import '../utils/music_colors.dart';

class MusicFavoritesPage extends ConsumerWidget {
  const MusicFavoritesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(musicPlayerProvider);
    final controller = ref.read(musicPlayerProvider.notifier);
    final favoriteTracks = state.favoriteTracks;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFFCF6), Color(0xFFF8F4EE)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ── Navigation Bar ──
              _buildNavBar(context),
              // ── Content ──
              Expanded(
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Statistics Card ──
                      _buildStatisticsCard(favoriteTracks.length),
                      // ── Favorite Songs ──
                      _buildFavoriteSongsSection(
                        favoriteTracks,
                        state,
                        controller,
                      ),
                      // ── Favorite Playlists ──
                      _buildFavoritePlaylistsSection(),
                    ],
                  ),
                ),
              ),
              // ── Mini Player ──
              if (state.hasTracks) _buildMiniPlayer(context, state, controller),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_rounded, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          const Expanded(
            child: Text(
              '我的收藏',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: MusicColors.ink,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.search_rounded, size: 22),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.menu_rounded, size: 22),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsCard(int favoriteCount) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: MusicColors.pinkGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: MusicColors.pink.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // ── Decorations ──
          Positioned(
            right: 10,
            top: 10,
            child: Opacity(
              opacity: 0.6,
              child: Image.asset(MusicAssets.decoHeartMusic, width: 50),
            ),
          ),
          Positioned(
            right: 60,
            bottom: 10,
            child: Opacity(
              opacity: 0.5,
              child: Image.asset(MusicAssets.decoStarMusic, width: 40),
            ),
          ),
          // ── Content ──
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Image.asset(MusicAssets.decoHeartMusic, width: 24),
                  const SizedBox(width: 8),
                  const Text(
                    '你的音乐偏好，我们为你珍藏',
                    style: TextStyle(
                      color: MusicColors.ink,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _StatItem(label: '已收藏', value: '$favoriteCount', unit: '首'),
                  const SizedBox(width: 32),
                  _StatItem(label: '最近添加', value: '$favoriteCount', unit: '首'),
                ],
              ),
            ],
          ),
          // ── Cat Illustration ──
          Positioned(
            right: 0,
            bottom: 0,
            child: Image.asset(MusicAssets.catFavorite, width: 90),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoriteSongsSection(
    List<MusicTrack> tracks,
    MusicPlayerState state,
    MusicPlayerController controller,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 3,
                height: 14,
                decoration: BoxDecoration(
                  color: MusicColors.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                '收藏歌曲',
                style: TextStyle(
                  color: MusicColors.ink,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                '全部 ${tracks.length} 首 >',
                style: const TextStyle(
                  color: MusicColors.muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (tracks.isEmpty)
            _buildEmptyState('还没有收藏歌曲', MusicAssets.emptyFavorite)
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: tracks.length.clamp(0, 5),
              itemBuilder: (context, index) {
                final track = tracks[index];
                final isSelected = track.id == state.currentTrackId;
                return _FavoriteSongTile(
                  track: track,
                  isSelected: isSelected,
                  isPlaying: isSelected && state.isPlaying,
                  onTap: () => controller.playTrack(track),
                  onFavorite: () => controller.toggleFavorite(track),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildFavoritePlaylistsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 3,
                height: 14,
                decoration: BoxDecoration(
                  color: MusicColors.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                '收藏歌单',
                style: TextStyle(
                  color: MusicColors.ink,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              const Text(
                '全部 3 个 >',
                style: TextStyle(
                  color: MusicColors.muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 140,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _PlaylistCard(
                  title: '晚安助眠',
                  subtitle: '治愈夜晚，好梦相伴',
                  cover: MusicAssets.playlistCoverSleep,
                  trackCount: 24,
                ),
                const SizedBox(width: 12),
                _PlaylistCard(
                  title: '专注学习',
                  subtitle: '沉浸专注，效率加倍',
                  cover: MusicAssets.playlistCoverStudy,
                  trackCount: 32,
                ),
                const SizedBox(width: 12),
                _PlaylistCard(
                  title: '轻松发呆',
                  subtitle: '放空心情，慢享时光',
                  cover: MusicAssets.playlistCoverRelax,
                  trackCount: 18,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message, String asset) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          children: [
            Image.asset(asset, width: 120),
            const SizedBox(height: 12),
            Text(
              message,
              style: const TextStyle(
                color: MusicColors.muted,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniPlayer(
    BuildContext context,
    MusicPlayerState state,
    MusicPlayerController controller,
  ) {
    final track = state.currentTrack;
    if (track == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: context.growthColors.card,
        boxShadow: [
          BoxShadow(
            color: MusicColors.shadowLight,
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              MusicAssets.coverForTitle(track.title),
              width: 44,
              height: 44,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  track.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: MusicColors.ink,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  track.artist ?? '未知艺术家',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: MusicColors.muted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Image.asset(MusicAssets.wavePlaying, width: 24),
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(
              state.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
              size: 28,
            ),
            onPressed: controller.togglePlayPause,
          ),
          IconButton(
            icon: const Icon(Icons.skip_next_rounded, size: 24),
            onPressed: controller.playNext,
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.label,
    required this.value,
    required this.unit,
  });

  final String label;
  final String value;
  final String unit;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: MusicColors.muted,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: const TextStyle(
                color: MusicColors.ink,
                fontSize: 28,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              unit,
              style: const TextStyle(
                color: MusicColors.muted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _FavoriteSongTile extends StatelessWidget {
  const _FavoriteSongTile({
    required this.track,
    required this.isSelected,
    required this.isPlaying,
    required this.onTap,
    required this.onFavorite,
  });

  final MusicTrack track;
  final bool isSelected;
  final bool isPlaying;
  final VoidCallback onTap;
  final VoidCallback onFavorite;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? MusicColors.primary.withValues(alpha: 0.08)
              : context.growthColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? MusicColors.primary.withValues(alpha: 0.2)
                : MusicColors.borderLight,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: context.growthColors.card,
                borderRadius: BorderRadius.circular(10),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  MusicAssets.coverForTitle(track.title),
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    track.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isSelected ? MusicColors.primary : MusicColors.ink,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    track.artist ?? '未知艺术家',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: MusicColors.muted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Image.asset(
                MusicAssets.decoHeartMusic,
                width: 20,
                color: MusicColors.favorite,
              ),
              onPressed: onFavorite,
            ),
            if (isSelected && isPlaying)
              Image.asset(MusicAssets.wavePlaying, width: 24)
            else
              Icon(
                Icons.play_arrow_rounded,
                color: MusicColors.muted,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }
}

class _PlaylistCard extends StatelessWidget {
  const _PlaylistCard({
    required this.title,
    required this.subtitle,
    required this.cover,
    required this.trackCount,
  });

  final String title;
  final String subtitle;
  final String cover;
  final int trackCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: context.growthColors.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: MusicColors.shadowLight,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.asset(
              cover,
              width: 100,
              height: 60,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: MusicColors.ink,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Icon(
                Icons.music_note_rounded,
                size: 12,
                color: MusicColors.muted,
              ),
              const SizedBox(width: 2),
              Text(
                '$trackCount首',
                style: const TextStyle(
                  color: MusicColors.muted,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
