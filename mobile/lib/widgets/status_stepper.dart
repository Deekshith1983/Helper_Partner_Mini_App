import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../models/job_status.dart';

class StatusStepper extends StatelessWidget {
  final JobStatus currentStatus;

  const StatusStepper({
    super.key,
    required this.currentStatus,
  });

  static const List<JobStatus> steps = [
    JobStatus.assigned,
    JobStatus.inProgress,
    JobStatus.completed,
  ];

  @override
  Widget build(BuildContext context) {
    final currentIndex = currentStatus.stepIndex;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: AppColors.outline),
      ),
      child: Row(
        children: [
          for (int i = 0; i < steps.length; i++) ...[
            _buildStep(context, steps[i], i, currentIndex),
            if (i < steps.length - 1)
              Expanded(
                child: Container(
                  height: 2,
                  color: i < currentIndex ? AppColors.success : AppColors.outline,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildStep(
    BuildContext context,
    JobStatus step,
    int index,
    int currentIndex,
  ) {
    final bool isCompleted = index < currentIndex || (index == 2 && currentIndex == 2);
    final bool isCurrent = index == currentIndex && !isCompleted;

    Color iconBg;
    Widget iconChild;

    if (isCompleted) {
      iconBg = AppColors.success;
      iconChild = const Icon(Icons.check, size: 14, color: Colors.white);
    } else if (isCurrent) {
      iconBg = AppColors.primary;
      iconChild = Text(
        '${index + 1}',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      );
    } else {
      iconBg = Colors.transparent;
      iconChild = Text(
        '${index + 1}',
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: iconBg,
            shape: BoxShape.circle,
            border: isCompleted || isCurrent
                ? null
                : Border.all(color: AppColors.outline, width: 2),
          ),
          alignment: Alignment.center,
          child: iconChild,
        ),
        const SizedBox(height: 6),
        Text(
          step.label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isCurrent || isCompleted ? FontWeight.w600 : FontWeight.w400,
            color: isCurrent
                ? AppColors.primary
                : isCompleted
                    ? AppColors.success
                    : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
