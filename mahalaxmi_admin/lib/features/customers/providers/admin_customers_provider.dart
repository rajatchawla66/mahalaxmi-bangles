import 'package:riverpod/riverpod.dart';
import 'package:mahalaxmi_shared/models/customer.dart';
import 'package:mahalaxmi_shared/providers/repository_providers.dart';

final adminCustomersProvider = FutureProvider<List<Customer>>((ref) async {
  final repo = ref.read(customerRepositoryProvider);
  return await repo.getCustomers();
});
