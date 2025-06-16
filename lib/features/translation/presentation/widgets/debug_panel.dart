import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../providers/translation_provider.dart';
import '../../../../core/services/service_locator.dart';
import '../../../../core/services/audio_service.dart';

class DebugPanel extends ConsumerWidget {
  const DebugPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final translationState = ref.watch(translationProvider);
    final audioService = sl<AudioService>();

    return Container(
      margin: EdgeInsets.all(16.w),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: Colors.green.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.bug_report, color: Colors.green, size: 16.sp),
              SizedBox(width: 8.w),
              Text(
                '調試資訊',
                style: TextStyle(
                  color: Colors.green,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          SizedBox(height: 8.h),

          _buildStatusRow('服務初始化', translationState.isInitialized),
          _buildStatusRow('音頻服務', audioService.isInitialized),
          _buildStatusRow('正在聽取', audioService.isListening),

          SizedBox(height: 4.h),

          _buildInfoRow('當前模式', _getModeText(translationState.mode)),
          _buildInfoRow(
              '下載進度', '${(translationState.downloadProgress * 100).toInt()}%'),
          _buildInfoRow('音量級別', translationState.soundLevel.toStringAsFixed(2)),

          if (translationState.statusMessage.isNotEmpty) ...[
            SizedBox(height: 4.h),
            _buildInfoRow('狀態訊息', translationState.statusMessage),
          ],

          if (translationState.currentText.isNotEmpty) ...[
            SizedBox(height: 4.h),
            _buildInfoRow('當前文字', translationState.currentText),
          ],

          SizedBox(height: 8.h),

          // 重新初始化按鈕
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                await _reinitializeServices(ref);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                padding: EdgeInsets.symmetric(vertical: 8.h),
              ),
              child: Text(
                '重新初始化服務',
                style: TextStyle(fontSize: 12.sp),
              ),
            ),
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

  String _getModeText(TranslationMode mode) {
    switch (mode) {
      case TranslationMode.listening:
        return '聽取中';
      case TranslationMode.translating:
        return '翻譯中';
      case TranslationMode.speaking:
        return '播放中';
      case TranslationMode.idle:
        return '待機';
    }
  }

  Future<void> _reinitializeServices(WidgetRef ref) async {
    try {
      final audioService = sl<AudioService>();

      // 重新初始化音頻服務
      await audioService.initialize();

      // 觸發翻譯提供者重新檢查狀態
      // 通過切換模式來觸發狀態更新
      final notifier = ref.read(translationProvider.notifier);
      notifier.stopListening();

      print('✅ Services reinitialized successfully');
    } catch (e) {
      print('❌ Error reinitializing services: $e');
    }
  }
}
