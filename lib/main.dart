import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart'
    show FlutterQuillLocalizations;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'config/theme.dart';
import 'controllers/theme_mode_controller.dart';
import 'providers/database_provider.dart';
import 'services/system_notification_service.dart';
import 'widgets/app_shell.dart';

Future<void> main() async {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      await SystemNotificationService.initialize();
      final db = AppDatabase.openInAppSupport();

      runApp(
        ProviderScope(
          overrides: [appDatabaseProvider.overrideWithValue(db)],
          child: const MainApp(),
        ),
      );
    },
    (error, stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(exception: error, stack: stackTrace),
      );
    },
    zoneSpecification: ZoneSpecification(
      print: (self, parent, zone, line) {
        if (_shouldSuppressLogLine(line)) {
          return;
        }
        parent.print(zone, line);
      },
    ),
  );
}

bool _shouldSuppressLogLine(String line) {
  if (!line.startsWith('🔧 ')) {
    return false;
  }

  return line.startsWith('🔧 Python executable path:') ||
      line.startsWith('🔧 Python executable exists:') ||
      line.startsWith('🔧 Python executable size:') ||
      line.startsWith('🔧 Python executable mode:') ||
      line.startsWith('🔧 Setting up Python process streams...') ||
      line.startsWith('🔧 Stream listeners set up complete') ||
      line.startsWith('🔧 Raw stdout line:');
}

class MainApp extends ConsumerWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [FlutterQuillLocalizations.delegate],
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      home: const Scaffold(body: AppShell()),
    );
  }
}
