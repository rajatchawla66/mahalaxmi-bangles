import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mahalaxmi_shared/providers/repository_providers.dart';
import '../providers/admin_customers_provider.dart';

class CustomerCreatePage extends ConsumerStatefulWidget {
  const CustomerCreatePage({super.key});

  @override
  ConsumerState<CustomerCreatePage> createState() => _CustomerCreatePageState();
}

class _CustomerCreatePageState extends ConsumerState<CustomerCreatePage> {
  final _shopNameCtrl = TextEditingController();
  final _mobileCtrl = TextEditingController();
  final _pinCtrl = TextEditingController();
  final _ownerNameCtrl = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _generatePin();
  }

  @override
  void dispose() {
    _shopNameCtrl.dispose();
    _mobileCtrl.dispose();
    _pinCtrl.dispose();
    _ownerNameCtrl.dispose();
    super.dispose();
  }

  Future<void> _generatePin() async {
    final rng = Random();
    for (int attempt = 0; attempt < 20; attempt++) {
      final pin = (10000000 + rng.nextInt(90000000)).toString();
      final exists = await ref.read(customerRepositoryProvider).customerExistsByPin(pin);
      if (!exists) {
        _pinCtrl.text = pin;
        return;
      }
    }
    _pinCtrl.text = (10000000 + rng.nextInt(90000000)).toString();
  }

  Future<void> _save() async {
    final messenger = ScaffoldMessenger.of(context);

    final shopName = _shopNameCtrl.text.trim();
    if (shopName.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Shop name is required'), behavior: SnackBarBehavior.floating, backgroundColor: Colors.red),
      );
      return;
    }

    final pin = _pinCtrl.text.trim();
    if (pin.length != 8 || !RegExp(r'^\d{8}$').hasMatch(pin)) {
      messenger.showSnackBar(
        const SnackBar(content: Text('PIN must be exactly 8 digits'), behavior: SnackBarBehavior.floating, backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final repo = ref.read(customerRepositoryProvider);

      final shopExists = await repo.customerExistsByShopName(shopName);
      if (shopExists) {
        if (!mounted) return;
        messenger.showSnackBar(
          const SnackBar(content: Text('A customer with this shop name already exists'), behavior: SnackBarBehavior.floating, backgroundColor: Colors.red),
        );
        setState(() => _isSaving = false);
        return;
      }

      final mobile = _mobileCtrl.text.trim();
      if (mobile.isNotEmpty) {
        final mobileExists = await repo.customerExistsByMobile(mobile);
        if (mobileExists) {
          if (!mounted) return;
          messenger.showSnackBar(
            const SnackBar(content: Text('A customer with this mobile already exists'), behavior: SnackBarBehavior.floating, backgroundColor: Colors.red),
          );
          setState(() => _isSaving = false);
          return;
        }
      }

      final pinExists = await repo.customerExistsByPin(pin);
      if (pinExists) {
        if (!mounted) return;
        messenger.showSnackBar(
          const SnackBar(content: Text('A customer with this PIN already exists'), behavior: SnackBarBehavior.floating, backgroundColor: Colors.red),
        );
        setState(() => _isSaving = false);
        return;
      }

      await repo.insertCustomer({
        'shop_name': shopName,
        'pin': pin,
        'owner_name': _ownerNameCtrl.text.trim(),
        'mobile': mobile,
        'is_active': true,
      });

      // ignore: unused_result
      ref.refresh(adminCustomersProvider);

      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Customer "$shopName" created'), behavior: SnackBarBehavior.floating),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Failed: $e'), behavior: SnackBarBehavior.floating, backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Customer'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.canPop() ? context.pop() : context.go('/customers'),
        ),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Save', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Shop Name
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Shop / Customer Name *', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _shopNameCtrl,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      hintText: 'Enter shop or customer name',
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
                  const SizedBox(height: 4),
                  Text('Optional', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _ownerNameCtrl,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      hintText: 'Enter owner name',
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
                  const SizedBox(height: 4),
                  Text('Optional', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _mobileCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      hintText: 'Enter mobile number',
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
                  const Text('PIN (8 digits) *', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text('Generated automatically. You can edit it.', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _pinCtrl,
                          keyboardType: TextInputType.number,
                          maxLength: 8,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            counterText: '',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: _generatePin,
                        icon: const Icon(Icons.refresh, size: 18),
                        label: const Text('Regen', style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
