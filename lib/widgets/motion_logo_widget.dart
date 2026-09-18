import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/utils/vibration_helper.dart';

/// A lively, medical-grade animated logo with:
/// - Clinical heartbeat "lub-dub" pulse rhythm
/// - Smooth vertical float / breathing motion
/// - Expanding concentric diagnostic sonar/ultrasound ripple rings
/// - Dynamic shimmer sweep across the badge shield
/// - Interactive spring bounce and haptics on tap
class MotionLogo extends StatefulWidget {
  final double size;
  final bool showRipples;
  final bool showShimmer;
  final bool showFloating;
  final bool showHeartbeat;
  final bool interactive;
  final String? badgeText;
  final VoidCallback? onTap;

  const MotionLogo({
    super.key,
    this.size = 68.0,
    this.showRipples = true,
    this.showShimmer = true,
    this.showFloating = true,
    this.showHeartbeat = true,
    this.interactive = true,
    this.badgeText,
    this.onTap,
  });

  @override
  State<MotionLogo> createState() => _MotionLogoState();
}

class _MotionLogoState extends State<MotionLogo> with TickerProviderStateMixin {
  late AnimationController _heartbeatController;
  late Animation<double> _heartbeatScale;

  late AnimationController _floatController;
  late Animation<double> _floatOffset;

  late AnimationController _rippleController;
  late Animation<double> _rippleRadius1;
  late Animation<double> _rippleOpacity1;
  late Animation<double> _rippleRadius2;
  late Animation<double> _rippleOpacity2;

  late AnimationController _shimmerController;
  late Animation<double> _shimmerProgress;

  late AnimationController _tapController;
  late Animation<double> _tapScale;

  @override
  void initState() {
    super.initState();

    // 1. Heartbeat "lub-dub" pulse rhythm: ~1.4s cycle
    _heartbeatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _heartbeatScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.07).chain(CurveTween(curve: Curves.easeOutCubic)), weight: 15),
      TweenSequenceItem(tween: Tween(begin: 1.07, end: 1.0).chain(CurveTween(curve: Curves.easeInCubic)), weight: 15),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.05).chain(CurveTween(curve: Curves.easeOutCubic)), weight: 15),
      TweenSequenceItem(tween: Tween(begin: 1.05, end: 1.0).chain(CurveTween(curve: Curves.easeInCubic)), weight: 15),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 40), // pause between heartbeats
    ]).animate(_heartbeatController);

    if (widget.showHeartbeat) {
      _heartbeatController.repeat();
    }

    // 2. Smooth vertical float / breathing
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );

    _floatOffset = Tween<double>(begin: -3.5, end: 3.5).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOutSine),
    );

    if (widget.showFloating) {
      _floatController.repeat(reverse: true);
    }

    // 3. Expanding concentric sonar / ultrasound ripple waves
    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    _rippleRadius1 = Tween<double>(begin: 0.9, end: 1.45).animate(
      CurvedAnimation(parent: _rippleController, curve: const Interval(0.0, 0.7, curve: Curves.easeOutQuad)),
    );
    _rippleOpacity1 = Tween<double>(begin: 0.35, end: 0.0).animate(
      CurvedAnimation(parent: _rippleController, curve: const Interval(0.0, 0.7, curve: Curves.easeOut)),
    );

    _rippleRadius2 = Tween<double>(begin: 0.9, end: 1.55).animate(
      CurvedAnimation(parent: _rippleController, curve: const Interval(0.3, 1.0, curve: Curves.easeOutQuad)),
    );
    _rippleOpacity2 = Tween<double>(begin: 0.30, end: 0.0).animate(
      CurvedAnimation(parent: _rippleController, curve: const Interval(0.3, 1.0, curve: Curves.easeOut)),
    );

    if (widget.showRipples) {
      _rippleController.repeat();
    }

    // 4. Shimmer sweep
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    );

    _shimmerProgress = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );

    if (widget.showShimmer) {
      _shimmerController.repeat();
    }

    // 5. Interactive spring bounce on tap
    _tapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 140),
    );

    _tapScale = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _tapController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _heartbeatController.dispose();
    _floatController.dispose();
    _rippleController.dispose();
    _shimmerController.dispose();
    _tapController.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (!widget.interactive) return;
    VibrationHelper.lightFeedback();
    _tapController.forward().then((_) => _tapController.reverse());
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    final logoSize = widget.size;
    final containerSize = logoSize + 16.0;

    return GestureDetector(
      onTap: _handleTap,
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _heartbeatController,
          _floatController,
          _rippleController,
          _shimmerController,
          _tapController,
        ]),
        builder: (context, child) {
          final heartbeatVal = widget.showHeartbeat ? _heartbeatScale.value : 1.0;
          final floatVal = widget.showFloating ? _floatOffset.value : 0.0;
          final tapVal = _tapScale.value;
          final currentScale = heartbeatVal * tapVal;

          return SizedBox(
            width: containerSize * 1.5,
            height: containerSize * 1.5,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                // 1. Concentric Ripple Ring 1 (Ultrasound wave)
                if (widget.showRipples)
                  Opacity(
                    opacity: _rippleOpacity1.value,
                    child: Container(
                      width: containerSize * _rippleRadius1.value,
                      height: containerSize * _rippleRadius1.value,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFE11D48).withOpacity(0.4),
                          width: 2.0,
                        ),
                      ),
                    ),
                  ),

                // 2. Concentric Ripple Ring 2 (Secondary wave)
                if (widget.showRipples)
                  Opacity(
                    opacity: _rippleOpacity2.value,
                    child: Container(
                      width: containerSize * _rippleRadius2.value,
                      height: containerSize * _rippleRadius2.value,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF0E8388).withOpacity(0.35),
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),

                // 3. Floating and Pulsing Logo Badge
                Transform.translate(
                  offset: Offset(0, floatVal),
                  child: Transform.scale(
                    scale: currentScale,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // Outer Glowing Container
                        Container(
                          width: containerSize,
                          height: containerSize,
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(containerSize * 0.28),
                            border: Border.all(
                              color: const Color(0xFFFECDD3),
                              width: 1.8,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFE11D48).withOpacity(0.18),
                                blurRadius: 16,
                                spreadRadius: 2,
                                offset: const Offset(0, 4),
                              ),
                              BoxShadow(
                                color: const Color(0xFF0E8388).withOpacity(0.12),
                                blurRadius: 24,
                                spreadRadius: -2,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Stack(
                            children: [
                              // Actual Logo Asset
                              Center(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(containerSize * 0.22),
                                  child: Image.asset(
                                    'assets/images/precisioncare_logo.jpeg',
                                    width: logoSize,
                                    height: logoSize,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),

                              // Shimmer Light Sweep Overlay
                              if (widget.showShimmer)
                                Positioned.fill(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(containerSize * 0.22),
                                    child: Transform.rotate(
                                      angle: math.pi / 4,
                                      child: Transform.translate(
                                        offset: Offset(_shimmerProgress.value * containerSize, 0),
                                        child: Container(
                                          width: 18,
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                Colors.white.withOpacity(0.0),
                                                Colors.white.withOpacity(0.45),
                                                Colors.white.withOpacity(0.0),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),

                        // Optional Badge (e.g. NABL / Verified / Pulse Dot)
                        if (widget.badgeText != null && widget.badgeText!.isNotEmpty)
                          Positioned(
                            bottom: -4,
                            right: -4,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFFE11D48), Color(0xFFBE123C)],
                                ),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.white, width: 1.5),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFE11D48).withOpacity(0.35),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Text(
                                widget.badgeText!,
                                style: const TextStyle(
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ),
                          )
                        else
                          // Clinical green pulse dot indicator
                          Positioned(
                            top: 2,
                            right: 2,
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF10B981).withOpacity(0.5),
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
