import 'package:intl/intl.dart';

import 'models.dart';

List<UsageSummaryBucket> summarizeEvents(
  List<UsageEvent> events,
  SummaryGroup group,
) {
  if (events.isEmpty) {
    return [];
  }

  final buckets = <String, _SummaryAccumulator>{};
  for (final event in events) {
    final label = _labelFor(event, group);
    buckets.putIfAbsent(label, _SummaryAccumulator.new).add(event);
  }

  final entries = buckets.entries.toList()
    ..sort((a, b) => a.key.compareTo(b.key));

  return entries
      .map(
        (entry) => UsageSummaryBucket(
          label: entry.key,
          totalMinutes: entry.value.totalMinutes,
          totalSessions: entry.value.totalSessions,
          uniqueScholars: entry.value.uniqueScholars.length,
          uniqueResources: entry.value.uniqueResources.length,
        ),
      )
      .toList();
}

String _labelFor(UsageEvent event, SummaryGroup group) {
  switch (group) {
    case SummaryGroup.week:
      final start = _weekStart(event.occurredAt);
      return DateFormat('yyyy-MM-dd').format(start);
    case SummaryGroup.month:
      return DateFormat('yyyy-MM').format(event.occurredAt);
    case SummaryGroup.resource:
      return event.resourceName;
    case SummaryGroup.scholar:
      return event.scholarName;
  }
}

DateTime _weekStart(DateTime date) {
  final normalized = DateTime.utc(date.year, date.month, date.day);
  final delta = normalized.weekday - DateTime.monday;
  return normalized.subtract(Duration(days: delta));
}

class _SummaryAccumulator {
  int totalMinutes = 0;
  int totalSessions = 0;
  final Set<String> uniqueScholars = {};
  final Set<String> uniqueResources = {};

  void add(UsageEvent event) {
    totalMinutes += event.minutes;
    totalSessions += 1;
    uniqueScholars.add(event.scholarName);
    uniqueResources.add(event.resourceName);
  }
}
