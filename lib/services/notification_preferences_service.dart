import 'package:pocketllm/services/backend_api_service.dart';
import 'package:pocketllm/models/notification_preferences_model.dart';

class NotificationPreferencesService {
  final _api = BackendApiService();

  Future<NotificationPreferences> getNotificationPreferences() async {
    final response = await _api.get('/v1/notification-preferences');
    return NotificationPreferences.fromJson(response.data);
  }

  Future<NotificationPreferences> updateNotificationPreferences(
      NotificationPreferencesUpdate payload) async {
    final response = await _api.put('/v1/notification-preferences', payload.toJson());
    return NotificationPreferences.fromJson(response.data);
  }
}
