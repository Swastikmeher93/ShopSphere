class AuthUser {
  const AuthUser({
    required this.id,
    required this.username,
    this.email,
    this.firstName,
    this.lastName,
    this.image,
    this.age,
    this.gender,
    this.phone,
    this.birthDate,
    this.bloodGroup,
    this.height,
    this.weight,
    this.eyeColor,
    this.hair,
    this.address,
    this.university,
    this.company,
    this.role,
  });

  final int id;
  final String username;
  final String? email;
  final String? firstName;
  final String? lastName;
  final String? image;
  final int? age;
  final String? gender;
  final String? phone;
  final String? birthDate;
  final String? bloodGroup;
  final double? height;
  final double? weight;
  final String? eyeColor;
  final Map<String, dynamic>? hair;
  final Map<String, dynamic>? address;
  final String? university;
  final Map<String, dynamic>? company;
  final String? role;

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
        id: json['id'] as int,
        username: json['username'] as String,
        email: json['email'] as String?,
        firstName: json['firstName'] as String?,
        lastName: json['lastName'] as String?,
        image: json['image'] as String?,
        age: (json['age'] as num?)?.toInt(),
        gender: json['gender'] as String?,
        phone: json['phone'] as String?,
        birthDate: json['birthDate'] as String?,
        bloodGroup: json['bloodGroup'] as String?,
        height: (json['height'] as num?)?.toDouble(),
        weight: (json['weight'] as num?)?.toDouble(),
        eyeColor: json['eyeColor'] as String?,
        hair: json['hair'] as Map<String, dynamic>?,
        address: json['address'] as Map<String, dynamic>?,
        university: json['university'] as String?,
        company: json['company'] as Map<String, dynamic>?,
        role: json['role'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'email': email,
        'firstName': firstName,
        'lastName': lastName,
        'image': image,
        'age': age,
        'gender': gender,
        'phone': phone,
        'birthDate': birthDate,
        'bloodGroup': bloodGroup,
        'height': height,
        'weight': weight,
        'eyeColor': eyeColor,
        'hair': hair,
        'address': address,
        'university': university,
        'company': company,
        'role': role,
      };
}
