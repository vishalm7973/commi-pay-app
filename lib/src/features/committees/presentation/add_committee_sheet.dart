import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:commipay_app/utils/app_colors.dart';
import 'package:commipay_app/src/features/committees/data/committee_service.dart';
import 'package:commipay_app/src/features/members/data/member_model.dart';
import 'package:commipay_app/src/features/members/data/member_service.dart';

class AddCommitteeSheet extends StatefulWidget {
  @override
  State<AddCommitteeSheet> createState() => _AddCommitteeSheetState();
}

class _AddCommitteeSheetState extends State<AddCommitteeSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _bidController = TextEditingController();
  DateTime? _startDate;
  int? _dueDay;
  List<String> _selectedMemberIds = [];

  bool _isSubmitting = false;
  String? _error;
  List<Member> _members = [];
  bool _loadingMembers = false;

  @override
  void initState() {
    super.initState();
    _fetchMembers();
  }

  Future<void> _fetchMembers() async {
    setState(() => _loadingMembers = true);
    try {
      final result = await MemberService().fetchMembers(page: 1, limit: 200);
      final List<Member> fetched = result['members'] as List<Member>;
      _members = fetched;
    } finally {
      setState(() => _loadingMembers = false);
    }
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _startDate = picked);
    }
  }

  Future<void> _openMemberPicker() async {
    final result = await showDialog<List<String>>(
      context: context,
      builder: (ctx) => MemberPickerDialog(
        allMembers: _members,
        alreadySelected: List<String>.from(_selectedMemberIds),
      ),
    );
    if (result != null) {
      setState(() {
        _selectedMemberIds = result;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() ||
        _startDate == null ||
        _dueDay == null ||
        _selectedMemberIds.isEmpty) {
      setState(() => _error = "All fields required.");
      return;
    }
    setState(() {
      _isSubmitting = true;
      _error = null;
    });
    final request = {
      "amount": int.tryParse(_amountController.text),
      "bid": int.tryParse(_bidController.text),
      "startDate": _startDate!.toUtc().toIso8601String(),
      "monthlyDueDay": _dueDay,
      "members": _selectedMemberIds,
    };
    final success = await CommitteeService().addCommittee(request);
    setState(() => _isSubmitting = false);
    if (success) {
      Navigator.pop(context, true);
    } else {
      setState(() => _error = "Failed to add committee. Try again.");
    }
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    child: SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Add Committee',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'Amount (₹)'),
              validator: (val) =>
                  val == null || val.isEmpty ? 'Required' : null,
            ),
            SizedBox(height: 14),
            TextFormField(
              controller: _bidController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'Bid (₹)'),
              validator: (val) =>
                  val == null || val.isEmpty ? 'Required' : null,
            ),
            SizedBox(height: 14),
            DropdownButtonFormField<int>(
              decoration: InputDecoration(labelText: 'Due Day (1-31)'),
              initialValue: _dueDay,
              items: List.generate(31, (i) {
                final day = i + 1;
                return DropdownMenuItem(
                  value: day,
                  child: Text(day.toString()),
                );
              }),
              onChanged: (val) => setState(() => _dueDay = val!),
              validator: (val) => val == null ? 'Select a due day' : null,
            ),
            SizedBox(height: 14),
            Row(
              children: [
                Expanded(child: Text('Start Date:')),
                TextButton(
                  onPressed: () => _selectDate(context, true),
                  child: Text(
                    _startDate == null
                        ? 'Select'
                        : DateFormat('MMM dd, yyyy').format(_startDate!),
                  ),
                ),
              ],
            ),
            SizedBox(height: 18),
            _loadingMembers
                ? CircularProgressIndicator()
                : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Members: ${_members.length}',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: AppColors.vividBlue,
                              ),
                            ),
                            if (_selectedMemberIds.isNotEmpty)
                              Text(
                                'Selected: ${_selectedMemberIds.length}',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: AppColors.caribbeanGreen,
                                ),
                              ),
                          ],
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: _members.isEmpty ? null : _openMemberPicker,
                        icon: Icon(
                          Icons.group_add_outlined,
                          color: AppColors.darkTeal,
                        ),
                        label: Text(
                          "Select Members",
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
            if (_selectedMemberIds.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(top: 6),
                child: Wrap(
                  spacing: 5,
                  children: _members
                      .where((m) => _selectedMemberIds.contains(m.id))
                      .map(
                        (m) => Chip(
                          label: Text(
                            '${m.firstName}${m.lastName != null && m.lastName!.isNotEmpty ? " ${m.lastName!}" : ""}',
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            if (_error != null)
              Padding(
                padding: EdgeInsets.only(top: 10),
                child: Text(_error!, style: TextStyle(color: Colors.red)),
              ),
            SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: _isSubmitting
                  ? Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Add Committee',
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

/// Fullscreen member picker dialog
class MemberPickerDialog extends StatefulWidget {
  final List<Member> allMembers;
  final List<String> alreadySelected;

  const MemberPickerDialog({
    required this.allMembers,
    required this.alreadySelected,
    Key? key,
  }) : super(key: key);

  @override
  State<MemberPickerDialog> createState() => _MemberPickerDialogState();
}

class _MemberPickerDialogState extends State<MemberPickerDialog> {
  late List<String> _selectedIds;

  @override
  void initState() {
    super.initState();
    _selectedIds = widget.alreadySelected.toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Select Members',
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
            child: TextButton(
              onPressed: () => Navigator.pop(context, _selectedIds),
              child: Text(
                "Done",
                style: TextStyle(color: AppColors.darkTeal, fontSize: 15),
              ),
            ),
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: widget.allMembers.length,
        itemBuilder: (ctx, idx) {
          final m = widget.allMembers[idx];
          final selected = _selectedIds.contains(m.id);
          return CheckboxListTile(
            value: selected,
            title: Text('${m.firstName} ${m.lastName ?? ""}'),
            subtitle: Text(m.phoneNumber),
            secondary: CircleAvatar(
              backgroundImage: m.avatarUrl != null && m.avatarUrl!.isNotEmpty
                  ? NetworkImage(m.avatarUrl!)
                  : null,
              child: (m.avatarUrl == null || m.avatarUrl!.isEmpty)
                  ? Icon(Icons.person)
                  : null,
            ),
            onChanged: (checked) {
              setState(() {
                if (checked == true)
                  _selectedIds.add(m.id);
                else
                  _selectedIds.remove(m.id);
              });
            },
          );
        },
      ),
    );
  }
}
