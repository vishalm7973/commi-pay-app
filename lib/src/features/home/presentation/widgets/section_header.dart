import 'package:flutter/material.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onBack;
  final VoidCallback? onAdd;

  const SectionHeader({
    super.key,
    required this.title,
    this.onBack,
    this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: Row(
          children: [
            // Back Button (optional)
            InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: onBack ?? () => Navigator.of(context).maybePop(),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Color(0xFFF1F1F1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.black87, size: 20),
              ),
            ),
            Expanded(
              child: Center(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),
            // Add Button (optional)
            InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: onAdd,
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Color(0xFFF1F1F1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.add, color: Colors.black87, size: 22),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
