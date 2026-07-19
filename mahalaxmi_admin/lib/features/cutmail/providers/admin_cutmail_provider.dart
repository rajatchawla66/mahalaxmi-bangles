import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mahalaxmi_shared/models/cutmail.dart';
import 'package:mahalaxmi_shared/models/cutmail_size.dart';
import 'package:mahalaxmi_shared/providers/repository_providers.dart';

final adminCutmailsProvider = FutureProvider<List<Cutmail>>((ref) {
  return ref.read(cutmailRepositoryProvider).getCutmails();
});

final adminCutmailsByStatusProvider =
    FutureProvider.family<List<Cutmail>, String?>((ref, status) {
  return ref.read(cutmailRepositoryProvider).getCutmails(
        status: status,
      );
});

final adminCutmailDetailProvider =
    FutureProvider.family<Cutmail?, String>((ref, id) {
  return ref.read(cutmailRepositoryProvider).getCutmailById(id);
});

final adminCutmailSizesProvider =
    FutureProvider.family<List<CutmailSize>, String>((ref, cutmailId) {
  return ref.read(cutmailRepositoryProvider).getCutmailSizes(cutmailId);
});
