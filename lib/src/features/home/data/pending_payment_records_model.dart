class CommitteeInfo {
  final String id;
  final int amount;
  final int monthlyDueDay;

  CommitteeInfo({
    required this.id,
    required this.amount,
    required this.monthlyDueDay,
  });

  factory CommitteeInfo.fromJson(Map<String, dynamic> json) {
    return CommitteeInfo(
      id: json['id']?.toString() ?? '',
      amount: json['amount'] is int
          ? json['amount'] as int
          : int.tryParse(json['amount']?.toString() ?? '0') ?? 0,
      monthlyDueDay: json['monthlyDueDay'] is int
          ? json['monthlyDueDay'] as int
          : int.tryParse(json['monthlyDueDay']?.toString() ?? '0') ?? 0,
    );
  }
}

class InstallmentInfo {
  final String id;
  final int startingBid;
  final int winningBidAmount;

  InstallmentInfo({
    required this.id,
    required this.startingBid,
    required this.winningBidAmount,
  });

  factory InstallmentInfo.fromJson(Map<String, dynamic> json) {
    return InstallmentInfo(
      id: json['id']?.toString() ?? '',
      startingBid: json['startingBid'] is int
          ? json['startingBid'] as int
          : int.tryParse(json['startingBid']?.toString() ?? '0') ?? 0,
      winningBidAmount: json['winningBidAmount'] is int
          ? json['winningBidAmount'] as int
          : int.tryParse(json['winningBidAmount']?.toString() ?? '0') ?? 0,
    );
  }
}

class PaymentGroup {
  final CommitteeInfo committee;
  final InstallmentInfo installment;
  final int monthlyContribution;
  final int count;
  int totalPendingAmount; // mutable so we can update after mark-as-paid

  PaymentGroup({
    required this.committee,
    required this.installment,
    required this.monthlyContribution,
    required this.count,
    required this.totalPendingAmount,
  });

  factory PaymentGroup.fromJson(Map<String, dynamic> json) {
    final payment = json['payment'] as Map<String, dynamic>? ?? {};
    return PaymentGroup(
      committee: CommitteeInfo.fromJson(
        json['committee'] as Map<String, dynamic>? ?? {},
      ),
      installment: InstallmentInfo.fromJson(
        json['installment'] as Map<String, dynamic>? ?? {},
      ),
      monthlyContribution: payment['monthlyContribution'] is int
          ? payment['monthlyContribution'] as int
          : int.tryParse(payment['monthlyContribution']?.toString() ?? '0') ??
                0,
      count: payment['count'] is int
          ? payment['count'] as int
          : int.tryParse(payment['count']?.toString() ?? '0') ?? 0,
      totalPendingAmount: payment['totalPendingAmount'] is int
          ? payment['totalPendingAmount'] as int
          : int.tryParse(payment['totalPendingAmount']?.toString() ?? '0') ?? 0,
    );
  }
}

class PendingPaymentRecordsResponse {
  final List<PaymentGroup> groups;
  final int totalPendingAmount;
  final int totalPendingCount;

  PendingPaymentRecordsResponse({
    required this.groups,
    required this.totalPendingAmount,
    required this.totalPendingCount,
  });

  factory PendingPaymentRecordsResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? {};
    final groupsList = (data['groups'] as List<dynamic>?) ?? [];
    final summary = (data['summary'] as Map<String, dynamic>?) ?? {};
    return PendingPaymentRecordsResponse(
      groups: groupsList
          .map((e) => PaymentGroup.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalPendingAmount: summary['totalPendingAmount'] is int
          ? summary['totalPendingAmount'] as int
          : int.tryParse(summary['totalPendingAmount']?.toString() ?? '0') ?? 0,
      totalPendingCount: summary['totalPendingCount'] is int
          ? summary['totalPendingCount'] as int
          : int.tryParse(summary['totalPendingCount']?.toString() ?? '0') ?? 0,
    );
  }
}
