class Shop {
  Shop({
    required this.id,
    required this.name,
    required this.address,
    required this.pays,
    required this.ville,
    required this.quartier,
    required this.phone,
    required this.email,
    this.latitude,
    this.longitude,
    this.status = 'ouvert',
  });

  final int id;
  final String name;
  final String address;
  final String pays;
  final String ville;
  final String quartier;
  final String phone;
  final String email;
  final double? latitude;
  final double? longitude;
  final String status;

  factory Shop.fromJson(Map<String, dynamic> json) {
    double? toD(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      return double.tryParse('$v');
    }

    return Shop(
      id: json['id'] is int ? json['id'] as int : int.parse('${json['id']}'),
      name: '${json['name'] ?? ''}',
      address: '${json['address'] ?? ''}',
      pays: '${json['pays'] ?? ''}',
      ville: '${json['ville'] ?? ''}',
      quartier: '${json['quartier'] ?? ''}',
      phone: '${json['phone'] ?? ''}',
      email: '${json['email'] ?? ''}',
      latitude: toD(json['latitude']),
      longitude: toD(json['longitude']),
      status: '${json['status'] ?? 'ouvert'}',
    );
  }

  String get displayAddressLine {
    final parts = <String>[];
    if (address.trim().isNotEmpty) parts.add(address.trim());
    if (quartier.trim().isNotEmpty) parts.add(quartier.trim());
    if (ville.trim().isNotEmpty) parts.add(ville.trim());
    if (pays.trim().isNotEmpty) parts.add(pays.trim());
    if (parts.isEmpty && name.isNotEmpty) return name;
    return parts.join(', ');
  }
}
