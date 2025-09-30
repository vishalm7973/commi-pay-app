import 'package:commipay_app/src/features/installments/data/installment_service.dart';
import 'package:flutter/material.dart';
import 'package:commipay_app/utils/app_colors.dart';

class AddInstallmentSheet extends StatefulWidget {
  final String committeeId;

  const AddInstallmentSheet({super.key, required this.committeeId});

  @override
  State<AddInstallmentSheet> createState() => _AddInstallmentSheetState();
}

class _AddInstallmentSheetState extends State<AddInstallmentSheet> {
  final _formKey = GlobalKey<FormState>();

  String? _selectedBidderId;
  String? _selectedBidderName;
  int? _selectedMonth;
  int? _selectedYear;

  final TextEditingController _winningBidAmountController =
      TextEditingController();
  final TextEditingController _startingBidController = TextEditingController();

  bool _isSubmitting = false;
  String? _error;

  // NEW: available members loaded on-demand when user taps Select Bidder
  List<dynamic> _availableMembers = [];
  bool _isLoadingMembers = false;
  String? _membersError;

  static const List<String> _monthNamesFull = [
    "January",
    "February",
    "March",
    "April",
    "May",
    "June",
    "July",
    "August",
    "September",
    "October",
    "November",
    "December",
  ];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = now.month;
    _selectedYear = now.year;

    // NO prefetch here — members load only when user taps the button
  }

  @override
  void dispose() {
    _winningBidAmountController.dispose();
    _startingBidController.dispose();
    super.dispose();
  }

  List<int> get _yearOptions {
    final now = DateTime.now();
    final current = now.year;
    return List<int>.generate(5, (i) => current - i);
  }

  List<int> _availableMonthsForYear(int? year) {
    final now = DateTime.now();
    if (year == null) return List.generate(12, (i) => i + 1);
    if (year == now.year) return List.generate(now.month, (i) => i + 1);
    return List.generate(12, (i) => i + 1);
  }

  void _ensureValidMonthForYear() {
    final available = _availableMonthsForYear(_selectedYear);
    if (_selectedMonth == null && available.isNotEmpty) {
      _selectedMonth = available.last;
    } else if (_selectedMonth != null && !available.contains(_selectedMonth)) {
      _selectedMonth = available.last;
    }
  }

  // Called only when user taps "Select Bidder"
  Future<void> _pickMember() async {
    setState(() {
      _isLoadingMembers = true;
      _membersError = null;
    });

    try {
      final res = await InstallmentService().fetchAvailableMembers(
        committeeId: widget.committeeId,
      );

      final data = res['data'] as List<dynamic>? ?? [];

      setState(() {
        _availableMembers = data;
        _isLoadingMembers = false;
      });

      if (_availableMembers.isEmpty) {
        // show friendly message — no modal opened
        final msg = _membersError ?? 'No available members';
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(msg)));
        return;
      }

      // open picker after members arrived
      final selected = await showModalBottomSheet<Map<String, dynamic>>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        builder: (context) => SizedBox(
          height: MediaQuery.of(context).size.height * 0.75,
          child: MemberPickerSheet(members: _availableMembers),
        ),
      );

      if (selected != null && selected['id'] != null) {
        setState(() {
          _selectedBidderId = selected['id'] as String;
          _selectedBidderName = selected['name'] as String;
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingMembers = false;
        _membersError = 'Failed to load members';
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_membersError!)));
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() ||
        _selectedBidderId == null ||
        _selectedMonth == null ||
        _selectedYear == null) {
      setState(() => _error = "All fields required.");
      return;
    }

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      final winningBidAmount = int.parse(
        _winningBidAmountController.text.trim(),
      );
      final startingBid = int.parse(_startingBidController.text.trim());

      final installmentData = {
        'committee': widget.committeeId,
        'winningBidder': _selectedBidderId,
        'winningBidAmount': winningBidAmount,
        'startingBid': startingBid,
        'month': _selectedMonth,
        'year': _selectedYear,
      };

      final success = await InstallmentService().addInstallment(
        installmentData,
      );

      setState(() => _isSubmitting = false);
      if (success) {
        // ignore: use_build_context_synchronously
        Navigator.pop(context, true);
      } else {
        setState(() => _error = "Failed to add installment. Try again.");
      }
    } catch (e) {
      setState(() {
        _isSubmitting = false;
        _error = "Invalid input or network error.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // auto-fix month if year change makes current month invalid
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final available = _availableMonthsForYear(_selectedYear);
      if (_selectedMonth == null && available.isNotEmpty) {
        setState(() => _selectedMonth = available.last);
      } else if (_selectedMonth != null &&
          !available.contains(_selectedMonth)) {
        setState(() => _selectedMonth = available.last);
      }
    });

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Add Installment',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _winningBidAmountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Winning Bid Amount (₹)',
                ),
                validator: (val) => val == null || val.isEmpty
                    ? 'Required'
                    : (int.tryParse(val) == null ? 'Enter valid number' : null),
              ),
              const SizedBox(height: 14),

              TextFormField(
                controller: _startingBidController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Starting Bid (₹)',
                ),
                validator: (val) => val == null || val.isEmpty
                    ? 'Required'
                    : (int.tryParse(val) == null ? 'Enter valid number' : null),
              ),
              const SizedBox(height: 14),

              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      decoration: const InputDecoration(labelText: 'Month'),
                      value: _selectedMonth,
                      items: _availableMonthsForYear(_selectedYear)
                          .map(
                            (m) => DropdownMenuItem<int>(
                              value: m,
                              child: Text(_monthNamesFull[m - 1]),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _selectedMonth = v),
                      validator: (v) => v == null ? 'Select month' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      decoration: const InputDecoration(labelText: 'Year'),
                      value: _selectedYear,
                      items: _yearOptions
                          .map(
                            (y) => DropdownMenuItem<int>(
                              value: y,
                              child: Text(y.toString()),
                            ),
                          )
                          .toList(),
                      onChanged: (v) {
                        setState(() {
                          _selectedYear = v;
                          _ensureValidMonthForYear();
                        });
                      },
                      validator: (v) => v == null ? 'Select year' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Member',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: AppColors.vividBlue,
                          ),
                        ),
                        if (_selectedBidderName != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Chip(label: Text(_selectedBidderName!)),
                          ),
                      ],
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: _isLoadingMembers ? null : _pickMember,
                    icon: _isLoadingMembers
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(Icons.person_add, color: AppColors.darkTeal),
                    label: Text(
                      _selectedBidderName == null ? "Select Bidder" : "Change",
                      style: TextStyle(color: AppColors.darkTeal),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppColors.darkTeal),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              if (_isLoadingMembers)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: LinearProgressIndicator(),
                ),

              if (_membersError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    _membersError!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),

              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),

              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: _isSubmitting
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        onPressed: _submit,
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'Add Installment',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.darkTeal,
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

/// Reuse your MemberPickerSheet (keeps single-select behavior)
class MemberPickerSheet extends StatelessWidget {
  final List<dynamic> members;
  const MemberPickerSheet({super.key, required this.members});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text(
              'Select Winning Bidder',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: members.isEmpty
                ? const Center(child: Text('No available members'))
                : ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: members.length,
                    itemBuilder: (context, index) {
                      final member = members[index];
                      final fullName =
                          '${member['firstName'] ?? ''} ${member['lastName'] ?? ''}'
                              .trim();
                      final id = member['id'] ?? member['_id'] ?? '';
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 0,
                        ),
                        leading: CircleAvatar(
                          backgroundColor: AppColors.caribbeanGreen.withAlpha(
                            (0.12 * 255).round(),
                          ),
                          child: Text(
                            fullName.isNotEmpty ? fullName[0] : '?',
                            style: TextStyle(color: AppColors.caribbeanGreen),
                          ),
                        ),
                        title: Text(fullName.isNotEmpty ? fullName : 'No Name'),
                        subtitle: Text(member['phoneNumber'] ?? ''),
                        trailing: const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                        ),
                        onTap: () => Navigator.pop(context, {
                          'id': id,
                          'name': fullName,
                        }),
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
                'Cancel',
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
    );
  }
}
