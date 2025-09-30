class Member {
  final String id;
  final String firstName;
  final String? lastName;
  final bool isActive;
  final String? email;
  final String role;
  final String? avatarUrl;
  final String countryCode;
  final String phoneNumber;
  final String createdAt;
  final String updatedAt;

  Member({
    required this.id,
    required this.firstName,
    this.lastName,
    required this.isActive,
    this.email,
    required this.role,
    this.avatarUrl,
    required this.countryCode,
    required this.phoneNumber,
    required this.createdAt,
    required this.updatedAt,
  });

  String get displayName =>
      (firstName + (lastName != null ? ' $lastName' : '')).trim();

  factory Member.fromJson(Map<String, dynamic> json) {
    return Member(
      id: json['id'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String?,
      isActive: json['isActive'] as bool,
      email: json['email'] as String?,
      role: json['role'] as String,
      avatarUrl: json['avatarUrl'] as String?,
      countryCode: json['countryCode'] as String,
      phoneNumber: json['phoneNumber'] as String,
      createdAt: json['createdAt'] as String,
      updatedAt: json['updatedAt'] as String,
    );
  }
}
