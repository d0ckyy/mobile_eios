import 'package:eios/core/network/api_service.dart';
import 'package:eios/data/models/user_model.dart';

class UserRepository {
  final _api = ApiClient();

  Future<UserModel> getUserProfile() async {
    try {
      final response = await _api.get('/v1/User');
      return UserModel.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }
}
