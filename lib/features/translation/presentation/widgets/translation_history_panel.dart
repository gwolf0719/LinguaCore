import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class TranslationHistoryPanel extends StatelessWidget {
  final List<String> speechSegments;
  final List<String> translationSegments;
  final String currentSpeech;
  final String lastTranslation;

  const TranslationHistoryPanel({
    super.key,
    required this.speechSegments,
    required this.translationSegments,
    required this.currentSpeech,
    required this.lastTranslation,
  });

  @override
  Widget build(BuildContext context) {
    final hasHistory =
        speechSegments.isNotEmpty || translationSegments.isNotEmpty;
    final hasCurrentContent =
        currentSpeech.isNotEmpty || lastTranslation.isNotEmpty;

    if (!hasHistory && !hasCurrentContent) {
      return _buildEmptyState();
    }

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 標題
          Padding(
            padding: EdgeInsets.symmetric(vertical: 12.h),
            child: Text(
              '翻譯記錄',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // 歷史記錄列表
          Expanded(
            child: ListView.builder(
              itemCount: _getTotalItemCount(),
              itemBuilder: (context, index) {
                return _buildHistoryItem(index);
              },
            ),
          ),
        ],
      ),
    );
  }

  int _getTotalItemCount() {
    // 計算歷史記錄 + 當前進行中的項目
    final historyCount = speechSegments.length > translationSegments.length
        ? speechSegments.length
        : translationSegments.length;

    // 如果有當前內容，加1
    return hasCurrentContent ? historyCount + 1 : historyCount;
  }

  bool get hasCurrentContent =>
      currentSpeech.isNotEmpty || lastTranslation.isNotEmpty;

  Widget _buildHistoryItem(int index) {
    final isCurrentItem =
        hasCurrentContent && index == _getTotalItemCount() - 1;

    if (isCurrentItem) {
      return _buildCurrentItem();
    }

    // 歷史項目
    final speechText =
        index < speechSegments.length ? speechSegments[index] : '';
    final translationText =
        index < translationSegments.length ? translationSegments[index] : '';

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D2D),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 時間標記
          Text(
            '記錄 ${index + 1}',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 12.sp,
            ),
          ),
          SizedBox(height: 8.h),

          // 日文原文
          if (speechText.isNotEmpty) ...[
            _buildTextSection('日文原文', speechText, Colors.blue),
            SizedBox(height: 8.h),
          ],

          // 中文翻譯
          if (translationText.isNotEmpty) ...[
            _buildTextSection('中文翻譯', translationText, Colors.green),
          ],
        ],
      ),
    );
  }

  Widget _buildCurrentItem() {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D2D),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.orange.withOpacity(0.6), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 當前標記
          Row(
            children: [
              Icon(
                Icons.fiber_manual_record,
                color: Colors.red,
                size: 12.sp,
              ),
              SizedBox(width: 6.w),
              Text(
                '實時進行中',
                style: TextStyle(
                  color: Colors.orange,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),

          // 當前日文語音
          if (currentSpeech.isNotEmpty) ...[
            _buildTextSection('即時語音', currentSpeech, Colors.blue),
            SizedBox(height: 8.h),
          ],

          // 當前中文翻譯
          if (lastTranslation.isNotEmpty) ...[
            _buildTextSection('即時翻譯', lastTranslation, Colors.green),
          ],
        ],
      ),
    );
  }

  Widget _buildTextSection(String label, String text, Color color) {
    return Column(
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
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      margin: EdgeInsets.all(16.w),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.translate,
              size: 64.sp,
              color: Colors.grey.withOpacity(0.5),
            ),
            SizedBox(height: 16.h),
            Text(
              '準備開始實時翻譯',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 16.sp,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              '點擊下方按鈕開始聽取日文並即時翻譯成中文',
              style: TextStyle(
                color: Colors.grey.withOpacity(0.7),
                fontSize: 14.sp,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
