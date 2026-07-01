import 'package:pocketllm/services/backend_api_service.dart';
import 'package:pocketllm/models/notification_models.dart';

class NotificationService {
  final _api = BackendApiService();

  Future<List<NotificationModel>> fetchNotifications() async {
    final response = await _api.get('/v1/notifications');
    return (response.data as List)
        .map((item) => NotificationModel.fromJson(item))
        .toList();
  }

  Future<void> markAsRead(String notificationId) async {
    await _api.patch('/v1/notifications/$notificationId/read', body: {});
  }

  Future<void> markAllAsRead() async {
    await _api.post('/v1/notifications/mark-all-read', body: {});
  }

  Future<int> getUnreadCount() async {
    final response = await _api.get('/v1/notifications/unread-count');
    return response.data['count'];
  }
}
