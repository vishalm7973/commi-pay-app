// share_installments.dart
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:io';

import 'package:cross_file/cross_file.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../home/data/pending_payment_records_model.dart';

class ShareInstallments {
  /// Main entry point. Call from your screen:
  /// await ShareInstallments.share(context, groups);
  static Future<void> share(
    BuildContext context,
    List<PaymentGroup> groups,
  ) async {
    try {
      // Configuration
      const double logicalWidth = 800; // logical pixels width (layout units)
      const double pixelRatio = 3.0; // output resolution multiplier
      const double padding = 24;
      const double headerFont = 28;
      const double regularFont = 18;
      const double rowSpacing = 12;
      const double lineHeight = 26;

      // Build the list of rows (strings and amounts)
      final rows = <_RowItem>[];
      for (var g in groups) {
        final name = (g.committee.id?.toString() ?? 'Committee').toString();
        final contribution = g.monthlyContribution;
        final count = g.count;
        final amount = contribution * count;
        rows.add(
          _RowItem(
            left: name,
            middle: '$contribution × $count',
            right: '₹$amount',
          ),
        );
      }

      final totalCount = groups.fold<int>(0, (s, g) => s + g.count);
      final totalAmount = groups.fold<int>(
        0,
        (s, g) => s + g.monthlyContribution * g.count,
      );

      // Estimate logical height based on rows
      final double headerHeight = headerFont + 16;
      final double rowsHeight = rows.length * (lineHeight + rowSpacing);
      final double totalsHeight = (lineHeight * 2) + (rowSpacing * 2);
      final double logicalHeight =
          padding * 2 + headerHeight + rowsHeight + totalsHeight;

      // Setup recorder and canvas
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(
        recorder,
        Rect.fromLTWH(
          0,
          0,
          logicalWidth * pixelRatio,
          logicalHeight * pixelRatio,
        ),
      );

      // Scale canvas so we can draw in logical units and get high-res output
      canvas.scale(pixelRatio, pixelRatio);

      // Background
      final paint = ui.Paint()..color = const ui.Color(0xFFFFFFFF);
      canvas.drawRect(Rect.fromLTWH(0, 0, logicalWidth, logicalHeight), paint);

      // Optional: subtle card background
      final cardPaint = ui.Paint()..color = const ui.Color(0xFFF8FBFF);
      final rrect = RRect.fromRectAndRadius(
        Rect.fromLTWH(12, 12, logicalWidth - 24, logicalHeight - 24),
        const Radius.circular(12),
      );
      canvas.drawRRect(rrect, cardPaint);

      // Draw header text
      double y = padding + 8;
      _drawParagraph(
        canvas,
        'Pending Installments',
        fontSize: headerFont,
        left: padding + 12,
        top: y,
        maxWidth: logicalWidth - padding * 2 - 24,
        fontWeight: FontWeight.w700,
      );
      y += headerHeight + 8;

      // Divider line
      final dividerPaint = ui.Paint()..color = const ui.Color(0xFFE0E6EE);
      canvas.drawRect(
        Rect.fromLTWH(
          padding + 12,
          y - 4,
          logicalWidth - (padding + 12) * 2,
          1,
        ),
        dividerPaint,
      );
      y += 8;

      // Rows
      for (var row in rows) {
        // Left: name (expanded)
        _drawParagraph(
          canvas,
          row.left,
          fontSize: regularFont,
          left: padding + 20,
          top: y,
          maxWidth: logicalWidth * 0.45,
          fontWeight: FontWeight.w600,
        );

        // Middle: contribution × count
        _drawParagraph(
          canvas,
          row.middle,
          fontSize: regularFont,
          left: padding + logicalWidth * 0.45 + 30,
          top: y,
          maxWidth: logicalWidth * 0.25,
          align: ui.TextAlign.left,
        );

        // Right: amount (aligned right)
        _drawParagraph(
          canvas,
          row.right,
          fontSize: regularFont,
          left: padding + logicalWidth * 0.75 + 10,
          top: y,
          maxWidth: logicalWidth * 0.2,
          align: ui.TextAlign.right,
          fontWeight: FontWeight.w700,
        );

        y += lineHeight + rowSpacing;
      }

      // Totals divider
      y += 6;
      canvas.drawRect(
        Rect.fromLTWH(
          padding + 12,
          y - 4,
          logicalWidth - (padding + 12) * 2,
          1,
        ),
        dividerPaint,
      );
      y += 12;

      // Totals rows
      _drawParagraph(
        canvas,
        'Total Count',
        fontSize: regularFont,
        left: padding + 20,
        top: y,
        maxWidth: logicalWidth * 0.6,
        fontWeight: FontWeight.w700,
      );
      _drawParagraph(
        canvas,
        '$totalCount',
        fontSize: regularFont,
        left: padding + logicalWidth * 0.75 + 10,
        top: y,
        maxWidth: logicalWidth * 0.2,
        align: ui.TextAlign.right,
        fontWeight: FontWeight.w700,
      );

      y += lineHeight + 8;

      _drawParagraph(
        canvas,
        'Total Amount',
        fontSize: regularFont,
        left: padding + 20,
        top: y,
        maxWidth: logicalWidth * 0.6,
        fontWeight: FontWeight.w700,
      );
      _drawParagraph(
        canvas,
        '₹$totalAmount',
        fontSize: regularFont,
        left: padding + logicalWidth * 0.75 + 10,
        top: y,
        maxWidth: logicalWidth * 0.2,
        align: ui.TextAlign.right,
        fontWeight: FontWeight.w700,
      );

      // Finish recording
      final picture = recorder.endRecording();

      // Convert picture to image pixels
      final ui.Image img = await picture.toImage(
        (logicalWidth * pixelRatio).toInt(),
        (logicalHeight * pixelRatio).toInt(),
      );

      final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) throw Exception('Failed to create PNG bytes');

      final pngBytes = byteData.buffer.asUint8List();

      // Save to temp file
      final tempDir = await getTemporaryDirectory();
      final file = await File(
        '${tempDir.path}/installments_${DateTime.now().millisecondsSinceEpoch}.png',
      ).create();
      await file.writeAsBytes(pngBytes);

      // Share
      await Share.shareXFiles([XFile(file.path)], text: 'Pending Installments');
    } catch (e, st) {
      debugPrint('ShareInstallments (canvas) error: $e\n$st');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not create share image: ${e.toString()}'),
          ),
        );
      }
    }
  }

  /// Helper that draws a text paragraph at given left/top with maxWidth.
  static void _drawParagraph(
    ui.Canvas canvas,
    String text, {
    required double left,
    required double top,
    required double maxWidth,
    double fontSize = 16,
    ui.TextAlign align = ui.TextAlign.left,
    FontWeight fontWeight = FontWeight.w400,
    Color color = const Color(0xFF062B2B),
  }) {
    final ui.ParagraphStyle pStyle = ui.ParagraphStyle(
      textAlign: align,
      maxLines: 2,
      ellipsis: '…',
    );

    final ui.TextStyle tStyle = ui.TextStyle(
      color: ui.Color(color.value),
      fontSize: fontSize,
      fontWeight: fontWeight,
    );

    final ui.ParagraphBuilder pb = ui.ParagraphBuilder(pStyle)
      ..pushStyle(tStyle)
      ..addText(text);
    final ui.Paragraph paragraph = pb.build();
    paragraph.layout(ui.ParagraphConstraints(width: maxWidth));
    canvas.drawParagraph(paragraph, Offset(left, top));
  }
}

/// Simple container for a row.
class _RowItem {
  final String left;
  final String middle;
  final String right;
  _RowItem({required this.left, required this.middle, required this.right});
}
