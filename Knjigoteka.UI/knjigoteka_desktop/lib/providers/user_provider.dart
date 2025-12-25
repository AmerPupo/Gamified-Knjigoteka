import '../models/user.dart';
import 'base_provider.dart';

class UserProvider extends BaseProvider<User> {
  UserProvider() : super('User');

  @override
  User fromJson(data) => User.fromJson(data);

  Future<List<User>> getUsersForEmployee() async {
    return getAll();
  }

  Future<List<User>> searchUsers({String? FTS}) async {
    final params = <String, dynamic>{};
    if (FTS != null && FTS.isNotEmpty) {
      params['FTS'] = FTS;
    }
    return getAll(params: params);
  }
}
