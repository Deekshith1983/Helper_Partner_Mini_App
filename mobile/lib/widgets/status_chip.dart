import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../models/job_status.dart';

class StatusChip extends StatelessWidget {
  final JobStatus status;

  const StatusChip({
    super.key,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color textColor;

    switch (status) {
      case JobStatus.assigned:
        bg = AppColors.assignedBg;
        textColor = AppColors.assignedText;
        break;
      case JobStatus.inProgress:
        bg = AppColors.inProgressBg;
        textColor = AppColors.inProgressText;
        break;
      case JobStatus.completed:
        bg = AppColors.completedBg;
        textColor = AppColors.completedText;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadii.chip),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
