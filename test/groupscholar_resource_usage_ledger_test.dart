import 'package:groupscholar_resource_usage_ledger/groupscholar_resource_usage_ledger.dart';
import 'package:test/test.dart';

void main() {
  test('summarizeEvents groups by week start date', () {
    final events = [
      UsageEvent(
        scholarName: 'Ava',
        resourceName: 'Essay Lab',
        resourceType: 'workshop',
        minutes: 45,
        occurredAt: DateTime.utc(2026, 2, 2, 12),
      ),
      UsageEvent(
        scholarName: 'Ava',
        resourceName: 'Essay Lab',
        resourceType: 'workshop',
        minutes: 30,
        occurredAt: DateTime.utc(2026, 2, 3, 9),
      ),
      UsageEvent(
        scholarName: 'Ben',
        resourceName: 'Scholar Guide',
        resourceType: 'guide',
        minutes: 20,
        occurredAt: DateTime.utc(2026, 2, 5, 10),
      ),
    ];

    final summary = summarizeEvents(events, SummaryGroup.week);
    expect(summary, hasLength(1));
    expect(summary.first.label, '2026-02-02');
    expect(summary.first.totalMinutes, 95);
    expect(summary.first.totalSessions, 3);
    expect(summary.first.uniqueScholars, 2);
    expect(summary.first.uniqueResources, 2);
  });

  test('summarizeEvents groups by resource', () {
    final events = [
      UsageEvent(
        scholarName: 'Ava',
        resourceName: 'Essay Lab',
        resourceType: 'workshop',
        minutes: 45,
        occurredAt: DateTime.utc(2026, 2, 2, 12),
      ),
      UsageEvent(
        scholarName: 'Cara',
        resourceName: 'Essay Lab',
        resourceType: 'workshop',
        minutes: 25,
        occurredAt: DateTime.utc(2026, 2, 7, 9),
      ),
      UsageEvent(
        scholarName: 'Ben',
        resourceName: 'Scholar Guide',
        resourceType: 'guide',
        minutes: 20,
        occurredAt: DateTime.utc(2026, 2, 5, 10),
      ),
    ];

    final summary = summarizeEvents(events, SummaryGroup.resource);
    expect(summary, hasLength(2));
    final essay = summary.firstWhere((bucket) => bucket.label == 'Essay Lab');
    expect(essay.totalSessions, 2);
    expect(essay.totalMinutes, 70);
    final guide = summary.firstWhere(
      (bucket) => bucket.label == 'Scholar Guide',
    );
    expect(guide.totalMinutes, 20);
  });
}
