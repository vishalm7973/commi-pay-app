import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:commipay_app/utils/app_colors.dart';
import '../data/user_profile_model.dart';
import '../data/profile_service.dart';
import 'package:commipay_app/utils/token_storage.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ProfileService _service = ProfileService();
  Map<String, dynamic>? _profile;
  bool _initialLoading = false; // only for first load
  bool _refreshing = false; // tracks pull-to-refresh
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProfile(initial: true);
  }

  Future<void> _loadProfile({bool initial = false}) async {
    if (initial) {
      setState(() => _initialLoading = true);
    } else {
      setState(() => _refreshing = true);
    }

    _error = null;

    try {
      final result = await _service.fetchCurrentUser();
      Map<String, dynamic> profileMap;

      if (result is UserProfile) {
        final up = result as UserProfile;
        profileMap = {
          'id': up.id,
          'firstName': up.firstName,
          'lastName': up.lastName,
          'isActive': up.isActive,
          'email': up.email,
          'role': up.role,
          'avatarUrl': up.avatarUrl,
          'countryCode': up.countryCode,
          'phoneNumber': up.phoneNumber,
          'createdAt': up.createdAt,
          'updatedAt': up.updatedAt,
        };
      } else if (result is Map) {
        final mapResult = Map<String, dynamic>.from(result);
        if (mapResult.containsKey('data') && mapResult['data'] is Map) {
          profileMap = Map<String, dynamic>.from(mapResult['data']);
        } else {
          profileMap = mapResult;
        }
      } else {
        throw Exception(
          'Unexpected profile response type: ${result.runtimeType}',
        );
      }

      if (mounted) {
        setState(() {
          _profile = profileMap;
          _initialLoading = false;
          _refreshing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _initialLoading = false;
          _refreshing = false;
        });
      }
    }
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      return DateFormat('MMM dd, yyyy').format(dt);
    } catch (_) {
      return iso;
    }
  }

  Widget _infoTile(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: AppColors.darkTeal),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    await TokenStorage.deleteToken();
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  Widget _buildProfileBody(BoxConstraints constraints) {
    String str(Map<String, dynamic> m, String key, [String fallback = '']) {
      final v = m[key];
      return v?.toString() ?? fallback;
    }

    bool boolVal(Map<String, dynamic> m, String key, [bool fallback = false]) {
      final v = m[key];
      if (v == null) return fallback;
      if (v is bool) return v;
      final s = v.toString().toLowerCase();
      return s == 'true' || s == '1';
    }

    if (_initialLoading && _profile == null) {
      return SizedBox(
        height: constraints.maxHeight,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return SizedBox(
        height: constraints.maxHeight,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Failed to load profile',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkTeal,
                  ),
                ),
                const SizedBox(height: 8),
                Text(_error!, textAlign: TextAlign.center),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => _loadProfile(initial: true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.darkTeal,
                  ),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final profile = _profile!;
    final firstName = str(profile, 'firstName');
    final lastName = str(profile, 'lastName');
    final avatarUrl = str(profile, 'avatarUrl');
    final isActive = boolVal(profile, 'isActive', true);
    final role = str(profile, 'role', 'USER');
    final email = str(profile, 'email', '-');
    final countryCode = str(profile, 'countryCode', '');
    final phoneNumber = str(profile, 'phoneNumber', '');
    final createdAt = str(profile, 'createdAt', '');

    String initial() {
      if (firstName.trim().isNotEmpty) return firstName.trim()[0].toUpperCase();
      if (lastName.trim().isNotEmpty) return lastName.trim()[0].toUpperCase();
      return '?';
    }

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(18.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 42,
                        backgroundImage: avatarUrl.isNotEmpty
                            ? NetworkImage(avatarUrl)
                            : null,
                        backgroundColor: avatarUrl.isEmpty
                            ? AppColors.darkTeal.withAlpha(30)
                            : Colors.transparent,
                        child: avatarUrl.isEmpty
                            ? Text(
                                initial(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.w700,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${firstName.isNotEmpty ? firstName : ''}${(firstName.isNotEmpty && lastName.isNotEmpty) ? ' ' : ''}${lastName.isNotEmpty ? lastName : ''}',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppColors.darkTeal,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: isActive
                                    ? AppColors.caribbeanGreen.withAlpha(30)
                                    : Colors.red.withAlpha(30),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                role.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Divider(color: Colors.grey[200]),
                  const SizedBox(height: 8),
                  _infoTile(Icons.email, 'Email', email),
                  _infoTile(
                    Icons.phone,
                    'Phone',
                    '${countryCode.isNotEmpty ? '$countryCode ' : ''}$phoneNumber',
                  ),
                  _infoTile(
                    Icons.calendar_today,
                    'Joined',
                    createdAt.isNotEmpty ? _formatDate(createdAt) : '-',
                  ),
                  // No LinearProgressIndicator here anymore
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.edit, color: Colors.white),
                  label: const Text('Edit Profile'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.greenAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _logout,
                  icon: const Icon(Icons.logout, color: Colors.white),
                  label: const Text('Logout'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Profile',
          style: TextStyle(
            color: AppColors.darkTeal,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.darkTeal,
      ),
      body: RefreshIndicator(
        onRefresh: () => _loadProfile(initial: false),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(child: _buildProfileBody(constraints)),
              ),
            );
          },
        ),
      ),
    );
  }
}
