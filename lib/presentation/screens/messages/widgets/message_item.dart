import 'package:flutter/material.dart';
import 'package:eios/data/models/message.dart';
import 'package:eios/core/theme/app_theme.dart';
import 'package:intl/intl.dart';

class MessageItem extends StatelessWidget {
  final Message message;
  final dynamic currentUserId;
  final VoidCallback? onDelete;

  const MessageItem({
    super.key,
    required this.message,
    required this.currentUserId,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isMyMessage = currentUserId.toString() == message.user?.id.toString();
    final isTeacher = message.isTeacher ?? false;

    DateTime? messageDate;
    try {
      if (message.createDate != null) {
        messageDate = DateTime.parse(message.createDate!);
      }
    } catch (e) {
      debugPrint('Error parsing date: ${message.createDate}');
    }

    final dateFormat = DateFormat('dd.MM.yyyy HH:mm');

    final photoUrl = message.user?.photo?.urlMedium;
    final hasPhoto = photoUrl != null && photoUrl.isNotEmpty;

    final bubbleColor = isMyMessage
        ? AppColors.primary
        : isTeacher
        ? AppColors.lemon.withValues(alpha: 0.55)
        : AppColors.white;
    final textColor = isMyMessage ? AppColors.white : AppColors.ink;
    final secondaryTextColor = isMyMessage
        ? AppColors.white.withValues(alpha: 0.74)
        : AppColors.mutedText;

    return Align(
      alignment: isMyMessage ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: bubbleColor,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(24),
              topRight: const Radius.circular(24),
              bottomLeft: isMyMessage
                  ? const Radius.circular(24)
                  : const Radius.circular(8),
              bottomRight: isMyMessage
                  ? const Radius.circular(8)
                  : const Radius.circular(24),
            ),
            border: isMyMessage ? null : Border.all(color: AppColors.outline),
            boxShadow: const [
              BoxShadow(
                color: AppColors.softShadow,
                blurRadius: 18,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: InkWell(
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(24),
              topRight: const Radius.circular(24),
              bottomLeft: isMyMessage
                  ? const Radius.circular(24)
                  : const Radius.circular(8),
              bottomRight: isMyMessage
                  ? const Radius.circular(8)
                  : const Radius.circular(24),
            ),
            onLongPress: isMyMessage ? onDelete : null,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: isTeacher
                            ? AppColors.magenta
                            : isMyMessage
                            ? AppColors.deepBlue
                            : AppColors.surfaceMuted,
                        backgroundImage: hasPhoto
                            ? NetworkImage(photoUrl)
                            : null,
                        child: !hasPhoto
                            ? Text(
                                _getInitials(message.user?.fio),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    message.user?.fio ?? 'Неизвестный',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                      color: textColor,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (isTeacher) ...[
                                  const SizedBox(width: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.magenta,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Text(
                                      'Преподаватель',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            if (messageDate != null)
                              Text(
                                dateFormat.format(messageDate),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: secondaryTextColor,
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (isMyMessage)
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          iconSize: 20,
                          color: AppColors.white.withValues(alpha: 0.82),
                          onPressed: onDelete,
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    message.text ?? '',
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.45,
                      color: textColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _getInitials(String? name) {
    if (name == null || name.isEmpty) return 'U';

    final words = name.trim().split(' ');
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }
}
