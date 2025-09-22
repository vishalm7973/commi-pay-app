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

  final TextEditingController _winningBidderController =
      TextEditingController();
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
      prefixIconConstraints: BoxConstraints(minWidth: 40, minHeight: 40),
      isDense: true,
      contentPadding: EdgeInsets.symmetric(vertical: 14, horizontal: 12),
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      setState(() => _error = "All fields required.");
      return;
    }
    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    final winningBidder = _winningBidderController.text.trim();
    final winningBidAmount = int.parse(_winningBidAmountController.text.trim());
    final startingBid = int.parse(_startingBidController.text.trim());
    print(' widget.committeeId: ${widget.committeeId}');

    final installmentData = {
      'committee': widget.committeeId,
      'winningBidder': winningBidder,
      'winningBidAmount': winningBidAmount,
      'startingBid': startingBid,
    };

    final success = await InstallmentService().addInstallment(installmentData);

    setState(() => _isSubmitting = false);
    if (success) {
      Navigator.pop(context, true);
    } else {
      setState(() => _error = "Failed to add committee. Try again.");
    }
  }

  @override
  void dispose() {
    _winningBidderController.dispose();
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
                  margin: EdgeInsets.only(bottom: 10),
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
              SizedBox(height: 28),

              // Winning Bidder ID
              Text(
                'Winning Bidder ID',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[500],
                ),
              ),
              SizedBox(height: 5),
              TextFormField(
                controller: _winningBidderController,
                decoration: _inputDecoration('Winning Bidder ID', Icons.person),
                style: TextStyle(fontSize: 16, color: AppColors.darkTeal),
                validator: (val) =>
                    val == null || val.isEmpty ? 'Required' : null,
              ),
              SizedBox(height: 18),

              // Winning Bid Amount
              Text(
                'Winning Bid Amount',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[500],
                ),
              ),
              SizedBox(height: 5),
              TextFormField(
                controller: _winningBidAmountController,
                decoration: _inputDecoration(
                  'Winning Bid Amount',
                  Icons.payments,
                ),
                style: TextStyle(fontSize: 16, color: AppColors.darkTeal),
                keyboardType: TextInputType.number,
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Required';
                  if (int.tryParse(val) == null) return 'Enter valid number';
                  return null;
                },
              ),
              SizedBox(height: 18),

              // Starting Bid
              Text(
                'Starting Bid',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[500],
                ),
              ),
              SizedBox(height: 5),
              TextFormField(
                controller: _startingBidController,
                decoration: _inputDecoration(
                  'Starting Bid',
                  Icons.attach_money,
                ),
                style: TextStyle(fontSize: 16, color: AppColors.darkTeal),
                keyboardType: TextInputType.number,
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Required';
                  if (int.tryParse(val) == null) return 'Enter valid number';
                  return null;
                },
              ),
              SizedBox(height: 30),

              if (_error != null)
                Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Text(_error!, style: TextStyle(color: Colors.red)),
                ),

              SizedBox(
                width: double.infinity,
                height: 54,
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
