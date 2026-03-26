part of '../main.dart';

class _OrderCard extends StatelessWidget {
  const _OrderCard({
    required this.order,
    this.onView,
    this.onEdit,
    this.onDelete,
  });

  final Order order;
  final VoidCallback? onView;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _StatusPill(status: order.status),
                  const SizedBox(height: 8),
                  Text(
                    order.customer,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    (order.customerPhone ?? '').trim().isEmpty
                        ? '-'
                        : order.customerPhone!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Flexible(
              fit: FlexFit.loose,
              child: Column(
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
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (onView != null)
                        IconButton.filledTonal(
                          onPressed: onView,
                          icon: const Icon(Icons.visibility_outlined, size: 18),
                          tooltip: 'View / Print',
                        ),
                      if (onEdit != null) ...[
                        IconButton.filledTonal(
                          onPressed: onEdit,
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          tooltip: 'Edit',
                        ),
                      ],
                      if (onDelete != null) ...[
                        if (onEdit != null) const SizedBox(width: 8),
                        IconButton.filledTonal(
                          onPressed: onDelete,
                          style: FilledButton.styleFrom(
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.errorContainer,
                            foregroundColor: Theme.of(
                              context,
                            ).colorScheme.onErrorContainer,
                          ),
                          icon: const Icon(Icons.delete_outline, size: 18),
                          tooltip: 'Delete',
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final OrderStatus status;

  @override
  Widget build(BuildContext context) {
    final color = status.color(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(31),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
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
