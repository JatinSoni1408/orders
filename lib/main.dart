import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

void main() {
  runApp(const OrderApp());
}

enum OrderStatus { pending, preparing, outForDelivery, delivered, canceled }

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

class OrderApp extends StatelessWidget {
  const OrderApp({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(seedColor: Colors.teal);
    return MaterialApp(
      title: 'Jewellery Orders',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: colorScheme,
        scaffoldBackgroundColor: const Color(0xFFF9F4EE),
        appBarTheme: AppBarTheme(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          centerTitle: false,
        ),
        cardTheme: const CardThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
          elevation: 1.5,
        ),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
        ),
      ),
      home: const OrdersDashboard(),
    );
  }
}

class OrdersDashboard extends StatefulWidget {
  const OrdersDashboard({super.key});

  @override
  State<OrdersDashboard> createState() => _OrdersDashboardState();
}

class _OrdersDashboardState extends State<OrdersDashboard> {
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
          weight: 0.0,
          making: 80,
        ),
      ],
      total: 1840.00,
      status: OrderStatus.preparing,
      createdAt: DateTime.now().subtract(const Duration(minutes: 12)),
      customerPhone: '+1 415 555 0142',
      altCustomerPhone: '+1 415 555 0143',
      customerPhotoPath: null,
      advancePayments: [
        AdvancePayment(
          date: DateTime.now().subtract(const Duration(days: 2)),
          amount: 450.00,
          rate: 52.75,
          making: 120.00,
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
          weight: 0.0,
          making: 140,
        ),
      ],
      total: 3250.00,
      status: OrderStatus.outForDelivery,
      createdAt: DateTime.now().subtract(const Duration(minutes: 25)),
      customerPhone: '+1 415 555 0188',
      altCustomerPhone: '+1 415 555 0199',
      customerPhotoPath: null,
      advancePayments: [
        AdvancePayment(
          date: DateTime.now().subtract(const Duration(days: 3)),
          amount: 800.00,
          rate: 53.10,
          making: 180.00,
          weight: 12.2,
        ),
        AdvancePayment(
          date: DateTime.now().subtract(const Duration(days: 1)),
          amount: 600.00,
          rate: 54.40,
          making: 140.00,
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
          weight: 0.0,
          making: 15,
        ),
      ],
      total: 980.00,
      status: OrderStatus.delivered,
      createdAt: DateTime.now().subtract(const Duration(hours: 1)),
      customerPhone: '+1 415 555 0126',
      altCustomerPhone: null,
      customerPhotoPath: null,
      advancePayments: [],
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
          weight: 0.0,
          making: 50,
        ),
      ],
      total: 760.00,
      status: OrderStatus.pending,
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      customerPhone: null,
      altCustomerPhone: null,
      advancePayments: [],
    ),
  ];

  OrderStatus? _selectedStatus;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

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
        return name.contains(query) || phone.contains(query);
      });
    }
    return results.toList();
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
          },
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final statuses = OrderStatus.values;
    final selectedIndex = _selectedStatus == null
        ? 0
        : statuses.indexOf(_selectedStatus!) + 1;
    final contentTopPadding = MediaQuery.of(context).padding.top + 16;

    return Scaffold(
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
            const Text('Orders'),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _openPrintPreview,
            icon: const Icon(Icons.print_outlined),
            tooltip: 'Print preview',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddOrderSheet,
        icon: const Icon(Icons.add),
        label: const Text('New order'),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedStatus = index == 0 ? null : statuses[index - 1];
          });
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
      ),
      body: SafeArea(
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
              Text(
                'Live orders',
                style: Theme.of(context).textTheme.titleMedium,
              ),
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
                      onEdit: () => _openEditOrderSheet(order),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order, required this.onEdit});

  final Order order;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final hasPickedPhoto =
        order.customerPhotoPath != null &&
        order.customerPhotoPath!.trim().isNotEmpty;
    ImageProvider? avatarImage;
    if (hasPickedPhoto) {
      avatarImage = FileImage(File(order.customerPhotoPath!));
    }
    return Card(
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 120),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: order.status.color(context).withAlpha(38),
                backgroundImage: avatarImage,
                child: avatarImage != null
                    ? null
                    : Text(
                        order.customer.substring(0, 1),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: order.status.color(context),
                        ),
                      ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            order.customer,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    if (order.customerPhone != null &&
                        order.customerPhone!.trim().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              order.customerPhone!,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: Colors.grey.shade700),
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      const SizedBox(height: 4),
                      const SizedBox.shrink(),
                    ],
                    if (order.altCustomerPhone != null &&
                        order.altCustomerPhone!.trim().isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Alt: ${order.altCustomerPhone!}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey.shade700,
                            ),
                      ),
                    ],
                    const Spacer(),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _StatusPill(status: order.status),
                  IconButton(
                    onPressed: onEdit,
                    icon: const Icon(Icons.remove_red_eye_outlined),
                    tooltip: 'View order',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final OrderStatus status;

  @override
  Widget build(BuildContext context) {
    final color = status.color(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(31),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 40,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 12),
            Text(
              'No jewellery orders yet',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              'Create your first jewellery order to get started.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade700),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Add order'),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderFormSheet extends StatefulWidget {
  const _OrderFormSheet({required this.onSave, this.initialOrder});

  final ValueChanged<Order> onSave;
  final Order? initialOrder;

  @override
  State<_OrderFormSheet> createState() => _OrderFormSheetState();
}

class _OrderFormSheetState extends State<_OrderFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _customerController = TextEditingController();
  final _phoneController = TextEditingController();
  final _altPhoneController = TextEditingController();
  String? _photoPath;
  final List<_OrderItemDraft> _itemDrafts = [];
  final List<_AdvancePaymentDraft> _advancePayments = [];
  OrderStatus _status = OrderStatus.pending;

  @override
  void initState() {
    super.initState();
    final existing = widget.initialOrder;
    if (existing == null) {
      _itemDrafts.add(_OrderItemDraft());
      _advancePayments.add(_AdvancePaymentDraft());
      _status = OrderStatus.pending;
      return;
    }
    _customerController.text = existing.customer;
    _phoneController.text = existing.customerPhone ?? '';
    _altPhoneController.text = existing.altCustomerPhone ?? '';
    _photoPath = existing.customerPhotoPath;
    if (existing.items.isEmpty) {
      _itemDrafts.add(_OrderItemDraft());
    } else {
      for (final item in existing.items) {
        _itemDrafts.add(_OrderItemDraft.fromItem(item));
      }
    }
    _status = existing.status;
    if (existing.advancePayments.isEmpty) {
      _advancePayments.add(_AdvancePaymentDraft());
      return;
    }
    for (final payment in existing.advancePayments) {
      _advancePayments.add(_AdvancePaymentDraft.fromPayment(payment));
    }
  }

  @override
  void dispose() {
    _customerController.dispose();
    _phoneController.dispose();
    _altPhoneController.dispose();
    for (final controller in _itemDrafts) {
      controller.dispose();
    }
    for (final payment in _advancePayments) {
      payment.dispose();
    }
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    final items = _itemDrafts
        .where((draft) => !draft.isEmpty)
        .map((draft) => draft.toItem())
        .toList();
    if (items.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Add at least one item')));
      return;
    }
    final total = items.fold<double>(0, (sum, item) {
      final base = item.bhav * item.weight * item.quantity;
      return sum + base + item.making;
    });
    final payments = _advancePayments
        .where((payment) => !payment.isEmpty)
        .map((payment) => payment.toPayment())
        .toList();
    final phone = _phoneController.text.trim();
    final altPhone = _altPhoneController.text.trim();
    final order = Order(
      id:
          widget.initialOrder?.id ??
          'JW-${DateTime.now().millisecondsSinceEpoch % 10000}',
      customer: _customerController.text.trim(),
      items: items,
      total: total,
      status: _status,
      createdAt: widget.initialOrder?.createdAt ?? DateTime.now(),
      advancePayments: payments,
      customerPhone: phone.isEmpty ? null : phone,
      altCustomerPhone: altPhone.isEmpty ? null : altPhone,
      customerPhotoPath: _photoPath,
    );
    widget.onSave(order);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 24,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              if (widget.initialOrder != null) ...[
                DropdownButtonFormField<OrderStatus>(
                  initialValue: _status,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: OrderStatus.values
                      .map(
                        (status) => DropdownMenuItem(
                          value: status,
                          child: Text(status.label),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      _status = value;
                    });
                  },
                ),
                const SizedBox(height: 12),
              ],
              Text(
                widget.initialOrder == null
                    ? 'Create jewellery order'
                    : 'Edit jewellery order',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _customerController,
                decoration: const InputDecoration(labelText: 'Customer name'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Enter a customer name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Mobile number'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Enter mobile number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _altPhoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Alternate mobile (optional)',
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final messenger = ScaffoldMessenger.of(context);
                        final picker = ImagePicker();
                        try {
                          final picked = await picker.pickImage(
                            source: ImageSource.gallery,
                          );
                          if (picked == null) return;
                          if (!mounted) return;
                          setState(() {
                            _photoPath = picked.path;
                          });
                        } on MissingPluginException {
                          if (!mounted) return;
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Image picking not available on this platform.',
                              ),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.photo_library_outlined),
                      label: const Text('Pick photo'),
                    ),
                  ),
                  if (_photoPath != null) ...[
                    const SizedBox(width: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        File(_photoPath!),
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Advance payments',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              ..._advancePayments.asMap().entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _AdvancePaymentEditor(
                    key: ValueKey(entry.value),
                    index: entry.key + 1,
                    payment: entry.value,
                    onRemove: _advancePayments.length == 1
                        ? null
                        : () {
                            setState(() {
                              final removed = _advancePayments.removeAt(
                                entry.key,
                              );
                              removed.dispose();
                            });
                          },
                    onDateChanged: () => setState(() {}),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _advancePayments.add(_AdvancePaymentDraft());
                    });
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add advance entry'),
                ),
              ),
              const SizedBox(height: 12),
              Text('Items', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              ..._itemDrafts.asMap().entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _OrderItemEditor(
                    index: entry.key + 1,
                    draft: entry.value,
                    onRemove: _itemDrafts.length == 1
                        ? null
                        : () {
                            setState(() {
                              final removed = _itemDrafts.removeAt(entry.key);
                              removed.dispose();
                            });
                          },
                    onChanged: () => setState(() {}),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _itemDrafts.add(_OrderItemDraft());
                    });
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add item'),
                ),
              ),
              const SizedBox(height: 4),
              const SizedBox(height: 12),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _submit,
                      child: Text(
                        widget.initialOrder == null ? 'Add order' : 'Save',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrderItemDraft {
  _OrderItemDraft()
    : date = DateTime.now(),
      nameController = TextEditingController(),
      categoryController = TextEditingController(),
      quantityController = TextEditingController(text: '1'),
      bhavController = TextEditingController(text: '0'),
      weightController = TextEditingController(text: '0'),
      makingController = TextEditingController(text: '0');

  _OrderItemDraft.fromItem(OrderItem item)
    : date = item.date,
      nameController = TextEditingController(text: item.name),
      categoryController = TextEditingController(text: item.category),
      quantityController = TextEditingController(
        text: item.quantity.toString(),
      ),
      bhavController = TextEditingController(text: item.bhav.toString()),
      weightController = TextEditingController(
        text: item.weight.toStringAsFixed(2),
      ),
      makingController = TextEditingController(
        text: item.making.toStringAsFixed(2),
      );

  DateTime date;
  final TextEditingController nameController;
  final TextEditingController categoryController;
  final TextEditingController quantityController;
  final TextEditingController bhavController;
  final TextEditingController weightController;
  final TextEditingController makingController;

  bool get isEmpty =>
      nameController.text.trim().isEmpty &&
      categoryController.text.trim().isEmpty &&
      (int.tryParse(quantityController.text.trim()) ?? 0) <= 0 &&
      (double.tryParse(bhavController.text.trim()) ?? 0) <= 0 &&
      (double.tryParse(weightController.text.trim()) ?? 0) <= 0 &&
      (double.tryParse(makingController.text.trim()) ?? 0) <= 0;

  OrderItem toItem() {
    final name = nameController.text.trim();
    final category = categoryController.text.trim().isEmpty
        ? 'General'
        : categoryController.text.trim();
    final quantity = int.tryParse(quantityController.text.trim()) ?? 1;
    final bhav = double.tryParse(bhavController.text.trim()) ?? 0;
    final weight = double.tryParse(weightController.text.trim()) ?? 0;
    final making = double.tryParse(makingController.text.trim()) ?? 0;
    return OrderItem(
      name: name,
      category: category,
      date: date,
      quantity: quantity <= 0 ? 1 : quantity,
      bhav: bhav < 0 ? 0 : bhav,
      weight: weight < 0 ? 0 : weight,
      making: making < 0 ? 0 : making,
    );
  }

  void dispose() {
    nameController.dispose();
    categoryController.dispose();
    quantityController.dispose();
    bhavController.dispose();
    weightController.dispose();
    makingController.dispose();
  }
}

class _AdvancePaymentDraft {
  _AdvancePaymentDraft()
    : date = DateTime.now(),
      amountController = TextEditingController(),
      rateController = TextEditingController(),
      makingController = TextEditingController(),
      weightController = TextEditingController();

  _AdvancePaymentDraft.fromPayment(AdvancePayment payment)
    : date = payment.date,
      amountController = TextEditingController(
        text: payment.amount.toStringAsFixed(2),
      ),
      rateController = TextEditingController(
        text: payment.rate.toStringAsFixed(2),
      ),
      makingController = TextEditingController(
        text: payment.making.toStringAsFixed(2),
      ),
      weightController = TextEditingController(
        text: payment.weight.toStringAsFixed(2),
      );

  DateTime date;
  final TextEditingController amountController;
  final TextEditingController rateController;
  final TextEditingController makingController;
  final TextEditingController weightController;

  bool get isEmpty {
    return amountController.text.trim().isEmpty &&
        rateController.text.trim().isEmpty &&
        makingController.text.trim().isEmpty &&
        weightController.text.trim().isEmpty;
  }

  double computeWeight() {
    final amount = double.tryParse(amountController.text.trim()) ?? 0;
    final rate = double.tryParse(rateController.text.trim()) ?? 0;
    final makingPercent = double.tryParse(makingController.text.trim()) ?? 0;
    final makingValue = rate * (makingPercent / 100);
    final denominator = rate + makingValue;
    if (denominator <= 0) return 0.0;
    return amount / denominator;
  }

  void syncWeightField() {
    final weight = computeWeight();
    weightController.text = weight.isFinite ? weight.toStringAsFixed(2) : '';
  }

  AdvancePayment toPayment() {
    final amount = double.parse(amountController.text.trim());
    final rate = double.parse(rateController.text.trim());
    final makingPercent = double.parse(makingController.text.trim());
    final makingValue = rate * (makingPercent / 100);
    final denominator = rate + makingValue;
    final weight = denominator > 0 ? amount / denominator : 0.0;
    return AdvancePayment(
      date: date,
      amount: amount,
      rate: rate,
      making: makingPercent,
      weight: weight,
    );
  }

  void dispose() {
    amountController.dispose();
    rateController.dispose();
    makingController.dispose();
    weightController.dispose();
  }
}

class _OrderItemEditor extends StatelessWidget {
  const _OrderItemEditor({
    required this.index,
    required this.draft,
    this.onRemove,
    required this.onChanged,
  });

  final int index;
  final _OrderItemDraft draft;
  final VoidCallback? onRemove;
  final VoidCallback onChanged;

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
            _DateField(
              date: draft.date,
              onDateSelected: (selected) {
                draft.date = selected;
                onChanged();
              },
            ),
            const SizedBox(height: 8),
            Builder(
              builder: (context) {
                const categories = ['Gold 22 KT', 'Gold 18 KT', 'Silver'];
                final initialCategory =
                    categories.contains(draft.categoryController.text)
                    ? draft.categoryController.text
                    : null;
                return DropdownButtonFormField<String>(
                  initialValue: initialCategory,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: categories
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (value) {
                    draft.categoryController.text = value ?? '';
                    onChanged();
                  },
                  validator: (value) {
                    if (index == 1 && (value == null || value.isEmpty)) {
                      return 'Select category';
                    }
                    return null;
                  },
                );
              },
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: draft.nameController,
              decoration: const InputDecoration(labelText: 'Item name'),
              validator: (value) {
                if (index == 1) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Enter an item name';
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: draft.quantityController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Qty'),
                    validator: (value) {
                      final parsed = int.tryParse(value ?? '');
                      if (parsed == null || parsed <= 0) {
                        return 'Qty';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: draft.bhavController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(labelText: 'Bhav'),
                    validator: (value) {
                      final parsed = double.tryParse(value ?? '');
                      if (parsed == null || parsed < 0) {
                        return 'Bhav';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: draft.weightController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Weight',
                      suffixText: 'g',
                    ),
                    validator: (value) {
                      final parsed = double.tryParse(value ?? '');
                      if (parsed == null || parsed <= 0) {
                        return 'Weight';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: draft.makingController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(labelText: 'Making'),
                    validator: (value) {
                      final parsed = double.tryParse(value ?? '');
                      if (parsed == null || parsed < 0) {
                        return 'Making';
                      }
                      return null;
                    },
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

class _AdvancePaymentEditor extends StatelessWidget {
  const _AdvancePaymentEditor({
    super.key,
    required this.index,
    required this.payment,
    this.onRemove,
    required this.onDateChanged,
  });

  final int index;
  final _AdvancePaymentDraft payment;
  final VoidCallback? onRemove;
  final VoidCallback onDateChanged;

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
                    'Entry $index',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (onRemove != null)
                  IconButton(
                    onPressed: onRemove,
                    icon: const Icon(Icons.delete_outline),
                    tooltip: 'Remove entry',
                  ),
              ],
            ),
            const SizedBox(height: 8),
            _DateField(
              date: payment.date,
              onDateSelected: (selected) {
                payment.date = selected;
                onDateChanged();
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: payment.amountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Amount',
                      prefixText: '₹',
                    ),
                    onChanged: (_) {
                      payment.syncWeightField();
                      onDateChanged();
                    },
                    validator: (value) {
                      if (payment.isEmpty) {
                        return null;
                      }
                      final parsed = double.tryParse(value ?? '');
                      if (parsed == null || parsed <= 0) {
                        return 'Amount';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: payment.rateController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Rate'),
                    onChanged: (_) {
                      payment.syncWeightField();
                      onDateChanged();
                    },
                    validator: (value) {
                      if (payment.isEmpty) {
                        return null;
                      }
                      final parsed = double.tryParse(value ?? '');
                      if (parsed == null || parsed <= 0) {
                        return 'Rate';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: payment.makingController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Making (%)',
                      suffixText: '%',
                    ),
                    onChanged: (_) {
                      payment.syncWeightField();
                      onDateChanged();
                    },
                    validator: (value) {
                      if (payment.isEmpty) {
                        return null;
                      }
                      final parsed = double.tryParse(value ?? '');
                      if (parsed == null || parsed < 0) {
                        return 'Making %';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: payment.weightController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Weight',
                      suffixText: 'g',
                    ),
                    enabled: false,
                    // weight is derived: amount / (rate + making)
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

class _DateField extends StatelessWidget {
  const _DateField({required this.date, required this.onDateSelected});

  final DateTime date;
  final ValueChanged<DateTime> onDateSelected;

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
        decoration: const InputDecoration(
          labelText: 'Date',
          border: OutlineInputBorder(),
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

class _PrintPreviewSheet extends StatelessWidget {
  const _PrintPreviewSheet({required this.orders, required this.totalRevenue});

  final List<Order> orders;
  final double totalRevenue;

  @override
  Widget build(BuildContext context) {
    final avgOrder = orders.isEmpty
        ? 0.0
        : totalRevenue / orders.length.toDouble();
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.print_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Print preview',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Jewellery sales summary',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade700),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: _PreviewMetric(
                        label: 'Orders',
                        value: orders.length.toString(),
                      ),
                    ),
                    Expanded(
                      child: _PreviewMetric(
                        label: 'Revenue',
                        value: '₹${totalRevenue.toStringAsFixed(2)}',
                      ),
                    ),
                    Expanded(
                      child: _PreviewMetric(
                        label: 'Avg order',
                        value: '₹${avgOrder.toStringAsFixed(2)}',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Jewellery orders',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _PreviewRow(
                      leading: 'ID',
                      middle: 'Customer',
                      trailing: 'Total',
                      isHeader: true,
                    ),
                    const Divider(),
                    ...orders.map(
                      (order) => _PreviewRow(
                        leading: order.id,
                        middle: order.customer,
                        trailing: '₹${order.total.toStringAsFixed(2)}',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Close'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Print preview only.')),
                      );
                    },
                    icon: const Icon(Icons.print),
                    label: const Text('Print'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _PreviewMetric extends StatelessWidget {
  const _PreviewMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade700),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _PreviewRow extends StatelessWidget {
  const _PreviewRow({
    required this.leading,
    required this.middle,
    required this.trailing,
    this.isHeader = false,
  });

  final String leading;
  final String middle;
  final String trailing;
  final bool isHeader;

  @override
  Widget build(BuildContext context) {
    final style = isHeader
        ? Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700)
        : Theme.of(context).textTheme.bodySmall;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(leading, style: style)),
          Expanded(flex: 3, child: Text(middle, style: style)),
          Expanded(
            flex: 2,
            child: Text(trailing, style: style, textAlign: TextAlign.end),
          ),
        ],
      ),
    );
  }
}

String _formatEntryDate(DateTime dateTime) {
  final month = _monthLabel(dateTime.month);
  return '${dateTime.day} $month ${dateTime.year}';
}

String _monthLabel(int month) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return months[(month - 1).clamp(0, 11)];
}
