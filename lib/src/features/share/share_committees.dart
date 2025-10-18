import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/material.dart';
import 'package:commipay_app/utils/app_colors.dart';
import '../committees/data/committee_model.dart';

class ShareCommittees {
  static Future<File?> generateCommitteePreview(
    BuildContext context,
    String title,
    List<Committee> committees,
  ) async {
    try {
      final rows = committees.map((committee) {
        return [
          '₹ ${committee.amount}',
          '${committee.monthlyDueDay}th day',
          'Members: ${committee.members.length}',
        ];
      }).toList();

      final totalCount = committees.length;
      final totalAmount = committees.fold<int>(0, (sum, c) => sum + c.amount);

      const double logicalWidth = 850;
      const double pixelRatio = 3.0;
      const double cardPadding = 32.0;
      const double headerBarHeight = 62;
      const double tableHeaderHeight = 38;
      const double rowHeight = 38;
      const double borderRadius = 12;

      final colWidths = [200.0, 240.0, 200.0];
      final double logicalHeight =
          cardPadding * 2 +
          headerBarHeight +
          16 +
          tableHeaderHeight +
          rowHeight * rows.length +
          cardPadding +
          40;

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(
        recorder,
        ui.Rect.fromLTWH(
          0,
          0,
          logicalWidth * pixelRatio,
          logicalHeight * pixelRatio,
        ),
      );
      canvas.scale(pixelRatio, pixelRatio);

      final bgPaint = ui.Paint()..color = const ui.Color(0xFFF8FBFF);
      final rrect = ui.RRect.fromRectAndRadius(
        ui.Rect.fromLTWH(0, 0, logicalWidth, logicalHeight),
        const ui.Radius.circular(borderRadius),
      );
      canvas.drawRRect(rrect, bgPaint);

      final headerPaint = ui.Paint()..color = const ui.Color(0xFF46828C);
      final headerBarRect = ui.Rect.fromLTWH(
        cardPadding,
        cardPadding,
        logicalWidth - 2 * cardPadding,
        headerBarHeight,
      );
      canvas.drawRect(headerBarRect, headerPaint);

      _drawParagraph(
        canvas,
        title,
        fontSize: 26,
        left: cardPadding + 14,
        top: cardPadding + 16,
        maxWidth: 380,
        color: const Color(0xFFFFFFFF),
        fontWeight: FontWeight.w700,
      );

      _drawParagraph(
        canvas,
        'Total: $totalCount',
        fontSize: 22,
        left: logicalWidth - cardPadding - 170,
        top: cardPadding + 21,
        maxWidth: 160,
        color: const Color(0xFFFFFFFF),
        fontWeight: FontWeight.w600,
        align: ui.TextAlign.right,
      );

      double y = cardPadding + headerBarHeight + 16;
      double x = cardPadding + 8;
      const headers = ['Amount', 'Due Day', 'Members'];

      for (int i = 0; i < headers.length; i++) {
        _drawParagraph(
          canvas,
          headers[i],
          fontSize: 19,
          left: x,
          top: y,
          maxWidth: colWidths[i],
          fontWeight: FontWeight.bold,
          color: const Color(0xFF24323F),
          align: ui.TextAlign.left,
        );
        x += colWidths[i];
      }

      y += tableHeaderHeight;
      for (final row in rows) {
        x = cardPadding + 8;
        for (int i = 0; i < row.length; i++) {
          _drawParagraph(
            canvas,
            row[i],
            fontSize: 20,
            left: x,
            top: y,
            maxWidth: colWidths[i],
            fontWeight: FontWeight.w400,
            color: const Color(0xFF486366),
            align: ui.TextAlign.left,
          );
          x += colWidths[i];
        }
        y += rowHeight;
      }

      y += 18;
      _drawParagraph(
        canvas,
        'Total Amount:',
        fontSize: 22,
        left: cardPadding + 8,
        top: y,
        maxWidth: colWidths[0] + colWidths[1],
        fontWeight: FontWeight.w800,
        color: const Color(0xFF24323F),
      );
      _drawParagraph(
        canvas,
        '₹ $totalAmount /-',
        fontSize: 27,
        left: logicalWidth - cardPadding - colWidths[2] - 8,
        top: y,
        maxWidth: colWidths[2],
        fontWeight: FontWeight.w800,
        color: AppColors.caribbeanGreen,
        align: ui.TextAlign.right,
      );

      final picture = recorder.endRecording();
      final ui.Image img = await picture.toImage(
        (logicalWidth * pixelRatio).toInt(),
        (logicalHeight * pixelRatio).toInt(),
      );
      final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) throw Exception('Failed to create PNG bytes');
      final pngBytes = byteData.buffer.asUint8List();
      final tempDir = await getTemporaryDirectory();
      final file = await File(
        '${tempDir.path}/committees_${DateTime.now().millisecondsSinceEpoch}.png',
      ).create();
      await file.writeAsBytes(pngBytes);

      return file;
    } catch (e, st) {
      debugPrint('ShareCommittees (canvas) error: $e\n$st');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Could not create committee preview image: ${e.toString()}',
            ),
          ),
        );
      }
      return null;
    }
  }

  static Future<void> shareFile(File imageFile) async {
    await Share.shareXFiles([XFile(imageFile.path)], text: 'Active Committees');
  }

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
    canvas.drawParagraph(paragraph, ui.Offset(left, top));
  }
}
