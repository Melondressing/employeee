import 'package:flutter/material.dart';

import '../theme/colors.dart';

class TaxNote extends StatelessWidget {
  const TaxNote(this.note, {super.key});
  final String note;

  @override
  Widget build(BuildContext context) {
    if (note.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.cardSurfaceAlt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.glassStroke),
      ),
      child: Text(
        note,
        style: const TextStyle(color: AppColors.softBlack, fontSize: 12),
      ),
    );
  }
}
