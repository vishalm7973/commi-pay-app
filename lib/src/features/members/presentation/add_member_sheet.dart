import 'package:flutter/material.dart';
import 'package:commipay_app/utils/app_colors.dart';
import '../data/member_service.dart';
import 'package:country_code_picker/country_code_picker.dart';

class AddMemberSheet extends StatefulWidget {
  const AddMemberSheet({super.key});

  @override
  State<AddMemberSheet> createState() => _AddMemberSheetState();
}

class _AddMemberSheetState extends State<AddMemberSheet> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _countryCodeController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _isLoading = false;
  String? _error;
  String _selectedCountryCode = '+91';

  @override
  void initState() {
    super.initState();
    _selectedCountryCode = '+91'; // default
    _countryCodeController.text = _selectedCountryCode;
  }

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

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final success = await MemberService().addMember(
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      countryCode: _countryCodeController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
    );

    setState(() => _isLoading = false);

    if (success) {
      Navigator.pop(context, true); // Close sheet on success
    } else {
      setState(() => _error = "Failed to add member. Try again.");
    }
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
                  'Add Member',
                  style: TextStyle(fontSize: 28, color: AppColors.darkTeal),
                ),
              ),
              SizedBox(height: 28),
              Text(
                'First Name',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[500],
                ),
              ),
              SizedBox(height: 5),
              TextFormField(
                controller: _firstNameController,
                decoration: _inputDecoration('First Name', Icons.person),
                style: TextStyle(fontSize: 16, color: AppColors.darkTeal),
                textCapitalization: TextCapitalization.words,
                validator: (val) =>
                    val == null || val.isEmpty ? 'Required' : null,
              ),
              SizedBox(height: 18),
              Text(
                'Last Name',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[500],
                ),
              ),
              SizedBox(height: 5),
              TextFormField(
                controller: _lastNameController,
                decoration: _inputDecoration('Last Name', Icons.person),
                style: TextStyle(fontSize: 16, color: AppColors.darkTeal),
                textCapitalization: TextCapitalization.words,
                validator: (val) => null, // Optional
              ),
              SizedBox(height: 18),
              Text(
                'Country Code',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[500],
                ),
              ),
              SizedBox(height: 5),
              CountryCodePicker(
                onChanged: (countryCode) {
                  setState(() {
                    _selectedCountryCode = countryCode.dialCode ?? '+91';
                    _countryCodeController.text = _selectedCountryCode;
                  });
                },
                initialSelection: 'IN',
                favorite: ['+91', 'IN'],
                showCountryOnly: false,
                showOnlyCountryWhenClosed: false,
                alignLeft: true,
              ),
              SizedBox(height: 18),
              Text(
                'Phone Number',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[500],
                ),
              ),
              SizedBox(height: 5),
              TextFormField(
                controller: _phoneController,
                decoration: _inputDecoration('Phone Number', Icons.phone),
                style: TextStyle(fontSize: 16, color: AppColors.darkTeal),
                keyboardType: TextInputType.phone,
                validator: (val) =>
                    val == null || val.isEmpty ? 'Required' : null,
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
                child: _isLoading
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
                          'Add Member',
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
