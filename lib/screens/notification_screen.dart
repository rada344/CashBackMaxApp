import 'package:flutter/material.dart';

import '../services/notification_log_service.dart';
import '../utils/app_colors.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final log = NotificationLog.instance;
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        title: const Text(
          'Notifications',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          ValueListenableBuilder<List<NotificationEntry>>(
            valueListenable: log.entries,
            builder: (_, list, __) {
              if (list.isEmpty) return const SizedBox.shrink();
              return TextButton(
                onPressed: () => _confirmClear(context, log),
                child: const Text(
                  'Clear',
                  style: TextStyle(color: AppColors.accent2, fontWeight: FontWeight.w700),
                ),
              );
            },
          ),
        ],
      ),
      body: ValueListenableBuilder<List<NotificationEntry>>(
        valueListenable: log.entries,
        builder: (_, list, __) {
          if (list.isEmpty) {
            return _EmptyState();
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            itemCount: list.length + 1,
            itemBuilder: (_, i) {
              if (i == 0) {
                return const Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: Text(
                    'Smart alerts based on your location, reward cards, and active offers.',
                    style: TextStyle(color: AppColors.text2, fontSize: 14),
                  ),
                );
              }
              return _Card(entry: list[i - 1]);
            },
          );
        },
      ),
    );
  }

  void _confirmClear(BuildContext context, NotificationLog log) {
    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.bg2,
        title: const Text('Clear all notifications?', style: TextStyle(color: AppColors.text)),
        content: const Text(
          'This will remove every alert from this list. It cannot be undone.',
          style: TextStyle(color: AppColors.text2),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              log.clear();
              Navigator.pop(dialogCtx);
            },
            child: const Text(
              'Clear',
              style: TextStyle(color: AppColors.red, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.entry});
  final NotificationEntry entry;

  @override
  Widget build(BuildContext context) {
    final accent = _accentFor(entry.type);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bg2,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: entry.read
              ? Colors.white.withValues(alpha: 0.06)
              : accent.withValues(alpha: .4),
          width: entry.read ? 1 : 1.5,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_iconFor(entry.type), color: accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        entry.title,
                        style: const TextStyle(
                          color: AppColors.text,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    if (!entry.read)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: accent,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  entry.message,
                  style: const TextStyle(
                    color: AppColors.text2,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _relativeTime(entry.createdAt),
                  style: const TextStyle(
                    color: AppColors.text3,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconFor(NotificationType t) => switch (t) {
        NotificationType.storeAlert => Icons.location_on,
        NotificationType.recommendation => Icons.credit_card,
        NotificationType.reward => Icons.local_offer,
        NotificationType.security => Icons.security,
        NotificationType.system => Icons.notifications,
      };

  Color _accentFor(NotificationType t) => switch (t) {
        NotificationType.storeAlert => AppColors.accent,
        NotificationType.recommendation => AppColors.green,
        NotificationType.reward => AppColors.amber,
        NotificationType.security => AppColors.red,
        NotificationType.system => AppColors.accent2,
      };

  String _relativeTime(DateTime t) {
    final diff = DateTime.now().difference(t);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hr ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${t.day}/${t.month}/${t.year}';
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: AppColors.bg2,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: .08)),
              ),
              child: const Icon(
                Icons.notifications_none_rounded,
                size: 44,
                color: AppColors.text3,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'No notifications yet',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            const Text(
              "When CashBackMax detects a supported store nearby, you'll see the alert here.",
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.text2, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}
