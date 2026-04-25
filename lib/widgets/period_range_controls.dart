import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../theme/colors.dart';
import 'glass_card.dart';

class PeriodRangeControls extends StatelessWidget {
  const PeriodRangeControls({
    super.key,
    required this.from,
    required this.to,
    required this.payday,
    required this.onPrevious,
    required this.onNext,
    required this.onCustomRange,
    required this.onReset,
    this.onMonth,
    this.customLabel = '사용자 지정',
    this.resetLabel = '현재 주기',
    this.monthLabel,
    this.paydaySuffix = '',
  });

  final DateTime from;
  final DateTime to;
  final DateTime payday;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final Future<void> Function() onCustomRange;
  final VoidCallback onReset;
  final VoidCallback? onMonth;
  final String customLabel;
  final String resetLabel;
  final String? monthLabel;
  final String paydaySuffix;

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('yyyy-MM-dd');
    final isCompact = MediaQuery.sizeOf(context).width < 380;
    return GlassCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: onPrevious,
                icon: const Icon(Icons.chevron_left, color: AppColors.deepInk),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      '${fmt.format(from)} ~ ${fmt.format(to)}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.deepInk,
                      ),
                    ),
                    Text(
                      '지급일 ${fmt.format(payday)}$paydaySuffix',
                      textAlign: TextAlign.center,
                      maxLines: isCompact ? 2 : 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.softBlack,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onNext,
                icon: const Icon(Icons.chevron_right, color: AppColors.deepInk),
              ),
            ],
          ),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              TextButton(
                onPressed: onCustomRange,
                child: Text(customLabel),
              ),
              if (onMonth != null)
                TextButton(
                  onPressed: onMonth,
                  child: Text(monthLabel ?? '이번 달'),
                ),
              TextButton(
                onPressed: onReset,
                child: Text(resetLabel),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
