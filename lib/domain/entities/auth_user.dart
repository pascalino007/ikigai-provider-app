import 'package:equatable/equatable.dart';

class AuthUser extends Equatable {
  const AuthUser({
    required this.id,
    required this.email,
    required this.firstname,
    required this.lastname,
    required this.phone,
    required this.role,
    this.image = '',
    this.shopId,
  });

  final int id;
  final String email;
  final String firstname;
  final String lastname;
  final String phone;
  final String role;
  final String image;
  final int? shopId;

  factory AuthUser.fromJson(Map<String, dynamic> json, {int? shopId}) {
    return AuthUser(
      id: json['id'] is int ? json['id'] as int : int.parse('${json['id']}'),
      email: '${json['email'] ?? ''}',
      firstname: '${json['firstname'] ?? ''}',
      lastname: '${json['lastname'] ?? ''}',
      phone: '${json['phone'] ?? ''}',
      role: '${json['role'] ?? 'provider'}',
      image: '${json['image'] ?? ''}',
      shopId: shopId,
    );
  }

  AuthUser copyWith({int? shopId}) {
    return AuthUser(
      id: id,
      email: email,
      firstname: firstname,
      lastname: lastname,
      phone: phone,
      role: role,
      image: image,
      shopId: shopId ?? this.shopId,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'firstname': firstname,
        'lastname': lastname,
        'phone': phone,
        'role': role,
        'image': image,
        'shopId': shopId,
      };

  @override
  List<Object?> get props => [id, email, firstname, lastname, phone, role, image, shopId];
}
