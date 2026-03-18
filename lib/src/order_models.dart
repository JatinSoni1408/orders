part of '../main.dart';

enum OrderStatus { pending, preparing, outForDelivery, delivered, canceled }

enum AppSection { orders, estimateCalculator }

class Order {
  Order({
    required this.id,
    required this.customer,
    required this.items,
    required this.total,
    required this.status,
    required this.createdAt,
    List<AdvancePayment>? advancePayments,
    this.customerPhone,
    this.altCustomerPhone,
    this.customerPhotoPath,
  }) : advancePayments = advancePayments ?? const [];

  final String id;
  final String customer;
  final List<OrderItem> items;
  final double total;
  final OrderStatus status;
  final DateTime createdAt;
  final List<AdvancePayment> advancePayments;
  final String? customerPhone;
  final String? altCustomerPhone;
  final String? customerPhotoPath;

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
      'customerPhone': customerPhone,
      'altCustomerPhone': altCustomerPhone,
      'customerPhotoPath': customerPhotoPath,
    };
  }

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] as String,
      customer: json['customer'] as String,
      items: (json['items'] as List<dynamic>)
          .map((item) => OrderItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      total: (json['total'] as num).toDouble(),
      status: _orderStatusFromName(json['status'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      advancePayments: (json['advancePayments'] as List<dynamic>? ?? const [])
          .map(
            (payment) =>
                AdvancePayment.fromJson(payment as Map<String, dynamic>),
          )
          .toList(),
      customerPhone: json['customerPhone'] as String?,
      altCustomerPhone: json['altCustomerPhone'] as String?,
      customerPhotoPath: json['customerPhotoPath'] as String?,
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
  });

  final String name;
  final String category;
  final DateTime date;
  final int quantity;
  final double bhav;
  final double weight;
  final double making;

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'category': category,
      'date': date.toIso8601String(),
      'quantity': quantity,
      'bhav': bhav,
      'weight': weight,
      'making': making,
    };
  }

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      name: json['name'] as String,
      category: json['category'] as String,
      date: DateTime.parse(json['date'] as String),
      quantity: json['quantity'] as int,
      bhav: (json['bhav'] as num).toDouble(),
      weight: (json['weight'] as num).toDouble(),
      making: (json['making'] as num).toDouble(),
    );
  }
}

class AdvancePayment {
  const AdvancePayment({
    required this.date,
    required this.amount,
    required this.rate,
    required this.making,
    required this.weight,
  });

  final DateTime date;
  final double amount;
  final double rate;
  final double making;
  final double weight;

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'amount': amount,
      'rate': rate,
      'making': making,
      'weight': weight,
    };
  }

  factory AdvancePayment.fromJson(Map<String, dynamic> json) {
    return AdvancePayment(
      date: DateTime.parse(json['date'] as String),
      amount: (json['amount'] as num).toDouble(),
      rate: (json['rate'] as num).toDouble(),
      making: (json['making'] as num).toDouble(),
      weight: (json['weight'] as num).toDouble(),
    );
  }
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
