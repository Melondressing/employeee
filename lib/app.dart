import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/services.dart';

import 'screens/calculator_screen.dart';
import 'screens/home_screen.dart';
import 'screens/paycheck_checker_screen.dart';
import 'screens/reverse_calculator_screen.dart';
import 'screens/rules_screen.dart';
import 'screens/scenario_screen.dart';
import 'screens/work_entry_form_screen.dart';
import 'screens/work_log_screen.dart';
import 'theme/colors.dart';

class EmployeeeeApp extends StatelessWidget {
  const EmployeeeeApp({super.key});

  @override
  Widget build(BuildContext context) {
    const subtleShadow = [
      Shadow(color: Color(0x44000000), blurRadius: 2, offset: Offset(0, 1)),
    ];

    return MaterialApp(
      title: 'employeeee',
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      supportedLocales: const [
        Locale('en', 'GB'),
        Locale('ko', 'KR'),
      ],
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'SF Pro',
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.warmYellow,
          primary: AppColors.warmYellow,
          secondary: AppColors.vividOrange,
          surface: const Color(0xFF1A120C),
          brightness: Brightness.dark,
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
          fillColor: AppColors.cardSurfaceStrong,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.glassStroke),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.glassStroke),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide:
                const BorderSide(color: AppColors.vividOrange, width: 1.4),
          ),
          labelStyle: const TextStyle(color: AppColors.softBlack),
          hintStyle: const TextStyle(color: AppColors.softBlack),
          prefixStyle: const TextStyle(color: AppColors.deepInk),
          suffixStyle: const TextStyle(color: AppColors.deepInk),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0x9921130D),
          foregroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shadowColor: Colors.transparent,
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.white),
          actionsIconTheme: IconThemeData(color: Colors.white),
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
          toolbarTextStyle: TextStyle(color: Colors.white),
          systemOverlayStyle: SystemUiOverlayStyle.light,
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
          selectedColor: Color(0xCC4A2D1D),
          labelStyle: TextStyle(color: AppColors.deepInk),
          secondaryLabelStyle: TextStyle(color: AppColors.deepInk),
          side: BorderSide(color: AppColors.glassStroke),
        ),
        dropdownMenuTheme: const DropdownMenuThemeData(
          textStyle: TextStyle(color: AppColors.deepInk),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: AppColors.vividOrange,
          foregroundColor: Colors.white,
        ),
      ),
      home: const HomeScreen(),
      routes: {
        RulesScreen.route: (_) => const RulesScreen(),
        WorkEntryFormScreen.route: (_) => const WorkEntryFormScreen(),
        CalculatorScreen.route: (_) => const CalculatorScreen(),
        ReverseCalculatorScreen.route: (_) => const ReverseCalculatorScreen(),
        PaycheckCheckerScreen.route: (_) => const PaycheckCheckerScreen(),
        ScenarioScreen.route: (_) => const ScenarioScreen(),
        WorkLogScreen.route: (_) => const WorkLogScreen(),
      },
    );
  }
}
