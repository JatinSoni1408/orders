part of '../main.dart';

class _BhavPage extends StatefulWidget {
  const _BhavPage({
    required this.gold22Rate,
    required this.gold18Rate,
    required this.silverRate,
    required this.openedAt,
  });

  final double gold22Rate;
  final double gold18Rate;
  final double silverRate;
  final DateTime openedAt;

  @override
  State<_BhavPage> createState() => _BhavPageState();
}

class _BhavPageState extends State<_BhavPage>
    with SingleTickerProviderStateMixin {
  Timer? _clockTimer;
  DateTime _now = DateTime.now();
  AnimationController? _returnRateController;
  Animation<double>? _returnRateOffset;

  @override
  void initState() {
    super.initState();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
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
    _clockTimer?.cancel();
    _returnRateController?.dispose();
    super.dispose();
  }

  void _ensureReturnRateAnimation() {
    if (_returnRateController != null) {
      return;
    }
    final controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 360),
    )..repeat(reverse: true);
    _returnRateController = controller;
    _returnRateOffset = Tween<double>(
      begin: -2.0,
      end: 2.0,
    ).animate(CurvedAnimation(parent: controller, curve: Curves.easeInOut));
  }

  String _twoDigits(int value) => value.toString().padLeft(2, '0');

  String _formatClock(DateTime value) {
    final date =
        '${_twoDigits(value.day)}/${_twoDigits(value.month)}/${value.year}';
    final time =
        '${_twoDigits(value.hour)}:${_twoDigits(value.minute)}:${_twoDigits(value.second)}';
    return '$date  $time';
  }

  String _formatRate(double value, {int decimals = 0}) {
    if (value <= 0) {
      return '-';
    }
    final formatter = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '',
      decimalDigits: decimals,
    );
    return formatter.format(value);
  }

  double get _gold24Approx =>
      widget.gold22Rate <= 0 ? 0 : (widget.gold22Rate * 24) / 22;

  double get _return22Rate =>
      widget.gold22Rate <= 0 ? 0 : widget.gold22Rate - 300;

  double get _return18Rate =>
      widget.gold18Rate <= 0 ? 0 : widget.gold18Rate - 300;

  Widget _rateRow({
    required BuildContext context,
    required String label,
    required String value,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$value / Gram',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: scheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _returnRateRow({required String label, required String value}) {
    _ensureReturnRateAnimation();
    return AnimatedBuilder(
      animation: _returnRateOffset ?? const AlwaysStoppedAnimation<double>(0),
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_returnRateOffset?.value ?? 0, 0),
          child: child,
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.red,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$value / Gram',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Bhav')),
      body: ColoredBox(
        color: Colors.white,
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(12),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: constraints.maxWidth > 720
                          ? 720
                          : constraints.maxWidth,
                    ),
                    child: Card(
                      elevation: 0,
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(color: colorScheme.outlineVariant),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.asset(
                                  'assets/logo.png',
                                  width: 32,
                                  height: 32,
                                  fit: BoxFit.contain,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'Current Bhav',
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _formatClock(_now),
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Rates from New Items: ${_formatClock(widget.openedAt)}',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.green.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            _rateRow(
                              context: context,
                              label: 'Gold24kt Rate (Approx)',
                              value: _formatRate(_gold24Approx, decimals: 0),
                            ),
                            const Divider(height: 1),
                            _rateRow(
                              context: context,
                              label: 'Gold22kt Rate',
                              value: _formatRate(
                                widget.gold22Rate,
                                decimals: 0,
                              ),
                            ),
                            const Divider(height: 1),
                            _rateRow(
                              context: context,
                              label: 'Gold18kt Rate',
                              value: _formatRate(
                                widget.gold18Rate,
                                decimals: 0,
                              ),
                            ),
                            const Divider(height: 1),
                            _rateRow(
                              context: context,
                              label: 'Silver Rate',
                              value: _formatRate(
                                widget.silverRate,
                                decimals: 2,
                              ),
                            ),
                            const Divider(height: 1),
                            _returnRateRow(
                              label: 'Return Rate 22kt',
                              value: _formatRate(_return22Rate, decimals: 0),
                            ),
                            const Divider(height: 1),
                            _returnRateRow(
                              label: 'Return Rate 18kt',
                              value: _formatRate(_return18Rate, decimals: 0),
                            ),
                            const SizedBox(height: 18),
                            Text(
                              'Rates shown here come directly from the New Items page.',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
