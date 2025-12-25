class Branch {
  final int id;
  final String name;
  final int cityId;
  final String cityName;
  final String address;
  final String phoneNumber;
  final String openingTime;
  final String closingTime;

  Branch({
    required this.id,
    required this.name,
    required this.cityId,
    required this.cityName,
    required this.address,
    required this.phoneNumber,
    required this.openingTime,
    required this.closingTime,
  });

  factory Branch.fromJson(Map<String, dynamic> json) => Branch(
    id: json['id'],
    name: json['name'],
    cityId: json['cityId'],
    cityName: json['cityName'],
    address: json['address'],
    phoneNumber: json['phoneNumber'],
    openingTime: json['openingTime'],
    closingTime: json['closingTime'],
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'cityId': cityId,
    'address': address,
    'phoneNumber': phoneNumber,
    'openingTime': openingTime,
    'closingTime': closingTime,
  };
}
