import 'package:riverpod/riverpod.dart';

import '../models/app_session.dart';
import '../models/customer.dart';
import '../repositories/customer_repository.dart';
import 'repository_providers.dart';
import 'session_provider.dart';

sealed class CustomerAuthFailure {
  const CustomerAuthFailure();
}

class InvalidPin extends CustomerAuthFailure {
  const InvalidPin();
}

class BlockedCustomer extends CustomerAuthFailure {
  const BlockedCustomer();
}

class CustomerNetworkError extends CustomerAuthFailure {
  final String message;
  const CustomerNetworkError(this.message);
}

class CustomerAuthController {
  final CustomerRepository _customerRepo;
  final SessionNotifier _sessionNotifier;
  final CustomerAccessService _accessService;

  CustomerAuthController(
    this._customerRepo,
    this._sessionNotifier,
    this._accessService,
  );

  Future<CustomerAuthFailure?> loginWithPin(String pin) async {
    try {
      final customer = await _customerRepo.getCustomerByPin(pin);

      if (customer == null) {
        return const InvalidPin();
      }

      if (!customer.isActive) {
        return const BlockedCustomer();
      }

      final session = AppSession.customer(
        customerId: customer.id ?? 0,
        customerShopName: customer.shopName,
        customerMobile: customer.mobile,
        customerOwnerName: customer.ownerName,
      );

      await _sessionNotifier.login(session);
      await _accessService.recordCatalogueAccess(customer.id ?? 0);
      return null;
    } catch (e) {
      return CustomerNetworkError(e.toString());
    }
  }

  Future<void> logout() async {
    await _sessionNotifier.logout();
  }

  Future<bool> validateActiveSession() async {
    final session = _sessionNotifier.state;
    if (!session.isCustomer || session.customerId == null) return true;
    try {
      final active = await _customerRepo.isCustomerActive(session.customerId!);
      if (!active) {
        await _sessionNotifier.logout();
        return false;
      }
      return true;
    } catch (_) {
      return true;
    }
  }
}

class CustomerAccessService {
  final CustomerRepository _customerRepo;
  bool _recordedThisSession = false;

  CustomerAccessService(this._customerRepo);

  Future<void> recordCatalogueAccess(int customerId) async {
    if (_recordedThisSession) return;
    _recordedThisSession = true;
    await _customerRepo.updateLastCatalogueAccess(customerId);
  }
}

final customerAccessServiceProvider = Provider<CustomerAccessService>((ref) {
  final repo = ref.read(customerRepositoryProvider);
  return CustomerAccessService(repo);
});

final customerAuthControllerProvider = Provider<CustomerAuthController>((ref) {
  final repo = ref.read(customerRepositoryProvider);
  final notifier = ref.read(appSessionProvider.notifier);
  final accessService = ref.read(customerAccessServiceProvider);
  return CustomerAuthController(repo, notifier, accessService);
});

final forcedLogoutReasonProvider = StateProvider<String?>((ref) => null);

final currentCustomerProvider = FutureProvider<Customer?>((ref) async {
  final session = ref.watch(appSessionProvider);
  if (!session.isCustomer || session.customerId == null) return null;
  final repo = ref.read(customerRepositoryProvider);
  return repo.getCustomerById(session.customerId!);
});
