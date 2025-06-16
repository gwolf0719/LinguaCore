import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../providers/real_time_translation_provider.dart';

class RealTimeControlButtons extends StatelessWidget {
  final RealTimeMode mode;
  final bool isInitialized;
  final VoidCallback onStartTranslation;
  final VoidCallback onStopTranslation;

  const RealTimeControlButtons({
    super.key,
    required this.mode,
    required this.isInitialized,
    required this.onStartTranslation,
    required this.onStopTranslation,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (mode == RealTimeMode.idle) ...[
            // 開始實時翻譯按鈕
            _buildActionButton(
              onPressed: isInitialized ? onStartTranslation : null,
              icon: Icons.flash_on,
              label: '🚀 開始極速翻譯',
              color: Colors.orange,
              isEnabled: isInitialized,
            ),
          ] else ...[
            // 停止實時翻譯按鈕
            _buildActionButton(
              onPressed: onStopTranslation,
              icon: Icons.stop,
              label: '停止實時翻譯',
              color: Colors.red,
              isEnabled: true,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required VoidCallback? onPressed,
    required IconData icon,
    required String label,
    required Color color,
    required bool isEnabled,
  }) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 200),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(
          icon,
          color: Colors.white,
          size: 24.sp,
        ),
        label: Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: isEnabled ? color : Colors.grey,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
          elevation: isEnabled ? 4 : 1,
        ),
      ),
    );
  }
}
