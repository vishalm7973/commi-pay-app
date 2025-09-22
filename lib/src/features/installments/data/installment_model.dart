class Installment {
  final String id;
  final String committeeId;
  final int monthlyContribution;
  final int startingBid;
  final int winningBidAmount;
  final bool isSettled;
  final String? settlementDate;
  final String createdBy;
  final String createdAt;
  final String updatedAt;

  Installment({
    required this.id,
    required this.committeeId,
    required this.monthlyContribution,
    required this.startingBid,
    required this.winningBidAmount,
    required this.isSettled,
    this.settlementDate,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Installment.fromJson(Map<String, dynamic> json) {
    return Installment(
      id: json['id'] as String,
      committeeId: json['committee'] as String,
      monthlyContribution: json['monthlyContribution'] as int,
      startingBid: json['startingBid'] as int,
      winningBidAmount: json['winningBidAmount'] as int,
      isSettled: json['isSettled'] as bool,
      settlementDate: json['settlementDate'] as String?,
      createdBy: json['createdBy'] as String,
      createdAt: json['createdAt'] as String,
      updatedAt: json['updatedAt'] as String,
    );
  }
}