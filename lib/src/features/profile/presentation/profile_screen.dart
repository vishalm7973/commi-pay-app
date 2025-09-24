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
  Map<String, dynamic>? _profile; // normalized profile map for UI
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  /// Loads profile and normalizes result into a Map<String, dynamic>
  Future<void> _loadProfile() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final result = await _service.fetchCurrentUser();

      Map<String, dynamic> profileMap;

      // If the service returns a UserProfile instance -> convert to map
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
        // service returned raw response map - try to find data key
        final mapResult = Map<String, dynamic>.from(result);
        if (mapResult.containsKey('data') && mapResult['data'] is Map) {
          profileMap = Map<String, dynamic>.from(mapResult['data']);
        } else {
          // maybe the service already returned the inner data
          profileMap = mapResult;
        }
      } else {
        // Unexpected shape
        throw Exception(
          'Unexpected profile response type: ${result.runtimeType}',
        );
      }

      setState(() {
        _profile = profileMap;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
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

  @override
  Widget build(BuildContext context) {
    // local helper to safely read profile fields
    String str(Map<String, dynamic> m, String key, [String fallback = '']) {
      final v = m[key];
      if (v == null) return fallback;
      return v.toString();
    }

    bool boolVal(Map<String, dynamic> m, String key, [bool fallback = false]) {
      final v = m[key];
      if (v == null) return fallback;
      if (v is bool) return v;
      final s = v.toString().toLowerCase();
      return s == 'true' || s == '1';
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.darkTeal,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadProfile,
            color: AppColors.darkTeal,
          ),
        ],
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: AppColors.darkTeal,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
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
                      onPressed: _loadProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.darkTeal,
                      ),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            )
          : _profile == null
          ? const Center(child: Text('No profile data'))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(18.0),
                      child: Builder(
                        builder: (context) {
                          // Promote local non-nullable profile map
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

                          // compute initial
                          String initial() {
                            if (firstName.trim().isNotEmpty)
                              return firstName.trim()[0].toUpperCase();
                            if (lastName.trim().isNotEmpty)
                              return lastName.trim()[0].toUpperCase();
                            return '?';
                          }

                          return Column(
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 84,
                                    height: 84,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                    ),
                                    child: avatarUrl.isNotEmpty
                                        ? CircleAvatar(
                                            radius: 42,
                                            backgroundImage: NetworkImage(
                                              avatarUrl,
                                            ),
                                            backgroundColor: Colors.transparent,
                                          )
                                        : CircleAvatar(
                                            radius: 42,
                                            backgroundColor: AppColors.darkTeal
                                                .withAlpha(
                                                  (0.12 * 255).round(),
                                                ),
                                            child: Text(
                                              initial(),
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 28,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
                                                ? AppColors.caribbeanGreen
                                                      .withAlpha(30)
                                                : Colors.red.withAlpha(30),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
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
                                '${countryCode.isNotEmpty ? countryCode + ' ' : ''}$phoneNumber',
                              ),
                              _infoTile(
                                Icons.calendar_today,
                                'Joined',
                                createdAt.isNotEmpty
                                    ? _formatDate(createdAt)
                                    : '-',
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.edit, color: Colors.black54),
                          label: const Text('Edit Profile'),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.grey.shade300),
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
                            backgroundColor: AppColors.darkTeal,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
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
