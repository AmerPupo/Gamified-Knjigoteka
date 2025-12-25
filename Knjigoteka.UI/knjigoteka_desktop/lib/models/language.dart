class Language {
  final int id;
  final String name;
  Language({required this.id, required this.name});

  factory Language.fromJson(Map<String, dynamic> json) =>
      Language(id: json['id'], name: json['name']);
}
