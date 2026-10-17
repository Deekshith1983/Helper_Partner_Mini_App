/// Job lifecycle statuses matching the backend contract and DESIGN.md
enum JobStatus {
  assigned('ASSIGNED', 'Assigned'),
  inProgress('IN_PROGRESS', 'In progress'),
  completed('COMPLETED', 'Completed');

  final String value;
  final String label;

  const JobStatus(this.value, this.label);

  static JobStatus fromString(String raw) {
    switch (raw.toUpperCase()) {
      case 'IN_PROGRESS':
        return JobStatus.inProgress;
      case 'COMPLETED':
        return JobStatus.completed;
      case 'ASSIGNED':
      default:
        return JobStatus.assigned;
    }
  }

  /// Returns the next permitted status in the lifecycle, or null if terminal.
  JobStatus? get nextStatus {
    switch (this) {
      case JobStatus.assigned:
        return JobStatus.inProgress;
      case JobStatus.inProgress:
        return JobStatus.completed;
      case JobStatus.completed:
        return null;
    }
  }

  /// Returns the button label for the single primary action on Details screen.
  String? get nextActionLabel {
    switch (this) {
      case JobStatus.assigned:
        return 'Start job';
      case JobStatus.inProgress:
        return 'Mark as completed';
      case JobStatus.completed:
        return null;
    }
  }

  /// Step index for 3-step status stepper (0 = Assigned, 1 = In Progress, 2 = Completed)
  int get stepIndex {
    switch (this) {
      case JobStatus.assigned:
        return 0;
      case JobStatus.inProgress:
        return 1;
      case JobStatus.completed:
        return 2;
    }
  }
}
