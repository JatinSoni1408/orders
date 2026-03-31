part of '../main.dart';

class _DateField extends StatelessWidget {
  const _DateField({
    required this.date,
    required this.onDateSelected,
    this.labelText = 'Date',
    this.valueStyle,
    this.labelStyle,
    this.iconColor,
    this.borderColor,
  });

  final DateTime date;
  final ValueChanged<DateTime> onDateSelected;
  final String labelText;
  final TextStyle? valueStyle;
  final TextStyle? labelStyle;
  final Color? iconColor;
  final Color? borderColor;

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
          labelStyle: labelStyle,
          border: OutlineInputBorder(
            borderSide: BorderSide(color: borderColor ?? Colors.grey),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: borderColor ?? Colors.grey),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: borderColor ?? Theme.of(context).colorScheme.primary,
              width: 1.4,
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today_outlined, size: 18, color: iconColor),
            const SizedBox(width: 8),
            Text(label, style: valueStyle),
          ],
        ),
      ),
    );
  }
}

class _EditableDateField extends StatefulWidget {
  const _EditableDateField({
    required this.date,
    required this.onDateSelected,
    this.labelText = 'Date',
  });

  final DateTime date;
  final ValueChanged<DateTime> onDateSelected;
  final String labelText;

  @override
  State<_EditableDateField> createState() => _EditableDateFieldState();
}

class _EditableDateFieldState extends State<_EditableDateField> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _formatDate(widget.date));
    _focusNode = FocusNode();
    _focusNode.addListener(() {
      if (mounted) {
        setState(() {});
      }
      if (!_focusNode.hasFocus) {
        _commitControllerValue();
      }
    });
  }

  @override
  void didUpdateWidget(covariant _EditableDateField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_focusNode.hasFocus) {
      return;
    }
    final formattedDate = _formatDate(widget.date);
    if (_controller.text != formattedDate) {
      _controller.text = formattedDate;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) => DateFormat('dd/MM/yy').format(date);

  DateTime? _parseDate(String rawText) {
    final parts = rawText.split('/');
    if (parts.length != 3) {
      return null;
    }

    final day = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final rawYear = int.tryParse(parts[2]);
    if (day == null || month == null || rawYear == null) {
      return null;
    }

    final year = switch (parts[2].length) {
      2 => 2000 + rawYear,
      4 => rawYear,
      _ => -1,
    };
    if (year < 2020 || year > 2100) {
      return null;
    }

    try {
      final parsedDate = DateTime(year, month, day);
      if (parsedDate.year != year ||
          parsedDate.month != month ||
          parsedDate.day != day) {
        return null;
      }
      return parsedDate;
    } catch (_) {
      return null;
    }
  }

  void _commitControllerValue() {
    final rawText = _controller.text.trim();
    if (rawText.isEmpty) {
      setState(() {
        _errorText = 'Enter a date';
        _controller.text = _formatDate(widget.date);
      });
      return;
    }

    final parsedDate = _parseDate(rawText);
    if (parsedDate != null) {
      setState(() {
        _errorText = null;
        _controller.text = _formatDate(parsedDate);
      });
      widget.onDateSelected(parsedDate);
      return;
    }

    setState(() {
      _errorText = 'Use DD/MM/YY';
      _controller.text = _formatDate(widget.date);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final activeBorderColor = colorScheme.primary;
    final inactiveBorderColor = colorScheme.outlineVariant;

    return TextField(
      controller: _controller,
      focusNode: _focusNode,
      keyboardType: TextInputType.datetime,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9/]')),
        LengthLimitingTextInputFormatter(10),
      ],
      decoration: InputDecoration(
        labelText: widget.labelText,
        hintText: 'DD/MM/YY',
        errorText: _errorText,
        filled: true,
        fillColor: _focusNode.hasFocus
            ? colorScheme.primaryContainer.withValues(alpha: 0.22)
            : colorScheme.surface,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: inactiveBorderColor, width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: activeBorderColor, width: 2.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.error, width: 1.6),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.error, width: 2.8),
        ),
        suffixIcon: IconButton(
          onPressed: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: widget.date,
              firstDate: DateTime(2020),
              lastDate: DateTime(2100),
            );
            if (picked == null) {
              return;
            }
            _controller.text = _formatDate(picked);
            setState(() {
              _errorText = null;
            });
            widget.onDateSelected(picked);
          },
          icon: Icon(
            Icons.calendar_today_outlined,
            size: 18,
            color: _focusNode.hasFocus ? activeBorderColor : null,
          ),
          tooltip: 'Select date',
        ),
      ),
      onSubmitted: (_) => _commitControllerValue(),
    );
  }
}
