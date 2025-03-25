class UsageEvent {
  UsageEvent({
    required this.scholarName,
    required this.resourceName,
    required this.resourceType,
    required this.minutes,
    required this.occurredAt,
    this.staffName,
    this.notes,
    this.id,
  });

  final int? id;
  final String scholarName;
  final String resourceName;
  final String resourceType;
  final int minutes;
  final DateTime occurredAt;
  final String? staffName;
  final String? notes;
}

class UsageSummaryBucket {
  UsageSummaryBucket({
    required this.label,
    required this.totalMinutes,
    required this.totalSessions,
    required this.uniqueScholars,
    required this.uniqueResources,
  });

  final String label;
  final int totalMinutes;
  final int totalSessions;
  final int uniqueScholars;
  final int uniqueResources;
}

enum SummaryGroup { week, month, resource, scholar }
