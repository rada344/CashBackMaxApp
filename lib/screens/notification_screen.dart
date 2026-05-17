import 'package:flutter/material.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  final List<NotificationItem> notifications = const [
    NotificationItem(
      icon: Icons.location_on,
      title: 'Store detected',
      message: 'You entered Coles. Flybuys gives the best reward here.',
      time: '2 min ago',
      color: Color(0xFF6C63FF),
    ),
    NotificationItem(
      icon: Icons.credit_card,
      title: 'Best card recommendation',
      message: 'Use Flybuys Card to earn 3x points on groceries.',
      time: '10 min ago',
      color: Color(0xFF22C55E),
    ),
    NotificationItem(
      icon: Icons.local_offer,
      title: 'Bonus offer available',
      message: 'Spend \$50 more at Coles to unlock 1,000 bonus points.',
      time: 'Today',
      color: Color(0xFFF59E0B),
    ),
    NotificationItem(
      icon: Icons.security,
      title: 'Security update',
      message: 'Your reward card data is securely stored.',
      time: 'Yesterday',
      color: Color(0xFFEF4444),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0F),
        elevation: 0,
        title: const Text(
          'Notifications',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Smart alerts based on your location, reward cards, and active offers.',
            style: TextStyle(
              color: Color(0xFF9CA3AF),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 20),

          ...notifications.map((item) {
            return _notificationCard(item);
          }),
        ],
      ),
    );
  }

  Widget _notificationCard(NotificationItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF13131A),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: item.color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(item.icon, color: item.color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.message,
                  style: const TextStyle(
                    color: Color(0xFF9CA3AF),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  item.time,
                  style: const TextStyle(
                    color: Color(0xFF5A5A7A),
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
}

class NotificationItem {
  final IconData icon;
  final String title;
  final String message;
  final String time;
  final Color color;

  const NotificationItem({
    required this.icon,
    required this.title,
    required this.message,
    required this.time,
    required this.color,
  });
}
