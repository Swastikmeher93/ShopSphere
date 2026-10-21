class AuthUser {
  const AuthUser({
    required this.id,
    required this.username,
    this.email,
    this.firstName,
    this.lastName,
    this.image,
  });

  final int id;
  final String username;
  final String? email;
  final String? firstName;
  final String? lastName;
  final String? image;

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
        id: json['id'] as int,
        username: json['username'] as String,
        email: json['email'] as String?,
        firstName: json['firstName'] as String?,
        lastName: json['lastName'] as String?,
        image: json['image'] as String?,
      );
}
