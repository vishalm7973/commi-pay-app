class Committee {
  final String id;
  final int amount;
  final int bid;
  final String startDate;
  final String? endDate;
  final String? dueDate;
  final List<dynamic> members;
  final String createdAt;
  final String updatedAt;

  Committee({
    required this.id,
    required this.amount,
    required this.bid,
    required this.startDate,
    required this.endDate,
    required this.dueDate,
    required this.members,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Committee.fromJson(Map<String, dynamic> json) {
    return Committee(
      id: json['id'] as String,
      amount: json['amount'] is int
          ? json['amount']
          : int.tryParse(json['amount'].toString()) ?? 0,
      bid: json['bid'] != null
          ? (json['bid'] is int
                ? json['bid']
                : int.tryParse(json['bid'].toString()))
          : null,
      startDate: json['startDate'] as String,
      endDate: json['endDate'] as String?,
      dueDate: json['dueDate'] as String?,
      members: List<dynamic>.from(json['members']),
      createdAt: json['createdAt'] as String,
      updatedAt: json['updatedAt'] as String,
    );
  }
}
