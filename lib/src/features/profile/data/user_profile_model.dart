class UserProfile {
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

  UserProfile({
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

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      firstName: (json['firstName'] ?? '').toString(),
      lastName: json['lastName']?.toString(),
      isActive: json['isActive'] is bool
          ? (json['isActive'] as bool)
          : (json['isActive']?.toString().toLowerCase() == 'true'),
      email: json['email']?.toString(),
      role: (json['role'] ?? 'user').toString(),
      avatarUrl: json['avatarUrl']?.toString(),
      countryCode: (json['countryCode'] ?? '').toString(),
      phoneNumber: (json['phoneNumber'] ?? '').toString(),
      createdAt: (json['createdAt'] ?? '').toString(),
      updatedAt: (json['updatedAt'] ?? '').toString(),
    );
  }
}
