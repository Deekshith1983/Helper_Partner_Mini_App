import 'job_status.dart';

class Job {
  final int id;
  final String title;
  final String description;
  final String customerName;
  final String location;
  final DateTime scheduledAt;
  final JobStatus status;
  final int helper;
  final DateTime createdAt;

  const Job({
    required this.id,
    required this.title,
    required this.description,
    required this.customerName,
    required this.location,
    required this.scheduledAt,
    required this.status,
    required this.helper,
    required this.createdAt,
  });

  factory Job.fromJson(Map<String, dynamic> json) {
    return Job(
      id: json['id'] as int,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      customerName: json['customer_name'] as String? ?? '',
      location: json['location'] as String? ?? '',
      scheduledAt: DateTime.tryParse(json['scheduled_at'] as String? ?? '')?.toLocal() ?? DateTime.now(),
      status: JobStatus.fromString(json['status'] as String? ?? 'ASSIGNED'),
      helper: json['helper'] as int? ?? 0,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '')?.toLocal() ?? DateTime.now(),
    );
  }

  Job copyWith({
    int? id,
    String? title,
    String? description,
    String? customerName,
    String? location,
    DateTime? scheduledAt,
    JobStatus? status,
    int? helper,
    DateTime? createdAt,
  }) {
    return Job(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      customerName: customerName ?? this.customerName,
      location: location ?? this.location,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      status: status ?? this.status,
      helper: helper ?? this.helper,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
