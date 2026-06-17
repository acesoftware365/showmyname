// Path: lib/app/app_scope.dart
// Description: InheritedNotifier wrapper to access AppController anywhere via context.
// Use: AppScope.of(context).setLocale(Locale('es'));

import 'package:flutter/material.dart';
import 'app_controller.dart';

class AppScope extends InheritedNotifier<AppController> {
  const AppScope({
    super.key,
    required AppController controller,
    required Widget child,
  }) : super(notifier: controller, child: child);

  static AppController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope not found in widget tree.');
    return scope!.notifier!;
  }
}
