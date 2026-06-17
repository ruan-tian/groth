import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../app/design/design.dart';
import '../models/inspiration_catalog.dart';

class InspirationBookmarkPage extends StatefulWidget {
  const InspirationBookmarkPage({super.key});

  @override
  State<InspirationBookmarkPage> createState() =>
      _InspirationBookmarkPageState();
}

class _InspirationBookmarkPageState extends State<InspirationBookmarkPage> {
  final _random = Random();
  int _selectedThemeIndex = 0;
  InspirationEntry? _current;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return FutureBuilder<InspirationCatalog>(
      future: InspirationCatalog.load(),
      builder: (context, snapshot) {
        final catalog = snapshot.data;
        if (catalog == null) {
          return Scaffold(
            backgroundColor: colors.background,
            body: snapshot.hasError
                ? _ErrorState(error: snapshot.error.toString())
                : Center(
                    child: CircularProgressIndicator(color: colors.journal),
                  ),
          );
        }

        final theme = catalog.themes[_selectedThemeIndex];
        final current = _current ??= InspirationCatalog.pickDailyEntry(
          theme.entries,
        );
        final palette = _paletteFor(context, _selectedThemeIndex);

        return Scaffold(
          backgroundColor: palette.background,
          body: AnimatedContainer(
            duration: const Duration(milliseconds: 360),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  palette.background,
                  palette.surface,
                  colors.background,
                ],
                stops: const [0, 0.58, 1],
              ),
            ),
            child: ListView(
              padding: EdgeInsets.zero,
              physics: const BouncingScrollPhysics(),
              children: [
                _ImmersiveBookmarkHeader(
                  theme: theme,
                  entry: current,
                  palette: palette,
                  onBack: () => Navigator.maybePop(context),
                  onShuffle: () => _shuffleEntry(theme),
                  onCopy: () => _copyEntry(current),
                  onWrite: () => _writeWithEntry(current),
                ),
                _ThemeRail(
                  themes: catalog.themes,
                  selectedIndex: _selectedThemeIndex,
                  palette: palette,
                  onSelected: (index) => _selectTheme(catalog.themes, index),
                ),
                const SizedBox(height: 18),
                _PosterWall(
                  themes: catalog.themes,
                  selectedIndex: _selectedThemeIndex,
                  palette: palette,
                  onSelected: (index) => _selectTheme(catalog.themes, index),
                ),
                const SizedBox(height: 28),
              ],
            ),
          ),
        );
      },
    );
  }

  void _selectTheme(List<InspirationTheme> themes, int index) {
    setState(() {
      _selectedThemeIndex = index;
      _current = InspirationCatalog.randomEntry(
        themes[index].entries,
        random: _random,
      );
    });
  }

  void _shuffleEntry(InspirationTheme theme) {
    setState(() {
      _current = InspirationCatalog.randomEntry(
        theme.entries,
        except: _current,
        random: _random,
      );
    });
  }

  Future<void> _copyEntry(InspirationEntry entry) async {
    final text = entry.source.isEmpty
        ? entry.text
        : '${entry.text} —— ${entry.source}';
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('已复制这张灵感书签'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _writeWithEntry(InspirationEntry entry) async {
    await _copyEntry(entry);
    if (!mounted) return;
    context.push('/plan/journal/write');
  }
}

class _ImmersiveBookmarkHeader extends StatelessWidget {
  const _ImmersiveBookmarkHeader({
    required this.theme,
    required this.entry,
    required this.palette,
    required this.onBack,
    required this.onShuffle,
    required this.onCopy,
    required this.onWrite,
  });

  final InspirationTheme theme;
  final InspirationEntry entry;
  final _InspirationPalette palette;
  final VoidCallback onBack;
  final VoidCallback onShuffle;
  final VoidCallback onCopy;
  final VoidCallback onWrite;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final posterHeight = width * 9 / 16;
        final bookmarkHeight = width < 380 ? 300.0 : 286.0;
        final overlap = 52.0;

        return SizedBox(
          height: posterHeight + bookmarkHeight - overlap + 20,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              _PosterBackdrop(
                theme: theme,
                height: posterHeight + 26,
                palette: palette,
              ),
              Positioned(
                left: 16,
                right: 16,
                top: MediaQuery.paddingOf(context).top + 8,
                child: _TopBar(onBack: onBack),
              ),
              Positioned(
                left: 20,
                right: 20,
                top: posterHeight - overlap,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  child: _BookmarkGlassCard(
                    key: ValueKey('${theme.name}_${entry.text}'),
                    theme: theme,
                    entry: entry,
                    palette: palette,
                    onShuffle: onShuffle,
                    onCopy: onCopy,
                    onWrite: onWrite,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PosterBackdrop extends StatelessWidget {
  const _PosterBackdrop({
    required this.theme,
    required this.height,
    required this.palette,
  });

  final InspirationTheme theme;
  final double height;
  final _InspirationPalette palette;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            theme.posterPath,
            fit: BoxFit.cover,
            cacheWidth: 1100,
            filterQuality: FilterQuality.medium,
            errorBuilder: (context, error, stackTrace) {
              return ColoredBox(color: palette.surface);
            },
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  palette.scrim.withValues(alpha: 0.08),
                  palette.scrim.withValues(alpha: 0.02),
                  palette.background.withValues(alpha: 0.96),
                ],
                stops: const [0, 0.56, 1],
              ),
            ),
          ),
          Positioned(
            left: 24,
            right: 24,
            bottom: 70,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _FrostedPill(
                  label: theme.kind == InspirationKind.poem ? '古诗词' : '名言短句',
                ),
                const SizedBox(height: 10),
                Text(
                  theme.name,
                  style: TextStyle(
                    color: palette.onImageText,
                    fontSize: 28,
                    height: 1.06,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  theme.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: palette.onImageText.withValues(alpha: 0.82),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return Row(
      children: [
        _GlassIconButton(icon: Icons.arrow_back_ios_new_rounded, onTap: onBack),
        const Spacer(),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              decoration: BoxDecoration(
                color: colors.textOnAccent.withValues(alpha: 0.24),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: colors.textOnAccent.withValues(alpha: 0.22),
                ),
              ),
              child: Text(
                '灵感书签',
                style: TextStyle(
                  color: colors.textOnAccent.withValues(alpha: 0.92),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _GlassIconButton extends StatelessWidget {
  const _GlassIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: InkWell(
          onTap: onTap,
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: colors.textOnAccent.withValues(alpha: 0.24),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: colors.textOnAccent.withValues(alpha: 0.22),
              ),
            ),
            child: Icon(icon, size: 18, color: colors.textOnAccent),
          ),
        ),
      ),
    );
  }
}

class _BookmarkGlassCard extends StatelessWidget {
  const _BookmarkGlassCard({
    super.key,
    required this.theme,
    required this.entry,
    required this.palette,
    required this.onShuffle,
    required this.onCopy,
    required this.onWrite,
  });

  final InspirationTheme theme;
  final InspirationEntry entry;
  final _InspirationPalette palette;
  final VoidCallback onShuffle;
  final VoidCallback onCopy;
  final VoidCallback onWrite;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
          decoration: BoxDecoration(
            color: colors.card.withValues(alpha: 0.70),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: colors.border.withValues(alpha: 0.64)),
            boxShadow: [
              BoxShadow(
                color: palette.ink.withValues(alpha: 0.10),
                blurRadius: 26,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 28,
                    height: 4,
                    decoration: BoxDecoration(
                      color: palette.accent.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    theme.name,
                    style: TextStyle(
                      color: palette.ink.withValues(alpha: 0.50),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                entry.text,
                style: TextStyle(
                  color: palette.ink,
                  fontSize: 18,
                  height: 1.78,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0,
                ),
              ),
              if (entry.source.isNotEmpty) ...[
                Text(
                  '—— ${entry.source}',
                  style: TextStyle(
                    color: palette.ink.withValues(alpha: 0.55),
                    fontSize: 13,
                    height: 1.35,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0,
                  ),
                ),
              ],
              const SizedBox(height: 20),
              _QuietActions(
                palette: palette,
                onShuffle: onShuffle,
                onCopy: onCopy,
                onWrite: onWrite,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuietActions extends StatelessWidget {
  const _QuietActions({
    required this.palette,
    required this.onShuffle,
    required this.onCopy,
    required this.onWrite,
  });

  final _InspirationPalette palette;
  final VoidCallback onShuffle;
  final VoidCallback onCopy;
  final VoidCallback onWrite;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _QuietAction(
          icon: Icons.auto_awesome_rounded,
          label: '换一句',
          palette: palette,
          onTap: onShuffle,
        ),
        _QuietAction(
          icon: Icons.copy_rounded,
          label: '复制',
          palette: palette,
          onTap: onCopy,
        ),
        _QuietAction(
          icon: Icons.edit_note_rounded,
          label: '写日记',
          palette: palette,
          onTap: onWrite,
        ),
      ],
    );
  }
}

class _QuietAction extends StatelessWidget {
  const _QuietAction({
    required this.icon,
    required this.label,
    required this.palette,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final _InspirationPalette palette;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: palette.accent.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: palette.accent.withValues(alpha: 0.12)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: palette.accent),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: palette.ink.withValues(alpha: 0.72),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemeRail extends StatelessWidget {
  const _ThemeRail({
    required this.themes,
    required this.selectedIndex,
    required this.palette,
    required this.onSelected,
  });

  final List<InspirationTheme> themes;
  final int selectedIndex;
  final _InspirationPalette palette;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 0, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionLabel(label: '换个主题', palette: palette),
          const SizedBox(height: 10),
          SizedBox(
            height: 38,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(right: 20),
              itemCount: themes.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final theme = themes[index];
                final selected = selectedIndex == index;
                return InkWell(
                  borderRadius: BorderRadius.circular(999),
                  onTap: () => onSelected(index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 13,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: selected
                          ? palette.accent.withValues(alpha: 0.13)
                          : colors.card.withValues(alpha: 0.52),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: selected
                            ? palette.accent.withValues(alpha: 0.18)
                            : colors.border.withValues(alpha: 0.58),
                      ),
                    ),
                    child: Text(
                      theme.name,
                      style: TextStyle(
                        color: selected
                            ? palette.ink
                            : palette.ink.withValues(alpha: 0.54),
                        fontSize: 12,
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PosterWall extends StatelessWidget {
  const _PosterWall({
    required this.themes,
    required this.selectedIndex,
    required this.palette,
    required this.onSelected,
  });

  final List<InspirationTheme> themes;
  final int selectedIndex;
  final _InspirationPalette palette;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionLabel(label: '主题海报', palette: palette),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final count = constraints.maxWidth >= 680 ? 3 : 2;
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: themes.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: count,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 16 / 10.8,
                ),
                itemBuilder: (context, index) {
                  return _PosterTile(
                    theme: themes[index],
                    selected: selectedIndex == index,
                    palette: palette,
                    onTap: () => onSelected(index),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class _PosterTile extends StatelessWidget {
  const _PosterTile({
    required this.theme,
    required this.selected,
    required this.palette,
    required this.onTap,
  });

  final InspirationTheme theme;
  final bool selected;
  final _InspirationPalette palette;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.all(selected ? 2 : 0),
        decoration: BoxDecoration(
          color: selected ? palette.accent.withValues(alpha: 0.30) : null,
          borderRadius: BorderRadius.circular(18),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                theme.posterPath,
                fit: BoxFit.cover,
                cacheWidth: 420,
                filterQuality: FilterQuality.medium,
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      palette.scrim.withValues(alpha: 0.02),
                      palette.scrim.withValues(alpha: 0.35),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 10,
                right: 10,
                bottom: 9,
                child: Text(
                  theme.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: palette.onImageText,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
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

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label, required this.palette});

  final String label;
  final _InspirationPalette palette;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        color: palette.ink.withValues(alpha: 0.72),
        fontSize: 14,
        fontWeight: FontWeight.w800,
        letterSpacing: 0,
      ),
    );
  }
}

class _FrostedPill extends StatelessWidget {
  const _FrostedPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: colors.textOnAccent.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: colors.textOnAccent.withValues(alpha: 0.20),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: colors.textOnAccent.withValues(alpha: 0.92),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.error});

  final String error;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.menu_book_outlined, color: colors.journal, size: 42),
            Text(
              '灵感加载失败',
              style: AppTextStyles.sectionTitle.copyWith(
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: AppTextStyles.caption.copyWith(
                color: colors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _InspirationPalette {
  const _InspirationPalette({
    required this.background,
    required this.surface,
    required this.accent,
    required this.ink,
    required this.onImageText,
    required this.scrim,
  });

  final Color background;
  final Color surface;
  final Color accent;
  final Color ink;
  final Color onImageText;
  final Color scrim;
}

_InspirationPalette _paletteFor(BuildContext context, int index) {
  final colors = context.growthColors;
  final accents = [
    colors.journal,
    colors.sleep,
    colors.focus,
    colors.success,
    colors.fitness,
    colors.accent,
    colors.primary,
    colors.diet,
  ];
  final accent = accents[index % accents.length];

  return _InspirationPalette(
    background: Color.lerp(accent, colors.background, 0.86)!,
    surface: Color.lerp(accent, colors.paper, 0.91)!,
    accent: accent,
    ink: colors.textPrimary,
    onImageText: colors.textOnAccent,
    scrim: colors.shadow,
  );
}
