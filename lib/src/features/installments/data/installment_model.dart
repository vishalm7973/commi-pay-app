class Installment {
  final String id;
  final String committeeId;
  final int month;
  final int year;
  final int monthlyContribution;
  final int startingBid;
  final int winningBidAmount;
  final WinningBidder winningBidder;
  final bool isSettled;
  final String? settlementDate;
  final String createdBy;
  final String createdAt;
  final String updatedAt;

  Installment({
    required this.id,
    required this.committeeId,
    required this.month,
    required this.year,
    required this.monthlyContribution,
    required this.startingBid,
    required this.winningBidder,
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
      month: json['month'] as int,
      year: json['year'] as int,
      winningBidder: WinningBidder.fromJson(json['winningBidder']),
      winningBidAmount: json['winningBidAmount'] as int,
      isSettled: json['isSettled'] as bool,
      settlementDate: json['settlementDate'] as String?,
      createdBy: json['createdBy'] as String,
      createdAt: json['createdAt'] as String,
      updatedAt: json['updatedAt'] as String,
    );
  }
}

class WinningBidder {
  final String id;
  final String firstName;
  final String? lastName;
  final String countryCode;
  final String phoneNumber;

  WinningBidder({
    required this.id,
    required this.firstName,
    this.lastName,
    required this.countryCode,
    required this.phoneNumber,
  });

  factory WinningBidder.fromJson(Map<String, dynamic> json) {
    return WinningBidder(
      id: json['id'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String?,
      countryCode: json['countryCode'] as String,
      phoneNumber: json['phoneNumber'] as String,
    );
  }
}
