import 'package:pocketllm/services/backend_api_service.dart';
import 'package:pocketllm/models/referral_models.dart';

class ReferralService {
  final _api = BackendApiService();

  Future<ReferralOverview> fetchOverview() async {
    final response = await _api.get('/v1/referral/list');
    return ReferralOverview.fromJson(response.data);
  }

  Future<void> sendInvite({
    required String email,
    String? fullName,
    String? message,
  }) async {
    await _api.post('/v1/referral/send', {
      'email': email,
      'full_name': fullName,
      'message': message,
    });
  }
}
