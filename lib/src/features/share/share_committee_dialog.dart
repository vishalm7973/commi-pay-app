import 'dart:io';
import 'package:flutter/material.dart';
import 'share_committees.dart';
import '../committees/data/committee_model.dart';

class ShareCommitteeDialog extends StatefulWidget {
  final List<Committee> committees;

  const ShareCommitteeDialog({
    super.key,
    required this.committees,
  });

  @override
  State<ShareCommitteeDialog> createState() => _ShareCommitteeDialogState();
}

class _ShareCommitteeDialogState extends State<ShareCommitteeDialog> {
  File? _imageFile;
  String? _error;
  bool _isSharing = false;

  @override
  void initState() {
    super.initState();
    _generateImage();
  }

  Future<void> _generateImage() async {
    final file = await ShareCommittees.generateCommitteePreview(
      context,
      'Committees',
      widget.committees,
    );

    if (file == null) {
      setState(() {
        _error = 'Failed to generate preview image.';
      });
    } else {
      setState(() {
        _imageFile = file;
      });
    }
  }

  Future<void> _onSend() async {
    if (_imageFile == null) return;
    setState(() {
      _isSharing = true;
    });
    await ShareCommittees.shareFile(_imageFile!);
    if (mounted) {
      setState(() {
        _isSharing = false;
      });
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Preview Share Image'),
      content: SizedBox(
        width: 300,
        height: 250,
        child: Center(
          child: _error != null
              ? Text(_error!, style: const TextStyle(color: Colors.red))
              : _imageFile == null
                  ? const CircularProgressIndicator()
                  : Image.file(_imageFile!),
        ),
      ),
      actions: [
        if (_imageFile != null && !_isSharing)
          IconButton(
            icon: const Icon(Icons.send, color: Colors.teal),
            onPressed: _onSend,
            tooltip: 'Send',
          ),
        if (_isSharing)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 18),
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        TextButton(
          onPressed: _isSharing ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}
