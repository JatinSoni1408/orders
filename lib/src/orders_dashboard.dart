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
  static const _authSessionStorageKey = 'orders_dashboard.auth_session';
  static const _lockedEstimatePurity = '22K';
  static const List<String> _newItemCategoryOptions = [
    'Gold22kt',
    'Gold18kt',
    'Silver',
  ];
  static const List<String> _estimateMakingOptions = [
    '5',
    '6',
    '7',
    '8',
    '9',
    '10',
    '11',
    '12',
    '13',
    '14',
    '15',
    '16',
    '17',
    '18',
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
  final _FirebaseAuthService _authService = const _FirebaseAuthService();
  final _RatesRepository _ratesRepository = const _RatesRepository();
  final _FirestoreAppSyncService _appSyncService =
      const _FirestoreAppSyncService();
  final _TagImportService _tagImportService = const _TagImportService();

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
  final TextEditingController _newItemsGold22RateController =
      TextEditingController();
  final TextEditingController _newItemsGold18RateController =
      TextEditingController();
  final TextEditingController _newItemsSilverRateController =
      TextEditingController();
  final TextEditingController _loginEmailController = TextEditingController();
  final TextEditingController _loginPasswordController =
      TextEditingController();
  final TextEditingController _newItemsOverallDiscountController =
      TextEditingController();
  final TextEditingController _takeawayDiscountController =
      TextEditingController();
  final FocusNode _estimateCustomerNameFocusNode = FocusNode();
  final FocusNode _estimateCustomerMobileFocusNode = FocusNode();
  final FocusNode _estimateAlternateMobileFocusNode = FocusNode();
  final List<_EstimateItemDraft> _estimateItems = [_EstimateItemDraft()];
  final List<_AdvanceValuationDraft> _advanceItems = [_AdvanceValuationDraft()];
  final List<_AdvanceOldItemDraft> _advanceOldItems = [_AdvanceOldItemDraft()];
  final List<_NewItemDraft> _newItems = [_NewItemDraft()];
  final List<_TakeawayPaymentDraft> _takeawayPayments = [
    _TakeawayPaymentDraft(),
  ];
  late final _NewItemDraft _differenceNewItem = _NewItemDraft(
    name: 'Difference Weight',
    category: 'Gold22kt',
    grossWeightText: '0.000',
    lessWeightText: '0.000',
    isDifferenceEntry: true,
  );
  Timer? _estimateClockTimer;
  Timer? _persistDebounceTimer;
  Timer? _firestoreSyncDebounceTimer;
  bool _showEstimateNameError = false;
  bool _showEstimateMobileError = false;
  bool _showEstimateAlternateMobileError = false;
  bool _isRestoringLocalState = false;
  bool _isRatesLoading = false;
  bool _isTagScanning = false;
  bool _isAccessRoleLoading = true;
  bool _isSigningIn = false;
  bool _hideLoginPassword = true;
  OrderStatus _estimateStatus = OrderStatus.pending;
  DateTime _estimateDate = DateTime.now();
  DateTime _estimateDeliveryDate = DateTime.now();
  double _ratesGold24Rate = 0;
  DateTime? _ratesSyncedAt;
  DateTime? _ratesUpdatedAt;
  String? _editingOrderId;
  String? _ratesUpdatedByEmail;
  DateTime? _editingOrderCreatedAt;
  String _searchQuery = '';
  _AuthSession? _authSession;
  AppAccessRole? _activeRole;
  String? _accessError;
  String? _lastSyncedOrdersJson;
  String? _lastSyncedDraftJson;

  bool get _showsLiveEstimateClock =>
      _selectedSection == AppSection.estimateCalculator ||
      _selectedSection == AppSection.actual;
  bool get _isAdmin => _activeRole == AppAccessRole.admin;
  bool get _isUser => _activeRole == AppAccessRole.user;

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
    for (final item in _takeawayPayments) {
      _attachTakeawayPaymentListeners(item);
    }
    _attachNewItemFieldListeners();
    for (final item in _newItems) {
      _attachNewItemListeners(item);
    }
    _attachNewItemListeners(_differenceNewItem);
    _estimateClockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) {
        return;
      }
      if (!_showsLiveEstimateClock) {
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
    _restoreLocalState().then((_) => _restoreAuthSession()).whenComplete(() {
      _loadRatesFromFirestore();
    });
  }

  Future<void> _restoreAuthSession() async {
    final prefs = await SharedPreferences.getInstance();
    final savedSessionJson = prefs.getString(_authSessionStorageKey);
    if (savedSessionJson == null) {
      if (!mounted) {
        return;
      }
      setState(() {
        _authSession = null;
        _activeRole = null;
        _isAccessRoleLoading = false;
      });
      return;
    }

    try {
      final savedSession = _AuthSession.fromJson(
        jsonDecode(savedSessionJson) as Map<String, dynamic>,
      );
      final refreshed = await _authService.refreshSession(savedSession);
      await prefs.setString(
        _authSessionStorageKey,
        jsonEncode(refreshed.toJson()),
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _authSession = refreshed;
        _activeRole = refreshed.role;
        _isAccessRoleLoading = false;
      });
      await _restoreStateFromFirestore();
    } catch (_) {
      await prefs.remove(_authSessionStorageKey);
      if (!mounted) {
        return;
      }
      setState(() {
        _authSession = null;
        _activeRole = null;
        _isAccessRoleLoading = false;
      });
    }
  }

  Future<void> _signInWithFirebase({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim();
    if (normalizedEmail.isEmpty || password.trim().isEmpty) {
      setState(() {
        _accessError = 'Enter both email and password.';
      });
      return;
    }

    setState(() {
      _isSigningIn = true;
      _accessError = null;
    });

    try {
      final session = await _authService.signIn(
        email: normalizedEmail,
        password: password,
      );
      final prefs = await SharedPreferences.getInstance();
      if (session.role == AppAccessRole.admin) {
        await prefs.setString(
          _authSessionStorageKey,
          jsonEncode(session.toJson()),
        );
      } else {
        await prefs.remove(_authSessionStorageKey);
      }
      if (!mounted) {
        return;
      }
      setState(() {
        _authSession = session;
        _activeRole = session.role;
        _isSigningIn = false;
        _accessError = null;
        _selectedSection = AppSection.orders;
        _selectedStatus = null;
      });
      await _restoreStateFromFirestore();
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isSigningIn = false;
        _accessError = error is StateError
            ? error.message
            : 'Could not sign in with Firebase.';
      });
    }
  }

  Future<void> _signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_authSessionStorageKey);
    if (!mounted) {
      return;
    }
    setState(() {
      _orders.clear();
      _clearEstimateForm();
      _authSession = null;
      _activeRole = null;
      _accessError = null;
      _isSigningIn = false;
      _loginEmailController.clear();
      _loginPasswordController.clear();
      _hideLoginPassword = true;
      _selectedSection = AppSection.orders;
      _selectedStatus = null;
      _lastSyncedOrdersJson = null;
      _lastSyncedDraftJson = null;
    });
  }

  Future<void> _showLoginPasswordDialog() async {
    if (_loginEmailController.text.trim().isEmpty) {
      setState(() {
        _accessError = 'Enter your email first.';
      });
      return;
    }

    _loginPasswordController.clear();
    _accessError = null;
    _hideLoginPassword = true;

    await showDialog<void>(
      context: context,
      barrierDismissible: !_isSigningIn,
      builder: (dialogContext) {
        final dialogNavigator = Navigator.of(dialogContext);
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> submit() async {
              setDialogState(() {});
              await _signInWithFirebase(
                email: _loginEmailController.text,
                password: _loginPasswordController.text,
              );
              if (mounted && _activeRole != null) {
                dialogNavigator.pop();
              } else if (mounted) {
                setDialogState(() {});
              }
            }

            return AlertDialog(
              title: const Text('Enter Password'),
              content: TextField(
                controller: _loginPasswordController,
                autofocus: true,
                obscureText: _hideLoginPassword,
                enabled: !_isSigningIn,
                decoration: InputDecoration(
                  labelText: 'Password',
                  errorText: _accessError,
                  suffixIcon: IconButton(
                    onPressed: () {
                      setDialogState(() {
                        _hideLoginPassword = !_hideLoginPassword;
                      });
                    },
                    icon: Icon(
                      _hideLoginPassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                  ),
                ),
                onChanged: (_) {
                  if (_accessError != null) {
                    setState(() {
                      _accessError = null;
                    });
                    setDialogState(() {});
                  }
                },
                onSubmitted: (_) => submit(),
              ),
              actions: [
                TextButton(
                  onPressed: _isSigningIn
                      ? null
                      : () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: _isSigningIn ? null : submit,
                  child: _isSigningIn
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Continue'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _persistDebounceTimer?.cancel();
      _persistLocalState(syncImmediately: true);
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
    return _lockedEstimatePurity;
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

  String get _estimateDeliveryDateLabel {
    return DateFormat('dd/MM/yyyy').format(_estimateDeliveryDate);
  }

  bool get _isEditingEstimate {
    return _editingOrderId != null;
  }

  int get _estimateTotalQuantity {
    return _estimateItems
        .where((item) => !item.isEmpty)
        .fold<int>(0, (total, item) => total + item.quantity);
  }

  double get _estimateTotalEstimatedWeight {
    return _estimateItems
        .where((item) => !item.isEmpty)
        .fold<double>(0, (total, item) => total + item.estimatedWeight);
  }

  double get _actualTotalGrossWeight {
    return _estimateItems
        .where((item) => !item.isEmpty)
        .fold<double>(0, (total, item) => total + item.grossWeight);
  }

  double get _actualTotalLessWeight {
    return _estimateItems
        .where((item) => !item.isEmpty)
        .fold<double>(0, (total, item) => total + item.lessWeight);
  }

  double get _actualTotalNetWeight {
    return _estimateItems
        .where((item) => !item.isEmpty)
        .fold<double>(0, (total, item) => total + item.actualNetWeight);
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
      (total, item) => total + item.amount,
    );
  }

  List<_AdvanceOldItemDraft> get _populatedAdvanceOldItems {
    return _advanceOldItems.where((item) => !item.isEmpty).toList();
  }

  double get _advanceOldItemsTotalAmount {
    return _populatedAdvanceOldItems.fold<double>(
      0,
      (total, item) => total + item.amount,
    );
  }

  List<_TakeawayPaymentDraft> get _populatedTakeawayPayments {
    return _takeawayPayments.where((item) => !item.isEmpty).toList();
  }

  double get _takeawayPaymentsTotal {
    return _populatedTakeawayPayments.fold<double>(
      0,
      (total, item) => total + item.amount,
    );
  }

  List<TakeawayPayment> get _takeawayPaymentsForCurrentDraft {
    return _populatedTakeawayPayments
        .map(
          (item) => TakeawayPayment(
            date: item.date,
            mode: item.mode,
            amount: item.amount,
          ),
        )
        .toList();
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
            advanceRate: item.advanceRate,
            advanceMaking: item.advanceMaking,
            grossWeight: item.grossWeight,
            lessWeight: item.lessWeight,
            tanch: item.tanch,
          ),
        )
        .toList();
  }

  double get _differenceNetWeight {
    final difference = _actualTotalNetWeight - _billPreviewAdvanceNetWeight;
    return difference > 0 ? difference : 0;
  }

  bool get _shouldShowDifferenceNewItem => _differenceNetWeight > 0;

  void _syncDifferenceNewItem() {
    final weightText = _formatWeightFixed3(_differenceNetWeight);
    if (_differenceNewItem.nameController.text != 'Difference Weight') {
      _differenceNewItem.nameController.text = 'Difference Weight';
    }
    if (_differenceNewItem.grossWeightController.text != weightText) {
      _differenceNewItem.grossWeightController.text = weightText;
    }
    if (_differenceNewItem.lessWeightController.text != '0.000') {
      _differenceNewItem.lessWeightController.text = '0.000';
    }
    if (_differenceNewItem.categoryController.text.trim().isEmpty) {
      _differenceNewItem.categoryController.text = 'Gold22kt';
    }
    final options = _makingTypeOptionsFor(_differenceNewItem.category);
    if (!options.contains(
      _differenceNewItem.makingTypeController.text.trim(),
    )) {
      _differenceNewItem.makingTypeController.text = options.first;
    }
  }

  List<_NewItemDraft> get _populatedNewItems {
    final items = _newItems.where((item) => !item.isEmpty).toList();
    if (!_shouldShowDifferenceNewItem) {
      return items;
    }
    _syncDifferenceNewItem();
    return [_differenceNewItem, ...items];
  }

  List<_NewItemDraft> get _editableManualNewItems {
    if (_newItems.length == 1 && _newItems.first.isEmpty) {
      return const <_NewItemDraft>[];
    }
    return _newItems;
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

  String _formatRateControllerText(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), '');
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
    final fallbackCategory = item.isDifferenceEntry
        ? 'Gold22kt'
        : item.category;
    return item.bhav > 0
        ? item.bhav
        : _newItemRateForCategory(fallbackCategory);
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
      (total, item) => total + _newItemBaseAmount(item) + item.additionalCharge,
    );
  }

  double get _newItemsTotalGst {
    return _populatedNewItems.fold<double>(
      0,
      (total, item) => total + _newItemGstAmount(item),
    );
  }

  double get _newItemsTotalBeforeDiscount {
    return _populatedNewItems.fold<double>(
      0,
      (total, item) => total + _newItemTotalAmount(item),
    );
  }

  double get _newItemsOverallDiscount {
    final requested = _parseFormattedDecimal(
      _newItemsOverallDiscountController.text,
    );
    final capped = requested.clamp(0, _newItemsTotalBeforeDiscount);
    return capped.toDouble();
  }

  double get _newItemsGrandTotal {
    final total = _newItemsTotalBeforeDiscount - _newItemsOverallDiscount;
    return total > 0 ? total : 0;
  }

  double get _takeawayDiscount {
    final requested = _parseFormattedDecimal(_takeawayDiscountController.text);
    final capped = requested.clamp(0, _takeawayBalanceAfterPayments);
    return capped.toDouble();
  }

  double get _takeawayBalanceAfterPayments {
    final balance = _newItemsGrandTotal - _takeawayPaymentsTotal;
    return balance > 0 ? balance : 0;
  }

  double get _takeawayFinalDueAmount {
    final balance = _takeawayBalanceAfterPayments - _takeawayDiscount;
    return balance > 0 ? balance : 0;
  }

  double get _takeawayRefundAmount {
    final refund =
        _takeawayPaymentsTotal + _takeawayDiscount - _newItemsGrandTotal;
    return refund > 0 ? refund : 0;
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
    ]) {
      controller.addListener(_schedulePersistence);
    }
  }

  void _attachNewItemFieldListeners() {
    for (final controller in [
      _newItemsGold22RateController,
      _newItemsGold18RateController,
      _newItemsSilverRateController,
      _newItemsOverallDiscountController,
      _takeawayDiscountController,
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
      item.advanceRateController,
      item.advanceMakingController,
      item.grossWeightController,
      item.lessWeightController,
      item.tanchController,
    ]) {
      controller.addListener(_schedulePersistence);
    }
  }

  void _attachTakeawayPaymentListeners(_TakeawayPaymentDraft item) {
    item.amountController.addListener(_schedulePersistence);
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

  String _serializeOrdersJson() {
    return jsonEncode(_orders.map((order) => order.toJson()).toList());
  }

  Map<String, dynamic> _buildDraftStateMap() {
    return {
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
      'status': _estimateStatus.name,
      'deliveryDate': _estimateDeliveryDate.toIso8601String(),
      'advanceItems': _advanceItems.map((item) => item.toJson()).toList(),
      'advanceOldItems': _advanceOldItems.map((item) => item.toJson()).toList(),
      'takeawayPayments': _takeawayPayments
          .map((item) => item.toJson())
          .toList(),
      'newItemsGold22Rate': _newItemsGold22RateController.text,
      'newItemsGold18Rate': _newItemsGold18RateController.text,
      'newItemsSilverRate': _newItemsSilverRateController.text,
      'newItemsOverallDiscount': _newItemsOverallDiscountController.text,
      'takeawayDiscount': _takeawayDiscountController.text,
      'newItems': _newItems.map((item) => item.toJson()).toList(),
      'differenceNewItem': _differenceNewItem.toJson(),
      'editingOrderId': _editingOrderId,
      'editingOrderCreatedAt': _editingOrderCreatedAt?.toIso8601String(),
      'items': _estimateItems.map((item) => item.toJson()).toList(),
    };
  }

  String _serializeDraftJson() {
    return jsonEncode(_buildDraftStateMap());
  }

  void _scheduleFirestoreSync({
    String? ordersJson,
    String? draftJson,
    bool syncImmediately = false,
  }) {
    if (_isRestoringLocalState || _authSession == null) {
      return;
    }

    final nextOrdersJson = ordersJson ?? _serializeOrdersJson();
    final nextDraftJson = draftJson ?? _serializeDraftJson();
    final ordersChanged = nextOrdersJson != _lastSyncedOrdersJson;
    final draftChanged = nextDraftJson != _lastSyncedDraftJson;
    if (!ordersChanged && !draftChanged) {
      return;
    }

    _firestoreSyncDebounceTimer?.cancel();
    if (syncImmediately) {
      _syncStateToFirestore(
        ordersJson: nextOrdersJson,
        draftJson: nextDraftJson,
      );
      return;
    }

    _firestoreSyncDebounceTimer = Timer(const Duration(milliseconds: 900), () {
      _syncStateToFirestore(
        ordersJson: nextOrdersJson,
        draftJson: nextDraftJson,
      );
    });
  }

  Future<void> _syncStateToFirestore({
    String? ordersJson,
    String? draftJson,
  }) async {
    final session = _authSession;
    if (session == null) {
      return;
    }
    final nextOrdersJson = ordersJson ?? _serializeOrdersJson();
    final nextDraftJson = draftJson ?? _serializeDraftJson();
    final writes = <Future<void>>[];

    if (nextOrdersJson != _lastSyncedOrdersJson) {
      writes.add(_syncOrdersCollection(session.idToken));
    }
    if (nextDraftJson != _lastSyncedDraftJson) {
      writes.add(
        _appSyncService.saveDraft(
          idToken: session.idToken,
          uid: session.uid,
          draft: _buildDraftStateMap(),
        ),
      );
    }
    if (writes.isEmpty) {
      return;
    }

    try {
      await Future.wait(writes);
      _lastSyncedOrdersJson = nextOrdersJson;
      _lastSyncedDraftJson = nextDraftJson;
    } catch (_) {}
  }

  Future<void> _syncOrdersCollection(String idToken) async {
    final remoteOrders = await _appSyncService.fetchOrders(idToken: idToken);
    final remoteIds = remoteOrders.map((order) => order.id).toSet();
    final localIds = _orders.map((order) => order.id).toSet();

    final writes = <Future<void>>[
      for (final order in _orders)
        _appSyncService.saveOrder(idToken: idToken, order: order),
      for (final orderId in remoteIds.difference(localIds))
        _appSyncService.deleteOrder(idToken: idToken, orderId: orderId),
    ];
    if (writes.isEmpty) {
      return;
    }
    await Future.wait(writes);
  }

  Future<void> _persistLocalState({bool syncImmediately = false}) async {
    if (_isRestoringLocalState) {
      return;
    }

    final ordersJson = _serializeOrdersJson();
    final draftJson = _serializeDraftJson();
    if (syncImmediately) {
      await _syncStateToFirestore(ordersJson: ordersJson, draftJson: draftJson);
      return;
    }
    _scheduleFirestoreSync(ordersJson: ordersJson, draftJson: draftJson);
  }

  Future<void> _loadRatesFromFirestore({bool showFeedback = false}) async {
    if (_isRatesLoading) {
      return;
    }

    setState(() {
      _isRatesLoading = true;
    });

    try {
      final rates = await _ratesRepository.fetchRates();
      if (!mounted) {
        return;
      }

      _newItemsGold22RateController.text = _formatRateControllerText(
        rates.gold22Rate,
      );
      _newItemsGold18RateController.text = _formatRateControllerText(
        rates.gold18Rate,
      );
      _newItemsSilverRateController.text = _formatRateControllerText(
        rates.silverRate,
      );

      setState(() {
        _ratesGold24Rate = rates.gold24Rate;
        _ratesSyncedAt = DateTime.now();
        _ratesUpdatedAt = rates.updatedAt;
        _ratesUpdatedByEmail = rates.updatedByEmail;
      });
      _schedulePersistence();

      if (showFeedback) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rates refreshed from Firestore.')),
        );
      }
    } catch (_) {
      if (!mounted) {
        return;
      }

      if (showFeedback) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not refresh rates from Firestore.'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRatesLoading = false;
        });
      }
    }
  }

  Future<void> _scanQrTagIntoNewItems() async {
    if (_isTagScanning) {
      return;
    }

    setState(() {
      _isTagScanning = true;
    });

    try {
      final scannedValue = await Navigator.of(context).push<String>(
        MaterialPageRoute(
          builder: (context) => const _QrScannerPage(title: 'Scan QR Tag'),
        ),
      );
      if (!mounted || scannedValue == null || scannedValue.trim().isEmpty) {
        return;
      }

      final tag = await _tagImportService.fetchTagFromQr(scannedValue);
      if (!mounted) {
        return;
      }

      final duplicate = _newItems.any(
        (item) => item.sourceTagId == tag.sourceTagId,
      );
      if (duplicate) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Tag ${tag.sourceTagId} is already in New Items.'),
          ),
        );
        return;
      }

      setState(() {
        final target = _newItems.length == 1 && _newItems.first.isEmpty
            ? _newItems.first
            : () {
                final item = _NewItemDraft();
                _newItems.add(item);
                _attachNewItemListeners(item);
                return item;
              }();
        _applyImportedTagToNewItem(target, tag);
      });
      _schedulePersistence();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Imported ${tag.name} into New Items.')),
      );
    } on FormatException catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } on StateError catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Could not import QR tag.')));
    } finally {
      if (mounted) {
        setState(() {
          _isTagScanning = false;
        });
      }
    }
  }

  void _applyImportedTagToNewItem(_NewItemDraft item, _ImportedTagData tag) {
    final makingOptions = _makingTypeOptionsFor(tag.category);
    final categoryBhav = _newItemRateForCategory(tag.category);
    item.nameController.text = tag.name;
    item.categoryController.text = tag.category;
    item.bhavController.text = categoryBhav > 0
        ? _formatRateControllerText(categoryBhav)
        : '';
    item.makingTypeController.text = makingOptions.contains(tag.makingType)
        ? tag.makingType
        : makingOptions.first;
    item.makingChargeController.text = tag.makingChargeText;
    item.grossWeightController.text = tag.grossWeightText;
    item.lessWeightController.text = tag.lessWeightText;
    item.additionalChargeController.text = tag.additionalChargeText;
    item.notesController.text = tag.notes;
    item.gstEnabled = true;
    item.gstLockedOn = tag.isHuid;
    item.sourceTagId = tag.sourceTagId;
    item.showNameError = false;
    item.showWeightError = false;
  }

  void _resetDifferenceNewItem() {
    _differenceNewItem.nameController.text = 'Difference Weight';
    _differenceNewItem.categoryController.text = 'Gold22kt';
    _differenceNewItem.bhavController.clear();
    _differenceNewItem.makingTypeController.text = 'FixRate';
    _differenceNewItem.makingChargeController.clear();
    _differenceNewItem.grossWeightController.text = '0.000';
    _differenceNewItem.lessWeightController.text = '0.000';
    _differenceNewItem.additionalChargeController.clear();
    _differenceNewItem.notesController.clear();
    _differenceNewItem.sourceTagId = null;
    _differenceNewItem.gstLockedOn = false;
    _differenceNewItem.gstEnabled = true;
    _differenceNewItem.showNameError = false;
    _differenceNewItem.showWeightError = false;
  }

  void _hydrateNewItemDraft(
    _NewItemDraft target, {
    required String name,
    required String category,
    required String bhavText,
    required String makingType,
    required String makingChargeText,
    required String grossWeightText,
    required String lessWeightText,
    required String additionalChargeText,
    required bool gstEnabled,
    required bool gstLockedOn,
    required String? sourceTagId,
    required String notes,
  }) {
    target.nameController.text = name;
    target.categoryController.text = category;
    target.bhavController.text = bhavText;
    target.makingTypeController.text = makingType;
    target.makingChargeController.text = makingChargeText;
    target.grossWeightController.text = grossWeightText;
    target.lessWeightController.text = lessWeightText;
    target.additionalChargeController.text = additionalChargeText;
    target.notesController.text = notes;
    target.gstEnabled = gstEnabled;
    target.gstLockedOn = gstLockedOn;
    target.sourceTagId = sourceTagId;
    target.showNameError = false;
    target.showWeightError = false;
  }

  Future<Map<String, dynamic>?> _openNewItemEntryPage({
    Map<String, dynamic>? initialData,
    String title = 'Add New Item',
  }) async {
    return Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (pageContext) {
          return _NewItemEntryPage(
            title: title,
            initialData: initialData,
            gold22Rate: _newItemRateForCategory('Gold22kt'),
            gold18Rate: _newItemRateForCategory('Gold18kt'),
            silverRate: _newItemRateForCategory('Silver'),
            gstRate: _estimateGst,
          );
        },
      ),
    );
  }

  Future<void> _openManualNewItemDialog() async {
    final result = await _openNewItemEntryPage();
    if (!mounted || result == null) {
      return;
    }

    final item = _NewItemDraft.fromJson(result);
    setState(() {
      if (_newItems.length == 1 && _newItems.first.isEmpty) {
        final removed = _newItems.removeAt(0);
        removed.dispose();
      }
      _newItems.add(item);
      _attachNewItemListeners(item);
    });
    _schedulePersistence();
  }

  Future<void> _editExistingNewItem(_NewItemDraft item) async {
    final result = await _openNewItemEntryPage(
      initialData: item.toJson(),
      title: 'Edit New Item',
    );
    if (!mounted || result == null) {
      return;
    }

    final updated = _NewItemDraft.fromJson(result);
    setState(() {
      _hydrateNewItemDraft(
        item,
        name: updated.nameController.text,
        category: updated.categoryController.text,
        bhavText: updated.bhavController.text,
        makingType: updated.makingTypeController.text,
        makingChargeText: updated.makingChargeController.text,
        grossWeightText: updated.grossWeightController.text,
        lessWeightText: updated.lessWeightController.text,
        additionalChargeText: updated.additionalChargeController.text,
        gstEnabled: updated.gstEnabled,
        gstLockedOn: updated.gstLockedOn,
        sourceTagId: updated.sourceTagId,
        notes: updated.notesController.text,
      );
    });
    updated.dispose();
    _schedulePersistence();
  }

  void _applySavedDraftMap(Map<String, dynamic> decodedEstimate) {
    final restoredItems =
        (decodedEstimate['items'] as List<dynamic>? ?? const [])
            .map(
              (item) =>
                  _EstimateItemDraft.fromJson(item as Map<String, dynamic>),
            )
            .toList();
    final restoredAdvanceItems =
        (decodedEstimate['advanceItems'] as List<dynamic>? ?? const [])
            .map(
              (item) =>
                  _AdvanceValuationDraft.fromJson(item as Map<String, dynamic>),
            )
            .toList();
    final restoredAdvanceOldItems =
        (decodedEstimate['advanceOldItems'] as List<dynamic>? ?? const [])
            .map(
              (item) =>
                  _AdvanceOldItemDraft.fromJson(item as Map<String, dynamic>),
            )
            .toList();
    final restoredTakeawayPayments =
        (decodedEstimate['takeawayPayments'] as List<dynamic>? ?? const [])
            .map(
              (item) =>
                  _TakeawayPaymentDraft.fromJson(item as Map<String, dynamic>),
            )
            .toList();
    final restoredNewItems =
        (decodedEstimate['newItems'] as List<dynamic>? ?? const [])
            .map((item) => _NewItemDraft.fromJson(item as Map<String, dynamic>))
            .toList();
    final restoredDifferenceNewItem = decodedEstimate['differenceNewItem'];

    _selectedSection = AppSection.orders;

    final savedStatus = decodedEstimate['selectedStatus'] as String?;
    _selectedStatus = savedStatus == null
        ? null
        : _orderStatusFromName(savedStatus);
    _selectedOrderSort = OrderSortOption.values.firstWhere(
      (option) => option.name == decodedEstimate['selectedOrderSort'],
      orElse: () => OrderSortOption.newest,
    );

    _estimatePurityController.text = _lockedEstimatePurity;
    _estimateGstController.text = decodedEstimate['gst'] as String? ?? '3';
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
    _newItemsGold22RateController.text =
        decodedEstimate['newItemsGold22Rate'] as String? ?? '';
    _newItemsGold18RateController.text =
        decodedEstimate['newItemsGold18Rate'] as String? ?? '';
    _newItemsSilverRateController.text =
        decodedEstimate['newItemsSilverRate'] as String? ?? '';
    _newItemsOverallDiscountController.text =
        decodedEstimate['newItemsOverallDiscount'] as String? ?? '';
    _takeawayDiscountController.text =
        decodedEstimate['takeawayDiscount'] as String? ?? '';
    _estimateStatus = _orderStatusFromName(
      decodedEstimate['status'] as String? ?? OrderStatus.pending.name,
    );
    _estimateDeliveryDate =
        _dateTimeFromJson(decodedEstimate['deliveryDate']) ?? DateTime.now();
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
      ..addAll(restoredItems.isEmpty ? [_EstimateItemDraft()] : restoredItems);
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

    for (final item in _takeawayPayments) {
      item.dispose();
    }
    _takeawayPayments
      ..clear()
      ..addAll(
        restoredTakeawayPayments.isEmpty
            ? [_TakeawayPaymentDraft()]
            : restoredTakeawayPayments,
      );
    for (final item in _takeawayPayments) {
      _attachTakeawayPaymentListeners(item);
    }

    for (final item in _newItems) {
      item.dispose();
    }
    _newItems
      ..clear()
      ..addAll(restoredNewItems.isEmpty ? [_NewItemDraft()] : restoredNewItems);
    for (final item in _newItems) {
      _attachNewItemListeners(item);
    }

    _resetDifferenceNewItem();
    if (restoredDifferenceNewItem is Map) {
      final draft = _NewItemDraft.fromJson(
        Map<String, dynamic>.from(restoredDifferenceNewItem),
      );
      _hydrateNewItemDraft(
        _differenceNewItem,
        name: draft.nameController.text,
        category: draft.categoryController.text,
        bhavText: draft.bhavController.text,
        makingType: draft.makingTypeController.text,
        makingChargeText: draft.makingChargeController.text,
        grossWeightText: draft.grossWeightController.text,
        lessWeightText: draft.lessWeightController.text,
        additionalChargeText: draft.additionalChargeController.text,
        gstEnabled: draft.gstEnabled,
        gstLockedOn: draft.gstLockedOn,
        sourceTagId: draft.sourceTagId,
        notes: draft.notesController.text,
      );
      draft.dispose();
    }
  }

  Future<void> _restoreStateFromFirestore() async {
    final session = _authSession;
    if (session == null) {
      return;
    }

    try {
      final results = await Future.wait<dynamic>([
        _appSyncService.fetchOrders(idToken: session.idToken),
        _appSyncService.fetchDraft(idToken: session.idToken, uid: session.uid),
      ]);
      final remoteOrders = results[0] as List<Order>;
      final remoteDraft = results[1] as Map<String, dynamic>?;

      if (!mounted) {
        return;
      }

      final hasRemoteOrders = remoteOrders.isNotEmpty;
      final hasRemoteDraft = remoteDraft != null;
      if (!hasRemoteOrders && !hasRemoteDraft) {
        _scheduleFirestoreSync(syncImmediately: true);
        return;
      }

      _isRestoringLocalState = true;
      setState(() {
        if (hasRemoteOrders) {
          _orders
            ..clear()
            ..addAll(remoteOrders);
        }
        final remoteDraftData = remoteDraft;
        if (remoteDraftData != null) {
          _applySavedDraftMap(remoteDraftData);
        }
      });
      _lastSyncedOrdersJson = hasRemoteOrders
          ? jsonEncode(remoteOrders.map((order) => order.toJson()).toList())
          : null;
      _lastSyncedDraftJson = hasRemoteDraft ? jsonEncode(remoteDraft) : null;
      if (!hasRemoteOrders || !hasRemoteDraft) {
        _scheduleFirestoreSync(syncImmediately: true);
      }
    } catch (_) {
      _scheduleFirestoreSync(syncImmediately: true);
      return;
    } finally {
      _isRestoringLocalState = false;
    }

    await _persistLocalState();
  }

  Future<void> _restoreLocalState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_ordersStorageKey);
    await prefs.remove(_estimateStorageKey);
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
    _estimatePurityController.text = _lockedEstimatePurity;
    _estimateGstController.text = '3';
    _estimateMakingController.text = '15';
    _estimateWeightRangeController.clear();
    _estimateCustomerNameController.clear();
    _estimateCustomerMobileController.clear();
    _estimateAlternateMobileController.clear();
    _newItemsOverallDiscountController.clear();
    _takeawayDiscountController.clear();
    _showEstimateNameError = false;
    _showEstimateMobileError = false;
    _showEstimateAlternateMobileError = false;
    _resetDifferenceNewItem();
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

    for (final item in _takeawayPayments) {
      item.dispose();
    }
    _takeawayPayments
      ..clear()
      ..add(_TakeawayPaymentDraft());
    _attachTakeawayPaymentListeners(_takeawayPayments.first);

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
    _estimatePurityController.text = _lockedEstimatePurity;
    _estimateGstController.text = (order.estimateGst ?? 3).toString();
    _estimateMakingController.text = (order.estimateMaking ?? 15).toString();
    _estimateWeightRangeController.text = order.estimateWeightRange ?? '';
    _estimateCustomerNameController.text = order.customer;
    _estimateCustomerMobileController.text = order.customerPhone ?? '';
    _estimateAlternateMobileController.text = order.altCustomerPhone ?? '';
    _newItemsOverallDiscountController.text = order.newItemsOverallDiscount > 0
        ? _formatIndianNumberInput(order.newItemsOverallDiscount.toString())
        : '';
    _takeawayDiscountController.text = order.takeawayDiscount > 0
        ? _formatIndianNumberInput(order.takeawayDiscount.toString())
        : '';
    _showEstimateNameError = false;
    _showEstimateMobileError = false;
    _showEstimateAlternateMobileError = false;
    _estimateStatus = order.status;
    _resetDifferenceNewItem();

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
                      purity: item.purity ?? _lockedEstimatePurity,
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
                      advanceRateText: item.advanceRate.toString(),
                      advanceMakingText: item.advanceMaking.toString(),
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

    for (final item in _takeawayPayments) {
      item.dispose();
    }
    _takeawayPayments
      ..clear()
      ..addAll(
        order.takeawayPayments.isEmpty
            ? [_TakeawayPaymentDraft()]
            : order.takeawayPayments
                  .map(
                    (payment) => _TakeawayPaymentDraft(
                      date: payment.date,
                      mode: payment.mode,
                      amountText: payment.amount.toString(),
                    ),
                  )
                  .toList(),
      );
    for (final item in _takeawayPayments) {
      _attachTakeawayPaymentListeners(item);
    }

    for (final item in _newItems) {
      item.dispose();
    }
    final restoredRegularNewItems = <_NewItemDraft>[];
    for (final item in order.newItems) {
      if (item.isDifferenceEntry) {
        _hydrateNewItemDraft(
          _differenceNewItem,
          name: item.name,
          category: item.category,
          bhavText: item.bhav > 0 ? item.bhav.toString() : '',
          makingType: item.makingType,
          makingChargeText: item.makingCharge.toString(),
          grossWeightText: item.grossWeight.toString(),
          lessWeightText: item.lessWeight.toString(),
          additionalChargeText: item.additionalCharge.toString(),
          gstEnabled: item.gstEnabled,
          gstLockedOn: item.gstLockedOn,
          sourceTagId: item.sourceTagId,
          notes: item.notes ?? '',
        );
        continue;
      }
      restoredRegularNewItems.add(
        _NewItemDraft(
          name: item.name,
          category: item.category,
          bhavText: item.bhav > 0 ? item.bhav.toString() : '',
          makingType: item.makingType,
          makingChargeText: item.makingCharge.toString(),
          grossWeightText: item.grossWeight.toString(),
          lessWeightText: item.lessWeight.toString(),
          additionalChargeText: item.additionalCharge.toString(),
          gstEnabled: item.gstEnabled,
          gstLockedOn: item.gstLockedOn,
          sourceTagId: item.sourceTagId,
          notes: item.notes ?? '',
        ),
      );
    }
    _newItems
      ..clear()
      ..addAll(
        restoredRegularNewItems.isEmpty
            ? [_NewItemDraft()]
            : restoredRegularNewItems,
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
      takeawayPayments: _takeawayPaymentsForCurrentDraft,
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
              gstLockedOn: item.gstLockedOn,
              sourceTagId: item.sourceTagId,
              isDifferenceEntry: item.isDifferenceEntry,
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
      deliveryDate: _estimateDeliveryDate,
      newItemsOverallDiscount: _newItemsOverallDiscount,
      takeawayDiscount: _takeawayDiscount,
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
      (total, order) => total + order.total,
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
            deliveryDate: _estimateDeliveryDateLabel,
            purity: _estimatePurity,
            making: _estimateMaking.toStringAsFixed(2),
            gst: '${_estimateGst.toStringAsFixed(2)}%',
            totalQuantity: _estimateTotalQuantity.toString(),
            totalWeight: _estimateWeightRangeLabel,
            gold22Rate: _newItemRateForCategory('Gold22kt'),
            gold18Rate: _newItemRateForCategory('Gold18kt'),
            silverRate: _newItemRateForCategory('Silver'),
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
            overallDiscount: _newItemsOverallDiscount,
            grandTotal: _newItemsGrandTotal,
            items: _populatedNewItems,
          );
        },
      ),
    );
  }

  void _openBhavScreen() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) {
          return _BhavPage(
            gold22Rate: _newItemRateForCategory('Gold22kt'),
            gold18Rate: _newItemRateForCategory('Gold18kt'),
            silverRate: _newItemRateForCategory('Silver'),
            gold24Rate: _ratesGold24Rate,
            syncedAt: _ratesSyncedAt ?? DateTime.now(),
            updatedAt: _ratesUpdatedAt,
            updatedByEmail: _ratesUpdatedByEmail,
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
      advanceNetWeight: _billPreviewAdvanceNetWeight,
      newItemsSubtotal: _newItemsSubtotal,
      newItemsTotalGst: _newItemsTotalGst,
      newItemsOverallDiscount: _newItemsOverallDiscount,
      newItemsGrandTotal: _newItemsGrandTotal,
      takeawayPayments: _populatedTakeawayPayments,
      takeawayPaymentsTotal: _takeawayPaymentsTotal,
      takeawayBalanceAfterPayments: _takeawayBalanceAfterPayments,
      takeawayDiscount: _takeawayDiscount,
      takeawayFinalDueAmount: _takeawayFinalDueAmount,
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

  String _orderWeightRangeLabel(Order order) {
    if ((order.estimateWeightRange ?? '').trim().isNotEmpty) {
      return order.estimateWeightRange!.trim();
    }
    final weights = order.items
        .map((item) => item.estimatedWeight ?? item.weight)
        .where((weight) => weight > 0)
        .toList();
    if (weights.isEmpty) {
      return '-';
    }
    final startWeight = weights.reduce((a, b) => a < b ? a : b);
    final endWeight = weights.reduce((a, b) => a > b ? a : b);
    if ((endWeight - startWeight).abs() < 0.0001) {
      return '${_formatWeight3(startWeight)} gm';
    }
    return '${_formatWeight3(startWeight)} gm - ${_formatWeight3(endWeight)} gm';
  }

  Future<void> _openCombinedBillPrintPreviewForOrder(Order order) async {
    final estimateDrafts = order.items
        .map(
          (item) => _EstimateItemDraft(
            name: item.name,
            purity: item.purity ?? _lockedEstimatePurity,
            quantity: item.quantity,
            estimatedNettWeight: item.estimatedWeight ?? item.weight,
            grossWeight: item.grossWeight,
            lessWeight: item.lessWeight,
            size: item.size,
            length: item.length,
            notes: item.notes ?? '',
          ),
        )
        .toList();
    final advanceDrafts = order.advancePayments
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
        .toList();
    final oldItemDrafts = order.oldItemReturns
        .map(
          (item) => _AdvanceOldItemDraft(
            date: item.date,
            itemName: item.itemName,
            returnRateText: item.returnRate.toString(),
            advanceRateText: item.advanceRate.toString(),
            advanceMakingText: item.advanceMaking.toString(),
            grossWeightText: item.grossWeight.toString(),
            lessWeightText: item.lessWeight.toString(),
            tanchText: item.tanch.toString(),
          ),
        )
        .toList();
    final newItemDrafts = order.newItems
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
            sourceTagId: item.sourceTagId,
            gstLockedOn: item.gstLockedOn,
            gstEnabled: item.gstEnabled,
            isDifferenceEntry: item.isDifferenceEntry,
            notes: item.notes ?? '',
          ),
        )
        .toList();
    final takeawayDrafts = order.takeawayPayments
        .map(
          (payment) => _TakeawayPaymentDraft(
            date: payment.date,
            mode: payment.mode,
            amountText: payment.amount.toString(),
          ),
        )
        .toList();

    final actualGrossWeight = order.items.fold<double>(
      0,
      (total, item) => total + (item.grossWeight ?? 0),
    );
    final actualLessWeight = order.items.fold<double>(
      0,
      (total, item) => total + (item.lessWeight ?? 0),
    );
    final actualNetWeight = order.items.fold<double>(0, (total, item) {
      final storedNet = item.netWeight;
      final computedNet = (item.grossWeight ?? 0) - (item.lessWeight ?? 0);
      final net = storedNet ?? (computedNet > 0 ? computedNet : 0);
      return total + (net > 0 ? net : 0);
    });
    final advanceTotalAmount = order.advancePayments.fold<double>(
      0,
      (total, payment) => total + payment.amount,
    );
    final advanceOldItemsTotalAmount = order.oldItemReturns.fold<double>(
      0,
      (total, item) => total + item.amount,
    );
    final advanceNetWeight =
        order.advancePayments.fold<double>(
          0,
          (total, payment) => total + payment.weight,
        ) +
        order.oldItemReturns.fold<double>(
          0,
          (total, item) => total + item.nettWeight,
        );
    final takeawayPaymentsTotal = order.takeawayPayments.fold<double>(
      0,
      (total, payment) => total + payment.amount,
    );
    final takeawayBalanceAfterPayments = (order.total - takeawayPaymentsTotal)
        .clamp(0, double.infinity)
        .toDouble();
    final takeawayDiscount = order.takeawayDiscount;
    final takeawayFinalDueAmount =
        (takeawayBalanceAfterPayments - takeawayDiscount)
            .clamp(0, double.infinity)
            .toDouble();

    final preview = _CombinedBillPrintPreviewSheet(
      customerName: order.customer,
      customerMobile: (order.customerPhone ?? '').trim().isEmpty
          ? '-'
          : order.customerPhone!,
      alternateMobile: (order.altCustomerPhone ?? '').trim().isEmpty
          ? '-'
          : order.altCustomerPhone!,
      statusLabel: order.status.label,
      deliveryDate: order.deliveryDate == null
          ? '-'
          : _formatEntryDate(order.deliveryDate!),
      purity: order.estimatePurity ?? _lockedEstimatePurity,
      making: (order.estimateMaking ?? 15).toStringAsFixed(2),
      gstRate: order.estimateGst ?? 3,
      estimateTotalQuantity: order.items
          .fold<int>(0, (total, item) => total + item.quantity)
          .toString(),
      estimateWeightRange: _orderWeightRangeLabel(order),
      actualTotalGrossWeight: _formatWeightFixed3(actualGrossWeight),
      actualTotalLessWeight: _formatWeightFixed3(actualLessWeight),
      actualTotalNetWeight: _formatWeightFixed3(actualNetWeight),
      advanceTotalAmount: advanceTotalAmount,
      advanceOldItemsTotalAmount: advanceOldItemsTotalAmount,
      advanceNetWeight: advanceNetWeight,
      newItemsSubtotal: 0,
      newItemsTotalGst: 0,
      newItemsOverallDiscount: order.newItemsOverallDiscount,
      newItemsGrandTotal: order.total,
      takeawayPayments: takeawayDrafts,
      takeawayPaymentsTotal: takeawayPaymentsTotal,
      takeawayBalanceAfterPayments: takeawayBalanceAfterPayments,
      takeawayDiscount: takeawayDiscount,
      takeawayFinalDueAmount: takeawayFinalDueAmount,
      balanceAfterAdvance:
          order.total - (advanceTotalAmount + advanceOldItemsTotalAmount),
      gold22Rate: _newItemRateForCategory('Gold22kt'),
      gold18Rate: _newItemRateForCategory('Gold18kt'),
      silverRate: _newItemRateForCategory('Silver'),
      estimateItems: estimateDrafts,
      advanceItems: advanceDrafts,
      oldItems: oldItemDrafts,
      newItems: newItemDrafts,
    );

    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => preview));

    for (final item in estimateDrafts) {
      item.dispose();
    }
    for (final item in advanceDrafts) {
      item.dispose();
    }
    for (final item in oldItemDrafts) {
      item.dispose();
    }
    for (final item in newItemDrafts) {
      item.dispose();
    }
    for (final item in takeawayDrafts) {
      item.dispose();
    }
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
            takeawayPayments: existingOrder.takeawayPayments,
            customerPhone: existingOrder.customerPhone,
            altCustomerPhone: existingOrder.altCustomerPhone,
            customerPhotoPath: existingOrder.customerPhotoPath,
            estimatePurity: existingOrder.estimatePurity,
            estimateGst: existingOrder.estimateGst,
            estimateMaking: existingOrder.estimateMaking,
            estimateWeightRange: existingOrder.estimateWeightRange,
            deliveryDate: existingOrder.deliveryDate,
            newItemsOverallDiscount: existingOrder.newItemsOverallDiscount,
            takeawayDiscount: existingOrder.takeawayDiscount,
          );
        }
      });
    }
    _persistDebounceTimer?.cancel();
    await _persistLocalState(syncImmediately: true);
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
                    onView: _isUser
                        ? () => _openCombinedBillPrintPreviewForOrder(order)
                        : null,
                    onEdit: _isAdmin ? () => _openEditOrderSheet(order) : null,
                    onDelete: _isAdmin
                        ? () => _confirmDeleteOrder(order)
                        : null,
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
                    enabled: false,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue:
                        _estimateMakingOptions.contains(
                          _estimateMakingController.text.trim(),
                        )
                        ? _estimateMakingController.text.trim()
                        : '15',
                    decoration: const InputDecoration(
                      labelText: 'Making',
                      suffixText: '%',
                      isDense: true,
                    ),
                    items: _estimateMakingOptions
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
                      _estimateMakingController.text = value;
                      setState(() {});
                      _schedulePersistence();
                    },
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
                    enabled: false,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue:
                        _estimateMakingOptions.contains(
                          _estimateMakingController.text.trim(),
                        )
                        ? _estimateMakingController.text.trim()
                        : '15',
                    decoration: const InputDecoration(
                      labelText: 'Making',
                      suffixText: '%',
                      isDense: true,
                    ),
                    items: _estimateMakingOptions
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
                      _estimateMakingController.text = value;
                      setState(() {});
                      _schedulePersistence();
                    },
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
    final populatedNewItems = _populatedNewItems;
    final editableManualNewItems = _editableManualNewItems;
    final showsDifferenceNewItem = _shouldShowDifferenceNewItem;
    if (showsDifferenceNewItem) {
      _syncDifferenceNewItem();
    }

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(16, contentTopPadding, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: _openManualNewItemDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('New Item'),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: _isTagScanning ? null : _scanQrTagIntoNewItems,
                  icon: _isTagScanning
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.qr_code_scanner_outlined),
                  label: const Text('Scan QR Tag'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (showsDifferenceNewItem)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _NewItemEditor(
                  index: 1,
                  item: _differenceNewItem,
                  titleText:
                      'Difference Weight (${_formatWeightFixed3(_differenceNetWeight)} g)',
                  effectiveBhav: _newItemBhav(_differenceNewItem),
                  amount: _newItemTotalAmount(_differenceNewItem),
                  baseAmount: _newItemBaseAmount(_differenceNewItem),
                  gstAmount: _newItemGstAmount(_differenceNewItem),
                  makingTypeOptions: _makingTypeOptionsFor(
                    _differenceNewItem.category,
                  ),
                  onChanged: () {
                    setState(() {});
                    _schedulePersistence();
                  },
                  onCategoryChanged: (_) {
                    _differenceNewItem.categoryController.text = 'Gold22kt';
                    final options = _makingTypeOptionsFor('Gold22kt');
                    if (!options.contains(_differenceNewItem.makingType)) {
                      _differenceNewItem.makingTypeController.text =
                          options.first;
                    }
                    setState(() {});
                    _schedulePersistence();
                  },
                  onMakingTypeChanged: (value) {
                    _differenceNewItem.makingTypeController.text = value;
                    setState(() {});
                    _schedulePersistence();
                  },
                ),
              ),
            ...List.generate(editableManualNewItems.length, (index) {
              final item = editableManualNewItems[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _NewItemEditor(
                  index: index + 1 + (showsDifferenceNewItem ? 1 : 0),
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
                  onEdit: () => _editExistingNewItem(item),
                  onRemove: () {
                    setState(() {
                      final removed = editableManualNewItems[index];
                      _newItems.remove(removed);
                      removed.dispose();
                    });
                    _schedulePersistence();
                  },
                ),
              );
            }),
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
                      label: 'Actual Nett Weight',
                      value: '${_formatWeightFixed3(_actualTotalNetWeight)} gm',
                    ),
                    const SizedBox(height: 8),
                    _EstimateSummaryRow(
                      label: 'Advance Nett Weight',
                      value:
                          '${_formatWeightFixed3(_billPreviewAdvanceNetWeight)} gm',
                    ),
                    const SizedBox(height: 8),
                    _EstimateSummaryRow(
                      label: 'Difference Weight',
                      value: '${_formatWeightFixed3(_differenceNetWeight)} gm',
                    ),
                    const SizedBox(height: 8),
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
                      label: 'Overall Discount',
                      value: _formatCurrency(_newItemsOverallDiscount),
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

  double get _billPreviewAdvanceNetWeight {
    return _populatedAdvanceItems.fold<double>(
          0,
          (total, item) => total + item.weight,
        ) +
        _populatedAdvanceOldItems.fold<double>(
          0,
          (total, item) => total + item.nettWeight,
        );
  }

  Widget _buildTakeawaySummaryCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Takeaway Summary',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Text(
              'Payments',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            ...List.generate(_takeawayPayments.length, (index) {
              final item = _takeawayPayments[index];
              return Padding(
                padding: EdgeInsets.only(
                  bottom: index == _takeawayPayments.length - 1 ? 0 : 8,
                ),
                child: _TakeawayPaymentEditor(
                  index: index,
                  item: item,
                  onChanged: () {
                    setState(() {});
                    _schedulePersistence();
                  },
                  onRemove: _takeawayPayments.length == 1
                      ? null
                      : () {
                          setState(() {
                            final removed = _takeawayPayments.removeAt(index);
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
              child: OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    final item = _TakeawayPaymentDraft();
                    _takeawayPayments.add(item);
                    _attachTakeawayPaymentListeners(item);
                  });
                  _schedulePersistence();
                },
                icon: const Icon(Icons.add),
                label: const Text('Add payment'),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _takeawayDiscountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: const [_IndianCurrencyInputFormatter()],
              decoration: const InputDecoration(
                labelText: 'Discount',
                hintText: 'Enter takeaway discount',
              ),
              onChanged: (_) {
                setState(() {});
                _schedulePersistence();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBillPreviewBody(double contentTopPadding) {
    return SafeArea(
      child: ListView(
        padding: EdgeInsets.fromLTRB(16, contentTopPadding, 16, 16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Order Summary',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Use the print button in the app bar to open the Order Summary PDF preview in a separate window.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildTakeawaySummaryCard(),
        ],
      ),
    );
  }

  Widget _buildBillPreviewStickyBar() {
    final colorScheme = Theme.of(context).colorScheme;
    final keyboardInset = MediaQuery.of(context).viewInsets.bottom;
    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: keyboardInset),
      child: Material(
        color: colorScheme.surface,
        elevation: 6,
        child: SafeArea(
          top: false,
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Received Payment',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: Colors.grey.shade700),
                          textAlign: TextAlign.left,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _formatCurrency(_takeawayPaymentsTotal),
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                          textAlign: TextAlign.left,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _takeawayRefundAmount > 0
                              ? 'Refund Amount'
                              : 'Final Due Amount',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: Colors.grey.shade700),
                          textAlign: TextAlign.right,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _formatCurrency(
                            _takeawayRefundAmount > 0
                                ? _takeawayRefundAmount
                                : _takeawayFinalDueAmount,
                          ),
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: _takeawayRefundAmount > 0
                                    ? Theme.of(context).colorScheme.error
                                    : Colors.green.shade700,
                              ),
                          textAlign: TextAlign.right,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAccessGate() {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Sign In',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Use your Firebase account to continue. Admin gets full access, and user accounts can view and print saved orders only.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: _loginEmailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.done,
                        enabled: !_isSigningIn,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          hintText: 'you@example.com',
                          errorText: _accessError,
                          prefixIcon: const Icon(Icons.mail_outline),
                        ),
                        onChanged: (_) {
                          if (_accessError != null) {
                            setState(() {
                              _accessError = null;
                            });
                          }
                        },
                        onSubmitted: (_) => _showLoginPasswordDialog(),
                      ),
                      const SizedBox(height: 20),
                      FilledButton.icon(
                        onPressed: _isSigningIn
                            ? null
                            : _showLoginPasswordDialog,
                        icon: const Icon(Icons.login_outlined),
                        label: const Text('Continue'),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Admin session stays signed in on relaunch. User session opens the sign-in page next time.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
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
    _firestoreSyncDebounceTimer?.cancel();
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    _searchController.dispose();
    _estimatePurityController.dispose();
    _estimateGstController.dispose();
    _estimateMakingController.dispose();
    _estimateWeightRangeController.dispose();
    _estimateCustomerNameController.dispose();
    _estimateCustomerMobileController.dispose();
    _estimateAlternateMobileController.dispose();
    _newItemsGold22RateController.dispose();
    _newItemsGold18RateController.dispose();
    _newItemsSilverRateController.dispose();
    _newItemsOverallDiscountController.dispose();
    _takeawayDiscountController.dispose();
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
    for (final item in _takeawayPayments) {
      item.dispose();
    }
    for (final item in _newItems) {
      item.dispose();
    }
    _differenceNewItem.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isAccessRoleLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_activeRole == null) {
      return _buildAccessGate();
    }

    final contentTopPadding = MediaQuery.of(context).padding.top + 16;
    final appBarTitle = _isUser
        ? 'Orders'
        : switch (_selectedSection) {
            AppSection.orders => 'Orders',
            AppSection.estimateCalculator =>
              (_isEditingEstimate ? 'Edit Order' : 'New Order'),
            AppSection.advance => 'Advance',
            AppSection.actual => 'Actual',
            AppSection.items => 'Items',
            AppSection.billPreview => 'Bill Preview',
          };
    final appBarActions = <Widget>[
      if (_isAdmin && _selectedSection == AppSection.estimateCalculator)
        IconButton(
          onPressed: () => _saveEstimateOrder(stayOnEstimate: true),
          icon: const Icon(Icons.save_outlined),
          tooltip: _isEditingEstimate ? 'Update order' : 'Save order',
        ),
      if (_isAdmin && _selectedSection == AppSection.actual)
        IconButton(
          onPressed: () => _saveEstimateOrder(stayOnEstimate: true),
          icon: const Icon(Icons.save_outlined),
          tooltip: _isEditingEstimate ? 'Update order' : 'Save order',
        ),
      if (_isAdmin && _selectedSection == AppSection.billPreview)
        IconButton(
          onPressed: () => _saveEstimateOrder(stayOnEstimate: true),
          icon: const Icon(Icons.save_outlined),
          tooltip: _isEditingEstimate ? 'Update order' : 'Save order',
        ),
      if (_isAdmin && _selectedSection == AppSection.items)
        IconButton(
          onPressed: _openBhavScreen,
          icon: const Icon(Icons.settings_outlined),
          tooltip: 'Bhav',
        ),
      if (_isAdmin && _selectedSection == AppSection.items)
        IconButton(
          onPressed: () => _saveEstimateOrder(stayOnEstimate: true),
          icon: const Icon(Icons.save_outlined),
          tooltip: _isEditingEstimate ? 'Update order' : 'Save order',
        ),
      if (_isAdmin && _selectedSection == AppSection.advance)
        IconButton(
          onPressed: _saveAdvanceEntries,
          icon: const Icon(Icons.save_outlined),
          tooltip: 'Save advance entries',
        ),
      if (_isAdmin &&
          (_selectedSection == AppSection.orders ||
              _selectedSection == AppSection.estimateCalculator ||
              _selectedSection == AppSection.advance ||
              _selectedSection == AppSection.actual ||
              _selectedSection == AppSection.items ||
              _selectedSection == AppSection.billPreview))
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
      IconButton(
        onPressed: _signOut,
        icon: const Icon(Icons.logout_outlined),
        tooltip: 'Switch access',
      ),
    ];

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
          await _persistLocalState(syncImmediately: true);
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: _isAdmin && _selectedSection != AppSection.orders
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
              Text(appBarTitle),
            ],
          ),
          actions: appBarActions,
        ),
        floatingActionButton: _isAdmin && _selectedSection == AppSection.orders
            ? FloatingActionButton.extended(
                onPressed: _openAddOrderSheet,
                icon: const Icon(Icons.add),
                label: const Text('New order'),
              )
            : null,
        bottomNavigationBar: _isUser
            ? null
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_selectedSection == AppSection.billPreview)
                    _buildBillPreviewStickyBar(),
                  NavigationBar(
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
                ],
              ),
        body: _isUser
            ? _buildOrdersBody(contentTopPadding)
            : switch (_selectedSection) {
                AppSection.orders => _buildOrdersBody(contentTopPadding),
                AppSection.estimateCalculator => _buildEstimateCalculatorBody(
                  contentTopPadding,
                ),
                AppSection.advance => _buildAdvanceBody(contentTopPadding),
                AppSection.actual => _buildActualBody(contentTopPadding),
                AppSection.items => _buildItemsBody(contentTopPadding),
                AppSection.billPreview => _buildBillPreviewBody(
                  contentTopPadding,
                ),
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
    this.sourceTagId,
    bool? gstLockedOn,
    bool? gstEnabled,
    this.isDifferenceEntry = false,
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
       notesController = TextEditingController(text: notes ?? '') {
    this.gstLockedOn = gstLockedOn ?? false;
    this.gstEnabled = gstEnabled ?? true;
  }

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
      sourceTagId: json['sourceTagId'] as String?,
      gstLockedOn: _readJsonBool(json['gstLockedOn'], fallback: false),
      gstEnabled: _readJsonBool(json['gstEnabled'], fallback: true),
      isDifferenceEntry: _readJsonBool(
        json['isDifferenceEntry'],
        fallback: false,
      ),
      notes: json['notes'] as String? ?? '',
    );
  }

  static bool _readJsonBool(dynamic value, {required bool fallback}) {
    if (value is bool) {
      return value;
    }
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      if (normalized == 'true') {
        return true;
      }
      if (normalized == 'false') {
        return false;
      }
    }
    if (value is num) {
      return value != 0;
    }
    return fallback;
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
  String? sourceTagId;
  bool gstLockedOn = false;
  bool gstEnabled = true;
  final bool isDifferenceEntry;
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
      'sourceTagId': sourceTagId,
      'gstLockedOn': gstLockedOn,
      'gstEnabled': gstEnabled,
      'isDifferenceEntry': isDifferenceEntry,
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
    this.titleText,
    this.onEdit,
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
  final String? titleText;
  final VoidCallback? onEdit;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final decimalInput = [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))];
    final locksDifferenceWeight = item.isDifferenceEntry;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    titleText ?? 'New Item $index',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (onEdit != null)
                  IconButton(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined),
                    tooltip: 'Edit item',
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
                      readOnly: item.isDifferenceEntry,
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
                    isExpanded: true,
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
                    isExpanded: true,
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
                      readOnly: locksDifferenceWeight,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: decimalInput,
                      decoration: InputDecoration(
                        labelText: 'Gross Weight',
                        suffixText: 'g',
                        helperText: locksDifferenceWeight
                            ? 'Auto from Order Nett - Advance Nett'
                            : null,
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
                    readOnly: locksDifferenceWeight,
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
                        onChanged: item.gstLockedOn
                            ? null
                            : (value) {
                                item.gstEnabled = value;
                                onChanged();
                              },
                      ),
                    ],
                  ),
                  if (item.gstLockedOn)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'GST stays enabled for HUID items.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
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

class _NewItemEntryPage extends StatefulWidget {
  const _NewItemEntryPage({
    required this.title,
    required this.gold22Rate,
    required this.gold18Rate,
    required this.silverRate,
    required this.gstRate,
    this.initialData,
  });

  final String title;
  final double gold22Rate;
  final double gold18Rate;
  final double silverRate;
  final double gstRate;
  final Map<String, dynamic>? initialData;

  @override
  State<_NewItemEntryPage> createState() => _NewItemEntryPageState();
}

class _NewItemEntryPageState extends State<_NewItemEntryPage> {
  late final _NewItemDraft _draft;

  @override
  void initState() {
    super.initState();
    _draft = widget.initialData == null
        ? _NewItemDraft()
        : _NewItemDraft.fromJson(widget.initialData!);
  }

  @override
  void dispose() {
    _draft.dispose();
    super.dispose();
  }

  double _rateForCategory(String category) {
    switch (category) {
      case 'Gold22kt':
        return widget.gold22Rate;
      case 'Gold18kt':
        return widget.gold18Rate;
      case 'Silver':
        return widget.silverRate;
      default:
        return 0;
    }
  }

  double get _effectiveBhav =>
      _draft.bhav > 0 ? _draft.bhav : _rateForCategory(_draft.category);

  double get _baseAmount {
    final rate = _effectiveBhav;
    switch (_draft.makingType) {
      case 'FixRate':
        return _draft.makingCharge;
      case 'PerGram':
        return (rate + _draft.makingCharge) * _draft.netWeight;
      case 'Percentage':
        return (rate + (rate * (_draft.makingCharge / 100))) * _draft.netWeight;
      case 'TotalMaking':
        return (rate * _draft.netWeight) + _draft.makingCharge;
      default:
        return (rate * _draft.netWeight) + _draft.makingCharge;
    }
  }

  double get _gstAmount {
    if (!_draft.gstEnabled || _draft.makingType == 'FixRate') {
      return 0;
    }
    return _baseAmount * (widget.gstRate / 100);
  }

  double get _totalAmount => _baseAmount + _gstAmount + _draft.additionalCharge;

  void _save() {
    setState(() {
      _draft.showNameError = true;
      _draft.showWeightError = true;
    });
    if (_draft.nameController.text.trim().isEmpty ||
        _draft.grossWeight <= 0 ||
        _draft.netWeight <= 0) {
      return;
    }
    Navigator.of(context).pop(_draft.toJson());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back',
        ),
        title: Text(widget.title),
        actions: [
          IconButton(
            onPressed: _save,
            icon: const Icon(Icons.save_outlined),
            tooltip: 'Save',
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: _NewItemEditor(
                index: 1,
                item: _draft,
                titleText: 'New Item Details',
                effectiveBhav: _effectiveBhav,
                amount: _totalAmount,
                baseAmount: _baseAmount,
                gstAmount: _gstAmount,
                makingTypeOptions: _draft.category == 'Silver'
                    ? _OrdersDashboardState._silverMakingTypeOptions
                    : _OrdersDashboardState._goldMakingTypeOptions,
                onChanged: () {
                  setState(() {});
                },
                onCategoryChanged: (value) {
                  final options = value == 'Silver'
                      ? _OrdersDashboardState._silverMakingTypeOptions
                      : _OrdersDashboardState._goldMakingTypeOptions;
                  setState(() {
                    _draft.categoryController.text = value;
                    if (!options.contains(_draft.makingType)) {
                      _draft.makingTypeController.text = options.first;
                    }
                  });
                },
                onMakingTypeChanged: (value) {
                  setState(() {
                    _draft.makingTypeController.text = value;
                  });
                },
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: FilledButton.icon(
          onPressed: _save,
          icon: const Icon(Icons.save_outlined),
          label: const Text('Save'),
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
       amountController = TextEditingController(
         text: _formatIndianNumberInput(amountText ?? ''),
       ),
       rateController = TextEditingController(
         text: _formatIndianNumberInput(rateText ?? ''),
       ),
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

  double get amount => _parseFormattedDecimal(amountController.text);

  double get rate => _parseFormattedDecimal(rateController.text);

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
                    'Advance Entry $index',
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
                    inputFormatters: const [_IndianCurrencyInputFormatter()],
                    decoration: const InputDecoration(labelText: 'Amount'),
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
                  child: TextField(
                    controller: item.rateController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: const [_IndianCurrencyInputFormatter()],
                    decoration: const InputDecoration(
                      labelText: 'Rate22',
                      hintText: '-Unfix-',
                    ),
                    onChanged: (_) => onChanged(),
                  ),
                ),
                const SizedBox(width: 12),
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

class _TakeawayPaymentDraft {
  _TakeawayPaymentDraft({DateTime? date, AdvanceMode? mode, String? amountText})
    : _date = date ?? DateTime.now(),
      _mode = mode ?? AdvanceMode.cash,
      amountController = TextEditingController(
        text: _formatIndianNumberInput(amountText ?? ''),
      );

  factory _TakeawayPaymentDraft.fromJson(Map<String, dynamic> json) {
    return _TakeawayPaymentDraft(
      date: _dateTimeFromJson(json['date']) ?? DateTime.now(),
      mode: AdvanceMode.values.firstWhere(
        (value) => value.name == ((json['mode'] as String?) ?? ''),
        orElse: () => AdvanceMode.cash,
      ),
      amountText: json['amountText'] as String? ?? '',
    );
  }

  DateTime? _date;
  AdvanceMode? _mode;
  final TextEditingController amountController;

  DateTime get date => _date ?? DateTime.now();

  set date(DateTime value) {
    _date = value;
  }

  AdvanceMode get mode => _mode ?? AdvanceMode.cash;

  set mode(AdvanceMode value) {
    _mode = value;
  }

  double get amount => _parseFormattedDecimal(amountController.text);

  bool get isEmpty => amount == 0;

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'mode': mode.name,
      'amountText': amountController.text,
    };
  }

  void dispose() {
    amountController.dispose();
  }
}

class _TakeawayPaymentEditor extends StatelessWidget {
  const _TakeawayPaymentEditor({
    required this.index,
    required this.item,
    required this.onChanged,
    this.onRemove,
  });

  final int index;
  final _TakeawayPaymentDraft item;
  final VoidCallback onChanged;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 640;
        final fields = [
          _DateField(
            date: item.date,
            labelText: 'Date',
            onDateSelected: (selected) {
              item.date = selected;
              onChanged();
            },
          ),
          DropdownButtonFormField<AdvanceMode>(
            initialValue: item.mode,
            decoration: const InputDecoration(labelText: 'Mode'),
            items: AdvanceMode.values
                .map(
                  (mode) =>
                      DropdownMenuItem(value: mode, child: Text(mode.label)),
                )
                .toList(),
            onChanged: (value) {
              item.mode = value ?? AdvanceMode.cash;
              onChanged();
            },
          ),
          TextField(
            controller: item.amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: const [_IndianCurrencyInputFormatter()],
            decoration: const InputDecoration(labelText: 'Amount'),
            onChanged: (_) => onChanged(),
          ),
        ];

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Payment ${index + 1}',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (onRemove != null)
                    IconButton(
                      onPressed: onRemove,
                      icon: const Icon(Icons.delete_outline),
                      tooltip: 'Remove payment',
                    ),
                ],
              ),
              const SizedBox(height: 8),
              if (isCompact)
                Column(
                  children: [
                    fields[0],
                    const SizedBox(height: 12),
                    fields[1],
                    const SizedBox(height: 12),
                    fields[2],
                  ],
                )
              else
                Row(
                  children: [
                    Expanded(child: fields[0]),
                    const SizedBox(width: 12),
                    Expanded(child: fields[1]),
                    const SizedBox(width: 12),
                    Expanded(child: fields[2]),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }
}

class _AdvanceOldItemDraft {
  _AdvanceOldItemDraft({
    DateTime? date,
    String? itemName,
    String? returnRateText,
    String? advanceRateText,
    String? advanceMakingText,
    String? grossWeightText,
    String? lessWeightText,
    String? tanchText,
  }) : _date = date ?? DateTime.now(),
       itemNameController = TextEditingController(text: itemName ?? ''),
       returnRateController = TextEditingController(
         text: _formatIndianNumberInput(returnRateText ?? ''),
       ),
       advanceRateController = TextEditingController(
         text: _formatIndianNumberInput(advanceRateText ?? ''),
       ),
       advanceMakingController = TextEditingController(
         text: _formatIndianNumberInput(advanceMakingText ?? ''),
       ),
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
      advanceRateText: json['advanceRateText'] as String? ?? '',
      advanceMakingText: json['advanceMakingText'] as String? ?? '',
      grossWeightText: json['grossWeightText'] as String? ?? '',
      lessWeightText: json['lessWeightText'] as String? ?? '',
      tanchText: json['tanchText'] as String? ?? '',
    );
  }

  DateTime? _date;
  final TextEditingController itemNameController;
  final TextEditingController returnRateController;
  final TextEditingController advanceRateController;
  final TextEditingController advanceMakingController;
  final TextEditingController grossWeightController;
  final TextEditingController lessWeightController;
  final TextEditingController tanchController;

  DateTime get date => _date ?? DateTime.now();

  set date(DateTime value) {
    _date = value;
  }

  double get returnRate => _parseFormattedDecimal(returnRateController.text);

  double get advanceRate => _parseFormattedDecimal(advanceRateController.text);

  double get advanceMaking =>
      _parseFormattedDecimal(advanceMakingController.text);

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
      advanceRate == 0 &&
      advanceMaking == 0 &&
      grossWeight == 0 &&
      lessWeight == 0 &&
      tanch == 0;

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'itemName': itemNameController.text,
      'returnRateText': returnRateController.text,
      'advanceRateText': advanceRateController.text,
      'advanceMakingText': advanceMakingController.text,
      'grossWeightText': grossWeightController.text,
      'lessWeightText': lessWeightController.text,
      'tanchText': tanchController.text,
    };
  }

  void dispose() {
    itemNameController.dispose();
    returnRateController.dispose();
    advanceRateController.dispose();
    advanceMakingController.dispose();
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

  static final List<String> _tanchOptions = <String>[
    '1.0',
    ...List<String>.generate(
      70,
      (index) => '.${(99 - index).toString().padLeft(2, '0')}',
    ),
  ];

  String? _selectedTanchValue(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    if (_tanchOptions.contains(trimmed)) {
      return trimmed;
    }
    if (trimmed == '1' || trimmed == '1.0' || trimmed == '1.00') {
      return '1.0';
    }
    if (trimmed.startsWith('0.')) {
      final normalized = '.${trimmed.substring(2)}';
      if (_tanchOptions.contains(normalized)) {
        return normalized;
      }
    }
    return null;
  }

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
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: item.itemNameController,
                    inputFormatters: [_WordCapitalizeFormatter()],
                    decoration: const InputDecoration(labelText: 'Item Name'),
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
                    controller: item.returnRateController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: const [_IndianCurrencyInputFormatter()],
                    decoration: const InputDecoration(labelText: 'Return Bhav'),
                    onChanged: (_) => onChanged(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedTanchValue(
                      item.tanchController.text,
                    ),
                    decoration: const InputDecoration(labelText: 'Tanch'),
                    items: _tanchOptions
                        .map(
                          (value) => DropdownMenuItem(
                            value: value,
                            child: Text(value),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      item.tanchController.text = value ?? '';
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
                  child: TextField(
                    controller: item.grossWeightController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: decimalInput,
                    decoration: const InputDecoration(labelText: 'Gross'),
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
                    decoration: const InputDecoration(labelText: 'Less'),
                    onChanged: (_) => onChanged(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InputDecorator(
                    decoration: const InputDecoration(labelText: 'Nett'),
                    child: Text(_formatWeight3(item.nettWeight)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
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
                    controller: item.advanceRateController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: const [_IndianCurrencyInputFormatter()],
                    decoration: const InputDecoration(
                      labelText: 'Advance Rate',
                    ),
                    onChanged: (_) => onChanged(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: item.advanceMakingController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: const [_IndianCurrencyInputFormatter()],
                    decoration: const InputDecoration(
                      labelText: 'Advance Making',
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
