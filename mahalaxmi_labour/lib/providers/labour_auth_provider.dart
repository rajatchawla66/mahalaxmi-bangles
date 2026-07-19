import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mahalaxmi_shared/providers/session_provider.dart';
import 'package:mahalaxmi_shared/models/app_session.dart';

const _kLabourPin = '1234';

class LabourAuthController {
  final SessionNotifier _sessionNotifier;

  LabourAuthController(this._sessionNotifier);

  bool validatePin(String pin) {
    return pin.length == 4 && pin == _kLabourPin;
  }

  Future<void> login() async {
    await _sessionNotifier.login(AppSession.labour('labour'));
  }

  Future<void> logout() async {
    await _sessionNotifier.logout();
  }
}

final labourAuthControllerProvider = Provider<LabourAuthController>((ref) {
  final notifier = ref.read(appSessionProvider.notifier);
  return LabourAuthController(notifier);
});
