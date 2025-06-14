import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../providers/translation_provider.dart';

class ConversationDisplay extends StatelessWidget {
  final List<ConversationItem> conversationHistory;

  const ConversationDisplay({
    super.key,
    required this.conversationHistory,
  });

  @override
  Widget build(BuildContext context) {
    if (conversationHistory.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 64.sp,
              color: Colors.grey[600],
            ),
            SizedBox(height: 16.h),
            Text(
              '對話記錄將顯示在這裡',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16.sp,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              '開始對話翻譯吧！',
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 14.sp,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16.w),
      reverse: true, // Show latest messages at bottom
      itemCount: conversationHistory.length,
      itemBuilder: (context, index) {
        final reversedIndex = conversationHistory.length - 1 - index;
        final item = conversationHistory[reversedIndex];
        return ConversationBubble(item: item);
      },
    );
  }
}

class ConversationBubble extends StatelessWidget {
  final ConversationItem item;

  const ConversationBubble({
    super.key,
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = item.role == ConversationRole.user;
    
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      child: Row(
        mainAxisAlignment: isUser 
            ? MainAxisAlignment.end 
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            _buildAvatar(isUser),
            SizedBox(width: 8.w),
          ],
          
          Flexible(
            child: Column(
              crossAxisAlignment: isUser 
                  ? CrossAxisAlignment.end 
                  : CrossAxisAlignment.start,
              children: [
                // Role label
                Padding(
                  padding: EdgeInsets.only(
                    left: isUser ? 0 : 8.w,
                    right: isUser ? 8.w : 0,
                    bottom: 4.h,
                  ),
                  child: Text(
                    isUser ? '您' : '對方',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                
                // Original text bubble
                _buildTextBubble(
                  text: item.originalText,
                  isUser: isUser,
                  isTranslated: false,
                ),
                
                SizedBox(height: 4.h),
                
                // Translated text bubble
                _buildTextBubble(
                  text: item.translatedText,
                  isUser: isUser,
                  isTranslated: true,
                ),
                
                // Timestamp
                Padding(
                  padding: EdgeInsets.only(
                    left: isUser ? 0 : 8.w,
                    right: isUser ? 8.w : 0,
                    top: 4.h,
                  ),
                  child: Text(
                    _formatTime(item.timestamp),
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 10.sp,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          if (isUser) ...[
            SizedBox(width: 8.w),
            _buildAvatar(isUser),
          ],
        ],
      ),
    );
  }

  Widget _buildAvatar(bool isUser) {
    return Container(
      width: 32.w,
      height: 32.h,
      decoration: BoxDecoration(
        color: isUser 
            ? const Color(0xFF2196F3)
            : const Color(0xFF4CAF50),
        shape: BoxShape.circle,
      ),
      child: Icon(
        isUser ? Icons.person : Icons.person_outline,
        color: Colors.white,
        size: 18.sp,
      ),
    );
  }

  Widget _buildTextBubble({
    required String text,
    required bool isUser,
    required bool isTranslated,
  }) {
    final bubbleColor = isUser
        ? (isTranslated 
           ? const Color(0xFF1976D2) 
           : const Color(0xFF2196F3))
        : (isTranslated 
           ? const Color(0xFF388E3C) 
           : const Color(0xFF4CAF50));

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: bubbleColor,
        borderRadius: BorderRadius.circular(16.r).copyWith(
          topLeft: !isUser ? Radius.zero : Radius.circular(16.r),
          topRight: isUser ? Radius.zero : Radius.circular(16.r),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isTranslated)
            Container(
              padding: EdgeInsets.only(bottom: 2.h),
              child: Text(
                '翻譯',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          Text(
            text,
            style: TextStyle(
              color: Colors.white,
              fontSize: 14.sp,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 1) {
      return '剛剛';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}分鐘前';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}小時前';
    } else {
      return '${dateTime.month}/${dateTime.day} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }
}