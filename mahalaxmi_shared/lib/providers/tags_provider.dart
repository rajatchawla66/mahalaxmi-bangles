import 'package:riverpod/riverpod.dart';

import '../models/tag.dart';
import 'repository_providers.dart';

final tagMasterProvider = FutureProvider<List<TagMaster>>((ref) {
  return ref.read(tagRepositoryProvider).getTagMaster();
});

final activeTagMasterProvider = FutureProvider<List<TagMaster>>((ref) {
  return ref.read(tagRepositoryProvider).getTagMaster(activeOnly: true);
});
