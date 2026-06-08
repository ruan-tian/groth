import 'package:flutter/material.dart';

import '../utils/plan_module_assets.dart';

class PlanModuleVisualHeader extends StatefulWidget {
  const PlanModuleVisualHeader({
    super.key,
    required this.module,
    required this.color,
    this.height = 168,
  });

  final PlanModuleType module;
  final Color color;
  final double height;

  @override
  State<PlanModuleVisualHeader> createState() => _PlanModuleVisualHeaderState();
}

class _PlanModuleVisualHeaderState extends State<PlanModuleVisualHeader> {
  late final PageController _controller;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController(viewportFraction: 0.94);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final images = PlanModuleAssets.heroImages(widget.module);
    return Column(
      children: [
        SizedBox(
          height: widget.height,
          child: PageView.builder(
            controller: _controller,
            itemCount: images.length,
            onPageChanged: (index) => setState(() => _index = index),
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: _ImageShell(
                  image: images[index],
                  color: widget.color,
                  aspectRatio: 1200 / 520,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(images.length, (index) {
            final selected = index == _index;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: selected ? 18 : 6,
              height: 6,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                color: selected ? widget.color : widget.color.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(999),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class PlanModuleActionImageCard extends StatelessWidget {
  const PlanModuleActionImageCard({
    super.key,
    required this.module,
    required this.color,
    required this.onTap,
    this.height = 136,
  });

  final PlanModuleType module;
  final Color color;
  final VoidCallback onTap;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: SizedBox(
          height: height,
          child: _ImageShell(
            image: PlanModuleAssets.timerImage(module),
            color: color,
            aspectRatio: 1200 / 520,
          ),
        ),
      ),
    );
  }
}

class _ImageShell extends StatelessWidget {
  const _ImageShell({
    required this.image,
    required this.color,
    required this.aspectRatio,
  });

  final String image;
  final Color color;
  final double aspectRatio;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.12),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(23),
        child: Image.asset(
          image,
          width: double.infinity,
          height: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => Container(
            color: color.withValues(alpha: 0.1),
            child: Icon(Icons.image_not_supported_outlined, color: color),
          ),
        ),
      ),
    );
  }
}
