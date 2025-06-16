import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../providers/real_time_translation_provider.dart';
import '../../../../core/services/service_locator.dart';
import '../../../../core/services/audio_service.dart';
import '../../../../core/services/translation_service.dart';
import '../../../../core/services/tts_service.dart';

class RealTimeDebugPanel extends ConsumerWidget {
  const RealTimeDebugPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final realTimeState = ref.watch(realTimeTranslationProvider);
    final audioService = sl<AudioService>();
    final translationService = sl<TranslationService>();
    final ttsService = sl<TTSService>();

    return Container(
      margin: EdgeInsets.all(16.w),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: Colors.orange.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.bug_report, color: Colors.orange, size: 16.sp),
              SizedBox(width: 8.w),
              Text(
                '實時翻譯調試資訊',
                style: TextStyle(
                  color: Colors.orange,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          SizedBox(height: 8.h),

          _buildStatusRow('音頻服務', audioService.isInitialized),
          _buildStatusRow('翻譯服務', translationService.isInitialized),
          _buildStatusRow('語音服務', ttsService.isInitialized),
          _buildStatusRow('整體初始化', realTimeState.isInitialized),
          _buildStatusRow('正在聽取', audioService.isListening),

          SizedBox(height: 4.h),

          _buildInfoRow('當前模式', _getModeText(realTimeState.mode)),
          _buildInfoRow('音量級別', realTimeState.soundLevel.toStringAsFixed(2)),

          if (realTimeState.statusMessage.isNotEmpty) ...[
            SizedBox(height: 4.h),
            _buildInfoRow('狀態訊息', realTimeState.statusMessage),
          ],

          if (realTimeState.currentSpeech.isNotEmpty) ...[
            SizedBox(height: 4.h),
            _buildInfoRow('當前語音', realTimeState.currentSpeech),
          ],

          if (realTimeState.lastTranslation.isNotEmpty) ...[
            SizedBox(height: 4.h),
            _buildInfoRow('最後翻譯', realTimeState.lastTranslation),
          ],

          SizedBox(height: 8.h),

          // 測試麥克風按鈕
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    await _testMicrophone(ref);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: EdgeInsets.symmetric(vertical: 8.h),
                  ),
                  child: Text(
                    '測試麥克風',
                    style: TextStyle(fontSize: 12.sp),
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    await _reinitializeServices(ref);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    padding: EdgeInsets.symmetric(vertical: 8.h),
                  ),
                  child: Text(
                    '重新初始化',
                    style: TextStyle(fontSize: 12.sp),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow(String label, bool status) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2.h),
      child: Row(
        children: [
          Container(
            width: 8.w,
            height: 8.h,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: status ? Colors.green : Colors.red,
            ),
          ),
          SizedBox(width: 8.w),
          Text(
            '$label: ${status ? "正常" : "異常"}',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 1.h),
      child: Text(
        '$label: $value',
        style: TextStyle(
          color: Colors.white70,
          fontSize: 11.sp,
        ),
      ),
    );
  }

  String _getModeText(RealTimeMode mode) {
    switch (mode) {
      case RealTimeMode.listening:
        return '聽取中';
      case RealTimeMode.translating:
        return '翻譯中';
      case RealTimeMode.speaking:
        return '播放中';
      case RealTimeMode.idle:
        return '待機';
    }
  }

  Future<void> _testMicrophone(WidgetRef ref) async {
    try {
      final audioService = sl<AudioService>();
      print('🎤 Testing microphone...');

      // 檢查可用語言
      final locales = await audioService.availableLocales;
      print('Available locales: $locales');

      if (locales.isEmpty) {
        print('❌ No speech recognition locales available');
        return;
      }

      // 測試短暫的語音識別
      await audioService.startListening(
        localeId: 'zh-TW',
        partialResults: true,
        realTimeMode: false,
      );

      // 等待2秒後停止
      await Future.delayed(Duration(seconds: 2));
      await audioService.stopListening();

      print('✅ Microphone test completed');
    } catch (e) {
      print('❌ Microphone test failed: $e');
    }
  }

  Future<void> _reinitializeServices(WidgetRef ref) async {
    try {
      print('🔄 Reinitializing all services...');

      final audioService = sl<AudioService>();
      final translationService = sl<TranslationService>();
      final ttsService = sl<TTSService>();

      // 重新初始化所有服務
      await audioService.initialize();
      await translationService.initialize();
      await ttsService.initialize();

      // 觸發 provider 重新檢查
      ref.invalidate(realTimeTranslationProvider);

      print('✅ All services reinitialized successfully');
    } catch (e) {
      print('❌ Error reinitializing services: $e');
    }
  }
}
