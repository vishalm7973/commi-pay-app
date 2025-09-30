class PendingMember {
  final String id;
  final String firstName;
  final String? lastName;
  final String phoneNumber;
  final String countryCode;
  final int totalPendingAmount;
  final int pendingCount;

  PendingMember({
    required this.id,
    required this.firstName,
    this.lastName,
    required this.phoneNumber,
    required this.countryCode,
    required this.totalPendingAmount,
    required this.pendingCount,
  });

  String get displayName =>
      (firstName + (lastName != null ? ' $lastName' : '')).trim();

  factory PendingMember.fromJson(Map<String, dynamic> json) {
    return PendingMember(
      id: json['id']?.toString() ?? '',
      firstName: json['firstName']?.toString() ?? '',
      lastName: json['lastName']?.toString(),
      phoneNumber: json['phoneNumber']?.toString() ?? '',
      countryCode: json['countryCode']?.toString() ?? '',
      totalPendingAmount: json['totalPendingAmount'] is int
          ? json['totalPendingAmount'] as int
          : int.tryParse(json['totalPendingAmount']?.toString() ?? '0') ?? 0,
      pendingCount: json['pendingCount'] is int
          ? json['pendingCount'] as int
          : int.tryParse(json['pendingCount']?.toString() ?? '0') ?? 0,
    );
  }
}

class PendingMembersPageResponse {
  final List<PendingMember> data;
  final int total;
  final int page;
  final int limit;

  PendingMembersPageResponse({
    required this.data,
    required this.total,
    required this.page,
    required this.limit,
  });

  factory PendingMembersPageResponse.fromJson(Map<String, dynamic> json) {
    final d = json['data'] as Map<String, dynamic>? ?? {};
    final list = (d['data'] as List<dynamic>?) ?? [];
    return PendingMembersPageResponse(
      data: list
          .map((e) => PendingMember.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: d['total'] is int
          ? d['total'] as int
          : int.tryParse(d['total']?.toString() ?? '0') ?? 0,
      page: d['page'] is int
          ? d['page'] as int
          : int.tryParse(d['page']?.toString() ?? '1') ?? 1,
      limit: d['limit'] is int
          ? d['limit'] as int
          : int.tryParse(d['limit']?.toString() ?? '10') ?? 10,
    );
  }
}
