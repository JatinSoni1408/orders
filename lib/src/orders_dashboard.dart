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
  static const List<String> _newItemCategoryOptions = [
    'Gold22kt',
    'Gold18kt',
    'Silver',
  ];
  static const List<String> _goldMakingTypeOptions = [
    'FixRate',
    'Percentage',
    'TotalMaking',
  ];
  static const List<String> _silverMakingTypeOptions = [
    'PerGram',
    'TotalMaking',
    'FixRate',
  ];
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
  final TextEditingController _newItemsGold22RateController =
      TextEditingController();
  final TextEditingController _newItemsGold18RateController =
      TextEditingController();
  final TextEditingController _newItemsSilverRateController =
      TextEditingController();
  final FocusNode _estimateCustomerNameFocusNode = FocusNode();
  final FocusNode _estimateCustomerMobileFocusNode = FocusNode();
  final FocusNode _estimateAlternateMobileFocusNode = FocusNode();
  final List<_EstimateItemDraft> _estimateItems = [_EstimateItemDraft()];
  final List<_AdvanceValuationDraft> _advanceItems = [_AdvanceValuationDraft()];
  final List<_AdvanceOldItemDraft> _advanceOldItems = [_AdvanceOldItemDraft()];
  final List<_NewItemDraft> _newItems = [_NewItemDraft()];
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
    _attachNewItemFieldListeners();
    for (final item in _newItems) {
      _attachNewItemListeners(item);
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

  List<_NewItemDraft> get _populatedNewItems {
    return _newItems.where((item) => !item.isEmpty).toList();
  }

  List<String> _makingTypeOptionsFor(String category) {
    if (category == 'Silver') {
      return _silverMakingTypeOptions;
    }
    return _goldMakingTypeOptions;
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

  double _parseNewItemText(String value) {
    final cleaned = value.replaceAll(',', '').replaceAll('%', '').trim();
    return double.tryParse(cleaned) ?? 0;
  }

  double _newItemRateForCategory(String category) {
    switch (category) {
      case 'Gold22kt':
        return _parseNewItemText(_newItemsGold22RateController.text);
      case 'Gold18kt':
        return _parseNewItemText(_newItemsGold18RateController.text);
      case 'Silver':
        return _parseNewItemText(_newItemsSilverRateController.text);
      default:
        return 0;
    }
  }

  double _newItemBhav(_NewItemDraft item) {
    return item.bhav > 0 ? item.bhav : _newItemRateForCategory(item.category);
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
    return _newItemBaseAmount(item) * (_estimateGst / 100);
  }

  double _newItemTotalAmount(_NewItemDraft item) {
    final total =
        _newItemBaseAmount(item) +
        _newItemGstAmount(item) +
        item.additionalCharge;
    return total > 0 ? total : 0;
  }

  double get _newItemsSubtotal {
    return _populatedNewItems.fold<double>(
      0,
      (sum, item) => sum + _newItemBaseAmount(item) + item.additionalCharge,
    );
  }

  double get _newItemsTotalGst {
    return _populatedNewItems.fold<double>(
      0,
      (sum, item) => sum + _newItemGstAmount(item),
    );
  }

  double get _newItemsGrandTotal {
    return _populatedNewItems.fold<double>(
      0,
      (sum, item) => sum + _newItemTotalAmount(item),
    );
  }

  List<MapEntry<String, double>> get _newItemsCategoryTotalEntries {
    final totals = <String, double>{};
    for (final item in _populatedNewItems) {
      final label = _newItemCategoryLabel(item.category);
      totals.update(
        label,
        (value) => value + _newItemTotalAmount(item),
        ifAbsent: () => _newItemTotalAmount(item),
      );
    }
    final entries = totals.entries.toList();
    entries.sort((a, b) => a.key.compareTo(b.key));
    return entries;
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

  void _attachNewItemFieldListeners() {
    for (final controller in [
      _newItemsGold22RateController,
      _newItemsGold18RateController,
      _newItemsSilverRateController,
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

  void _attachNewItemListeners(_NewItemDraft item) {
    for (final controller in [
      item.nameController,
      item.categoryController,
      item.bhavController,
      item.makingTypeController,
      item.makingChargeController,
      item.grossWeightController,
      item.lessWeightController,
      item.additionalChargeController,
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
        'newItemsGold22Rate': _newItemsGold22RateController.text,
        'newItemsGold18Rate': _newItemsGold18RateController.text,
        'newItemsSilverRate': _newItemsSilverRateController.text,
        'newItems': _newItems.map((item) => item.toJson()).toList(),
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
          final restoredNewItems =
              (decodedEstimate['newItems'] as List<dynamic>? ?? const [])
                  .map(
                    (item) =>
                        _NewItemDraft.fromJson(item as Map<String, dynamic>),
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
          _newItemsGold22RateController.text =
              decodedEstimate['newItemsGold22Rate'] as String? ?? '';
          _newItemsGold18RateController.text =
              decodedEstimate['newItemsGold18Rate'] as String? ?? '';
          _newItemsSilverRateController.text =
              decodedEstimate['newItemsSilverRate'] as String? ?? '';
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

          for (final item in _newItems) {
            item.dispose();
          }
          _newItems
            ..clear()
            ..addAll(
              restoredNewItems.isEmpty ? [_NewItemDraft()] : restoredNewItems,
            );

          for (final item in _newItems) {
            _attachNewItemListeners(item);
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

    for (final item in _newItems) {
      item.dispose();
    }
    _newItems
      ..clear()
      ..add(_NewItemDraft());
    _attachNewItemListeners(_newItems.first);
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

    for (final item in _newItems) {
      item.dispose();
    }
    _newItems
      ..clear()
      ..addAll(
        order.newItems.isEmpty
            ? [_NewItemDraft()]
            : order.newItems
                  .map(
                    (item) => _NewItemDraft(
                      name: item.name,
                      category: item.category,
                      bhavText: item.bhav > 0 ? item.bhav.toString() : '',
                      makingType: item.makingType,
                      makingChargeText: item.makingCharge.toString(),
                      grossWeightText: item.grossWeight.toString(),
                      lessWeightText: item.lessWeight.toString(),
                      additionalChargeText: item.additionalCharge.toString(),
                      gstEnabled: item.gstEnabled,
                      notes: item.notes ?? '',
                    ),
                  )
                  .toList(),
      );
    for (final item in _newItems) {
      _attachNewItemListeners(item);
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
      total: _newItemsGrandTotal,
      status: _estimateStatus,
      createdAt: _editingOrderCreatedAt ?? DateTime.now(),
      advancePayments: _advancePaymentsForCurrentDraft,
      oldItemReturns: _advanceOldItemReturnsForCurrentDraft,
      newItems: _populatedNewItems
          .map(
            (item) => NewOrderItem(
              name: item.nameController.text.trim(),
              category: item.category,
              bhav: item.bhav,
              makingType: item.makingType,
              makingCharge: item.makingCharge,
              grossWeight: item.grossWeight,
              lessWeight: item.lessWeight,
              additionalCharge: item.additionalCharge,
              gstEnabled: item.gstEnabled,
              notes: item.notesController.text.trim().isEmpty
                  ? null
                  : item.notesController.text.trim(),
            ),
          )
          .toList(),
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

  void _openActualPrintPreview() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) {
          return _ActualPrintPreviewSheet(
            customerName: _estimateCustomerName,
            customerMobile: _estimateCustomerMobile,
            alternateMobile: _estimateAlternateMobile,
            statusLabel: _estimateStatus.label,
            deliveryDate: _estimateDeliveryDateLabel,
            purity: _estimatePurity,
            making: _estimateMaking.toStringAsFixed(2),
            gst: '${_estimateGst.toStringAsFixed(2)}%',
            totalQuantity: _estimateTotalQuantity.toString(),
            totalGrossWeight: _formatWeightFixed3(_actualTotalGrossWeight),
            totalLessWeight: _formatWeightFixed3(_actualTotalLessWeight),
            totalNetWeight: _formatWeightFixed3(_actualTotalNetWeight),
            items: _sortedEstimateItems,
          );
        },
      ),
    );
  }

  void _openNewItemsPrintPreview() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) {
          return _NewItemsPrintPreviewSheet(
            customerName: _estimateCustomerName,
            customerMobile: _estimateCustomerMobile,
            alternateMobile: _estimateAlternateMobile,
            deliveryDate: _estimateDeliveryDateLabel,
            gstRate: _estimateGst,
            gold22Rate: _newItemRateForCategory('Gold22kt'),
            gold18Rate: _newItemRateForCategory('Gold18kt'),
            silverRate: _newItemRateForCategory('Silver'),
            subtotal: _newItemsSubtotal,
            totalGst: _newItemsTotalGst,
            grandTotal: _newItemsGrandTotal,
            items: _populatedNewItems,
          );
        },
      ),
    );
  }

  _CombinedBillPrintPreviewSheet _buildCombinedBillPrintPreviewSheet() {
    return _CombinedBillPrintPreviewSheet(
      customerName: _estimateCustomerName,
      customerMobile: _estimateCustomerMobile,
      alternateMobile: _estimateAlternateMobile,
      statusLabel: _estimateStatus.label,
      occasion: _estimateOccasion,
      occasionDate: _estimateOccasionDateLabel,
      deliveryDate: _estimateDeliveryDateLabel,
      purity: _estimatePurity,
      making: _estimateMaking.toStringAsFixed(2),
      gstRate: _estimateGst,
      estimateTotalQuantity: _estimateTotalQuantity.toString(),
      estimateWeightRange: _estimateWeightRangeLabel,
      actualTotalGrossWeight: _formatWeightFixed3(_actualTotalGrossWeight),
      actualTotalLessWeight: _formatWeightFixed3(_actualTotalLessWeight),
      actualTotalNetWeight: _formatWeightFixed3(_actualTotalNetWeight),
      advanceTotalAmount: _advanceTotalAmount,
      advanceOldItemsTotalAmount: _advanceOldItemsTotalAmount,
      advanceNetWeight: _advanceTotalNetWeight,
      newItemsSubtotal: _newItemsSubtotal,
      newItemsTotalGst: _newItemsTotalGst,
      newItemsGrandTotal: _newItemsGrandTotal,
      balanceAfterAdvance: _billPreviewBalanceAfterAdvance,
      gold22Rate: _newItemRateForCategory('Gold22kt'),
      gold18Rate: _newItemRateForCategory('Gold18kt'),
      silverRate: _newItemRateForCategory('Silver'),
      estimateItems: _sortedEstimateItems,
      advanceItems: _populatedAdvanceItems,
      oldItems: _populatedAdvanceOldItems,
      newItems: _populatedNewItems,
    );
  }

  void _openCombinedBillPrintPreview() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) {
          return _buildCombinedBillPrintPreviewSheet();
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
            newItems: existingOrder.newItems,
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
                                _EstimateTableCell(
                                  'Serial No.',
                                  isHeader: true,
                                ),
                                _EstimateTableCell('Purity', isHeader: true),
                                _EstimateTableCell('Item Name', isHeader: true),
                                _EstimateTableCell('Quantity', isHeader: true),
                                _EstimateTableCell(
                                  'Gross Weight',
                                  isHeader: true,
                                  textAlign: TextAlign.right,
                                ),
                                _EstimateTableCell(
                                  'Less Weight',
                                  isHeader: true,
                                  textAlign: TextAlign.right,
                                ),
                                _EstimateTableCell(
                                  'Nett Weight',
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
                                    _formatWeightFixed3(
                                      entry.value.grossWeight,
                                    ),
                                    textAlign: TextAlign.right,
                                  ),
                                  _EstimateTableCell(
                                    _formatWeight3(entry.value.lessWeight),
                                    textAlign: TextAlign.right,
                                  ),
                                  _EstimateTableCell(
                                    _formatWeightFixed3(
                                      entry.value.actualNetWeight,
                                    ),
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
                                  _formatWeightFixed3(_actualTotalGrossWeight),
                                  isHeader: true,
                                  textAlign: TextAlign.right,
                                ),
                                _EstimateTableCell(
                                  _formatWeight3(_actualTotalLessWeight),
                                  isHeader: true,
                                  textAlign: TextAlign.right,
                                ),
                                _EstimateTableCell(
                                  _formatWeightFixed3(_actualTotalNetWeight),
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
                        value:
                            '${_formatWeightFixed3(_actualTotalNetWeight)} gm',
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
    final rateInputFormatters = [
      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
    ];
    final populatedNewItems = _populatedNewItems;

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(16, contentTopPadding, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'New Items',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Add manually priced items here. Shared rates stay available, and each item can also carry its own manual Bhav.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _newItemsGold22RateController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            inputFormatters: rateInputFormatters,
                            decoration: const InputDecoration(
                              labelText: '22K Rate',
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _newItemsGold18RateController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            inputFormatters: rateInputFormatters,
                            decoration: const InputDecoration(
                              labelText: '18K Rate',
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _newItemsSilverRateController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            inputFormatters: rateInputFormatters,
                            decoration: const InputDecoration(
                              labelText: 'Silver Rate',
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withAlpha(10),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withAlpha(28),
                        ),
                      ),
                      child: Text(
                        'GST is using the same rate as Estimate: ${_estimateGst.toStringAsFixed(2)}%',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Priced Items',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              'Enter gross and less weight for each piece. Nett weight and line amount are calculated automatically, and item Bhav overrides the shared rate when entered.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            ...List.generate(_newItems.length, (index) {
              final item = _newItems[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _NewItemEditor(
                  index: index + 1,
                  item: item,
                  effectiveBhav: _newItemBhav(item),
                  amount: _newItemTotalAmount(item),
                  baseAmount: _newItemBaseAmount(item),
                  gstAmount: _newItemGstAmount(item),
                  makingTypeOptions: _makingTypeOptionsFor(item.category),
                  onChanged: () {
                    setState(() {});
                    _schedulePersistence();
                  },
                  onCategoryChanged: (value) {
                    final options = _makingTypeOptionsFor(value);
                    item.categoryController.text = value;
                    if (!options.contains(item.makingType)) {
                      item.makingTypeController.text = options.first;
                    }
                    setState(() {});
                    _schedulePersistence();
                  },
                  onMakingTypeChanged: (value) {
                    item.makingTypeController.text = value;
                    setState(() {});
                    _schedulePersistence();
                  },
                  onRemove: _newItems.length == 1
                      ? null
                      : () {
                          setState(() {
                            final removed = _newItems.removeAt(index);
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
                    final item = _NewItemDraft();
                    _newItems.add(item);
                    _attachNewItemListeners(item);
                  });
                  _schedulePersistence();
                },
                icon: const Icon(Icons.add),
                label: const Text('Add new item'),
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
                      'New Items Summary',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _EstimateSummaryRow(
                      label: 'Items',
                      value: populatedNewItems.length.toString(),
                    ),
                    const SizedBox(height: 8),
                    _EstimateSummaryRow(
                      label: 'Base + Extras',
                      value: _formatCurrency(_newItemsSubtotal),
                    ),
                    const SizedBox(height: 8),
                    _EstimateSummaryRow(
                      label: 'GST',
                      value: _formatCurrency(_newItemsTotalGst),
                    ),
                    const SizedBox(height: 8),
                    _EstimateSummaryRow(
                      label: 'Grand Total',
                      value: _formatCurrency(_newItemsGrandTotal),
                      emphasize: true,
                    ),
                    if (_newItemsCategoryTotalEntries.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        'By Category',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _newItemsCategoryTotalEntries
                            .map(
                              (entry) => Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      entry.key,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: Colors.grey.shade700,
                                          ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _formatCurrency(entry.value),
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  double get _advanceCombinedAmount {
    return _advanceTotalAmount + _advanceOldItemsTotalAmount;
  }

  double get _billPreviewBalanceAfterAdvance {
    return _newItemsGrandTotal - _advanceCombinedAmount;
  }

  Widget _buildBillPreviewBody(double contentTopPadding) {
    final combinedPreview = _buildCombinedBillPrintPreviewSheet();

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, contentTopPadding, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bill PDF Preview',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'The Bill Preview tab now renders the same live PDF preview used in the print screen for the current draft.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton.icon(
                        onPressed: () {
                          Printing.layoutPdf(
                            onLayout: combinedPreview._buildCombinedBillPdf,
                          );
                        },
                        icon: const Icon(Icons.print_outlined),
                        label: const Text('Print'),
                      ),
                    ),
                  ],
                ),
              ),
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
                  build: combinedPreview._buildCombinedBillPdf,
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
    _estimateWeightRangeController.dispose();
    _estimateCustomerNameController.dispose();
    _estimateCustomerMobileController.dispose();
    _estimateAlternateMobileController.dispose();
    _estimateOccasionController.dispose();
    _newItemsGold22RateController.dispose();
    _newItemsGold18RateController.dispose();
    _newItemsSilverRateController.dispose();
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
    for (final item in _newItems) {
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
            if (_selectedSection == AppSection.items)
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
                _selectedSection == AppSection.advance ||
                _selectedSection == AppSection.actual ||
                _selectedSection == AppSection.items)
              IconButton(
                onPressed: switch (_selectedSection) {
                  AppSection.orders => _openPrintPreview,
                  AppSection.estimateCalculator => _openEstimatePrintPreview,
                  AppSection.advance => _openAdvancePrintPreview,
                  AppSection.actual => _openActualPrintPreview,
                  AppSection.items => _openNewItemsPrintPreview,
                  AppSection.billPreview => _openCombinedBillPrintPreview,
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
                _formatWeightFixed3(item.actualNetWeight),
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

class _NewItemDraft {
  _NewItemDraft({
    String? name,
    String? category,
    String? bhavText,
    String? makingType,
    String? makingChargeText,
    String? grossWeightText,
    String? lessWeightText,
    String? additionalChargeText,
    this.gstEnabled = true,
    String? notes,
  }) : nameController = TextEditingController(text: name ?? ''),
       categoryController = TextEditingController(text: category ?? 'Gold22kt'),
       bhavController = TextEditingController(text: bhavText ?? ''),
       makingTypeController = TextEditingController(
         text:
             makingType ??
             ((category ?? 'Gold22kt') == 'Silver' ? 'PerGram' : 'FixRate'),
       ),
       makingChargeController = TextEditingController(
         text: makingChargeText ?? '',
       ),
       grossWeightController = TextEditingController(
         text: grossWeightText ?? '',
       ),
       lessWeightController = TextEditingController(text: lessWeightText ?? ''),
       additionalChargeController = TextEditingController(
         text: additionalChargeText ?? '',
       ),
       notesController = TextEditingController(text: notes ?? '');

  factory _NewItemDraft.fromJson(Map<String, dynamic> json) {
    return _NewItemDraft(
      name: json['name'] as String? ?? '',
      category: json['category'] as String? ?? 'Gold22kt',
      bhavText: json['bhavText'] as String? ?? '',
      makingType: json['makingType'] as String?,
      makingChargeText: json['makingChargeText'] as String? ?? '',
      grossWeightText: json['grossWeightText'] as String? ?? '',
      lessWeightText: json['lessWeightText'] as String? ?? '',
      additionalChargeText: json['additionalChargeText'] as String? ?? '',
      gstEnabled: json['gstEnabled'] as bool? ?? true,
      notes: json['notes'] as String? ?? '',
    );
  }

  final TextEditingController nameController;
  final TextEditingController categoryController;
  final TextEditingController bhavController;
  final TextEditingController makingTypeController;
  final TextEditingController makingChargeController;
  final TextEditingController grossWeightController;
  final TextEditingController lessWeightController;
  final TextEditingController additionalChargeController;
  final TextEditingController notesController;
  bool gstEnabled;
  bool showNameError = false;
  bool showWeightError = false;

  String get category {
    final value = categoryController.text.trim();
    return value.isEmpty ? 'Gold22kt' : value;
  }

  String get makingType {
    final value = makingTypeController.text.trim();
    if (value.isNotEmpty) {
      return value;
    }
    return category == 'Silver' ? 'PerGram' : 'FixRate';
  }

  double get bhav {
    return double.tryParse(bhavController.text.trim()) ?? 0;
  }

  double get makingCharge {
    return double.tryParse(makingChargeController.text.trim()) ?? 0;
  }

  double get grossWeight {
    return double.tryParse(grossWeightController.text.trim()) ?? 0;
  }

  double get lessWeight {
    return double.tryParse(lessWeightController.text.trim()) ?? 0;
  }

  double get netWeight {
    final value = grossWeight - lessWeight;
    return value > 0 ? value : 0;
  }

  double get additionalCharge {
    return double.tryParse(additionalChargeController.text.trim()) ?? 0;
  }

  bool get isEmpty =>
      nameController.text.trim().isEmpty &&
      bhav == 0 &&
      makingCharge == 0 &&
      grossWeight == 0 &&
      lessWeight == 0 &&
      additionalCharge == 0 &&
      notesController.text.trim().isEmpty;

  String? get nameError {
    if (!showNameError) {
      return null;
    }
    return nameController.text.trim().isEmpty ? 'Enter item name' : null;
  }

  String? get weightError {
    if (!showWeightError) {
      return null;
    }
    if (grossWeight <= 0) {
      return 'Enter gross weight';
    }
    if (netWeight <= 0) {
      return 'Nett weight must be positive';
    }
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'name': nameController.text,
      'category': categoryController.text,
      'bhavText': bhavController.text,
      'makingType': makingTypeController.text,
      'makingChargeText': makingChargeController.text,
      'grossWeightText': grossWeightController.text,
      'lessWeightText': lessWeightController.text,
      'additionalChargeText': additionalChargeController.text,
      'gstEnabled': gstEnabled,
      'notes': notesController.text,
    };
  }

  void dispose() {
    nameController.dispose();
    categoryController.dispose();
    bhavController.dispose();
    makingTypeController.dispose();
    makingChargeController.dispose();
    grossWeightController.dispose();
    lessWeightController.dispose();
    additionalChargeController.dispose();
    notesController.dispose();
  }
}

class _NewItemEditor extends StatelessWidget {
  const _NewItemEditor({
    required this.index,
    required this.item,
    required this.effectiveBhav,
    required this.amount,
    required this.baseAmount,
    required this.gstAmount,
    required this.makingTypeOptions,
    required this.onChanged,
    required this.onCategoryChanged,
    required this.onMakingTypeChanged,
    this.onRemove,
  });

  final int index;
  final _NewItemDraft item;
  final double effectiveBhav;
  final double amount;
  final double baseAmount;
  final double gstAmount;
  final List<String> makingTypeOptions;
  final VoidCallback onChanged;
  final ValueChanged<String> onCategoryChanged;
  final ValueChanged<String> onMakingTypeChanged;
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
                    'New Item $index',
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
                        _OrdersDashboardState._newItemCategoryOptions.contains(
                          item.category,
                        )
                        ? item.category
                        : _OrdersDashboardState._newItemCategoryOptions.first,
                    decoration: const InputDecoration(labelText: 'Category'),
                    items: _OrdersDashboardState._newItemCategoryOptions
                        .map(
                          (option) => DropdownMenuItem(
                            value: option,
                            child: Text(option),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }
                      onCategoryChanged(value);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: makingTypeOptions.contains(item.makingType)
                        ? item.makingType
                        : makingTypeOptions.first,
                    decoration: const InputDecoration(labelText: 'Making Type'),
                    items: makingTypeOptions
                        .map(
                          (option) => DropdownMenuItem(
                            value: option,
                            child: Text(option),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }
                      onMakingTypeChanged(value);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: item.bhavController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: decimalInput,
                    decoration: const InputDecoration(
                      labelText: 'Bhav',
                      hintText: 'Optional manual rate',
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
                  child: TextField(
                    controller: item.makingChargeController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: decimalInput,
                    decoration: InputDecoration(
                      labelText: item.makingType == 'Percentage'
                          ? 'Making %'
                          : 'Making Charge',
                      suffixText: item.makingType == 'Percentage' ? '%' : null,
                    ),
                    onChanged: (_) => onChanged(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Applied Bhav',
                    ),
                    child: Text(
                      _formatCurrency(effectiveBhav),
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
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
                        item.showWeightError = true;
                        onChanged();
                      }
                    },
                    child: TextField(
                      controller: item.grossWeightController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: decimalInput,
                      decoration: InputDecoration(
                        labelText: 'Gross Weight',
                        suffixText: 'g',
                        errorText: item.weightError,
                      ),
                      onChanged: (_) => onChanged(),
                    ),
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
                      labelText: 'Less Weight',
                      suffixText: 'g',
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
                      labelText: 'Nett Weight',
                      suffixText: 'g',
                    ),
                    child: Text(
                      _formatWeightFixed3(item.netWeight),
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: item.additionalChargeController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: decimalInput,
                    decoration: const InputDecoration(
                      labelText: 'Additional Charge',
                    ),
                    onChanged: (_) => onChanged(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'GST',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                      Switch(
                        value: item.gstEnabled,
                        onChanged: (value) {
                          item.gstEnabled = value;
                          onChanged();
                        },
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Base Amount',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                      Text(
                        _formatCurrency(baseAmount),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'GST Amount',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                      Text(
                        _formatCurrency(gstAmount),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Line Total',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      Text(
                        _formatCurrency(amount),
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
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
