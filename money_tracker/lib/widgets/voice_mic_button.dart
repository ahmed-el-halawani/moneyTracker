import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// Large animated microphone button for voice input
/// Features gradient background, glow shadow, and animated ripples when listening
class VoiceMicButton extends StatefulWidget {
  final bool isListening;
  final bool isProcessing;
  final double soundLevel;
  final VoidCallback onPressed;
  final VoidCallback? onLongPressStart;
  final VoidCallback? onLongPressEnd;
  final double size;

  const VoiceMicButton({
    super.key,
    required this.isListening,
    required this.isProcessing,
    required this.onPressed,
    this.onLongPressStart,
    this.onLongPressEnd,
    this.soundLevel = 0.0,
    this.size = 96,
  });

  @override
  State<VoiceMicButton> createState() => _VoiceMicButtonState();
}

class _VoiceMicButtonState extends State<VoiceMicButton>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _ripple1Controller;
  late AnimationController _ripple2Controller;
  late AnimationController _ripple3Controller;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _ripple1Controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    _ripple2Controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    Future.delayed(const Duration(milliseconds: 666), () {
      if (mounted) _ripple2Controller.repeat();
    });

    _ripple3Controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    Future.delayed(const Duration(milliseconds: 1333), () {
      if (mounted) _ripple3Controller.repeat();
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _ripple1Controller.dispose();
    _ripple2Controller.dispose();
    _ripple3Controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // Outer ripple rings (only visible when listening)
          if (widget.isListening) ...[
            // Ripple 1
            Positioned(
              left: -widget.size,
              right: -widget.size,
              top: -widget.size,
              bottom: -widget.size,
              child: Center(
                child: AnimatedBuilder(
                  animation: _ripple1Controller,
                  builder: (context, child) {
                    return Container(
                      width:
                          widget.size *
                          2.8 *
                          (0.5 + _ripple1Controller.value * 0.5),
                      height:
                          widget.size *
                          2.8 *
                          (0.5 + _ripple1Controller.value * 0.5),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: primaryColor.withOpacity(
                            0.1 * (1 - _ripple1Controller.value),
                          ),
                          width: 1,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            // Ripple 2
            Positioned(
              left: -widget.size,
              right: -widget.size,
              top: -widget.size,
              bottom: -widget.size,
              child: Center(
                child: AnimatedBuilder(
                  animation: _ripple2Controller,
                  builder: (context, child) {
                    return Container(
                      width:
                          widget.size *
                          2.8 *
                          (0.5 + _ripple2Controller.value * 0.5),
                      height:
                          widget.size *
                          2.8 *
                          (0.5 + _ripple2Controller.value * 0.5),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: primaryColor.withOpacity(
                            0.1 * (1 - _ripple2Controller.value),
                          ),
                          width: 1,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            // Ripple 3
            Positioned(
              left: -widget.size,
              right: -widget.size,
              top: -widget.size,
              bottom: -widget.size,
              child: Center(
                child: AnimatedBuilder(
                  animation: _ripple3Controller,
                  builder: (context, child) {
                    return Container(
                      width:
                          widget.size *
                          2.8 *
                          (0.5 + _ripple3Controller.value * 0.5),
                      height:
                          widget.size *
                          2.8 *
                          (0.5 + _ripple3Controller.value * 0.5),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: primaryColor.withOpacity(
                            0.1 * (1 - _ripple3Controller.value),
                          ),
                          width: 1,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],

          // Static concentric circles
          if (widget.isListening) ...[
            Positioned(
              left: -widget.size,
              right: -widget.size,
              top: -widget.size,
              bottom: -widget.size,
              child: Center(
                child: Container(
                  width: widget.size * 2.2,
                  height: widget.size * 2.2,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: primaryColor.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: -widget.size,
              right: -widget.size,
              top: -widget.size,
              bottom: -widget.size,
              child: Center(
                child: AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return Container(
                      width: widget.size * 1.6,
                      height: widget.size * 1.6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: primaryColor.withOpacity(
                          0.05 + 0.05 * _pulseController.value,
                        ),
                        border: Border.all(
                          color: primaryColor.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],

          // Main button
          GestureDetector(
            onTap: widget.onPressed,
            onLongPressStart: (_) => widget.onLongPressStart?.call(),
            onLongPressEnd: (_) => widget.onLongPressEnd?.call(),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [const Color(0xFF2B7FFF), primaryColor],
                ),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withOpacity(
                      widget.isListening ? 0.6 : 0.3,
                    ),
                    blurRadius: widget.isListening ? 40 : 20,
                    spreadRadius: widget.isListening ? 5 : 0,
                  ),
                ],
              ),
              child: Center(
                child: widget.isProcessing
                    ? SizedBox(
                        width: widget.size * 0.35,
                        height: widget.size * 0.35,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                      )
                    : Icon(
                        widget.isListening
                            ? LucideIcons.micOff
                            : LucideIcons.mic,
                        size: widget.size * 0.4,
                        color: Colors.white,
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
