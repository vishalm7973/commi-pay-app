import 'package:commipay_app/src/features/home/presentation/member_payments_screen.dart';
import 'package:flutter/material.dart';
import 'package:commipay_app/src/features/home/data/pending_member_model.dart';
import 'package:commipay_app/src/features/home/data/home_service.dart';
import 'package:commipay_app/utils/app_colors.dart';

class UnpaidMembersScreen extends StatefulWidget {
  const UnpaidMembersScreen({super.key});

  @override
  State<UnpaidMembersScreen> createState() => _UnpaidMembersScreenState();
}

class _UnpaidMembersScreenState extends State<UnpaidMembersScreen> {
  final HomeService _service = HomeService();
  final ScrollController _sc = ScrollController();

  List<PendingMember> _items = [];
  int _page = 1;
  final int _limit = 20;
  int _total = 0;
  bool _loading = false;
  bool _hasMore = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPage();
    _sc.addListener(_onScroll);
  }

  @override
  void dispose() {
    _sc.removeListener(_onScroll);
    _sc.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_sc.hasClients || _loading || !_hasMore) return;
    final threshold = 200.0;
    if (_sc.position.pixels + threshold >= _sc.position.maxScrollExtent) {
      _loadPage();
    }
  }

  Future<void> _loadPage() async {
    setState(() => _loading = true);
    try {
      final resp = await _service.fetchPendingMembers(
        page: _page,
        limit: _limit,
      );
      setState(() {
        _items.addAll(resp.data);
        _total = resp.total;
        _page++;
        _hasMore = _items.length < _total;
        _error = null;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load unpaid members';
        _loading = false;
      });
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _items = [];
      _page = 1;
      _hasMore = true;
      _total = 0;
    });
    await _loadPage();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Unpaid Members',
          style: TextStyle(
            color: AppColors.darkTeal,
            fontWeight: FontWeight.w600,
            fontSize: 20,
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
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: _error != null
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(height: 60),
                  Center(
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: ElevatedButton(
                      onPressed: _refresh,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.darkTeal,
                      ),
                      child: const Text('Retry'),
                    ),
                  ),
                ],
              )
            : ListView.separated(
                controller: _sc,
                padding: const EdgeInsets.all(16),
                itemCount: _items.length + (_hasMore ? 1 : 0),
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  if (index >= _items.length) {
                    // loading indicator at bottom
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.darkTeal,
                          ),
                        ),
                      ),
                    );
                  }
                  final m = _items[index];
                  return Material(
                    borderRadius: BorderRadius.circular(10),
                    elevation: 1,
                    color: Colors.white,
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      leading: CircleAvatar(
                        backgroundColor: AppColors.vividBlue.withAlpha(
                          (0.12 * 255).round(),
                        ),
                        child: Text(
                          m.firstName.isNotEmpty
                              ? m.firstName[0].toUpperCase()
                              : '?',
                          style: TextStyle(color: AppColors.vividBlue),
                        ),
                      ),
                      title: Text(
                        m.displayName,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      subtitle: Text('${m.countryCode} ${m.phoneNumber}'),
                      trailing: SizedBox(
                        width: 120, // tune this to fit your content
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize
                                  .min, // important so Row doesn't expand
                              children: [
                                const Icon(
                                  Icons.currency_rupee,
                                  size: 16,
                                  color: AppColors.lightRed,
                                ),
                                const SizedBox(width: 2),
                                Flexible(
                                  // ensures long numbers don't overflow
                                  child: Text(
                                    '${m.totalPendingAmount} /-',
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14,
                                      color: AppColors.lightRed,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${m.pendingCount} pending',
                              textAlign: TextAlign.right,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => MemberPaymentsScreen(
                              memberId: m.id,
                              memberName: m.displayName,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
      ),
    );
  }
}
