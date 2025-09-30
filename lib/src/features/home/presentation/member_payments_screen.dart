import 'package:flutter/material.dart';
import 'package:commipay_app/src/features/home/data/pending_payment_records_model.dart';
import 'package:commipay_app/src/features/home/data/home_service.dart';
import 'package:commipay_app/utils/app_colors.dart';

class MemberPaymentsScreen extends StatefulWidget {
  final String memberId;
  final String memberName;

  const MemberPaymentsScreen({
    super.key,
    required this.memberId,
    required this.memberName,
  });

  @override
  State<MemberPaymentsScreen> createState() => _MemberPaymentsScreenState();
}

class _MemberPaymentsScreenState extends State<MemberPaymentsScreen> {
  final HomeService _service = HomeService();

  bool _loading = true;
  int _totalPendingAmount = 0;
  int _totalPendingCount = 0;
  String? _error;
  List<PaymentGroup> _groups = [];

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final resp = await _service.fetchMemberPaymentRecords(widget.memberId);
      setState(() {
        _groups = resp.groups;
        _totalPendingAmount = resp.totalPendingAmount;
        _totalPendingCount = resp.totalPendingCount;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load payment records';
        _loading = false;
      });
    }
  }

  Future<void> _markPaid(int index) async {
    final g = _groups[index];
    final installmentId = g.installment.id;
    final backup = g.totalPendingAmount;
    // optimistic update: set to 0 while request in flight
    setState(() => g.totalPendingAmount = 0);
    try {
      // Uncomment and use real API call when ready:
      // await _service.markInstallmentPaid(
      //   memberId: widget.memberId,
      //   installmentId: installmentId,
      // );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Marked as paid — ${g.installment.id}')),
      );
    } catch (e) {
      // rollback
      setState(() => g.totalPendingAmount = backup);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not mark as paid: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.memberName,
          style: TextStyle(
            color: AppColors.darkTeal,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.darkTeal),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.darkTeal),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.hourglass_top,
                    color: AppColors.darkTeal,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '$_totalPendingCount',
                    style: const TextStyle(
                      color: AppColors.darkTeal,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadRecords,
        child: _loading
            ? ListView(
                children: const [
                  SizedBox(height: 120),
                  Center(child: CircularProgressIndicator()),
                ],
              )
            : _error != null
            ? ListView(
                children: [
                  const SizedBox(height: 80),
                  Center(
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: ElevatedButton(
                      onPressed: _loadRecords,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.darkTeal,
                      ),
                      child: const Text('Retry'),
                    ),
                  ),
                ],
              )
            : _groups.isEmpty
            ? ListView(
                children: [
                  const SizedBox(height: 80),
                  Center(
                    child: Text(
                      'No pending payments',
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                  ),
                ],
              )
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _groups.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final g = _groups[index];
                  final pending = g.totalPendingAmount;
                  final contribution = g.monthlyContribution;
                  return Material(
                    color: Colors.white,
                    elevation: 1,
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // top row: serial avatar, committee amount and due day
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: AppColors.caribbeanGreen
                                    .withOpacity(0.12),
                                child: Text(
                                  '${index + 1}',
                                  style: TextStyle(
                                    color: AppColors.caribbeanGreen,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Committee amount with rupee icon
                                    Row(
                                      children: [
                                        const Text(
                                          'Committee: ',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        const Icon(
                                          Icons.currency_rupee,
                                          size: 16,
                                          color: Colors.black87,
                                        ),
                                        const SizedBox(width: 2),
                                        Text(
                                          '${g.committee.amount}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Monthly due day: ${g.committee.monthlyDueDay}',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // amount & pending count
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.currency_rupee,
                                        size: 16,
                                        color: Colors.black87,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '$contribution',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '${g.count} pending',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),

                          const Divider(height: 18),

                          // Installment info as simple text lines (no chips)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Installment:',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Text(
                                    'Starting Bid: ',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.currency_rupee,
                                        size: 16,
                                        color: Colors.black87,
                                      ),
                                      const SizedBox(width: 2),
                                      Text('${g.installment.startingBid}'),
                                    ],
                                  ),
                                  const SizedBox(width: 16),
                                  const Text(
                                    'Winning Bid: ',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.currency_rupee,
                                        size: 16,
                                        color: Colors.black87,
                                      ),
                                      const SizedBox(width: 2),
                                      Text('${g.installment.winningBidAmount}'),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          // Pay button aligned to end with rupee icon and amount
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              ElevatedButton.icon(
                                onPressed: pending <= 0
                                    ? null
                                    : () => _markPaid(index),
                                label: Row(
                                  children: [
                                    Text('Pay'),
                                    const SizedBox(width: 10),
                                    const Icon(Icons.currency_rupee, size: 16),
                                    const SizedBox(width: 1),
                                    Text('$pending'),
                                  ],
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.darkTeal,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 10,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  elevation: 0,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
