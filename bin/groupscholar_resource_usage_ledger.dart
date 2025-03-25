import 'dart:io';

import 'package:args/args.dart';
import 'package:groupscholar_resource_usage_ledger/groupscholar_resource_usage_ledger.dart';

Future<void> main(List<String> arguments) async {
  final parser = ArgParser()
    ..addCommand(
      'log',
      ArgParser()
        ..addOption('scholar', abbr: 's', help: 'Scholar name.')
        ..addOption('resource', abbr: 'r', help: 'Resource name.')
        ..addOption('type', abbr: 't', help: 'Resource type.')
        ..addOption('minutes', abbr: 'm', help: 'Minutes spent.')
        ..addOption('occurred-at', abbr: 'o', help: 'ISO date/time.')
        ..addOption('staff', help: 'Staff member name.')
        ..addOption('notes', help: 'Optional notes.'),
    )
    ..addCommand(
      'list',
      ArgParser()
        ..addOption('scholar', abbr: 's', help: 'Filter by scholar name.')
        ..addOption('resource', abbr: 'r', help: 'Filter by resource name.')
        ..addOption('since', help: 'ISO date/time lower bound.')
        ..addOption('until', help: 'ISO date/time upper bound.')
        ..addOption('limit', defaultsTo: '50', help: 'Max rows.'),
    )
    ..addCommand(
      'summary',
      ArgParser()
        ..addOption(
          'group-by',
          defaultsTo: 'week',
          allowed: ['week', 'month', 'resource', 'scholar'],
          help: 'Bucket summary.',
        )
        ..addOption('since', help: 'ISO date/time lower bound.')
        ..addOption('until', help: 'ISO date/time upper bound.'),
    )
    ..addCommand(
      'init-db',
      ArgParser()
        ..addOption(
          'schema',
          defaultsTo: 'sql/schema.sql',
          help: 'Schema SQL path.',
        )
        ..addOption('seed', defaultsTo: 'sql/seed.sql', help: 'Seed SQL path.'),
    )
    ..addFlag('help', abbr: 'h', negatable: false, help: 'Show usage.');

  late ArgResults results;
  try {
    results = parser.parse(arguments);
  } on ArgParserException catch (error) {
    stderr.writeln(error.message);
    _printUsage(parser);
    exitCode = 64;
    return;
  }

  if (results['help'] as bool || results.command == null) {
    _printUsage(parser);
    return;
  }

  final command = results.command!;
  final config = DatabaseConfig.fromEnv();
  final repository = ResourceUsageRepository(config);

  switch (command.name) {
    case 'log':
      await _handleLog(repository, command);
      return;
    case 'list':
      await _handleList(repository, command);
      return;
    case 'summary':
      await _handleSummary(repository, command);
      return;
    case 'init-db':
      await _handleInit(repository, command);
      return;
    default:
      stderr.writeln('Unknown command: ${command.name}');
      _printUsage(parser);
      exitCode = 64;
  }
}

Future<void> _handleLog(
  ResourceUsageRepository repository,
  ArgResults command,
) async {
  final scholar = command['scholar'] as String?;
  final resource = command['resource'] as String?;
  final type = command['type'] as String?;
  final minutesRaw = command['minutes'] as String?;
  if (scholar == null ||
      resource == null ||
      type == null ||
      minutesRaw == null) {
    stderr.writeln('Missing required options for log.');
    exitCode = 64;
    return;
  }

  final minutes = int.tryParse(minutesRaw);
  if (minutes == null || minutes < 0) {
    stderr.writeln('Minutes must be a positive integer.');
    exitCode = 64;
    return;
  }

  DateTime occurredAt;
  final occurredRaw = command['occurred-at'] as String?;
  if (occurredRaw == null || occurredRaw.trim().isEmpty) {
    occurredAt = DateTime.now().toUtc();
  } else {
    try {
      occurredAt = parseDateTime(occurredRaw);
    } on FormatException catch (error) {
      stderr.writeln(error.message);
      exitCode = 64;
      return;
    }
  }

  final event = UsageEvent(
    scholarName: scholar,
    resourceName: resource,
    resourceType: type,
    minutes: minutes,
    occurredAt: occurredAt,
    staffName: command['staff'] as String?,
    notes: command['notes'] as String?,
  );

  final id = await repository.insert(event);
  stdout.writeln('Logged usage event #$id');
}

Future<void> _handleList(
  ResourceUsageRepository repository,
  ArgResults command,
) async {
  DateTime? since;
  DateTime? until;
  try {
    since = _parseOptionalDate(command['since'] as String?);
    until = _parseOptionalDate(command['until'] as String?);
  } on FormatException catch (error) {
    stderr.writeln(error.message);
    exitCode = 64;
    return;
  }
  final limitRaw = command['limit'] as String? ?? '50';
  final limit = int.tryParse(limitRaw) ?? 50;

  final events = await repository.list(
    scholar: command['scholar'] as String?,
    resource: command['resource'] as String?,
    since: since,
    until: until,
    limit: limit,
  );

  if (events.isEmpty) {
    stdout.writeln('No usage events found.');
    return;
  }

  for (final event in events) {
    stdout.writeln(formatEvent(event));
  }
}

Future<void> _handleSummary(
  ResourceUsageRepository repository,
  ArgResults command,
) async {
  DateTime? since;
  DateTime? until;
  try {
    since = _parseOptionalDate(command['since'] as String?);
    until = _parseOptionalDate(command['until'] as String?);
  } on FormatException catch (error) {
    stderr.writeln(error.message);
    exitCode = 64;
    return;
  }
  final groupValue = command['group-by'] as String? ?? 'week';
  final group = SummaryGroup.values.firstWhere(
    (value) => value.name == groupValue,
    orElse: () => SummaryGroup.week,
  );

  final events = await repository.allForWindow(since: since, until: until);
  final summary = summarizeEvents(events, group);

  if (summary.isEmpty) {
    stdout.writeln('No usage events available for summary.');
    return;
  }

  for (final bucket in summary) {
    stdout.writeln(formatSummary(bucket));
  }
}

Future<void> _handleInit(
  ResourceUsageRepository repository,
  ArgResults command,
) async {
  final schemaPath = command['schema'] as String;
  final seedPath = command['seed'] as String;
  await repository.initSchema(schemaPath: schemaPath, seedPath: seedPath);
  stdout.writeln('Schema initialized and seed data loaded.');
}

DateTime? _parseOptionalDate(String? value) {
  if (value == null || value.trim().isEmpty) {
    return null;
  }
  return parseDateTime(value);
}

void _printUsage(ArgParser parser) {
  stdout.writeln('Groupscholar Resource Usage Ledger');
  stdout.writeln(
    'Usage: dart run bin/groupscholar_resource_usage_ledger.dart <command>',
  );
  stdout.writeln(parser.usage);
}
