import 'package:commipay_app/src/features/home/data/analytics_stats_model.dart';
import 'package:commipay_app/src/features/home/data/home_service.dart';
import 'package:commipay_app/src/features/home/data/pending_member_model.dart';
import 'package:commipay_app/src/features/home/presentation/member_payments_screen.dart';
import 'package:commipay_app/src/features/home/presentation/unpaid_members_page.dart';
import 'package:flutter/material.dart';
import 'package:commipay_app/utils/app_colors.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final HomeService _service = HomeService();

  bool _loading = true;
  String? _error;
  AnalyticsStats? _stats;

  // For quick unpaid members preview (top 5)
  bool _loadingPendingPreview = true;
  String? _pendingPreviewError;
  List<PendingMember> _pendingPreviewItems = [];

  @override
  void initState() {
    super.initState();
    _loadStats();
    _loadPendingPreview();
  }

  Future<void> _loadStats() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final s = await _service.fetchStats();
      setState(() {
        _stats = s;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load dashboard';
        _loading = false;
      });
    }
  }

  Future<void> _loadPendingPreview() async {
    setState(() {
      _loadingPendingPreview = true;
      _pendingPreviewError = null;
    });
    try {
      final resp = await _service.fetchPendingMembers(page: 1, limit: 5);
      setState(() {
        _pendingPreviewItems = resp.data;
        _loadingPendingPreview = false;
      });
    } catch (e) {
      setState(() {
        _pendingPreviewError = 'Failed to load unpaid members';
        _loadingPendingPreview = false;
      });
    }
  }

  Future<void> _refreshAll() async {
    await Future.wait([_loadStats(), _loadPendingPreview()]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Dashboard',
          style: TextStyle(
            color: AppColors.darkTeal,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _refreshAll,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading && _stats == null) {
      return SizedBox(
        height: MediaQuery.of(context).size.height - 120,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null && _stats == null) {
      return SizedBox(
        height: MediaQuery.of(context).size.height - 120,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _loadStats,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.darkTeal,
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final stats = _stats!;
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

        // Stats rows (same compact cards)
        Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    title: 'Committees',
                    value: stats.committees.toString(),
                    icon: Icons.group_work,
                    color: AppColors.vividBlue,
                    onTap: () {},
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    title: 'Members',
                    value: stats.members.toString(),
                    icon: Icons.people_alt,
                    color: AppColors.darkTeal,
                    onTap: () {},
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _StatCard(
              title: 'Total Unpaid Members',
              value: stats.pendingMembers.toString(),
              icon: Icons.hourglass_top,
              color: Colors.orange.shade700,
              onTap: () {},
            ),
          ],
        ),

        const SizedBox(height: 18),
        Divider(color: Colors.grey.shade300, thickness: 1),

        // Unpaid members heading with See All
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Unpaid Members',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.darkTeal,
              ),
            ),
            InkWell(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const UnpaidMembersScreen(),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                child: Text(
                  'See All',
                  style: TextStyle(
                    color: AppColors.vividBlue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Replace buttons with a compact list (limit 5 preview)
        if (_loadingPendingPreview)
          const SizedBox(
            height: 60,
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_pendingPreviewError != null)
          Column(
            children: [
              Text(
                _pendingPreviewError!,
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _loadPendingPreview,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.darkTeal,
                ),
                child: const Text('Retry'),
              ),
            ],
          )
        else if (_pendingPreviewItems.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'No unpaid members',
              style: TextStyle(color: Colors.grey[700]),
            ),
          )
        else
          Column(
            children: _pendingPreviewItems.map((m) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Material(
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
                ),
              );
            }).toList(),
          ),

        const SizedBox(height: 18),
      ],
    );
  }
}

/// Compact stat card widget
class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
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
