// glowing_moving_circle.dart

import 'dart:math';
import 'package:flutter/material.dart';

class GlowingMovingCircle extends StatefulWidget {
  final double size;
  final Color color;
  final double speed;

  const GlowingMovingCircle({
    super.key,
    this.size = 80,
    this.color = Colors.blue,
    this.speed = 100,
  });

  @override
  State<GlowingMovingCircle> createState() => _GlowingMovingCircleState();
}

class _GlowingMovingCircleState extends State<GlowingMovingCircle> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late double x;
  late double y;
  late double dx;
  late double dy;
  late double screenWidth;
  late double screenHeight;
  bool isInitialized = false;

  final Random random = Random();

  @override
  void initState() {
    super.initState();

    double angle = random.nextDouble() * 2 * pi;
    dx = cos(angle);
    dy = sin(angle);

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(days: 9999),
    )..addListener(_updatePosition);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  void _initializePosition(BoxConstraints constraints) {
    screenWidth = constraints.maxWidth;
    screenHeight = constraints.maxHeight;

    // Start the circle slightly outside the screen area (a little extra space)
    x = (screenWidth - widget.size) / 2; // Adjust starting position to allow out-of-screen
    y = (screenHeight - widget.size) / 2; // Same for vertical axis
    isInitialized = true;
  }

  void _updatePosition() {
    if (!isInitialized) return;

    final elapsed = _controller.lastElapsedDuration;
    if (elapsed == null) return;

    final double dt = elapsed.inMilliseconds / 1000;
    _controller.reset();

    setState(() {
      x += dx * widget.speed * dt;
      y += dy * widget.speed * dt;

      // Allow the circle to go outside the visible area slightly
      if (x <= -widget.size || x >= screenWidth + widget.size) {
        dx *= -1;
        x = x.clamp(-widget.size, screenWidth + widget.size);
      }
      if (y <= -widget.size || y >= screenHeight + widget.size) {
        dy *= -1;
        y = y.clamp(-widget.size, screenHeight + widget.size);
      }
    });

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (!isInitialized) {
          _initializePosition(constraints);
        }

        return Stack(
          children: [
            Positioned(
              left: x,
              top: y,
              child: Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: widget.color.withAlpha(20),
                      blurRadius: 100,
                      spreadRadius: 100,
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
