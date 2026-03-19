part of '../main.dart';

class _PrintPreviewSheet extends StatelessWidget {
  const _PrintPreviewSheet({required this.orders, required this.totalRevenue});

  final List<Order> orders;
  final double totalRevenue;

  @override
  Widget build(BuildContext context) {
    final avgOrder = orders.isEmpty
        ? 0.0
        : totalRevenue / orders.length.toDouble();

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.print_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Print preview',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Jewellery sales summary',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade700),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: _PreviewMetric(
                        label: 'Orders',
                        value: orders.length.toString(),
                      ),
                    ),
                    Expanded(
                      child: _PreviewMetric(
                        label: 'Revenue',
                        value: _formatCurrency(totalRevenue),
                      ),
                    ),
                    Expanded(
                      child: _PreviewMetric(
                        label: 'Avg order',
                        value: _formatCurrency(avgOrder),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Jewellery orders',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _PreviewRow(
                      leading: 'ID',
                      middle: 'Customer',
                      trailing: 'Total',
                      isHeader: true,
                    ),
                    const Divider(),
                    ...orders.map(
                      (order) => _PreviewRow(
                        leading: order.id,
                        middle: order.customer,
                        trailing: _formatCurrency(order.total),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Close'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Print preview only.')),
                      );
                    },
                    icon: const Icon(Icons.print),
                    label: const Text('Print'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _PreviewMetric extends StatelessWidget {
  const _PreviewMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade700),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _PreviewRow extends StatelessWidget {
  const _PreviewRow({
    required this.leading,
    required this.middle,
    required this.trailing,
    this.isHeader = false,
  });

  final String leading;
  final String middle;
  final String trailing;
  final bool isHeader;

  @override
  Widget build(BuildContext context) {
    final style = isHeader
        ? Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700)
        : Theme.of(context).textTheme.bodySmall;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(leading, style: style)),
          Expanded(flex: 3, child: Text(middle, style: style)),
          Expanded(
            flex: 2,
            child: Text(trailing, style: style, textAlign: TextAlign.end),
          ),
        ],
      ),
    );
  }
}

class _EstimatePrintPreviewSheet extends StatelessWidget {
  const _EstimatePrintPreviewSheet({
    required this.customerName,
    required this.customerMobile,
    required this.alternateMobile,
    required this.statusLabel,
    required this.occasion,
    required this.occasionDate,
    required this.deliveryDate,
    required this.purity,
    required this.making,
    required this.gst,
    required this.totalQuantity,
    required this.totalWeight,
    required this.items,
  });

  final String customerName;
  final String customerMobile;
  final String alternateMobile;
  final String statusLabel;
  final String occasion;
  final String occasionDate;
  final String deliveryDate;
  final String purity;
  final String making;
  final String gst;
  final String totalQuantity;
  final String totalWeight;
  final List<_EstimateItemDraft> items;

  List<MapEntry<String, double>> get _categoryWeightEntries {
    const preferredOrder = ['22K', '18K', 'Silver'];
    final totals = <String, double>{};

    for (final item in items.where((item) => !item.isEmpty)) {
      final category = item.purityController.text.trim().isEmpty
          ? 'Other'
          : item.purityController.text.trim();
      totals.update(
        category,
        (value) => value + item.estimatedWeight,
        ifAbsent: () => item.estimatedWeight,
      );
    }

    final entries = totals.entries.toList();
    entries.sort((a, b) {
      final aIndex = preferredOrder.indexOf(a.key);
      final bIndex = preferredOrder.indexOf(b.key);
      final normalizedAIndex = aIndex == -1 ? preferredOrder.length : aIndex;
      final normalizedBIndex = bIndex == -1 ? preferredOrder.length : bIndex;
      final orderCompare = normalizedAIndex.compareTo(normalizedBIndex);
      if (orderCompare != 0) {
        return orderCompare;
      }
      return a.key.compareTo(b.key);
    });
    return entries;
  }

  double _categoryWeightFor(String category) {
    return _categoryWeightEntries
        .firstWhere(
          (entry) => entry.key == category,
          orElse: () => const MapEntry('', 0),
        )
        .value;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text('Estimate PDF Preview'),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Double-click to enlarge on desktop, or pinch to zoom in and out on touch devices.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade700),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Card(
                clipBehavior: Clip.antiAlias,
                child: PdfPreview(
                  canChangePageFormat: false,
                  canChangeOrientation: false,
                  canDebug: false,
                  allowSharing: false,
                  pdfFileName: 'estimate-summary-preview.pdf',
                  build: _buildEstimatePdf,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<Uint8List> _buildEstimatePdf(PdfPageFormat format) async {
    try {
      final document = pw.Document();
      pw.MemoryImage? shreeHeaderImage;
      try {
        final shreeHeaderBytes = await _buildShreeHeaderImage().timeout(
          const Duration(seconds: 2),
        );
        if (shreeHeaderBytes.isNotEmpty) {
          shreeHeaderImage = pw.MemoryImage(shreeHeaderBytes);
        }
      } catch (_) {
        shreeHeaderImage = null;
      }

      final pageFormat = PdfPageFormat.a5;
      final itemCount = items.length;
      final longestItemNameLength = items.fold<int>(0, (maxLength, item) {
        final currentLength = item.nameController.text.trim().length;
        return currentLength > maxLength ? currentLength : maxLength;
      });
      var itemNameColumnWidth = 62.0 + (longestItemNameLength * 2.4);
      if (itemNameColumnWidth < 76) {
        itemNameColumnWidth = 76;
      } else if (itemNameColumnWidth > 126) {
        itemNameColumnWidth = 126;
      }
      final compactTableFontSize = itemCount <= 4
          ? 9.4
          : itemCount <= 8
          ? 8.0
          : 7.0;
      final compactLabelFontSize = itemCount <= 8 ? 7.0 : 6.2;
      final compactValueFontSize = itemCount <= 8 ? 7.6 : 6.8;
      final tableVerticalPadding = itemCount <= 8 ? 3.2 : 2.6;
      final labelStyle = pw.TextStyle(
        fontSize: compactLabelFontSize,
        color: PdfColors.black,
        fontWeight: pw.FontWeight.bold,
      );
      final valueStyle = pw.TextStyle(
        fontSize: compactValueFontSize,
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.black,
      );
      final headingStyle = pw.TextStyle(
        fontSize: 14,
        fontWeight: pw.FontWeight.bold,
        letterSpacing: 0.4,
        color: PdfColors.black,
      );

      pw.Widget infoCell(String label, String value) {
        return pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey300),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(label, style: labelStyle),
              pw.SizedBox(height: 2),
              pw.Container(
                height: compactValueFontSize + 2,
                alignment: pw.Alignment.centerLeft,
                child: pw.Text(value, style: valueStyle, maxLines: 1),
              ),
            ],
          ),
        );
      }

      pw.Widget tableCell(
        String text, {
        required pw.TextStyle style,
        pw.Alignment alignment = pw.Alignment.centerLeft,
        PdfColor? backgroundColor,
      }) {
        return pw.Container(
          alignment: alignment,
          color: backgroundColor,
          padding: pw.EdgeInsets.symmetric(
            horizontal: 4,
            vertical: tableVerticalPadding,
          ),
          child: pw.Container(
            height: compactTableFontSize + 3,
            alignment: alignment,
            child: pw.Text(
              text.isEmpty ? ' ' : text,
              style: style,
              maxLines: 1,
            ),
          ),
        );
      }

      document.addPage(
        pw.Page(
          pageFormat: pageFormat,
          margin: const pw.EdgeInsets.all(16),
          build: (context) {
            final tableStyle = pw.TextStyle(
              fontSize: compactTableFontSize,
              color: PdfColors.black,
            );
            final tableHeaderStyle = pw.TextStyle(
              fontSize: compactTableFontSize,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.black,
            );

            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                pw.Center(
                  child: shreeHeaderImage == null
                      ? pw.Row(
                          mainAxisSize: pw.MainAxisSize.min,
                          children: [
                            pw.Container(
                              width: 2,
                              height: 36,
                              color: PdfColors.black,
                            ),
                            pw.SizedBox(width: 6),
                            pw.Container(
                              width: 2,
                              height: 36,
                              color: PdfColors.black,
                            ),
                            pw.SizedBox(width: 12),
                            pw.Text(
                              'Shree :',
                              style: pw.TextStyle(
                                fontSize: 14,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                            pw.SizedBox(width: 12),
                            pw.Container(
                              width: 2,
                              height: 36,
                              color: PdfColors.black,
                            ),
                            pw.SizedBox(width: 6),
                            pw.Container(
                              width: 2,
                              height: 36,
                              color: PdfColors.black,
                            ),
                          ],
                        )
                      : pw.Image(shreeHeaderImage, width: 116),
                ),
                pw.SizedBox(height: 6),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Container(
                      width: 12,
                      height: 12,
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.black, width: 1),
                      ),
                    ),
                    pw.Text(
                      DateFormat('dd/MM/yyyy').format(DateTime.now()),
                      style: labelStyle,
                    ),
                  ],
                ),
                pw.SizedBox(height: 4),
                pw.Center(child: pw.Text('Estimate', style: headingStyle)),
                pw.SizedBox(height: 8),
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(flex: 2, child: infoCell('Name', customerName)),
                    pw.SizedBox(width: 8),
                    pw.Expanded(child: infoCell('Status', statusLabel)),
                    pw.SizedBox(width: 8),
                    pw.Expanded(child: infoCell('Delivery Date', deliveryDate)),
                  ],
                ),
                pw.SizedBox(height: 6),
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(
                      child: infoCell('Whatsapp Number', customerMobile),
                    ),
                    pw.SizedBox(width: 8),
                    pw.Expanded(
                      child: infoCell('Alternate Mobile', alternateMobile),
                    ),
                  ],
                ),
                pw.SizedBox(height: 6),
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(child: infoCell('Purity', purity)),
                    pw.SizedBox(width: 8),
                    pw.Expanded(child: infoCell('Making', making)),
                    pw.SizedBox(width: 8),
                    pw.Expanded(child: infoCell('GST', gst)),
                  ],
                ),
                pw.SizedBox(height: 8),
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey400),
                  columnWidths: {
                    0: const pw.FixedColumnWidth(20),
                    1: const pw.FixedColumnWidth(34),
                    2: pw.FixedColumnWidth(itemNameColumnWidth),
                    3: const pw.FixedColumnWidth(20),
                    4: const pw.FixedColumnWidth(44),
                    5: const pw.FlexColumnWidth(1.4),
                  },
                  defaultVerticalAlignment:
                      pw.TableCellVerticalAlignment.middle,
                  children: [
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(
                        color: PdfColors.grey200,
                      ),
                      children: [
                        tableCell(
                          'S No.',
                          style: tableHeaderStyle,
                          backgroundColor: PdfColors.grey200,
                        ),
                        tableCell(
                          'Purity',
                          style: tableHeaderStyle,
                          backgroundColor: PdfColors.grey200,
                        ),
                        tableCell(
                          'Item Name',
                          style: tableHeaderStyle,
                          backgroundColor: PdfColors.grey200,
                        ),
                        tableCell(
                          'Qty',
                          style: tableHeaderStyle,
                          alignment: pw.Alignment.center,
                          backgroundColor: PdfColors.grey200,
                        ),
                        tableCell(
                          'Est. Wt',
                          style: tableHeaderStyle,
                          alignment: pw.Alignment.center,
                          backgroundColor: PdfColors.grey200,
                        ),
                        tableCell(
                          'Notes',
                          style: tableHeaderStyle,
                          backgroundColor: PdfColors.grey200,
                        ),
                      ],
                    ),
                    ...items.asMap().entries.map(
                      (entry) => pw.TableRow(
                        children: [
                          tableCell('${entry.key + 1}', style: tableStyle),
                          tableCell(
                            entry.value.purityController.text.trim(),
                            style: tableStyle,
                          ),
                          tableCell(
                            entry.value.nameController.text.trim(),
                            style: tableStyle,
                          ),
                          tableCell(
                            entry.value.quantityController.text.trim(),
                            style: tableStyle,
                            alignment: pw.Alignment.center,
                          ),
                          tableCell(
                            _formatWeight3(entry.value.estimatedWeight),
                            style: tableStyle,
                            alignment: pw.Alignment.center,
                          ),
                          tableCell(
                            entry.value.notesController.text.trim(),
                            style: tableStyle,
                          ),
                        ],
                      ),
                    ),
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(
                        color: PdfColors.grey100,
                      ),
                      children: [
                        tableCell(
                          '',
                          style: tableHeaderStyle,
                          backgroundColor: PdfColors.grey100,
                        ),
                        tableCell(
                          '',
                          style: tableHeaderStyle,
                          backgroundColor: PdfColors.grey100,
                        ),
                        tableCell(
                          'Total',
                          style: tableHeaderStyle,
                          backgroundColor: PdfColors.grey100,
                        ),
                        tableCell(
                          totalQuantity,
                          style: tableHeaderStyle,
                          alignment: pw.Alignment.center,
                          backgroundColor: PdfColors.grey100,
                        ),
                        tableCell(
                          _formatWeight3(
                            items.fold<double>(
                              0,
                              (sum, item) => sum + item.estimatedWeight,
                            ),
                          ),
                          style: tableHeaderStyle,
                          alignment: pw.Alignment.center,
                          backgroundColor: PdfColors.grey100,
                        ),
                        tableCell(
                          '',
                          style: tableHeaderStyle,
                          backgroundColor: PdfColors.grey100,
                        ),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 8),
                if (_categoryWeightEntries.isNotEmpty)
                  pw.Row(
                    children: [
                      for (final category in const [
                        '22K',
                        '18K',
                        'Silver',
                      ]) ...[
                        pw.Expanded(
                          child: infoCell(
                            category,
                            '${_formatWeight3(_categoryWeightFor(category))} gm',
                          ),
                        ),
                        if (category != 'Silver') pw.SizedBox(width: 6),
                      ],
                    ],
                  ),
                if (_categoryWeightEntries.isNotEmpty) pw.SizedBox(height: 8),
                pw.Row(
                  children: [
                    pw.Spacer(),
                    pw.Expanded(
                      flex: 2,
                      child: infoCell('Estimated Weight', totalWeight),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      );

      return document.save();
    } catch (error) {
      final document = pw.Document();
      document.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a5,
          build: (context) => pw.Center(
            child: pw.Text(
              'Unable to generate estimate preview.\n$error',
              textAlign: pw.TextAlign.center,
            ),
          ),
        ),
      );

      return document.save();
    }
  }

  Future<Uint8List> _buildShreeHeaderImage() async {
    const width = 420.0;
    const height = 64.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final linePaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 2;

    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'श्री:',
        style: TextStyle(
          color: Colors.black,
          fontSize: 28,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    )..layout();

    final textLeft = (width - textPainter.width) / 2;
    final textRight = textLeft + textPainter.width;
    const lineTop = 12.0;
    const lineBottom = 52.0;
    const innerGap = 12.0;
    const lineSpacing = 8.0;

    canvas.drawLine(
      Offset(textLeft - innerGap - lineSpacing, lineTop),
      Offset(textLeft - innerGap - lineSpacing, lineBottom),
      linePaint,
    );
    canvas.drawLine(
      Offset(textLeft - innerGap, lineTop),
      Offset(textLeft - innerGap, lineBottom),
      linePaint,
    );
    canvas.drawLine(
      Offset(textRight + innerGap, lineTop),
      Offset(textRight + innerGap, lineBottom),
      linePaint,
    );
    canvas.drawLine(
      Offset(textRight + innerGap + lineSpacing, lineTop),
      Offset(textRight + innerGap + lineSpacing, lineBottom),
      linePaint,
    );

    textPainter.paint(
      canvas,
      Offset(textLeft, (height - textPainter.height) / 2),
    );

    final image = await recorder.endRecording().toImage(
      width.toInt(),
      height.toInt(),
    );
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }
}

class _AdvancePrintPreviewSheet extends StatelessWidget {
  const _AdvancePrintPreviewSheet({
    required this.items,
    required this.oldItems,
    required this.totalAmount,
  });

  final List<_AdvanceValuationDraft> items;
  final List<_AdvanceOldItemDraft> oldItems;
  final double totalAmount;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text('Advance PDF Preview'),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Double-click to enlarge on desktop, or pinch to zoom in and out on touch devices.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade700),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Card(
                clipBehavior: Clip.antiAlias,
                child: PdfPreview(
                  canChangePageFormat: false,
                  canChangeOrientation: false,
                  canDebug: false,
                  allowSharing: false,
                  pdfFileName: 'advance-preview.pdf',
                  build: _buildAdvancePdf,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<Uint8List> _buildAdvancePdf(PdfPageFormat format) async {
    final document = pw.Document();
    final lines = items
        .where((item) => !item.isEmpty)
        .map((item) => item.line)
        .toList();
    final totalNetWeight = lines.fold<double>(
      0,
      (sum, line) => sum + line.weight,
    );
    final oldItemLines = oldItems.where((item) => !item.isEmpty).toList();
    final oldItemsTotalAmount = oldItemLines.fold<double>(
      0,
      (sum, item) => sum + item.amount,
    );

    document.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a5,
        margin: const pw.EdgeInsets.all(16),
        build: (context) {
          final headerStyle = pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.black,
          );
          final bodyStyle = const pw.TextStyle(
            fontSize: 9,
            color: PdfColors.black,
          );
          final labelStyle = pw.TextStyle(
            fontSize: 8,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.black,
          );

          pw.Widget tableCell(
            String text, {
            pw.Alignment alignment = pw.Alignment.centerLeft,
            bool isHeader = false,
          }) {
            return pw.Container(
              alignment: alignment,
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 4,
                vertical: 4,
              ),
              color: isHeader ? PdfColors.grey200 : null,
              child: pw.Text(
                text.isEmpty ? ' ' : text,
                style: isHeader ? labelStyle : bodyStyle,
                textAlign: alignment == pw.Alignment.center
                    ? pw.TextAlign.center
                    : alignment == pw.Alignment.centerRight
                    ? pw.TextAlign.right
                    : pw.TextAlign.left,
              ),
            );
          }

          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              pw.Center(child: pw.Text('Advance', style: headerStyle)),
              pw.SizedBox(height: 10),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey400),
                columnWidths: const {
                  0: pw.FixedColumnWidth(38),
                  1: pw.FixedColumnWidth(34),
                  2: pw.FixedColumnWidth(46),
                  3: pw.FixedColumnWidth(48),
                  4: pw.FixedColumnWidth(42),
                  5: pw.FixedColumnWidth(40),
                  6: pw.FixedColumnWidth(44),
                },
                children: [
                  pw.TableRow(
                    children: [
                      tableCell('Date', isHeader: true),
                      tableCell('Mode', isHeader: true),
                      tableCell('Cheque No', isHeader: true),
                      tableCell(
                        'Amount',
                        isHeader: true,
                        alignment: pw.Alignment.centerRight,
                      ),
                      tableCell(
                        'Rate22',
                        isHeader: true,
                        alignment: pw.Alignment.centerRight,
                      ),
                      tableCell(
                        'Making%',
                        isHeader: true,
                        alignment: pw.Alignment.centerRight,
                      ),
                      tableCell(
                        'Net Wt',
                        isHeader: true,
                        alignment: pw.Alignment.centerRight,
                      ),
                    ],
                  ),
                  ...lines.map(
                    (line) => pw.TableRow(
                      children: [
                        tableCell(_formatEntryDate(line.date)),
                        tableCell(line.mode.label),
                        tableCell(line.chequeNumber ?? '-'),
                        tableCell(
                          _formatCurrency(line.amount),
                          alignment: pw.Alignment.centerRight,
                        ),
                        tableCell(
                          _formatCurrency(line.rate),
                          alignment: pw.Alignment.centerRight,
                        ),
                        tableCell(
                          '${line.rateMaking.toStringAsFixed(2)}%',
                          alignment: pw.Alignment.centerRight,
                        ),
                        tableCell(
                          _formatWeight3(line.weight),
                          alignment: pw.Alignment.centerRight,
                        ),
                      ],
                    ),
                  ),
                  pw.TableRow(
                    children: [
                      tableCell(''),
                      tableCell('Total', isHeader: true),
                      tableCell(''),
                      tableCell(
                        _formatCurrency(totalAmount),
                        isHeader: true,
                        alignment: pw.Alignment.centerRight,
                      ),
                      tableCell(''),
                      tableCell(''),
                      tableCell(
                        _formatWeight3(totalNetWeight),
                        isHeader: true,
                        alignment: pw.Alignment.centerRight,
                      ),
                    ],
                  ),
                ],
              ),
              if (oldItemLines.isNotEmpty) pw.SizedBox(height: 12),
              if (oldItemLines.isNotEmpty)
                pw.Text('Old Items', style: headerStyle),
              if (oldItemLines.isNotEmpty) pw.SizedBox(height: 8),
              if (oldItemLines.isNotEmpty)
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey400),
                  columnWidths: const {
                    0: pw.FixedColumnWidth(34),
                    1: pw.FlexColumnWidth(1.8),
                    2: pw.FixedColumnWidth(36),
                    3: pw.FixedColumnWidth(34),
                    4: pw.FixedColumnWidth(34),
                    5: pw.FixedColumnWidth(34),
                    6: pw.FixedColumnWidth(30),
                    7: pw.FixedColumnWidth(44),
                  },
                  children: [
                    pw.TableRow(
                      children: [
                        tableCell('Date', isHeader: true),
                        tableCell('Item', isHeader: true),
                        tableCell(
                          'Rate',
                          isHeader: true,
                          alignment: pw.Alignment.centerRight,
                        ),
                        tableCell(
                          'Gross',
                          isHeader: true,
                          alignment: pw.Alignment.centerRight,
                        ),
                        tableCell(
                          'Less',
                          isHeader: true,
                          alignment: pw.Alignment.centerRight,
                        ),
                        tableCell(
                          'Nett',
                          isHeader: true,
                          alignment: pw.Alignment.centerRight,
                        ),
                        tableCell(
                          'Purity',
                          isHeader: true,
                          alignment: pw.Alignment.centerRight,
                        ),
                        tableCell(
                          'Amount',
                          isHeader: true,
                          alignment: pw.Alignment.centerRight,
                        ),
                      ],
                    ),
                    ...oldItemLines.map(
                      (item) => pw.TableRow(
                        children: [
                          tableCell(_formatEntryDate(item.date)),
                          tableCell(item.itemNameController.text.trim()),
                          tableCell(
                            _formatCurrency(item.returnRate),
                            alignment: pw.Alignment.centerRight,
                          ),
                          tableCell(
                            _formatWeight3(item.grossWeight),
                            alignment: pw.Alignment.centerRight,
                          ),
                          tableCell(
                            _formatWeight3(item.lessWeight),
                            alignment: pw.Alignment.centerRight,
                          ),
                          tableCell(
                            _formatWeight3(item.nettWeight),
                            alignment: pw.Alignment.centerRight,
                          ),
                          tableCell(
                            _formatWeight3(item.tanch),
                            alignment: pw.Alignment.centerRight,
                          ),
                          tableCell(
                            _formatCurrency(item.amount),
                            alignment: pw.Alignment.centerRight,
                          ),
                        ],
                      ),
                    ),
                    pw.TableRow(
                      children: [
                        tableCell(''),
                        tableCell('Total', isHeader: true),
                        tableCell(''),
                        tableCell(''),
                        tableCell(''),
                        tableCell(''),
                        tableCell(''),
                        tableCell(
                          _formatCurrency(oldItemsTotalAmount),
                          isHeader: true,
                          alignment: pw.Alignment.centerRight,
                        ),
                      ],
                    ),
                  ],
                ),
            ],
          );
        },
      ),
    );

    return document.save();
  }
}

class _ActualPrintPreviewSheet extends StatelessWidget {
  const _ActualPrintPreviewSheet({
    required this.customerName,
    required this.customerMobile,
    required this.alternateMobile,
    required this.statusLabel,
    required this.deliveryDate,
    required this.purity,
    required this.making,
    required this.gst,
    required this.totalQuantity,
    required this.totalGrossWeight,
    required this.totalLessWeight,
    required this.totalNetWeight,
    required this.items,
  });

  final String customerName;
  final String customerMobile;
  final String alternateMobile;
  final String statusLabel;
  final String deliveryDate;
  final String purity;
  final String making;
  final String gst;
  final String totalQuantity;
  final String totalGrossWeight;
  final String totalLessWeight;
  final String totalNetWeight;
  final List<_EstimateItemDraft> items;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text('Actual PDF Preview'),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Double-click to enlarge on desktop, or pinch to zoom in and out on touch devices.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade700),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Card(
                clipBehavior: Clip.antiAlias,
                child: PdfPreview(
                  canChangePageFormat: false,
                  canChangeOrientation: false,
                  canDebug: false,
                  allowSharing: false,
                  pdfFileName: 'actual-preview.pdf',
                  build: _buildActualPdf,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<Uint8List> _buildActualPdf(PdfPageFormat format) async {
    final document = pw.Document();
    final actualItems = items.where((item) => !item.isEmpty).toList();

    final longestItemNameLength = actualItems.fold<int>(0, (maxLength, item) {
      final currentLength = item.nameController.text.trim().length;
      return currentLength > maxLength ? currentLength : maxLength;
    });
    var itemNameColumnWidth = 56.0 + (longestItemNameLength * 2.2);
    if (itemNameColumnWidth < 72) {
      itemNameColumnWidth = 72;
    } else if (itemNameColumnWidth > 118) {
      itemNameColumnWidth = 118;
    }

    document.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a5,
        margin: const pw.EdgeInsets.all(16),
        build: (context) {
          final headingStyle = pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.black,
          );
          final labelStyle = pw.TextStyle(
            fontSize: 8,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.black,
          );
          final valueStyle = pw.TextStyle(
            fontSize: 8.4,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.black,
          );
          final tableStyle = const pw.TextStyle(
            fontSize: 8.2,
            color: PdfColors.black,
          );
          final tableHeaderStyle = pw.TextStyle(
            fontSize: 8.2,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.black,
          );

          pw.Widget infoCell(String label, String value) {
            return pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 6,
                vertical: 4,
              ),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(label, style: labelStyle),
                  pw.SizedBox(height: 2),
                  pw.Text(value, style: valueStyle, maxLines: 1),
                ],
              ),
            );
          }

          pw.Widget tableCell(
            String text, {
            required pw.TextStyle style,
            pw.Alignment alignment = pw.Alignment.centerLeft,
            PdfColor? backgroundColor,
          }) {
            return pw.Container(
              alignment: alignment,
              color: backgroundColor,
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 4,
                vertical: 4,
              ),
              child: pw.Text(
                text.isEmpty ? ' ' : text,
                style: style,
                maxLines: 1,
                textAlign: alignment == pw.Alignment.center
                    ? pw.TextAlign.center
                    : alignment == pw.Alignment.centerRight
                    ? pw.TextAlign.right
                    : pw.TextAlign.left,
              ),
            );
          }

          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              pw.Center(child: pw.Text('Actual', style: headingStyle)),
              pw.SizedBox(height: 10),
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(flex: 2, child: infoCell('Name', customerName)),
                  pw.SizedBox(width: 8),
                  pw.Expanded(child: infoCell('Status', statusLabel)),
                  pw.SizedBox(width: 8),
                  pw.Expanded(child: infoCell('Delivery Date', deliveryDate)),
                ],
              ),
              pw.SizedBox(height: 6),
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: infoCell('Whatsapp Number', customerMobile),
                  ),
                  pw.SizedBox(width: 8),
                  pw.Expanded(
                    child: infoCell('Alternate Mobile', alternateMobile),
                  ),
                ],
              ),
              pw.SizedBox(height: 6),
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(child: infoCell('Purity', purity)),
                  pw.SizedBox(width: 8),
                  pw.Expanded(child: infoCell('Making', making)),
                  pw.SizedBox(width: 8),
                  pw.Expanded(child: infoCell('GST', gst)),
                ],
              ),
              pw.SizedBox(height: 8),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey400),
                columnWidths: {
                  0: const pw.FixedColumnWidth(20),
                  1: const pw.FixedColumnWidth(34),
                  2: pw.FixedColumnWidth(itemNameColumnWidth),
                  3: const pw.FixedColumnWidth(20),
                  4: const pw.FixedColumnWidth(38),
                  5: const pw.FixedColumnWidth(34),
                  6: const pw.FixedColumnWidth(38),
                  7: const pw.FlexColumnWidth(1.2),
                },
                defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.grey200,
                    ),
                    children: [
                      tableCell(
                        'S No.',
                        style: tableHeaderStyle,
                        backgroundColor: PdfColors.grey200,
                      ),
                      tableCell(
                        'Purity',
                        style: tableHeaderStyle,
                        backgroundColor: PdfColors.grey200,
                      ),
                      tableCell(
                        'Item Name',
                        style: tableHeaderStyle,
                        backgroundColor: PdfColors.grey200,
                      ),
                      tableCell(
                        'Qty',
                        style: tableHeaderStyle,
                        alignment: pw.Alignment.center,
                        backgroundColor: PdfColors.grey200,
                      ),
                      tableCell(
                        'Gross',
                        style: tableHeaderStyle,
                        alignment: pw.Alignment.centerRight,
                        backgroundColor: PdfColors.grey200,
                      ),
                      tableCell(
                        'Less',
                        style: tableHeaderStyle,
                        alignment: pw.Alignment.centerRight,
                        backgroundColor: PdfColors.grey200,
                      ),
                      tableCell(
                        'Nett',
                        style: tableHeaderStyle,
                        alignment: pw.Alignment.centerRight,
                        backgroundColor: PdfColors.grey200,
                      ),
                      tableCell(
                        'Notes',
                        style: tableHeaderStyle,
                        backgroundColor: PdfColors.grey200,
                      ),
                    ],
                  ),
                  ...actualItems.asMap().entries.map(
                    (entry) => pw.TableRow(
                      children: [
                        tableCell('${entry.key + 1}', style: tableStyle),
                        tableCell(
                          entry.value.purityController.text.trim(),
                          style: tableStyle,
                        ),
                        tableCell(
                          entry.value.nameController.text.trim(),
                          style: tableStyle,
                        ),
                        tableCell(
                          entry.value.quantityController.text.trim(),
                          style: tableStyle,
                          alignment: pw.Alignment.center,
                        ),
                        tableCell(
                          _formatWeightFixed3(entry.value.grossWeight),
                          style: tableStyle,
                          alignment: pw.Alignment.centerRight,
                        ),
                        tableCell(
                          _formatWeight3(entry.value.lessWeight),
                          style: tableStyle,
                          alignment: pw.Alignment.centerRight,
                        ),
                        tableCell(
                          _formatWeightFixed3(entry.value.actualNetWeight),
                          style: tableStyle,
                          alignment: pw.Alignment.centerRight,
                        ),
                        tableCell(
                          entry.value.notesController.text.trim(),
                          style: tableStyle,
                        ),
                      ],
                    ),
                  ),
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.grey100,
                    ),
                    children: [
                      tableCell(
                        '',
                        style: tableHeaderStyle,
                        backgroundColor: PdfColors.grey100,
                      ),
                      tableCell(
                        '',
                        style: tableHeaderStyle,
                        backgroundColor: PdfColors.grey100,
                      ),
                      tableCell(
                        'Total',
                        style: tableHeaderStyle,
                        backgroundColor: PdfColors.grey100,
                      ),
                      tableCell(
                        totalQuantity,
                        style: tableHeaderStyle,
                        alignment: pw.Alignment.center,
                        backgroundColor: PdfColors.grey100,
                      ),
                      tableCell(
                        totalGrossWeight,
                        style: tableHeaderStyle,
                        alignment: pw.Alignment.centerRight,
                        backgroundColor: PdfColors.grey100,
                      ),
                      tableCell(
                        totalLessWeight,
                        style: tableHeaderStyle,
                        alignment: pw.Alignment.centerRight,
                        backgroundColor: PdfColors.grey100,
                      ),
                      tableCell(
                        totalNetWeight,
                        style: tableHeaderStyle,
                        alignment: pw.Alignment.centerRight,
                        backgroundColor: PdfColors.grey100,
                      ),
                      tableCell(
                        '',
                        style: tableHeaderStyle,
                        backgroundColor: PdfColors.grey100,
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 8),
              pw.Row(
                children: [
                  pw.Spacer(),
                  pw.Expanded(
                    flex: 2,
                    child: infoCell('Actual Nett Weight', '$totalNetWeight gm'),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    return document.save();
  }
}
