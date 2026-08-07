class AppUser {
  final String id;
  final String email;
  final String? name;
  final String role;

  AppUser({required this.id, required this.email, this.name, required this.role});

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: json['id'] as String,
        email: json['email'] as String,
        name: json['name'] as String?,
        role: json['role'] as String,
      );
}
