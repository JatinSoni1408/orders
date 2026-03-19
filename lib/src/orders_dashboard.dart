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
  static const _legacySampleOrderIds = {
    'JW-2046',
    'JW-2047',
    'JW-2048',
    'JW-2049',
  };
  final List<Order> _orders = [];

  OrderStatus? _selectedStatus;
  OrderSortOption _selectedOrderSort = OrderSortOption.newest;
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
  final TextEditingController _estimateWeightRangeController =
      TextEditingController();
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
  final List<_AdvanceValuationDraft> _advanceItems = [_AdvanceValuationDraft()];
  final List<_AdvanceOldItemDraft> _advanceOldItems = [_AdvanceOldItemDraft()];
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
  String? _editingOrderId;
  DateTime? _editingOrderCreatedAt;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _attachEstimateFieldListeners();
    for (final item in _estimateItems) {
      _attachEstimateItemListeners(item);
    }
    for (final item in _advanceItems) {
      _attachAdvanceItemListeners(item);
    }
    for (final item in _advanceOldItems) {
      _attachAdvanceOldItemListeners(item);
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

    final sortedResults = results.toList();
    sortedResults.sort((a, b) {
      switch (_selectedOrderSort) {
        case OrderSortOption.newest:
          return b.createdAt.compareTo(a.createdAt);
        case OrderSortOption.oldest:
          return a.createdAt.compareTo(b.createdAt);
        case OrderSortOption.deliverySoonest:
          final aDate = a.deliveryDate ?? DateTime(9999);
          final bDate = b.deliveryDate ?? DateTime(9999);
          final deliveryCompare = aDate.compareTo(bDate);
          if (deliveryCompare != 0) {
            return deliveryCompare;
          }
          return b.createdAt.compareTo(a.createdAt);
        case OrderSortOption.deliveryLatest:
          final aDate = a.deliveryDate ?? DateTime(0);
          final bDate = b.deliveryDate ?? DateTime(0);
          final deliveryCompare = bDate.compareTo(aDate);
          if (deliveryCompare != 0) {
            return deliveryCompare;
          }
          return b.createdAt.compareTo(a.createdAt);
        case OrderSortOption.nameAZ:
          return a.customer.toLowerCase().compareTo(b.customer.toLowerCase());
      }
    });

    return sortedResults;
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

  bool get _isEditingEstimate {
    return _editingOrderId != null;
  }

  int get _estimateTotalQuantity {
    return _estimateItems
        .where((item) => !item.isEmpty)
        .fold<int>(0, (sum, item) => sum + item.quantity);
  }

  double get _estimateTotalEstimatedWeight {
    return _estimateItems
        .where((item) => !item.isEmpty)
        .fold<double>(0, (sum, item) => sum + item.estimatedWeight);
  }

  double get _actualTotalGrossWeight {
    return _estimateItems
        .where((item) => !item.isEmpty)
        .fold<double>(0, (sum, item) => sum + item.grossWeight);
  }

  double get _actualTotalLessWeight {
    return _estimateItems
        .where((item) => !item.isEmpty)
        .fold<double>(0, (sum, item) => sum + item.lessWeight);
  }

  double get _actualTotalNetWeight {
    return _estimateItems
        .where((item) => !item.isEmpty)
        .fold<double>(0, (sum, item) => sum + item.actualNetWeight);
  }

  List<MapEntry<String, double>> get _estimateCategoryWeightEntries {
    const preferredOrder = ['22K', '18K', 'Silver'];
    final totals = <String, double>{};

    for (final item in _estimateItems.where((item) => !item.isEmpty)) {
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

  double _estimateCategoryWeightFor(String category) {
    return _estimateCategoryWeightEntries
        .firstWhere(
          (entry) => entry.key == category,
          orElse: () => const MapEntry('', 0),
        )
        .value;
  }

  String get _estimateAutoWeightRangeLabel {
    final startWeight = _estimateTotalEstimatedWeight;
    final endWeight = startWeight + 4;
    return '${_formatWeight3(startWeight)} gm - ${_formatWeight3(endWeight)} gm';
  }

  double? get _estimateManualWeightRangeAddition {
    final text = _estimateWeightRangeController.text.trim();
    if (text.isEmpty) {
      return null;
    }
    return double.tryParse(text);
  }

  String get _estimateWeightRangeLabel {
    final startWeight = _estimateTotalEstimatedWeight;
    final manualAddition = _estimateManualWeightRangeAddition;
    if (manualAddition != null) {
      final endWeight = startWeight + manualAddition;
      return '${_formatWeight3(startWeight)} gm - ${_formatWeight3(endWeight)} gm';
    }

    final legacyRange = _estimateWeightRangeController.text.trim();
    return legacyRange.isEmpty ? _estimateAutoWeightRangeLabel : legacyRange;
  }

  List<_AdvanceValuationDraft> get _populatedAdvanceItems {
    return _advanceItems.where((item) => !item.isEmpty).toList();
  }

  double get _advanceTotalAmount {
    return _populatedAdvanceItems.fold<double>(
      0,
      (sum, item) => sum + item.amount,
    );
  }

  double get _advanceTotalNetWeight {
    return _populatedAdvanceItems.fold<double>(
      0,
      (sum, item) => sum + item.weight,
    );
  }

  List<_AdvanceOldItemDraft> get _populatedAdvanceOldItems {
    return _advanceOldItems.where((item) => !item.isEmpty).toList();
  }

  double get _advanceOldItemsTotalAmount {
    return _populatedAdvanceOldItems.fold<double>(
      0,
      (sum, item) => sum + item.amount,
    );
  }

  List<AdvancePayment> get _advancePaymentsForCurrentDraft {
    return _populatedAdvanceItems
        .map(
          (item) => AdvancePayment(
            date: item.date,
            mode: item.mode,
            amount: item.amount,
            rate: item.rate,
            making: item.rateMaking,
            weight: item.weight,
            chequeNumber: item.chequeNumber,
          ),
        )
        .toList();
  }

  List<OldItemReturn> get _advanceOldItemReturnsForCurrentDraft {
    return _populatedAdvanceOldItems
        .map(
          (item) => OldItemReturn(
            date: item.date,
            itemName: item.itemNameController.text.trim(),
            returnRate: item.returnRate,
            grossWeight: item.grossWeight,
            lessWeight: item.lessWeight,
            tanch: item.tanch,
          ),
        )
        .toList();
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
      _estimateWeightRangeController,
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
      item.grossWeightController,
      item.lessWeightController,
      item.sizeController,
      item.lengthController,
      item.notesController,
    ]) {
      controller.addListener(_schedulePersistence);
    }
  }

  void _attachAdvanceItemListeners(_AdvanceValuationDraft item) {
    for (final controller in [
      item.amountController,
      item.rateController,
      item.rateMakingController,
      item.chequeNumberController,
    ]) {
      controller.addListener(_schedulePersistence);
    }
  }

  void _attachAdvanceOldItemListeners(_AdvanceOldItemDraft item) {
    for (final controller in [
      item.itemNameController,
      item.returnRateController,
      item.grossWeightController,
      item.lessWeightController,
      item.tanchController,
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
        'selectedOrderSort': _selectedOrderSort.name,
        'purity': _estimatePurityController.text,
        'gst': _estimateGstController.text,
        'making': _estimateMakingController.text,
        'weightRange': _estimateWeightRangeController.text,
        'customerName': _estimateCustomerNameController.text,
        'customerMobile': _estimateCustomerMobileController.text,
        'alternateMobile': _estimateAlternateMobileController.text,
        'occasion': _estimateOccasionController.text,
        'status': _estimateStatus.name,
        'deliveryDate': _estimateDeliveryDate.toIso8601String(),
        'occasionDate': _estimateOccasionDate.toIso8601String(),
        'advanceItems': _advanceItems.map((item) => item.toJson()).toList(),
        'advanceOldItems': _advanceOldItems
            .map((item) => item.toJson())
            .toList(),
        'editingOrderId': _editingOrderId,
        'editingOrderCreatedAt': _editingOrderCreatedAt?.toIso8601String(),
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
              decodedOrders
                  .map((order) => Order.fromJson(order as Map<String, dynamic>))
                  .where((order) => !_legacySampleOrderIds.contains(order.id)),
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
          final restoredAdvanceItems =
              (decodedEstimate['advanceItems'] as List<dynamic>? ?? const [])
                  .map(
                    (item) => _AdvanceValuationDraft.fromJson(
                      item as Map<String, dynamic>,
                    ),
                  )
                  .toList();
          final restoredAdvanceOldItems =
              (decodedEstimate['advanceOldItems'] as List<dynamic>? ?? const [])
                  .map(
                    (item) => _AdvanceOldItemDraft.fromJson(
                      item as Map<String, dynamic>,
                    ),
                  )
                  .toList();

          _selectedSection = AppSection.orders;

          final savedStatus = decodedEstimate['selectedStatus'] as String?;
          _selectedStatus = savedStatus == null
              ? null
              : _orderStatusFromName(savedStatus);
          _selectedOrderSort = OrderSortOption.values.firstWhere(
            (option) => option.name == decodedEstimate['selectedOrderSort'],
            orElse: () => OrderSortOption.newest,
          );

          _estimatePurityController.text =
              decodedEstimate['purity'] as String? ?? '22K';
          _estimateGstController.text =
              decodedEstimate['gst'] as String? ?? '3';
          _estimateMakingController.text =
              decodedEstimate['making'] as String? ?? '15';
          _estimateWeightRangeController.text =
              decodedEstimate['weightRange'] as String? ?? '';
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
              _dateTimeFromJson(decodedEstimate['deliveryDate']) ??
              DateTime.now();
          _estimateOccasionDate =
              _dateTimeFromJson(decodedEstimate['occasionDate']) ??
              DateTime.now();
          _editingOrderId = decodedEstimate['editingOrderId'] as String?;
          _editingOrderCreatedAt = _dateTimeFromJson(
            decodedEstimate['editingOrderCreatedAt'],
          );
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

          for (final item in _advanceItems) {
            item.dispose();
          }
          _advanceItems
            ..clear()
            ..addAll(
              restoredAdvanceItems.isEmpty
                  ? [_AdvanceValuationDraft()]
                  : restoredAdvanceItems,
            );

          for (final item in _advanceItems) {
            _attachAdvanceItemListeners(item);
          }

          for (final item in _advanceOldItems) {
            item.dispose();
          }
          _advanceOldItems
            ..clear()
            ..addAll(
              restoredAdvanceOldItems.isEmpty
                  ? [_AdvanceOldItemDraft()]
                  : restoredAdvanceOldItems,
            );

          for (final item in _advanceOldItems) {
            _attachAdvanceOldItemListeners(item);
          }
        }
      });
    } finally {
      _isRestoringLocalState = false;
    }
  }

  void _openAddOrderSheet() {
    setState(() {
      _clearEstimateForm();
      _selectedSection = AppSection.estimateCalculator;
    });
    _schedulePersistence();
  }

  void _openEditOrderSheet(Order order) {
    setState(() {
      _loadEstimateFromOrder(order);
      _selectedSection = AppSection.estimateCalculator;
    });
    _schedulePersistence();
  }

  void _clearEstimateForm() {
    _editingOrderId = null;
    _editingOrderCreatedAt = null;
    _estimateDate = DateTime.now();
    _estimateDeliveryDate = DateTime.now();
    _estimateOccasionDate = DateTime.now();
    _estimatePurityController.text = '22K';
    _estimateGstController.text = '3';
    _estimateMakingController.text = '15';
    _estimateWeightRangeController.clear();
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

    for (final item in _advanceItems) {
      item.dispose();
    }
    _advanceItems
      ..clear()
      ..add(_AdvanceValuationDraft());
    _attachAdvanceItemListeners(_advanceItems.first);

    for (final item in _advanceOldItems) {
      item.dispose();
    }
    _advanceOldItems
      ..clear()
      ..add(_AdvanceOldItemDraft());
    _attachAdvanceOldItemListeners(_advanceOldItems.first);
  }

  void _loadEstimateFromOrder(Order order) {
    _editingOrderId = order.id;
    _editingOrderCreatedAt = order.createdAt;
    _estimateDate = DateTime.now();
    _estimateDeliveryDate = order.deliveryDate ?? DateTime.now();
    _estimateOccasionDate = order.occasionDate ?? DateTime.now();
    _estimatePurityController.text = order.estimatePurity ?? '22K';
    _estimateGstController.text = (order.estimateGst ?? 3).toString();
    _estimateMakingController.text = (order.estimateMaking ?? 15).toString();
    _estimateWeightRangeController.text = order.estimateWeightRange ?? '';
    _estimateCustomerNameController.text = order.customer;
    _estimateCustomerMobileController.text = order.customerPhone ?? '';
    _estimateAlternateMobileController.text = order.altCustomerPhone ?? '';
    _estimateOccasionController.text = order.occasion ?? '';
    _showEstimateNameError = false;
    _showEstimateMobileError = false;
    _showEstimateAlternateMobileError = false;
    _estimateStatus = order.status;

    for (final item in _estimateItems) {
      item.dispose();
    }
    _estimateItems
      ..clear()
      ..addAll(
        order.items.isEmpty
            ? [_EstimateItemDraft()]
            : order.items
                  .map(
                    (item) => _EstimateItemDraft(
                      name: item.name,
                      purity: item.purity ?? order.estimatePurity ?? '22K',
                      quantity: item.quantity,
                      estimatedNettWeight: item.estimatedWeight ?? item.weight,
                      grossWeight: item.grossWeight,
                      lessWeight: item.lessWeight,
                      size: item.size,
                      length: item.length,
                      notes: item.notes ?? '',
                    ),
                  )
                  .toList(),
      );
    for (final item in _estimateItems) {
      _attachEstimateItemListeners(item);
    }

    for (final item in _advanceItems) {
      item.dispose();
    }
    _advanceItems
      ..clear()
      ..addAll(
        order.advancePayments.isEmpty
            ? [_AdvanceValuationDraft()]
            : order.advancePayments
                  .map(
                    (payment) => _AdvanceValuationDraft(
                      date: payment.date,
                      mode: payment.mode,
                      amountText: payment.amount.toString(),
                      rateText: payment.rate.toString(),
                      rateMakingText: payment.making.toString(),
                      chequeNumber: payment.chequeNumber,
                    ),
                  )
                  .toList(),
      );
    for (final item in _advanceItems) {
      _attachAdvanceItemListeners(item);
    }

    for (final item in _advanceOldItems) {
      item.dispose();
    }
    _advanceOldItems
      ..clear()
      ..addAll(
        order.oldItemReturns.isEmpty
            ? [_AdvanceOldItemDraft()]
            : order.oldItemReturns
                  .map(
                    (item) => _AdvanceOldItemDraft(
                      date: item.date,
                      itemName: item.itemName,
                      returnRateText: item.returnRate.toString(),
                      grossWeightText: item.grossWeight.toString(),
                      lessWeightText: item.lessWeight.toString(),
                      tanchText: item.tanch.toString(),
                    ),
                  )
                  .toList(),
      );
    for (final item in _advanceOldItems) {
      _attachAdvanceOldItemListeners(item);
    }
  }

  bool _validateEstimateForm() {
    setState(() {
      _showEstimateNameError = true;
      _showEstimateMobileError = true;
      _showEstimateAlternateMobileError = true;
      for (final item in _estimateItems) {
        item.showNameError = true;
        item.showQuantityError = true;
        item.showWeightError = true;
      }
    });

    final hasTopLevelError =
        _estimateNameError != null ||
        _estimateMobileError != null ||
        _estimateAlternateMobileError != null;
    final hasItemError = _estimateItems.any(
      (item) =>
          !item.isEmpty &&
          (item.nameError != null ||
              item.quantityError != null ||
              item.weightError != null),
    );
    return !hasTopLevelError && !hasItemError;
  }

  void _saveEstimateOrder({bool stayOnEstimate = false}) {
    final populatedItems = _estimateItems
        .where((item) => !item.isEmpty)
        .toList();
    if (!_validateEstimateForm()) {
      return;
    }

    if (populatedItems.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Add at least one item')));
      return;
    }

    final order = Order(
      id:
          _editingOrderId ??
          'JW-${DateTime.now().millisecondsSinceEpoch % 100000}',
      customer: _estimateCustomerNameController.text.trim(),
      items: populatedItems
          .map(
            (item) => OrderItem(
              name: item.nameController.text.trim(),
              category: '',
              date: _estimateDate,
              quantity: item.quantity,
              bhav: 0,
              weight: item.estimatedWeight,
              making: 0,
              purity: item.purityController.text.trim(),
              estimatedWeight: item.estimatedWeight,
              grossWeight: item.grossWeight > 0 ? item.grossWeight : null,
              lessWeight: item.lessWeight > 0 ? item.lessWeight : null,
              netWeight: item.hasActualWeight ? item.actualNetWeight : null,
              size: item.sizeController.text.trim().isEmpty
                  ? null
                  : item.sizeController.text.trim(),
              length: item.lengthController.text.trim().isEmpty
                  ? null
                  : item.lengthController.text.trim(),
              notes: item.notesController.text.trim().isEmpty
                  ? null
                  : item.notesController.text.trim(),
            ),
          )
          .toList(),
      total: 0,
      status: _estimateStatus,
      createdAt: _editingOrderCreatedAt ?? DateTime.now(),
      advancePayments: _advancePaymentsForCurrentDraft,
      oldItemReturns: _advanceOldItemReturnsForCurrentDraft,
      customerPhone: _estimateCustomerMobileController.text.trim(),
      altCustomerPhone: _estimateAlternateMobileController.text.trim().isEmpty
          ? null
          : _estimateAlternateMobileController.text.trim(),
      estimatePurity: _estimatePurityController.text.trim(),
      estimateGst: _estimateGst,
      estimateMaking: _estimateMaking,
      estimateWeightRange: _estimateWeightRangeController.text.trim().isEmpty
          ? null
          : _estimateWeightRangeController.text.trim(),
      occasion: _estimateOccasionController.text.trim().isEmpty
          ? null
          : _estimateOccasionController.text.trim(),
      occasionDate: _estimateOccasionDate,
      deliveryDate: _estimateDeliveryDate,
    );

    final isEditing = _isEditingEstimate;
    setState(() {
      final existingIndex = _orders.indexWhere((item) => item.id == order.id);
      if (existingIndex == -1) {
        _orders.insert(0, order);
      } else {
        _orders[existingIndex] = order;
      }
      if (stayOnEstimate) {
        _editingOrderId = order.id;
        _editingOrderCreatedAt = order.createdAt;
      } else {
        _clearEstimateForm();
        _selectedSection = AppSection.orders;
        _selectedStatus = null;
      }
    });
    _schedulePersistence();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          stayOnEstimate
              ? (isEditing ? 'Order updated' : 'Order saved')
              : (isEditing ? 'Order updated' : 'Order created'),
        ),
      ),
    );
  }

  Future<void> _confirmDeleteOrder(Order order) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete order?'),
          content: Text('Remove ${order.customer} from your orders list?'),
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
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) {
      return;
    }

    final previousIndex = _orders.indexWhere((item) => item.id == order.id);
    final wasEditingOrder = _editingOrderId == order.id;

    setState(() {
      _orders.removeWhere((item) => item.id == order.id);
      if (wasEditingOrder) {
        _clearEstimateForm();
        _selectedSection = AppSection.orders;
        _selectedStatus = null;
      }
    });
    _schedulePersistence();

    if (!mounted) {
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    var wasUndone = false;
    final controller = messenger.showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 3),
        content: const Text('Order deleted'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            wasUndone = true;
            if (!mounted) {
              return;
            }
            setState(() {
              final insertIndex =
                  previousIndex >= 0 && previousIndex <= _orders.length
                  ? previousIndex
                  : _orders.length;
              _orders.insert(insertIndex, order);
            });
            _schedulePersistence();
          },
        ),
      ),
    );

    await controller.closed;
    if (!mounted || wasUndone || !wasEditingOrder) {
      return;
    }

    setState(() {
      _selectedSection = AppSection.orders;
      _selectedStatus = null;
    });
    _schedulePersistence();
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

  void _openAdvancePrintPreview() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) {
          return _AdvancePrintPreviewSheet(
            items: _populatedAdvanceItems,
            oldItems: _populatedAdvanceOldItems,
            totalAmount: _advanceTotalAmount,
          );
        },
      ),
    );
  }

  bool _stepBackOrdersTab() {
    return false;
  }

  void _resetEstimateForm() {
    setState(() {
      _clearEstimateForm();
    });
    _schedulePersistence();
  }

  void _resetAdvanceForm() {
    setState(() {
      for (final item in _advanceItems) {
        item.dispose();
      }
      _advanceItems
        ..clear()
        ..add(_AdvanceValuationDraft());
      _attachAdvanceItemListeners(_advanceItems.first);

      for (final item in _advanceOldItems) {
        item.dispose();
      }
      _advanceOldItems
        ..clear()
        ..add(_AdvanceOldItemDraft());
      _attachAdvanceOldItemListeners(_advanceOldItems.first);
    });
    _schedulePersistence();
  }

  Future<void> _saveAdvanceEntries() async {
    final currentOrderId = _editingOrderId;
    if (currentOrderId != null) {
      setState(() {
        final orderIndex = _orders.indexWhere(
          (order) => order.id == currentOrderId,
        );
        if (orderIndex != -1) {
          final existingOrder = _orders[orderIndex];
          _orders[orderIndex] = Order(
            id: existingOrder.id,
            customer: existingOrder.customer,
            items: existingOrder.items,
            total: existingOrder.total,
            status: existingOrder.status,
            createdAt: existingOrder.createdAt,
            advancePayments: _advancePaymentsForCurrentDraft,
            oldItemReturns: _advanceOldItemReturnsForCurrentDraft,
            customerPhone: existingOrder.customerPhone,
            altCustomerPhone: existingOrder.altCustomerPhone,
            customerPhotoPath: existingOrder.customerPhotoPath,
            estimatePurity: existingOrder.estimatePurity,
            estimateGst: existingOrder.estimateGst,
            estimateMaking: existingOrder.estimateMaking,
            estimateWeightRange: existingOrder.estimateWeightRange,
            occasion: existingOrder.occasion,
            occasionDate: existingOrder.occasionDate,
            deliveryDate: existingOrder.deliveryDate,
          );
        }
      });
    }
    _persistDebounceTimer?.cancel();
    await _persistLocalState();
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          currentOrderId == null
              ? 'Advance entries saved'
              : 'Advance entries saved for current customer',
        ),
      ),
    );
  }

  Future<bool> _confirmExitApp() async {
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

  Widget _buildOrdersBody(double contentTopPadding) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(16, contentTopPadding, 16, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      labelText: 'Name / Mobile',
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
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 3,
                  child: DropdownButtonFormField<OrderSortOption>(
                    initialValue: _selectedOrderSort,
                    decoration: const InputDecoration(
                      labelText: 'Sort',
                      isDense: true,
                    ),
                    isExpanded: true,
                    selectedItemBuilder: (context) {
                      return OrderSortOption.values
                          .map(
                            (option) => Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Sort',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList();
                    },
                    items: OrderSortOption.values
                        .map(
                          (option) => DropdownMenuItem(
                            value: option,
                            child: Text(
                              option.label,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }
                      setState(() {
                        _selectedOrderSort = value;
                      });
                      _schedulePersistence();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text('Live orders', style: Theme.of(context).textTheme.titleMedium),
            if (_filteredOrders.isNotEmpty) ...[
              const SizedBox(height: 12),
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
                    onEdit: () => _openEditOrderSheet(order),
                    onDelete: () => _confirmDeleteOrder(order),
                  );
                },
              ),
            ],
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
                        const SizedBox(width: 12),
                        Expanded(
                          child: _DateField(
                            date: _estimateDeliveryDate,
                            labelText: 'Delivery Date',
                            onDateSelected: (selected) {
                              setState(() {
                                _estimateDeliveryDate = selected;
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
            TextField(
              controller: _estimateWeightRangeController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              decoration: InputDecoration(
                labelText: 'Estimated Weight Range',
                hintText: 'Add extra weight, e.g. 2.080',
                suffixText: 'gm',
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
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
                                _EstimateTableCell('S No.', isHeader: true),
                                _EstimateTableCell('Purity', isHeader: true),
                                _EstimateTableCell('Item Name', isHeader: true),
                                _EstimateTableCell('Qty', isHeader: true),
                                _EstimateTableCell(
                                  'Est. Weight',
                                  isHeader: true,
                                  textAlign: TextAlign.right,
                                ),
                                _EstimateTableCell('Notes', isHeader: true),
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
                                    _formatWeight3(entry.value.estimatedWeight),
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
                                  _formatWeight3(_estimateTotalEstimatedWeight),
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
                    if (_estimateCategoryWeightEntries.isNotEmpty) ...[
                      Text(
                        'Estimated Weight By Category',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          for (final category in const [
                            '22K',
                            '18K',
                            'Silver',
                          ]) ...[
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.primary.withAlpha(10),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary.withAlpha(28),
                                  ),
                                ),
                                child: Text(
                                  '$category: ${_formatWeight3(_estimateCategoryWeightFor(category))} gm',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(fontWeight: FontWeight.w600),
                                ),
                              ),
                            ),
                            if (category != 'Silver') const SizedBox(width: 8),
                          ],
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],
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
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _saveEstimateOrder,
                    icon: const Icon(Icons.save_outlined),
                    label: Text(
                      _isEditingEstimate ? 'Update Order' : 'Save Order',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
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
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActualBody(double contentTopPadding) {
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
                        const SizedBox(width: 12),
                        Expanded(
                          child: _DateField(
                            date: _estimateDeliveryDate,
                            labelText: 'Delivery Date',
                            onDateSelected: (selected) {
                              setState(() {
                                _estimateDeliveryDate = selected;
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
            Text(
              'Actual Items',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              'Enter gross and less weight for each item. Nett weight is calculated automatically.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            ...List.generate(_estimateItems.length, (index) {
              final item = _estimateItems[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _ActualItemEditor(
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
                                _EstimateTableCell('S No.', isHeader: true),
                                _EstimateTableCell('Purity', isHeader: true),
                                _EstimateTableCell('Item Name', isHeader: true),
                                _EstimateTableCell('Qty', isHeader: true),
                                _EstimateTableCell(
                                  'Gross',
                                  isHeader: true,
                                  textAlign: TextAlign.right,
                                ),
                                _EstimateTableCell(
                                  'Less',
                                  isHeader: true,
                                  textAlign: TextAlign.right,
                                ),
                                _EstimateTableCell(
                                  'Nett',
                                  isHeader: true,
                                  textAlign: TextAlign.right,
                                ),
                                _EstimateTableCell('Notes', isHeader: true),
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
                                    _formatWeight3(entry.value.grossWeight),
                                    textAlign: TextAlign.right,
                                  ),
                                  _EstimateTableCell(
                                    _formatWeight3(entry.value.lessWeight),
                                    textAlign: TextAlign.right,
                                  ),
                                  _EstimateTableCell(
                                    _formatWeight3(entry.value.actualNetWeight),
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
                                  _formatWeight3(_actualTotalGrossWeight),
                                  isHeader: true,
                                  textAlign: TextAlign.right,
                                ),
                                _EstimateTableCell(
                                  _formatWeight3(_actualTotalLessWeight),
                                  isHeader: true,
                                  textAlign: TextAlign.right,
                                ),
                                _EstimateTableCell(
                                  _formatWeight3(_actualTotalNetWeight),
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
                        label: 'Actual Nett Weight',
                        value: '${_formatWeight3(_actualTotalNetWeight)} gm',
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
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _saveEstimateOrder(stayOnEstimate: true),
                    icon: const Icon(Icons.save_outlined),
                    label: Text(
                      _isEditingEstimate ? 'Update Order' : 'Save Order',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
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
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdvanceBody(double contentTopPadding) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(16, contentTopPadding, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Advance Entries',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              'Customer: $_estimateCustomerName',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            ...List.generate(_advanceItems.length, (index) {
              final item = _advanceItems[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _AdvanceValuationEditor(
                  index: index + 1,
                  item: item,
                  onChanged: () {
                    setState(() {});
                    _schedulePersistence();
                  },
                  onRemove: _advanceItems.length == 1
                      ? null
                      : () {
                          setState(() {
                            final removed = _advanceItems.removeAt(index);
                            removed.dispose();
                          });
                          _schedulePersistence();
                        },
                ),
              );
            }),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () {
                  setState(() {
                    final item = _AdvanceValuationDraft();
                    _advanceItems.add(item);
                    _attachAdvanceItemListeners(item);
                  });
                  _schedulePersistence();
                },
                icon: const Icon(Icons.add),
                label: const Text('Add advance item'),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Old Items',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            ...List.generate(_advanceOldItems.length, (index) {
              final item = _advanceOldItems[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _AdvanceOldItemEditor(
                  index: index + 1,
                  item: item,
                  onChanged: () {
                    setState(() {});
                    _schedulePersistence();
                  },
                  onRemove: _advanceOldItems.length == 1
                      ? null
                      : () {
                          setState(() {
                            final removed = _advanceOldItems.removeAt(index);
                            removed.dispose();
                          });
                          _schedulePersistence();
                        },
                ),
              );
            }),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () {
                  setState(() {
                    final item = _AdvanceOldItemDraft();
                    _advanceOldItems.add(item);
                    _attachAdvanceOldItemListeners(item);
                  });
                  _schedulePersistence();
                },
                icon: const Icon(Icons.add),
                label: const Text('Add old item'),
              ),
            ),
            const SizedBox(height: 12),
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
                    _EstimateSummaryRow(
                      label: 'Items',
                      value: _populatedAdvanceItems.length.toString(),
                    ),
                    const SizedBox(height: 10),
                    _EstimateSummaryRow(
                      label: 'Old Items',
                      value: _populatedAdvanceOldItems.length.toString(),
                    ),
                    const SizedBox(height: 10),
                    _EstimateSummaryRow(
                      label: 'Total Net Weight',
                      value: '${_formatWeight3(_advanceTotalNetWeight)} gm',
                    ),
                    const SizedBox(height: 10),
                    _EstimateSummaryRow(
                      label: 'Old Item Amount',
                      value: _formatCurrency(_advanceOldItemsTotalAmount),
                    ),
                    const SizedBox(height: 10),
                    _EstimateSummaryRow(
                      label: 'Total Amount',
                      value: _formatCurrency(
                        _advanceTotalAmount + _advanceOldItemsTotalAmount,
                      ),
                      emphasize: true,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _resetAdvanceForm,
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Theme.of(context).colorScheme.onError,
                minimumSize: const Size.fromHeight(48),
              ),
              icon: const Icon(Icons.restart_alt),
              label: const Text('Reset Advance'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemsBody(double contentTopPadding) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(16, contentTopPadding, 16, 32),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Items',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(
                  'This section is ready for item management next.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBillPreviewBody(double contentTopPadding) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(16, contentTopPadding, 16, 32),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bill Preview',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(
                  'This section is ready for bill preview work next.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
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
    _estimateWeightRangeController.dispose();
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
    for (final item in _advanceItems) {
      item.dispose();
    }
    for (final item in _advanceOldItems) {
      item.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final contentTopPadding = MediaQuery.of(context).padding.top + 16;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) {
          return;
        }
        final currentRoute = ModalRoute.of(context);
        if (currentRoute?.isCurrent != true) {
          return;
        }
        if (_selectedSection != AppSection.orders) {
          setState(() {
            _selectedSection = AppSection.orders;
            _selectedStatus = null;
          });
          _schedulePersistence();
          return;
        }
        if (_stepBackOrdersTab()) {
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
        appBar: AppBar(
          leading: _selectedSection != AppSection.orders
              ? IconButton(
                  onPressed: () {
                    setState(() {
                      _selectedSection = AppSection.orders;
                      _selectedStatus = null;
                    });
                    _schedulePersistence();
                  },
                  icon: const Icon(Icons.arrow_back),
                  tooltip: 'Back to orders',
                )
              : null,
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
              Text(switch (_selectedSection) {
                AppSection.orders => 'Orders',
                AppSection.estimateCalculator =>
                  (_isEditingEstimate ? 'Edit Order' : 'New Order'),
                AppSection.advance => 'Advance',
                AppSection.actual => 'Actual',
                AppSection.items => 'Items',
                AppSection.billPreview => 'Bill Preview',
              }),
            ],
          ),
          actions: [
            if (_selectedSection == AppSection.estimateCalculator)
              IconButton(
                onPressed: () => _saveEstimateOrder(stayOnEstimate: true),
                icon: const Icon(Icons.save_outlined),
                tooltip: _isEditingEstimate ? 'Update order' : 'Save order',
              ),
            if (_selectedSection == AppSection.actual)
              IconButton(
                onPressed: () => _saveEstimateOrder(stayOnEstimate: true),
                icon: const Icon(Icons.save_outlined),
                tooltip: _isEditingEstimate ? 'Update order' : 'Save order',
              ),
            if (_selectedSection == AppSection.advance)
              IconButton(
                onPressed: _saveAdvanceEntries,
                icon: const Icon(Icons.save_outlined),
                tooltip: 'Save advance entries',
              ),
            if (_selectedSection == AppSection.orders ||
                _selectedSection == AppSection.estimateCalculator ||
                _selectedSection == AppSection.advance)
              IconButton(
                onPressed: switch (_selectedSection) {
                  AppSection.orders => _openPrintPreview,
                  AppSection.estimateCalculator => _openEstimatePrintPreview,
                  AppSection.advance => _openAdvancePrintPreview,
                  _ => _openPrintPreview,
                },
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
        bottomNavigationBar: NavigationBar(
          selectedIndex: _selectedSection.index,
          onDestinationSelected: (index) {
            final nextSection = AppSection.values[index];
            if (_selectedSection == nextSection) {
              return;
            }
            setState(() {
              _selectedSection = nextSection;
              if (nextSection == AppSection.orders) {
                _selectedStatus = null;
              }
            });
            _schedulePersistence();
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined),
              label: 'Orders',
            ),
            NavigationDestination(
              icon: Icon(Icons.calculate_outlined),
              label: 'Estimate',
            ),
            NavigationDestination(
              icon: Icon(Icons.account_balance_wallet_outlined),
              label: 'Advance',
            ),
            NavigationDestination(
              icon: Icon(Icons.scale_outlined),
              label: 'Actual',
            ),
            NavigationDestination(
              icon: Icon(Icons.add_box_outlined),
              label: 'New Items',
            ),
            NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined),
              label: 'Bill Preview',
            ),
          ],
        ),
        body: switch (_selectedSection) {
          AppSection.orders => _buildOrdersBody(contentTopPadding),
          AppSection.estimateCalculator => _buildEstimateCalculatorBody(
            contentTopPadding,
          ),
          AppSection.advance => _buildAdvanceBody(contentTopPadding),
          AppSection.actual => _buildActualBody(contentTopPadding),
          AppSection.items => _buildItemsBody(contentTopPadding),
          AppSection.billPreview => _buildBillPreviewBody(contentTopPadding),
        },
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
    double? grossWeight,
    double? lessWeight,
    String? size,
    String? length,
    String? notes,
    String? quantityText,
    String? estimatedNettWeightText,
    String? grossWeightText,
    String? lessWeightText,
  }) : nameController = TextEditingController(text: name ?? ''),
       purityController = TextEditingController(text: purity ?? '22K'),
       quantityController = TextEditingController(
         text: quantityText ?? (quantity == null ? '1' : quantity.toString()),
       ),
       estimatedNettWeightController = TextEditingController(
         text:
             estimatedNettWeightText ?? (estimatedNettWeight?.toString() ?? ''),
       ),
       grossWeightController = TextEditingController(
         text: grossWeightText ?? (grossWeight?.toString() ?? ''),
       ),
       lessWeightController = TextEditingController(
         text: lessWeightText ?? (lessWeight?.toString() ?? ''),
       ),
       sizeController = TextEditingController(text: size ?? ''),
       lengthController = TextEditingController(text: length ?? ''),
       notesController = TextEditingController(text: notes ?? '');

  factory _EstimateItemDraft.fromJson(Map<String, dynamic> json) {
    return _EstimateItemDraft(
      name: json['name'] as String? ?? '',
      purity: json['purity'] as String? ?? '22K',
      quantityText: json['quantityText'] as String? ?? '1',
      estimatedNettWeightText: json['estimatedNettWeightText'] as String? ?? '',
      grossWeightText: json['grossWeightText'] as String? ?? '',
      lessWeightText: json['lessWeightText'] as String? ?? '',
      size: json['size'] as String? ?? '',
      length: json['length'] as String? ?? '',
      notes: json['notes'] as String? ?? '',
    );
  }

  final TextEditingController nameController;
  final TextEditingController purityController;
  final TextEditingController quantityController;
  final TextEditingController estimatedNettWeightController;
  final TextEditingController grossWeightController;
  final TextEditingController lessWeightController;
  final TextEditingController sizeController;
  final TextEditingController lengthController;
  final TextEditingController notesController;
  bool showNameError = false;
  bool showQuantityError = false;
  bool showWeightError = false;

  bool get isEmpty =>
      nameController.text.trim().isEmpty &&
      sizeController.text.trim().isEmpty &&
      lengthController.text.trim().isEmpty &&
      notesController.text.trim().isEmpty &&
      estimatedWeight == 0 &&
      grossWeight == 0 &&
      lessWeight == 0;

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
      'grossWeightText': grossWeightController.text,
      'lessWeightText': lessWeightController.text,
      'size': sizeController.text,
      'length': lengthController.text,
      'notes': notesController.text,
    };
  }

  int get quantity => int.tryParse(quantityController.text.trim()) ?? 0;

  double get estimatedWeight {
    return double.tryParse(estimatedNettWeightController.text.trim()) ?? 0;
  }

  double get grossWeight {
    return double.tryParse(grossWeightController.text.trim()) ?? 0;
  }

  double get lessWeight {
    return double.tryParse(lessWeightController.text.trim()) ?? 0;
  }

  double get actualNetWeight {
    final net = grossWeight - lessWeight;
    return net > 0 ? net : 0;
  }

  bool get hasActualWeight => grossWeight > 0 || lessWeight > 0;

  void dispose() {
    nameController.dispose();
    purityController.dispose();
    quantityController.dispose();
    estimatedNettWeightController.dispose();
    grossWeightController.dispose();
    lessWeightController.dispose();
    sizeController.dispose();
    lengthController.dispose();
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
                      inputFormatters: [_WordCapitalizeFormatter()],
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
                        labelText: 'Estimated Weight',
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

class _ActualItemEditor extends StatelessWidget {
  const _ActualItemEditor({
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
                      inputFormatters: [_WordCapitalizeFormatter()],
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
                        labelText: 'Estimated Weight',
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
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: item.grossWeightController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Gross Weight',
                      suffixText: 'g',
                    ),
                    onChanged: (_) => onChanged(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: item.lessWeightController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Less Weight',
                      suffixText: 'g',
                    ),
                    onChanged: (_) => onChanged(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Nett Weight',
                suffixText: 'g',
              ),
              child: Text(
                _formatWeight3(item.actualNetWeight),
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
              ),
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

class _AdvanceValuationDraft {
  _AdvanceValuationDraft({
    DateTime? date,
    AdvanceMode? mode,
    String? amountText,
    String? rateText,
    String? rateMakingText,
    String? chequeNumber,
  }) : _date = date ?? DateTime.now(),
       _mode = mode ?? AdvanceMode.cash,
       amountController = TextEditingController(text: amountText ?? ''),
       rateController = TextEditingController(text: rateText ?? ''),
       rateMakingController = TextEditingController(text: rateMakingText ?? ''),
       chequeNumberController = TextEditingController(text: chequeNumber ?? '');

  factory _AdvanceValuationDraft.fromJson(Map<String, dynamic> json) {
    final legacyWeightText = json['weightText'] as String? ?? '';
    final legacyRateText = json['rateText'] as String? ?? '';
    final legacyWeight = double.tryParse(legacyWeightText) ?? 0;
    final legacyRate = double.tryParse(legacyRateText) ?? 0;

    return _AdvanceValuationDraft(
      date: _dateTimeFromJson(json['date']) ?? DateTime.now(),
      mode: AdvanceMode.values.firstWhere(
        (value) =>
            value.name ==
            ((json['mode'] as String?) ?? (json['metal'] as String?) ?? ''),
        orElse: () => AdvanceMode.cash,
      ),
      amountText:
          json['amountText'] as String? ??
          (legacyWeight > 0 && legacyRate > 0
              ? (legacyWeight * legacyRate).toStringAsFixed(2)
              : ''),
      rateText: legacyRateText,
      rateMakingText: json['rateMakingText'] as String? ?? '',
      chequeNumber: json['chequeNumber'] as String? ?? '',
    );
  }

  DateTime? _date;
  AdvanceMode? _mode;
  final TextEditingController amountController;
  final TextEditingController rateController;
  final TextEditingController rateMakingController;
  final TextEditingController chequeNumberController;

  DateTime get date => _date ?? DateTime.now();

  set date(DateTime value) {
    _date = value;
  }

  AdvanceMode get mode => _mode ?? AdvanceMode.cash;

  set mode(AdvanceMode value) {
    _mode = value;
  }

  bool get isEmpty => amount == 0 && rate == 0 && rateMaking == 0;

  double get amount => double.tryParse(amountController.text.trim()) ?? 0;

  double get rate => double.tryParse(rateController.text.trim()) ?? 0;

  double get rateMaking =>
      double.tryParse(rateMakingController.text.trim()) ?? 0;

  String? get chequeNumber {
    final value = chequeNumberController.text.trim();
    return value.isEmpty ? null : value;
  }

  double get effectiveRate {
    return rate + ((rate * rateMaking) / 100);
  }

  double get weight {
    final denominator = effectiveRate;
    if (denominator <= 0) {
      return 0;
    }
    return amount / denominator;
  }

  AdvanceValuationLine get line => AdvanceValuationLine(
    date: date,
    mode: mode,
    amount: amount,
    rate: rate,
    rateMaking: rateMaking,
    chequeNumber: chequeNumber,
  );

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'mode': mode.name,
      'amountText': amountController.text,
      'rateText': rateController.text,
      'rateMakingText': rateMakingController.text,
      'chequeNumber': chequeNumberController.text,
    };
  }

  void dispose() {
    amountController.dispose();
    rateController.dispose();
    rateMakingController.dispose();
    chequeNumberController.dispose();
  }
}

class _AdvanceValuationEditor extends StatelessWidget {
  const _AdvanceValuationEditor({
    required this.index,
    required this.item,
    required this.onChanged,
    this.onRemove,
  });

  final int index;
  final _AdvanceValuationDraft item;
  final VoidCallback onChanged;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Advance Item $index',
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
              children: [
                Expanded(
                  child: _DateField(
                    date: item.date,
                    labelText: 'Date',
                    onDateSelected: (selected) {
                      item.date = selected;
                      onChanged();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<AdvanceMode>(
                    initialValue: item.mode,
                    decoration: const InputDecoration(labelText: 'Mode'),
                    items: AdvanceMode.values
                        .map(
                          (mode) => DropdownMenuItem(
                            value: mode,
                            child: Text(mode.label),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      item.mode = value ?? AdvanceMode.cash;
                      onChanged();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (item.mode == AdvanceMode.banking) ...[
              TextField(
                controller: item.chequeNumberController,
                keyboardType: TextInputType.text,
                decoration: const InputDecoration(labelText: 'Cheque Number'),
                onChanged: (_) => onChanged(),
              ),
              const SizedBox(height: 12),
            ],
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: item.amountController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                    ],
                    decoration: const InputDecoration(labelText: 'Amount'),
                    onChanged: (_) => onChanged(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: item.rateController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                    ],
                    decoration: const InputDecoration(labelText: 'Rate22kt'),
                    onChanged: (_) => onChanged(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: item.rateMakingController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Making%',
                      suffixText: '%',
                    ),
                    onChanged: (_) => onChanged(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Net Weight',
                      suffixText: 'gm',
                    ),
                    child: Text(
                      _formatWeight3(item.weight),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AdvanceOldItemDraft {
  _AdvanceOldItemDraft({
    DateTime? date,
    String? itemName,
    String? returnRateText,
    String? grossWeightText,
    String? lessWeightText,
    String? tanchText,
  }) : _date = date ?? DateTime.now(),
       itemNameController = TextEditingController(text: itemName ?? ''),
       returnRateController = TextEditingController(text: returnRateText ?? ''),
       grossWeightController = TextEditingController(
         text: grossWeightText ?? '',
       ),
       lessWeightController = TextEditingController(text: lessWeightText ?? ''),
       tanchController = TextEditingController(text: tanchText ?? '');

  factory _AdvanceOldItemDraft.fromJson(Map<String, dynamic> json) {
    return _AdvanceOldItemDraft(
      date: _dateTimeFromJson(json['date']) ?? DateTime.now(),
      itemName: json['itemName'] as String? ?? '',
      returnRateText: json['returnRateText'] as String? ?? '',
      grossWeightText: json['grossWeightText'] as String? ?? '',
      lessWeightText: json['lessWeightText'] as String? ?? '',
      tanchText: json['tanchText'] as String? ?? '',
    );
  }

  DateTime? _date;
  final TextEditingController itemNameController;
  final TextEditingController returnRateController;
  final TextEditingController grossWeightController;
  final TextEditingController lessWeightController;
  final TextEditingController tanchController;

  DateTime get date => _date ?? DateTime.now();

  set date(DateTime value) {
    _date = value;
  }

  double get returnRate =>
      double.tryParse(returnRateController.text.trim()) ?? 0;

  double get grossWeight =>
      double.tryParse(grossWeightController.text.trim()) ?? 0;

  double get lessWeight =>
      double.tryParse(lessWeightController.text.trim()) ?? 0;

  double get nettWeight {
    final value = grossWeight - lessWeight;
    return value > 0 ? value : 0;
  }

  double get tanch => double.tryParse(tanchController.text.trim()) ?? 0;

  double get amount => nettWeight * tanch * returnRate;

  bool get isEmpty =>
      itemNameController.text.trim().isEmpty &&
      returnRate == 0 &&
      grossWeight == 0 &&
      lessWeight == 0 &&
      tanch == 0;

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'itemName': itemNameController.text,
      'returnRateText': returnRateController.text,
      'grossWeightText': grossWeightController.text,
      'lessWeightText': lessWeightController.text,
      'tanchText': tanchController.text,
    };
  }

  void dispose() {
    itemNameController.dispose();
    returnRateController.dispose();
    grossWeightController.dispose();
    lessWeightController.dispose();
    tanchController.dispose();
  }
}

class _AdvanceOldItemEditor extends StatelessWidget {
  const _AdvanceOldItemEditor({
    required this.index,
    required this.item,
    required this.onChanged,
    this.onRemove,
  });

  final int index;
  final _AdvanceOldItemDraft item;
  final VoidCallback onChanged;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final decimalInput = [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Old Item $index',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (onRemove != null)
                  IconButton(
                    onPressed: onRemove,
                    icon: const Icon(Icons.delete_outline),
                    tooltip: 'Remove old item',
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _DateField(
                    date: item.date,
                    labelText: 'Date',
                    onDateSelected: (selected) {
                      item.date = selected;
                      onChanged();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: item.itemNameController,
              inputFormatters: [_WordCapitalizeFormatter()],
              decoration: const InputDecoration(labelText: 'Item Name'),
              onChanged: (_) => onChanged(),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: item.returnRateController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: decimalInput,
                    decoration: const InputDecoration(labelText: 'ReturnRate'),
                    onChanged: (_) => onChanged(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InputDecorator(
                    decoration: const InputDecoration(labelText: 'Amount'),
                    child: Text(_formatCurrency(item.amount)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: item.grossWeightController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: decimalInput,
                    decoration: const InputDecoration(
                      labelText: 'Gross',
                      suffixText: 'gm',
                    ),
                    onChanged: (_) => onChanged(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: item.lessWeightController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: decimalInput,
                    decoration: const InputDecoration(
                      labelText: 'Less',
                      suffixText: 'gm',
                    ),
                    onChanged: (_) => onChanged(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Nett',
                      suffixText: 'gm',
                    ),
                    child: Text(_formatWeight3(item.nettWeight)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: item.tanchController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: decimalInput,
                    decoration: const InputDecoration(
                      labelText: 'Tanch',
                      suffixText: '%',
                    ),
                    onChanged: (_) => onChanged(),
                  ),
                ),
              ],
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
        maxLines: isHeader ? 2 : 1,
        softWrap: isHeader,
        overflow: TextOverflow.visible,
      ),
    );
  }
}
