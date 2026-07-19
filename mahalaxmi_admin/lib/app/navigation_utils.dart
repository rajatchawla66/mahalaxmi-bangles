import 'package:go_router/go_router.dart';
import 'package:flutter/widgets.dart';

extension SafeBack on BuildContext {
  void safeBack({String fallback = '/dashboard'}) {
    if (canPop()) {
      pop();
    } else {
      go(fallback);
    }
  }
}
