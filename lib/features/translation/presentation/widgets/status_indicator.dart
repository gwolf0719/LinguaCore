import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/translation_provider.dart';
import '../../../settings/presentation/providers/language_settings_provider.dart';
import 'dart:math' as math;
import 'dart:async';

class StatusIndicator extends ConsumerWidget {
  final TranslationMode mode;
  final ConversationRole currentRole;
  final String currentText;
  final String translatedText;
  final String statusMessage;
  final double soundLevel;

  const StatusIndicator({
    super.key,
    required this.mode,
    required this.currentRole,
    required this.currentText,
    required this.translatedText,
    required this.statusMessage,
    required this.soundLevel,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final languageSettings = ref.watch(languageSettingsProvider);
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
          // Status icon and text
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildStatusIcon(),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  statusMessage.isNotEmpty
                      ? statusMessage
                      : _getStatusText(languageSettings),
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

          SizedBox(height: 16.h),

          // Current role indicator
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: currentRole == ConversationRole.user
                  ? const Color(0xFF2196F3)
                  : const Color(0xFF4CAF50),
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Text(
              currentRole == ConversationRole.user
                  ? '我的語言: ${languageSettings.nativeLanguage.name}'
                  : '對方語言: ${languageSettings.targetLanguage.name}',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          // Current text display
          if (currentText.isNotEmpty) ...[
            SizedBox(height: 16.h),
            _buildTextDisplay('原文', currentText, Colors.blue),
          ],

          // Translated text display
          if (translatedText.isNotEmpty) ...[
            SizedBox(height: 12.h),
            _buildTextDisplay('翻譯', translatedText, Colors.green),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusIcon() {
    switch (mode) {
      case TranslationMode.listening:
        return _SoundWaveAnimation(soundLevel: soundLevel);
      case TranslationMode.translating:
        return SizedBox(
          width: 24.w,
          height: 24.h,
          child: const CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
          ),
        );
      case TranslationMode.speaking:
        return _SpeakingAnimation();
      case TranslationMode.idle:
      default:
        return Icon(
          Icons.pause_circle_outline,
          color: Colors.grey,
          size: 24.sp,
        );
    }
  }

  String _getStatusText(LanguageSettings languageSettings) {
    switch (mode) {
      case TranslationMode.listening:
        final language = currentRole == ConversationRole.user
            ? languageSettings.nativeLanguage.name
            : languageSettings.targetLanguage.name;
        return '🎤 正在聽取$language...';
      case TranslationMode.translating:
        return '🔄 正在翻譯中...';
      case TranslationMode.speaking:
        return '🔊 正在播放翻譯...';
      case TranslationMode.idle:
      default:
        return '⏸️ 待機中';
    }
  }

  Color _getBorderColor() {
    switch (mode) {
      case TranslationMode.listening:
        return Colors.red;
      case TranslationMode.translating:
        return Colors.orange;
      case TranslationMode.speaking:
        return Colors.green;
      case TranslationMode.idle:
      default:
        return Colors.grey;
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

// 聲音波形動畫組件
class _SoundWaveAnimation extends StatefulWidget {
  final double soundLevel;

  const _SoundWaveAnimation({required this.soundLevel});

  @override
  _SoundWaveAnimationState createState() => _SoundWaveAnimationState();
}

class _SoundWaveAnimationState extends State<_SoundWaveAnimation>
    with TickerProviderStateMixin {
  Timer? _animationTimer;
  List<double> _barHeights = [];
  List<double> _targetHeights = [];
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    // 初始化波形條高度
    _barHeights = List.generate(7, (index) => 0.2);
    _targetHeights = List.generate(7, (index) => 0.2);

    // 脈衝動畫控制器
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // 定時更新波形
    _animationTimer = Timer.periodic(Duration(milliseconds: 80), (timer) {
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

    // 根據音量級別生成更自然的波形
    for (int i = 0; i < _targetHeights.length; i++) {
      if (soundLevel > 0.05) {
        // 有聲音時，使用音量級別加上隨機變化
        final baseMultiplier =
            soundLevel * (0.5 + math.Random().nextDouble() * 1.5);
        final frequencyOffset = (i * 0.8) + (now / 150.0);
        final waveEffect = math.sin(frequencyOffset) * 0.4;

        _targetHeights[i] =
            math.max(0.1, math.min(2.0, baseMultiplier + waveEffect));
      } else {
        // 無聲音時，保持最低高度與微小波動
        _targetHeights[i] = 0.15 + (math.sin(now / 300.0 + i) * 0.05);
      }

      // 平滑過渡到目標高度
      final diff = _targetHeights[i] - _barHeights[i];
      _barHeights[i] += diff * 0.3; // 30% 的過渡速度
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final soundLevel = widget.soundLevel;
    final baseHeight = 24.h;
    final isActive = soundLevel > 0.05;

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: isActive ? _pulseAnimation.value : 1.0,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(_barHeights.length, (index) {
              final height = baseHeight * _barHeights[index];

              // 中間的條比較高，兩邊的條比較低（類似真實的聲音頻譜）
              final centerWeight = 1.0 -
                  (index - (_barHeights.length / 2)).abs() /
                      (_barHeights.length / 2);
              final adjustedHeight = height * (0.5 + centerWeight * 0.5);

              return AnimatedContainer(
                duration: Duration(milliseconds: 100),
                width: index == _barHeights.length ~/ 2 ? 4.w : 3.w, // 中間條稍寬
                height: math.max(4.h, adjustedHeight),
                margin: EdgeInsets.symmetric(horizontal: 0.5.w),
                decoration: BoxDecoration(
                  color: _getBarColor(soundLevel, index),
                  borderRadius: BorderRadius.circular(2.r),
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color: Colors.red.withOpacity(0.3),
                            blurRadius: 2,
                            spreadRadius: 0.5,
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
    if (soundLevel > 0.05) {
      // 活躍時的顏色漸變
      final intensity = math.min(1.0, soundLevel * 2);
      if (intensity > 0.8) {
        return Color.lerp(Colors.red, Colors.orange, 0.3)!;
      } else if (intensity > 0.5) {
        return Colors.red;
      } else {
        return Colors.red.withOpacity(0.8);
      }
    } else {
      // 靜音時的顏色
      return Colors.red.withOpacity(0.2);
    }
  }
}

// 語音播放動畫組件
class _SpeakingAnimation extends StatefulWidget {
  @override
  _SpeakingAnimationState createState() => _SpeakingAnimationState();
}

class _SpeakingAnimationState extends State<_SpeakingAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
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
