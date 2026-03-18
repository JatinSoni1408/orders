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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
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
    final document = pw.Document();
    final shreeHeaderImage = pw.MemoryImage(await _buildShreeHeaderImage());
    final labelStyle = pw.TextStyle(fontSize: 9, color: PdfColors.grey700);
    final valueStyle = pw.TextStyle(
      fontSize: 11,
      fontWeight: pw.FontWeight.bold,
    );
    final headingStyle = pw.TextStyle(
      fontSize: 18,
      fontWeight: pw.FontWeight.bold,
      letterSpacing: 0.6,
    );

    pw.Widget infoCell(String label, String value) {
      return pw.Container(
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey300),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(label, style: labelStyle),
            pw.SizedBox(height: 4),
            pw.Text(value, style: valueStyle),
          ],
        ),
      );
    }

    document.addPage(
      pw.MultiPage(
        pageFormat: format,
        margin: const pw.EdgeInsets.all(24),
        build: (context) => [
          pw.Center(child: pw.Image(shreeHeaderImage, width: 180)),
          pw.SizedBox(height: 14),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Container(
                width: 14,
                height: 14,
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
          pw.SizedBox(height: 12),
          pw.Center(child: pw.Text('Estimate', style: headingStyle)),
          pw.SizedBox(height: 16),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(child: infoCell('Name', customerName)),
              pw.SizedBox(width: 10),
              pw.Expanded(child: infoCell('Whatsapp Number', customerMobile)),
            ],
          ),
          pw.SizedBox(height: 10),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(child: infoCell('Alternate Mobile', alternateMobile)),
              pw.SizedBox(width: 10),
              pw.Expanded(child: infoCell('Status', statusLabel)),
            ],
          ),
          pw.SizedBox(height: 10),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(child: infoCell('Occasion', occasion)),
              pw.SizedBox(width: 10),
              pw.Expanded(child: infoCell('Occasion Date', occasionDate)),
            ],
          ),
          pw.SizedBox(height: 14),
          pw.Row(
            children: [
              pw.Expanded(child: infoCell('Purity', purity)),
              pw.SizedBox(width: 10),
              pw.Expanded(child: infoCell('Making', making)),
              pw.SizedBox(width: 10),
              pw.Expanded(child: infoCell('GST', gst)),
            ],
          ),
          pw.SizedBox(height: 18),
          pw.TableHelper.fromTextArray(
            border: pw.TableBorder.all(color: PdfColors.grey400),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            cellAlignment: pw.Alignment.centerLeft,
            cellPadding: const pw.EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 6,
            ),
            headers: const [
              'S No',
              'Purity',
              'Item Name',
              'Qty',
              'Weight (gm)',
              'Notes / Instructions',
            ],
            data: [
              ...items.asMap().entries.map(
                (entry) => [
                  '${entry.key + 1}',
                  entry.value.purityController.text.trim(),
                  entry.value.nameController.text.trim(),
                  entry.value.quantityController.text.trim(),
                  _formatWeight3(entry.value.totalNettWeight),
                  entry.value.notesController.text.trim(),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 18),
          pw.Row(
            children: [
              pw.Expanded(
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey100,
                    borderRadius: const pw.BorderRadius.all(
                      pw.Radius.circular(6),
                    ),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Estimated Weight', style: valueStyle),
                      pw.Text(totalWeight, style: valueStyle),
                    ],
                  ),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 12),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Text(
              'Delivery Date: $deliveryDate',
              style: valueStyle.copyWith(fontSize: 10),
            ),
          ),
        ],
      ),
    );

    return document.save();
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
