class AnalyticsStats {
  final int committees;
  final int members;
  final int pendingMembers;

  AnalyticsStats({
    required this.committees,
    required this.members,
    required this.pendingMembers,
  });

  factory AnalyticsStats.fromJson(Map<String, dynamic> json) {
    final data = json;
    return AnalyticsStats(
      committees: data['committees'] is int
          ? data['committees'] as int
          : int.tryParse(data['committees']?.toString() ?? '0') ?? 0,
      members: data['members'] is int
          ? data['members'] as int
          : int.tryParse(data['members']?.toString() ?? '0') ?? 0,
      pendingMembers: data['pendingMembers'] is int
          ? data['pendingMembers'] as int
          : int.tryParse(data['pendingMembers']?.toString() ?? '0') ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'committees': committees,
    'members': members,
    'pendingMembers': pendingMembers,
  };
}
