import 'package:flutter/material.dart';
import 'package:pocketllm/models/notification_models.dart';
import 'package:pocketllm/services/notification_service.dart';
import 'package:pocketllm/theme/theme.dart';
import 'notification_settings_page.dart';

class NotificationCenterScreen extends StatefulWidget {
  const NotificationCenterScreen({super.key});

  @override
  State<NotificationCenterScreen> createState() =>
      _NotificationCenterScreenState();
}

class _NotificationCenterScreenState extends State<NotificationCenterScreen> {
  final NotificationService _notificationService = NotificationService();
  List<NotificationModel> _notifications = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final notifications = await _notificationService.fetchNotifications();
      setState(() {
        _notifications = notifications;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load notifications. Please try again later.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      await _notificationService.markAllAsRead();
      _loadNotifications();
    } catch (e) {
      // Handle error
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: _markAllAsRead,
            child: const Text('Mark all read'),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationSettingsPage(),
                ),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator.adaptive())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(_error!, textAlign: TextAlign.center),
                  ),
                )
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_notifications.isEmpty) {
      return const Center(child: Text('No notifications yet.'));
    }

    return RefreshIndicator(
      onRefresh: _loadNotifications,
      child: ListView.builder(
        itemCount: _notifications.length,
        itemBuilder: (context, index) {
          final notification = _notifications[index];
          return _buildNotificationTile(notification, Theme.of(context));
        },
      ),
    );
  }

  Widget _buildNotificationTile(NotificationModel notification, ThemeData theme) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outline.withOpacity(0.3)),
      ),
      child: ListTile(
        leading: _getNotificationIcon(notification.type, theme),
        title: Text(notification.contentSummary, style: theme.textTheme.bodyLarge),
        subtitle: Text(
          _formatDate(notification.createdAt),
          style: theme.textTheme.bodySmall,
        ),
        trailing: !notification.isRead
            ? Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: HiVpnColors.primary,
                  shape: BoxShape.circle,
                ),
              )
            : null,
      ),
    );
  }

  Widget _getNotificationIcon(String type, ThemeData theme) {
    IconData iconData;
    Color color;

    switch (type) {
      case 'account_deletion':
        iconData = Icons.warning_amber_rounded;
        color = HiVpnColors.Error;
        break;
      case 'job_completed':
        iconData = Icons.check_circle_outline;
        color = HiVpnColors.Success;
        break;
      case 'subscription_renewed':
        iconData = Icons.autorenew;
        color = HiVpnColors.primary;
        break;
      case 'referral_bonus':
        iconData = Icons.star_outline;
        color = Colors.orange;
        break;
      default:
        iconData = Icons.notifications_none;
        color = theme.colorScheme.onSurface;
    }

    return Icon(iconData, color: color);
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 1) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
