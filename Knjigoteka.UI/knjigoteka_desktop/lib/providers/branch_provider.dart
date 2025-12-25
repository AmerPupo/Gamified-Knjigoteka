import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:knjigoteka_desktop/providers/auth_provider.dart';
import '../models/branch.dart';
import 'base_provider.dart';

class BranchProvider extends BaseProvider<Branch> {
  static String _baseUrl = const String.fromEnvironment(
    "baseUrl",
    defaultValue: 'http://localhost:7295/api',
  );
  BranchProvider() : super('Branches');

  @override
  Branch fromJson(data) => Branch.fromJson(data);

  Future<List<Branch>> searchBranches({String? fts}) async {
    final params = <String, dynamic>{};
    if (fts != null && fts.isNotEmpty) params['fts'] = fts;
    return getAll(params: params);
  }

  Future<Map<String, dynamic>> getReport({
    required int branchId,
    DateTime? from,
    DateTime? to,
  }) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/Branches/$branchId/report'),
      headers: {
        'Content-Type': 'application/json',
        if (AuthProvider.token != null)
          'Authorization': 'Bearer ${AuthProvider.token}',
      },
      body: jsonEncode({
        "from": from?.toIso8601String(),
        "to": to?.toIso8601String(),
      }),
    );
    if (res.statusCode != 200) throw Exception(res.body);
    return jsonDecode(res.body);
  }
}
