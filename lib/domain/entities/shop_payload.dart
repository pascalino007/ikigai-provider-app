import 'package:equatable/equatable.dart';

class ShopPayload extends Equatable {
  const ShopPayload({
    required this.name,
    required this.category,
    required this.type,
    required this.address,
    required this.pays,
    required this.ville,
    required this.quartier,
    required this.phone,
    required this.email,
    required this.nonLoinDe,
    required this.descriptionShop,
    required this.profileImageUrl,
    required this.certificationImage,
    required this.galleryImages,
    required this.cfeImageUrl,
    required this.workingHours,
    required this.tags,
    required this.owner,
    required this.registeredBy,
    this.longitude,
    this.latitude,
  });

  final String name;
  final String category;
  final String type;
  final String address;
  final String pays;
  final String ville;
  final String quartier;
  final String phone;
  final String email;
  final String nonLoinDe;
  final String descriptionShop;
  final String profileImageUrl;
  final String certificationImage;
  final List<String> galleryImages;
  final String cfeImageUrl;
  final List<List<String>> workingHours;
  final String tags;
  final String owner;
  final String registeredBy;
  final double? longitude;
  final double? latitude;

  Map<String, dynamic> toJson() => {
        'name': name,
        'category': category,
        'type': type,
        'address': address,
        'pays': pays,
        'ville': ville,
        'quartier': quartier,
        'phone': phone,
        'email': email,
        'non_loin_de': nonLoinDe,
        'description_shop': descriptionShop,
        'profileImageUrl': profileImageUrl,
        'certificationImage': certificationImage,
        'galleryImages': galleryImages,
        'cfeImageUrl': cfeImageUrl,
        'workingHours': workingHours,
        'tags': tags,
        'owner': owner,
        'registered_by': registeredBy,
        if (longitude != null) 'longitude': longitude,
        if (latitude != null) 'latitude': latitude,
      };

  @override
  List<Object?> get props => [name, owner, email];
}
