import 'package:commipay_app/src/features/installments/data/installment_service.dart';
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
  final InstallmentService _installmentService = InstallmentService();

  bool _loading = true;
  int _totalPendingCount = 0;
  int _totalPendingAmount = 0; // NEW: total pending amount across groups
  String? _error;
  List<PaymentGroup> _groups = [];

  // Local state for processing and paid
  List<bool> _isProcessing = [];
  List<bool> _isPaid = [];

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

      int totalPending = 0;
      try {
        totalPending = resp.totalPendingAmount;
      } catch (_) {
        // fallback: sum groups
        totalPending = resp.groups.fold<int>(
          0,
          (sum, g) => sum + (g.totalPendingAmount),
        );
      }

      setState(() {
        _groups = resp.groups;
        _totalPendingCount = resp.totalPendingCount;
        _totalPendingAmount = totalPending;
        _loading = false;

        // Initialize local state arrays
        _isProcessing = List<bool>.filled(_groups.length, false);
        _isPaid = List<bool>.filled(_groups.length, false);
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load payment records';
        _loading = false;
      });
    }
  }

  Future<void> _markPaid(int index) async {
    // Prevent double click
    if (_isProcessing[index] || _isPaid[index]) return;

    setState(() => _isProcessing[index] = true);

    final g = _groups[index];

    try {
      final success = await _installmentService.markInstallmentPaid(
        installmentId: g.installment.id,
        memberId: widget.memberId,
      );

      if (!mounted) return;

      if (success) {
        // Update local states and totals
        setState(() {
          _isProcessing[index] = false;
          _isPaid[index] = true;
          // subtract group's pending amount from total
          final removed = g.totalPendingAmount;
          g.totalPendingAmount = 0;
          _totalPendingAmount = (_totalPendingAmount - removed).clamp(
            0,
            1 << 60,
          );
          _totalPendingCount = (_totalPendingCount - (g.count)).clamp(
            0,
            1 << 60,
          );
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.check_circle, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text('Marked as paid', textAlign: TextAlign.center),
              ],
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      setState(() => _isProcessing[index] = false);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  'Could not mark as paid: ${e.toString()}',
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final showInitialLoader = _loading && _groups.isEmpty;

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
          const SizedBox(width: 12),
          IconButton(
            icon: const Icon(Icons.share, color: Colors.teal),
            onPressed: () {},
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadRecords,
        child: showInitialLoader
            ? ListView(
                children: const [
                  SizedBox(height: 120),
                  Center(child: CircularProgressIndicator()),
                ],
              )
            : _error != null && _groups.isEmpty
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
                padding: const EdgeInsets.all(16),
                children: [
                  // header with totals even when list empty
                  _buildTotalsHeader(),
                  const SizedBox(height: 12),
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
                itemCount: _groups.length + 1, // +1 for header row (totals)
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, idx) {
                  if (idx == 0) {
                    return _buildTotalsHeader();
                  }

                  final g = _groups[idx - 1];
                  return _buildGroupCard(context, g, idx - 1);
                },
              ),
      ),
    );
  }

  Widget _buildTotalsHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 6),
        Text(
          'Overview',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.darkTeal,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                title: 'Total Amount',
                value: '₹ $_totalPendingAmount',
                icon: Icons.account_balance_wallet,
                color: AppColors.vividBlue,
                onTap: () {},
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                title: 'Total Count',
                value: _totalPendingCount.toString(),
                icon: Icons.hourglass_top,
                color: Colors.orange.shade700,
                onTap: () {},
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Divider(color: Colors.grey.shade300, thickness: 1),

        const SizedBox(height: 18),
        Text(
          'Installments',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.darkTeal,
          ),
        ),
      ],
    );
  }

  Widget _buildGroupCard(BuildContext context, PaymentGroup g, int groupIndex) {
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
            // top row
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.caribbeanGreen.withAlpha(
                    (0.12 * 255).round(),
                  ),
                  child: Text(
                    '${groupIndex + 1}',
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
                      Row(
                        children: [
                          const Text(
                            'Committee: ',
                            style: TextStyle(fontWeight: FontWeight.w700),
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
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Monthly due day: ${g.committee.monthlyDueDay}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.currency_rupee,
                          size: 16,
                          color: Colors.black87,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '$contribution',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${g.count} pending',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),

            const Divider(height: 18),

            // Installment info
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Installment:',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text(
                      'Starting Bid: ',
                      style: TextStyle(color: Colors.grey),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
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
                      mainAxisSize: MainAxisSize.min,
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

            // Pay button
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton(
                  onPressed:
                      _isPaid[groupIndex] ||
                          _isProcessing[groupIndex] ||
                          (pending) <= 0
                      ? null
                      : () => _markPaid(groupIndex),
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
                  child: _isProcessing[groupIndex]
                      ? const Text('Processing')
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(_isPaid[groupIndex] ? 'Paid' : 'Pay'),
                            if (!_isPaid[groupIndex]) ...[
                              const SizedBox(width: 6),
                              const Icon(Icons.currency_rupee, size: 16),
                              const SizedBox(width: 2),
                              Text('$pending'),
                            ],
                          ],
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// small stat card used in header row
class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      elevation: 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.max,
            children: [
              // Small icon container
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withAlpha((0.12 * 255).round()),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Center(child: Icon(icon, color: color, size: 20)),
              ),
              const SizedBox(width: 10),
              // Title and value
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.darkTeal,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
