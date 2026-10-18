import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class SpriteSheetAnimator extends StatefulWidget {
  final Uint8List imageBytes;
  final int frameCount;
  final Duration frameDuration;
  final double width;
  final double height;
  final double cropLeft;
  final double cropRight;

  const SpriteSheetAnimator({
    super.key,
    required this.imageBytes,
    this.frameCount = 2,
    this.frameDuration = const Duration(milliseconds: 500),
    required this.width,
    required this.height,
    this.cropLeft = 0.0,
    this.cropRight = 0.0,
  });

  @override
  State<SpriteSheetAnimator> createState() => _SpriteSheetAnimatorState();
}

class _SpriteSheetAnimatorState extends State<SpriteSheetAnimator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  ui.Image? _spriteSheet;
  int _currentFrame = 0;

  @override
  void initState() {
    super.initState();
    _loadSpriteSheet();

    _controller = AnimationController(
      vsync: this,
      duration: Duration(
          milliseconds:
              widget.frameDuration.inMilliseconds * widget.frameCount),
    )..addListener(() {
        final newFrame =
            (_controller.value * widget.frameCount).floor() % widget.frameCount;
        if (newFrame != _currentFrame) {
          setState(() {
            _currentFrame = newFrame;
          });
        }
      });

    _controller.repeat();
  }

  @override
  void didUpdateWidget(SpriteSheetAnimator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.imageBytes != oldWidget.imageBytes) {
      _loadSpriteSheet();
    }
  }

  Future<void> _loadSpriteSheet() async {
    final codec = await ui.instantiateImageCodec(widget.imageBytes);
    final frame = await codec.getNextFrame();
    if (mounted) {
      setState(() {
        _spriteSheet = frame.image;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_spriteSheet == null) {
      return SizedBox(
        width: widget.width,
        height: widget.height,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    return CustomPaint(
      size: Size(widget.width, widget.height),
      painter: SpritePainter(
        spriteSheet: _spriteSheet!,
        frameCount: widget.frameCount,
        currentFrame: _currentFrame,
        cropLeft: widget.cropLeft,
        cropRight: widget.cropRight,
      ),
    );
  }
}

class SpritePainter extends CustomPainter {
  final ui.Image spriteSheet;
  final int frameCount;
  final int currentFrame;
  final double cropLeft;
  final double cropRight;

  SpritePainter({
    required this.spriteSheet,
    required this.frameCount,
    required this.currentFrame,
    this.cropLeft = 0.0,
    this.cropRight = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..filterQuality = FilterQuality.none; // Important pour le pixel art

    final frameWidth = spriteSheet.width / frameCount;
    final frameHeight = spriteSheet.height.toDouble();

    final srcLeft = (currentFrame * frameWidth) + cropLeft;
    final srcWidth = (frameWidth - cropLeft - cropRight).clamp(1.0, frameWidth);

    // La portion de l'image source à dessiner (rognée à gauche et à droite)
    final srcRect = Rect.fromLTWH(
      srcLeft,
      0,
      srcWidth,
      frameHeight,
    );

    // La portion de destination sur le canvas
    final dstRect = Rect.fromLTWH(0, 0, size.width, size.height);

    canvas.drawImageRect(spriteSheet, srcRect, dstRect, paint);
  }

  @override
  bool shouldRepaint(covariant SpritePainter oldDelegate) {
    return oldDelegate.currentFrame != currentFrame ||
        oldDelegate.spriteSheet != spriteSheet ||
        oldDelegate.cropLeft != cropLeft ||
        oldDelegate.cropRight != cropRight;
  }
}
