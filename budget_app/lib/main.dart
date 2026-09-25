import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'providers/app_navigation.dart';
import 'providers/budget_provider.dart';
import 'providers/locale_controller.dart';
import 'screens/main_shell.dart';
import 'screens/setup_onboarding_screen.dart';
import 'services/external_launch_service.dart';
import 'services/home_widget_service.dart';
import 'services/storage_service.dart';
import 'theme/app_motion.dart';
import 'theme/app_theme.dart';
import 'widgets/ambient_background.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final storage = StorageService();
  await storage.init();
  await LocaleController.preload();
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
          create: (_) => LocaleController(widget.storage),
        ),
        ChangeNotifierProvider(
          create: (_) => BudgetProvider(widget.storage)..init(),
        ),
      ],
      child: Consumer<LocaleController>(
        builder: (context, locales, _) {
          return MaterialApp(
            navigatorKey: ExternalLaunchService.navigatorKey,
            title: 'Budget App',
            debugShowCheckedModeBanner: false,
            theme: buildAppTheme(),
            locale: locales.locale,
            supportedLocales: LocaleController.supportedLocales,
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: const _LaunchShell(),
          );
        },
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
    final provider = context.watch<BudgetProvider>();

    if (provider.isLoading) {
      return const Scaffold(
        backgroundColor: Colors.transparent,
        body: AmbientBackground(
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return AnimatedSwitcher(
      duration: AppMotion.page,
      switchInCurve: AppMotion.pageCurve,
      switchOutCurve: AppMotion.pageCurve,
      child: provider.hasCompletedOnboarding
          ? const MainShell(key: ValueKey('main'))
          : const SetupOnboardingScreen(key: ValueKey('onboarding')),
    );
  }
}
