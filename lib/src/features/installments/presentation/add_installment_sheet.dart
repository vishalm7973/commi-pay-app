import 'package:commipay_app/src/features/installments/data/installment_service.dart';
import 'package:flutter/material.dart';
import 'package:commipay_app/utils/app_colors.dart';

class AddInstallmentSheet extends StatefulWidget {
  final String committeeId;
  final List<dynamic> members;

  const AddInstallmentSheet({
    Key? key,
    required this.committeeId,
    required this.members,
  }) : super(key: key);

  @override
  State<AddInstallmentSheet> createState() => _AddInstallmentSheetState();
}

class _AddInstallmentSheetState extends State<AddInstallmentSheet> {
  final _formKey = GlobalKey<FormState>();

  String? _selectedBidderId;
  String? _selectedBidderName;
  final TextEditingController _winningBidAmountController =
      TextEditingController();
  final TextEditingController _startingBidController = TextEditingController();

  bool _isSubmitting = false;
  String? _error;

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      prefixIcon: Padding(
        padding: EdgeInsets.only(left: 0, right: 8),
        child: Icon(icon, size: 18, color: Colors.grey[500]),
      ),
      prefixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 40),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      border: UnderlineInputBorder(
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      enabledBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      focusedBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: AppColors.caribbeanGreen),
      ),
    );
  }

  Future<void> _pickMember() async {
    final selected = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.75,
        child: MemberPickerSheet(members: widget.members),
      ),
    );

    if (selected != null && selected['id'] != null) {
      setState(() {
        _selectedBidderId = selected['id'] as String;
        _selectedBidderName = selected['name'] as String;
      });
    }
  }

  Future<void> _submit() async {
    if (_selectedBidderId == null || !_formKey.currentState!.validate()) {
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
      };

      final success = await InstallmentService().addInstallment(
        installmentData,
      );

      setState(() => _isSubmitting = false);
      if (success) {
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
  void dispose() {
    _winningBidAmountController.dispose();
    _startingBidController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 48,
                  height: 6,
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              Center(
                child: Text(
                  'Add Installment',
                  style: TextStyle(fontSize: 28, color: AppColors.darkTeal),
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'Winning Bidder',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[500],
                ),
              ),
              const SizedBox(height: 5),
              GestureDetector(
                onTap: _pickMember,
                child: Container(
                  width: double.infinity,
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _selectedBidderName ?? 'Select winning bidder',
                    style: TextStyle(
                      color: _selectedBidderName == null
                          ? Colors.grey[500]
                          : AppColors.darkTeal,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Winning Bid Amount',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[500],
                ),
              ),
              const SizedBox(height: 5),
              TextFormField(
                controller: _winningBidAmountController,
                decoration: _inputDecoration(
                  'Winning Bid Amount',
                  Icons.currency_rupee_rounded,
                ),
                style: TextStyle(fontSize: 16, color: AppColors.darkTeal),
                keyboardType: TextInputType.number,
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Required';
                  if (int.tryParse(val) == null) return 'Enter valid number';
                  return null;
                },
              ),
              const SizedBox(height: 18),
              Text(
                'Starting Bid',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[500],
                ),
              ),
              const SizedBox(height: 5),
              TextFormField(
                controller: _startingBidController,
                decoration: _inputDecoration(
                  'Starting Bid',
                  Icons.currency_rupee_rounded,
                ),
                style: TextStyle(fontSize: 16, color: AppColors.darkTeal),
                keyboardType: TextInputType.number,
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Required';
                  if (int.tryParse(val) == null) return 'Enter valid number';
                  return null;
                },
              ),
              const SizedBox(height: 30),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              SizedBox(
                width: double.infinity,
                height: 54,
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
                        child: const Text(
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

class MemberPickerSheet extends StatelessWidget {
  final List<dynamic> members;
  const MemberPickerSheet({Key? key, required this.members}) : super(key: key);

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
            child: ListView.builder(
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
                    child: Text(fullName.isNotEmpty ? fullName[0] : '?'),
                  ),
                  title: Text(fullName.isNotEmpty ? fullName : 'No Name'),
                  subtitle: Text(member['phoneNumber'] ?? ''),
                  trailing: member['isActive'] == true
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : const Icon(Icons.cancel, color: Colors.red),
                  onTap: () =>
                      Navigator.pop(context, {'id': id, 'name': fullName}),
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
