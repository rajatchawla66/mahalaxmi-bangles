import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mahalaxmi_shared/models/customer.dart';
import 'package:mahalaxmi_shared/providers/repository_providers.dart';
import '../providers/admin_customers_provider.dart';

class CustomerEditPage extends ConsumerStatefulWidget {
  final int customerId;

  const CustomerEditPage({super.key, required this.customerId});

  @override
  ConsumerState<CustomerEditPage> createState() => _CustomerEditPageState();
}

class _CustomerEditPageState extends ConsumerState<CustomerEditPage> {
  final _shopNameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _pinController = TextEditingController();
  final _ownerNameController = TextEditingController();
  bool _isActive = true;
  bool _saving = false;
  bool _dataLoaded = false;

  @override
  void dispose() {
    _shopNameController.dispose();
    _mobileController.dispose();
    _pinController.dispose();
    _ownerNameController.dispose();
    super.dispose();
  }

  void _initFromCustomer(Customer customer) {
    if (_dataLoaded) return;
    _dataLoaded = true;
    _shopNameController.text = customer.shopName;
    _mobileController.text = customer.mobile;
    _pinController.text = customer.pin;
    _ownerNameController.text = customer.ownerName;
    _isActive = customer.isActive;
  }

  Future<void> _save() async {
    final messenger = ScaffoldMessenger.of(context);

    final shopName = _shopNameController.text.trim();
    if (shopName.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Shop name is required'), behavior: SnackBarBehavior.floating, backgroundColor: Colors.red),
      );
      return;
    }

    final pin = _pinController.text.trim();
    if (pin.length != 8 || !RegExp(r'^\d{8}$').hasMatch(pin)) {
      messenger.showSnackBar(
        const SnackBar(content: Text('PIN must be exactly 8 digits'), behavior: SnackBarBehavior.floating, backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final repo = ref.read(customerRepositoryProvider);

      await repo.updateCustomerShopName(widget.customerId, shopName);
      await repo.updateCustomerMobile(widget.customerId, _mobileController.text.trim());
      await repo.updateCustomerPin(widget.customerId, pin);
      await repo.updateCustomerField(widget.customerId, 'owner_name', _ownerNameController.text.trim());
      await repo.updateCustomerActiveStatus(widget.customerId, _isActive);

      // ignore: unused_result
      ref.refresh(adminCustomersProvider);

      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('Customer updated'), behavior: SnackBarBehavior.floating),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('Failed to save: $e'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final customersAsync = ref.watch(adminCustomersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Customer'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Save', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
      body: customersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (customers) {
          final customer = customers.where((c) => c.id == widget.customerId).firstOrNull;
          if (customer == null) {
            return const Center(child: Text('Customer not found'));
          }

          _initFromCustomer(customer);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Active toggle
              Card(
                child: SwitchListTile(
                  title: const Text('Active'),
                  subtitle: Text(_isActive ? 'Customer can log in' : 'Customer cannot log in'),
                  value: _isActive,
                  onChanged: (v) => setState(() => _isActive = v),
                ),
              ),

              const SizedBox(height: 8),

              // Shop Name
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Shop / Customer Name', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _shopNameController,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // Owner Name
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Owner Name', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _ownerNameController,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // Mobile
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Mobile Number', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _mobileController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // PIN
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('PIN (8 digits)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      const SizedBox(height: 4),
                      Text('Changing PIN will require customer to use the new PIN',
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _pinController,
                        keyboardType: TextInputType.number,
                        maxLength: 8,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          counterText: '',
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 40),
            ],
          );
        },
      ),
    );
  }
}
