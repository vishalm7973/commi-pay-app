import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:commipay_app/utils/app_colors.dart';
import 'package:dio/dio.dart';
import 'package:commipay_app/utils/token_storage.dart';

class InstallmentPaymentsPage extends StatefulWidget {
  final String installmentId;
  const InstallmentPaymentsPage({super.key, required this.installmentId});

  @override
  State<InstallmentPaymentsPage> createState() =>
      _InstallmentPaymentsPageState();
}

class _InstallmentPaymentsPageState extends State<InstallmentPaymentsPage> {
  bool _loading = true;
  bool _hasError = false;
  List<dynamic> _payments = [];
  int _page = 1;
  final int _limit = 10;
  bool _hasMore = true;
  bool _loadingMore = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchPayments();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchPayments({bool refresh = false}) async {
    if (_loadingMore && !refresh) return;
    if (!_hasMore && !refresh) return;

    setState(() {
      if (refresh) {
        _loading = true;
        _hasMore = true;
      } else {
        _loadingMore = true;
      }
      _hasError = false;
    });

    try {
      final token = await TokenStorage.getToken();
      final response = await Dio().get(
        'https://commi-pay.onrender.com/installment/${widget.installmentId}/payments',
        queryParameters: {'page': refresh ? 1 : _page, 'limit': _limit},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        final data = response.data['data']['data'] as List<dynamic>;
        final total = response.data['data']['total'] as int;

        setState(() {
          if (refresh) {
            _payments = data;
            _page = 1;
          } else {
            _payments.addAll(data);
          }

          _hasMore = _payments.length < total;
          if (!refresh) _page++;
          _loading = false;
          _loadingMore = false;
        });
      } else {
        throw Exception('Failed to fetch payment records');
      }
    } catch (e) {
      setState(() {
        _loading = false;
        _hasError = true;
        _loadingMore = false;
      });
    }
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 100) {
      if (!_loadingMore && _hasMore) {
        _fetchPayments();
      }
    }
  }

  Future<void> _onRefresh() async {
    await _fetchPayments(refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Installment Payments'),
        backgroundColor: Colors.white,
        iconTheme: IconThemeData(color: AppColors.darkTeal),
        elevation: 0,
        titleTextStyle: TextStyle(
          color: AppColors.darkTeal,
          fontWeight: FontWeight.w600,
          fontSize: 20,
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _hasError
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Failed to load payments'),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => _fetchPayments(refresh: true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.darkTeal,
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _onRefresh,
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(12),
                itemCount: _payments.length + (_hasMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _payments.length) {
                    if (_loadingMore) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    } else {
                      return const SizedBox.shrink();
                    }
                  }

                  final payment = _payments[index];
                  final member = payment['member'];
                  final status = payment['status'] ?? 'unknown';
                  final paymentDateRaw = payment['paymentDate'];
                  final bool isPaid = status == 'completed';
                  final paymentDate = paymentDateRaw != null
                      ? DateFormat(
                          'MMM dd, yyyy',
                        ).format(DateTime.parse(paymentDateRaw))
                      : 'Pending';

                  return Card(
                    elevation: 1,
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppColors.caribbeanGreen.withAlpha(30),
                        child: Text(
                          member['firstName'] != null &&
                                  member['firstName'].isNotEmpty
                              ? member['firstName'][0]
                              : '?',
                          style: TextStyle(color: AppColors.caribbeanGreen),
                        ),
                      ),
                      title: Text(
                        '${member['firstName'] ?? ''} ${member['lastName'] ?? ''}'
                            .trim(),
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.darkTeal,
                        ),
                      ),
                      subtitle: Text(
                        'Phone: ${member['countryCode'] ?? ''} ${member['phoneNumber'] ?? ''}\nStatus: ${isPaid ? "Paid" : "Pending"}\nDate: $paymentDate',
                        style: TextStyle(
                          color: isPaid ? Colors.green : Colors.red,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
