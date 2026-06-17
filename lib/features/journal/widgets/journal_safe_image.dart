import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

import '../../../app/design/design.dart';
import 'journal_colors.dart';

class JournalSafeImage extends StatefulWidget {
  const JournalSafeImage({
    super.key,
    required this.path,
    this.maxHeight = 320,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.borderRadius = 16,
    this.cacheWidth = 1200,
    this.enablePreview = true,
  });

  final String path;
  final double maxHeight;
  final double? width;
  final double? height;
  final BoxFit fit;
  final double borderRadius;
  final int cacheWidth;
  final bool enablePreview;

  @override
  State<JournalSafeImage> createState() => _JournalSafeImageState();
}

class _JournalSafeImageState extends State<JournalSafeImage> {
  late Future<bool> _existsFuture;

  @override
  void initState() {
    super.initState();
    _existsFuture = _exists();
  }

  @override
  void didUpdateWidget(covariant JournalSafeImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.path != widget.path) {
      _existsFuture = _exists();
    }
  }

  Future<bool> _exists() async {
    if (widget.path.startsWith('http')) return true;
    return File(widget.path).exists();
  }

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(widget.borderRadius);
    return FutureBuilder<bool>(
      future: _existsFuture,
      builder: (context, snapshot) {
        final exists = snapshot.data == true;
        if (!exists) {
          return _placeholder(radius);
        }

        Widget image;
        if (widget.path.startsWith('http')) {
          image = Image.network(
            widget.path,
            width: widget.width,
            height: widget.height,
            fit: widget.fit,
            filterQuality: FilterQuality.medium,
            errorBuilder: (_, _, _) => _placeholder(radius),
          );
        } else {
          image = Image.file(
            File(widget.path),
            width: widget.width,
            height: widget.height,
            fit: widget.fit,
            cacheWidth: widget.cacheWidth,
            filterQuality: FilterQuality.medium,
            errorBuilder: (_, _, _) => _placeholder(radius),
          );
        }

        final framed = ClipRRect(
          borderRadius: radius,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: widget.maxHeight),
            child: image,
          ),
        );

        if (!widget.enablePreview) return framed;
        return GestureDetector(
          onTap: () => _showPreview(context),
          child: framed,
        );
      },
    );
  }

  Widget _placeholder(BorderRadius radius) {
    return ClipRRect(
      borderRadius: radius,
      child: Container(
        width: widget.width ?? double.infinity,
        height: widget.height ?? 140,
        decoration: BoxDecoration(
          color: JournalColors.pinkBg.withValues(alpha: 0.7),
          border: Border.all(color: JournalColors.pinkBorder),
          borderRadius: radius,
        ),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.broken_image_outlined,
                size: 30,
                color: JournalColors.textMuted,
              ),
              SizedBox(height: 6),
              Text(
                '图片无法加载',
                style: TextStyle(fontSize: 12, color: JournalColors.textMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPreview(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: context.growthColors.shadow.withValues(alpha: 0.86),
          insetPadding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            height: MediaQuery.sizeOf(context).height * 0.72,
            child: Stack(
              children: [
                Positioned.fill(
                  child: InteractiveViewer(
                    minScale: 0.8,
                    maxScale: 4,
                    child: Center(
                      child: widget.path.startsWith('http')
                          ? Image.network(widget.path, fit: BoxFit.contain)
                          : Image.file(File(widget.path), fit: BoxFit.contain),
                    ),
                  ),
                ),
                Positioned(
                  right: 8,
                  top: 8,
                  child: IconButton.filled(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class JournalQuillImageEmbedBuilder extends EmbedBuilder {
  const JournalQuillImageEmbedBuilder();

  @override
  String get key => BlockEmbed.imageType;

  @override
  bool get expanded => false;

  @override
  Widget build(BuildContext context, EmbedContext embedContext) {
    final raw = embedContext.node.value.data;
    final path = raw is String ? raw : raw.toString();
    if (path.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: JournalSafeImage(
        path: path,
        maxHeight: 320,
        borderRadius: 18,
        cacheWidth: 1200,
      ),
    );
  }
}
