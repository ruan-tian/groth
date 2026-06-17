import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/design/design.dart';
import '../../../shared/providers/dashboard_provider.dart';
import '../../../features/fitness/utils/fitness_timer_assets.dart';
import '../../../shared/widgets/common/error_retry_widget.dart';

/// 头像 + 昵称 + 等级徽章组合组件
class ProfileAvatarSection extends StatelessWidget {
  final String? avatarPath;
  final String nickname;
  final AsyncValue<DashboardData> dashboard;
  final VoidCallback onAvatarTap;
  final VoidCallback onNicknameTap;

  const ProfileAvatarSection({
    super.key,
    required this.avatarPath,
    required this.nickname,
    required this.dashboard,
    required this.onAvatarTap,
    required this.onNicknameTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── 头像（点击可更换）──
        Semantics(
          button: true,
          label: '更换头像',
          child: GestureDetector(
            onTap: onAvatarTap,
            child: AnimatedScale(
              scale: 1.0,
              duration: const Duration(milliseconds: 200),
              child: Stack(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: context.growthColors.card,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(
                            0xFF8B75F6,
                          ).withValues(alpha: 0.15),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: avatarPath != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(28),
                            child: Image.file(
                              File(avatarPath!),
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => ClipRRect(
                                borderRadius: BorderRadius.circular(28),
                                child: Image.asset(
                                  FitnessTimerAssets.catAvatarDefault,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          )
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(28),
                            child: Image.asset(
                              FitnessTimerAssets.catAvatarDefault,
                              fit: BoxFit.cover,
                            ),
                          ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: const Color(0xFF5C3D2E),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: context.growthColors.card,
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        Icons.camera_alt_rounded,
                        size: 16,
                        color: context.growthColors.textOnAccent,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // ── 昵称（点击可编辑）──
        Semantics(
          button: true,
          label: '编辑昵称',
          child: GestureDetector(
            onTap: onNicknameTap,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Row(
                key: ValueKey(nickname),
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    nickname,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF5C3D2E),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.edit_outlined,
                    size: 16,
                    color: Color(0xFFB0A09A),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),

        // ── 等级徽章 ──
        dashboard.when(
          data: (data) => AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Container(
              key: ValueKey(data.currentLevel),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF1DF),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Lv.${data.currentLevel} · ${_getLevelName(data.currentLevel)}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFFD4A574),
                ),
              ),
            ),
          ),
          loading: () => const SizedBox.shrink(),
          error: (_, _) => const ErrorRetryWidget(),
        ),
      ],
    );
  }

  static String _getLevelName(int level) {
    if (level < 5) return '成长新手';
    if (level < 10) return '习惯探索者';
    if (level < 20) return '成长实践家';
    if (level < 30) return '成长探索家';
    if (level < 50) return '长期主义者';
    return '成长大师';
  }
}
