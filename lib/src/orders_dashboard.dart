part of '../main.dart';

class OrdersDashboard extends StatefulWidget {
  const OrdersDashboard({super.key});

  @override
  State<OrdersDashboard> createState() => _OrdersDashboardState();
}

class _OrdersDashboardState extends State<OrdersDashboard>
    with WidgetsBindingObserver {
  static const Duration _remoteRefreshInterval = Duration(seconds: 5);
  static const _ordersStorageKey = 'orders_dashboard.orders';
  static const _estimateStorageKey = 'orders_dashboard.estimate';
  static const _authSessionStorageKey = 'orders_dashboard.auth_session';
  static const _lastEmailStorageKey = 'orders_dashboard.last_email';
  static const _lockedEstimatePurity = '22K';
  static const _defaultEstimateWeightRange = '0';
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
  static const String _paymentUpiQrBase =
      'upi://pay?mode=02&pa=Q596211014@ybl&purpose=00&mc=0000&pn=PhonePeMerchant&orgid=180001';
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
      TextEditingController(text: _defaultEstimateWeightRange);
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
  final TextEditingController _newItemsAdditionalChargesController =
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
  Timer? _remoteRefreshTimer;
  bool _showEstimateNameError = false;
  bool _showEstimateMobileError = false;
  bool _showEstimateAlternateMobileError = false;
  bool _isRestoringLocalState = false;
  bool _isRatesLoading = false;
  bool _isTagScanning = false;
  bool _isAccessRoleLoading = true;
  bool _isSigningIn = false;
  bool _hideLoginPassword = true;
  bool _billPreviewGstEnabled = false;
  double _billPreviewLockedGstAddedAmount = 0;
  OrderStatus _estimateStatus = OrderStatus.pending;
  DateTime _estimateDate = DateTime.now();
  bool _estimateDateFollowsNow = true;
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
  DateTime? _lastLocalSavedAt;
  DateTime? _lastRemoteSyncedAt;
  bool _isRemoteSyncInProgress = false;
  bool _hasRemoteSyncError = false;
  bool _isRemoteRefreshInProgress = false;
  bool _isExitFlowActive = false;
  bool _allowImmediateAppExit = false;

  bool get _showsLiveEstimateClock =>
      _selectedSection == AppSection.estimateCalculator ||
      _selectedSection == AppSection.actual;
  bool get _isAdmin => _activeRole == AppAccessRole.admin;
  bool get _isUser =>
      _activeRole == AppAccessRole.user || _activeRole == AppAccessRole.staff;
  bool get _showAdminEditNavigation =>
      _isAdmin && _isEditingEstimate && _selectedSection != AppSection.orders;
  AppAccessRole? get _platformRequiredRole => _requiredAccessRoleForPlatform;

  bool _isRoleAllowedOnThisPlatform(AppAccessRole role) {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.windows) {
      return role == AppAccessRole.admin || role == AppAccessRole.staff;
    }
    final requiredRole = _platformRequiredRole;
    return requiredRole == null || requiredRole == role;
  }

  String get _accessGateTitle {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.windows) {
      return 'Admin / Staff Sign In';
    }
    return switch (_platformRequiredRole) {
      AppAccessRole.admin => 'Admin Sign In',
      AppAccessRole.staff => 'Staff Sign In',
      AppAccessRole.user => 'User Sign In',
      null => 'Sign In',
    };
  }

  String get _accessGateDescription {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.windows) {
      return 'This Windows build supports admin and staff accounts. Admin can manage, edit, and print orders. Staff can only view saved orders and open print preview from the Orders tab.';
    }
    return switch (_platformRequiredRole) {
      AppAccessRole.admin =>
        'This Windows build is the admin app. Sign in with an admin account to manage, edit, and print orders.',
      AppAccessRole.staff =>
        'This build is for staff accounts. Sign in with a staff account to view and print saved orders.',
      AppAccessRole.user =>
        'This Android and iOS build is for user accounts. Sign in with a user account to view and print saved orders.',
      null =>
        'Use your Firebase account to continue. Admin gets full access, and user accounts can view and print saved orders only.',
    };
  }

  String _platformRoleMismatchMessage() {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.windows) {
      return 'This Windows build only allows admin or staff accounts.';
    }
    final requiredRole = _platformRequiredRole;
    if (requiredRole == null) {
      return 'This account is not allowed on this device.';
    }
    if (requiredRole == AppAccessRole.admin) {
      return 'This Windows build only allows admin accounts. Sign in with an admin account.';
    }
    if (requiredRole == AppAccessRole.staff) {
      return 'This build only allows staff accounts. Sign in with a staff account.';
    }
    return 'Android and iOS builds only allow user accounts. Sign in with a user account on this device.';
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    HardwareKeyboard.instance.addHandler(_handleAppKeyEvent);
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
      if (!_showsLiveEstimateClock || !_estimateDateFollowsNow) {
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
    final localStore = await _appLocalStore;
    final lastEmail = localStore.getString(_lastEmailStorageKey);
    final savedLastEmail = (await lastEmail)?.trim() ?? '';
    if (savedLastEmail.isNotEmpty) {
      _loginEmailController.text = savedLastEmail;
    }
    final savedSessionJson = await localStore.getString(_authSessionStorageKey);
    if (savedSessionJson == null) {
      if (!mounted) {
        return;
      }
      setState(() {
        _authSession = null;
        _activeRole = null;
        _isAccessRoleLoading = false;
      });
      _stopRemoteRefreshLoop();
      return;
    }

    try {
      final savedSession = _AuthSession.fromJson(
        jsonDecode(savedSessionJson) as Map<String, dynamic>,
      );
      final refreshed = await _authService.refreshSession(savedSession);
      if (!_isRoleAllowedOnThisPlatform(refreshed.role)) {
        await localStore.remove(_authSessionStorageKey);
        if (!mounted) {
          return;
        }
        setState(() {
          _authSession = null;
          _activeRole = null;
          _accessError = _platformRoleMismatchMessage();
          _isAccessRoleLoading = false;
        });
        _stopRemoteRefreshLoop();
        return;
      }
      await localStore.setString(_lastEmailStorageKey, refreshed.email);
      await localStore.setString(
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
      _startRemoteRefreshLoop();
      await _restoreStateFromFirestore();
    } catch (_) {
      await localStore.remove(_authSessionStorageKey);
      if (!mounted) {
        return;
      }
      setState(() {
        _authSession = null;
        _activeRole = null;
        _isAccessRoleLoading = false;
      });
      _stopRemoteRefreshLoop();
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
      if (!_isRoleAllowedOnThisPlatform(session.role)) {
        if (!mounted) {
          return;
        }
        setState(() {
          _isSigningIn = false;
          _accessError = _platformRoleMismatchMessage();
        });
        return;
      }
      final localStore = await _appLocalStore;
      await localStore.setString(_lastEmailStorageKey, session.email);
      await localStore.setString(
        _authSessionStorageKey,
        jsonEncode(session.toJson()),
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _authSession = session;
        _activeRole = session.role;
        _isSigningIn = false;
        _accessError = null;
        _loginEmailController.text = session.email;
        _selectedSection = AppSection.orders;
        _selectedStatus = null;
      });
      _startRemoteRefreshLoop();
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
    _stopRemoteRefreshLoop();
    final localStore = await _appLocalStore;
    await localStore.remove(_authSessionStorageKey);
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
      _loginPasswordController.clear();
      _hideLoginPassword = true;
      _selectedSection = AppSection.orders;
      _selectedStatus = null;
      _lastSyncedOrdersJson = null;
      _lastSyncedDraftJson = null;
      _lastLocalSavedAt = null;
      _lastRemoteSyncedAt = null;
      _isRemoteSyncInProgress = false;
      _hasRemoteSyncError = false;
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
      _stopRemoteRefreshLoop();
      _persistDebounceTimer?.cancel();
      _persistLocalState();
    } else if (state == AppLifecycleState.resumed) {
      _startRemoteRefreshLoop();
      _refreshRemoteStateIfNeeded();
    }
  }

  @override
  Future<ui.AppExitResponse> didRequestAppExit() async {
    if (_allowImmediateAppExit) {
      return ui.AppExitResponse.exit;
    }
    final shouldExit = await _confirmAndPersistExit();
    return shouldExit ? ui.AppExitResponse.exit : ui.AppExitResponse.cancel;
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
      DateTime deliveryDeadline(DateTime? date) {
        if (date == null) {
          return DateTime(9999);
        }
        return DateTime(date.year, date.month, date.day, 23, 59, 59, 999);
      }

      switch (_selectedOrderSort) {
        case OrderSortOption.newest:
          return b.createdAt.compareTo(a.createdAt);
        case OrderSortOption.deliveryLatest:
          final now = DateTime.now();
          final aRemaining = deliveryDeadline(a.deliveryDate).difference(now);
          final bRemaining = deliveryDeadline(b.deliveryDate).difference(now);
          final deliveryCompare = aRemaining.compareTo(bRemaining);
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

  String get _selectedEstimateMakingOption =>
      _normalizeEstimateMakingText(_estimateMakingController.text);

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

  String get _saveStatusText {
    final localSavedAt = _lastLocalSavedAt;
    final remoteSyncedAt = _lastRemoteSyncedAt;
    final timeFormatter = DateFormat('HH:mm:ss');

    if (localSavedAt == null) {
      return _authSession == null
          ? 'Local save not started yet'
          : 'Waiting for first save';
    }

    final localText = 'Saved locally ${timeFormatter.format(localSavedAt)}';
    if (_authSession == null) {
      return '$localText | local only';
    }
    if (_isRemoteSyncInProgress) {
      return '$localText | syncing...';
    }
    if (_hasRemoteSyncError) {
      return '$localText | sync pending';
    }
    if (remoteSyncedAt != null) {
      return '$localText | synced ${timeFormatter.format(remoteSyncedAt)}';
    }
    return '$localText | sync pending';
  }

  Widget _buildSaveStatusBar() {
    final theme = Theme.of(context);
    final statusTextColor = theme.colorScheme.onPrimary;
    final statusColor = statusTextColor;
    final statusIcon = _hasRemoteSyncError
        ? Icons.cloud_off_outlined
        : _isRemoteSyncInProgress
        ? Icons.cloud_upload_outlined
        : Icons.cloud_done_outlined;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      alignment: Alignment.centerLeft,
      child: Row(
        children: [
          Icon(statusIcon, size: 16, color: statusColor),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              _saveStatusText,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: statusTextColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _normalizeEstimateMakingText(dynamic rawValue) {
    final raw = rawValue?.toString().trim() ?? '';
    if (raw.isEmpty) {
      return '15';
    }
    if (_estimateMakingOptions.contains(raw)) {
      return raw;
    }
    final parsed = double.tryParse(raw);
    if (parsed == null) {
      return '15';
    }
    final normalized = parsed == parsed.roundToDouble()
        ? parsed.toInt().toString()
        : parsed.toString();
    return _estimateMakingOptions.contains(normalized) ? normalized : '15';
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
        .fold<double>(
          0,
          (total, item) => total + (item.quantity * item.estimatedWeight),
        );
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
    final formattedWeight = _formatWeightFixed3(_truncateWeight3(startWeight));
    return '$formattedWeight gm - $formattedWeight gm';
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
      return '${_formatWeightFixed3(_truncateWeight3(startWeight))} gm - ${_formatWeightFixed3(_truncateWeight3(endWeight))} gm';
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
            gstApplied: item.gstApplied,
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
    return _roundCurrency2(
      _populatedNewItems.fold<double>(
            0,
            (total, item) =>
                total + _newItemBaseAmount(item) + item.additionalCharge,
          ) +
          _newItemsAdditionalCharges,
    );
  }

  double get _newItemsAdditionalCharges {
    final requested = _parseFormattedDecimal(
      _newItemsAdditionalChargesController.text,
    );
    return requested > 0 ? _roundCurrency2(requested) : 0;
  }

  double get _newItemsTotalGst {
    return _populatedNewItems.fold<double>(
      0,
      (total, item) => total + _newItemGstAmount(item),
    );
  }

  double get _newItemsTotalBeforeDiscount {
    return _roundCurrency2(
      _populatedNewItems.fold<double>(
            0,
            (total, item) => total + _newItemTotalAmount(item),
          ) +
          _newItemsAdditionalCharges,
    );
  }

  double get _newItemsOverallDiscount {
    final requested = _parseFormattedDecimal(
      _newItemsOverallDiscountController.text,
    );
    final capped = requested.clamp(0, _newItemsTotalBeforeDiscount);
    return _roundCurrency2(capped.toDouble());
  }

  double get _newItemsGrandTotal {
    final total = _newItemsTotalBeforeDiscount - _newItemsOverallDiscount;
    return total > 0 ? _roundCurrency2(total) : 0;
  }

  double get _takeawayDiscount {
    final requested = _parseFormattedDecimal(_takeawayDiscountController.text);
    final capped = requested.clamp(0, _takeawayBalanceAfterPayments);
    return _roundCurrency2(capped.toDouble());
  }

  double get _takeawayBalanceAfterPayments {
    final balance = _newItemsGrandTotal - _takeawayPaymentsTotal;
    return balance > 0 ? _roundCurrency2(balance) : 0;
  }

  double get _takeawayBaseFinalDueAmount {
    final balance = _takeawayBalanceAfterPayments - _takeawayDiscount;
    return balance > 0 ? _roundCurrency2(balance) : 0;
  }

  double get _takeawayPreGstRefundAmount {
    final refund =
        _takeawayPaymentsTotal + _takeawayDiscount - _newItemsGrandTotal;
    return refund > 0 ? _roundCurrency2(refund) : 0;
  }

  double get _takeawayGstAddedAmount {
    if (!_billPreviewGstEnabled) {
      return 0;
    }
    return _billPreviewLockedGstAddedAmount;
  }

  double get _takeawaySettlementTargetAmount {
    final target =
        _newItemsGrandTotal - _takeawayDiscount + _takeawayGstAddedAmount;
    return target > 0 ? _roundCurrency2(target) : 0;
  }

  double get _takeawayFinalDueAmount {
    final due = _takeawaySettlementTargetAmount - _takeawayPaymentsTotal;
    return due > 0 ? _roundCurrency2(due) : 0;
  }

  double get _takeawayRefundAmount {
    final refund = _takeawayPaymentsTotal - _takeawaySettlementTargetAmount;
    return refund > 0 ? _roundCurrency2(refund) : 0;
  }

  bool get _canApplyBillPreviewGst {
    return _billPreviewGstEnabled ||
        (_takeawayPreGstRefundAmount <= 0 && _takeawayBaseFinalDueAmount > 0);
  }

  double get _billPreviewDisplayedDueAmount {
    if (_takeawayRefundAmount > 0) {
      return _takeawayRefundAmount;
    }
    return _takeawayFinalDueAmount;
  }

  void _setBillPreviewGstEnabled(bool value) {
    if (value) {
      if (!_canApplyBillPreviewGst || _billPreviewGstEnabled) {
        return;
      }
      _billPreviewLockedGstAddedAmount = _roundCurrency2(
        _takeawayBaseFinalDueAmount * 0.03,
      );
      _billPreviewGstEnabled = _billPreviewLockedGstAddedAmount > 0;
      return;
    }
    _billPreviewGstEnabled = false;
    _billPreviewLockedGstAddedAmount = 0;
  }

  bool get _canGenerateTakeawayPaymentQr {
    return _takeawayRefundAmount <= 0 && _billPreviewDisplayedDueAmount > 0;
  }

  String _buildPaymentUpiQr(double amount, String note) {
    final normalized = amount.toStringAsFixed(2);
    final encodedNote = Uri.encodeComponent(note);
    return '$_paymentUpiQrBase&am=$normalized&tn=$encodedNote&cu=INR';
  }

  List<double> _splitPaymentQrAmounts(double amount) {
    final chunks = <double>[];
    double remaining = _roundCurrency2(amount);
    while (remaining > 100000) {
      chunks.add(100000);
      remaining = _roundCurrency2(remaining - 100000);
    }
    if (remaining > 0) {
      chunks.add(remaining);
    }
    return chunks;
  }

  String _paymentQrNote(int splitIndex, int totalSplits) {
    final customerName = _estimateCustomerNameController.text.trim();
    final baseNote = customerName.isEmpty
        ? 'Order payment'
        : '$customerName order payment';
    if (totalSplits <= 1) {
      return baseNote;
    }
    return '$baseNote ${splitIndex + 1}/$totalSplits';
  }

  void _showTakeawayPaymentQrDialog() {
    if (!_canGenerateTakeawayPaymentQr) {
      return;
    }
    final totalAmount = _billPreviewDisplayedDueAmount;
    final splitAmounts = _splitPaymentQrAmounts(totalAmount);
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final theme = Theme.of(dialogContext);
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 24,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 440,
              maxHeight: MediaQuery.of(dialogContext).size.height * 0.85,
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Generate Payment QR',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        icon: const Icon(Icons.close),
                        tooltip: 'Close',
                      ),
                    ],
                  ),
                  Text(
                    'Final Due Amount',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatCurrency(totalAmount),
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: Colors.green.shade700,
                    ),
                  ),
                  if (splitAmounts.length > 1) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Split into multiple QR codes because UPI supports up to 100000.00 per payment.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Flexible(
                    child: SingleChildScrollView(
                      child: Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        alignment: WrapAlignment.center,
                        children: List.generate(splitAmounts.length, (index) {
                          final splitAmount = splitAmounts[index];
                          final note = _paymentQrNote(
                            index,
                            splitAmounts.length,
                          );
                          return Container(
                            width: 240,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerLowest,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: theme.colorScheme.outlineVariant,
                              ),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  splitAmounts.length == 1
                                      ? 'Scan to pay'
                                      : 'QR ${index + 1}',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: QrImageView(
                                    data: _buildPaymentUpiQr(splitAmount, note),
                                    size: 180,
                                    backgroundColor: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  _formatCurrency(splitAmount),
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SelectableText(
                    'UPI ID: Q596211014@ybl',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    icon: const Icon(Icons.done),
                    label: const Text('Close'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
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
    ]) {
      controller.addListener(_schedulePersistence);
    }
  }

  void _attachNewItemFieldListeners() {
    for (final controller in [
      _newItemsGold22RateController,
      _newItemsGold18RateController,
      _newItemsSilverRateController,
      _newItemsAdditionalChargesController,
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

  void _scheduleFirestoreSync() {
    if (_authSession == null || _isRestoringLocalState) {
      return;
    }

    _firestoreSyncDebounceTimer?.cancel();
    _firestoreSyncDebounceTimer = Timer(const Duration(milliseconds: 900), () {
      if (_authSession == null ||
          _isRestoringLocalState ||
          _isRemoteSyncInProgress ||
          _isRemoteRefreshInProgress) {
        return;
      }
      _syncStateToFirestore();
    });
  }

  bool get _hasPendingLocalChanges {
    if (_authSession == null || _isRestoringLocalState) {
      return false;
    }
    return _serializeOrdersJson() != _lastSyncedOrdersJson ||
        _serializeDraftJson() != _lastSyncedDraftJson;
  }

  void _startRemoteRefreshLoop() {
    _stopRemoteRefreshLoop();
    if (_authSession == null) {
      return;
    }
    _remoteRefreshTimer = Timer.periodic(_remoteRefreshInterval, (_) {
      _refreshRemoteStateIfNeeded();
    });
  }

  void _stopRemoteRefreshLoop() {
    _remoteRefreshTimer?.cancel();
    _remoteRefreshTimer = null;
  }

  String _ordersSnapshotJson(List<Order> orders) {
    return jsonEncode(orders.map((order) => order.toJson()).toList());
  }

  Future<void> _persistSnapshotsLocally({
    required String ordersJson,
    String? draftJson,
  }) async {
    final localStore = await _appLocalStore;
    await localStore.setString(_ordersStorageKey, ordersJson);
    if (draftJson == null) {
      await localStore.remove(_estimateStorageKey);
    } else {
      await localStore.setString(_estimateStorageKey, draftJson);
    }
  }

  bool _setControllerTextIfChanged(
    TextEditingController controller,
    String nextText,
  ) {
    if (controller.text == nextText) {
      return false;
    }
    controller.text = nextText;
    return true;
  }

  bool _applyRatesSnapshot(_AppRates rates) {
    var changed = false;
    changed =
        _setControllerTextIfChanged(
          _newItemsGold22RateController,
          _formatRateControllerText(rates.gold22Rate),
        ) ||
        changed;
    changed =
        _setControllerTextIfChanged(
          _newItemsGold18RateController,
          _formatRateControllerText(rates.gold18Rate),
        ) ||
        changed;
    changed =
        _setControllerTextIfChanged(
          _newItemsSilverRateController,
          _formatRateControllerText(rates.silverRate),
        ) ||
        changed;

    if (_ratesGold24Rate != rates.gold24Rate ||
        _ratesUpdatedAt != rates.updatedAt ||
        _ratesUpdatedByEmail != rates.updatedByEmail ||
        _ratesSyncedAt == null) {
      changed = true;
      _ratesGold24Rate = rates.gold24Rate;
      _ratesUpdatedAt = rates.updatedAt;
      _ratesUpdatedByEmail = rates.updatedByEmail;
      _ratesSyncedAt = DateTime.now();
    } else {
      _ratesSyncedAt = DateTime.now();
    }

    return changed;
  }

  String _serializeOrdersJson() {
    return jsonEncode(_orders.map((order) => order.toJson()).toList());
  }

  void _applySavedOrdersJson(String encodedOrders) {
    final decoded = jsonDecode(encodedOrders);
    if (decoded is! List) {
      return;
    }

    _orders
      ..clear()
      ..addAll(
        decoded.whereType<Map>().map(
          (order) => Order.fromJson(Map<String, dynamic>.from(order)),
        ),
      );
  }

  Map<String, dynamic> _buildDraftStateMap() {
    return {
      'selectedSection': _selectedSection.name,
      'selectedStatus': _selectedStatus?.name,
      'selectedOrderSort': _selectedOrderSort.name,
      'searchQuery': _searchQuery,
      'purity': _estimatePurityController.text,
      'gst': _estimateGstController.text,
      'making': _estimateMakingController.text,
      'weightRange': _estimateWeightRangeController.text,
      'customerName': _estimateCustomerNameController.text,
      'customerMobile': _estimateCustomerMobileController.text,
      'alternateMobile': _estimateAlternateMobileController.text,
      'status': _estimateStatus.name,
      'estimateDate': _estimateDate.toIso8601String(),
      'estimateDateAutoSync': _estimateDateFollowsNow,
      'deliveryDate': _estimateDeliveryDate.toIso8601String(),
      'advanceItems': _advanceItems.map((item) => item.toJson()).toList(),
      'advanceOldItems': _advanceOldItems.map((item) => item.toJson()).toList(),
      'takeawayPayments': _takeawayPayments
          .map((item) => item.toJson())
          .toList(),
      'newItemsGold22Rate': _newItemsGold22RateController.text,
      'newItemsGold18Rate': _newItemsGold18RateController.text,
      'newItemsSilverRate': _newItemsSilverRateController.text,
      'newItemsAdditionalCharges': _newItemsAdditionalChargesController.text,
      'newItemsOverallDiscount': _newItemsOverallDiscountController.text,
      'takeawayDiscount': _takeawayDiscountController.text,
      'billPreviewGstEnabled': _billPreviewGstEnabled,
      'billPreviewLockedGstAddedAmount': _billPreviewLockedGstAddedAmount,
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

    if (mounted) {
      setState(() {
        _isRemoteSyncInProgress = true;
        _hasRemoteSyncError = false;
      });
    }

    try {
      await Future.wait(writes);
      _lastSyncedOrdersJson = nextOrdersJson;
      _lastSyncedDraftJson = nextDraftJson;
      if (mounted) {
        setState(() {
          _isRemoteSyncInProgress = false;
          _hasRemoteSyncError = false;
          _lastRemoteSyncedAt = DateTime.now();
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isRemoteSyncInProgress = false;
          _hasRemoteSyncError = true;
        });
      }
    }
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
    final localStore = await _appLocalStore;
    await localStore.setString(_ordersStorageKey, ordersJson);
    await localStore.setString(_estimateStorageKey, draftJson);
    if (mounted) {
      setState(() {
        _lastLocalSavedAt = DateTime.now();
      });
    }
    if (syncImmediately) {
      await _syncStateToFirestore(ordersJson: ordersJson, draftJson: draftJson);
    } else {
      _scheduleFirestoreSync();
    }
  }

  Future<void> _refreshRemoteStateIfNeeded() async {
    final session = _authSession;
    if (session == null ||
        _isRestoringLocalState ||
        _isRemoteSyncInProgress ||
        _isRemoteRefreshInProgress ||
        _hasPendingLocalChanges) {
      return;
    }

    _isRemoteRefreshInProgress = true;
    try {
      final results = await Future.wait<dynamic>([
        _appSyncService.fetchOrders(idToken: session.idToken),
        _appSyncService.fetchDraft(idToken: session.idToken, uid: session.uid),
        _ratesRepository.fetchRates(),
      ]);
      if (!mounted || _authSession?.uid != session.uid) {
        return;
      }

      final remoteOrders = results[0] as List<Order>;
      final remoteDraft = results[1] as Map<String, dynamic>?;
      final rates = results[2] as _AppRates;
      final remoteOrdersJson = _ordersSnapshotJson(remoteOrders);
      final remoteDraftJson = remoteDraft == null
          ? null
          : jsonEncode(remoteDraft);
      final shouldApplyOrders = remoteOrdersJson != _lastSyncedOrdersJson;
      final shouldApplyDraft =
          remoteDraftJson != null && remoteDraftJson != _lastSyncedDraftJson;

      if (shouldApplyOrders || shouldApplyDraft) {
        _isRestoringLocalState = true;
        setState(() {
          if (shouldApplyOrders) {
            _orders
              ..clear()
              ..addAll(remoteOrders);
          }
          if (shouldApplyDraft && remoteDraft != null) {
            _applySavedDraftMap(remoteDraft);
          }
          _lastLocalSavedAt = DateTime.now();
          _lastRemoteSyncedAt = DateTime.now();
          _hasRemoteSyncError = false;
        });
        _lastSyncedOrdersJson = remoteOrdersJson;
        if (shouldApplyDraft) {
          _lastSyncedDraftJson = remoteDraftJson;
        }
        await _persistSnapshotsLocally(
          ordersJson: remoteOrdersJson,
          draftJson: shouldApplyDraft ? remoteDraftJson : _serializeDraftJson(),
        );
        _isRestoringLocalState = false;
      }

      if (!mounted || _authSession?.uid != session.uid) {
        return;
      }

      var ratesChanged = false;
      setState(() {
        ratesChanged = _applyRatesSnapshot(rates);
      });
      if (ratesChanged) {
        _schedulePersistence();
      }
    } catch (_) {
      // Keep the last known local state; the status bar already reflects sync issues.
    } finally {
      _isRemoteRefreshInProgress = false;
      _isRestoringLocalState = false;
    }
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

      var changed = false;
      setState(() {
        changed = _applyRatesSnapshot(rates);
      });
      if (changed) {
        _schedulePersistence();
      }

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
    if (!_supportsQrScanning) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'QR scanning is not available on ${defaultTargetPlatform.name}. Use New Item instead.',
          ),
        ),
      );
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

    final savedSection = decodedEstimate['selectedSection'] as String?;
    _selectedSection = _isUser
        ? AppSection.orders
        : AppSection.values.firstWhere(
            (section) => section.name == savedSection,
            orElse: () => AppSection.orders,
          );

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
    _estimateMakingController.text = _normalizeEstimateMakingText(
      decodedEstimate['making'],
    );
    final restoredWeightRange =
        decodedEstimate['weightRange'] as String? ??
        _defaultEstimateWeightRange;
    _estimateWeightRangeController.text = restoredWeightRange.trim().isEmpty
        ? _defaultEstimateWeightRange
        : restoredWeightRange;
    _estimateCustomerNameController.text =
        decodedEstimate['customerName'] as String? ?? '';
    _estimateCustomerMobileController.text =
        decodedEstimate['customerMobile'] as String? ?? '';
    _estimateAlternateMobileController.text =
        decodedEstimate['alternateMobile'] as String? ?? '';
    _searchQuery = decodedEstimate['searchQuery'] as String? ?? '';
    _searchController.text = _searchQuery;
    _newItemsGold22RateController.text =
        decodedEstimate['newItemsGold22Rate'] as String? ?? '';
    _newItemsGold18RateController.text =
        decodedEstimate['newItemsGold18Rate'] as String? ?? '';
    _newItemsSilverRateController.text =
        decodedEstimate['newItemsSilverRate'] as String? ?? '';
    _newItemsAdditionalChargesController.text =
        decodedEstimate['newItemsAdditionalCharges'] as String? ?? '';
    _newItemsOverallDiscountController.text =
        decodedEstimate['newItemsOverallDiscount'] as String? ?? '';
    _takeawayDiscountController.text =
        decodedEstimate['takeawayDiscount'] as String? ?? '';
    _billPreviewGstEnabled =
        decodedEstimate['billPreviewGstEnabled'] as bool? ?? false;
    _billPreviewLockedGstAddedAmount =
        (decodedEstimate['billPreviewLockedGstAddedAmount'] as num?)
            ?.toDouble() ??
        0;
    if (_billPreviewGstEnabled && _billPreviewLockedGstAddedAmount <= 0) {
      _billPreviewGstEnabled = false;
    }
    _estimateStatus = _orderStatusFromName(
      decodedEstimate['status'] as String? ?? OrderStatus.pending.name,
    );
    _estimateDate =
        _dateTimeFromJson(decodedEstimate['estimateDate']) ?? DateTime.now();
    _estimateDateFollowsNow =
        decodedEstimate['estimateDateAutoSync'] as bool? ?? true;
    if (_estimateDateFollowsNow) {
      _estimateDate = DateTime.now();
    }
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
        _lastLocalSavedAt = DateTime.now();
        if (hasRemoteOrders || hasRemoteDraft) {
          _lastRemoteSyncedAt = DateTime.now();
          _hasRemoteSyncError = false;
        }
      });
      _lastSyncedOrdersJson = hasRemoteOrders
          ? jsonEncode(remoteOrders.map((order) => order.toJson()).toList())
          : null;
      _lastSyncedDraftJson = hasRemoteDraft ? jsonEncode(remoteDraft) : null;
    } catch (_) {
      return;
    } finally {
      _isRestoringLocalState = false;
    }

    await _persistLocalState();
  }

  Future<void> _restoreLocalState() async {
    final localStore = await _appLocalStore;
    final savedOrdersJson = await localStore.getString(_ordersStorageKey);
    final savedDraftJson = await localStore.getString(_estimateStorageKey);
    if (savedOrdersJson == null && savedDraftJson == null) {
      return;
    }

    try {
      _isRestoringLocalState = true;
      if (!mounted) {
        return;
      }
      setState(() {
        if (savedOrdersJson != null && savedOrdersJson.trim().isNotEmpty) {
          _applySavedOrdersJson(savedOrdersJson);
        }
        if (savedDraftJson != null && savedDraftJson.trim().isNotEmpty) {
          final decodedDraft = jsonDecode(savedDraftJson);
          if (decodedDraft is Map<String, dynamic>) {
            _applySavedDraftMap(decodedDraft);
          } else if (decodedDraft is Map) {
            _applySavedDraftMap(Map<String, dynamic>.from(decodedDraft));
          }
        }
        _lastLocalSavedAt = DateTime.now();
      });
    } catch (_) {
      await localStore.remove(_ordersStorageKey);
      await localStore.remove(_estimateStorageKey);
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
    _estimateDateFollowsNow = true;
    _estimateDeliveryDate = DateTime.now();
    _estimatePurityController.text = _lockedEstimatePurity;
    _estimateGstController.text = '3';
    _estimateMakingController.text = _normalizeEstimateMakingText('15');
    _estimateWeightRangeController.text = _defaultEstimateWeightRange;
    _estimateCustomerNameController.clear();
    _estimateCustomerMobileController.clear();
    _estimateAlternateMobileController.clear();
    _newItemsAdditionalChargesController.clear();
    _newItemsOverallDiscountController.clear();
    _takeawayDiscountController.clear();
    _showEstimateNameError = false;
    _showEstimateMobileError = false;
    _showEstimateAlternateMobileError = false;
    _resetDifferenceNewItem();
    _billPreviewGstEnabled = false;
    _billPreviewLockedGstAddedAmount = 0;
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
    _estimateDate = _estimateOrderDateFromOrder(order);
    _estimateDateFollowsNow = false;
    _estimateDeliveryDate = order.deliveryDate ?? DateTime.now();
    _estimatePurityController.text = _lockedEstimatePurity;
    _estimateGstController.text = (order.estimateGst ?? 3).toString();
    _estimateMakingController.text = _normalizeEstimateMakingText(
      order.estimateMaking,
    );
    _estimateWeightRangeController.text =
        (order.estimateWeightRange?.trim().isNotEmpty ?? false)
        ? order.estimateWeightRange!.trim()
        : _defaultEstimateWeightRange;
    _estimateCustomerNameController.text = order.customer;
    _estimateCustomerMobileController.text = order.customerPhone ?? '';
    _estimateAlternateMobileController.text = order.altCustomerPhone ?? '';
    _newItemsAdditionalChargesController.text =
        order.newItemsAdditionalCharges > 0
        ? _formatIndianNumberInput(
            order.newItemsAdditionalCharges.toStringAsFixed(2),
          )
        : '';
    _newItemsOverallDiscountController.text = order.newItemsOverallDiscount > 0
        ? _formatIndianNumberInput(
            order.newItemsOverallDiscount.toStringAsFixed(2),
          )
        : '';
    _takeawayDiscountController.text = order.takeawayDiscount > 0
        ? _formatIndianNumberInput(order.takeawayDiscount.toStringAsFixed(2))
        : '';
    _showEstimateNameError = false;
    _showEstimateMobileError = false;
    _showEstimateAlternateMobileError = false;
    _estimateStatus = order.status;
    _resetDifferenceNewItem();
    _billPreviewGstEnabled = false;
    _billPreviewLockedGstAddedAmount = 0;

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
                      gstApplied: payment.gstApplied,
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

  DateTime _estimateOrderDateFromOrder(Order order) {
    if (order.items.isNotEmpty) {
      return order.items.first.date;
    }
    return order.createdAt;
  }

  DateTime _mergeEstimateDateWithCurrentTime(DateTime selectedDate) {
    return DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      _estimateDate.hour,
      _estimateDate.minute,
      _estimateDate.second,
      _estimateDate.millisecond,
      _estimateDate.microsecond,
    );
  }

  void _setEstimateDate(DateTime selectedDate) {
    setState(() {
      _estimateDate = _mergeEstimateDateWithCurrentTime(selectedDate);
      _estimateDateFollowsNow = false;
    });
    _schedulePersistence();
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

  void _saveEstimateOrder({
    bool stayOnEstimate = false,
    bool syncImmediately = false,
  }) async {
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
      newItemsAdditionalCharges: _newItemsAdditionalCharges,
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
        _selectedOrderSort = OrderSortOption.newest;
      }
    });
    await _persistLocalState(syncImmediately: syncImmediately);
    if (!mounted) {
      return;
    }

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
        duration: const Duration(seconds: 5),
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
    unawaited(
      Future<void>.delayed(const Duration(seconds: 5), () {
        controller.close();
      }),
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
      newItemsAdditionalCharges: _newItemsAdditionalCharges,
      newItemsSubtotal: _newItemsSubtotal,
      newItemsTotalGst: _newItemsTotalGst,
      newItemsOverallDiscount: _newItemsOverallDiscount,
      newItemsGrandTotal: _newItemsGrandTotal,
      takeawayPayments: _populatedTakeawayPayments,
      takeawayPaymentsTotal: _takeawayPaymentsTotal,
      takeawayBalanceAfterPayments: _takeawayBalanceAfterPayments,
      takeawayDiscount: _takeawayDiscount,
      takeawayGstAddedAmount: _takeawayGstAddedAmount,
      takeawayRefundAmount: _takeawayRefundAmount,
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
            gstApplied: payment.gstApplied,
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
    final advanceNetWeight = _truncateWeight3(
      order.advancePayments.fold<double>(
            0,
            (sum, payment) => sum + _truncateWeight3(payment.weight),
          ) +
          order.oldItemReturns.fold<double>(
            0,
            (sum, item) => sum + _truncateWeight3(item.advanceWeight),
          ),
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
    final takeawayRefundAmount =
        (takeawayPaymentsTotal + takeawayDiscount - order.total)
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
      newItemsAdditionalCharges: order.newItemsAdditionalCharges,
      newItemsSubtotal: 0,
      newItemsTotalGst: 0,
      newItemsOverallDiscount: order.newItemsOverallDiscount,
      newItemsGrandTotal: order.total,
      takeawayPayments: takeawayDrafts,
      takeawayPaymentsTotal: takeawayPaymentsTotal,
      takeawayBalanceAfterPayments: takeawayBalanceAfterPayments,
      takeawayDiscount: takeawayDiscount,
      takeawayGstAddedAmount: 0,
      takeawayRefundAmount: takeawayRefundAmount,
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

  bool _stepBackAdminSection() {
    final previousSection = switch (_selectedSection) {
      AppSection.billPreview => AppSection.items,
      AppSection.items => AppSection.actual,
      AppSection.actual => AppSection.advance,
      AppSection.advance => AppSection.estimateCalculator,
      AppSection.estimateCalculator => AppSection.orders,
      AppSection.orders => null,
    };
    if (previousSection == null) {
      return false;
    }
    setState(() {
      _selectedSection = previousSection;
      if (previousSection == AppSection.orders) {
        _selectedStatus = null;
      }
    });
    _schedulePersistence();
    return true;
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

  void _resetAdvanceEntry(int index) {
    setState(() {
      final replacement = _AdvanceValuationDraft();
      final removed = _advanceItems[index];
      _advanceItems[index] = replacement;
      removed.dispose();
      _attachAdvanceItemListeners(replacement);
    });
    _schedulePersistence();
  }

  void _resetAdvanceOldItemEntry(int index) {
    setState(() {
      final replacement = _AdvanceOldItemDraft();
      final removed = _advanceOldItems[index];
      _advanceOldItems[index] = replacement;
      removed.dispose();
      _attachAdvanceOldItemListeners(replacement);
    });
    _schedulePersistence();
  }

  Future<void> _saveAdvanceEntries({bool syncImmediately = false}) async {
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
            newItemsAdditionalCharges: existingOrder.newItemsAdditionalCharges,
            newItemsOverallDiscount: existingOrder.newItemsOverallDiscount,
            takeawayDiscount: existingOrder.takeawayDiscount,
          );
        }
      });
    }
    _persistDebounceTimer?.cancel();
    await _persistLocalState(syncImmediately: syncImmediately);
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

  Future<void> _syncOrdersPageState() async {
    if (_isRemoteSyncInProgress) {
      return;
    }
    _persistDebounceTimer?.cancel();
    await _persistLocalState(syncImmediately: true);
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _hasRemoteSyncError ? 'Cloud sync failed' : 'Synced successfully',
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
            'Exit the application? Any unsaved changes will be synced before the app closes.',
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

  Future<void> _waitForRemoteSyncToFinish() async {
    while (_isRemoteSyncInProgress) {
      await Future<void>.delayed(const Duration(milliseconds: 120));
    }
  }

  Future<bool> _syncBeforeExit() async {
    _persistDebounceTimer?.cancel();
    if (_authSession == null) {
      await _persistLocalState();
      return true;
    }
    await _waitForRemoteSyncToFinish();
    await _persistLocalState(syncImmediately: true);
    await _waitForRemoteSyncToFinish();
    return !_hasRemoteSyncError;
  }

  Future<T> _runWithExitSyncDialog<T>(Future<T> Function() action) async {
    final rootNavigator = Navigator.of(context, rootNavigator: true);
    showDialog<void>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: false,
      builder: (progressContext) {
        return const PopScope(
          canPop: false,
          child: AlertDialog(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2.4),
                ),
                SizedBox(width: 16),
                Expanded(child: Text('Syncing data before closing...')),
              ],
            ),
          ),
        );
      },
    );
    await Future<void>.delayed(Duration.zero);
    try {
      return await action();
    } finally {
      if (rootNavigator.mounted && rootNavigator.canPop()) {
        rootNavigator.pop();
      }
    }
  }

  Future<bool> _confirmAndPersistExit() async {
    final shouldExit = await _confirmExitApp();
    if (!shouldExit) {
      return false;
    }
    final synced = await _runWithExitSyncDialog(_syncBeforeExit);
    if (!synced && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cloud sync failed. Please try again before closing.'),
        ),
      );
    }
    return synced;
  }

  bool _isEditableTextFocused() {
    final focusContext = FocusManager.instance.primaryFocus?.context;
    if (focusContext == null) {
      return false;
    }
    if (focusContext.widget is EditableText) {
      return true;
    }
    return focusContext.findAncestorWidgetOfExactType<EditableText>() != null;
  }

  bool _isDashboardRouteCurrent() {
    final currentRoute = ModalRoute.of(context);
    return currentRoute?.isCurrent == true;
  }

  Future<void> _handleExitShortcut() async {
    if (_isEditableTextFocused()) {
      return;
    }
    if (!_isDashboardRouteCurrent()) {
      return;
    }
    await _runExitFlow();
  }

  Future<void> _runExitFlow({bool onlyFromOrders = false}) async {
    if (_isExitFlowActive) {
      return;
    }
    if (onlyFromOrders && _selectedSection != AppSection.orders) {
      return;
    }
    final currentRoute = ModalRoute.of(context);
    if (currentRoute?.isCurrent != true) {
      return;
    }
    _isExitFlowActive = true;
    try {
      final shouldExit = await _confirmAndPersistExit();
      if (shouldExit) {
        await _requestAppClose();
      }
    } finally {
      _isExitFlowActive = false;
    }
  }

  Future<void> _requestAppClose() async {
    final isDesktopPlatform =
        !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.windows ||
            defaultTargetPlatform == TargetPlatform.macOS ||
            defaultTargetPlatform == TargetPlatform.linux);
    if (isDesktopPlatform) {
      await ServicesBinding.instance.exitApplication(ui.AppExitType.required);
      return;
    }
    _allowImmediateAppExit = true;
    try {
      await SystemNavigator.pop();
    } finally {
      _allowImmediateAppExit = false;
    }
  }

  Future<void> _handleEscapeShortcut() async {
    if (!_isDashboardRouteCurrent()) {
      return;
    }
    if (_stepBackAdminSection()) {
      return;
    }
    await _runExitFlow(onlyFromOrders: true);
  }

  bool _handleAppKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) {
      return false;
    }
    if (!_isDashboardRouteCurrent()) {
      return false;
    }
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      unawaited(_handleEscapeShortcut());
      return true;
    }
    if (event.logicalKey == LogicalKeyboardKey.keyQ) {
      if (_isEditableTextFocused()) {
        return false;
      }
      unawaited(_handleExitShortcut());
      return true;
    }
    return false;
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
                                _schedulePersistence();
                              },
                              tooltip: 'Clear search',
                            ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                      _schedulePersistence();
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
                                option.label,
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
            Row(
              children: [
                Text(
                  'Live orders',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    _filteredOrders.length.toString(),
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
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
                    onPrint: () => _openCombinedBillPrintPreviewForOrder(order),
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 1100;
        final horizontalPadding = isDesktop ? 24.0 : 16.0;

        return SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              contentTopPadding,
              horizontalPadding,
              32,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: isDesktop ? 1480 : 920),
                child: isDesktop
                    ? _buildEstimateCalculatorDesktopLayout()
                    : _buildEstimateCalculatorMobileLayout(),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEstimateCalculatorMobileLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildEstimateDetailsCard(isDesktop: false),
        const SizedBox(height: 20),
        _buildEstimatePricingRow(spacing: 8),
        const SizedBox(height: 20),
        _buildEstimateItemsSection(isDesktop: false),
        const SizedBox(height: 12),
        _buildEstimateActionButtons(isDesktop: false),
      ],
    );
  }

  Widget _buildEstimateCalculatorDesktopLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildEstimateDetailsCard(isDesktop: true),
              const SizedBox(height: 20),
              _buildEstimateItemsSection(isDesktop: true),
            ],
          ),
        ),
        const SizedBox(width: 24),
        SizedBox(width: 360, child: _buildEstimateDesktopSummaryCard()),
      ],
    );
  }

  Widget _buildEstimateDetailsCard({required bool isDesktop}) {
    final deliveryDateColor = Theme.of(context).colorScheme.tertiary;
    final titleStyle = Theme.of(
      context,
    ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800);

    final nameField = TextField(
      focusNode: _estimateCustomerNameFocusNode,
      controller: _estimateCustomerNameController,
      decoration: InputDecoration(
        labelText: 'Name',
        errorText: _estimateNameError,
      ),
      onChanged: (_) => setState(() {}),
    );
    final mobileField = TextField(
      focusNode: _estimateCustomerMobileFocusNode,
      controller: _estimateCustomerMobileController,
      keyboardType: TextInputType.phone,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
        LengthLimitingTextInputFormatter(10),
      ],
      decoration: InputDecoration(
        labelText: 'Whatsapp Number',
        errorText: _estimateMobileError,
      ),
      onChanged: (_) => setState(() {}),
    );
    final purityField = TextField(
      controller: _estimatePurityController,
      decoration: const InputDecoration(labelText: 'Purity', isDense: true),
      enabled: false,
    );
    final makingField = DropdownButtonFormField<String>(
      key: ValueKey('estimate-making-$_selectedEstimateMakingOption'),
      initialValue: _selectedEstimateMakingOption,
      decoration: const InputDecoration(
        labelText: 'Making',
        suffixText: '%',
        isDense: true,
      ),
      items: _estimateMakingOptions
          .map((option) => DropdownMenuItem(value: option, child: Text(option)))
          .toList(),
      onChanged: (value) {
        if (value == null) {
          return;
        }
        _estimateMakingController.text = value;
        setState(() {});
        _schedulePersistence();
      },
    );
    final gstField = TextField(
      controller: _estimateGstController,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: const InputDecoration(
        labelText: 'GST: 3%',
        suffixText: '%',
        isDense: true,
      ),
      enabled: false,
    );

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isDesktop ? 20 : 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Text('Customer Details', style: titleStyle)),
          const SizedBox(height: 12),
          if (isDesktop) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _EditableDateField(
                    date: _estimateDate,
                    labelText: 'Order Date',
                    onDateSelected: _setEstimateDate,
                  ),
                ),
                const SizedBox(width: 16),
                SizedBox(
                  width: 220,
                  child: _DateField(
                    date: _estimateDeliveryDate,
                    labelText: 'Delivery Date',
                    valueStyle: Theme.of(context).textTheme.bodyMedium
                        ?.copyWith(
                          color: deliveryDateColor,
                          fontWeight: FontWeight.w700,
                        ),
                    labelStyle: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: deliveryDateColor),
                    iconColor: deliveryDateColor,
                    borderColor: deliveryDateColor,
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
            const SizedBox(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: nameField),
                const SizedBox(width: 12),
                Expanded(child: mobileField),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: purityField),
                const SizedBox(width: 12),
                Expanded(child: makingField),
                const SizedBox(width: 12),
                Expanded(child: gstField),
              ],
            ),
          ] else ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: _EditableDateField(
                    date: _estimateDate,
                    labelText: 'Order Date',
                    onDateSelected: _setEstimateDate,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DateField(
                    date: _estimateDeliveryDate,
                    labelText: 'Delivery Date',
                    valueStyle: Theme.of(context).textTheme.bodyMedium
                        ?.copyWith(
                          color: deliveryDateColor,
                          fontWeight: FontWeight.w700,
                        ),
                    labelStyle: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: deliveryDateColor),
                    iconColor: deliveryDateColor,
                    borderColor: deliveryDateColor,
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: nameField),
                const SizedBox(width: 12),
                Expanded(child: mobileField),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEstimatePricingRow({required double spacing}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
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
          SizedBox(width: spacing),
          Expanded(
            child: DropdownButtonFormField<String>(
              key: ValueKey('estimate-making-$_selectedEstimateMakingOption'),
              initialValue: _selectedEstimateMakingOption,
              decoration: const InputDecoration(
                labelText: 'Making',
                suffixText: '%',
                isDense: true,
              ),
              items: _estimateMakingOptions
                  .map(
                    (option) =>
                        DropdownMenuItem(value: option, child: Text(option)),
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
          SizedBox(width: spacing),
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
    );
  }

  Widget _buildEstimateItemsHeadingCard({required bool isDesktop}) {
    final subtitleStyle = Theme.of(
      context,
    ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade700);

    return Column(
      children: [
        Text(
          'Estimate Items',
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        if (isDesktop) ...[
          const SizedBox(height: 6),
          Text(
            'Add each design with quantity, purity, estimated weight, and notes.',
            textAlign: TextAlign.center,
            style: subtitleStyle,
          ),
        ],
      ],
    );
  }

  Widget _buildEstimateItemsSection({required bool isDesktop}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isDesktop ? 20 : 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: _buildEstimateItemsHeadingCard(isDesktop: isDesktop)),
          const SizedBox(height: 12),
          ..._buildEstimateItemEditors(),
          const SizedBox(height: 4),
          _buildEstimateAddItemButton(),
          const SizedBox(height: 12),
          _buildEstimateWeightRangeField(),
        ],
      ),
    );
  }

  Widget _buildEstimateAddItemButton() {
    return Center(
      child: FractionallySizedBox(
        widthFactor: 0.5,
        child: FilledButton.icon(
          onPressed: _addEstimateItem,
          icon: const Icon(Icons.add),
          label: const Text('Add item'),
        ),
      ),
    );
  }

  Widget _buildEstimateWeightRangeField() {
    return TextField(
      controller: _estimateWeightRangeController,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
      decoration: const InputDecoration(
        labelText: 'Estimated Weight Range',
        hintText: 'Add extra weight, e.g. 2.080',
        suffixText: 'gm',
      ),
      onChanged: (_) => setState(() {}),
    );
  }

  List<Widget> _buildEstimateItemEditors() {
    return List.generate(_estimateItems.length, (index) {
      final item = _estimateItems[index];
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: _EstimateItemEditor(
          index: index + 1,
          item: item,
          onChanged: () => setState(() {}),
          onReset: _estimateItems.length == 1
              ? () {
                  setState(() {
                    item.reset();
                  });
                  _schedulePersistence();
                }
              : null,
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
    });
  }

  Widget _buildEstimateDesktopSummaryCard() {
    final subtitleStyle = Theme.of(
      context,
    ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade700);
    final deliveryDateColor = Theme.of(context).colorScheme.tertiary;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Estimate Summary',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              'The right panel keeps totals and actions visible while you edit items.',
              style: subtitleStyle,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildEstimateMetricTile(
                    label: 'Designs',
                    value: _sortedEstimateItems.length.toString(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildEstimateMetricTile(
                    label: 'Quantity',
                    value: _estimateTotalQuantity.toString(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildEstimateMetricTile(
                    label: 'Weight',
                    value:
                        '${_formatWeightFixed3(_estimateTotalEstimatedWeight)} gm',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildEstimateMetricTile(
                    label: 'Making',
                    value: '$_selectedEstimateMakingOption%',
                  ),
                ),
              ],
            ),
            const Divider(height: 28),
            _EstimateSummaryRow(label: 'Purity', value: _estimatePurity),
            const SizedBox(height: 8),
            _EstimateSummaryRow(
              label: 'GST',
              value: '${_estimateGst.toStringAsFixed(2)}%',
            ),
            const SizedBox(height: 8),
            _EstimateSummaryRow(
              label: 'Delivery Date',
              value: _estimateDeliveryDateLabel,
              textColor: deliveryDateColor,
            ),
            const SizedBox(height: 8),
            _EstimateSummaryRow(
              label: 'Live Range',
              value: '$_estimateWeightRangeLabel gm',
              emphasize: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _estimateWeightRangeController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              decoration: const InputDecoration(
                labelText: 'Estimated Weight Range',
                hintText: 'Add extra weight, e.g. 2.080',
                suffixText: 'gm',
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 8),
            Text(
              'Tip: enter only the extra buffer. The live range updates automatically.',
              style: subtitleStyle,
            ),
            const SizedBox(height: 20),
            _buildEstimateActionButtons(isDesktop: true),
          ],
        ),
      ),
    );
  }

  Widget _buildEstimateMetricTile({
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade700),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _buildEstimateActionButtons({required bool isDesktop}) {
    final resetButton = FilledButton.icon(
      onPressed: _resetEstimateForm,
      style: FilledButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.error,
        foregroundColor: Theme.of(context).colorScheme.onError,
      ),
      icon: const Icon(Icons.restart_alt),
      label: const Text('Reset'),
    );

    if (isDesktop) {
      return SizedBox(width: double.infinity, child: resetButton);
    }

    return SizedBox(width: double.infinity, child: resetButton);
  }

  void _addEstimateItem() {
    setState(() {
      final item = _EstimateItemDraft();
      _estimateItems.add(item);
      _attachEstimateItemListeners(item);
    });
    _schedulePersistence();
  }

  Widget _buildActualBody(double contentTopPadding) {
    final deliveryDateColor = Theme.of(context).colorScheme.tertiary;
    final titleStyle = Theme.of(
      context,
    ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800);

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(16, contentTopPadding, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 980;

                  final orderDateField = _EditableDateField(
                    date: _estimateDate,
                    labelText: 'Order Date',
                    onDateSelected: _setEstimateDate,
                  );
                  final deliveryDateField = _DateField(
                    date: _estimateDeliveryDate,
                    labelText: 'Delivery Date',
                    valueStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: deliveryDateColor,
                      fontWeight: FontWeight.w700,
                    ),
                    labelStyle: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: deliveryDateColor),
                    iconColor: deliveryDateColor,
                    borderColor: deliveryDateColor,
                    onDateSelected: (selected) {
                      setState(() {
                        _estimateDeliveryDate = selected;
                      });
                      _schedulePersistence();
                    },
                  );
                  final nameField = TextField(
                    focusNode: _estimateCustomerNameFocusNode,
                    controller: _estimateCustomerNameController,
                    decoration: InputDecoration(
                      labelText: 'Name',
                      errorText: _estimateNameError,
                    ),
                    onChanged: (_) => setState(() {}),
                  );
                  final mobileField = TextField(
                    focusNode: _estimateCustomerMobileFocusNode,
                    controller: _estimateCustomerMobileController,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
                      LengthLimitingTextInputFormatter(10),
                    ],
                    decoration: InputDecoration(
                      labelText: 'Whatsapp Number',
                      errorText: _estimateMobileError,
                    ),
                    onChanged: (_) => setState(() {}),
                  );

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(child: Text('Customer Details', style: titleStyle)),
                      const SizedBox(height: 12),
                      if (isWide)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: orderDateField),
                            const SizedBox(width: 12),
                            Expanded(child: deliveryDateField),
                            const SizedBox(width: 12),
                            Expanded(child: nameField),
                            const SizedBox(width: 12),
                            Expanded(child: mobileField),
                          ],
                        )
                      else ...[
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: orderDateField),
                            const SizedBox(width: 12),
                            Expanded(child: deliveryDateField),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: nameField),
                            const SizedBox(width: 12),
                            Expanded(child: mobileField),
                          ],
                        ),
                      ],
                    ],
                  );
                },
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
                    key: ValueKey(
                      'estimate-making-$_selectedEstimateMakingOption',
                    ),
                    initialValue: _selectedEstimateMakingOption,
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
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAdvanceOverviewCard(),
                const SizedBox(height: 20),
                _buildAdvanceSectionWrapper(
                  title: 'Advance Entries',
                  subtitle:
                      'Record payment mode, rate, and net weight for each advance entry.',
                  child: Column(
                    children: [
                      ...List.generate(_advanceItems.length, (index) {
                        final item = _advanceItems[index];
                        return Padding(
                          padding: EdgeInsets.only(
                            bottom: index == _advanceItems.length - 1 ? 0 : 12,
                          ),
                          child: _AdvanceValuationEditor(
                            index: index + 1,
                            item: item,
                            onChanged: () {
                              setState(() {});
                              _schedulePersistence();
                            },
                            onReset: _advanceItems.length == 1
                                ? () => _resetAdvanceEntry(index)
                                : null,
                            onRemove: _advanceItems.length == 1
                                ? null
                                : () {
                                    setState(() {
                                      final removed = _advanceItems.removeAt(
                                        index,
                                      );
                                      removed.dispose();
                                    });
                                    _schedulePersistence();
                                  },
                          ),
                        );
                      }),
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.center,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 280),
                          child: FilledButton.icon(
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
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                _buildAdvanceSectionWrapper(
                  title: 'Old Items',
                  subtitle:
                      'Track returned items and their computed advance conversion values.',
                  child: Column(
                    children: [
                      ...List.generate(_advanceOldItems.length, (index) {
                        final item = _advanceOldItems[index];
                        return Padding(
                          padding: EdgeInsets.only(
                            bottom:
                                index == _advanceOldItems.length - 1 ? 0 : 12,
                          ),
                          child: _AdvanceOldItemEditor(
                            index: index + 1,
                            item: item,
                            onChanged: () {
                              setState(() {});
                              _schedulePersistence();
                            },
                            onReset: _advanceOldItems.length == 1
                                ? () => _resetAdvanceOldItemEntry(index)
                                : null,
                            onRemove: _advanceOldItems.length == 1
                                ? null
                                : () {
                                    setState(() {
                                      final removed = _advanceOldItems.removeAt(
                                        index,
                                      );
                                      removed.dispose();
                                    });
                                    _schedulePersistence();
                                  },
                          ),
                        );
                      }),
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.center,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 280),
                          child: OutlinedButton.icon(
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
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: _resetAdvanceForm,
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error,
                    foregroundColor: Theme.of(context).colorScheme.onError,
                    minimumSize: const Size.fromHeight(52),
                  ),
                  icon: const Icon(Icons.restart_alt),
                  label: const Text('Reset Advance'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAdvanceOverviewCard() {
    final colorScheme = Theme.of(context).colorScheme;
    final customerName = _estimateCustomerName.trim().isEmpty
        ? 'Walk-in customer'
        : _estimateCustomerName;
    final metrics = [
      (
        label: 'Advance Entries',
        value: _populatedAdvanceItems.length.toString(),
        icon: Icons.account_balance_wallet_outlined,
      ),
      (
        label: 'Old Items',
        value: _populatedAdvanceOldItems.length.toString(),
        icon: Icons.history_toggle_off_outlined,
      ),
      (
        label: 'Total Amount',
        value: _formatCurrency(_advanceCombinedAmount),
        icon: Icons.currency_rupee_outlined,
      ),
      (
        label: 'Net Weight',
        value: '${_formatWeightFixed3(_billPreviewAdvanceNetWeight)} gm',
        icon: Icons.scale_outlined,
      ),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Advance',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            'Manage advance entries and returned items without changing the current order flow.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade700),
          ),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withValues(alpha: 0.42),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(Icons.person_outline, color: colorScheme.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Customer',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        customerName,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: metrics
                .map(
                  (metric) => _buildAdvanceMetricChip(
                    label: metric.label,
                    value: metric.value,
                    icon: metric.icon,
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildAdvanceMetricChip({
    required String label,
    required String value,
    required IconData icon,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      constraints: const BoxConstraints(minWidth: 180),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: colorScheme.primary),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade700,
                ),
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
        ],
      ),
    );
  }

  Widget _buildAdvanceSectionWrapper({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade700),
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }


  Widget _buildItemsBody(double contentTopPadding) {
    final populatedNewItems = _populatedNewItems;
    final editableManualNewItems = _editableManualNewItems;
    final showsDifferenceNewItem = _shouldShowDifferenceNewItem;
    final additionalChargesColor = Theme.of(context).colorScheme.error;
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
                  label: Text(
                    _supportsQrScanning ? 'Scan QR Tag' : 'QR Not Available',
                  ),
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
            TextField(
              controller: _newItemsAdditionalChargesController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: const [_IndianCurrencyInputFormatter()],
              style: TextStyle(color: additionalChargesColor),
              decoration: InputDecoration(
                labelText: 'Additional Charges',
                hintText: 'Enter overall additional charges',
                labelStyle: TextStyle(color: additionalChargesColor),
                floatingLabelStyle: TextStyle(color: additionalChargesColor),
              ),
              onChanged: (_) {
                setState(() {});
                _schedulePersistence();
              },
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
                      label: 'Additional Charges',
                      value: _formatCurrency(_newItemsAdditionalCharges),
                      textColor: additionalChargesColor,
                    ),
                    const SizedBox(height: 8),
                    _EstimateSummaryRow(
                      label: 'Subtotal',
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
    final total =
        _populatedAdvanceItems.fold<double>(
          0,
          (sum, item) => sum + _truncateWeight3(item.weight),
        ) +
        _populatedAdvanceOldItems.fold<double>(
          0,
          (sum, item) => sum + _truncateWeight3(item.advanceWeight),
        );
    return _truncateWeight3(total);
  }

  Widget _buildTakeawaySummaryCard() {
    final takeawaySubtotal = _advanceCombinedAmount + _newItemsGrandTotal;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Totals',
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
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  _EstimateSummaryRow(
                    label: 'Subtotal',
                    value: _formatCurrency(takeawaySubtotal),
                  ),
                  const SizedBox(height: 8),
                  _EstimateSummaryRow(
                    label: 'Final Due Before G%',
                    value: _formatCurrency(_takeawayBaseFinalDueAmount),
                  ),
                  if (_takeawayGstAddedAmount > 0) ...[
                    const SizedBox(height: 8),
                    _EstimateSummaryRow(
                      label: 'G% Added',
                      value: _formatCurrency(_takeawayGstAddedAmount),
                    ),
                  ],
                  const SizedBox(height: 8),
                  _EstimateSummaryRow(
                    label: _takeawayRefundAmount > 0
                        ? 'Refund Amount'
                        : 'Final Due Amount',
                    value: _formatCurrency(_billPreviewDisplayedDueAmount),
                    emphasize: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: _canGenerateTakeawayPaymentQr
                    ? _showTakeawayPaymentQrDialog
                    : null,
                icon: const Icon(Icons.qr_code_2_outlined),
                label: const Text('Generate Payment QR'),
              ),
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
                  ChoiceChip(
                    label: const Text('G%'),
                    selected: _billPreviewGstEnabled,
                    onSelected: _canApplyBillPreviewGst
                        ? (value) {
                            setState(() {
                              _setBillPreviewGstEnabled(value);
                            });
                            _schedulePersistence();
                          }
                        : null,
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
                        if (_takeawayGstAddedAmount > 0) ...[
                          const SizedBox(height: 2),
                          Text(
                            'G% Added ${_formatCurrency(_takeawayGstAddedAmount)}',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: Colors.grey.shade700),
                            textAlign: TextAlign.right,
                          ),
                        ],
                        const SizedBox(height: 2),
                        Text(
                          _formatCurrency(_billPreviewDisplayedDueAmount),
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
                        _accessGateTitle,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _accessGateDescription,
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
                        'The app reopens with the last signed-in account, and the last used email stays filled in.',
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
    HardwareKeyboard.instance.removeHandler(_handleAppKeyEvent);
    _estimateClockTimer?.cancel();
    _persistDebounceTimer?.cancel();
    _firestoreSyncDebounceTimer?.cancel();
    _remoteRefreshTimer?.cancel();
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
    _newItemsAdditionalChargesController.dispose();
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
      if (_selectedSection == AppSection.orders)
        IconButton(
          onPressed: _isRemoteSyncInProgress ? null : _syncOrdersPageState,
          icon: const Icon(Icons.sync_outlined),
          tooltip: 'Sync now',
        ),
      if (_isAdmin && _selectedSection == AppSection.estimateCalculator)
        IconButton(
          onPressed: () => _saveEstimateOrder(
            stayOnEstimate: true,
            syncImmediately: true,
          ),
          icon: const Icon(Icons.save_outlined),
          tooltip: _isEditingEstimate ? 'Update order' : 'Save order',
        ),
      if (_isAdmin && _selectedSection == AppSection.actual)
        IconButton(
          onPressed: () => _saveEstimateOrder(
            stayOnEstimate: true,
            syncImmediately: true,
          ),
          icon: const Icon(Icons.save_outlined),
          tooltip: _isEditingEstimate ? 'Update order' : 'Save order',
        ),
      if (_isAdmin && _selectedSection == AppSection.billPreview)
        IconButton(
          onPressed: () => _saveEstimateOrder(
            stayOnEstimate: true,
            syncImmediately: true,
          ),
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
          onPressed: () => _saveEstimateOrder(
            stayOnEstimate: true,
            syncImmediately: true,
          ),
          icon: const Icon(Icons.save_outlined),
          tooltip: _isEditingEstimate ? 'Update order' : 'Save order',
        ),
      if (_isAdmin && _selectedSection == AppSection.advance)
        IconButton(
          onPressed: () => _saveAdvanceEntries(syncImmediately: true),
          icon: const Icon(Icons.save_outlined),
          tooltip: 'Save advance entries',
        ),
      if (_isAdmin &&
          (_selectedSection == AppSection.estimateCalculator ||
              _selectedSection == AppSection.advance ||
              _selectedSection == AppSection.actual ||
              _selectedSection == AppSection.items ||
              _selectedSection == AppSection.billPreview))
        IconButton(
          onPressed: () {
            switch (_selectedSection) {
              case AppSection.orders:
                return;
              case AppSection.estimateCalculator:
                _openEstimatePrintPreview();
                return;
              case AppSection.advance:
                _openAdvancePrintPreview();
                return;
              case AppSection.actual:
                _openActualPrintPreview();
                return;
              case AppSection.items:
                _openNewItemsPrintPreview();
                return;
              case AppSection.billPreview:
                _openCombinedBillPrintPreview();
                return;
            }
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
        final shouldExit = await _confirmAndPersistExit();
        if (shouldExit) {
          await _requestAppClose();
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
            title: Text(appBarTitle),
            actions: appBarActions,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(28),
              child: _buildSaveStatusBar(),
            ),
          ),
          floatingActionButton:
              _isAdmin && _selectedSection == AppSection.orders
              ? FloatingActionButton.extended(
                  onPressed: _openAddOrderSheet,
                  icon: const Icon(Icons.add),
                  label: const Text('New order'),
                )
              : null,
          bottomNavigationBar: !_showAdminEditNavigation
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
                          label: 'Summary',
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
    if (quantityValue == null || quantityValue < 1 || quantityValue > 100) {
      return 'Select quantity';
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
    final allowsZeroWeight = switch (purityController.text.trim()) {
      '18K' || 'Silver' => true,
      _ => false,
    };
    if (weightValue == null ||
        weightValue < 0 ||
        (!allowsZeroWeight && weightValue <= 0)) {
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

  void reset() {
    nameController.clear();
    purityController.text = '22K';
    quantityController.text = '1';
    estimatedNettWeightController.clear();
    grossWeightController.clear();
    lessWeightController.clear();
    sizeController.clear();
    lengthController.clear();
    notesController.clear();
    showNameError = false;
    showQuantityError = false;
    showWeightError = false;
  }

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
    this.onReset,
    this.onRemove,
  });

  final int index;
  final _EstimateItemDraft item;
  final VoidCallback onChanged;
  final VoidCallback? onReset;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    const purityOptions = ['22K', '18K', 'Silver'];
    final quantityOptions = List<int>.generate(100, (index) => index + 1);

    final nameField = Focus(
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
    );
    final purityField = DropdownButtonFormField<String>(
      initialValue: purityOptions.contains(item.purityController.text)
          ? item.purityController.text
          : purityOptions.first,
      decoration: const InputDecoration(labelText: 'Purity'),
      items: purityOptions
          .map((option) => DropdownMenuItem(value: option, child: Text(option)))
          .toList(),
      onChanged: (value) {
        item.purityController.text = value ?? purityOptions.first;
        onChanged();
      },
    );
    final quantityField = Focus(
      onFocusChange: (hasFocus) {
        if (!hasFocus) {
          item.showQuantityError = true;
          onChanged();
        }
      },
      child: DropdownButtonFormField<int>(
        initialValue: quantityOptions.contains(item.quantity)
            ? item.quantity
            : 1,
        decoration: InputDecoration(
          labelText: 'Quantity',
          errorText: item.quantityError,
        ),
        items: quantityOptions
            .map(
              (quantity) => DropdownMenuItem(
                value: quantity,
                child: Text(quantity.toString()),
              ),
            )
            .toList(),
        onChanged: (value) {
          item.quantityController.text = (value ?? 1).toString();
          item.showQuantityError = true;
          onChanged();
        },
      ),
    );
    final weightField = Focus(
      onFocusChange: (hasFocus) {
        if (!hasFocus) {
          item.showWeightError = true;
          onChanged();
        }
      },
      child: TextField(
        controller: item.estimatedNettWeightController,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: 'Estimated Weight',
          suffixText: 'g',
          errorText: item.weightError,
        ),
        onChanged: (_) => onChanged(),
      ),
    );

    return Card(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 760;

          return Padding(
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
                      Focus(
                        canRequestFocus: false,
                        skipTraversal: true,
                        descendantsAreFocusable: false,
                        child: IconButton(
                          onPressed: onRemove,
                          color: Theme.of(context).colorScheme.error,
                          icon: const Icon(Icons.delete_outline),
                          tooltip: 'Remove item',
                        ),
                      )
                    else if (onReset != null)
                      Focus(
                        canRequestFocus: false,
                        skipTraversal: true,
                        descendantsAreFocusable: false,
                        child: IconButton(
                          onPressed: onReset,
                          color: Theme.of(context).colorScheme.primary,
                          icon: const Icon(Icons.restart_alt),
                          tooltip: 'Reset item',
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                if (isWide)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(width: 150, child: purityField),
                      const SizedBox(width: 12),
                      Expanded(flex: 4, child: nameField),
                      const SizedBox(width: 12),
                      SizedBox(width: 140, child: quantityField),
                      const SizedBox(width: 12),
                      SizedBox(width: 170, child: weightField),
                    ],
                  )
                else ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: purityField),
                      const SizedBox(width: 12),
                      Expanded(child: nameField),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: quantityField),
                      const SizedBox(width: 12),
                      Expanded(child: weightField),
                    ],
                  ),
                ],
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
          );
        },
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
    final quantityOptions = List<int>.generate(100, (index) => index + 1);
    final purityField = DropdownButtonFormField<String>(
      initialValue: purityOptions.contains(item.purityController.text)
          ? item.purityController.text
          : purityOptions.first,
      decoration: const InputDecoration(labelText: 'Purity'),
      items: purityOptions
          .map(
            (option) => DropdownMenuItem(value: option, child: Text(option)),
          )
          .toList(),
      onChanged: (value) {
        item.purityController.text = value ?? purityOptions.first;
        onChanged();
      },
    );
    final itemNameField = Focus(
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
    );
    final quantityField = Focus(
      onFocusChange: (hasFocus) {
        if (!hasFocus) {
          item.showQuantityError = true;
          onChanged();
        }
      },
      child: DropdownButtonFormField<int>(
        initialValue: quantityOptions.contains(item.quantity) ? item.quantity : 1,
        decoration: InputDecoration(
          labelText: 'Quantity',
          errorText: item.quantityError,
        ),
        items: quantityOptions
            .map(
              (quantity) => DropdownMenuItem(
                value: quantity,
                child: Text(quantity.toString()),
              ),
            )
            .toList(),
        onChanged: (value) {
          item.quantityController.text = (value ?? 1).toString();
          item.showQuantityError = true;
          onChanged();
        },
      ),
    );
    final estimatedWeightField = Focus(
      onFocusChange: (hasFocus) {
        if (!hasFocus) {
          item.showWeightError = true;
          onChanged();
        }
      },
      child: TextField(
        controller: item.estimatedNettWeightController,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: 'Estimated Weight',
          suffixText: 'g',
          errorText: item.weightError,
        ),
        onChanged: (_) => onChanged(),
      ),
    );
    final grossWeightField = TextField(
      controller: item.grossWeightController,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: const InputDecoration(
        labelText: 'Gross Weight',
        suffixText: 'g',
      ),
      onChanged: (_) => onChanged(),
    );
    final lessWeightField = TextField(
      controller: item.lessWeightController,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: const InputDecoration(
        labelText: 'Less Weight',
        suffixText: 'g',
      ),
      onChanged: (_) => onChanged(),
    );
    final netWeightField = InputDecorator(
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
    );

    return Card(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 920;
          final canFitWeightRow = constraints.maxWidth >= 620;

          return Padding(
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
                        color: Theme.of(context).colorScheme.error,
                        icon: const Icon(Icons.delete_outline),
                        tooltip: 'Remove item',
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                if (isWide)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 2, child: purityField),
                      const SizedBox(width: 12),
                      Expanded(flex: 4, child: itemNameField),
                      const SizedBox(width: 12),
                      Expanded(flex: 2, child: quantityField),
                      const SizedBox(width: 12),
                      Expanded(flex: 3, child: estimatedWeightField),
                    ],
                  )
                else ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: purityField),
                      const SizedBox(width: 12),
                      Expanded(child: itemNameField),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: quantityField),
                      const SizedBox(width: 12),
                      Expanded(child: estimatedWeightField),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                if (canFitWeightRow)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: grossWeightField),
                      const SizedBox(width: 12),
                      Expanded(child: lessWeightField),
                      const SizedBox(width: 12),
                      Expanded(child: netWeightField),
                    ],
                  )
                else ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: grossWeightField),
                      const SizedBox(width: 12),
                      Expanded(child: lessWeightField),
                    ],
                  ),
                  const SizedBox(height: 12),
                  netWeightField,
                ],
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
          );
        },
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
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Additional Charge',
                      labelStyle: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                      floatingLabelStyle: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
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
    this.gstApplied = false,
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
      gstApplied: json['gstApplied'] as bool? ?? false,
      chequeNumber: json['chequeNumber'] as String? ?? '',
    );
  }

  DateTime? _date;
  AdvanceMode? _mode;
  bool gstApplied;
  final TextEditingController amountController;
  final TextEditingController rateController;
  final TextEditingController rateMakingController;
  final TextEditingController chequeNumberController;
  static const double gstPercent = 3;

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
    return _truncateTo3Decimals(rate + ((rate * rateMaking) / 100));
  }

  double get otherCharges {
    if (!gstApplied || effectiveRate <= 0) {
      return 0;
    }
    return _truncateTo3Decimals(effectiveRate * (gstPercent / 100));
  }

  double get effectiveRateWithOthers {
    return _truncateTo3Decimals(effectiveRate + otherCharges);
  }

  double get weight {
    return _netWeightFromRateWithMaking(amount, effectiveRateWithOthers);
  }

  AdvanceValuationLine get line => AdvanceValuationLine(
    date: date,
    mode: mode,
    amount: amount,
    rate: rate,
    rateMaking: rateMaking,
    gstApplied: gstApplied,
    chequeNumber: chequeNumber,
  );

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'mode': mode.name,
      'amountText': amountController.text,
      'rateText': rateController.text,
      'rateMakingText': rateMakingController.text,
      'gstApplied': gstApplied,
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
    this.onReset,
    this.onRemove,
  });

  final int index;
  final _AdvanceValuationDraft item;
  final VoidCallback onChanged;
  final VoidCallback? onReset;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 760;

        final dateField = _DateField(
          date: item.date,
          labelText: 'Date',
          onDateSelected: (selected) {
            item.date = selected;
            onChanged();
          },
        );
        final modeField = DropdownButtonFormField<AdvanceMode>(
          initialValue: item.mode,
          decoration: const InputDecoration(labelText: 'Mode'),
          items: AdvanceMode.values
              .map(
                (mode) => DropdownMenuItem(value: mode, child: Text(mode.label)),
              )
              .toList(),
          onChanged: (value) {
            item.mode = value ?? AdvanceMode.cash;
            onChanged();
          },
        );
        final amountField = TextField(
          controller: item.amountController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: const [_IndianCurrencyInputFormatter()],
          decoration: const InputDecoration(labelText: 'Amount'),
          onChanged: (_) => onChanged(),
        );
        final rateField = TextField(
          controller: item.rateController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: const [_IndianCurrencyInputFormatter()],
          decoration: const InputDecoration(labelText: 'Rate22', hintText: '-Unfix-'),
          onChanged: (_) => onChanged(),
        );
        final makingField = TextField(
          controller: item.rateMakingController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
          ],
          decoration: const InputDecoration(
            labelText: 'Making%',
            suffixText: '%',
          ),
          onChanged: (_) => onChanged(),
        );
        final gstField = InputDecorator(
          decoration: const InputDecoration(labelText: 'GST', suffixText: '%'),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _formatWeight3(_AdvanceValuationDraft.gstPercent),
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Apply',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                  Switch.adaptive(
                    value: item.gstApplied,
                    onChanged: (value) {
                      item.gstApplied = value;
                      onChanged();
                    },
                  ),
                ],
              ),
            ],
          ),
        );
        final netWeightField = InputDecorator(
          decoration: const InputDecoration(
            labelText: 'Net Weight',
            suffixText: 'gm',
          ),
          child: Text(
            _formatWeight3(item.weight),
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        );

        Widget buildRow(List<Widget> fields) {
          if (isCompact) {
            return Column(
              children: [
                for (var i = 0; i < fields.length; i++) ...[
                  fields[i],
                  if (i != fields.length - 1) const SizedBox(height: 12),
                ],
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < fields.length; i++) ...[
                Expanded(child: fields[i]),
                if (i != fields.length - 1) const SizedBox(width: 12),
              ],
            ],
          );
        }

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
                      Focus(
                        canRequestFocus: false,
                        skipTraversal: true,
                        descendantsAreFocusable: false,
                        child: IconButton(
                          onPressed: onRemove,
                          color: Theme.of(context).colorScheme.error,
                          icon: const Icon(Icons.delete_outline),
                          tooltip: 'Remove item',
                        ),
                      )
                    else if (onReset != null)
                      Focus(
                        canRequestFocus: false,
                        skipTraversal: true,
                        descendantsAreFocusable: false,
                        child: IconButton(
                          onPressed: onReset,
                          color: Theme.of(context).colorScheme.primary,
                          icon: const Icon(Icons.restart_alt),
                          tooltip: 'Reset item',
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                buildRow([dateField, modeField, amountField]),
                if (item.mode == AdvanceMode.banking) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: item.chequeNumberController,
                    keyboardType: TextInputType.text,
                    decoration: const InputDecoration(labelText: 'Cheque Number'),
                    onChanged: (_) => onChanged(),
                  ),
                ],
                const SizedBox(height: 12),
                buildRow([rateField, makingField, gstField, netWeightField]),
              ],
            ),
          ),
        );
      },
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

  double get advanceEffectiveRate {
    return _truncateTo3Decimals(
      advanceRate + ((advanceRate * advanceMaking) / 100),
    );
  }

  double get advanceWeight {
    return _netWeightFromRateWithMaking(amount, advanceEffectiveRate);
  }

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
    this.onReset,
    this.onRemove,
  });

  final int index;
  final _AdvanceOldItemDraft item;
  final VoidCallback onChanged;
  final VoidCallback? onReset;
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 900;

        final returnBhavField = TextField(
          controller: item.returnRateController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: const [_IndianCurrencyInputFormatter()],
          decoration: const InputDecoration(labelText: 'Return Bhav'),
          onChanged: (_) => onChanged(),
        );
        final tanchField = DropdownButtonFormField<String>(
          initialValue: _selectedTanchValue(item.tanchController.text),
          decoration: const InputDecoration(labelText: 'Tanch'),
          items: _tanchOptions
              .map(
                (value) => DropdownMenuItem(
                  value: value,
                  child: Text(_formatTanchPercent(double.tryParse(value) ?? 0)),
                ),
              )
              .toList(),
          onChanged: (value) {
            item.tanchController.text = value ?? '';
            onChanged();
          },
        );
        final grossField = TextField(
          controller: item.grossWeightController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: decimalInput,
          decoration: const InputDecoration(labelText: 'Gross'),
          onChanged: (_) => onChanged(),
        );
        final lessField = TextField(
          controller: item.lessWeightController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: decimalInput,
          decoration: const InputDecoration(labelText: 'Less'),
          onChanged: (_) => onChanged(),
        );
        final nettField = InputDecorator(
          decoration: const InputDecoration(labelText: 'Nett'),
          child: Text(_formatWeight3(item.nettWeight)),
        );
        final amountField = InputDecorator(
          decoration: const InputDecoration(labelText: 'Amount'),
          child: Text(_formatCurrency(item.amount)),
        );

        Widget buildRow(List<Widget> fields) {
          if (isCompact) {
            return Column(
              children: [
                for (var i = 0; i < fields.length; i++) ...[
                  fields[i],
                  if (i != fields.length - 1) const SizedBox(height: 12),
                ],
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < fields.length; i++) ...[
                Expanded(child: fields[i]),
                if (i != fields.length - 1) const SizedBox(width: 12),
              ],
            ],
          );
        }

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
                      Focus(
                        canRequestFocus: false,
                        skipTraversal: true,
                        descendantsAreFocusable: false,
                        child: IconButton(
                          onPressed: onRemove,
                          color: Theme.of(context).colorScheme.error,
                          icon: const Icon(Icons.delete_outline),
                          tooltip: 'Remove old item',
                        ),
                      )
                    else if (onReset != null)
                      Focus(
                        canRequestFocus: false,
                        skipTraversal: true,
                        descendantsAreFocusable: false,
                        child: IconButton(
                          onPressed: onReset,
                          color: Theme.of(context).colorScheme.primary,
                          icon: const Icon(Icons.restart_alt),
                          tooltip: 'Reset old item',
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                buildRow([
                  _DateField(
                    date: item.date,
                    labelText: 'Date',
                    onDateSelected: (selected) {
                      item.date = selected;
                      onChanged();
                    },
                  ),
                  TextField(
                    controller: item.itemNameController,
                    inputFormatters: [_WordCapitalizeFormatter()],
                    decoration: const InputDecoration(labelText: 'Item Name'),
                    onChanged: (_) => onChanged(),
                  ),
                ]),
                const SizedBox(height: 12),
                buildRow([
                  grossField,
                  lessField,
                  nettField,
                  tanchField,
                  returnBhavField,
                  amountField,
                ]),
                const SizedBox(height: 12),
                buildRow([
                  TextField(
                    controller: item.advanceRateController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: const [_IndianCurrencyInputFormatter()],
                    decoration: const InputDecoration(labelText: 'Advance Rate'),
                    onChanged: (_) => onChanged(),
                  ),
                  TextField(
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
                ]),
              ],
            ),
          ),
        );
      },
    );
  }
}

