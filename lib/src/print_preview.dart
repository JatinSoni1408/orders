part of '../main.dart';

class _PdfPreviewScaffold extends StatefulWidget {
  const _PdfPreviewScaffold({
    required this.title,
    required this.pdfFileName,
    required this.buildPdf,
    this.helperText,
  });

  final String title;
  final String pdfFileName;
  final LayoutCallback buildPdf;
  final String? helperText;

  @override
  State<_PdfPreviewScaffold> createState() => _PdfPreviewScaffoldState();
}

class _PdfPreviewScaffoldState extends State<_PdfPreviewScaffold> {
  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_handleKeyEvent);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
    super.dispose();
  }

  bool _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) {
      return false;
    }
    if (event.logicalKey != LogicalKeyboardKey.escape) {
      return false;
    }
    final currentRoute = ModalRoute.of(context);
    if (currentRoute?.isCurrent != true) {
      return false;
    }
    unawaited(Navigator.of(context).maybePop());
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back),
        ),
        title: Text(widget.title),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.helperText != null) ...[
              Text(
                widget.helperText!,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade700),
              ),
              const SizedBox(height: 16),
            ],
            Expanded(
              child: Card(
                clipBehavior: Clip.antiAlias,
                child: PdfPreview(
                  canChangePageFormat: false,
                  canChangeOrientation: false,
                  canDebug: false,
                  allowSharing: false,
                  pdfFileName: widget.pdfFileName,
                  build: widget.buildPdf,
                ),
              ),
            ),
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
    required this.newItemsAdditionalCharges,
    required this.newItemsSubtotal,
    required this.newItemsTotalGst,
    required this.newItemsOverallDiscount,
    required this.newItemsGrandTotal,
    required this.takeawayPayments,
    required this.takeawayPaymentsTotal,
    required this.takeawayBalanceAfterPayments,
    required this.takeawayDiscount,
    required this.takeawayGstAddedAmount,
    required this.takeawayRefundAmount,
    required this.takeawayFinalDueAmount,
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
  final double newItemsAdditionalCharges;
  final double newItemsSubtotal;
  final double newItemsTotalGst;
  final double newItemsOverallDiscount;
  final double newItemsGrandTotal;
  final List<_TakeawayPaymentDraft> takeawayPayments;
  final double takeawayPaymentsTotal;
  final double takeawayBalanceAfterPayments;
  final double takeawayDiscount;
  final double takeawayGstAddedAmount;
  final double takeawayRefundAmount;
  final double takeawayFinalDueAmount;
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

  String _advanceModeLabelWithCheque(_AdvanceValuationDraft item) {
    final chequeNumber = item.chequeNumber?.trim() ?? '';
    if (chequeNumber.isEmpty) {
      return item.mode.label;
    }
    return '${item.mode.label} - $chequeNumber';
  }

  String _advanceRateLabel(double value) {
    return value <= 0 ? '-Unfix-' : _formatCurrency(value);
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

  String _newItemNameWithNotes(_NewItemDraft item) {
    final itemName = item.nameController.text.trim();
    final notes = item.notesController.text.trim();
    if (notes.isEmpty) {
      return itemName;
    }
    return '$itemName ($notes)';
  }

  String _newItemMakingDisplay(_NewItemDraft item) {
    final making = _formatCurrency(item.makingCharge);
    switch (item.makingType) {
      case 'PerGram':
        return '$making / gm';
      case 'TotalMaking':
        return '$making T';
      case 'FixRate':
        return '$making FixRate';
      case 'Percentage':
        return '$making%';
      default:
        return making;
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
        text: 'श्री',
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
    return _PdfPreviewScaffold(
      title: 'Order Summary',
      pdfFileName: 'order-summary-preview.pdf',
      buildPdf: _buildCombinedBillPdf,
    );
  }

  Future<Uint8List> _buildCombinedBillPdf(PdfPageFormat format) async {
    final document = pw.Document();
    final emojiFont = await PdfGoogleFonts.notoColorEmoji();
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

    String truncatedWeightText(double value) {
      return NumberFormat('0.000', 'en_IN').format(_truncateWeight3(value));
    }

    String formattedRateWithMaking(double value) {
      return value <= 0
          ? '-Unfix-'
          : NumberFormat('0.000', 'en_IN').format(value);
    }

    String formattedAdvanceOthers(double value) {
      return NumberFormat('0.000', 'en_IN').format(_truncateWeight3(value));
    }

    final estimateList = estimateItems.where((item) => !item.isEmpty).toList();
    final advanceList = advanceItems.where((item) => !item.isEmpty).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    final oldItemList = oldItems.where((item) => !item.isEmpty).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    final newItemList = newItems.where((item) => !item.isEmpty).toList();
    final totalRowCount =
        (estimateList.length * 2) +
        advanceList.length +
        oldItemList.length +
        newItemList.length;
    final combinedAdvanceRows =
        <
            ({
              DateTime date,
              String mode,
              String amount,
              String rate,
              String making,
              String rateWithMaking,
              String others,
              String netWeight,
            })
          >[
            ...advanceList.map(
              (item) => (
                date: item.date,
                mode: _advanceModeLabelWithCheque(item),
                amount: _formatCurrency(item.amount),
                rate: _advanceRateLabel(item.rate),
                making: '${item.rateMaking.toStringAsFixed(2)}%',
                rateWithMaking: formattedRateWithMaking(item.effectiveRate),
                others: formattedAdvanceOthers(item.otherCharges),
                netWeight: truncatedWeightText(item.weight),
              ),
            ),
            ...oldItemList.map(
              (item) => (
                date: item.date,
                mode: 'OLD - ${item.itemNameController.text.trim()}',
                amount: _formatCurrency(item.amount),
                rate: _advanceRateLabel(item.advanceRate),
                making: item.advanceMaking > 0
                    ? '${item.advanceMaking.toStringAsFixed(2)}%'
                    : '-',
                rateWithMaking: formattedRateWithMaking(
                  item.advanceEffectiveRate,
                ),
                others: '-',
                netWeight: truncatedWeightText(item.advanceWeight),
              ),
            ),
          ]
          ..sort((a, b) => a.date.compareTo(b.date));
    final combinedAdvanceTotalAmount =
        advanceTotalAmount + advanceOldItemsTotalAmount;
    final combinedAdvanceTotalNetWeight = _truncateWeight3(
      advanceList.fold<double>(
            0,
            (sum, item) => sum + _truncateWeight3(item.weight),
          ) +
          oldItemList.fold<double>(
            0,
            (sum, item) => sum + _truncateWeight3(item.advanceWeight),
          ),
    );
    final takeawayList =
        takeawayPayments.where((item) => !item.isEmpty).toList()
          ..sort((a, b) => a.date.compareTo(b.date));
    final compactFontSize = totalRowCount > 28
        ? 6.4
        : totalRowCount > 18
        ? 6.9
        : totalRowCount > 10
        ? 7.4
        : 7.8;
    final headerFontSize = compactFontSize + 0.5;

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(14, 26, 14, 14),
        build: (context) {
          final headingStyle = pw.TextStyle(
            fontSize: 15,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.black,
          );
          final subheadingStyle = pw.TextStyle(
            fontSize: 8.4,
            color: PdfColors.grey700,
          );
          final labelStyle = pw.TextStyle(
            fontSize: 7.8,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.black,
          );
          final valueStyle = pw.TextStyle(
            fontSize: 8.8,
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

          pw.Widget summaryMetaCell(String iconGlyph, String value) {
            return pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 6,
              ),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Text(
                    iconGlyph,
                    style: pw.TextStyle(
                      fontFallback: [emojiFont],
                      fontSize: 12,
                    ),
                  ),
                  pw.SizedBox(width: 6),
                  pw.Expanded(
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
            int maxLines = 1,
            bool scaleDown = false,
          }) {
            final resolvedStyle = scaleDown
                ? style.copyWith(
                    fontSize: ((style.fontSize ?? 8) - 1.2).clamp(6.0, 20.0),
                  )
                : style;
            final textWidget = pw.Text(
              text.isEmpty ? ' ' : text,
              style: resolvedStyle,
              maxLines: maxLines,
              textAlign: alignment == pw.Alignment.center
                  ? pw.TextAlign.center
                  : alignment == pw.Alignment.centerRight
                  ? pw.TextAlign.right
                  : pw.TextAlign.left,
            );
            return pw.Container(
              alignment: alignment,
              color: backgroundColor,
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 3,
                vertical: 3,
              ),
              child: textWidget,
            );
          }

          pw.Widget sectionCard({
            String? title,
            String? subtitle,
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
                  if (title != null && title.trim().isNotEmpty) ...[
                    pw.Text(title, style: valueStyle),
                    if (subtitle != null && subtitle.trim().isNotEmpty) ...[
                      pw.SizedBox(height: 2),
                      pw.Text(subtitle, style: subheadingStyle),
                      pw.SizedBox(height: 6),
                    ] else
                      pw.SizedBox(height: 6),
                  ] else
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

          pw.Widget actualTable() {
            if (estimateList.isEmpty) return emptyState('No actual items');
            return pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey400),
              columnWidths: const {
                0: pw.FixedColumnWidth(22),
                1: pw.FixedColumnWidth(30),
                2: pw.FlexColumnWidth(2.1),
                3: pw.FixedColumnWidth(24),
                4: pw.FixedColumnWidth(34),
                5: pw.FixedColumnWidth(34),
                6: pw.FixedColumnWidth(34),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    tableCell(
                      'S No',
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
                      'Item Name',
                      style: tableHeaderStyle,
                      backgroundColor: PdfColors.grey200,
                      alignment: pw.Alignment.center,
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
                        (() {
                          final itemName = entry.value.nameController.text
                              .trim();
                          final notes = entry.value.notesController.text.trim();
                          if (notes.isEmpty) {
                            return itemName;
                          }
                          return '$itemName ($notes)';
                        })(),
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
                if (oldItemList.isNotEmpty)
                  pw.Text('Old Items Details', style: tableHeaderStyle),
                if (oldItemList.isNotEmpty) pw.SizedBox(height: 4),
                if (oldItemList.isNotEmpty)
                  pw.Table(
                    border: pw.TableBorder.all(color: PdfColors.grey400),
                    columnWidths: const {
                      0: pw.FixedColumnWidth(44),
                      1: pw.FlexColumnWidth(1.7),
                      2: pw.FixedColumnWidth(38),
                      3: pw.FixedColumnWidth(38),
                      4: pw.FixedColumnWidth(44),
                      5: pw.FixedColumnWidth(46),
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
                            scaleDown: true,
                          ),
                          tableCell(
                            'Item',
                            style: tableHeaderStyle,
                            backgroundColor: PdfColors.grey200,
                            scaleDown: true,
                          ),
                          tableCell(
                            'Nett',
                            style: tableHeaderStyle,
                            backgroundColor: PdfColors.grey200,
                            alignment: pw.Alignment.centerRight,
                            scaleDown: true,
                          ),
                          tableCell(
                            'Tanch',
                            style: tableHeaderStyle,
                            backgroundColor: PdfColors.grey200,
                            alignment: pw.Alignment.centerRight,
                            scaleDown: true,
                          ),
                          tableCell(
                            'Return Bhav',
                            style: tableHeaderStyle,
                            backgroundColor: PdfColors.grey200,
                            alignment: pw.Alignment.center,
                            scaleDown: true,
                          ),
                          tableCell(
                            'Amount',
                            style: tableHeaderStyle,
                            backgroundColor: PdfColors.grey200,
                            alignment: pw.Alignment.centerRight,
                            scaleDown: true,
                          ),
                        ],
                      ),
                      ...oldItemList.map(
                        (item) => pw.TableRow(
                          children: [
                            tableCell(
                              _formatEntryDate(item.date),
                              style: tableStyle,
                              scaleDown: true,
                            ),
                            tableCell(
                              item.itemNameController.text.trim(),
                              style: tableStyle,
                              scaleDown: true,
                            ),
                            tableCell(
                              _formatWeightFixed3(item.nettWeight),
                              style: tableStyle,
                              alignment: pw.Alignment.centerRight,
                              scaleDown: true,
                            ),
                            tableCell(
                              _formatTanchPercent(item.tanch),
                              style: tableStyle,
                              alignment: pw.Alignment.centerRight,
                              scaleDown: true,
                            ),
                            tableCell(
                              _formatCurrency(item.returnRate),
                              style: tableStyle,
                              alignment: pw.Alignment.centerRight,
                              scaleDown: true,
                              maxLines: 1,
                            ),
                            tableCell(
                              _formatCurrency(item.amount),
                              style: tableStyle,
                              alignment: pw.Alignment.centerRight,
                              scaleDown: true,
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
                            scaleDown: true,
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
                            scaleDown: true,
                          ),
                        ],
                      ),
                    ],
                  ),
                if (oldItemList.isNotEmpty && combinedAdvanceRows.isNotEmpty)
                  pw.SizedBox(height: 8),
                if (combinedAdvanceRows.isNotEmpty)
                  pw.Text('Advance', style: valueStyle),
                if (combinedAdvanceRows.isNotEmpty) pw.SizedBox(height: 6),
                if (combinedAdvanceRows.isNotEmpty)
                  pw.Table(
                    border: pw.TableBorder.all(color: PdfColors.grey400),
                    columnWidths: const {
                      0: pw.FixedColumnWidth(34),
                      1: pw.FixedColumnWidth(68),
                      2: pw.FixedColumnWidth(58),
                      3: pw.FixedColumnWidth(48),
                      4: pw.FixedColumnWidth(34),
                      5: pw.FixedColumnWidth(48),
                      6: pw.FixedColumnWidth(42),
                      7: pw.FixedColumnWidth(38),
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
                            'Amount',
                            style: tableHeaderStyle,
                            backgroundColor: PdfColors.grey200,
                            alignment: pw.Alignment.centerRight,
                          ),
                          tableCell(
                            'Rate 22/22 K',
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
                            'Rate + Making',
                            style: tableHeaderStyle,
                            backgroundColor: PdfColors.grey200,
                            alignment: pw.Alignment.centerRight,
                            scaleDown: true,
                          ),
                          tableCell(
                            'Others',
                            style: tableHeaderStyle,
                            backgroundColor: PdfColors.grey200,
                            alignment: pw.Alignment.centerRight,
                            scaleDown: true,
                          ),
                          tableCell(
                            'Net Wt',
                            style: tableHeaderStyle,
                            backgroundColor: PdfColors.grey200,
                            alignment: pw.Alignment.centerRight,
                          ),
                        ],
                      ),
                      ...combinedAdvanceRows.map(
                        (entry) => pw.TableRow(
                          children: [
                            tableCell(
                              _formatEntryDate(entry.date),
                              style: tableStyle,
                            ),
                            tableCell(entry.mode, style: tableStyle),
                            tableCell(
                              entry.amount,
                              style: tableStyle,
                              alignment: pw.Alignment.centerRight,
                            ),
                            tableCell(
                              entry.rate,
                              style: tableStyle,
                              alignment: pw.Alignment.centerRight,
                            ),
                            tableCell(
                              entry.making,
                              style: tableStyle,
                              alignment: pw.Alignment.centerRight,
                            ),
                            tableCell(
                              entry.rateWithMaking,
                              style: tableStyle,
                              alignment: pw.Alignment.centerRight,
                              scaleDown: true,
                            ),
                            tableCell(
                              entry.others,
                              style: tableStyle,
                              alignment: pw.Alignment.centerRight,
                              scaleDown: true,
                            ),
                            tableCell(
                              entry.netWeight,
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
                            _formatCurrency(combinedAdvanceTotalAmount),
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
                          tableCell(
                            '',
                            style: tableHeaderStyle,
                            backgroundColor: PdfColors.grey100,
                          ),
                          tableCell(
                            truncatedWeightText(combinedAdvanceTotalNetWeight),
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
                0: pw.FixedColumnWidth(22),
                1: pw.FlexColumnWidth(2.2),
                2: pw.FixedColumnWidth(36),
                3: pw.FixedColumnWidth(34),
                4: pw.FixedColumnWidth(34),
                5: pw.FixedColumnWidth(34),
                6: pw.FixedColumnWidth(42),
                7: pw.FixedColumnWidth(54),
                8: pw.FixedColumnWidth(46),
                9: pw.FixedColumnWidth(42),
                10: pw.FixedColumnWidth(48),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    tableCell(
                      'S No',
                      style: tableHeaderStyle,
                      backgroundColor: PdfColors.grey200,
                      alignment: pw.Alignment.center,
                      maxLines: 2,
                    ),
                    tableCell(
                      'Item Name',
                      style: tableHeaderStyle,
                      backgroundColor: PdfColors.grey200,
                      alignment: pw.Alignment.center,
                    ),
                    tableCell(
                      'Purity',
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
                      'Rate',
                      style: tableHeaderStyle,
                      backgroundColor: PdfColors.grey200,
                      alignment: pw.Alignment.centerRight,
                    ),
                    tableCell(
                      'Making',
                      style: tableHeaderStyle,
                      backgroundColor: PdfColors.grey200,
                      alignment: pw.Alignment.center,
                    ),
                    tableCell(
                      'Additionals',
                      style: tableHeaderStyle,
                      backgroundColor: PdfColors.grey200,
                      alignment: pw.Alignment.centerRight,
                    ),
                    tableCell(
                      'Others',
                      style: tableHeaderStyle,
                      backgroundColor: PdfColors.grey200,
                      alignment: pw.Alignment.centerRight,
                    ),
                    tableCell(
                      'Total',
                      style: tableHeaderStyle,
                      backgroundColor: PdfColors.grey200,
                      alignment: pw.Alignment.centerRight,
                    ),
                  ],
                ),
                ...newItemList.asMap().entries.map((entry) {
                  final itemNameStyle = entry.value.isDifferenceEntry
                      ? tableStyle.copyWith(fontWeight: pw.FontWeight.bold)
                      : tableStyle;
                  return pw.TableRow(
                    children: [
                      tableCell(
                        '${entry.key + 1}',
                        style: tableStyle,
                        alignment: pw.Alignment.center,
                      ),
                      tableCell(
                        _newItemNameWithNotes(entry.value),
                        style: itemNameStyle,
                      ),
                      tableCell(
                        _newItemCategoryLabel(entry.value.category),
                        style: tableStyle,
                        alignment: pw.Alignment.center,
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
                        _formatCurrency(_newItemBhav(entry.value)),
                        style: tableStyle,
                        alignment: pw.Alignment.centerRight,
                      ),
                      tableCell(
                        _newItemMakingDisplay(entry.value),
                        style: tableStyle,
                      ),
                      tableCell(
                        entry.value.additionalCharge > 0
                            ? _formatCurrency(entry.value.additionalCharge)
                            : '-',
                        style: tableStyle,
                        alignment: pw.Alignment.centerRight,
                      ),
                      tableCell(
                        _newItemGstAmount(entry.value) > 0
                            ? _formatCurrency(_newItemGstAmount(entry.value))
                            : '-',
                        style: tableStyle,
                        alignment: pw.Alignment.centerRight,
                      ),
                      tableCell(
                        _formatCurrency(_newItemTotal(entry.value)),
                        style: tableStyle,
                        alignment: pw.Alignment.centerRight,
                      ),
                    ],
                  );
                }),
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
                      _formatWeightFixed3(
                        newItemList.fold<double>(
                          0,
                          (total, item) => total + item.grossWeight,
                        ),
                      ),
                      style: tableHeaderStyle,
                      alignment: pw.Alignment.centerRight,
                      backgroundColor: PdfColors.grey100,
                    ),
                    tableCell(
                      _formatWeightFixed3(
                        newItemList.fold<double>(
                          0,
                          (total, item) => total + item.lessWeight,
                        ),
                      ),
                      style: tableHeaderStyle,
                      alignment: pw.Alignment.centerRight,
                      backgroundColor: PdfColors.grey100,
                    ),
                    tableCell(
                      _formatWeightFixed3(
                        newItemList.fold<double>(
                          0,
                          (total, item) => total + item.netWeight,
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
                      _formatCurrency(
                        newItemList.fold<double>(
                          0,
                          (total, item) => total + item.additionalCharge,
                        ),
                      ),
                      style: tableHeaderStyle,
                      alignment: pw.Alignment.centerRight,
                      backgroundColor: PdfColors.grey100,
                    ),
                    tableCell(
                      _formatCurrency(
                        newItemList.fold<double>(
                          0,
                          (total, item) => total + _newItemGstAmount(item),
                        ),
                      ),
                      style: tableHeaderStyle,
                      alignment: pw.Alignment.centerRight,
                      backgroundColor: PdfColors.grey100,
                    ),
                    tableCell(
                      _formatCurrency(
                        newItemList.fold<double>(
                          0,
                          (total, item) => total + _newItemTotal(item),
                        ),
                      ),
                      style: tableHeaderStyle,
                      alignment: pw.Alignment.centerRight,
                      backgroundColor: PdfColors.grey100,
                    ),
                  ],
                ),
              ],
            );
          }

          pw.Widget takeawaySummaryTable() {
            final takeawayStatusLabel = takeawayRefundAmount > 0
                ? 'Refund Amount'
                : takeawayFinalDueAmount == 0
                ? 'Transaction Settled'
                : 'Final Due Amount';
            final takeawaySubtotal =
                (advanceTotalAmount + advanceOldItemsTotalAmount) +
                newItemsGrandTotal;
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  children: [
                    pw.Expanded(
                      child: pw.Text('Additional Charges', style: labelStyle),
                    ),
                    pw.Text(
                      _formatCurrency(newItemsAdditionalCharges),
                      style: valueStyle,
                    ),
                  ],
                ),
                pw.SizedBox(height: 6),
                pw.Row(
                  children: [
                    pw.Expanded(child: pw.Text('Subtotal', style: labelStyle)),
                    pw.Text(
                      _formatCurrency(takeawaySubtotal),
                      style: valueStyle,
                    ),
                  ],
                ),
                pw.SizedBox(height: 6),
                pw.Row(
                  children: [
                    pw.Expanded(
                      child: pw.Text('Total Due Amount', style: labelStyle),
                    ),
                    pw.Text(
                      _formatCurrency(newItemsGrandTotal),
                      style: valueStyle,
                    ),
                  ],
                ),
                pw.SizedBox(height: 8),
                pw.Text('Payments', style: labelStyle),
                pw.SizedBox(height: 6),
                if (takeawayList.isNotEmpty)
                  pw.Table(
                    border: pw.TableBorder.all(color: PdfColors.grey400),
                    columnWidths: const {
                      0: pw.FixedColumnWidth(54),
                      1: pw.FlexColumnWidth(1.2),
                      2: pw.FixedColumnWidth(58),
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
                            'Amount',
                            style: tableHeaderStyle,
                            backgroundColor: PdfColors.grey200,
                            alignment: pw.Alignment.centerRight,
                          ),
                        ],
                      ),
                      ...takeawayList.map(
                        (item) => pw.TableRow(
                          children: [
                            tableCell(
                              _formatEntryDate(item.date),
                              style: tableStyle,
                            ),
                            tableCell(item.mode.label, style: tableStyle),
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
                            _formatCurrency(takeawayPaymentsTotal),
                            style: tableHeaderStyle,
                            alignment: pw.Alignment.centerRight,
                            backgroundColor: PdfColors.grey100,
                          ),
                        ],
                      ),
                    ],
                  )
                else
                  emptyState('No takeaway payments'),
                pw.SizedBox(height: 8),
                pw.Row(
                  children: [
                    pw.Expanded(
                      child: pw.Text(
                        'Total Due Amount After Payments',
                        style: labelStyle,
                      ),
                    ),
                    pw.Text(
                      _formatCurrency(
                        takeawayBalanceAfterPayments + takeawayGstAddedAmount,
                      ),
                      style: valueStyle,
                    ),
                  ],
                ),
                pw.SizedBox(height: 6),
                pw.Row(
                  children: [
                    pw.Expanded(child: pw.Text('Discount', style: labelStyle)),
                    pw.Text(
                      _formatCurrency(takeawayDiscount),
                      style: valueStyle,
                    ),
                  ],
                ),
                pw.SizedBox(height: 6),
                pw.Row(
                  children: [
                    pw.Expanded(
                      child: pw.Text(takeawayStatusLabel, style: labelStyle),
                    ),
                    pw.Text(
                      _formatCurrency(
                        takeawayRefundAmount > 0
                            ? takeawayRefundAmount
                            : takeawayFinalDueAmount,
                      ),
                      style: valueStyle,
                    ),
                  ],
                ),
              ],
            );
          }

          return [
            pw.SizedBox(height: 6),
            pw.Center(
              child: shreeHeaderImage == null
                  ? pw.Text('Order Summary', style: headingStyle)
                  : pw.Column(
                      children: [
                        pw.Image(shreeHeaderImage, width: 110),
                        pw.SizedBox(height: 4),
                        pw.Text('Order Summary', style: headingStyle),
                      ],
                    ),
            ),
            pw.SizedBox(height: 8),
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  flex: 2,
                  child: summaryMetaCell('👤', customerName),
                ),
                pw.SizedBox(width: 6),
                pw.Expanded(child: summaryMetaCell('📞', customerMobile)),
                pw.SizedBox(width: 6),
                pw.Expanded(child: summaryMetaCell('⏰', deliveryDate)),
              ],
            ),
            pw.SizedBox(height: 10),
            sectionCard(title: 'Order', child: actualTable()),
            pw.SizedBox(height: 10),
            sectionCard(child: advanceTable()),
            pw.SizedBox(height: 10),
            sectionCard(
              title: 'New Items',
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  newItemsTable(),
                  if (newItemsOverallDiscount > 0) ...[
                    pw.SizedBox(height: 6),
                    pw.Align(
                      alignment: pw.Alignment.centerRight,
                      child: pw.Text(
                        'Overall Discount ${_formatCurrency(newItemsOverallDiscount)}',
                        style: subheadingStyle,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            pw.SizedBox(height: 10),
            sectionCard(
              title: 'Totals',
              child: takeawaySummaryTable(),
            ),
            pw.SizedBox(height: 12),
            pw.Center(
              child: pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.black, width: 1.2),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Text(
                      'BILL PENDING',
                      style: pw.TextStyle(
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                        letterSpacing: 0.8,
                        color: PdfColors.black,
                      ),
                      textAlign: pw.TextAlign.center,
                    ),
                    pw.SizedBox(height: 8),
                    pw.Container(
                      width: 92,
                      height: 1.2,
                      color: PdfColors.black,
                    ),
                    pw.SizedBox(height: 5),
                    pw.Container(
                      width: 92,
                      height: 1.2,
                      color: PdfColors.black,
                    ),
                  ],
                ),
              ),
            ),
          ];
        },
      ),
    );

    return document.save();
  }
}

class _EstimatePrintPreviewSheet extends StatelessWidget {
  const _EstimatePrintPreviewSheet({
    required this.customerName,
    required this.customerMobile,
    required this.alternateMobile,
    required this.statusLabel,
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
  final String deliveryDate;
  final String purity;
  final String making;
  final String gst;
  final String totalQuantity;
  final String totalWeight;
  final List<_EstimateItemDraft> items;

  @override
  Widget build(BuildContext context) {
    return _PdfPreviewScaffold(
      title: 'Order Estimate PDF Preview',
      helperText:
          'Double-click to enlarge on desktop, or pinch to zoom in and out on touch devices.',
      pdfFileName: 'estimate-summary-preview.pdf',
      buildPdf: _buildEstimatePdf,
    );
  }

  Future<Uint8List> _buildEstimatePdf(PdfPageFormat format) async {
    try {
      final document = pw.Document();
      pw.MemoryImage? shreeHeaderImage;
      pw.MemoryImage? personIconImage;
      pw.MemoryImage? phoneIconImage;
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
      try {
        final personIconBytes = await _buildPersonIconImage().timeout(
          const Duration(seconds: 2),
        );
        if (personIconBytes.isNotEmpty) {
          personIconImage = pw.MemoryImage(personIconBytes);
        }
      } catch (_) {
        personIconImage = null;
      }
      try {
        final phoneIconBytes = await _buildPhoneIconImage().timeout(
          const Duration(seconds: 2),
        );
        if (phoneIconBytes.isNotEmpty) {
          phoneIconImage = pw.MemoryImage(phoneIconBytes);
        }
      } catch (_) {
        phoneIconImage = null;
      }

      final pageFormat = PdfPageFormat.a5;
      final itemCount = items.length;
      final compactTableFontSize = itemCount <= 4
          ? 9.4
          : itemCount <= 8
          ? 8.0
          : 7.0;
      final compactTableDataFontSize = (compactTableFontSize - 0.8).clamp(
        5.8,
        compactTableFontSize,
      );
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
      final headerValueStyle = pw.TextStyle(
        fontSize: compactValueFontSize + 1.6,
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.black,
      );
      final headingStyle = pw.TextStyle(
        fontSize: 14,
        fontWeight: pw.FontWeight.bold,
        letterSpacing: 0.4,
        color: PdfColors.black,
      );

      String truncatedEstimatedWeightText(double value) {
        return _formatWeightFixed3(_truncateWeight3(value));
      }

      String estimateLineWeightText(_EstimateItemDraft item) {
        return truncatedEstimatedWeightText(
          item.quantity * item.estimatedWeight,
        );
      }

      String estimateLineWeightBreakdownText(_EstimateItemDraft item) {
        return '[${truncatedEstimatedWeightText(item.estimatedWeight)} X ${item.quantity}]';
      }

      double dynamicColumnWidth(
        String header,
        Iterable<String> values, {
        required double minWidth,
        required double maxWidth,
      }) {
        final maxLength = values.fold<int>(header.length, (longest, value) {
          final currentLength = value.trim().length;
          return currentLength > longest ? currentLength : longest;
        });
        final estimatedWidth = 12 + (maxLength * (compactTableFontSize * 0.72));
        return estimatedWidth.clamp(minWidth, maxWidth).toDouble();
      }

      final serialColumnWidth = dynamicColumnWidth(
        'S No',
        List.generate(items.length, (index) => '${index + 1}'),
        minWidth: 30,
        maxWidth: 42,
      );
      final purityColumnWidth = dynamicColumnWidth(
        'Purity',
        items.map((item) => item.purityController.text),
        minWidth: 40,
        maxWidth: 54,
      );
      var itemNameColumnWidth = dynamicColumnWidth(
        'Item Name',
        items.map((item) => item.nameController.text),
        minWidth: 92,
        maxWidth: 156,
      );
      final quantityColumnWidth = dynamicColumnWidth(
        'Qty',
        items.map((item) => item.quantityController.text),
        minWidth: 28,
        maxWidth: 40,
      );
      final estimatedWeightColumnWidth = dynamicColumnWidth(
        'EWt / gm',
        items.expand(
          (item) => [
            estimateLineWeightText(item),
            if (item.quantity > 1) estimateLineWeightBreakdownText(item),
          ],
        ),
        minWidth: 36,
        maxWidth: 74,
      );
      var notesColumnWidth = dynamicColumnWidth(
        'Notes',
        items.map((item) => item.notesController.text),
        minWidth: 52,
        maxWidth: 92,
      );
      final availableTableWidth = pageFormat.width - 32;
      final totalTableWidth =
          serialColumnWidth +
          purityColumnWidth +
          itemNameColumnWidth +
          quantityColumnWidth +
          estimatedWeightColumnWidth +
          notesColumnWidth;
      if (totalTableWidth > availableTableWidth) {
        var overflow = totalTableWidth - availableTableWidth;

        final reducibleNotes = notesColumnWidth - 52;
        final noteReduction = overflow > reducibleNotes
            ? reducibleNotes
            : overflow;
        notesColumnWidth -= noteReduction;
        overflow -= noteReduction;

        final reducibleItemName = itemNameColumnWidth - 92;
        final itemReduction = overflow > reducibleItemName
            ? reducibleItemName
            : overflow;
        itemNameColumnWidth -= itemReduction;
      }

      pw.Widget infoCell(
        String label,
        String value, {
        bool roundedBorder = true,
        bool inlineValue = false,
        bool centerContent = false,
        pw.TextStyle? customValueStyle,
      }) {
        final resolvedValueStyle = customValueStyle ?? valueStyle;
        return pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: roundedBorder
              ? pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: const pw.BorderRadius.all(
                    pw.Radius.circular(6),
                  ),
                )
              : null,
          child: inlineValue
              ? pw.Row(
                  children: [
                    pw.Text('$label: ', style: labelStyle),
                    pw.Expanded(
                      child: pw.Text(
                        value,
                        style: resolvedValueStyle,
                        maxLines: 1,
                        textAlign: pw.TextAlign.left,
                      ),
                    ),
                  ],
                )
              : pw.Column(
                  crossAxisAlignment: centerContent
                      ? pw.CrossAxisAlignment.center
                      : pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      label,
                      style: labelStyle,
                      textAlign: centerContent
                          ? pw.TextAlign.center
                          : pw.TextAlign.left,
                    ),
                    pw.SizedBox(height: 2),
                    pw.Container(
                      height: compactValueFontSize + 2,
                      alignment: centerContent
                          ? pw.Alignment.center
                          : pw.Alignment.centerLeft,
                      child: pw.Text(
                        value,
                        style: resolvedValueStyle,
                        maxLines: 1,
                        textAlign: centerContent
                            ? pw.TextAlign.center
                            : pw.TextAlign.left,
                      ),
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
        int? maxLines = 1,
        bool fixedHeight = true,
        pw.TextAlign? textAlign,
      }) {
        final cellText = pw.Text(
          text.isEmpty ? ' ' : text,
          style: style,
          maxLines: maxLines,
          textAlign: textAlign,
        );
        return pw.Container(
          alignment: alignment,
          color: backgroundColor,
          padding: pw.EdgeInsets.symmetric(
            horizontal: 4,
            vertical: tableVerticalPadding,
          ),
          child: fixedHeight
              ? pw.Container(
                  height: compactTableFontSize + 3,
                  alignment: alignment,
                  child: cellText,
                )
              : cellText,
        );
      }

      pw.Widget estimateWeightCell(
        _EstimateItemDraft item, {
        required pw.TextStyle style,
        PdfColor? backgroundColor,
      }) {
        final breakdownStyle = pw.TextStyle(
          fontSize: compactTableFontSize - 1,
          color: PdfColors.grey700,
        );

        return pw.Container(
          alignment: pw.Alignment.centerRight,
          color: backgroundColor,
          padding: pw.EdgeInsets.symmetric(
            horizontal: 4,
            vertical: tableVerticalPadding,
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              if (item.quantity > 1)
                pw.Text(
                  estimateLineWeightBreakdownText(item),
                  style: breakdownStyle,
                  textAlign: pw.TextAlign.right,
                ),
              pw.Text(
                estimateLineWeightText(item),
                style: style,
                textAlign: pw.TextAlign.right,
              ),
            ],
          ),
        );
      }

      document.addPage(
        pw.Page(
          pageFormat: pageFormat,
          margin: const pw.EdgeInsets.fromLTRB(16, 16, 16, 16),
          build: (context) {
            final tableStyle = pw.TextStyle(
              fontSize: compactTableDataFontSize,
              color: PdfColors.black,
            );
            final tableHeaderStyle = pw.TextStyle(
              fontSize: compactTableFontSize,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.black,
            );
            final dateStyle = pw.TextStyle(
              fontSize: compactValueFontSize + 2,
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
                pw.Stack(
                  alignment: pw.Alignment.center,
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        pw.Container(
                          width: 12,
                          height: 12,
                          decoration: pw.BoxDecoration(
                            border: pw.Border.all(
                              color: PdfColors.black,
                              width: 1,
                            ),
                          ),
                        ),
                        pw.Text(
                          DateFormat('dd/MM/yyyy').format(DateTime.now()),
                          style: dateStyle,
                        ),
                      ],
                    ),
                    pw.Center(child: pw.Text('Estimate', style: headingStyle)),
                  ],
                ),
                pw.SizedBox(height: 8),
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(
                      flex: 2,
                      child: pw.Row(
                        children: [
                          pw.Expanded(
                            flex: 3,
                            child: pw.Row(
                              children: [
                                if (personIconImage != null)
                                  pw.Image(
                                    personIconImage,
                                    width: compactLabelFontSize + 7,
                                    height: compactLabelFontSize + 7,
                                  )
                                else
                                  pw.Text('Name:', style: labelStyle),
                                pw.SizedBox(width: 5),
                                pw.Expanded(
                                  child: pw.Text(
                                    customerName,
                                    style: headerValueStyle,
                                    maxLines: 1,
                                    textAlign: pw.TextAlign.left,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          pw.SizedBox(width: 6),
                          pw.Expanded(
                            flex: 2,
                            child: pw.Container(
                              alignment: pw.Alignment.centerRight,
                              child: pw.Row(
                                mainAxisSize: pw.MainAxisSize.min,
                                children: [
                                  if (phoneIconImage != null)
                                    pw.Image(
                                      phoneIconImage,
                                      width: compactLabelFontSize + 5,
                                      height: compactLabelFontSize + 5,
                                    )
                                  else
                                    pw.Text('Call:', style: labelStyle),
                                  pw.SizedBox(width: 4),
                                  pw.Text(
                                    customerMobile,
                                    style: headerValueStyle,
                                    textAlign: pw.TextAlign.right,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 6),
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(
                      child: infoCell('Purity', purity, centerContent: true),
                    ),
                    pw.SizedBox(width: 8),
                    pw.Expanded(
                      child: infoCell('Making', making, centerContent: true),
                    ),
                    pw.SizedBox(width: 8),
                    pw.Expanded(
                      child: infoCell('GST', gst, centerContent: true),
                    ),
                  ],
                ),
                pw.SizedBox(height: 8),
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey400),
                  columnWidths: {
                    0: pw.FixedColumnWidth(serialColumnWidth),
                    1: pw.FixedColumnWidth(purityColumnWidth),
                    2: pw.FixedColumnWidth(itemNameColumnWidth),
                    3: pw.FixedColumnWidth(quantityColumnWidth),
                    4: pw.FixedColumnWidth(estimatedWeightColumnWidth),
                    5: pw.FixedColumnWidth(notesColumnWidth),
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
                          'S No',
                          style: tableHeaderStyle,
                          alignment: pw.Alignment.center,
                          backgroundColor: PdfColors.grey200,
                        ),
                        tableCell(
                          'Purity',
                          style: tableHeaderStyle,
                          alignment: pw.Alignment.center,
                          backgroundColor: PdfColors.grey200,
                        ),
                        tableCell(
                          'Item Name',
                          style: tableHeaderStyle,
                          alignment: pw.Alignment.center,
                          backgroundColor: PdfColors.grey200,
                        ),
                        tableCell(
                          'Qty',
                          style: tableHeaderStyle,
                          alignment: pw.Alignment.center,
                          backgroundColor: PdfColors.grey200,
                        ),
                        tableCell(
                          'EWt / gm',
                          style: tableHeaderStyle,
                          alignment: pw.Alignment.center,
                          backgroundColor: PdfColors.grey200,
                        ),
                        tableCell(
                          'Notes',
                          style: tableHeaderStyle,
                          alignment: pw.Alignment.center,
                          backgroundColor: PdfColors.grey200,
                        ),
                      ],
                    ),
                    ...items.asMap().entries.map(
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
                            alignment: pw.Alignment.center,
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
                          estimateWeightCell(entry.value, style: tableStyle),
                          tableCell(
                            entry.value.notesController.text.trim(),
                            style: tableStyle,
                            alignment: pw.Alignment.center,
                            maxLines: null,
                            fixedHeight: false,
                            textAlign: pw.TextAlign.center,
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
                          totalQuantity,
                          style: tableHeaderStyle,
                          alignment: pw.Alignment.center,
                          backgroundColor: PdfColors.grey100,
                        ),
                        tableCell(
                          truncatedEstimatedWeightText(
                            items.fold<double>(
                              0,
                              (total, item) =>
                                  total +
                                  (item.quantity * item.estimatedWeight),
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
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 8),
                pw.Row(
                  children: [
                    pw.Expanded(
                      child: pw.Align(
                        alignment: pw.Alignment.centerLeft,
                        child: infoCell(
                          'Delivery Date',
                          deliveryDate,
                          centerContent: true,
                        ),
                      ),
                    ),
                    pw.SizedBox(width: 8),
                    pw.Expanded(
                      child: pw.Align(
                        alignment: pw.Alignment.centerRight,
                        child: infoCell(
                          'Estimated Weight',
                          totalWeight,
                          centerContent: true,
                        ),
                      ),
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
        text: '\u0936\u094d\u0930\u0940:',
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
    if (byteData == null) {
      return Uint8List(0);
    }
    return byteData.buffer.asUint8List();
  }

  Future<Uint8List> _buildPersonIconImage() async {
    const iconSize = 18.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final textPainter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(Icons.person.codePoint),
        style: TextStyle(
          color: Colors.black,
          fontSize: iconSize,
          fontFamily: Icons.person.fontFamily,
          package: Icons.person.fontPackage,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    )..layout();

    textPainter.paint(canvas, Offset.zero);
    final image = await recorder.endRecording().toImage(
      textPainter.width <= 0 ? 1 : textPainter.width.ceil(),
      textPainter.height <= 0 ? 1 : textPainter.height.ceil(),
    );
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) {
      return Uint8List(0);
    }
    return byteData.buffer.asUint8List();
  }

  Future<Uint8List> _buildPhoneIconImage() async {
    const iconSize = 18.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final textPainter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(Icons.phone.codePoint),
        style: TextStyle(
          color: Colors.black,
          fontSize: iconSize,
          fontFamily: Icons.phone.fontFamily,
          package: Icons.phone.fontPackage,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    )..layout();

    textPainter.paint(canvas, Offset.zero);
    final image = await recorder.endRecording().toImage(
      textPainter.width <= 0 ? 1 : textPainter.width.ceil(),
      textPainter.height <= 0 ? 1 : textPainter.height.ceil(),
    );
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) {
      return Uint8List(0);
    }
    return byteData.buffer.asUint8List();
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

  String _modeLabelWithCheque(AdvanceValuationLine line) {
    final chequeNumber = line.chequeNumber?.trim() ?? '';
    if (chequeNumber.isEmpty) {
      return line.mode.label;
    }
    return '${line.mode.label} - $chequeNumber';
  }

  @override
  Widget build(BuildContext context) {
    return _PdfPreviewScaffold(
      title: 'Advance PDF Preview',
      helperText:
          'Double-click to enlarge on desktop, or pinch to zoom in and out on touch devices.',
      pdfFileName: 'advance-preview.pdf',
      buildPdf: _buildAdvancePdf,
    );
  }

  Future<Uint8List> _buildAdvancePdf(PdfPageFormat format) async {
    final document = pw.Document();

    String formatAdvanceAmount(double value) {
      return NumberFormat.currency(
        locale: 'en_IN',
        symbol: '',
        decimalDigits: 2,
      ).format(value);
    }

    String formatAdvanceRate(double value) {
      return value <= 0
          ? '-Unfix-'
          : NumberFormat.currency(
              locale: 'en_IN',
              symbol: '',
              decimalDigits: 1,
            ).format(value);
    }

    String formatAdvanceWeight3(double value) {
      return NumberFormat('0.000', 'en_IN').format(_truncateWeight3(value));
    }

    String formatAdvanceRateWithMaking(double value) {
      return value <= 0
          ? '-Unfix-'
          : NumberFormat('0.000', 'en_IN').format(value);
    }

    String formatAdvanceOthers(double value) {
      return NumberFormat('0.000', 'en_IN').format(_truncateWeight3(value));
    }

    final sortedAdvanceItems = items.where((item) => !item.isEmpty).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    final lines = sortedAdvanceItems.map((item) => item.line).toList();
    final oldItemLines = oldItems.where((item) => !item.isEmpty).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    final advanceLinesTotalNetWeight = lines.fold<double>(
      0,
      (sum, line) => sum + _truncateWeight3(line.weight),
    );
    final oldItemsTotalAmount = oldItemLines.fold<double>(
      0,
      (total, item) => total + item.amount,
    );
    final oldItemsAdvanceTotalNetWeight = oldItemLines.fold<double>(
      0,
      (sum, item) => sum + _truncateWeight3(item.advanceWeight),
    );
    final combinedAdvanceTotalAmount = totalAmount + oldItemsTotalAmount;
    final combinedAdvanceTotalNetWeight = _truncateWeight3(
      advanceLinesTotalNetWeight + oldItemsAdvanceTotalNetWeight,
    );
    final combinedAdvanceRows =
        <
            ({
              DateTime date,
              String mode,
              String amount,
              String rate,
              String making,
              String rateWithMaking,
              String others,
              String netWeight,
            })
          >[
            ...lines.map(
              (line) => (
                date: line.date,
                mode: _modeLabelWithCheque(line),
                amount: formatAdvanceAmount(line.amount),
                rate: formatAdvanceRate(line.rate),
                making: '${line.rateMaking.toStringAsFixed(2)}%',
                rateWithMaking: formatAdvanceRateWithMaking(line.effectiveRate),
                others: formatAdvanceOthers(line.otherCharges),
                netWeight: formatAdvanceWeight3(line.weight),
              ),
            ),
            ...oldItemLines.map(
              (item) => (
                date: item.date,
                mode: 'OLD - ${item.itemNameController.text.trim()}',
                amount: formatAdvanceAmount(item.amount),
                rate: formatAdvanceRate(item.advanceRate),
                making: item.advanceMaking > 0
                    ? '${item.advanceMaking.toStringAsFixed(2)}%'
                    : '-',
                rateWithMaking: formatAdvanceRateWithMaking(
                  item.advanceEffectiveRate,
                ),
                others: '-',
                netWeight: formatAdvanceWeight3(item.advanceWeight),
              ),
            ),
          ]
          ..sort((a, b) => a.date.compareTo(b.date));

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
            bool scaleDown = false,
            int maxLines = 1,
          }) {
            final baseStyle = isHeader ? labelStyle : bodyStyle;
            final resolvedStyle = scaleDown
                ? baseStyle.copyWith(
                    fontSize: ((baseStyle.fontSize ?? 8) - 1.2).clamp(
                      6.0,
                      20.0,
                    ),
                  )
                : baseStyle;
            final textWidget = pw.Text(
              text.isEmpty ? ' ' : text,
              style: resolvedStyle,
              maxLines: maxLines,
              textAlign: alignment == pw.Alignment.center
                  ? pw.TextAlign.center
                  : alignment == pw.Alignment.centerRight
                  ? pw.TextAlign.right
                  : pw.TextAlign.left,
            );
            return pw.Container(
              alignment: alignment,
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 4,
                vertical: 4,
              ),
              color: isHeader ? PdfColors.grey200 : null,
              child: textWidget,
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
                  0: pw.FixedColumnWidth(50),
                  1: pw.FixedColumnWidth(64),
                  2: pw.FixedColumnWidth(60),
                  3: pw.FixedColumnWidth(50),
                  4: pw.FixedColumnWidth(34),
                  5: pw.FixedColumnWidth(48),
                  6: pw.FixedColumnWidth(40),
                  7: pw.FixedColumnWidth(40),
                },
                children: [
                  pw.TableRow(
                    children: [
                      tableCell('Date', isHeader: true),
                      tableCell('Mode', isHeader: true),
                      tableCell(
                        'Amount',
                        isHeader: true,
                        alignment: pw.Alignment.centerRight,
                      ),
                      tableCell(
                        'Rate 22/22 K',
                        isHeader: true,
                        alignment: pw.Alignment.centerRight,
                      ),
                      tableCell(
                        'Making%',
                        isHeader: true,
                        alignment: pw.Alignment.centerRight,
                        scaleDown: true,
                      ),
                      tableCell(
                        'Rate + Making',
                        isHeader: true,
                        alignment: pw.Alignment.centerRight,
                        scaleDown: true,
                      ),
                      tableCell(
                        'Others',
                        isHeader: true,
                        alignment: pw.Alignment.centerRight,
                        scaleDown: true,
                      ),
                      tableCell(
                        'Net Wt',
                        isHeader: true,
                        alignment: pw.Alignment.centerRight,
                      ),
                    ],
                  ),
                  ...combinedAdvanceRows.map(
                    (entry) => pw.TableRow(
                      children: [
                        tableCell(_formatEntryDate(entry.date)),
                        tableCell(entry.mode),
                        tableCell(
                          entry.amount,
                          alignment: pw.Alignment.centerRight,
                        ),
                        tableCell(
                          entry.rate,
                          alignment: pw.Alignment.centerRight,
                        ),
                        tableCell(
                          entry.making,
                          alignment: pw.Alignment.centerRight,
                        ),
                        tableCell(
                          entry.rateWithMaking,
                          alignment: pw.Alignment.centerRight,
                          scaleDown: true,
                        ),
                        tableCell(
                          entry.others,
                          alignment: pw.Alignment.centerRight,
                          scaleDown: true,
                        ),
                        tableCell(
                          entry.netWeight,
                          alignment: pw.Alignment.centerRight,
                        ),
                      ],
                    ),
                  ),
                  pw.TableRow(
                    children: [
                      tableCell(''),
                      tableCell('Total', isHeader: true),
                      tableCell(
                        formatAdvanceAmount(combinedAdvanceTotalAmount),
                        isHeader: true,
                        alignment: pw.Alignment.centerRight,
                      ),
                      tableCell(''),
                      tableCell(''),
                      tableCell(''),
                      tableCell(''),
                      tableCell(
                        formatAdvanceWeight3(combinedAdvanceTotalNetWeight),
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
                    0: pw.FixedColumnWidth(50),
                    1: pw.FlexColumnWidth(1.8),
                    2: pw.FixedColumnWidth(36),
                    3: pw.FixedColumnWidth(34),
                    4: pw.FixedColumnWidth(42),
                    5: pw.FixedColumnWidth(52),
                  },
                  children: [
                    pw.TableRow(
                      children: [
                        tableCell('Date', isHeader: true, scaleDown: true),
                        tableCell('Item', isHeader: true, scaleDown: true),
                        tableCell(
                          'Nett',
                          isHeader: true,
                          alignment: pw.Alignment.centerRight,
                          scaleDown: true,
                        ),
                        tableCell(
                          'Tanch',
                          isHeader: true,
                          alignment: pw.Alignment.centerRight,
                          scaleDown: true,
                        ),
                        tableCell(
                          'Return Bhav',
                          isHeader: true,
                          alignment: pw.Alignment.center,
                          scaleDown: true,
                        ),
                        tableCell(
                          'Amount',
                          isHeader: true,
                          alignment: pw.Alignment.centerRight,
                          scaleDown: true,
                        ),
                      ],
                    ),
                    ...oldItemLines.map(
                      (item) => pw.TableRow(
                        children: [
                          tableCell(
                            _formatEntryDate(item.date),
                            scaleDown: true,
                          ),
                          tableCell(
                            item.itemNameController.text.trim(),
                            scaleDown: true,
                          ),
                          tableCell(
                            formatAdvanceWeight3(item.nettWeight),
                            alignment: pw.Alignment.centerRight,
                            scaleDown: true,
                          ),
                          tableCell(
                            _formatTanchPercent(item.tanch),
                            alignment: pw.Alignment.centerRight,
                            scaleDown: true,
                          ),
                          tableCell(
                            formatAdvanceRate(item.returnRate),
                            alignment: pw.Alignment.centerRight,
                            scaleDown: true,
                            maxLines: 1,
                          ),
                          tableCell(
                            formatAdvanceAmount(item.amount),
                            alignment: pw.Alignment.centerRight,
                            scaleDown: true,
                          ),
                        ],
                      ),
                    ),
                    pw.TableRow(
                      children: [
                        tableCell(''),
                        tableCell('Total', isHeader: true, scaleDown: true),
                        tableCell(''),
                        tableCell(''),
                        tableCell(''),
                        tableCell(
                          formatAdvanceAmount(oldItemsTotalAmount),
                          isHeader: true,
                          alignment: pw.Alignment.centerRight,
                          scaleDown: true,
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
    return _PdfPreviewScaffold(
      title: 'Order PDF Preview',
      helperText:
          'Double-click to enlarge on desktop, or pinch to zoom in and out on touch devices.',
      pdfFileName: 'actual-preview.pdf',
      buildPdf: _buildActualPdf,
    );
  }

  Future<Uint8List> _buildActualPdf(PdfPageFormat format) async {
    final document = pw.Document();
    final actualItems = items.where((item) => !item.isEmpty).toList();
    pw.MemoryImage? shreeHeaderImage;
    pw.MemoryImage? personIconImage;
    pw.MemoryImage? phoneIconImage;
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
    try {
      final personIconBytes = await _buildPersonIconImage().timeout(
        const Duration(seconds: 2),
      );
      if (personIconBytes.isNotEmpty) {
        personIconImage = pw.MemoryImage(personIconBytes);
      }
    } catch (_) {
      personIconImage = null;
    }
    try {
      final phoneIconBytes = await _buildPhoneIconImage().timeout(
        const Duration(seconds: 2),
      );
      if (phoneIconBytes.isNotEmpty) {
        phoneIconImage = pw.MemoryImage(phoneIconBytes);
      }
    } catch (_) {
      phoneIconImage = null;
    }

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
    itemNameColumnWidth += 28;
    final itemCount = actualItems.length;

    document.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a5,
        margin: const pw.EdgeInsets.all(16),
        build: (context) {
          final compactLabelFontSize = itemCount <= 8 ? 7.0 : 6.2;
          final compactValueFontSize = itemCount <= 8 ? 7.6 : 6.8;
          final headingStyle = pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
            letterSpacing: 0.4,
            color: PdfColors.black,
          );
          final labelStyle = pw.TextStyle(
            fontSize: compactLabelFontSize,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.black,
          );
          final valueStyle = pw.TextStyle(
            fontSize: compactValueFontSize,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.black,
          );
          final headerValueStyle = pw.TextStyle(
            fontSize: compactValueFontSize + 1.6,
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
          final dateStyle = pw.TextStyle(
            fontSize: compactValueFontSize + 2,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.black,
          );

          pw.Widget infoCell(
            String label,
            String value, {
            bool centerContent = false,
          }) {
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
                crossAxisAlignment: centerContent
                    ? pw.CrossAxisAlignment.center
                    : pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    label,
                    style: labelStyle,
                    textAlign: centerContent
                        ? pw.TextAlign.center
                        : pw.TextAlign.left,
                  ),
                  pw.SizedBox(height: 2),
                  pw.Container(
                    height: compactValueFontSize + 2,
                    alignment: centerContent
                        ? pw.Alignment.center
                        : pw.Alignment.centerLeft,
                    child: pw.Text(
                      value,
                      style: valueStyle,
                      maxLines: 1,
                      textAlign: centerContent
                          ? pw.TextAlign.center
                          : pw.TextAlign.left,
                    ),
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
              pw.Stack(
                alignment: pw.Alignment.center,
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Container(
                        width: 12,
                        height: 12,
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(
                            color: PdfColors.black,
                            width: 1,
                          ),
                        ),
                      ),
                      pw.Text(
                        DateFormat('dd/MM/yyyy').format(DateTime.now()),
                        style: dateStyle,
                      ),
                    ],
                  ),
                  pw.Center(child: pw.Text('Actual', style: headingStyle)),
                ],
              ),
              pw.SizedBox(height: 8),
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    flex: 2,
                    child: pw.Row(
                      children: [
                        pw.Expanded(
                          flex: 3,
                          child: pw.Row(
                            children: [
                              if (personIconImage != null)
                                pw.Container(
                                  width: 11,
                                  height: 11,
                                  margin: const pw.EdgeInsets.only(right: 5),
                                  child: pw.Image(personIconImage),
                                )
                              else
                                pw.Text('Name:', style: labelStyle),
                              pw.Expanded(
                                child: pw.Text(
                                  customerName,
                                  style: headerValueStyle,
                                  maxLines: 1,
                                  textAlign: pw.TextAlign.left,
                                ),
                              ),
                            ],
                          ),
                        ),
                        pw.SizedBox(width: 6),
                        pw.Expanded(
                          flex: 2,
                          child: pw.Container(
                            alignment: pw.Alignment.centerRight,
                            child: pw.Row(
                              mainAxisSize: pw.MainAxisSize.min,
                              children: [
                                if (phoneIconImage != null)
                                  pw.Container(
                                    width: 11,
                                    height: 11,
                                    margin: const pw.EdgeInsets.only(right: 4),
                                    child: pw.Image(phoneIconImage),
                                  )
                                else
                                  pw.Text('Call:', style: labelStyle),
                                pw.Text(
                                  customerMobile,
                                  style: headerValueStyle,
                                  textAlign: pw.TextAlign.right,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 6),
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: infoCell('Purity', purity, centerContent: true),
                  ),
                  pw.SizedBox(width: 8),
                  pw.Expanded(
                    child: infoCell('Making', making, centerContent: true),
                  ),
                  pw.SizedBox(width: 8),
                  pw.Expanded(child: infoCell('GST', gst, centerContent: true)),
                ],
              ),
              pw.SizedBox(height: 8),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey400),
                columnWidths: {
                  0: const pw.FixedColumnWidth(26),
                  1: const pw.FixedColumnWidth(34),
                  2: pw.FixedColumnWidth(itemNameColumnWidth),
                  3: const pw.FixedColumnWidth(20),
                  4: const pw.FixedColumnWidth(38),
                  5: const pw.FixedColumnWidth(34),
                  6: const pw.FixedColumnWidth(38),
                },
                defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.grey200,
                    ),
                    children: [
                      tableCell(
                        'S No',
                        style: tableHeaderStyle,
                        backgroundColor: PdfColors.grey200,
                        maxLines: 1,
                      ),
                      tableCell(
                        'Purity',
                        style: tableHeaderStyle,
                        backgroundColor: PdfColors.grey200,
                        maxLines: 1,
                      ),
                      tableCell(
                        'Item Name',
                        style: tableHeaderStyle,
                        backgroundColor: PdfColors.grey200,
                        maxLines: 1,
                      ),
                      tableCell(
                        'Qty',
                        style: tableHeaderStyle,
                        alignment: pw.Alignment.center,
                        backgroundColor: PdfColors.grey200,
                        maxLines: 1,
                      ),
                      tableCell(
                        'Gross',
                        style: tableHeaderStyle,
                        alignment: pw.Alignment.centerRight,
                        backgroundColor: PdfColors.grey200,
                        maxLines: 1,
                      ),
                      tableCell(
                        'Less',
                        style: tableHeaderStyle,
                        alignment: pw.Alignment.centerRight,
                        backgroundColor: PdfColors.grey200,
                        maxLines: 1,
                      ),
                      tableCell(
                        'Nett',
                        style: tableHeaderStyle,
                        alignment: pw.Alignment.centerRight,
                        backgroundColor: PdfColors.grey200,
                        maxLines: 1,
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
                          (() {
                            final itemName = entry.value.nameController.text
                                .trim();
                            final notes = entry.value.notesController.text
                                .trim();
                            if (notes.isEmpty) {
                              return itemName;
                            }
                            return '$itemName ($notes)';
                          })(),
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
                        '$totalGrossWeight gm',
                        style: tableHeaderStyle,
                        alignment: pw.Alignment.centerRight,
                        backgroundColor: PdfColors.grey100,
                      ),
                      tableCell(
                        '$totalLessWeight gm',
                        style: tableHeaderStyle,
                        alignment: pw.Alignment.centerRight,
                        backgroundColor: PdfColors.grey100,
                      ),
                      tableCell(
                        '$totalNetWeight gm',
                        style: tableHeaderStyle,
                        alignment: pw.Alignment.centerRight,
                        backgroundColor: PdfColors.grey100,
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 8),
              pw.Align(
                alignment: pw.Alignment.centerLeft,
                child: infoCell(
                  'Delivery Date',
                  deliveryDate,
                  centerContent: true,
                ),
              ),
            ],
          );
        },
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
        text: '\u0936\u094d\u0930\u0940:',
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
    if (byteData == null) {
      return Uint8List(0);
    }
    return byteData.buffer.asUint8List();
  }

  Future<Uint8List> _buildPersonIconImage() async {
    const iconSize = 18.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final textPainter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(Icons.person.codePoint),
        style: TextStyle(
          color: Colors.black,
          fontSize: iconSize,
          fontFamily: Icons.person.fontFamily,
          package: Icons.person.fontPackage,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    )..layout();

    textPainter.paint(canvas, Offset.zero);
    final image = await recorder.endRecording().toImage(
      textPainter.width <= 0 ? 1 : textPainter.width.ceil(),
      textPainter.height <= 0 ? 1 : textPainter.height.ceil(),
    );
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) {
      return Uint8List(0);
    }
    return byteData.buffer.asUint8List();
  }

  Future<Uint8List> _buildPhoneIconImage() async {
    const iconSize = 18.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final textPainter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(Icons.phone.codePoint),
        style: TextStyle(
          color: Colors.black,
          fontSize: iconSize,
          fontFamily: Icons.phone.fontFamily,
          package: Icons.phone.fontPackage,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    )..layout();

    textPainter.paint(canvas, Offset.zero);
    final image = await recorder.endRecording().toImage(
      textPainter.width <= 0 ? 1 : textPainter.width.ceil(),
      textPainter.height <= 0 ? 1 : textPainter.height.ceil(),
    );
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) {
      return Uint8List(0);
    }
    return byteData.buffer.asUint8List();
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
    required this.overallDiscount,
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
  final double overallDiscount;
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

  String _itemNameWithNotes(_NewItemDraft item) {
    final name = item.nameController.text.trim();
    final notes = item.notesController.text.trim();
    if (notes.isEmpty) {
      return name;
    }
    return '$name ($notes)';
  }

  String _makingDisplay(_NewItemDraft item) {
    switch (item.makingType) {
      case 'PerGram':
        return '${_formatCurrency(item.makingCharge)} / gm';
      case 'TotalMaking':
        return '${_formatCurrency(item.makingCharge)} T';
      case 'FixRate':
        return '${_formatCurrency(item.makingCharge)} FixRate';
      case 'Percentage':
        final value = item.makingCharge;
        final text = value == value.roundToDouble()
            ? value.toStringAsFixed(0)
            : value.toStringAsFixed(2);
        return '$text%';
      default:
        return _formatCurrency(item.makingCharge);
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
        text: '\u0936\u094d\u0930\u0940:',
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
    return _PdfPreviewScaffold(
      title: 'New Items PDF Preview',
      helperText:
          'Double-click to enlarge on desktop, or pinch to zoom in and out on touch devices.',
      pdfFileName: 'new-items-preview.pdf',
      buildPdf: _buildNewItemsPdf,
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
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(16),
        build: (context) {
          final headingStyle = pw.TextStyle(
            fontSize: 14,
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

          pw.Widget tableCell(
            String text, {
            required pw.TextStyle style,
            pw.Alignment alignment = pw.Alignment.centerLeft,
            PdfColor? backgroundColor,
            int maxLines = 1,
          }) {
            final content = text.isEmpty ? ' ' : text;
            final baseFontSize = style.fontSize ?? 7.5;
            final scaledFontSize = switch (content.length) {
              > 42 => (baseFontSize - 2.8).clamp(4.2, baseFontSize),
              > 30 => (baseFontSize - 2.2).clamp(4.4, baseFontSize),
              > 22 => (baseFontSize - 1.6).clamp(4.8, baseFontSize),
              > 14 => (baseFontSize - 1.0).clamp(5.2, baseFontSize),
              _ => baseFontSize,
            };
            return pw.Container(
              alignment: alignment,
              color: backgroundColor,
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 4,
                vertical: 4,
              ),
              child: pw.Text(
                content,
                style: style.copyWith(fontSize: scaledFontSize),
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
            pw.SizedBox(height: 8),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey400),
              columnWidths: const {
                0: pw.FixedColumnWidth(32),
                1: pw.FlexColumnWidth(2.0),
                2: pw.FixedColumnWidth(40),
                3: pw.FixedColumnWidth(44),
                4: pw.FixedColumnWidth(40),
                5: pw.FixedColumnWidth(44),
                6: pw.FixedColumnWidth(48),
                7: pw.FixedColumnWidth(66),
                8: pw.FixedColumnWidth(58),
                9: pw.FixedColumnWidth(40),
                10: pw.FixedColumnWidth(52),
              },
              defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    tableCell(
                      'S No',
                      style: tableHeaderStyle,
                      backgroundColor: PdfColors.grey200,
                      alignment: pw.Alignment.center,
                    ),
                    tableCell(
                      'Item Name',
                      style: tableHeaderStyle,
                      backgroundColor: PdfColors.grey200,
                      alignment: pw.Alignment.center,
                      maxLines: 2,
                    ),
                    tableCell(
                      'Purity',
                      style: tableHeaderStyle,
                      backgroundColor: PdfColors.grey200,
                      alignment: pw.Alignment.center,
                      maxLines: 2,
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
                      'Rate / gm',
                      style: tableHeaderStyle,
                      backgroundColor: PdfColors.grey200,
                      alignment: pw.Alignment.centerRight,
                    ),
                    tableCell(
                      'Making',
                      style: tableHeaderStyle,
                      backgroundColor: PdfColors.grey200,
                      alignment: pw.Alignment.center,
                      maxLines: 2,
                    ),
                    tableCell(
                      'Additionals',
                      style: tableHeaderStyle,
                      backgroundColor: PdfColors.grey200,
                      alignment: pw.Alignment.centerRight,
                    ),
                    tableCell(
                      'Others',
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
                        _itemNameWithNotes(entry.value),
                        style: tableStyle,
                      ),
                      tableCell(
                        _categoryLabel(entry.value.category),
                        style: tableStyle,
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
                        _formatCurrency(_bhavFor(entry.value)),
                        style: tableStyle,
                        alignment: pw.Alignment.centerRight,
                      ),
                      tableCell(_makingDisplay(entry.value), style: tableStyle),
                      tableCell(
                        entry.value.additionalCharge > 0
                            ? _formatCurrency(entry.value.additionalCharge)
                            : '-',
                        style: tableStyle,
                        alignment: pw.Alignment.centerRight,
                      ),
                      tableCell(
                        _gstAmount(entry.value) > 0
                            ? _formatCurrency(_gstAmount(entry.value))
                            : '-',
                        style: tableStyle,
                        alignment: pw.Alignment.centerRight,
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
                      _formatWeightFixed3(
                        newItems.fold<double>(
                          0,
                          (total, item) => total + item.netWeight,
                        ),
                      ),
                      style: tableHeaderStyle,
                      backgroundColor: PdfColors.grey100,
                      alignment: pw.Alignment.centerRight,
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
                      _formatCurrency(
                        newItems.fold<double>(
                          0,
                          (total, item) => total + item.additionalCharge,
                        ),
                      ),
                      style: tableHeaderStyle,
                      backgroundColor: PdfColors.grey100,
                      alignment: pw.Alignment.centerRight,
                    ),
                    tableCell(
                      _formatCurrency(
                        newItems.fold<double>(
                          0,
                          (total, item) => total + _gstAmount(item),
                        ),
                      ),
                      style: tableHeaderStyle,
                      backgroundColor: PdfColors.grey100,
                      alignment: pw.Alignment.centerRight,
                    ),
                    tableCell(
                      _formatCurrency(
                        newItems.fold<double>(
                          0,
                          (total, item) => total + _lineTotal(item),
                        ),
                      ),
                      style: tableHeaderStyle,
                      backgroundColor: PdfColors.grey100,
                      alignment: pw.Alignment.centerRight,
                    ),
                  ],
                ),
                if (overallDiscount > 0)
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
                        'Overall Discount',
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
                        '',
                        style: tableHeaderStyle,
                        backgroundColor: PdfColors.grey100,
                      ),
                      tableCell(
                        _formatCurrency(overallDiscount),
                        style: tableHeaderStyle,
                        backgroundColor: PdfColors.grey100,
                        alignment: pw.Alignment.centerRight,
                      ),
                    ],
                  ),
                if (overallDiscount > 0)
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
                        'Total Due Amount',
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
          ];
        },
      ),
    );

    return document.save();
  }
}
