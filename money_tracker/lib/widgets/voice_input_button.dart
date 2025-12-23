import 'dart:math';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../core/theme/app_colors.dart';

/// Animated voice input button with pulse effect
class VoiceInputButton extends StatefulWidget {
  final bool isListening;
  final bool isProcessing;
  final double soundLevel;
  final VoidCallback onPressed;
  final double size;
  
  const VoiceInputButton({
    super.key,
    required this.isListening,
    required this.isProcessing,
    required this.soundLevel,
    required this.onPressed,
    this.size = 72,
  });
  
  @override
  State<VoiceInputButton> createState() => _VoiceInputButtonState();
}

class _VoiceInputButtonState extends State<VoiceInputButton>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _waveController;
  late Animation<double> _pulseAnimation;
  
  @override
  void initState() {
    super.initState();
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _waveController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    _pulseController.repeat(reverse: true);
  }
  
  @override
  void dispose() {
    _pulseController.dispose();
    _waveController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return GestureDetector(
      onTap: widget.onPressed,
      child: AnimatedBuilder(
        animation: Listenable.merge([_pulseAnimation, _waveController]),
        builder: (context, child) {
          final scale = widget.isListening ? _pulseAnimation.value : 1.0;
          final waveProgress = _waveController.value;
          
          return SizedBox(
            width: widget.size * 1.6,
            height: widget.size * 1.6,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Outer wave rings (only when listening)
                if (widget.isListening) ...[
                  _WaveRing(
                    size: widget.size * 1.5,
                    progress: waveProgress,
                    opacity: 0.3,
                  ),
                  _WaveRing(
                    size: widget.size * 1.3,
                    progress: (waveProgress + 0.3) % 1.0,
                    opacity: 0.4,
                  ),
                ],
                // Sound level indicator
                if (widget.isListening)
                  Container(
                    width: widget.size * (1.0 + widget.soundLevel * 0.3),
                    height: widget.size * (1.0 + widget.soundLevel * 0.3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primaryLight.withOpacity(0.2),
                    ),
                  ),
                // Main button
                Transform.scale(
                  scale: scale,
                  child: Container(
                    width: widget.size,
                    height: widget.size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: widget.isListening
                            ? [AppColors.error, AppColors.errorLight]
                            : [AppColors.primaryLight, AppColors.primaryDark],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (widget.isListening 
                              ? AppColors.error 
                              : AppColors.primaryLight).withOpacity(0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Center(
                      child: widget.isProcessing
                          ? const SizedBox(
                              width: 28,
                              height: 28,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 3,
                              ),
                            )
                          : Icon(
                              widget.isListening 
                                  ? LucideIcons.micOff 
                                  : LucideIcons.mic,
                              color: Colors.white,
                              size: 28,
                            ),
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

class _WaveRing extends StatelessWidget {
  final double size;
  final double progress;
  final double opacity;
  
  const _WaveRing({
    required this.size,
    required this.progress,
    required this.opacity,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      width: size * (1 + progress * 0.3),
      height: size * (1 + progress * 0.3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.primaryLight.withOpacity(opacity * (1 - progress)),
          width: 2,
        ),
      ),
    );
  }
}
