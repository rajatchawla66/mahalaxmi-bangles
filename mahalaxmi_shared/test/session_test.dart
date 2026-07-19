import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';
import 'package:mahalaxmi_shared/models/app_session.dart';
import 'package:mahalaxmi_shared/models/customer.dart';
import 'package:mahalaxmi_shared/repositories/customer_repository.dart';
import 'package:mahalaxmi_shared/services/session_storage.dart';
import 'package:mahalaxmi_shared/providers/session_provider.dart';
import 'package:mahalaxmi_shared/providers/auth_provider.dart';
import 'package:mahalaxmi_shared/providers/customer_auth_provider.dart';

class _MockSessionStorage implements SessionStorage {
  AppSession? _session;

  @override
  Future<AppSession?> load() async => _session;

  @override
  Future<void> save(AppSession session) async {
    _session = session;
  }

  @override
  Future<void> clear() async {
    _session = null;
  }
}

class _MockCustomerRepository extends CustomerRepository {
  final Map<String, Customer?> _customers;

  _MockCustomerRepository(this._customers);

  @override
  Future<Customer?> getCustomerByPin(String pin) async {
    return _customers[pin];
  }

  @override
  Future<Customer?> getCustomerById(int customerId) async {
    return _customers.values.firstWhere(
      (c) => c?.id == customerId,
      orElse: () => null,
    );
  }

  @override
  Future<List<Customer>> getCustomers() async {
    return _customers.values.whereType<Customer>().toList();
  }
}

class _MockCustomerAccessService extends CustomerAccessService {
  _MockCustomerAccessService() : super(_MockCustomerRepository({}));

  @override
  Future<void> recordCatalogueAccess(int customerId) async {}
}

void main() {
  group('AppSession', () {
    test('loggedOut has role none and isLoggedIn is false', () {
      expect(AppSession.loggedOut.role, AuthRole.none);
      expect(AppSession.loggedOut.isLoggedIn, false);
      expect(AppSession.loggedOut.isCustomer, false);
      expect(AppSession.loggedOut.isAdmin, false);
      expect(AppSession.loggedOut.isLabour, false);
    });

    test('customer session has correct role and fields', () {
      final session = AppSession.customer(
        customerId: 1,
        customerShopName: 'Test Shop',
        customerMobile: '9876543210',
        customerOwnerName: 'Owner',
      );

      expect(session.role, AuthRole.customer);
      expect(session.isLoggedIn, true);
      expect(session.isCustomer, true);
      expect(session.customerId, 1);
      expect(session.customerShopName, 'Test Shop');
      expect(session.customerMobile, '9876543210');
      expect(session.customerOwnerName, 'Owner');
    });

    test('admin session has correct role', () {
      final session = AppSession.admin('admin1');
      expect(session.role, AuthRole.admin);
      expect(session.isLoggedIn, true);
      expect(session.isAdmin, true);
      expect(session.username, 'admin1');
    });

    test('labour session has correct role', () {
      final session = AppSession.labour('worker1');
      expect(session.role, AuthRole.labour);
      expect(session.isLoggedIn, true);
      expect(session.isLabour, true);
      expect(session.username, 'worker1');
    });

    group('JSON serialization', () {
      test('loggedOut session round-trips', () {
        final json = AppSession.loggedOut.toJson();
        final restored = AppSession.fromJson(json);
        expect(restored.role, AuthRole.none);
        expect(restored.isLoggedIn, false);
      });

      test('customer session round-trips', () {
        final original = AppSession.customer(
          customerId: 42,
          customerShopName: 'Mega Shop',
          customerMobile: '9999888877',
          customerOwnerName: 'Raj',
        );
        final json = original.toJson();
        final restored = AppSession.fromJson(json);

        expect(restored.role, AuthRole.customer);
        expect(restored.customerId, 42);
        expect(restored.customerShopName, 'Mega Shop');
        expect(restored.customerMobile, '9999888877');
        expect(restored.customerOwnerName, 'Raj');
      });

      test('admin session round-trips', () {
        final original = AppSession.admin('boss');
        final json = original.toJson();
        final restored = AppSession.fromJson(json);
        expect(restored.role, AuthRole.admin);
        expect(restored.username, 'boss');
      });

      test('fromJson returns loggedOut for null role', () {
        final restored = AppSession.fromJson({'role': null});
        expect(restored.role, AuthRole.none);
      });

      test('fromJson returns loggedOut for empty map', () {
        final restored = AppSession.fromJson({});
        expect(restored.role, AuthRole.none);
      });

      test('fromJson returns loggedOut for unknown role', () {
        final restored = AppSession.fromJson({'role': 'superadmin'});
        expect(restored.role, AuthRole.none);
      });
    });
  });

  group('SessionStorage', () {
    test('InMemorySessionStorage starts empty', () async {
      final storage = InMemorySessionStorage();
      expect(await storage.load(), isNull);
    });

    test('InMemorySessionStorage save and load', () async {
      final storage = InMemorySessionStorage();
      await storage.save(AppSession.admin('test'));
      final loaded = await storage.load();
      expect(loaded, isNotNull);
      expect(loaded!.role, AuthRole.admin);
      expect(loaded.username, 'test');
    });

    test('InMemorySessionStorage clear', () async {
      final storage = InMemorySessionStorage();
      await storage.save(AppSession.customer(
        customerId: 1,
        customerShopName: 'S',
      ));
      await storage.clear();
      expect(await storage.load(), isNull);
    });
  });

  group('SessionNotifier', () {
    late _MockSessionStorage storage;
    late SessionNotifier notifier;

    setUp(() {
      storage = _MockSessionStorage();
      notifier = SessionNotifier(storage);
    });

    test('starts logged out', () {
      expect(notifier.state.role, AuthRole.none);
    });

    test('login updates state and persists', () async {
      final session = AppSession.admin('boss');
      await notifier.login(session);
      expect(notifier.state.role, AuthRole.admin);
      expect(notifier.state.username, 'boss');

      final stored = await storage.load();
      expect(stored!.role, AuthRole.admin);
    });

    test('logout clears state and storage', () async {
      await notifier.login(AppSession.admin('boss'));
      await notifier.logout();
      expect(notifier.state.role, AuthRole.none);
      expect(await storage.load(), isNull);
    });

    test('restore loads saved session', () async {
      await storage.save(AppSession.labour('worker'));
      expect(notifier.state.role, AuthRole.none);

      await notifier.restore();
      expect(notifier.state.role, AuthRole.labour);
      expect(notifier.state.username, 'worker');
    });

    test('restore with no saved session leaves loggedOut', () async {
      await notifier.restore();
      expect(notifier.state.role, AuthRole.none);
    });
  });

  group('AuthController (admin/labour)', () {
    late _MockSessionStorage storage;
    late SessionNotifier sessionNotifier;
    late AuthController authController;

    setUp(() {
      storage = _MockSessionStorage();
      sessionNotifier = SessionNotifier(storage);
      authController = AuthController(sessionNotifier);
    });

    test('admin login with correct password succeeds', () async {
      final error = await authController.loginAdmin('admin', 'admin123');
      expect(error, isNull);
      expect(sessionNotifier.state.role, AuthRole.admin);
      expect(sessionNotifier.state.username, 'admin');
    });

    test('admin login with wrong password fails', () async {
      final error = await authController.loginAdmin('admin', 'wrong');
      expect(error, isA<InvalidCredentials>());
      expect(sessionNotifier.state.role, AuthRole.none);
    });

    test('labour login with correct password succeeds', () async {
      final error = await authController.loginLabour('worker', 'labour123');
      expect(error, isNull);
      expect(sessionNotifier.state.role, AuthRole.labour);
      expect(sessionNotifier.state.username, 'worker');
    });

    test('labour login with wrong password fails', () async {
      final error = await authController.loginLabour('worker', 'wrong');
      expect(error, isA<InvalidCredentials>());
      expect(sessionNotifier.state.role, AuthRole.none);
    });

    test('logout clears session', () async {
      await authController.loginAdmin('admin', 'admin123');
      await authController.logout();
      expect(sessionNotifier.state.role, AuthRole.none);
      expect(await storage.load(), isNull);
    });
  });

  group('CustomerAuthController', () {
    late _MockSessionStorage storage;
    late SessionNotifier sessionNotifier;
    late CustomerAuthController customerAuth;
    late _MockCustomerRepository mockRepo;

    final activeCustomer = Customer(
      id: 10,
      pin: '12345678',
      shopName: 'Active Shop',
      mobile: '1111111111',
      ownerName: 'Active Owner',
      isActive: true,
    );

    final blockedCustomer = Customer(
      id: 20,
      pin: '87654321',
      shopName: 'Blocked Shop',
      mobile: '2222222222',
      ownerName: 'Blocked Owner',
      isActive: false,
    );

    setUp(() {
      storage = _MockSessionStorage();
      sessionNotifier = SessionNotifier(storage);
      mockRepo = _MockCustomerRepository({
        '12345678': activeCustomer,
        '87654321': blockedCustomer,
      });
      customerAuth = CustomerAuthController(
        mockRepo,
        sessionNotifier,
        _MockCustomerAccessService(),
      );
    });

    test('login with valid PIN succeeds and creates session', () async {
      final error = await customerAuth.loginWithPin('12345678');
      expect(error, isNull);
      expect(sessionNotifier.state.role, AuthRole.customer);
      expect(sessionNotifier.state.customerId, 10);
      expect(sessionNotifier.state.customerShopName, 'Active Shop');
      expect(sessionNotifier.state.customerMobile, '1111111111');
      expect(sessionNotifier.state.customerOwnerName, 'Active Owner');
    });

    test('login with invalid PIN returns InvalidPin', () async {
      final error = await customerAuth.loginWithPin('00000000');
      expect(error, isA<InvalidPin>());
      expect(sessionNotifier.state.role, AuthRole.none);
    });

    test('login with blocked customer returns BlockedCustomer', () async {
      final error = await customerAuth.loginWithPin('87654321');
      expect(error, isA<BlockedCustomer>());
      expect(sessionNotifier.state.role, AuthRole.none);
    });

    test('logout clears customer session', () async {
      await customerAuth.loginWithPin('12345678');
      expect(sessionNotifier.state.isLoggedIn, true);

      await customerAuth.logout();
      expect(sessionNotifier.state.role, AuthRole.none);
      expect(await storage.load(), isNull);
    });

    test('second login replaces previous session', () async {
      await customerAuth.loginWithPin('12345678');
      expect(sessionNotifier.state.customerId, 10);

      final error = await customerAuth.loginWithPin('87654321');
      expect(error, isA<BlockedCustomer>());
    });
  });
}
