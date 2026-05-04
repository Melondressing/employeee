import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/language_service.dart';
import '../theme/colors.dart';

class LanguageToggle extends ConsumerWidget {
  const LanguageToggle({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final language = ref.watch(appLanguageProvider);
    final next = language == AppLanguage.ko ? AppLanguage.en : AppLanguage.ko;

    if (compact) {
      return IconButton(
        tooltip: language.text('Switch to English', '한국어로 전환'),
        onPressed: () => ref.read(appLanguageProvider.notifier).toggle(),
        icon: Container(
          width: 34,
          height: 26,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.cardSurfaceStrong,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: AppColors.inputStroke),
          ),
          child: Text(
            next.shortLabel,
            style: const TextStyle(
              color: AppColors.deepInk,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      );
    }

    return SegmentedButton<AppLanguage>(
      segments: const [
        ButtonSegment(value: AppLanguage.ko, label: Text('한국어')),
        ButtonSegment(value: AppLanguage.en, label: Text('English')),
      ],
      selected: {language},
      onSelectionChanged: (selection) {
        ref.read(appLanguageProvider.notifier).setLanguage(selection.first);
      },
      style: SegmentedButton.styleFrom(
        foregroundColor: AppColors.deepInk,
        selectedForegroundColor: Colors.white,
        selectedBackgroundColor: AppColors.lavender,
      ),
    );
  }
}
