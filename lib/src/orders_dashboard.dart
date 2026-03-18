part of '../main.dart';

class OrdersDashboard extends StatefulWidget {
  const OrdersDashboard({super.key});

  @override
  State<OrdersDashboard> createState() => _OrdersDashboardState();
}

class _OrdersDashboardState extends State<OrdersDashboard>
    with WidgetsBindingObserver {
  static const _ordersStorageKey = 'orders_dashboard.orders';
  static const _estimateStorageKey = 'orders_dashboard.estimate';
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final List<Order> _orders = [
    Order(
      id: 'JW-2049',
      customer: 'Ava Kapoor',
      items: [
        OrderItem(
          name: 'Rose gold ring',
          category: 'Ring',
          date: DateTime.now().subtract(const Duration(hours: 3)),
          quantity: 1,
          bhav: 5200,
          weight: 8.5,
          making: 120,
        ),
        OrderItem(
          name: 'Diamond accent polishing',
          category: 'Service',
          date: DateTime.now().subtract(const Duration(hours: 3)),
          quantity: 1,
          bhav: 0,
          weight: 0,
          making: 80,
        ),
      ],
      total: 1840,
      status: OrderStatus.preparing,
      createdAt: DateTime.now().subtract(const Duration(minutes: 12)),
      customerPhone: '+1 415 555 0142',
      altCustomerPhone: '+1 415 555 0143',
      advancePayments: [
        AdvancePayment(
          date: DateTime.now().subtract(const Duration(days: 2)),
          amount: 450,
          rate: 52.75,
          making: 120,
          weight: 8.5,
        ),
      ],
    ),
    Order(
      id: 'JW-2048',
      customer: 'Chris Mehta',
      items: [
        OrderItem(
          name: 'Custom necklace',
          category: 'Necklace',
          date: DateTime.now().subtract(const Duration(hours: 5)),
          quantity: 1,
          bhav: 5400,
          weight: 12.2,
          making: 180,
        ),
        OrderItem(
          name: 'Emerald setting',
          category: 'Setting',
          date: DateTime.now().subtract(const Duration(hours: 4)),
          quantity: 1,
          bhav: 0,
          weight: 0,
          making: 140,
        ),
      ],
      total: 3250,
      status: OrderStatus.outForDelivery,
      createdAt: DateTime.now().subtract(const Duration(minutes: 25)),
      customerPhone: '+1 415 555 0188',
      altCustomerPhone: '+1 415 555 0199',
      advancePayments: [
        AdvancePayment(
          date: DateTime.now().subtract(const Duration(days: 3)),
          amount: 800,
          rate: 53.1,
          making: 180,
          weight: 12.2,
        ),
        AdvancePayment(
          date: DateTime.now().subtract(const Duration(days: 1)),
          amount: 600,
          rate: 54.4,
          making: 140,
          weight: 9.7,
        ),
      ],
    ),
    Order(
      id: 'JW-2047',
      customer: 'Maya Patel',
      items: [
        OrderItem(
          name: 'Pearl earrings',
          category: 'Earrings',
          date: DateTime.now().subtract(const Duration(hours: 6)),
          quantity: 1,
          bhav: 0,
          weight: 5.6,
          making: 90,
        ),
        OrderItem(
          name: 'Gift box',
          category: 'Packaging',
          date: DateTime.now().subtract(const Duration(hours: 6)),
          quantity: 1,
          bhav: 0,
          weight: 0,
          making: 15,
        ),
      ],
      total: 980,
      status: OrderStatus.delivered,
      createdAt: DateTime.now().subtract(const Duration(hours: 1)),
      customerPhone: '+1 415 555 0126',
    ),
    Order(
      id: 'JW-2046',
      customer: 'Noah Singh',
      items: [
        OrderItem(
          name: "Men's bracelet",
          category: 'Bracelet',
          date: DateTime.now().subtract(const Duration(hours: 7)),
          quantity: 1,
          bhav: 4800,
          weight: 7.1,
          making: 110,
        ),
        OrderItem(
          name: 'Engraving',
          category: 'Service',
          date: DateTime.now().subtract(const Duration(hours: 7)),
          quantity: 1,
          bhav: 0,
          weight: 0,
          making: 50,
        ),
      ],
      total: 760,
      status: OrderStatus.pending,
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
  ];

  OrderStatus? _selectedStatus;
  AppSection _selectedSection = AppSection.orders;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _estimatePurityController = TextEditingController(
    text: '22K',
  );
  final TextEditingController _estimateGstController = TextEditingController(
    text: '3',
  );
  final TextEditingController _estimateMakingController = TextEditingController(
    text: '15',
  );
  final TextEditingController _estimateCustomerNameController =
      TextEditingController();
  final TextEditingController _estimateCustomerMobileController =
      TextEditingController();
  final TextEditingController _estimateAlternateMobileController =
      TextEditingController();
  final TextEditingController _estimateOccasionController =
      TextEditingController();
  final FocusNode _estimateCustomerNameFocusNode = FocusNode();
  final FocusNode _estimateCustomerMobileFocusNode = FocusNode();
  final FocusNode _estimateAlternateMobileFocusNode = FocusNode();
  final List<_EstimateItemDraft> _estimateItems = [_EstimateItemDraft()];
  Timer? _estimateClockTimer;
  Timer? _persistDebounceTimer;
  bool _showEstimateNameError = false;
  bool _showEstimateMobileError = false;
  bool _showEstimateAlternateMobileError = false;
  bool _isRestoringLocalState = false;
  OrderStatus _estimateStatus = OrderStatus.pending;
  DateTime _estimateDate = DateTime.now();
  DateTime _estimateDeliveryDate = DateTime.now();
  DateTime _estimateOccasionDate = DateTime.now();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _attachEstimateFieldListeners();
    for (final item in _estimateItems) {
      _attachEstimateItemListeners(item);
    }
    _estimateClockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _estimateDate = DateTime.now();
      });
    });
    _estimateCustomerNameFocusNode.addListener(() {
      if (!_estimateCustomerNameFocusNode.hasFocus) {
        setState(() {
          _showEstimateNameError = true;
        });
      }
    });
    _estimateCustomerMobileFocusNode.addListener(() {
      if (!_estimateCustomerMobileFocusNode.hasFocus) {
        setState(() {
          _showEstimateMobileError = true;
        });
      }
    });
    _estimateAlternateMobileFocusNode.addListener(() {
      if (!_estimateAlternateMobileFocusNode.hasFocus) {
        setState(() {
          _showEstimateAlternateMobileError = true;
        });
      }
    });
    _restoreLocalState();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _persistDebounceTimer?.cancel();
      _persistLocalState();
    }
  }

  List<Order> get _filteredOrders {
    Iterable<Order> results = _orders;

    if (_selectedStatus != null) {
      results = results.where((order) => order.status == _selectedStatus);
    }

    final query = _searchQuery.trim().toLowerCase();
    if (query.isNotEmpty) {
      results = results.where((order) {
        final name = order.customer.toLowerCase();
        final phone = (order.customerPhone ?? '').toLowerCase();
        final altPhone = (order.altCustomerPhone ?? '').toLowerCase();
        return name.contains(query) ||
            phone.contains(query) ||
            altPhone.contains(query) ||
            order.id.toLowerCase().contains(query);
      });
    }

    return results.toList();
  }

  double get _estimateGst {
    return double.tryParse(_estimateGstController.text.trim()) ?? 0;
  }

  double get _estimateMaking {
    return double.tryParse(_estimateMakingController.text.trim()) ?? 0;
  }

  String get _estimatePurity {
    final purity = _estimatePurityController.text.trim();
    return purity.isEmpty ? '-' : purity;
  }

  String get _estimateCustomerName {
    final name = _estimateCustomerNameController.text.trim();
    return name.isEmpty ? '-' : name;
  }

  String get _estimateCustomerMobile {
    final mobile = _estimateCustomerMobileController.text.trim();
    return mobile.isEmpty ? '-' : mobile;
  }

  String get _estimateAlternateMobile {
    final mobile = _estimateAlternateMobileController.text.trim();
    return mobile.isEmpty ? '-' : mobile;
  }

  String get _estimateOccasion {
    final occasion = _estimateOccasionController.text.trim();
    return occasion.isEmpty ? '-' : occasion;
  }

  String get _estimateOccasionDateLabel {
    return DateFormat('dd/MM/yyyy').format(_estimateOccasionDate);
  }

  String get _estimateDeliveryDateLabel {
    return DateFormat('dd/MM/yyyy').format(_estimateDeliveryDate);
  }

  int get _estimateTotalQuantity {
    return _estimateItems
        .where((item) => !item.isEmpty)
        .fold<int>(0, (sum, item) => sum + item.quantity);
  }

  double get _estimateTotalNettWeight {
    return _estimateItems
        .where((item) => !item.isEmpty)
        .fold<double>(0, (sum, item) => sum + item.totalNettWeight);
  }

  String get _estimateWeightRangeLabel {
    final startWeight = _estimateTotalNettWeight;
    final endWeight = startWeight + 4;
    return '${_formatWeight3(startWeight)} gm - ${_formatWeight3(endWeight)} gm';
  }

  List<_EstimateItemDraft> get _sortedEstimateItems {
    const purityOrder = {'22K': 0, '18K': 1, 'Silver': 2};
    final items = _estimateItems.where((item) => !item.isEmpty).toList();
    items.sort((a, b) {
      final purityCompare = (purityOrder[a.purityController.text.trim()] ?? 99)
          .compareTo(purityOrder[b.purityController.text.trim()] ?? 99);
      if (purityCompare != 0) {
        return purityCompare;
      }
      return a.nameController.text.trim().compareTo(
        b.nameController.text.trim(),
      );
    });
    return items;
  }

  String? get _estimateNameError {
    if (!_showEstimateNameError) {
      return null;
    }
    final name = _estimateCustomerNameController.text.trim();
    if (name.isEmpty) {
      return 'Enter name';
    }
    if (RegExp(r'\d').hasMatch(name)) {
      return 'Name cannot contain numbers';
    }
    return null;
  }

  String? get _estimateMobileError {
    if (!_showEstimateMobileError) {
      return null;
    }
    final mobile = _estimateCustomerMobileController.text.trim();
    if (mobile.isEmpty) {
      return 'Enter mobile number';
    }
    final digitsOnly = mobile.replaceAll(RegExp(r'\D'), '');
    if (digitsOnly.length != 10) {
      return 'Enter a valid 10-digit mobile number';
    }
    return null;
  }

  String? get _estimateAlternateMobileError {
    if (!_showEstimateAlternateMobileError) {
      return null;
    }
    final mobile = _estimateAlternateMobileController.text.trim();
    if (mobile.isEmpty) {
      return null;
    }
    final digitsOnly = mobile.replaceAll(RegExp(r'\D'), '');
    if (digitsOnly.length != 10) {
      return 'Enter a valid 10-digit number';
    }
    return null;
  }

  void _attachEstimateFieldListeners() {
    for (final controller in [
      _estimatePurityController,
      _estimateGstController,
      _estimateMakingController,
      _estimateCustomerNameController,
      _estimateCustomerMobileController,
      _estimateAlternateMobileController,
      _estimateOccasionController,
    ]) {
      controller.addListener(_schedulePersistence);
    }
  }

  void _attachEstimateItemListeners(_EstimateItemDraft item) {
    for (final controller in [
      item.nameController,
      item.purityController,
      item.quantityController,
      item.estimatedNettWeightController,
      item.notesController,
    ]) {
      controller.addListener(_schedulePersistence);
    }
  }

  void _schedulePersistence() {
    if (_isRestoringLocalState) {
      return;
    }
    _persistDebounceTimer?.cancel();
    _persistDebounceTimer = Timer(const Duration(milliseconds: 400), () {
      _persistLocalState();
    });
  }

  Future<void> _persistLocalState() async {
    if (_isRestoringLocalState) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _ordersStorageKey,
      jsonEncode(_orders.map((order) => order.toJson()).toList()),
    );
    await prefs.setString(
      _estimateStorageKey,
      jsonEncode({
        'selectedSection': _selectedSection.name,
        'selectedStatus': _selectedStatus?.name,
        'purity': _estimatePurityController.text,
        'gst': _estimateGstController.text,
        'making': _estimateMakingController.text,
        'customerName': _estimateCustomerNameController.text,
        'customerMobile': _estimateCustomerMobileController.text,
        'alternateMobile': _estimateAlternateMobileController.text,
        'occasion': _estimateOccasionController.text,
        'status': _estimateStatus.name,
        'deliveryDate': _estimateDeliveryDate.toIso8601String(),
        'occasionDate': _estimateOccasionDate.toIso8601String(),
        'items': _estimateItems.map((item) => item.toJson()).toList(),
      }),
    );
  }

  Future<void> _restoreLocalState() async {
    final prefs = await SharedPreferences.getInstance();
    final savedOrders = prefs.getString(_ordersStorageKey);
    final savedEstimate = prefs.getString(_estimateStorageKey);

    if (savedOrders == null && savedEstimate == null) {
      return;
    }

    _isRestoringLocalState = true;
    try {
      if (!mounted) {
        return;
      }

      setState(() {
        if (savedOrders != null) {
          final decodedOrders = jsonDecode(savedOrders) as List<dynamic>;
          _orders
            ..clear()
            ..addAll(
              decodedOrders.map(
                (order) => Order.fromJson(order as Map<String, dynamic>),
              ),
            );
        }

        if (savedEstimate != null) {
          final decodedEstimate =
              jsonDecode(savedEstimate) as Map<String, dynamic>;
          final restoredItems =
              (decodedEstimate['items'] as List<dynamic>? ?? const [])
                  .map(
                    (item) => _EstimateItemDraft.fromJson(
                      item as Map<String, dynamic>,
                    ),
                  )
                  .toList();

          _selectedSection = AppSection.values.firstWhere(
            (section) => section.name == decodedEstimate['selectedSection'],
            orElse: () => AppSection.orders,
          );

          final savedStatus = decodedEstimate['selectedStatus'] as String?;
          _selectedStatus = savedStatus == null
              ? null
              : _orderStatusFromName(savedStatus);

          _estimatePurityController.text =
              decodedEstimate['purity'] as String? ?? '22K';
          _estimateGstController.text =
              decodedEstimate['gst'] as String? ?? '3';
          _estimateMakingController.text =
              decodedEstimate['making'] as String? ?? '15';
          _estimateCustomerNameController.text =
              decodedEstimate['customerName'] as String? ?? '';
          _estimateCustomerMobileController.text =
              decodedEstimate['customerMobile'] as String? ?? '';
          _estimateAlternateMobileController.text =
              decodedEstimate['alternateMobile'] as String? ?? '';
          _estimateOccasionController.text =
              decodedEstimate['occasion'] as String? ?? '';
          _estimateStatus = _orderStatusFromName(
            decodedEstimate['status'] as String? ?? OrderStatus.pending.name,
          );
          _estimateDeliveryDate =
              DateTime.tryParse(
                decodedEstimate['deliveryDate'] as String? ?? '',
              ) ??
              DateTime.now();
          _estimateOccasionDate =
              DateTime.tryParse(
                decodedEstimate['occasionDate'] as String? ?? '',
              ) ??
              DateTime.now();
          _showEstimateNameError = false;
          _showEstimateMobileError = false;
          _showEstimateAlternateMobileError = false;

          for (final item in _estimateItems) {
            item.dispose();
          }
          _estimateItems
            ..clear()
            ..addAll(
              restoredItems.isEmpty ? [_EstimateItemDraft()] : restoredItems,
            );

          for (final item in _estimateItems) {
            _attachEstimateItemListeners(item);
          }
        }
      });
    } finally {
      _isRestoringLocalState = false;
    }
  }

  void _openAddOrderSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return _OrderFormSheet(
          onSave: (order) {
            setState(() {
              _orders.insert(0, order);
            });
            _schedulePersistence();
          },
        );
      },
    );
  }

  void _openEditOrderSheet(Order order) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return _OrderFormSheet(
          initialOrder: order,
          onSave: (updated) {
            setState(() {
              final index = _orders.indexWhere((item) => item.id == order.id);
              if (index != -1) {
                _orders[index] = updated;
              }
            });
            _schedulePersistence();
          },
        );
      },
    );
  }

  void _openViewOrder(Order order) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final totalWeight = order.items.fold<double>(
          0,
          (sum, item) => sum + item.weight,
        );
        final totalAdvance = order.advancePayments.fold<double>(
          0,
          (sum, payment) => sum + payment.amount,
        );

        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: order.status
                          .color(context)
                          .withAlpha(38),
                      backgroundImage:
                          order.customerPhotoPath != null &&
                              order.customerPhotoPath!.trim().isNotEmpty
                          ? FileImage(File(order.customerPhotoPath!))
                          : null,
                      child:
                          (order.customerPhotoPath != null &&
                              order.customerPhotoPath!.trim().isNotEmpty)
                          ? null
                          : Text(
                              order.customer.substring(0, 1),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: order.status.color(context),
                              ),
                            ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            order.customer,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Order ID: ${order.id}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    _StatusPill(status: order.status),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _DetailChip(
                      label: 'Created',
                      value: _formatEntryDate(order.createdAt),
                    ),
                    _DetailChip(
                      label: 'Total',
                      value: _formatCurrency(order.total),
                    ),
                    _DetailChip(
                      label: 'Advance',
                      value: _formatCurrency(totalAdvance),
                    ),
                    _DetailChip(
                      label: 'Weight',
                      value: '${_formatWeight3(totalWeight)} g',
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if ((order.customerPhone ?? '').trim().isNotEmpty ||
                    (order.altCustomerPhone ?? '').trim().isNotEmpty) ...[
                  Text(
                    'Contact',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if ((order.customerPhone ?? '').trim().isNotEmpty)
                    Text(order.customerPhone!),
                  if ((order.altCustomerPhone ?? '').trim().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(order.altCustomerPhone!),
                    ),
                  const SizedBox(height: 16),
                ],
                Text(
                  'Items',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                ...order.items.map(
                  (item) => Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      title: Text(item.name),
                      subtitle: Text(
                        '${item.category} • Qty ${item.quantity} • ${_formatWeight3(item.weight)} g',
                      ),
                      trailing: Text(_formatCurrency(item.making)),
                    ),
                  ),
                ),
                if (order.advancePayments.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Advance payments',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...order.advancePayments.map(
                    (payment) => Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        title: Text(_formatCurrency(payment.amount)),
                        subtitle: Text(
                          '${_formatEntryDate(payment.date)} • Rate ${payment.rate.toStringAsFixed(2)} • Making ${payment.making.toStringAsFixed(2)}%',
                        ),
                        trailing: Text('${_formatWeight3(payment.weight)} g'),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.print_outlined),
                        label: const Text('Print'),
                        onPressed: () {
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Print coming soon')),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        icon: const Icon(Icons.edit_outlined),
                        label: const Text('Edit order'),
                        onPressed: () {
                          Navigator.of(context).pop();
                          _openEditOrderSheet(order);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openPrintPreview() {
    final totalRevenue = _orders.fold<double>(
      0,
      (sum, order) => sum + order.total,
    );

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return _PrintPreviewSheet(orders: _orders, totalRevenue: totalRevenue);
      },
    );
  }

  void _openEstimatePrintPreview() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) {
          return _EstimatePrintPreviewSheet(
            customerName: _estimateCustomerName,
            customerMobile: _estimateCustomerMobile,
            alternateMobile: _estimateAlternateMobile,
            statusLabel: _estimateStatus.label,
            occasion: _estimateOccasion,
            occasionDate: _estimateOccasionDateLabel,
            deliveryDate: _estimateDeliveryDateLabel,
            purity: _estimatePurity,
            making: _estimateMaking.toStringAsFixed(2),
            gst: '${_estimateGst.toStringAsFixed(2)}%',
            totalQuantity: _estimateTotalQuantity.toString(),
            totalWeight: _estimateWeightRangeLabel,
            items: _sortedEstimateItems,
          );
        },
      ),
    );
  }

  void _selectSection(AppSection section) {
    Navigator.of(context).pop();
    if (_selectedSection == section) {
      return;
    }

    setState(() {
      _selectedSection = section;
    });
    _schedulePersistence();
  }

  void _resetEstimateForm() {
    setState(() {
      _estimateDate = DateTime.now();
      _estimateDeliveryDate = DateTime.now();
      _estimateOccasionDate = DateTime.now();
      _estimatePurityController.text = '22K';
      _estimateGstController.text = '3';
      _estimateMakingController.text = '15';
      _estimateCustomerNameController.clear();
      _estimateCustomerMobileController.clear();
      _estimateAlternateMobileController.clear();
      _estimateOccasionController.clear();
      _showEstimateNameError = false;
      _showEstimateMobileError = false;
      _showEstimateAlternateMobileError = false;
      _estimateStatus = OrderStatus.pending;

      for (final item in _estimateItems) {
        item.dispose();
      }
      _estimateItems
        ..clear()
        ..add(_EstimateItemDraft());
      _attachEstimateItemListeners(_estimateItems.first);
    });
    _schedulePersistence();
  }

  Future<bool> _confirmExitApp() async {
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
      Navigator.of(context).pop();
      return false;
    }

    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Exit App?'),
          content: const Text(
            'Closing the app will reset the current in-memory data. Do you want to exit?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Theme.of(context).colorScheme.onError,
              ),
              child: const Text('Exit'),
            ),
          ],
        );
      },
    );

    return shouldExit ?? false;
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DrawerHeader(
              margin: EdgeInsets.zero,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Image.asset('assets/logo.png', height: 40, width: 40),
                  const SizedBox(height: 16),
                  Text(
                    'Jewellery Orders',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Navigate between orders and tools.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.receipt_long_outlined),
              title: const Text('Orders'),
              selected: _selectedSection == AppSection.orders,
              onTap: () => _selectSection(AppSection.orders),
            ),
            ListTile(
              leading: const Icon(Icons.calculate_outlined),
              title: const Text('Estimate Calculator'),
              selected: _selectedSection == AppSection.estimateCalculator,
              onTap: () => _selectSection(AppSection.estimateCalculator),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrdersBody(double contentTopPadding) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(16, contentTopPadding, 16, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search by customer or mobile',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _searchQuery = '';
                          });
                        },
                        tooltip: 'Clear search',
                      ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
            const SizedBox(height: 16),
            Text('Live orders', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            if (_filteredOrders.isEmpty)
              _EmptyState(onAdd: _openAddOrderSheet)
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _filteredOrders.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final order = _filteredOrders[index];
                  return _OrderCard(
                    order: order,
                    onView: () => _openViewOrder(order),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEstimateCalculatorBody(double contentTopPadding) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(16, contentTopPadding, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            DateFormat(
                              'dd/MM/yy HH:mm:ss',
                            ).format(_estimateDate),
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            focusNode: _estimateCustomerNameFocusNode,
                            controller: _estimateCustomerNameController,
                            decoration: InputDecoration(
                              labelText: 'Name',
                              errorText: _estimateNameError,
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<OrderStatus>(
                            initialValue: _estimateStatus,
                            decoration: const InputDecoration(
                              labelText: 'Status',
                            ),
                            items: OrderStatus.values
                                .map(
                                  (status) => DropdownMenuItem(
                                    value: status,
                                    child: Text(status.label),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              if (value == null) {
                                return;
                              }
                              setState(() {
                                _estimateStatus = value;
                              });
                              _schedulePersistence();
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            focusNode: _estimateCustomerMobileFocusNode,
                            controller: _estimateCustomerMobileController,
                            keyboardType: TextInputType.phone,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'[0-9]'),
                              ),
                              LengthLimitingTextInputFormatter(10),
                            ],
                            decoration: InputDecoration(
                              labelText: 'Whatsapp Number',
                              errorText: _estimateMobileError,
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            focusNode: _estimateAlternateMobileFocusNode,
                            controller: _estimateAlternateMobileController,
                            keyboardType: TextInputType.phone,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'[0-9]'),
                              ),
                              LengthLimitingTextInputFormatter(10),
                            ],
                            decoration: InputDecoration(
                              labelText: 'Alternate Mobile',
                              errorText: _estimateAlternateMobileError,
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _estimateOccasionController,
                            decoration: const InputDecoration(
                              labelText: 'Occasion',
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Date of Occasion',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              const SizedBox(height: 6),
                              _DateField(
                                date: _estimateOccasionDate,
                                onDateSelected: (selected) {
                                  setState(() {
                                    _estimateOccasionDate = selected;
                                  });
                                  _schedulePersistence();
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _estimatePurityController,
                    decoration: const InputDecoration(
                      labelText: 'Purity',
                      isDense: true,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _estimateMakingController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Making',
                      suffixText: '%',
                      isDense: true,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _estimateGstController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'GST: 3%',
                      suffixText: '%',
                      isDense: true,
                    ),
                    enabled: false,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Text(
                  'Estimate Items',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...List.generate(_estimateItems.length, (index) {
              final item = _estimateItems[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _EstimateItemEditor(
                  index: index + 1,
                  item: item,
                  onChanged: () => setState(() {}),
                  onRemove: _estimateItems.length == 1
                      ? null
                      : () {
                          setState(() {
                            final removed = _estimateItems.removeAt(index);
                            removed.dispose();
                          });
                          _schedulePersistence();
                        },
                ),
              );
            }),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () {
                  setState(() {
                    final item = _EstimateItemDraft();
                    _estimateItems.add(item);
                    _attachEstimateItemListeners(item);
                  });
                  _schedulePersistence();
                },
                icon: const Icon(Icons.add),
                label: const Text('Add item'),
              ),
            ),
            const SizedBox(height: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Delivery Date',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 6),
                _DateField(
                  date: _estimateDeliveryDate,
                  onDateSelected: (selected) {
                    setState(() {
                      _estimateDeliveryDate = selected;
                    });
                    _schedulePersistence();
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _resetEstimateForm,
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                  foregroundColor: Theme.of(context).colorScheme.onError,
                ),
                icon: const Icon(Icons.restart_alt),
                label: const Text('Reset'),
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Summary',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withAlpha(12),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withAlpha(28),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _EstimateSummaryMetaTile(
                            label: 'Name',
                            value: _estimateCustomerName,
                            icon: Icons.person_outline,
                            maxLines: 2,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _EstimateSummaryMetaTile(
                                  label: 'Whatsapp Number',
                                  value: _estimateCustomerMobile,
                                  icon: Icons.call_outlined,
                                  maxLines: 2,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _EstimateSummaryMetaTile(
                                  label: 'Alternate Mobile',
                                  value: _estimateAlternateMobile,
                                  icon: Icons.phone_forwarded_outlined,
                                  maxLines: 2,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _EstimateSummaryMetaTile(
                                  label: 'Occasion',
                                  value: _estimateOccasion,
                                  icon: Icons.celebration_outlined,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _EstimateSummaryMetaTile(
                                  label: 'Occasion Date',
                                  value: _estimateOccasionDateLabel,
                                  icon: Icons.event_outlined,
                                  singleLineValue: true,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Divider(color: Colors.grey.shade300, height: 1),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _EstimateSummaryInlineItem(
                            label: 'Purity',
                            value: _estimatePurity,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _EstimateSummaryInlineItem(
                            label: 'Making',
                            value: _estimateMaking.toStringAsFixed(2),
                            crossAxisAlignment: CrossAxisAlignment.center,
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _EstimateSummaryInlineItem(
                            label: 'GST',
                            value: '${_estimateGst.toStringAsFixed(2)}%',
                            crossAxisAlignment: CrossAxisAlignment.center,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    if (_sortedEstimateItems.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Table(
                          defaultColumnWidth: const IntrinsicColumnWidth(),
                          border: TableBorder.all(color: Colors.grey),
                          children: [
                            TableRow(
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                              ),
                              children: const [
                                _EstimateTableCell('S No', isHeader: true),
                                _EstimateTableCell('Purity', isHeader: true),
                                _EstimateTableCell('Item Name', isHeader: true),
                                _EstimateTableCell('Qty', isHeader: true),
                                _EstimateTableCell(
                                  'Weight (gm)',
                                  isHeader: true,
                                  textAlign: TextAlign.right,
                                ),
                                _EstimateTableCell(
                                  'Notes / Instructions',
                                  isHeader: true,
                                ),
                              ],
                            ),
                            ..._sortedEstimateItems.asMap().entries.map(
                              (entry) => TableRow(
                                children: [
                                  _EstimateTableCell('${entry.key + 1}'),
                                  _EstimateTableCell(
                                    entry.value.purityController.text.trim(),
                                  ),
                                  _EstimateTableCell(
                                    entry.value.nameController.text.trim(),
                                  ),
                                  _EstimateTableCell(
                                    entry.value.quantityController.text.trim(),
                                  ),
                                  _EstimateTableCell(
                                    _formatWeight3(entry.value.totalNettWeight),
                                    textAlign: TextAlign.right,
                                  ),
                                  _EstimateTableCell(
                                    entry.value.notesController.text.trim(),
                                  ),
                                ],
                              ),
                            ),
                            TableRow(
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                              ),
                              children: [
                                const _EstimateTableCell(''),
                                const _EstimateTableCell(''),
                                const _EstimateTableCell(
                                  'Total',
                                  isHeader: true,
                                ),
                                _EstimateTableCell(
                                  _estimateTotalQuantity.toString(),
                                  isHeader: true,
                                ),
                                _EstimateTableCell(
                                  _formatWeight3(_estimateTotalNettWeight),
                                  isHeader: true,
                                  textAlign: TextAlign.right,
                                ),
                                const _EstimateTableCell(''),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      _EstimateSummaryRow(
                        label: 'Estimated Weight',
                        value: _estimateWeightRangeLabel,
                        emphasize: true,
                      ),
                    ],
                    const SizedBox(height: 12),
                    Divider(color: Colors.grey.shade300, height: 1),
                    const SizedBox(height: 12),
                    _EstimateSummaryRow(
                      label: 'Delivery Date',
                      value: _estimateDeliveryDateLabel,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _estimateClockTimer?.cancel();
    _persistDebounceTimer?.cancel();
    _searchController.dispose();
    _estimatePurityController.dispose();
    _estimateGstController.dispose();
    _estimateMakingController.dispose();
    _estimateCustomerNameController.dispose();
    _estimateCustomerMobileController.dispose();
    _estimateAlternateMobileController.dispose();
    _estimateOccasionController.dispose();
    _estimateCustomerNameFocusNode.dispose();
    _estimateCustomerMobileFocusNode.dispose();
    _estimateAlternateMobileFocusNode.dispose();
    for (final item in _estimateItems) {
      item.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final statuses = OrderStatus.values;
    final selectedIndex = _selectedStatus == null
        ? 0
        : statuses.indexOf(_selectedStatus!) + 1;
    final contentTopPadding = MediaQuery.of(context).padding.top + 16;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) {
          return;
        }
        final shouldExit = await _confirmExitApp();
        if (shouldExit) {
          _persistDebounceTimer?.cancel();
          await _persistLocalState();
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        key: _scaffoldKey,
        drawer: _buildDrawer(context),
        appBar: AppBar(
          title: Row(
            children: [
              Image.asset(
                'assets/logo.png',
                height: 28,
                width: 28,
                fit: BoxFit.contain,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
              const SizedBox(width: 12),
              Text(
                _selectedSection == AppSection.orders
                    ? 'Orders'
                    : 'Estimate Calculator',
              ),
            ],
          ),
          actions: [
            IconButton(
              onPressed: _selectedSection == AppSection.orders
                  ? _openPrintPreview
                  : _openEstimatePrintPreview,
              icon: const Icon(Icons.print_outlined),
              tooltip: 'Print preview',
            ),
          ],
        ),
        floatingActionButton: _selectedSection == AppSection.orders
            ? FloatingActionButton.extended(
                onPressed: _openAddOrderSheet,
                icon: const Icon(Icons.add),
                label: const Text('New order'),
              )
            : null,
        bottomNavigationBar: _selectedSection == AppSection.orders
            ? NavigationBar(
                selectedIndex: selectedIndex,
                onDestinationSelected: (index) {
                  setState(() {
                    _selectedStatus = index == 0 ? null : statuses[index - 1];
                  });
                  _schedulePersistence();
                },
                destinations: [
                  const NavigationDestination(
                    icon: Icon(Icons.all_inbox_outlined),
                    label: 'All',
                  ),
                  ...statuses.map(
                    (status) => NavigationDestination(
                      icon: Icon(status.icon),
                      label: status.label,
                    ),
                  ),
                ],
              )
            : null,
        body: _selectedSection == AppSection.orders
            ? _buildOrdersBody(contentTopPadding)
            : _buildEstimateCalculatorBody(contentTopPadding),
      ),
    );
  }
}

class _EstimateItemDraft {
  _EstimateItemDraft({
    String? name,
    String? purity,
    int? quantity,
    double? estimatedNettWeight,
    String? notes,
    String? quantityText,
    String? estimatedNettWeightText,
  }) : nameController = TextEditingController(text: name ?? ''),
       purityController = TextEditingController(text: purity ?? '22K'),
       quantityController = TextEditingController(
         text: quantityText ?? (quantity == null ? '1' : quantity.toString()),
       ),
       estimatedNettWeightController = TextEditingController(
         text:
             estimatedNettWeightText ?? (estimatedNettWeight?.toString() ?? ''),
       ),
       notesController = TextEditingController(text: notes ?? '');

  factory _EstimateItemDraft.fromJson(Map<String, dynamic> json) {
    return _EstimateItemDraft(
      name: json['name'] as String? ?? '',
      purity: json['purity'] as String? ?? '22K',
      quantityText: json['quantityText'] as String? ?? '1',
      estimatedNettWeightText: json['estimatedNettWeightText'] as String? ?? '',
      notes: json['notes'] as String? ?? '',
    );
  }

  final TextEditingController nameController;
  final TextEditingController purityController;
  final TextEditingController quantityController;
  final TextEditingController estimatedNettWeightController;
  final TextEditingController notesController;
  bool showNameError = false;
  bool showQuantityError = false;
  bool showWeightError = false;

  bool get isEmpty =>
      nameController.text.trim().isEmpty &&
      notesController.text.trim().isEmpty &&
      (double.tryParse(estimatedNettWeightController.text.trim()) ?? 0) == 0;

  String? get nameError {
    if (!showNameError) {
      return null;
    }
    return nameController.text.trim().isEmpty ? 'Enter item name' : null;
  }

  String? get quantityError {
    if (!showQuantityError) {
      return null;
    }
    final quantityValue = int.tryParse(quantityController.text.trim());
    if (quantityValue == null || quantityValue <= 0) {
      return 'Enter quantity';
    }
    return null;
  }

  String? get weightError {
    if (!showWeightError) {
      return null;
    }
    final weightValue = double.tryParse(
      estimatedNettWeightController.text.trim(),
    );
    if (weightValue == null || weightValue <= 0) {
      return 'Enter weight';
    }
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'name': nameController.text,
      'purity': purityController.text,
      'quantityText': quantityController.text,
      'estimatedNettWeightText': estimatedNettWeightController.text,
      'notes': notesController.text,
    };
  }

  int get quantity => int.tryParse(quantityController.text.trim()) ?? 0;

  double get totalNettWeight {
    return double.tryParse(estimatedNettWeightController.text.trim()) ?? 0;
  }

  void dispose() {
    nameController.dispose();
    purityController.dispose();
    quantityController.dispose();
    estimatedNettWeightController.dispose();
    notesController.dispose();
  }
}

class _EstimateItemEditor extends StatelessWidget {
  const _EstimateItemEditor({
    required this.index,
    required this.item,
    required this.onChanged,
    this.onRemove,
  });

  final int index;
  final _EstimateItemDraft item;
  final VoidCallback onChanged;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    const purityOptions = ['22K', '18K', 'Silver'];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Item $index',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (onRemove != null)
                  IconButton(
                    onPressed: onRemove,
                    icon: const Icon(Icons.delete_outline),
                    tooltip: 'Remove item',
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Focus(
                    onFocusChange: (hasFocus) {
                      if (!hasFocus) {
                        item.showNameError = true;
                        onChanged();
                      }
                    },
                    child: TextField(
                      controller: item.nameController,
                      decoration: InputDecoration(
                        labelText: 'Item Name',
                        errorText: item.nameError,
                      ),
                      onChanged: (_) => onChanged(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue:
                        purityOptions.contains(item.purityController.text)
                        ? item.purityController.text
                        : purityOptions.first,
                    decoration: const InputDecoration(labelText: 'Purity'),
                    items: purityOptions
                        .map(
                          (option) => DropdownMenuItem(
                            value: option,
                            child: Text(option),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      item.purityController.text = value ?? purityOptions.first;
                      onChanged();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Focus(
                    onFocusChange: (hasFocus) {
                      if (!hasFocus) {
                        item.showQuantityError = true;
                        onChanged();
                      }
                    },
                    child: TextField(
                      controller: item.quantityController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Quantity',
                        errorText: item.quantityError,
                      ),
                      onChanged: (_) => onChanged(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Focus(
                    onFocusChange: (hasFocus) {
                      if (!hasFocus) {
                        item.showWeightError = true;
                        onChanged();
                      }
                    },
                    child: TextField(
                      controller: item.estimatedNettWeightController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Weight',
                        suffixText: 'g',
                        errorText: item.weightError,
                      ),
                      onChanged: (_) => onChanged(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: item.notesController,
              minLines: 2,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Notes / Instructions',
                hintText: 'Optional',
              ),
              onChanged: (_) => onChanged(),
            ),
          ],
        ),
      ),
    );
  }
}

class _EstimateTableCell extends StatelessWidget {
  const _EstimateTableCell(
    this.text, {
    this.isHeader = false,
    this.textAlign = TextAlign.left,
  });

  final String text;
  final bool isHeader;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    final style = isHeader
        ? Theme.of(
            context,
          ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700)
        : Theme.of(context).textTheme.bodySmall;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Text(
        text,
        textAlign: textAlign,
        style: style,
        maxLines: 1,
        softWrap: false,
        overflow: TextOverflow.visible,
      ),
    );
  }
}

class _DetailChip extends StatelessWidget {
  const _DetailChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade700),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
