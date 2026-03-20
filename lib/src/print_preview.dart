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

class _CombinedBillPrintPreviewSheet extends StatelessWidget {
  const _CombinedBillPrintPreviewSheet({
    required this.customerName,
    required this.customerMobile,
    required this.alternateMobile,
    required this.statusLabel,
    required this.occasion,
    required this.occasionDate,
    required this.deliveryDate,
    required this.purity,
    required this.making,
    required this.gstRate,
    required this.estimateTotalQuantity,
    required this.estimateWeightRange,
    required this.actualTotalGrossWeight,
    required this.actualTotalLessWeight,
    required this.actualTotalNetWeight,
    required this.advanceTotalAmount,
    required this.advanceOldItemsTotalAmount,
    required this.advanceNetWeight,
    required this.newItemsSubtotal,
    required this.newItemsTotalGst,
    required this.newItemsGrandTotal,
    required this.balanceAfterAdvance,
    required this.gold22Rate,
    required this.gold18Rate,
    required this.silverRate,
    required this.estimateItems,
    required this.advanceItems,
    required this.oldItems,
    required this.newItems,
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
  final double gstRate;
  final String estimateTotalQuantity;
  final String estimateWeightRange;
  final String actualTotalGrossWeight;
  final String actualTotalLessWeight;
  final String actualTotalNetWeight;
  final double advanceTotalAmount;
  final double advanceOldItemsTotalAmount;
  final double advanceNetWeight;
  final double newItemsSubtotal;
  final double newItemsTotalGst;
  final double newItemsGrandTotal;
  final double balanceAfterAdvance;
  final double gold22Rate;
  final double gold18Rate;
  final double silverRate;
  final List<_EstimateItemDraft> estimateItems;
  final List<_AdvanceValuationDraft> advanceItems;
  final List<_AdvanceOldItemDraft> oldItems;
  final List<_NewItemDraft> newItems;

  double _newItemRateFor(String category) {
    switch (category) {
      case 'Gold22kt':
        return gold22Rate;
      case 'Gold18kt':
        return gold18Rate;
      case 'Silver':
        return silverRate;
      default:
        return 0;
    }
  }

  double _newItemBhav(_NewItemDraft item) {
    return item.bhav > 0 ? item.bhav : _newItemRateFor(item.category);
  }

  double _newItemBaseAmount(_NewItemDraft item) {
    final rate = _newItemBhav(item);
    switch (item.makingType) {
      case 'FixRate':
        return item.makingCharge;
      case 'PerGram':
        return (rate + item.makingCharge) * item.netWeight;
      case 'Percentage':
        return (rate + (rate * (item.makingCharge / 100))) * item.netWeight;
      case 'TotalMaking':
        return (rate * item.netWeight) + item.makingCharge;
      default:
        return (rate * item.netWeight) + item.makingCharge;
    }
  }

  double _newItemGstAmount(_NewItemDraft item) {
    if (!item.gstEnabled || item.makingType == 'FixRate') {
      return 0;
    }
    return _newItemBaseAmount(item) * (gstRate / 100);
  }

  double _newItemTotal(_NewItemDraft item) {
    final total =
        _newItemBaseAmount(item) +
        _newItemGstAmount(item) +
        item.additionalCharge;
    return total > 0 ? total : 0;
  }

  String _newItemCategoryLabel(String category) {
    switch (category) {
      case 'Gold22kt':
        return '22K';
      case 'Gold18kt':
        return '18K';
      case 'Silver':
        return 'Silver';
      default:
        return category;
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
        text: 'Shree:',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text('Combined Bill PDF Preview'),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Single-page combined preview using the current draft from all bill sections.',
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
                  pdfFileName: 'combined-bill-preview.pdf',
                  build: _buildCombinedBillPdf,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<Uint8List> _buildCombinedBillPdf(PdfPageFormat format) async {
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

    final estimateList = estimateItems.where((item) => !item.isEmpty).toList();
    final advanceList = advanceItems.where((item) => !item.isEmpty).toList();
    final oldItemList = oldItems.where((item) => !item.isEmpty).toList();
    final newItemList = newItems.where((item) => !item.isEmpty).toList();
    final totalRowCount =
        (estimateList.length * 2) +
        advanceList.length +
        oldItemList.length +
        newItemList.length;
    final compactFontSize = totalRowCount > 28
        ? 5.4
        : totalRowCount > 18
        ? 5.8
        : totalRowCount > 10
        ? 6.3
        : 6.8;
    final headerFontSize = compactFontSize + 0.3;

    document.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a3.landscape,
        margin: const pw.EdgeInsets.all(14),
        build: (context) {
          final headingStyle = pw.TextStyle(
            fontSize: 13,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.black,
          );
          final subheadingStyle = pw.TextStyle(
            fontSize: 7.2,
            color: PdfColors.grey700,
          );
          final labelStyle = pw.TextStyle(
            fontSize: 6.8,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.black,
          );
          final valueStyle = pw.TextStyle(
            fontSize: 7.2,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.black,
          );
          final tableStyle = pw.TextStyle(
            fontSize: compactFontSize,
            color: PdfColors.black,
          );
          final tableHeaderStyle = pw.TextStyle(
            fontSize: headerFontSize,
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

          pw.Widget metricCell(String label, String value) {
            return pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 6,
              ),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                border: pw.Border.all(color: PdfColors.grey300),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(label, style: labelStyle),
                  pw.SizedBox(height: 2),
                  pw.Text(value, style: valueStyle),
                ],
              ),
            );
          }

          pw.Widget tableCell(
            String text, {
            required pw.TextStyle style,
            pw.Alignment alignment = pw.Alignment.centerLeft,
            PdfColor? backgroundColor,
            int maxLines = 1,
          }) {
            return pw.Container(
              alignment: alignment,
              color: backgroundColor,
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 3,
                vertical: 3,
              ),
              child: pw.Text(
                text.isEmpty ? ' ' : text,
                style: style,
                maxLines: maxLines,
                textAlign: alignment == pw.Alignment.center
                    ? pw.TextAlign.center
                    : alignment == pw.Alignment.centerRight
                    ? pw.TextAlign.right
                    : pw.TextAlign.left,
              ),
            );
          }

          pw.Widget sectionCard({
            required String title,
            required String subtitle,
            required pw.Widget child,
          }) {
            return pw.Container(
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(title, style: valueStyle),
                  pw.SizedBox(height: 2),
                  pw.Text(subtitle, style: subheadingStyle),
                  pw.SizedBox(height: 6),
                  child,
                ],
              ),
            );
          }

          pw.Widget emptyState(String message) {
            return pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(8),
              decoration: const pw.BoxDecoration(color: PdfColors.grey100),
              child: pw.Text(message, style: tableStyle),
            );
          }

          pw.Widget estimateTable() {
            if (estimateList.isEmpty) return emptyState('No estimate items');
            return pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey400),
              columnWidths: const {
                0: pw.FixedColumnWidth(18),
                1: pw.FixedColumnWidth(30),
                2: pw.FlexColumnWidth(1.8),
                3: pw.FixedColumnWidth(20),
                4: pw.FixedColumnWidth(38),
                5: pw.FixedColumnWidth(34),
                6: pw.FixedColumnWidth(36),
                7: pw.FlexColumnWidth(1.4),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    tableCell(
                      'No.',
                      style: tableHeaderStyle,
                      backgroundColor: PdfColors.grey200,
                      alignment: pw.Alignment.center,
                    ),
                    tableCell(
                      'Purity',
                      style: tableHeaderStyle,
                      backgroundColor: PdfColors.grey200,
                    ),
                    tableCell(
                      'Item',
                      style: tableHeaderStyle,
                      backgroundColor: PdfColors.grey200,
                    ),
                    tableCell(
                      'Qty',
                      style: tableHeaderStyle,
                      backgroundColor: PdfColors.grey200,
                      alignment: pw.Alignment.center,
                    ),
                    tableCell(
                      'Est. Wt',
                      style: tableHeaderStyle,
                      backgroundColor: PdfColors.grey200,
                      alignment: pw.Alignment.centerRight,
                    ),
                    tableCell(
                      'Size',
                      style: tableHeaderStyle,
                      backgroundColor: PdfColors.grey200,
                    ),
                    tableCell(
                      'Length',
                      style: tableHeaderStyle,
                      backgroundColor: PdfColors.grey200,
                    ),
                    tableCell(
                      'Notes',
                      style: tableHeaderStyle,
                      backgroundColor: PdfColors.grey200,
                    ),
                  ],
                ),
                ...estimateList.asMap().entries.map(
                  (entry) => pw.TableRow(
                    children: [
                      tableCell(
                        '${entry.key + 1}',
                        style: tableStyle,
                        alignment: pw.Alignment.center,
                      ),
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
                        alignment: pw.Alignment.centerRight,
                      ),
                      tableCell(
                        entry.value.sizeController.text.trim(),
                        style: tableStyle,
                      ),
                      tableCell(
                        entry.value.lengthController.text.trim(),
                        style: tableStyle,
                      ),
                      tableCell(
                        entry.value.notesController.text.trim(),
                        style: tableStyle,
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey100),
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
                      estimateTotalQuantity,
                      style: tableHeaderStyle,
                      alignment: pw.Alignment.center,
                      backgroundColor: PdfColors.grey100,
                    ),
                    tableCell(
                      estimateWeightRange,
                      style: tableHeaderStyle,
                      alignment: pw.Alignment.centerRight,
                      backgroundColor: PdfColors.grey100,
                    ),
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
                      '',
                      style: tableHeaderStyle,
                      backgroundColor: PdfColors.grey100,
                    ),
                  ],
                ),
              ],
            );
          }

          pw.Widget actualTable() {
            if (estimateList.isEmpty) return emptyState('No actual items');
            return pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey400),
              columnWidths: const {
                0: pw.FixedColumnWidth(18),
                1: pw.FixedColumnWidth(30),
                2: pw.FlexColumnWidth(1.7),
                3: pw.FixedColumnWidth(20),
                4: pw.FixedColumnWidth(34),
                5: pw.FixedColumnWidth(34),
                6: pw.FixedColumnWidth(34),
                7: pw.FixedColumnWidth(34),
                8: pw.FixedColumnWidth(36),
                9: pw.FlexColumnWidth(1.4),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    tableCell(
                      'No.',
                      style: tableHeaderStyle,
                      backgroundColor: PdfColors.grey200,
                      alignment: pw.Alignment.center,
                    ),
                    tableCell(
                      'Purity',
                      style: tableHeaderStyle,
                      backgroundColor: PdfColors.grey200,
                    ),
                    tableCell(
                      'Item',
                      style: tableHeaderStyle,
                      backgroundColor: PdfColors.grey200,
                    ),
                    tableCell(
                      'Qty',
                      style: tableHeaderStyle,
                      backgroundColor: PdfColors.grey200,
                      alignment: pw.Alignment.center,
                    ),
                    tableCell(
                      'Gross',
                      style: tableHeaderStyle,
                      backgroundColor: PdfColors.grey200,
                      alignment: pw.Alignment.centerRight,
                    ),
                    tableCell(
                      'Less',
                      style: tableHeaderStyle,
                      backgroundColor: PdfColors.grey200,
                      alignment: pw.Alignment.centerRight,
                    ),
                    tableCell(
                      'Nett',
                      style: tableHeaderStyle,
                      backgroundColor: PdfColors.grey200,
                      alignment: pw.Alignment.centerRight,
                    ),
                    tableCell(
                      'Size',
                      style: tableHeaderStyle,
                      backgroundColor: PdfColors.grey200,
                    ),
                    tableCell(
                      'Length',
                      style: tableHeaderStyle,
                      backgroundColor: PdfColors.grey200,
                    ),
                    tableCell(
                      'Notes',
                      style: tableHeaderStyle,
                      backgroundColor: PdfColors.grey200,
                    ),
                  ],
                ),
                ...estimateList.asMap().entries.map(
                  (entry) => pw.TableRow(
                    children: [
                      tableCell(
                        '${entry.key + 1}',
                        style: tableStyle,
                        alignment: pw.Alignment.center,
                      ),
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
                        entry.value.sizeController.text.trim(),
                        style: tableStyle,
                      ),
                      tableCell(
                        entry.value.lengthController.text.trim(),
                        style: tableStyle,
                      ),
                      tableCell(
                        entry.value.notesController.text.trim(),
                        style: tableStyle,
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey100),
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
                      estimateTotalQuantity,
                      style: tableHeaderStyle,
                      alignment: pw.Alignment.center,
                      backgroundColor: PdfColors.grey100,
                    ),
                    tableCell(
                      actualTotalGrossWeight,
                      style: tableHeaderStyle,
                      alignment: pw.Alignment.centerRight,
                      backgroundColor: PdfColors.grey100,
                    ),
                    tableCell(
                      actualTotalLessWeight,
                      style: tableHeaderStyle,
                      alignment: pw.Alignment.centerRight,
                      backgroundColor: PdfColors.grey100,
                    ),
                    tableCell(
                      actualTotalNetWeight,
                      style: tableHeaderStyle,
                      alignment: pw.Alignment.centerRight,
                      backgroundColor: PdfColors.grey100,
                    ),
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
                      '',
                      style: tableHeaderStyle,
                      backgroundColor: PdfColors.grey100,
                    ),
                  ],
                ),
              ],
            );
          }

          pw.Widget advanceTable() {
            if (advanceList.isEmpty && oldItemList.isEmpty) {
              return emptyState('No advance data');
            }
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                if (advanceList.isNotEmpty)
                  pw.Table(
                    border: pw.TableBorder.all(color: PdfColors.grey400),
                    columnWidths: const {
                      0: pw.FixedColumnWidth(34),
                      1: pw.FixedColumnWidth(30),
                      2: pw.FixedColumnWidth(48),
                      3: pw.FixedColumnWidth(42),
                      4: pw.FixedColumnWidth(40),
                      5: pw.FixedColumnWidth(42),
                      6: pw.FixedColumnWidth(42),
                    },
                    children: [
                      pw.TableRow(
                        decoration: const pw.BoxDecoration(
                          color: PdfColors.grey200,
                        ),
                        children: [
                          tableCell(
                            'Date',
                            style: tableHeaderStyle,
                            backgroundColor: PdfColors.grey200,
                          ),
                          tableCell(
                            'Mode',
                            style: tableHeaderStyle,
                            backgroundColor: PdfColors.grey200,
                          ),
                          tableCell(
                            'Cheque No.',
                            style: tableHeaderStyle,
                            backgroundColor: PdfColors.grey200,
                          ),
                          tableCell(
                            'Amount',
                            style: tableHeaderStyle,
                            backgroundColor: PdfColors.grey200,
                            alignment: pw.Alignment.centerRight,
                          ),
                          tableCell(
                            'Rate22',
                            style: tableHeaderStyle,
                            backgroundColor: PdfColors.grey200,
                            alignment: pw.Alignment.centerRight,
                          ),
                          tableCell(
                            'Making%',
                            style: tableHeaderStyle,
                            backgroundColor: PdfColors.grey200,
                            alignment: pw.Alignment.centerRight,
                          ),
                          tableCell(
                            'Net Wt',
                            style: tableHeaderStyle,
                            backgroundColor: PdfColors.grey200,
                            alignment: pw.Alignment.centerRight,
                          ),
                        ],
                      ),
                      ...advanceList.map(
                        (item) => pw.TableRow(
                          children: [
                            tableCell(
                              _formatEntryDate(item.date),
                              style: tableStyle,
                            ),
                            tableCell(item.mode.label, style: tableStyle),
                            tableCell(
                              item.chequeNumber ?? '-',
                              style: tableStyle,
                            ),
                            tableCell(
                              _formatCurrency(item.amount),
                              style: tableStyle,
                              alignment: pw.Alignment.centerRight,
                            ),
                            tableCell(
                              _formatCurrency(item.rate),
                              style: tableStyle,
                              alignment: pw.Alignment.centerRight,
                            ),
                            tableCell(
                              '${item.rateMaking.toStringAsFixed(2)}%',
                              style: tableStyle,
                              alignment: pw.Alignment.centerRight,
                            ),
                            tableCell(
                              _formatWeight3(item.weight),
                              style: tableStyle,
                              alignment: pw.Alignment.centerRight,
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
                            'Total',
                            style: tableHeaderStyle,
                            backgroundColor: PdfColors.grey100,
                          ),
                          tableCell(
                            '',
                            style: tableHeaderStyle,
                            backgroundColor: PdfColors.grey100,
                          ),
                          tableCell(
                            _formatCurrency(advanceTotalAmount),
                            style: tableHeaderStyle,
                            alignment: pw.Alignment.centerRight,
                            backgroundColor: PdfColors.grey100,
                          ),
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
                            _formatWeight3(advanceNetWeight),
                            style: tableHeaderStyle,
                            alignment: pw.Alignment.centerRight,
                            backgroundColor: PdfColors.grey100,
                          ),
                        ],
                      ),
                    ],
                  ),
                if (advanceList.isNotEmpty && oldItemList.isNotEmpty)
                  pw.SizedBox(height: 6),
                if (oldItemList.isNotEmpty)
                  pw.Table(
                    border: pw.TableBorder.all(color: PdfColors.grey400),
                    columnWidths: const {
                      0: pw.FixedColumnWidth(34),
                      1: pw.FlexColumnWidth(1.5),
                      2: pw.FixedColumnWidth(38),
                      3: pw.FixedColumnWidth(34),
                      4: pw.FixedColumnWidth(34),
                      5: pw.FixedColumnWidth(34),
                      6: pw.FixedColumnWidth(30),
                      7: pw.FixedColumnWidth(44),
                    },
                    children: [
                      pw.TableRow(
                        decoration: const pw.BoxDecoration(
                          color: PdfColors.grey200,
                        ),
                        children: [
                          tableCell(
                            'Date',
                            style: tableHeaderStyle,
                            backgroundColor: PdfColors.grey200,
                          ),
                          tableCell(
                            'Item',
                            style: tableHeaderStyle,
                            backgroundColor: PdfColors.grey200,
                          ),
                          tableCell(
                            'Rate',
                            style: tableHeaderStyle,
                            backgroundColor: PdfColors.grey200,
                            alignment: pw.Alignment.centerRight,
                          ),
                          tableCell(
                            'Gross',
                            style: tableHeaderStyle,
                            backgroundColor: PdfColors.grey200,
                            alignment: pw.Alignment.centerRight,
                          ),
                          tableCell(
                            'Less',
                            style: tableHeaderStyle,
                            backgroundColor: PdfColors.grey200,
                            alignment: pw.Alignment.centerRight,
                          ),
                          tableCell(
                            'Nett',
                            style: tableHeaderStyle,
                            backgroundColor: PdfColors.grey200,
                            alignment: pw.Alignment.centerRight,
                          ),
                          tableCell(
                            'Tanch',
                            style: tableHeaderStyle,
                            backgroundColor: PdfColors.grey200,
                            alignment: pw.Alignment.centerRight,
                          ),
                          tableCell(
                            'Amount',
                            style: tableHeaderStyle,
                            backgroundColor: PdfColors.grey200,
                            alignment: pw.Alignment.centerRight,
                          ),
                        ],
                      ),
                      ...oldItemList.map(
                        (item) => pw.TableRow(
                          children: [
                            tableCell(
                              _formatEntryDate(item.date),
                              style: tableStyle,
                            ),
                            tableCell(
                              item.itemNameController.text.trim(),
                              style: tableStyle,
                            ),
                            tableCell(
                              _formatCurrency(item.returnRate),
                              style: tableStyle,
                              alignment: pw.Alignment.centerRight,
                            ),
                            tableCell(
                              _formatWeight3(item.grossWeight),
                              style: tableStyle,
                              alignment: pw.Alignment.centerRight,
                            ),
                            tableCell(
                              _formatWeight3(item.lessWeight),
                              style: tableStyle,
                              alignment: pw.Alignment.centerRight,
                            ),
                            tableCell(
                              _formatWeight3(item.nettWeight),
                              style: tableStyle,
                              alignment: pw.Alignment.centerRight,
                            ),
                            tableCell(
                              _formatWeight3(item.tanch),
                              style: tableStyle,
                              alignment: pw.Alignment.centerRight,
                            ),
                            tableCell(
                              _formatCurrency(item.amount),
                              style: tableStyle,
                              alignment: pw.Alignment.centerRight,
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
                            'Total',
                            style: tableHeaderStyle,
                            backgroundColor: PdfColors.grey100,
                          ),
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
                            '',
                            style: tableHeaderStyle,
                            backgroundColor: PdfColors.grey100,
                          ),
                          tableCell(
                            _formatCurrency(advanceOldItemsTotalAmount),
                            style: tableHeaderStyle,
                            alignment: pw.Alignment.centerRight,
                            backgroundColor: PdfColors.grey100,
                          ),
                        ],
                      ),
                    ],
                  ),
              ],
            );
          }

          pw.Widget newItemsTable() {
            if (newItemList.isEmpty) return emptyState('No new item entries');
            return pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey400),
              columnWidths: const {
                0: pw.FixedColumnWidth(18),
                1: pw.FlexColumnWidth(1.55),
                2: pw.FixedColumnWidth(32),
                3: pw.FixedColumnWidth(40),
                4: pw.FlexColumnWidth(1.05),
                5: pw.FixedColumnWidth(44),
                6: pw.FixedColumnWidth(40),
                7: pw.FixedColumnWidth(34),
                8: pw.FixedColumnWidth(34),
                9: pw.FixedColumnWidth(34),
                10: pw.FixedColumnWidth(38),
                11: pw.FixedColumnWidth(24),
                12: pw.FixedColumnWidth(44),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    tableCell(
                      'No.',
                      style: tableHeaderStyle,
                      backgroundColor: PdfColors.grey200,
                      alignment: pw.Alignment.center,
                    ),
                    tableCell(
                      'Item',
                      style: tableHeaderStyle,
                      backgroundColor: PdfColors.grey200,
                    ),
                    tableCell(
                      'Cat',
                      style: tableHeaderStyle,
                      backgroundColor: PdfColors.grey200,
                    ),
                    tableCell(
                      'Bhav',
                      style: tableHeaderStyle,
                      backgroundColor: PdfColors.grey200,
                      alignment: pw.Alignment.centerRight,
                    ),
                    tableCell(
                      'Notes',
                      style: tableHeaderStyle,
                      backgroundColor: PdfColors.grey200,
                    ),
                    tableCell(
                      'Making Type',
                      style: tableHeaderStyle,
                      backgroundColor: PdfColors.grey200,
                      maxLines: 2,
                    ),
                    tableCell(
                      'Making',
                      style: tableHeaderStyle,
                      backgroundColor: PdfColors.grey200,
                      alignment: pw.Alignment.centerRight,
                    ),
                    tableCell(
                      'Gross',
                      style: tableHeaderStyle,
                      backgroundColor: PdfColors.grey200,
                      alignment: pw.Alignment.centerRight,
                    ),
                    tableCell(
                      'Less',
                      style: tableHeaderStyle,
                      backgroundColor: PdfColors.grey200,
                      alignment: pw.Alignment.centerRight,
                    ),
                    tableCell(
                      'Nett',
                      style: tableHeaderStyle,
                      backgroundColor: PdfColors.grey200,
                      alignment: pw.Alignment.centerRight,
                    ),
                    tableCell(
                      'Addl.',
                      style: tableHeaderStyle,
                      backgroundColor: PdfColors.grey200,
                      alignment: pw.Alignment.centerRight,
                    ),
                    tableCell(
                      'GST',
                      style: tableHeaderStyle,
                      backgroundColor: PdfColors.grey200,
                      alignment: pw.Alignment.center,
                    ),
                    tableCell(
                      'Total',
                      style: tableHeaderStyle,
                      backgroundColor: PdfColors.grey200,
                      alignment: pw.Alignment.centerRight,
                    ),
                  ],
                ),
                ...newItemList.asMap().entries.map(
                  (entry) => pw.TableRow(
                    children: [
                      tableCell(
                        '${entry.key + 1}',
                        style: tableStyle,
                        alignment: pw.Alignment.center,
                      ),
                      tableCell(
                        entry.value.nameController.text.trim(),
                        style: tableStyle,
                      ),
                      tableCell(
                        _newItemCategoryLabel(entry.value.category),
                        style: tableStyle,
                      ),
                      tableCell(
                        _formatCurrency(_newItemBhav(entry.value)),
                        style: tableStyle,
                        alignment: pw.Alignment.centerRight,
                      ),
                      tableCell(
                        entry.value.notesController.text.trim(),
                        style: tableStyle,
                        maxLines: 2,
                      ),
                      tableCell(entry.value.makingType, style: tableStyle),
                      tableCell(
                        _formatCurrency(entry.value.makingCharge),
                        style: tableStyle,
                        alignment: pw.Alignment.centerRight,
                      ),
                      tableCell(
                        _formatWeightFixed3(entry.value.grossWeight),
                        style: tableStyle,
                        alignment: pw.Alignment.centerRight,
                      ),
                      tableCell(
                        _formatWeightFixed3(entry.value.lessWeight),
                        style: tableStyle,
                        alignment: pw.Alignment.centerRight,
                      ),
                      tableCell(
                        _formatWeightFixed3(entry.value.netWeight),
                        style: tableStyle,
                        alignment: pw.Alignment.centerRight,
                      ),
                      tableCell(
                        _formatCurrency(entry.value.additionalCharge),
                        style: tableStyle,
                        alignment: pw.Alignment.centerRight,
                      ),
                      tableCell(
                        entry.value.gstEnabled ? 'Yes' : 'No',
                        style: tableStyle,
                        alignment: pw.Alignment.center,
                      ),
                      tableCell(
                        _formatCurrency(_newItemTotal(entry.value)),
                        style: tableStyle,
                        alignment: pw.Alignment.centerRight,
                      ),
                    ],
                  ),
                ),
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey100),
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
                      _formatWeight3(
                        newItemList.fold<double>(
                          0,
                          (sum, item) => sum + item.netWeight,
                        ),
                      ),
                      style: tableHeaderStyle,
                      alignment: pw.Alignment.centerRight,
                      backgroundColor: PdfColors.grey100,
                    ),
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
                      _formatCurrency(newItemsGrandTotal),
                      style: tableHeaderStyle,
                      alignment: pw.Alignment.centerRight,
                      backgroundColor: PdfColors.grey100,
                    ),
                  ],
                ),
              ],
            );
          }

          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              pw.Center(
                child: shreeHeaderImage == null
                    ? pw.Text('Combined Bill Preview', style: headingStyle)
                    : pw.Column(
                        children: [
                          pw.Image(shreeHeaderImage, width: 110),
                          pw.SizedBox(height: 4),
                          pw.Text('Combined Bill Preview', style: headingStyle),
                        ],
                      ),
              ),
              pw.SizedBox(height: 4),
              pw.Center(
                child: pw.Text(
                  'Single page summary of Estimate, Actual, Advance and New Items',
                  style: subheadingStyle,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(flex: 2, child: infoCell('Name', customerName)),
                  pw.SizedBox(width: 6),
                  pw.Expanded(child: infoCell('Status', statusLabel)),
                  pw.SizedBox(width: 6),
                  pw.Expanded(
                    child: infoCell('Whatsapp Number', customerMobile),
                  ),
                  pw.SizedBox(width: 6),
                  pw.Expanded(child: infoCell('Delivery Date', deliveryDate)),
                ],
              ),
              pw.SizedBox(height: 6),
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: infoCell('Alternate Mobile', alternateMobile),
                  ),
                  pw.SizedBox(width: 6),
                  pw.Expanded(child: infoCell('Occasion', occasion)),
                  pw.SizedBox(width: 6),
                  pw.Expanded(child: infoCell('Occasion Date', occasionDate)),
                  pw.SizedBox(width: 6),
                  pw.Expanded(
                    child: infoCell(
                      'Rates',
                      '22K ${_formatCurrency(gold22Rate)} | 18K ${_formatCurrency(gold18Rate)} | Silver ${_formatCurrency(silverRate)}',
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 8),
              pw.Row(
                children: [
                  pw.Expanded(
                    child: metricCell('Estimate Range', estimateWeightRange),
                  ),
                  pw.SizedBox(width: 6),
                  pw.Expanded(
                    child: metricCell(
                      'Actual Nett',
                      '$actualTotalNetWeight gm',
                    ),
                  ),
                  pw.SizedBox(width: 6),
                  pw.Expanded(
                    child: metricCell(
                      'Advance Credit',
                      _formatCurrency(
                        advanceTotalAmount + advanceOldItemsTotalAmount,
                      ),
                    ),
                  ),
                  pw.SizedBox(width: 6),
                  pw.Expanded(
                    child: metricCell(
                      'New Items Total',
                      _formatCurrency(newItemsGrandTotal),
                    ),
                  ),
                  pw.SizedBox(width: 6),
                  pw.Expanded(
                    child: metricCell(
                      balanceAfterAdvance < 0
                          ? 'Excess Advance'
                          : 'Balance After Advance',
                      _formatCurrency(balanceAfterAdvance.abs()),
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 8),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                  children: [
                    pw.Expanded(
                      child: pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Expanded(
                            child: sectionCard(
                              title: 'Estimate',
                              subtitle:
                                  'Qty $estimateTotalQuantity | Range $estimateWeightRange gm | Purity $purity | Making $making | GST ${gstRate.toStringAsFixed(2)}%',
                              child: estimateTable(),
                            ),
                          ),
                          pw.SizedBox(width: 8),
                          pw.Expanded(
                            child: sectionCard(
                              title: 'Actual',
                              subtitle:
                                  'Gross $actualTotalGrossWeight gm | Less $actualTotalLessWeight gm | Nett $actualTotalNetWeight gm',
                              child: actualTable(),
                            ),
                          ),
                        ],
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Expanded(
                      child: pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Expanded(
                            child: sectionCard(
                              title: 'Advance',
                              subtitle:
                                  'Cash/UPI ${_formatCurrency(advanceTotalAmount)} | Old Items ${_formatCurrency(advanceOldItemsTotalAmount)} | Net Wt ${_formatWeight3(advanceNetWeight)} gm',
                              child: advanceTable(),
                            ),
                          ),
                          pw.SizedBox(width: 8),
                          pw.Expanded(
                            child: sectionCard(
                              title: 'New Items',
                              subtitle:
                                  'Base + Extras ${_formatCurrency(newItemsSubtotal)} | GST ${_formatCurrency(newItemsTotalGst)} | Grand Total ${_formatCurrency(newItemsGrandTotal)}',
                              child: newItemsTable(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    return document.save();
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
            int maxLines = 1,
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
                maxLines: maxLines,
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
                        'Serial No.',
                        style: tableHeaderStyle,
                        backgroundColor: PdfColors.grey200,
                        maxLines: 2,
                      ),
                      tableCell(
                        'Purity',
                        style: tableHeaderStyle,
                        backgroundColor: PdfColors.grey200,
                        maxLines: 2,
                      ),
                      tableCell(
                        'Item Name',
                        style: tableHeaderStyle,
                        backgroundColor: PdfColors.grey200,
                        maxLines: 2,
                      ),
                      tableCell(
                        'Quantity',
                        style: tableHeaderStyle,
                        alignment: pw.Alignment.center,
                        backgroundColor: PdfColors.grey200,
                        maxLines: 2,
                      ),
                      tableCell(
                        'Gross Weight',
                        style: tableHeaderStyle,
                        alignment: pw.Alignment.centerRight,
                        backgroundColor: PdfColors.grey200,
                        maxLines: 2,
                      ),
                      tableCell(
                        'Less Weight',
                        style: tableHeaderStyle,
                        alignment: pw.Alignment.centerRight,
                        backgroundColor: PdfColors.grey200,
                        maxLines: 2,
                      ),
                      tableCell(
                        'Nett Weight',
                        style: tableHeaderStyle,
                        alignment: pw.Alignment.centerRight,
                        backgroundColor: PdfColors.grey200,
                        maxLines: 2,
                      ),
                      tableCell(
                        'Notes',
                        style: tableHeaderStyle,
                        backgroundColor: PdfColors.grey200,
                        maxLines: 2,
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

class _NewItemsPrintPreviewSheet extends StatelessWidget {
  const _NewItemsPrintPreviewSheet({
    required this.customerName,
    required this.customerMobile,
    required this.alternateMobile,
    required this.deliveryDate,
    required this.gstRate,
    required this.gold22Rate,
    required this.gold18Rate,
    required this.silverRate,
    required this.subtotal,
    required this.totalGst,
    required this.grandTotal,
    required this.items,
  });

  final String customerName;
  final String customerMobile;
  final String alternateMobile;
  final String deliveryDate;
  final double gstRate;
  final double gold22Rate;
  final double gold18Rate;
  final double silverRate;
  final double subtotal;
  final double totalGst;
  final double grandTotal;
  final List<_NewItemDraft> items;

  double _rateFor(String category) {
    switch (category) {
      case 'Gold22kt':
        return gold22Rate;
      case 'Gold18kt':
        return gold18Rate;
      case 'Silver':
        return silverRate;
      default:
        return 0;
    }
  }

  double _bhavFor(_NewItemDraft item) {
    return item.bhav > 0 ? item.bhav : _rateFor(item.category);
  }

  double _baseAmount(_NewItemDraft item) {
    final rate = _bhavFor(item);
    switch (item.makingType) {
      case 'FixRate':
        return item.makingCharge;
      case 'PerGram':
        return (rate + item.makingCharge) * item.netWeight;
      case 'Percentage':
        return (rate + (rate * (item.makingCharge / 100))) * item.netWeight;
      case 'TotalMaking':
        return (rate * item.netWeight) + item.makingCharge;
      default:
        return (rate * item.netWeight) + item.makingCharge;
    }
  }

  double _gstAmount(_NewItemDraft item) {
    if (!item.gstEnabled || item.makingType == 'FixRate') {
      return 0;
    }
    return _baseAmount(item) * (gstRate / 100);
  }

  double _lineTotal(_NewItemDraft item) {
    final total = _baseAmount(item) + _gstAmount(item) + item.additionalCharge;
    return total > 0 ? total : 0;
  }

  String _notesFor(_NewItemDraft item) {
    final notes = item.notesController.text.trim();
    return notes.isEmpty ? '-' : notes;
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
        text: 'Shree:',
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

  String _categoryLabel(String category) {
    switch (category) {
      case 'Gold22kt':
        return '22K';
      case 'Gold18kt':
        return '18K';
      case 'Silver':
        return 'Silver';
      default:
        return category;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text('New Items PDF Preview'),
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
                  pdfFileName: 'new-items-preview.pdf',
                  build: _buildNewItemsPdf,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<Uint8List> _buildNewItemsPdf(PdfPageFormat format) async {
    final document = pw.Document();
    final newItems = items.where((item) => !item.isEmpty).toList();
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

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(16),
        build: (context) {
          final preparedDate = DateFormat('dd/MM/yyyy').format(DateTime.now());
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
            fontSize: 7.5,
            color: PdfColors.black,
          );
          final tableHeaderStyle = pw.TextStyle(
            fontSize: 7.4,
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
            int maxLines = 1,
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
                maxLines: maxLines,
                textAlign: alignment == pw.Alignment.center
                    ? pw.TextAlign.center
                    : alignment == pw.Alignment.centerRight
                    ? pw.TextAlign.right
                    : pw.TextAlign.left,
              ),
            );
          }

          return [
            pw.Center(
              child: shreeHeaderImage == null
                  ? pw.Text('New Items Bill', style: headingStyle)
                  : pw.Column(
                      children: [
                        pw.Image(shreeHeaderImage, width: 116),
                        pw.SizedBox(height: 4),
                        pw.Text('New Items Bill', style: headingStyle),
                      ],
                    ),
            ),
            pw.SizedBox(height: 4),
            pw.Center(
              child: pw.Text(
                'Pricing preview for manually added items',
                style: pw.TextStyle(fontSize: 8.5, color: PdfColors.grey700),
              ),
            ),
            pw.SizedBox(height: 10),
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(flex: 2, child: infoCell('Name', customerName)),
                pw.SizedBox(width: 8),
                pw.Expanded(child: infoCell('Whatsapp Number', customerMobile)),
                pw.SizedBox(width: 8),
                pw.Expanded(
                  child: infoCell('Alternate Mobile', alternateMobile),
                ),
                pw.SizedBox(width: 8),
                pw.Expanded(child: infoCell('Delivery Date', deliveryDate)),
              ],
            ),
            pw.SizedBox(height: 6),
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(child: infoCell('Prepared On', preparedDate)),
                pw.SizedBox(width: 8),
                pw.Expanded(
                  child: infoCell('Items', newItems.length.toString()),
                ),
                pw.SizedBox(width: 8),
                pw.Expanded(
                  child: infoCell('22K Rate', _formatCurrency(gold22Rate)),
                ),
                pw.SizedBox(width: 8),
                pw.Expanded(
                  child: infoCell('18K Rate', _formatCurrency(gold18Rate)),
                ),
                pw.SizedBox(width: 8),
                pw.Expanded(
                  child: infoCell('Silver Rate', _formatCurrency(silverRate)),
                ),
              ],
            ),
            pw.SizedBox(height: 6),
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: infoCell('Base + Extras', _formatCurrency(subtotal)),
                ),
                pw.SizedBox(width: 8),
                pw.Expanded(
                  child: infoCell('GST Total', _formatCurrency(totalGst)),
                ),
                pw.SizedBox(width: 8),
                pw.Expanded(
                  child: infoCell('Grand Total', _formatCurrency(grandTotal)),
                ),
                pw.SizedBox(width: 8),
                pw.Expanded(
                  child: infoCell('GST Rate', '${gstRate.toStringAsFixed(2)}%'),
                ),
              ],
            ),
            pw.SizedBox(height: 8),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey400),
              columnWidths: const {
                0: pw.FixedColumnWidth(24),
                1: pw.FlexColumnWidth(1.8),
                2: pw.FixedColumnWidth(40),
                3: pw.FixedColumnWidth(48),
                4: pw.FlexColumnWidth(1.6),
                5: pw.FixedColumnWidth(54),
                6: pw.FixedColumnWidth(48),
                7: pw.FixedColumnWidth(44),
                8: pw.FixedColumnWidth(40),
                9: pw.FixedColumnWidth(44),
                10: pw.FixedColumnWidth(44),
                11: pw.FixedColumnWidth(34),
                12: pw.FixedColumnWidth(52),
              },
              defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    tableCell(
                      'No.',
                      style: tableHeaderStyle,
                      backgroundColor: PdfColors.grey200,
                      alignment: pw.Alignment.center,
                    ),
                    tableCell(
                      'Item Name',
                      style: tableHeaderStyle,
                      backgroundColor: PdfColors.grey200,
                      maxLines: 2,
                    ),
                    tableCell(
                      'Category',
                      style: tableHeaderStyle,
                      backgroundColor: PdfColors.grey200,
                      maxLines: 2,
                    ),
                    tableCell(
                      'Bhav',
                      style: tableHeaderStyle,
                      backgroundColor: PdfColors.grey200,
                      alignment: pw.Alignment.centerRight,
                    ),
                    tableCell(
                      'Notes',
                      style: tableHeaderStyle,
                      backgroundColor: PdfColors.grey200,
                      maxLines: 2,
                    ),
                    tableCell(
                      'Making Type',
                      style: tableHeaderStyle,
                      backgroundColor: PdfColors.grey200,
                      maxLines: 2,
                    ),
                    tableCell(
                      'Making',
                      style: tableHeaderStyle,
                      backgroundColor: PdfColors.grey200,
                      alignment: pw.Alignment.centerRight,
                    ),
                    tableCell(
                      'Gross Wt',
                      style: tableHeaderStyle,
                      backgroundColor: PdfColors.grey200,
                      alignment: pw.Alignment.centerRight,
                    ),
                    tableCell(
                      'Less Wt',
                      style: tableHeaderStyle,
                      backgroundColor: PdfColors.grey200,
                      alignment: pw.Alignment.centerRight,
                    ),
                    tableCell(
                      'Nett Wt',
                      style: tableHeaderStyle,
                      backgroundColor: PdfColors.grey200,
                      alignment: pw.Alignment.centerRight,
                    ),
                    tableCell(
                      'Addl.',
                      style: tableHeaderStyle,
                      backgroundColor: PdfColors.grey200,
                      alignment: pw.Alignment.centerRight,
                    ),
                    tableCell(
                      'GST',
                      style: tableHeaderStyle,
                      backgroundColor: PdfColors.grey200,
                      alignment: pw.Alignment.center,
                    ),
                    tableCell(
                      'Total',
                      style: tableHeaderStyle,
                      backgroundColor: PdfColors.grey200,
                      alignment: pw.Alignment.centerRight,
                    ),
                  ],
                ),
                ...newItems.asMap().entries.map(
                  (entry) => pw.TableRow(
                    children: [
                      tableCell(
                        '${entry.key + 1}',
                        style: tableStyle,
                        alignment: pw.Alignment.center,
                      ),
                      tableCell(
                        entry.value.nameController.text.trim(),
                        style: tableStyle,
                      ),
                      tableCell(
                        _categoryLabel(entry.value.category),
                        style: tableStyle,
                      ),
                      tableCell(
                        _formatCurrency(_bhavFor(entry.value)),
                        style: tableStyle,
                        alignment: pw.Alignment.centerRight,
                      ),
                      tableCell(_notesFor(entry.value), style: tableStyle),
                      tableCell(entry.value.makingType, style: tableStyle),
                      tableCell(
                        _formatCurrency(entry.value.makingCharge),
                        style: tableStyle,
                        alignment: pw.Alignment.centerRight,
                      ),
                      tableCell(
                        _formatWeightFixed3(entry.value.grossWeight),
                        style: tableStyle,
                        alignment: pw.Alignment.centerRight,
                      ),
                      tableCell(
                        _formatWeightFixed3(entry.value.lessWeight),
                        style: tableStyle,
                        alignment: pw.Alignment.centerRight,
                      ),
                      tableCell(
                        _formatWeightFixed3(entry.value.netWeight),
                        style: tableStyle,
                        alignment: pw.Alignment.centerRight,
                      ),
                      tableCell(
                        _formatCurrency(entry.value.additionalCharge),
                        style: tableStyle,
                        alignment: pw.Alignment.centerRight,
                      ),
                      tableCell(
                        entry.value.gstEnabled ? 'Yes' : 'No',
                        style: tableStyle,
                        alignment: pw.Alignment.center,
                      ),
                      tableCell(
                        _formatCurrency(_lineTotal(entry.value)),
                        style: tableStyle,
                        alignment: pw.Alignment.centerRight,
                      ),
                    ],
                  ),
                ),
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                  children: [
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
                      '',
                      style: tableHeaderStyle,
                      backgroundColor: PdfColors.grey100,
                    ),
                    tableCell(
                      newItems.length.toString(),
                      style: tableHeaderStyle,
                      backgroundColor: PdfColors.grey100,
                      alignment: pw.Alignment.center,
                    ),
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
                      _formatCurrency(grandTotal),
                      style: tableHeaderStyle,
                      backgroundColor: PdfColors.grey100,
                      alignment: pw.Alignment.centerRight,
                    ),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 8),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Text(
                  'Working preview generated from the current draft',
                  style: pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
                ),
              ],
            ),
          ];
        },
      ),
    );

    return document.save();
  }
}
