part of '../main.dart';

class _DateField extends StatelessWidget {
  const _DateField({
    required this.date,
    required this.onDateSelected,
    this.labelText = 'Date',
  });

  final DateTime date;
  final ValueChanged<DateTime> onDateSelected;
  final String labelText;

  @override
  Widget build(BuildContext context) {
    final label = _formatEntryDate(date);

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime(2020),
          lastDate: DateTime(2100),
        );
        if (picked == null) {
          return;
        }
        onDateSelected(picked);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: labelText,
          border: const OutlineInputBorder(),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_outlined, size: 18),
            const SizedBox(width: 8),
            Text(label),
          ],
        ),
      ),
    );
  }
}
