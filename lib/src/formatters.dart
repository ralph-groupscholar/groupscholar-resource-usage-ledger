import 'package:intl/intl.dart';

import 'models.dart';

String formatEvent(UsageEvent event) {
  final date = DateFormat('yyyy-MM-dd').format(event.occurredAt.toLocal());
  final staff = event.staffName == null || event.staffName!.isEmpty
      ? 'unassigned'
      : event.staffName!;
  final notes = event.notes == null || event.notes!.isEmpty
      ? ''
      : ' | ${event.notes}';
  return [
    date,
    event.scholarName,
    event.resourceName,
    event.resourceType,
    '${event.minutes}m',
    staff,
    notes,
  ].join(' | ');
}

String formatSummary(UsageSummaryBucket bucket) {
  return [
    bucket.label,
    '${bucket.totalSessions} sessions',
    '${bucket.totalMinutes} minutes',
    '${bucket.uniqueScholars} scholars',
    '${bucket.uniqueResources} resources',
  ].join(' | ');
}
