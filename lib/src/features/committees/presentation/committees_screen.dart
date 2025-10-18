import 'dart:async';
import 'package:commipay_app/src/features/committees/data/committee_model.dart';
import 'package:commipay_app/src/features/committees/data/committee_service.dart';
import 'package:commipay_app/src/features/committees/presentation/add_committee_sheet.dart';
import 'package:commipay_app/src/features/installments/presentation/installments_screen.dart';
import 'package:commipay_app/src/features/share/share_committee_dialog.dart';
import 'package:commipay_app/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CommitteesScreen extends StatefulWidget {
  const CommitteesScreen({super.key});

  @override
  _CommitteesScreenState createState() => _CommitteesScreenState();
}

class _CommitteesScreenState extends State<CommitteesScreen> {
  final CommitteeService _committeeService = CommitteeService();

  List<Committee> _committees = [];
  int _total = 0;

  // loading states
  bool _isLoading = false; // used for initial load / infinite scroll
  bool _isRefreshing = false; // used for pull-to-refresh

  bool _hasMore = true;
  int _page = 1;
  final int _limit = 20;
  String? _search;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  Timer? _debounce;
  int _currentRequestId = 0;

  @override
  void initState() {
    super.initState();
    _loadCommittees();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 100 &&
          !_isLoading &&
          _hasMore &&
          !_isRefreshing) {
        _loadCommittees();
      }
    });

    _searchController.addListener(() {
      if (_debounce?.isActive ?? false) _debounce!.cancel();
      _debounce = Timer(const Duration(milliseconds: 300), () {
        final search = _searchController.text.trim();
        if (search != _search) {
          _search = search;
          _page = 1;
          _hasMore = true;
          _loadCommittees();
        }
      });
    });
  }

  Future<void> _refreshCommittees() async {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
      _page = 1;
      _hasMore = true;
      // Don't clear _committees here so UI keeps showing existing items while refreshing.
      // Only show center loader when list is empty and not refreshing.
    });

    await _loadCommittees();

    if (mounted) {
      setState(() {
        _isRefreshing = false;
        // ensure isLoading false after refresh
        _isLoading = false;
      });
    }
  }

  Future<void> _loadCommittees() async {
    // If we've exhausted pages (and not a page=1 reload), bail out.
    if (!_hasMore && _page != 1) return;

    // Show manual loader only when not refreshing.
    // For initial load (empty list) we want center loader; for subsequent pages we want bottom loader.
    if (!_isRefreshing) {
      setState(() => _isLoading = true);
    }

    final requestId = ++_currentRequestId;

    try {
      final result = await _committeeService.fetchCommittees(
        page: _page,
        limit: _limit,
        search: _search,
      );

      if (requestId != _currentRequestId) return;

      final List<Committee> fetched = result['committees'] as List<Committee>;
      final int total = result['total'] as int;

      setState(() {
        _isLoading = false;

        if (_page == 1) {
          // replace list on first page (initial load or refresh)
          _committees = fetched;
          _total = total;
        } else {
          // append for subsequent pages
          _committees.addAll(fetched);
          _total = total;
        }

        if (fetched.length < _limit) {
          _hasMore = false;
        } else {
          _hasMore = true;
        }

        _page++;
      });
    } catch (e) {
      if (requestId != _currentRequestId) return;
      setState(() {
        _isLoading = false;
        // keep existing committees on error
      });
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '-';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('MMM dd, yyyy').format(date);
    } catch (_) {
      return dateStr;
    }
  }

  bool _isActive(Committee c) {
    if (c.endDate.isEmpty) return true;
    try {
      final endDate = DateTime.parse(c.endDate);
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

  Widget _buildCommitteeItem(Committee committee, int index) {
    final bool active = _isActive(committee);
    final Color textColor = active ? AppColors.darkTeal : Colors.teal.shade900;
    final Color dotColor = active ? Colors.green : Colors.red;

    final displayNumber = index + 1;

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                CommitteeInstallmentsPage(committeeId: committee.id),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.only(
          bottom: 16.0,
          left: 12,
          right: 12,
          top: 10,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 30,
              height: 30,
              margin: const EdgeInsets.only(right: 14, top: 4),
              decoration: BoxDecoration(
                color: AppColors.darkTeal.withAlpha((0.1 * 255).round()),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                displayNumber.toString(),
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Amount:",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: AppColors.darkTeal,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(
                                  Icons.currency_rupee,
                                  size: 25,
                                  color: AppColors.darkTeal,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  NumberFormat(
                                    "#,##0",
                                  ).format(committee.amount),
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 22,
                                    color: AppColors.darkTeal,
                                    letterSpacing: 1.0,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Container(
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
                          children: [
                            Text(
                              active ? "Active" : "Closed",
                              style: TextStyle(
                                color: textColor,
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(width: 6),
                            _statusDot(dotColor),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Row(
                        children: [
                          Text(
                            'Starting Bid:',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                              color: AppColors.darkTeal,
                            ),
                          ),
                          const SizedBox(width: 2),
                          const Icon(
                            Icons.currency_rupee,
                            size: 16,
                            color: AppColors.darkTeal,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '${committee.bid}',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                              color: AppColors.darkTeal,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Text(
                        'Members: ${committee.members.length}',
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
                        'Start: ${_formatDate(committee.startDate)}',
                        style: TextStyle(
                          fontSize: 15,
                          color: AppColors.darkTeal,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'End: ${_formatDate(committee.endDate)}',
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
                        'Monthly Due Day: ${committee.monthlyDueDay}',
                        style: TextStyle(
                          fontSize: 15,
                          color: AppColors.darkTeal,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Divider(height: 1, thickness: 1, color: Colors.grey.shade300),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    // optional offset to better center under appbar + search; tweak if needed
    final centerBoxHeight = (screenHeight * 0.6).round();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Committees',
          style: TextStyle(
            color: AppColors.darkTeal,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leadingWidth: 90,
        leading: Padding(
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
                Icon(Icons.group_work, color: AppColors.darkTeal, size: 18),
                const SizedBox(width: 4),
                Text(
                  '$_total',
                  style: TextStyle(
                    color: AppColors.darkTeal,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          const SizedBox(width: 12),
          IconButton(
            icon: const Icon(Icons.share, color: Colors.teal),
            onPressed: () {
              final activeCommittees = _committees.where(_isActive).toList();
              showDialog(
                context: context,
                builder: (_) =>
                    ShareCommitteeDialog(committees: activeCommittees),
              );
            },
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: GestureDetector(
        // Use translucent so child scroll views receive drag gestures
        behavior: HitTestBehavior.translucent,
        onTap: () {
          if (_searchFocusNode.hasFocus) {
            _searchFocusNode.unfocus();
          }
        },
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 18.0,
                vertical: 12,
              ),
              child: SizedBox(
                height: 48,
                child: TextField(
                  focusNode: _searchFocusNode,
                  controller: _searchController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ),
                    labelText: 'Search Amount',
                    labelStyle: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w400,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: Colors.grey.shade400,
                        width: 1,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: AppColors.darkTeal,
                        width: 2,
                      ),
                    ),
                    prefixIcon: const Icon(
                      Icons.search,
                      size: 24,
                      color: Colors.grey,
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _searchFocusNode.unfocus();
                              setState(() {
                                _search = '';
                                _page = 1;
                                _committees.clear();
                                _hasMore = true;
                              });
                              _loadCommittees();
                            },
                          )
                        : null,
                  ),
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refreshCommittees,
                child: _committees.isEmpty && _isLoading && !_isRefreshing
                    // Use a ListView so RefreshIndicator works when empty.
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          SizedBox(
                            height: centerBoxHeight.toDouble(),
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          ),
                        ],
                      )
                    : _committees.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          SizedBox(
                            height: centerBoxHeight.toDouble(),
                            child: Center(
                              child: Text(
                                'No committees found',
                                style: TextStyle(color: Colors.grey[700]),
                              ),
                            ),
                          ),
                        ],
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 8,
                        ).copyWith(bottom: 80),
                        itemCount:
                            _committees.length +
                            ((_hasMore && !_isRefreshing) ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index >= _committees.length) {
                            // show bottom loading indicator only when not refreshing
                            return Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Center(
                                child: (_hasMore && !_isRefreshing)
                                    ? const CircularProgressIndicator()
                                    : const SizedBox.shrink(),
                              ),
                            );
                          }
                          final committee = _committees[index];
                          return _buildCommitteeItem(committee, index);
                        },
                      ),
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
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
            ),
            builder: (context) => Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: AddCommitteeSheet(),
            ),
          );
          if (shouldReload == true) {
            setState(() {
              _committees.clear();
              _page = 1;
              _hasMore = true;
            });
            _loadCommittees();
          }
        },
        backgroundColor: AppColors.darkTeal,
        child: const Icon(Icons.add),
      ),
    );
  }
}
