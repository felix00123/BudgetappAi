import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/app_navigation.dart';
import 'providers/budget_provider.dart';
import 'screens/main_shell.dart';
import 'services/external_launch_service.dart';
import 'services/home_widget_service.dart';
import 'services/storage_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final storage = StorageService();
  await storage.init();
  await ExternalLaunchService.init();
  await HomeWidgetService.init();

  runApp(BudgetApp(storage: storage));
}

class BudgetApp extends StatefulWidget {
  const BudgetApp({super.key, required this.storage});

  final StorageService storage;

  @override
  State<BudgetApp> createState() => _BudgetAppState();
}

class _BudgetAppState extends State<BudgetApp> {
  @override
  void dispose() {
    ExternalLaunchService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppNavigation()),
        ChangeNotifierProvider(
          create: (_) => BudgetProvider(widget.storage)..init(),
        ),
      ],
      child: MaterialApp(
        navigatorKey: ExternalLaunchService.navigatorKey,
        title: 'Budget App',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        home: const _LaunchShell(),
      ),
    );
  }
}

class _LaunchShell extends StatefulWidget {
  const _LaunchShell();

  @override
  State<_LaunchShell> createState() => _LaunchShellState();
}

class _LaunchShellState extends State<_LaunchShell> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ExternalLaunchService.flushPendingLaunch();
    });
  }

  @override
  Widget build(BuildContext context) {
    return const MainShell();
  }
}
