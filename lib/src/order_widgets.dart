part of '../main.dart';

class _OrderCard extends StatelessWidget {
  const _OrderCard({
    required this.order,
    this.onPrint,
    this.onEdit,
    this.onDelete,
  });

  final Order order;
  final VoidCallback? onPrint;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final actionButtons = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (onPrint != null) ...[
          IconButton.filledTonal(
            onPressed: onPrint,
            icon: const Icon(Icons.print_outlined, size: 18),
            tooltip: 'Print preview',
          ),
          if (onEdit != null || onDelete != null) const SizedBox(width: 8),
        ],
        if (onEdit != null) ...[
          IconButton.filledTonal(
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined, size: 18),
            tooltip: 'Edit',
          ),
          if (onDelete != null) const SizedBox(width: 8),
        ],
        if (onDelete != null)
          IconButton.filledTonal(
            onPressed: onDelete,
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.errorContainer,
              foregroundColor: Theme.of(context).colorScheme.onErrorContainer,
            ),
            icon: const Icon(Icons.delete_outline, size: 18),
            tooltip: 'Delete',
          ),
      ],
    );

    final orderDetails = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _DeliveryCountdownPill(deliveryDate: order.deliveryDate),
        const SizedBox(height: 8),
        Text(
          order.customer,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Text(
          (order.customerPhone ?? '').trim().isEmpty
              ? '-'
              : order.customerPhone!,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade700),
        ),
      ],
    );

    final actionPane = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          order.deliveryDate == null
              ? 'Delivery Date: -'
              : 'Delivery Date: ${_formatEntryDate(order.deliveryDate!)}',
          textAlign: TextAlign.right,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          softWrap: false,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade700),
        ),
        const SizedBox(height: 8),
        Align(alignment: Alignment.centerRight, child: actionButtons),
      ],
    );

    return Card(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 760;

          return Padding(
            padding: const EdgeInsets.all(16),
            child: isCompact
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      orderDetails,
                      const SizedBox(height: 12),
                      actionPane,
                    ],
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(child: orderDetails),
                      const SizedBox(width: 24),
                      SizedBox(width: 250, child: actionPane),
                    ],
                  ),
          );
        },
      ),
    );
  }
}

class _DeliveryCountdownPill extends StatefulWidget {
  const _DeliveryCountdownPill({required this.deliveryDate});

  final DateTime? deliveryDate;

  @override
  State<_DeliveryCountdownPill> createState() => _DeliveryCountdownPillState();
}

class _DeliveryCountdownPillState extends State<_DeliveryCountdownPill> {
  Timer? _ticker;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _now = DateTime.now();
      });
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  DateTime _deliveryDeadline(DateTime date) {
    return DateTime(date.year, date.month, date.day, 23, 59, 59, 999);
  }

  String _formatDuration(Duration duration) {
    final totalSeconds = duration.inSeconds;
    final days = totalSeconds ~/ Duration.secondsPerDay;
    final hours =
        (totalSeconds % Duration.secondsPerDay) ~/ Duration.secondsPerHour;
    final minutes =
        (totalSeconds % Duration.secondsPerHour) ~/ Duration.secondsPerMinute;
    final seconds = totalSeconds % Duration.secondsPerMinute;

    if (days > 0) {
      return '${days}d ${hours.toString().padLeft(2, '0')}h ${minutes.toString().padLeft(2, '0')}m ${seconds.toString().padLeft(2, '0')}s';
    }
    return '${hours.toString().padLeft(2, '0')}h ${minutes.toString().padLeft(2, '0')}m ${seconds.toString().padLeft(2, '0')}s';
  }

  @override
  Widget build(BuildContext context) {
    final deliveryDate = widget.deliveryDate;
    final colorScheme = Theme.of(context).colorScheme;

    late final String label;
    late final Color textColor;
    late final Color backgroundColor;

    if (deliveryDate == null) {
      label = 'No delivery date';
      textColor = Colors.grey.shade700;
      backgroundColor = colorScheme.surfaceContainerHighest;
    } else {
      final remaining = _deliveryDeadline(deliveryDate).difference(_now);
      if (remaining.isNegative) {
        label = 'Overdue ${_formatDuration(remaining.abs())}';
        textColor = colorScheme.error;
        backgroundColor = colorScheme.errorContainer;
      } else {
        label = _formatDuration(remaining);
        final isUrgent = remaining.inHours < 24;
        textColor = isUrgent ? colorScheme.tertiary : colorScheme.primary;
        backgroundColor = isUrgent
            ? colorScheme.tertiaryContainer
            : colorScheme.primaryContainer;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: textColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _EstimateSummaryRow extends StatelessWidget {
  const _EstimateSummaryRow({
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final textStyle = emphasize
        ? Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)
        : Theme.of(context).textTheme.bodyLarge;

    return Row(
      children: [
        Expanded(child: Text(label, style: textStyle)),
        Text(value, style: textStyle),
      ],
    );
  }
}

class _EstimateSummaryInlineItem extends StatelessWidget {
  const _EstimateSummaryInlineItem({
    required this.label,
    required this.value,
    this.crossAxisAlignment = CrossAxisAlignment.start,
    this.textAlign = TextAlign.left,
  });

  final String label;
  final String value;
  final CrossAxisAlignment crossAxisAlignment;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    final labelStyle = Theme.of(
      context,
    ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade700);
    final valueStyle = Theme.of(
      context,
    ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700);

    return Column(
      crossAxisAlignment: crossAxisAlignment,
      children: [
        Text(label, style: labelStyle, textAlign: textAlign),
        const SizedBox(height: 2),
        Text(value, style: valueStyle, textAlign: textAlign),
      ],
    );
  }
}
