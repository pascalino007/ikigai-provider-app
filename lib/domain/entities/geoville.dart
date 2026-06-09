class Geoville {
  Geoville({
    required this.id,
    required this.countryId,
    required this.regionId,
    this.cityId,
    this.districtId,
    required this.name,
    required this.isActive,
  });

  final int id;
  final String countryId;
  final String regionId;
  final String? cityId;
  final String? districtId;
  final String name;
  final bool isActive;

  factory Geoville.fromJson(Map<String, dynamic> json) {
    return Geoville(
      id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}') ?? 0,
      countryId: '${json['countryId'] ?? ''}',
      regionId: '${json['regionId'] ?? ''}',
      cityId: json['cityId'] != null ? '${json['cityId']}' : null,
      districtId: json['districtId'] != null ? '${json['districtId']}' : null,
      name: '${json['name'] ?? ''}',
      isActive: json['isActive'] == true || json['isActive'] == 1,
    );
  }
}
