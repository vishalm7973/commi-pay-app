import 'dart:async';

import 'package:commipay_app/src/features/home/presentation/member_payments_screen.dart';
import 'package:commipay_app/src/features/members/data/member_model.dart';
import 'package:commipay_app/src/features/members/data/member_service.dart';
import 'package:commipay_app/src/features/members/presentation/add_member_sheet.dart';
import 'package:commipay_app/utils/app_colors.dart';
import 'package:flutter/material.dart';

class MembersScreen extends StatefulWidget {
  const MembersScreen({super.key});

  @override
  _MembersScreenState createState() => _MembersScreenState();
}

class _MembersScreenState extends State<MembersScreen> {
  final MemberService _memberService = MemberService();

  List<Member> _members = [];
  int _total = 0;
  bool _isLoading = false;
  bool _hasMore = true;
  int _page = 1;
  final int _limit = 20;
  String? _search;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  Timer? _debounce;
  int _currentRequestId = 0; // To track latest API requests

  @override
  void initState() {
    super.initState();
    _loadMembers();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 100 &&
          !_isLoading &&
          _hasMore) {
        _loadMembers();
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
          _loadMembers();
        }
      });
    });
  }

  Future<void> _loadMembers() async {
    if (!_hasMore) return;
    setState(() => _isLoading = true);

    final requestId = ++_currentRequestId; // increment request id

    try {
      final result = await _memberService.fetchMembers(
        page: _page,
        limit: _limit,
        search: _search,
      );

      final List<Member> fetched = result['members'] as List<Member>;
      final int total = result['total'] as int;

      // Ignore if not latest request
      if (requestId != _currentRequestId) return;

      setState(() {
        _isLoading = false;
        if (_page == 1) {
          _members = fetched;
          _total = total;
        } else {
          _members.addAll(fetched);
          _total = total;
        }
        if (fetched.length < _limit) {
          _hasMore = false;
        }
        _page++;
      });
    } catch (e) {
      if (requestId != _currentRequestId) return;
      setState(() => _isLoading = false);
      // Optionally show error UI
    }
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
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Members',
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
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.darkTeal),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.group, color: AppColors.darkTeal, size: 18),
                  SizedBox(width: 4),
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
        ],
      ),

      body: GestureDetector(
        onTap: () {
          if (_searchFocusNode.hasFocus) {
            _searchFocusNode.unfocus();
          }
        },
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: SizedBox(
                height: 50,
                child: TextField(
                  focusNode: _searchFocusNode,
                  controller: _searchController,
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 12,
                    ),
                    labelText: 'Search',
                    prefixIcon: Icon(Icons.search, size: 20),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _searchFocusNode.unfocus();
                              setState(() {
                                _search = '';
                                _page = 1;
                                _members.clear();
                                _hasMore = true;
                              });
                              _loadMembers();
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(),
                    ),
                  ),
                  style: TextStyle(fontSize: 14),
                ),
              ),
            ),
            Expanded(
              child: _members.isEmpty && _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      controller: _scrollController,
                      padding: EdgeInsets.only(
                        bottom: 80,
                      ), // Adjust height as needed (e.g., FAB height + extra space)
                      itemCount: _members.length + (_hasMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index >= _members.length) {
                          return Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        final member = _members[index];
                        final fullName =
                            '${member.firstName} ${member.lastName ?? ''}'
                                .trim();
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppColors.caribbeanGreen.withAlpha(
                              (0.12 * 255).round(),
                            ),
                            child: Text(
                              fullName.isNotEmpty
                                  ? fullName[0].toUpperCase()
                                  : '?',
                              style: TextStyle(color: AppColors.caribbeanGreen),
                            ),
                          ),
                          title: Text(
                            fullName,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          subtitle: Text(
                            '${member.countryCode} ${member.phoneNumber}',
                          ),
                          trailing: const Icon(
                            Icons.phone,
                            color: Colors.green,
                          ),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => MemberPaymentsScreen(
                                  memberId: member.id,
                                  memberName: member.displayName,
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await showModalBottomSheet<bool>(
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
              child: AddMemberSheet(),
            ),
          );

          if (result == true) {
            setState(() {
              _page = 1;
              _members.clear();
              _hasMore = true;
            });
            _loadMembers();
          }
        },
        backgroundColor: AppColors.darkTeal,
        child: Icon(Icons.add),
      ),
    );
  }
}
