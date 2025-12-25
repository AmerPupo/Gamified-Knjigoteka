import '../models/city.dart';
import 'base_provider.dart';

class CityProvider extends BaseProvider<City> {
  CityProvider() : super('City');

  @override
  City fromJson(dynamic data) => City.fromJson(data);

  Future<List<City>> searchCities({String? fts}) async {
    final params = <String, dynamic>{};
    if (fts != null && fts.isNotEmpty) params['fts'] = fts;
    return getAll(params: params);
  }
}
