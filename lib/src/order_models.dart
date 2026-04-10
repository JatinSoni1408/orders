part of '../main.dart';

enum OrderStatus { pending, preparing, outForDelivery, delivered, canceled }

enum AppSection {
  orders,
  estimateCalculator,
  advance,
  actual,
  items,
  billPreview,
}

enum AppAccessRole { admin, staff, user }

enum OrderSortOption { newest, deliveryLatest, nameAZ }

enum AdvanceMode { cash, upi, banking, imps, neft, rtgs }

class Order {
  Order({
    required this.id,
    required this.customer,
    required this.items,
    required this.total,
    required this.status,
    required this.createdAt,
    List<AdvancePayment>? advancePayments,
    List<OldItemReturn>? oldItemReturns,
    List<NewOrderItem>? newItems,
    List<TakeawayPayment>? takeawayPayments,
    this.customerPhone,
    this.altCustomerPhone,
    this.customerPhotoPath,
    this.estimatePurity,
    this.estimateGst,
    this.estimateMaking,
    this.estimateWeightRange,
    this.deliveryDate,
    this.newItemsAdditionalCharges = 0,
    this.newItemsOverallDiscount = 0,
    this.takeawayDiscount = 0,
  }) : advancePayments = advancePayments ?? const [],
       oldItemReturns = oldItemReturns ?? const [],
       newItems = newItems ?? const [],
       takeawayPayments = takeawayPayments ?? const [];

  final String id;
  final String customer;
  final List<OrderItem> items;
  final double total;
  final OrderStatus status;
  final DateTime createdAt;
  final List<AdvancePayment> advancePayments;
  final List<OldItemReturn> oldItemReturns;
  final List<NewOrderItem> newItems;
  final List<TakeawayPayment> takeawayPayments;
  final String? customerPhone;
  final String? altCustomerPhone;
  final String? customerPhotoPath;
  final String? estimatePurity;
  final double? estimateGst;
  final double? estimateMaking;
  final String? estimateWeightRange;
  final DateTime? deliveryDate;
  final double newItemsAdditionalCharges;
  final double newItemsOverallDiscount;
  final double takeawayDiscount;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customer': customer,
      'items': items.map((item) => item.toJson()).toList(),
      'total': total,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'advancePayments': advancePayments
          .map((payment) => payment.toJson())
          .toList(),
      'oldItemReturns': oldItemReturns.map((item) => item.toJson()).toList(),
      'newItems': newItems.map((item) => item.toJson()).toList(),
      'takeawayPayments': takeawayPayments
          .map((payment) => payment.toJson())
          .toList(),
      'customerPhone': customerPhone,
      'altCustomerPhone': altCustomerPhone,
      'customerPhotoPath': customerPhotoPath,
      'estimatePurity': estimatePurity,
      'estimateGst': estimateGst,
      'estimateMaking': estimateMaking,
      'estimateWeightRange': estimateWeightRange,
      'deliveryDate': deliveryDate?.toIso8601String(),
      'newItemsAdditionalCharges': newItemsAdditionalCharges,
      'newItemsOverallDiscount': newItemsOverallDiscount,
      'takeawayDiscount': takeawayDiscount,
    };
  }

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] as String,
      customer: json['customer'] as String,
      items: (json['items'] as List<dynamic>)
          .map((item) => OrderItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      total: (json['total'] as num?)?.toDouble() ?? 0,
      status: _orderStatusFromName(json['status'] as String),
      createdAt: _dateTimeFromJson(json['createdAt']) ?? DateTime.now(),
      advancePayments: (json['advancePayments'] as List<dynamic>? ?? const [])
          .map(
            (payment) =>
                AdvancePayment.fromJson(payment as Map<String, dynamic>),
          )
          .toList(),
      oldItemReturns: (json['oldItemReturns'] as List<dynamic>? ?? const [])
          .map((item) => OldItemReturn.fromJson(item as Map<String, dynamic>))
          .toList(),
      newItems: (json['newItems'] as List<dynamic>? ?? const [])
          .map((item) => NewOrderItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      takeawayPayments: (json['takeawayPayments'] as List<dynamic>? ?? const [])
          .map(
            (payment) =>
                TakeawayPayment.fromJson(payment as Map<String, dynamic>),
          )
          .toList(),
      customerPhone: json['customerPhone'] as String?,
      altCustomerPhone: json['altCustomerPhone'] as String?,
      customerPhotoPath: json['customerPhotoPath'] as String?,
      estimatePurity: json['estimatePurity'] as String?,
      estimateGst: (json['estimateGst'] as num?)?.toDouble(),
      estimateMaking: (json['estimateMaking'] as num?)?.toDouble(),
      estimateWeightRange: json['estimateWeightRange'] as String?,
      deliveryDate: _dateTimeFromJson(json['deliveryDate']),
      newItemsAdditionalCharges:
          (json['newItemsAdditionalCharges'] as num?)?.toDouble() ?? 0,
      newItemsOverallDiscount:
          (json['newItemsOverallDiscount'] as num?)?.toDouble() ?? 0,
      takeawayDiscount: (json['takeawayDiscount'] as num?)?.toDouble() ?? 0,
    );
  }
}

class OrderItem {
  const OrderItem({
    required this.name,
    required this.category,
    required this.date,
    required this.quantity,
    required this.bhav,
    required this.weight,
    required this.making,
    this.purity,
    this.notes,
    this.estimatedWeight,
    this.grossWeight,
    this.lessWeight,
    this.netWeight,
    this.size,
    this.length,
  });

  final String name;
  final String category;
  final DateTime date;
  final int quantity;
  final double bhav;
  final double weight;
  final double making;
  final String? purity;
  final String? notes;
  final double? estimatedWeight;
  final double? grossWeight;
  final double? lessWeight;
  final double? netWeight;
  final String? size;
  final String? length;

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'category': category,
      'date': date.toIso8601String(),
      'quantity': quantity,
      'bhav': bhav,
      'weight': weight,
      'making': making,
      'purity': purity,
      'notes': notes,
      'estimatedWeight': estimatedWeight,
      'grossWeight': grossWeight,
      'lessWeight': lessWeight,
      'netWeight': netWeight,
      'size': size,
      'length': length,
    };
  }

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      name: json['name'] as String,
      category: json['category'] as String? ?? '',
      date: _dateTimeFromJson(json['date']) ?? DateTime.now(),
      quantity: json['quantity'] as int? ?? 0,
      bhav: (json['bhav'] as num).toDouble(),
      weight: (json['weight'] as num).toDouble(),
      making: (json['making'] as num).toDouble(),
      purity: json['purity'] as String?,
      notes: json['notes'] as String?,
      estimatedWeight: (json['estimatedWeight'] as num?)?.toDouble(),
      grossWeight: (json['grossWeight'] as num?)?.toDouble(),
      lessWeight: (json['lessWeight'] as num?)?.toDouble(),
      netWeight: (json['netWeight'] as num?)?.toDouble(),
      size: json['size'] as String?,
      length: json['length'] as String?,
    );
  }
}

class AdvancePayment {
  const AdvancePayment({
    required this.date,
    required this.mode,
    required this.amount,
    required this.rate,
    required this.making,
    required this.weight,
    this.gstApplied = false,
    this.chequeNumber,
  });

  final DateTime date;
  final AdvanceMode mode;
  final double amount;
  final double rate;
  final double making;
  final double weight;
  final bool gstApplied;
  final String? chequeNumber;

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'mode': mode.name,
      'amount': amount,
      'rate': rate,
      'making': making,
      'weight': weight,
      'gstApplied': gstApplied,
      'chequeNumber': chequeNumber,
    };
  }

  factory AdvancePayment.fromJson(Map<String, dynamic> json) {
    return AdvancePayment(
      date: _dateTimeFromJson(json['date']) ?? DateTime.now(),
      mode: AdvanceMode.values.firstWhere(
        (value) =>
            value.name ==
            ((json['mode'] as String?) ?? (json['metal'] as String?) ?? ''),
        orElse: () => AdvanceMode.cash,
      ),
      amount: (json['amount'] as num).toDouble(),
      rate: (json['rate'] as num).toDouble(),
      making: (json['making'] as num).toDouble(),
      weight: (json['weight'] as num).toDouble(),
      gstApplied: json['gstApplied'] as bool? ?? false,
      chequeNumber: json['chequeNumber'] as String?,
    );
  }
}

class TakeawayPayment {
  const TakeawayPayment({
    required this.date,
    required this.mode,
    required this.amount,
    this.chequeNumber,
  });

  final DateTime date;
  final AdvanceMode mode;
  final double amount;
  final String? chequeNumber;

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'mode': mode.name,
      'amount': amount,
      'chequeNumber': chequeNumber,
    };
  }

  factory TakeawayPayment.fromJson(Map<String, dynamic> json) {
    return TakeawayPayment(
      date: _dateTimeFromJson(json['date']) ?? DateTime.now(),
      mode: AdvanceMode.values.firstWhere(
        (value) => value.name == ((json['mode'] as String?) ?? ''),
        orElse: () => AdvanceMode.cash,
      ),
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      chequeNumber: json['chequeNumber'] as String?,
    );
  }
}

class NewOrderItem {
  const NewOrderItem({
    required this.name,
    required this.category,
    required this.bhav,
    required this.makingType,
    required this.makingCharge,
    required this.grossWeight,
    required this.lessWeight,
    required this.additionalCharge,
    required this.gstEnabled,
    this.gstLockedOn = false,
    this.sourceTagId,
    this.isDifferenceEntry = false,
    this.notes,
  });

  final String name;
  final String category;
  final double bhav;
  final String makingType;
  final double makingCharge;
  final double grossWeight;
  final double lessWeight;
  final double additionalCharge;
  final bool gstEnabled;
  final bool gstLockedOn;
  final String? sourceTagId;
  final bool isDifferenceEntry;
  final String? notes;

  double get netWeight {
    final value = grossWeight - lessWeight;
    return value > 0 ? value : 0;
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'category': category,
      'bhav': bhav,
      'makingType': makingType,
      'makingCharge': makingCharge,
      'grossWeight': grossWeight,
      'lessWeight': lessWeight,
      'additionalCharge': additionalCharge,
      'gstEnabled': gstEnabled,
      'gstLockedOn': gstLockedOn,
      'sourceTagId': sourceTagId,
      'isDifferenceEntry': isDifferenceEntry,
      'notes': notes,
    };
  }

  factory NewOrderItem.fromJson(Map<String, dynamic> json) {
    return NewOrderItem(
      name: json['name'] as String? ?? '',
      category: json['category'] as String? ?? 'Gold22kt',
      bhav: (json['bhav'] as num?)?.toDouble() ?? 0,
      makingType: json['makingType'] as String? ?? 'Percentage',
      makingCharge: (json['makingCharge'] as num?)?.toDouble() ?? 0,
      grossWeight: (json['grossWeight'] as num?)?.toDouble() ?? 0,
      lessWeight: (json['lessWeight'] as num?)?.toDouble() ?? 0,
      additionalCharge: (json['additionalCharge'] as num?)?.toDouble() ?? 0,
      gstEnabled: json['gstEnabled'] as bool? ?? true,
      gstLockedOn: json['gstLockedOn'] as bool? ?? false,
      sourceTagId: json['sourceTagId'] as String?,
      isDifferenceEntry: json['isDifferenceEntry'] as bool? ?? false,
      notes: json['notes'] as String?,
    );
  }
}

class AdvanceValuationLine {
  const AdvanceValuationLine({
    required this.date,
    required this.mode,
    required this.amount,
    required this.rate,
    required this.rateMaking,
    this.gstApplied = false,
    this.chequeNumber,
  });

  final DateTime date;
  final AdvanceMode mode;
  final double amount;
  final double rate;
  final double rateMaking;
  final bool gstApplied;
  final String? chequeNumber;

  static const double gstPercent = 3;

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

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'mode': mode.name,
      'amount': amount,
      'rate': rate,
      'rateMaking': rateMaking,
      'gstApplied': gstApplied,
      'chequeNumber': chequeNumber,
    };
  }

  factory AdvanceValuationLine.fromJson(Map<String, dynamic> json) {
    final legacyRate = (json['rate'] as num?)?.toDouble() ?? 0;
    final legacyWeight = (json['weight'] as num?)?.toDouble() ?? 0;
    return AdvanceValuationLine(
      date: _dateTimeFromJson(json['date']) ?? DateTime.now(),
      mode: AdvanceMode.values.firstWhere(
        (value) =>
            value.name ==
            ((json['mode'] as String?) ?? (json['metal'] as String?) ?? ''),
        orElse: () => AdvanceMode.cash,
      ),
      amount:
          (json['amount'] as num?)?.toDouble() ?? (legacyWeight * legacyRate),
      rate: legacyRate,
      rateMaking: (json['rateMaking'] as num?)?.toDouble() ?? 0,
      gstApplied: json['gstApplied'] as bool? ?? false,
      chequeNumber: json['chequeNumber'] as String?,
    );
  }
}

class OldItemReturn {
  const OldItemReturn({
    required this.date,
    required this.itemName,
    required this.returnRate,
    required this.advanceRate,
    required this.advanceMaking,
    required this.grossWeight,
    required this.lessWeight,
    required this.tanch,
  });

  final DateTime date;
  final String itemName;
  final double returnRate;
  final double advanceRate;
  final double advanceMaking;
  final double grossWeight;
  final double lessWeight;
  final double tanch;

  double get nettWeight {
    final value = grossWeight - lessWeight;
    return value > 0 ? value : 0;
  }

  double get amount => nettWeight * tanch * returnRate;

  double get advanceEffectiveRate {
    return _truncateTo3Decimals(
      advanceRate + ((advanceRate * advanceMaking) / 100),
    );
  }

  double get advanceWeight {
    return _netWeightFromRateWithMaking(amount, advanceEffectiveRate);
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'itemName': itemName,
      'returnRate': returnRate,
      'advanceRate': advanceRate,
      'advanceMaking': advanceMaking,
      'grossWeight': grossWeight,
      'lessWeight': lessWeight,
      'tanch': tanch,
      'amount': amount,
    };
  }

  factory OldItemReturn.fromJson(Map<String, dynamic> json) {
    return OldItemReturn(
      date: _dateTimeFromJson(json['date']) ?? DateTime.now(),
      itemName: json['itemName'] as String? ?? '',
      returnRate: (json['returnRate'] as num?)?.toDouble() ?? 0,
      advanceRate: (json['advanceRate'] as num?)?.toDouble() ?? 0,
      advanceMaking: (json['advanceMaking'] as num?)?.toDouble() ?? 0,
      grossWeight: (json['grossWeight'] as num?)?.toDouble() ?? 0,
      lessWeight: (json['lessWeight'] as num?)?.toDouble() ?? 0,
      tanch: (json['tanch'] as num?)?.toDouble() ?? 0,
    );
  }
}

DateTime? _dateTimeFromJson(dynamic value) {
  if (value == null) {
    return null;
  }
  if (value is num) {
    return DateTime.fromMillisecondsSinceEpoch(value.toInt());
  }

  final text = value.toString().trim();
  if (text.isEmpty || text.toLowerCase() == 'null') {
    return null;
  }

  return DateTime.tryParse(text);
}

OrderStatus _orderStatusFromName(String value) {
  return OrderStatus.values.firstWhere(
    (status) => status.name == value,
    orElse: () => OrderStatus.pending,
  );
}

extension OrderStatusX on OrderStatus {
  String get label {
    switch (this) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.preparing:
        return 'Preparing';
      case OrderStatus.outForDelivery:
        return 'Ready';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.canceled:
        return 'Canceled';
    }
  }

  IconData get icon {
    switch (this) {
      case OrderStatus.pending:
        return Icons.hourglass_bottom_outlined;
      case OrderStatus.preparing:
        return Icons.inventory_2_outlined;
      case OrderStatus.outForDelivery:
        return Icons.local_shipping_outlined;
      case OrderStatus.delivered:
        return Icons.check_circle_outline;
      case OrderStatus.canceled:
        return Icons.cancel_outlined;
    }
  }

  Color color(BuildContext context) {
    switch (this) {
      case OrderStatus.pending:
        return Colors.orange.shade600;
      case OrderStatus.preparing:
        return Colors.blue.shade600;
      case OrderStatus.outForDelivery:
        return Colors.indigo.shade600;
      case OrderStatus.delivered:
        return Colors.green.shade600;
      case OrderStatus.canceled:
        return Colors.red.shade600;
    }
  }
}

extension AdvanceModeX on AdvanceMode {
  String get label {
    switch (this) {
      case AdvanceMode.cash:
        return 'Cash';
      case AdvanceMode.upi:
        return 'UPI';
      case AdvanceMode.banking:
        return 'Cheque';
      case AdvanceMode.imps:
        return 'IMPS';
      case AdvanceMode.neft:
        return 'NEFT';
      case AdvanceMode.rtgs:
        return 'RTGS';
    }
  }
}

extension OrderSortOptionX on OrderSortOption {
  String get label {
    switch (this) {
      case OrderSortOption.newest:
        return 'Newest First';
      case OrderSortOption.deliveryLatest:
        return 'Delivery Date';
      case OrderSortOption.nameAZ:
        return 'Name A-Z';
    }
  }
}

extension AppAccessRoleX on AppAccessRole {
  String get label {
    switch (this) {
      case AppAccessRole.admin:
        return 'Admin';
      case AppAccessRole.staff:
        return 'Staff';
      case AppAccessRole.user:
        return 'User';
    }
  }
}
