import 'package:commipay_app/src/features/installments/data/installment_model.dart';
import 'package:commipay_app/src/features/installments/data/installment_service.dart';
import 'package:commipay_app/src/features/installments/presentation/add_installment_sheet.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:commipay_app/utils/app_colors.dart';
import 'package:commipay_app/src/features/committees/data/committee_service.dart';

class CommitteeInstallmentsPage extends StatefulWidget {
  final String committeeId;
  const CommitteeInstallmentsPage({super.key, required this.committeeId});

  @override
  _CommitteeInstallmentsPageState createState() =>
      _CommitteeInstallmentsPageState();
}

class _CommitteeInstallmentsPageState extends State<CommitteeInstallmentsPage> {
  bool _isLoading = true;
  bool _hasError = false;
  Map<String, dynamic>? _committeeData;

  List<Installment> _installments = [];
  bool _isLoadingInstallments = false;
  bool _hasMoreInstallments = true;
  int _currentPage = 1;
  int _total = 0;
  final int _limit = 10;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchCommitteeDetails();
    _fetchInstallments(page: _currentPage);
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchCommitteeDetails() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    try {
      final result = await CommitteeService().fetchCommitteeById(
        widget.committeeId,
      );
      setState(() {
        _committeeData = result['data'];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchInstallments({required int page}) async {
    if (_isLoadingInstallments || !_hasMoreInstallments) return;

    setState(() {
      _isLoadingInstallments = true;
    });

    try {
      final res = await InstallmentService().fetchInstallments(
        committeeId: widget.committeeId,
        page: page,
        limit: _limit,
      );
      List<Installment> newInstallments =
          res['installments'] as List<Installment>;
      final total = res['total'] as int;

      setState(() {
        _currentPage = page;
        _installments.addAll(newInstallments);
        _total = total;

        if (_installments.length >= total) {
          _hasMoreInstallments = false;
        }
        _isLoadingInstallments = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingInstallments = false;
      });
    }
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 100) {
      if (!_isLoadingInstallments && _hasMoreInstallments) {
        _fetchInstallments(page: _currentPage + 1);
      }
    }
  }

  Widget _buildInstallmentItem(Installment installment, int index) {
    final bool settled = installment.isSettled;
    final Color textColor = settled ? AppColors.darkTeal : Colors.teal.shade900;
    final Color dotColor = settled ? Colors.green : Colors.red;

    final installmentNumber = (_currentPage - 1) * _limit + index + 1;

    return InkWell(
      onTap: () {},
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 30,
              height: 30,
              margin: const EdgeInsets.only(right: 14, top: 4),
              decoration: BoxDecoration(
                color: AppColors.darkTeal.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                installmentNumber.toString(),
                style: TextStyle(
                  color: AppColors.darkTeal,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        // LEFT SIDE TEXT RESTRICTED
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              DateFormat('MMM yyyy').format(
                                DateTime(installment.year, installment.month),
                              ),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Colors.red,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "₹ ${NumberFormat("#,##0").format(installment.monthlyContribution)}",
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 22,
                                color: const Color.fromARGB(255, 5, 8, 8),
                                letterSpacing: 1.0,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ],
                        ),
                      ),
                      Flexible(
                        // RIGHT SIDE CONTAINER CONSTRAINED
                        fit: FlexFit.loose,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: settled
                                  ? AppColors.darkTeal
                                  : Colors.teal.shade900,
                              width: 1.5,
                            ),
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.transparent,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Text(
                                  settled ? "Settled" : "Unsettled",
                                  style: TextStyle(
                                    color: textColor,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: dotColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Starting Bid: ₹ ${NumberFormat("#,##0").format(installment.startingBid)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: AppColors.darkTeal,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    'Winning Bid: ₹ ${NumberFormat("#,##0").format(installment.winningBidAmount)}',
                    style: const TextStyle(
                      fontSize: 15,
                      color: AppColors.darkTeal,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    'Bidder: ${installment.winningBidder.firstName} ${installment.winningBidder.lastName}',
                    style: const TextStyle(
                      fontSize: 15,
                      color: AppColors.darkTeal,
                    ),
                  ),
                  const SizedBox(height: 7),
                  if (installment.settlementDate != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 7),
                      child: Text(
                        'Settlement Date: ${_formatDate(installment.settlementDate)}',
                        style: const TextStyle(
                          fontSize: 15,
                          color: AppColors.darkTeal,
                        ),
                      ),
                    ),
                  const Divider(height: 1, thickness: 1, color: Colors.grey),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '-';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('MMM dd, yyyy').format(date);
    } catch (_) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final members = _committeeData?['members'] as List<dynamic>? ?? [];
    final membersCount = members.length;
    final bool active = _committeeData != null
        ? _isActive(_committeeData!)
        : true;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.darkTeal),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Installments',
          style: TextStyle(
            color: AppColors.darkTeal,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
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
                    Icons.account_balance_wallet,
                    color: AppColors.darkTeal,
                    size: 18,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$_total',
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _hasError
          ? const Center(child: Text('Failed to load installments'))
          : _committeeData == null
          ? const Center(child: Text('No data'))
          : Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Card(
                    margin: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: AppColors.darkTeal),
                    ),
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(18.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Amount",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: AppColors.darkTeal,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "₹ ${_committeeData!['amount'] ?? '-'}",
                                    style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 22,
                                      color: AppColors.darkTeal,
                                    ),
                                  ),
                                ],
                              ),
                              Flexible(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: active
                                          ? AppColors.darkTeal
                                          : Colors.teal.shade900,
                                      width: 1.5,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                    color: Colors.transparent,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        active ? "Active" : "Closed",
                                        style: TextStyle(
                                          color: active
                                              ? AppColors.darkTeal
                                              : Colors.teal.shade900,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 15,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                      const SizedBox(width: 6),
                                      _statusDot(
                                        active ? Colors.green : Colors.red,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Text(
                                'Starting Bid: ₹${_committeeData!['bid'] ?? '-'}',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                  color: AppColors.darkTeal,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                'Due Day: ${_committeeData!['monthlyDueDay'] ?? '-'}',
                                style: TextStyle(
                                  fontSize: 15,
                                  color: AppColors.darkTeal,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 7),
                          Row(
                            children: [
                              Text(
                                'Start: ${_formatDate(_committeeData!['startDate'])}',
                                style: TextStyle(
                                  fontSize: 15,
                                  color: AppColors.darkTeal,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                'End: ${_formatDate(_committeeData!['endDate'])}',
                                style: TextStyle(
                                  fontSize: 15,
                                  color: AppColors.darkTeal,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            onPressed: () => _showMembersBottomSheet(members),
                            icon: const Icon(Icons.group),
                            label: Text('Members ($membersCount)'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.darkTeal,
                              minimumSize: const Size(double.infinity, 46),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: ListView.builder(
                      controller: _scrollController,
                      itemCount:
                          _installments.length + (_hasMoreInstallments ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index < _installments.length) {
                          return _buildInstallmentItem(
                            _installments[index],
                            index,
                          );
                        } else {
                          if (_isLoadingInstallments) {
                            return const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Center(child: CircularProgressIndicator()),
                            );
                          } else {
                            return const SizedBox.shrink();
                          }
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final shouldReload = await showModalBottomSheet<bool>(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
            ),
            builder: (context) => Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: AddInstallmentSheet(
                committeeId: widget.committeeId,
                members: _committeeData?['members'] ?? [],
              ),
            ),
          );
          if (shouldReload == true) {
            setState(() {
              _installments.clear();
              _currentPage = 1;
              _hasMoreInstallments = true;
            });
            _fetchInstallments(page: _currentPage);
          }
        },
        backgroundColor: AppColors.darkTeal,
        child: const Icon(Icons.add),
      ),
    );
  }

  bool _isActive(Map<String, dynamic> committeeData) {
    final endDateStr = committeeData['endDate'] as String?;
    if (endDateStr == null || endDateStr.isEmpty) return true;
    try {
      final endDate = DateTime.parse(endDateStr);
      return endDate.isAfter(DateTime.now());
    } catch (_) {
      return true;
    }
  }

  Widget _statusDot(Color color) => Container(
    width: 10,
    height: 10,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );

  Future<void> _showMembersBottomSheet(List<dynamic> members) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.75,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'Members (${members.length})',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: members.length,
                  itemBuilder: (context, index) {
                    final member = members[index];
                    final fullName =
                        '${member['firstName'] ?? ''} ${member['lastName'] ?? ''}'
                            .trim();
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 0,
                      ),
                      leading: CircleAvatar(
                        child: Text(fullName.isNotEmpty ? fullName[0] : '?'),
                      ),
                      title: Text(fullName.isNotEmpty ? fullName : 'No Name'),
                      subtitle: Text(member['phoneNumber'] ?? ''),
                      trailing: member['isActive'] == true
                          ? const Icon(Icons.check_circle, color: Colors.green)
                          : const Icon(Icons.cancel, color: Colors.red),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.darkTeal,
                    minimumSize: const Size(double.infinity, 46),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Close',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
