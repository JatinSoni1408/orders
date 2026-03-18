part of '../main.dart';

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
  final List<_OrderItemDraft> _itemDrafts = [];
  final List<_AdvancePaymentDraft> _advancePayments = [];

  String? _photoPath;
  OrderStatus _status = OrderStatus.pending;

  @override
  void initState() {
    super.initState();

    final existing = widget.initialOrder;
    if (existing == null) {
      _itemDrafts.add(_OrderItemDraft());
      _advancePayments.add(_AdvancePaymentDraft());
      return;
    }

    _customerController.text = existing.customer;
    _phoneController.text = existing.customerPhone ?? '';
    _altPhoneController.text = existing.altCustomerPhone ?? '';
    _photoPath = existing.customerPhotoPath;
    _status = existing.status;

    if (existing.items.isEmpty) {
      _itemDrafts.add(_OrderItemDraft());
    } else {
      for (final item in existing.items) {
        _itemDrafts.add(_OrderItemDraft.fromItem(item));
      }
    }

    if (existing.advancePayments.isEmpty) {
      _advancePayments.add(_AdvancePaymentDraft());
    } else {
      for (final payment in existing.advancePayments) {
        _advancePayments.add(_AdvancePaymentDraft.fromPayment(payment));
      }
    }
  }

  @override
  void dispose() {
    _customerController.dispose();
    _phoneController.dispose();
    _altPhoneController.dispose();
    for (final draft in _itemDrafts) {
      draft.dispose();
    }
    for (final payment in _advancePayments) {
      payment.dispose();
    }
    super.dispose();
  }

  Future<void> _pickCustomerPhoto() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (!mounted || file == null) {
      return;
    }

    setState(() {
      _photoPath = file.path;
    });
  }

  void _saveOrder() {
    if (!_formKey.currentState!.validate()) {
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

    final payments = _advancePayments
        .where((payment) => !payment.isEmpty)
        .map((payment) => payment.toPayment())
        .toList();

    final total = items.fold<double>(
      0,
      (sum, item) => sum + item.bhav * item.weight * item.quantity + item.making,
    );

    final existing = widget.initialOrder;
    final order = Order(
      id: existing?.id ?? 'JW-${DateTime.now().millisecondsSinceEpoch % 10000}',
      customer: _customerController.text.trim(),
      items: items,
      total: total,
      status: _status,
      createdAt: existing?.createdAt ?? DateTime.now(),
      advancePayments: payments,
      customerPhone: _phoneController.text.trim().isEmpty
          ? null
          : _phoneController.text.trim(),
      altCustomerPhone: _altPhoneController.text.trim().isEmpty
          ? null
          : _altPhoneController.text.trim(),
      customerPhotoPath: _photoPath,
    );

    widget.onSave(order);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final statusOptions = OrderStatus.values;

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.initialOrder == null ? 'New order' : 'Edit order',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundImage: _photoPath != null && _photoPath!.isNotEmpty
                        ? FileImage(File(_photoPath!))
                        : null,
                    child: _photoPath == null || _photoPath!.isEmpty
                        ? const Icon(Icons.person_outline)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: _pickCustomerPhoto,
                    icon: const Icon(Icons.photo_camera_back_outlined),
                    label: const Text('Customer photo'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _customerController,
                decoration: const InputDecoration(labelText: 'Customer name'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Enter customer name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9+\-\s]')),
                ],
                decoration: const InputDecoration(labelText: 'Primary mobile'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _altPhoneController,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9+\-\s]')),
                ],
                decoration: const InputDecoration(labelText: 'Alternate mobile'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<OrderStatus>(
                initialValue: _status,
                decoration: const InputDecoration(labelText: 'Status'),
                items: statusOptions
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
                    _status = value;
                  });
                },
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Text(
                    'Items',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _itemDrafts.add(_OrderItemDraft());
                      });
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Add item'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...List.generate(_itemDrafts.length, (index) {
                final draft = _itemDrafts[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _OrderItemEditor(
                    index: index + 1,
                    draft: draft,
                    onChanged: () => setState(() {}),
                    onRemove: _itemDrafts.length == 1
                        ? null
                        : () {
                            setState(() {
                              final removed = _itemDrafts.removeAt(index);
                              removed.dispose();
                            });
                          },
                  ),
                );
              }),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    'Advance payments',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _advancePayments.add(_AdvancePaymentDraft());
                      });
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Add entry'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...List.generate(_advancePayments.length, (index) {
                final payment = _advancePayments[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _AdvancePaymentEditor(
                    index: index + 1,
                    payment: payment,
                    onDateChanged: () => setState(() {}),
                    onRemove: _advancePayments.length == 1
                        ? null
                        : () {
                            setState(() {
                              final removed = _advancePayments.removeAt(index);
                              removed.dispose();
                            });
                          },
                  ),
                );
              }),
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
                      onPressed: _saveOrder,
                      child: const Text('Save order'),
                    ),
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

class _OrderItemDraft {
  _OrderItemDraft({
    DateTime? date,
    String? name,
    String? category,
    int? quantity,
    double? bhav,
    double? weight,
    double? making,
  }) : date = date ?? DateTime.now(),
       nameController = TextEditingController(text: name ?? ''),
       categoryController = TextEditingController(text: category ?? ''),
       quantityController = TextEditingController(
         text: quantity?.toString() ?? '1',
       ),
       bhavController = TextEditingController(text: bhav?.toString() ?? ''),
       weightController = TextEditingController(text: weight?.toString() ?? ''),
       makingController = TextEditingController(text: making?.toString() ?? '');

  factory _OrderItemDraft.fromItem(OrderItem item) {
    return _OrderItemDraft(
      date: item.date,
      name: item.name,
      category: item.category,
      quantity: item.quantity,
      bhav: item.bhav,
      weight: item.weight,
      making: item.making,
    );
  }

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
      (double.tryParse(weightController.text.trim()) ?? 0) == 0 &&
      (double.tryParse(makingController.text.trim()) ?? 0) == 0;

  OrderItem toItem() {
    return OrderItem(
      name: nameController.text.trim(),
      category: categoryController.text.trim(),
      date: date,
      quantity: int.parse(quantityController.text.trim()),
      bhav: double.parse(bhavController.text.trim()),
      weight: double.parse(weightController.text.trim()),
      making: double.parse(makingController.text.trim()),
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
  _AdvancePaymentDraft({
    DateTime? date,
    double? amount,
    double? rate,
    double? making,
    double? weight,
  }) : date = date ?? DateTime.now(),
       amountController = TextEditingController(text: amount?.toString() ?? ''),
       rateController = TextEditingController(text: rate?.toString() ?? ''),
       makingController = TextEditingController(text: making?.toString() ?? ''),
       weightController = TextEditingController(text: weight?.toString() ?? '');

  factory _AdvancePaymentDraft.fromPayment(AdvancePayment payment) {
    return _AdvancePaymentDraft(
      date: payment.date,
      amount: payment.amount,
      rate: payment.rate,
      making: payment.making,
      weight: payment.weight,
    );
  }

  DateTime date;
  final TextEditingController amountController;
  final TextEditingController rateController;
  final TextEditingController makingController;
  final TextEditingController weightController;

  bool get isEmpty =>
      amountController.text.trim().isEmpty &&
      rateController.text.trim().isEmpty &&
      makingController.text.trim().isEmpty;

  double computeWeight() {
    final amount = double.tryParse(amountController.text.trim()) ?? 0;
    final rate = double.tryParse(rateController.text.trim()) ?? 0;
    final makingPercent = double.tryParse(makingController.text.trim()) ?? 0;
    final makingValue = rate * (makingPercent / 100);
    final denominator = rate + makingValue;
    if (denominator <= 0) {
      return 0;
    }
    return amount / denominator;
  }

  void syncWeightField() {
    final weight = computeWeight();
    weightController.text = weight > 0 ? _formatWeight3(weight) : '';
  }

  AdvancePayment toPayment() {
    final amount = double.parse(amountController.text.trim());
    final rate = double.parse(rateController.text.trim());
    final makingPercent = double.parse(makingController.text.trim());
    final weight = computeWeight();

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
    const categories = [
      'Ring',
      'Necklace',
      'Bracelet',
      'Earrings',
      'Service',
      'Packaging',
      'Setting',
    ];

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
            DropdownButtonFormField<String>(
              initialValue: categories.contains(draft.categoryController.text)
                  ? draft.categoryController.text
                  : null,
              decoration: const InputDecoration(labelText: 'Category'),
              items: categories
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (value) {
                draft.categoryController.text = value ?? '';
                onChanged();
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Select category';
                }
                return null;
              },
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: draft.nameController,
              decoration: const InputDecoration(labelText: 'Item name'),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Enter an item name';
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
                    decoration: const InputDecoration(labelText: 'Amount'),
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
