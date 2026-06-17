import 'dart:math';

import 'package:flutter/material.dart';

import '../../../app/design/design.dart';
import '../models/drink_recommendation.dart';

class DrinkRecommendationPage extends StatefulWidget {
  const DrinkRecommendationPage({super.key});

  @override
  State<DrinkRecommendationPage> createState() =>
      _DrinkRecommendationPageState();
}

class _DrinkRecommendationPageState extends State<DrinkRecommendationPage> {
  final _random = Random();
  final _scrollController = ScrollController();
  String _selectedCategory = '全部';
  late DrinkRecommendation _current;

  @override
  void initState() {
    super.initState();
    _current = DrinkCatalog.todayRecommendation();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final drinks = DrinkCatalog.byCategory(_selectedCategory);

    return Scaffold(
      backgroundColor: context.growthColors.paper,
      appBar: AppBar(
        title: const Text('今天想喝点什么', style: AppTextStyles.pageTitle),
        centerTitle: false,
        backgroundColor: context.growthColors.paper,
        foregroundColor: context.growthColors.textPrimary,
        elevation: 0,
      ),
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              context.growthColors.softGold.withValues(alpha: 0.3),
              context.growthColors.diet.withValues(alpha: 0.06),
              context.growthColors.paper,
            ],
          ),
        ),
        child: ListView(
          controller: _scrollController,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
          children: [
            _TodayDrinkHero(
              drink: _current,
              onShuffle: _shuffleDrink,
              onAccept: _acceptDrink,
            ),
            const SizedBox(height: 16),
            _CategoryRail(
              selectedCategory: _selectedCategory,
              onSelected: _selectCategory,
            ),
            const SizedBox(height: 16),
            _DrinkWall(
              drinks: drinks,
              selectedId: _current.id,
              onSelected: _selectDrink,
            ),
          ],
        ),
      ),
    );
  }

  void _selectCategory(String category) {
    final nextDrinks = DrinkCatalog.byCategory(category);
    setState(() {
      _selectedCategory = category;
      if (!nextDrinks.any((drink) => drink.id == _current.id)) {
        _current = nextDrinks.first;
      }
    });
  }

  void _selectDrink(DrinkRecommendation drink) {
    setState(() => _current = drink);
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  void _shuffleDrink() {
    final pool = DrinkCatalog.byCategory(_selectedCategory);
    if (pool.isEmpty) return;
    setState(() {
      if (pool.length == 1) {
        _current = pool.first;
      } else {
        DrinkRecommendation next;
        do {
          next = pool[_random.nextInt(pool.length)];
        } while (next.id == _current.id);
        _current = next;
      }
    });
  }

  void _acceptDrink() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('今天就喝 ${_current.brand} · ${_current.name}'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _TodayDrinkHero extends StatelessWidget {
  const _TodayDrinkHero({
    required this.drink,
    required this.onShuffle,
    required this.onAccept,
  });

  final DrinkRecommendation drink;
  final VoidCallback onShuffle;
  final VoidCallback onAccept;

  @override
  Widget build(BuildContext context) {
    final color = _categoryColor(drink.category);
    final colors = context.growthColors;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.92),
            colors.diet.withValues(alpha: 0.84),
            colors.softGold,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.24),
            blurRadius: 28,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            Positioned(
              right: -54,
              top: -40,
              child: _SoftCircle(size: 180, color: colors.textOnAccent),
            ),
            Positioned(
              left: -42,
              bottom: -56,
              child: _SoftCircle(size: 150, color: colors.textOnAccent),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: colors.textOnAccent.withValues(alpha: 0.22),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: colors.textOnAccent.withValues(alpha: 0.28),
                          ),
                        ),
                        child: Text(
                          '今日推荐',
                          style: TextStyle(
                            color: colors.textOnAccent,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.local_cafe_rounded,
                        color: colors.textOnAccent.withValues(alpha: 0.9),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isNarrow = constraints.maxWidth < 360;
                      final image = AspectRatio(
                        aspectRatio: 1,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 220),
                          child: _DrinkImage(
                            key: ValueKey(drink.id),
                            path: drink.imagePath,
                            borderRadius: 22,
                          ),
                        ),
                      );

                      if (isNarrow) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _DrinkCopy(drink: drink),
                            const SizedBox(height: 14),
                            image,
                          ],
                        );
                      }

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(flex: 6, child: _DrinkCopy(drink: drink)),
                          const SizedBox(width: 14),
                          Expanded(flex: 5, child: image),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: drink.tags
                        .map(
                          (tag) => _Pill(
                            label: tag,
                            background: colors.textOnAccent.withValues(
                              alpha: 0.18,
                            ),
                            foreground: colors.textOnAccent,
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: onShuffle,
                          icon: const Icon(Icons.casino_rounded, size: 18),
                          label: const Text('换一杯'),
                          style: FilledButton.styleFrom(
                            backgroundColor: colors.textOnAccent,
                            foregroundColor: color,
                            padding: const EdgeInsets.symmetric(vertical: 13),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: onAccept,
                          icon: const Icon(Icons.check_rounded, size: 18),
                          label: const Text('就喝这个'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: colors.textOnAccent,
                            side: BorderSide(
                              color: colors.textOnAccent.withValues(
                                alpha: 0.68,
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 13),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrinkCopy extends StatelessWidget {
  const _DrinkCopy({required this.drink});

  final DrinkRecommendation drink;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          drink.brand,
          style: TextStyle(
            color: colors.textOnAccent,
            fontSize: 28,
            height: 1.08,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          drink.name,
          style: TextStyle(
            color: colors.textOnAccent.withValues(alpha: 0.92),
            fontSize: 15,
            fontWeight: FontWeight.w800,
            height: 1.25,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          drink.description,
          style: TextStyle(
            color: colors.textOnAccent.withValues(alpha: 0.86),
            fontSize: 13,
            height: 1.45,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _CategoryRail extends StatelessWidget {
  const _CategoryRail({
    required this.selectedCategory,
    required this.onSelected,
  });

  final String selectedCategory;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final categories = ['全部', ...DrinkCatalog.categories];
    final colors = context.growthColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '按分类筛选',
          key: ValueKey('drink_category_title'),
          style: AppTextStyles.sectionTitle,
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: categories.map((category) {
              final selected = selectedCategory == category;
              final color = category == '全部'
                  ? colors.diet
                  : _categoryColor(category);
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(category),
                  selected: selected,
                  onSelected: (_) => onSelected(category),
                  selectedColor: color.withValues(alpha: 0.16),
                  backgroundColor: colors.card,
                  labelStyle: TextStyle(
                    color: selected ? color : colors.textSecondary,
                    fontWeight: FontWeight.w800,
                  ),
                  side: BorderSide(
                    color: selected
                        ? color.withValues(alpha: 0.36)
                        : colors.border,
                  ),
                  showCheckmark: false,
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _DrinkWall extends StatelessWidget {
  const _DrinkWall({
    required this.drinks,
    required this.selectedId,
    required this.onSelected,
  });

  final List<DrinkRecommendation> drinks;
  final String selectedId;
  final ValueChanged<DrinkRecommendation> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              '全部饮品墙',
              key: ValueKey('drink_wall_title'),
              style: AppTextStyles.sectionTitle,
            ),
            const SizedBox(width: 8),
            _Pill(
              label: '${drinks.length} 款',
              background: colors.diet.withValues(alpha: 0.12),
              foreground: colors.diet,
            ),
          ],
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final crossAxisCount = constraints.maxWidth >= 680 ? 4 : 2;
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: drinks.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.74,
              ),
              itemBuilder: (context, index) {
                final drink = drinks[index];
                return _DrinkTile(
                  drink: drink,
                  isSelected: drink.id == selectedId,
                  onTap: () => onSelected(drink),
                );
              },
            );
          },
        ),
      ],
    );
  }
}

class _DrinkTile extends StatelessWidget {
  const _DrinkTile({
    required this.drink,
    required this.isSelected,
    required this.onTap,
  });

  final DrinkRecommendation drink;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = _categoryColor(drink.category);
    final colors = context.growthColors;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: colors.card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isSelected ? color : colors.border,
              width: isSelected ? 1.4 : 0.8,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: isSelected ? 0.15 : 0.06),
                blurRadius: isSelected ? 18 : 12,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _DrinkImage(
                  path: drink.imagePath,
                  borderRadius: 14,
                  backgroundColor: color.withValues(alpha: 0.08),
                ),
              ),
              const SizedBox(height: 9),
              Text(
                drink.brand,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.cardTitle.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                drink.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.caption,
              ),
              const SizedBox(height: 7),
              _Pill(
                label: drink.category,
                background: color.withValues(alpha: 0.11),
                foreground: color,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DrinkImage extends StatelessWidget {
  const _DrinkImage({
    super.key,
    required this.path,
    required this.borderRadius,
    this.backgroundColor,
  });

  final String path;
  final double borderRadius;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: ColoredBox(
        color:
            backgroundColor ??
            context.growthColors.surfaceVariant.withValues(alpha: 0.18),
        child: Image.asset(
          path,
          width: double.infinity,
          height: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return const _MissingDrinkImage();
          },
        ),
      ),
    );
  }
}

class _MissingDrinkImage extends StatelessWidget {
  const _MissingDrinkImage();

  @override
  Widget build(BuildContext context) {
    final colors = context.growthColors;
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colors.softOrange,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.local_drink_outlined, color: colors.diet, size: 34),
          SizedBox(height: 6),
          Text('图片走丢了', style: AppTextStyles.caption),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foreground,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _SoftCircle extends StatelessWidget {
  const _SoftCircle({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.12),
      ),
    );
  }
}

Color _categoryColor(String category) {
  return switch (category) {
    '咖啡' => const Color(0xFF8A5B3E),
    '新茶饮' => const Color(0xFFFF7EAA),
    '即饮茶' => const Color(0xFF35A66B),
    '气泡' => const Color(0xFF5D68F2),
    '果汁' => const Color(0xFFFF8A3D),
    '乳饮' => const Color(0xFF8B75F6),
    '功能' => const Color(0xFFE5584F),
    '凉茶' => const Color(0xFF9A7038),
    _ => AppColors.diet,
  };
}
