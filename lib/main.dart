import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'services/auth_service.dart';
import 'services/providers.dart';
import 'services/storage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Storage.init();
  final bootstrap = await Storage.loadBootstrap();
  final authSession = await AuthStorage.loadSession();

  runApp(
    ProviderScope(
      overrides: [
        bootstrapPayRuleProvider.overrideWithValue(bootstrap.rule),
        bootstrapWorkEntriesProvider.overrideWithValue(bootstrap.entries),
        bootstrapAuthSessionProvider.overrideWithValue(authSession),
      ],
      child: const EmployeeeeApp(),
    ),
  );
}
