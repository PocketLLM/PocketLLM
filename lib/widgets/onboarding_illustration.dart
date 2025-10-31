import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class OnboardingIllustration extends StatefulWidget {
  const OnboardingIllustration({
    super.key,
    required this.asset,
    required this.reduceMotion,
    this.height,
  });

  final String asset;
  final bool reduceMotion;
  final double? height;

  @override
  State<OnboardingIllustration> createState() => _OnboardingIllustrationState();
}

class _OnboardingIllustrationState extends State<OnboardingIllustration> {
  ui.Image? _staticFrame;

  @override
  void initState() {
    super.initState();
    if (widget.reduceMotion && widget.asset.endsWith('.gif')) {
      _loadFirstFrame();
    }
  }

  @override
  void didUpdateWidget(covariant OnboardingIllustration oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.reduceMotion != oldWidget.reduceMotion ||
        widget.asset != oldWidget.asset) {
      _staticFrame?.dispose();
      _staticFrame = null;
      if (widget.reduceMotion && widget.asset.endsWith('.gif')) {
        _loadFirstFrame();
      }
    }
  }

  Future<void> _loadFirstFrame() async {
    final data = await rootBundle.load(widget.asset);
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    if (!mounted) return;
    setState(() {
      _staticFrame = frame.image;
    });
  }

  @override
  void dispose() {
    _staticFrame?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final height = widget.height;
    if (widget.reduceMotion && widget.asset.endsWith('.gif')) {
      if (_staticFrame == null) {
        return SizedBox(height: height, child: const Center(child: CircularProgressIndicator()));
      }
      return RawImage(
        image: _staticFrame,
        height: height,
        fit: BoxFit.contain,
      );
    }

    return Image.asset(
      widget.asset,
      height: height,
      fit: BoxFit.contain,
      gaplessPlayback: !widget.asset.endsWith('.gif'),
    );
  }
}
