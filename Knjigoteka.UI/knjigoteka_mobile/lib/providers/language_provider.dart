import '../models/language.dart';
import 'base_provider.dart';

class LanguageProvider extends BaseProvider<Language> {
  LanguageProvider() : super("Languages");

  @override
  Language fromJson(data) => Language.fromJson(data);

  Future<List<Language>> getLanguages() async => getAll();
}
