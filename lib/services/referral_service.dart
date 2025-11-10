import '../models/referral_models.dart';
import 'backend_api_service.dart';

class ReferralService {
  ReferralService({BackendApiService? api}) : _api = api ?? BackendApiService();

  final BackendApiService _api;

  Future<ReferralOverview> fetchOverview() async {
    final response = await _api.get('/referral/list');
    if (response is Map<String, dynamic>) {
      return ReferralOverview.fromMap(response);
    }
    throw BackendApiException(500, 'Unexpected referral list response');
  }

  Future<void> sendInvite({
    required String email,
    String? fullName,
    String? message,
  }) async {
    final payload = <String, dynamic>{
      'email': email,
      if (fullName != null && fullName.trim().isNotEmpty) 'full_name': fullName.trim(),
      if (message != null && message.trim().isNotEmpty) 'message': message.trim(),
    };
    await _api.post('/referral/send', body: payload);
  }
}
