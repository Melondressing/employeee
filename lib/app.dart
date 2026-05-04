import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'models/auth_session.dart';
import 'screens/calculator_screen.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/pay_history_screen.dart';
import 'screens/paycheck_checker_screen.dart';
import 'screens/reverse_calculator_screen.dart';
import 'screens/rules_screen.dart';
import 'screens/scenario_screen.dart';
import 'screens/work_entry_form_screen.dart';
import 'screens/work_log_screen.dart';
import 'services/auth_service.dart';
import 'services/cloud_sync_coordinator.dart';
import 'services/language_service.dart';
import 'theme/colors.dart';

class AuthGate extends ConsumerStatefulWidget {
  const AuthGate({super.key});

  @override
  ConsumerState<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends ConsumerState<AuthGate> {
  String? _lastCloudSyncKey;
  Timer? _cloudRefreshTimer;

  @override
  void dispose() {
    _cloudRefreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(authSessionProvider);
    _scheduleCloudSync(session);
    return session == null ? const LoginScreen() : const HomeScreen();
  }

  void _scheduleCloudSync(AuthSession? session) {
    if (session == null || !session.hasCloudToken) {
      _lastCloudSyncKey = null;
      _cloudRefreshTimer?.cancel();
      _cloudRefreshTimer = null;
      return;
    }

    final key = '${session.provider}:${session.userId}:${session.accessToken}';
    if (_lastCloudSyncKey == key) return;
    _lastCloudSyncKey = key;
    _cloudRefreshTimer?.cancel();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _runCloudSync(session);
    });

    _cloudRefreshTimer = Timer.periodic(
      const Duration(seconds: 45),
      (_) => _runCloudSync(session),
    );
  }

  void _runCloudSync(AuthSession session) {
    if (!mounted || !session.hasCloudToken) return;
    unawaited(
      EmployeeeeCloudSyncCoordinator.sync(ref, session).catchError((_) {}),
    );
  }
}

class EmployeeeeApp extends ConsumerWidget {
  const EmployeeeeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final language = ref.watch(appLanguageProvider);
    const subtleShadow = [
      Shadow(color: Color(0x22FFFFFF), blurRadius: 2, offset: Offset(0, 1)),
    ];

    return MaterialApp(
      title: 'employeeee',
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      locale: language.locale,
      supportedLocales: const [
        Locale('en', 'GB'),
        Locale('ko', 'KR'),
      ],
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'SF Pro',
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.lavender,
          primary: AppColors.lavender,
          secondary: AppColors.serenityBlue,
          surface: AppColors.offWhite,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: Colors.transparent,
        cardTheme: CardThemeData(
          color: AppColors.cardSurface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: AppColors.glassStroke),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.inputSurface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.inputStroke),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.inputStroke),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.lavender, width: 1.4),
          ),
          labelStyle: const TextStyle(color: AppColors.softBlack),
          hintStyle: const TextStyle(color: AppColors.softBlack),
          prefixStyle: const TextStyle(color: AppColors.deepInk),
          suffixStyle: const TextStyle(color: AppColors.deepInk),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xA6FFFFFF),
          foregroundColor: AppColors.deepInk,
          surfaceTintColor: Colors.transparent,
          shadowColor: Colors.transparent,
          elevation: 0,
          iconTheme: IconThemeData(color: AppColors.deepInk),
          actionsIconTheme: IconThemeData(color: AppColors.deepInk),
          titleTextStyle: TextStyle(
            color: AppColors.deepInk,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
          toolbarTextStyle: TextStyle(color: AppColors.deepInk),
          systemOverlayStyle: SystemUiOverlayStyle.dark,
        ),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(
            color: AppColors.deepInk,
            fontWeight: FontWeight.w500,
            shadows: subtleShadow,
          ),
          bodyLarge: TextStyle(
            color: AppColors.deepInk,
            fontWeight: FontWeight.w600,
            shadows: subtleShadow,
          ),
          titleMedium: TextStyle(
            color: AppColors.deepInk,
            fontWeight: FontWeight.bold,
            shadows: subtleShadow,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.deepInk),
        dividerColor: AppColors.glassStroke,
        listTileTheme: const ListTileThemeData(
          textColor: AppColors.deepInk,
          iconColor: AppColors.deepInk,
        ),
        chipTheme: const ChipThemeData(
          backgroundColor: AppColors.cardSurfaceAlt,
          selectedColor: Color(0x66B4A7D6),
          labelStyle: TextStyle(color: AppColors.deepInk),
          secondaryLabelStyle: TextStyle(color: AppColors.deepInk),
          side: BorderSide(color: AppColors.glassStroke),
        ),
        dropdownMenuTheme: const DropdownMenuThemeData(
          textStyle: TextStyle(color: AppColors.deepInk),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: AppColors.lavender,
          foregroundColor: Colors.white,
        ),
      ),
      home: const AuthGate(),
      routes: {
        LoginScreen.route: (_) => const LoginScreen(),
        RulesScreen.route: (_) => const RulesScreen(),
        WorkEntryFormScreen.route: (_) => const WorkEntryFormScreen(),
        CalculatorScreen.route: (_) => const CalculatorScreen(),
        PayHistoryScreen.route: (_) => const PayHistoryScreen(),
        ReverseCalculatorScreen.route: (_) => const ReverseCalculatorScreen(),
        PaycheckCheckerScreen.route: (_) => const PaycheckCheckerScreen(),
        ScenarioScreen.route: (_) => const ScenarioScreen(),
        WorkLogScreen.route: (_) => const WorkLogScreen(),
      },
    );
  }
}
