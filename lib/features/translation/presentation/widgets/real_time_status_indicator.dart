import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../providers/real_time_translation_provider.dart';
import 'dart:math' as math;
import 'dart:async';

class RealTimeStatusIndicator extends StatelessWidget {
  final RealTimeMode mode;
  final String currentSpeech;
  final String lastTranslation;
  final double soundLevel;
  final String statusMessage;

  const RealTimeStatusIndicator({
    super.key,
    required this.mode,
    required this.currentSpeech,
    required this.lastTranslation,
    required this.soundLevel,
    required this.statusMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      margin: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D2D),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: _getBorderColor(),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          // 狀態圖示和文字
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildStatusIcon(),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  statusMessage.isNotEmpty
                      ? statusMessage
                      : _getDefaultStatusText(),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),

          // 即時語音顯示
          if (currentSpeech.isNotEmpty) ...[
            SizedBox(height: 16.h),
            _buildTextDisplay('即時語音', currentSpeech, Colors.blue),
          ],

          // 即時翻譯顯示
          if (lastTranslation.isNotEmpty) ...[
            SizedBox(height: 12.h),
            _buildTextDisplay('即時翻譯', lastTranslation, Colors.green),
          ],

          // 模式指示器
          SizedBox(height: 16.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: _getModeColor(),
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Text(
              _getModeText(),
              style: TextStyle(
                color: Colors.white,
                fontSize: 12.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIcon() {
    switch (mode) {
      case RealTimeMode.listening:
        return _RealTimeSoundWaveAnimation(soundLevel: soundLevel);
      case RealTimeMode.translating:
        return SizedBox(
          width: 24.w,
          height: 24.h,
          child: const CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
          ),
        );
      case RealTimeMode.speaking:
        return _RealTimeSpeakingAnimation();
      case RealTimeMode.idle:
      default:
        return Icon(
          Icons.live_tv,
          color: Colors.grey,
          size: 24.sp,
        );
    }
  }

  String _getDefaultStatusText() {
    switch (mode) {
      case RealTimeMode.listening:
        return '🎤 實時聽取中...';
      case RealTimeMode.translating:
        return '🔄 實時翻譯中...';
      case RealTimeMode.speaking:
        return '🔊 實時播放中...';
      case RealTimeMode.idle:
      default:
        return '⏸️ 實時翻譯待機';
    }
  }

  Color _getBorderColor() {
    switch (mode) {
      case RealTimeMode.listening:
        return Colors.red;
      case RealTimeMode.translating:
        return Colors.orange;
      case RealTimeMode.speaking:
        return Colors.green;
      case RealTimeMode.idle:
      default:
        return Colors.grey;
    }
  }

  Color _getModeColor() {
    switch (mode) {
      case RealTimeMode.listening:
        return Colors.red;
      case RealTimeMode.translating:
        return Colors.orange;
      case RealTimeMode.speaking:
        return Colors.green;
      case RealTimeMode.idle:
      default:
        return Colors.grey;
    }
  }

  String _getModeText() {
    switch (mode) {
      case RealTimeMode.listening:
        return '聽取模式';
      case RealTimeMode.translating:
        return '翻譯模式';
      case RealTimeMode.speaking:
        return '播放模式';
      case RealTimeMode.idle:
      default:
        return '待機模式';
    }
  }

  Widget _buildTextDisplay(String label, String text, Color color) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            text,
            style: TextStyle(
              color: Colors.white,
              fontSize: 14.sp,
            ),
          ),
        ],
      ),
    );
  }
}

// 實時聲音波形動畫組件
class _RealTimeSoundWaveAnimation extends StatefulWidget {
  final double soundLevel;

  const _RealTimeSoundWaveAnimation({required this.soundLevel});

  @override
  _RealTimeSoundWaveAnimationState createState() =>
      _RealTimeSoundWaveAnimationState();
}

class _RealTimeSoundWaveAnimationState
    extends State<_RealTimeSoundWaveAnimation> with TickerProviderStateMixin {
  Timer? _animationTimer;
  List<double> _barHeights = [];
  List<double> _targetHeights = [];
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _barHeights = List.generate(9, (index) => 0.2);
    _targetHeights = List.generate(9, (index) => 0.2);

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 0.9, end: 1.3).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _animationTimer = Timer.periodic(Duration(milliseconds: 60), (timer) {
      if (mounted) {
        _updateWaveform();
      }
    });

    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _updateWaveform() {
    final soundLevel = widget.soundLevel;
    final now = DateTime.now().millisecondsSinceEpoch;

    for (int i = 0; i < _targetHeights.length; i++) {
      if (soundLevel > 0.03) {
        final baseMultiplier =
            soundLevel * (0.6 + math.Random().nextDouble() * 1.8);
        final frequencyOffset = (i * 0.7) + (now / 120.0);
        final waveEffect = math.sin(frequencyOffset) * 0.5;

        _targetHeights[i] =
            math.max(0.1, math.min(2.5, baseMultiplier + waveEffect));
      } else {
        _targetHeights[i] = 0.1 + (math.sin(now / 400.0 + i) * 0.03);
      }

      final diff = _targetHeights[i] - _barHeights[i];
      _barHeights[i] += diff * 0.4;
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final soundLevel = widget.soundLevel;
    final baseHeight = 26.h;
    final isActive = soundLevel > 0.03;

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: isActive ? _pulseAnimation.value : 1.0,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(_barHeights.length, (index) {
              final height = baseHeight * _barHeights[index];
              final centerWeight = 1.0 -
                  (index - (_barHeights.length / 2)).abs() /
                      (_barHeights.length / 2);
              final adjustedHeight = height * (0.4 + centerWeight * 0.6);

              return AnimatedContainer(
                duration: Duration(milliseconds: 80),
                width: index == _barHeights.length ~/ 2 ? 4.w : 3.w,
                height: math.max(3.h, adjustedHeight),
                margin: EdgeInsets.symmetric(horizontal: 0.5.w),
                decoration: BoxDecoration(
                  color: _getBarColor(soundLevel, index),
                  borderRadius: BorderRadius.circular(2.r),
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color: Colors.red.withOpacity(0.4),
                            blurRadius: 3,
                            spreadRadius: 1,
                          ),
                        ]
                      : null,
                ),
              );
            }),
          ),
        );
      },
    );
  }

  Color _getBarColor(double soundLevel, int index) {
    if (soundLevel > 0.03) {
      final intensity = math.min(1.0, soundLevel * 2.5);
      if (intensity > 0.8) {
        return Color.lerp(Colors.red, Colors.yellow, 0.4)!;
      } else if (intensity > 0.5) {
        return Colors.red;
      } else {
        return Colors.red.withOpacity(0.9);
      }
    } else {
      return Colors.red.withOpacity(0.15);
    }
  }
}

// 實時語音播放動畫組件
class _RealTimeSpeakingAnimation extends StatefulWidget {
  @override
  _RealTimeSpeakingAnimationState createState() =>
      _RealTimeSpeakingAnimationState();
}

class _RealTimeSpeakingAnimationState extends State<_RealTimeSpeakingAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.3).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Icon(
            Icons.volume_up,
            color: Colors.green,
            size: 24.sp,
          ),
        );
      },
    );
  }
}
