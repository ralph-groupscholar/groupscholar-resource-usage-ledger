import 'dart:io';

import 'package:postgres/postgres.dart';

import 'config.dart';
import 'models.dart';

class ResourceUsageRepository {
  ResourceUsageRepository(this.config);

  final DatabaseConfig config;

  Future<Connection> _open() {
    return Connection.open(
      Endpoint(
        host: config.host,
        database: config.database,
        username: config.username,
        password: config.password,
        port: config.port,
      ),
      settings: ConnectionSettings(sslMode: config.sslMode),
    );
  }

  Future<void> initSchema({
    required String schemaPath,
    required String seedPath,
  }) async {
    final conn = await _open();
    try {
      await _executeFile(conn, schemaPath);
      await _executeFile(conn, seedPath);
    } finally {
      await conn.close();
    }
  }

  Future<int> insert(UsageEvent event) async {
    final conn = await _open();
    try {
      final result = await conn.execute(
        Sql.named('''
          INSERT INTO groupscholar_resource_usage_ledger.usage_events (
            scholar_name,
            resource_name,
            resource_type,
            minutes,
            occurred_at,
            staff_name,
            notes
          ) VALUES (
            @scholar,
            @resource,
            @type,
            @minutes,
            @occurredAt,
            @staff,
            @notes
          )
          RETURNING id
        '''),
        parameters: {
          'scholar': event.scholarName,
          'resource': event.resourceName,
          'type': event.resourceType,
          'minutes': event.minutes,
          'occurredAt': event.occurredAt.toUtc(),
          'staff': event.staffName,
          'notes': event.notes,
        },
      );
      return result.first.first as int;
    } finally {
      await conn.close();
    }
  }

  Future<List<UsageEvent>> list({
    String? scholar,
    String? resource,
    DateTime? since,
    DateTime? until,
    int limit = 50,
  }) async {
    final conn = await _open();
    try {
      final where = <String>[];
      final params = <String, dynamic>{};

      if (scholar != null) {
        where.add('scholar_name = @scholar');
        params['scholar'] = scholar;
      }
      if (resource != null) {
        where.add('resource_name = @resource');
        params['resource'] = resource;
      }
      if (since != null) {
        where.add('occurred_at >= @since');
        params['since'] = since.toUtc();
      }
      if (until != null) {
        where.add('occurred_at <= @until');
        params['until'] = until.toUtc();
      }

      final buffer = StringBuffer(
        'SELECT id, scholar_name, resource_name, resource_type, minutes, '
        'occurred_at, staff_name, notes '
        'FROM groupscholar_resource_usage_ledger.usage_events',
      );
      if (where.isNotEmpty) {
        buffer.write(' WHERE ${where.join(' AND ')}');
      }
      buffer.write(' ORDER BY occurred_at DESC LIMIT @limit');
      params['limit'] = limit;

      final result = await conn.execute(
        Sql.named(buffer.toString()),
        parameters: params,
      );

      return result
          .map(
            (row) => UsageEvent(
              id: row[0] as int,
              scholarName: row[1] as String,
              resourceName: row[2] as String,
              resourceType: row[3] as String,
              minutes: row[4] as int,
              occurredAt: row[5] as DateTime,
              staffName: row[6] as String?,
              notes: row[7] as String?,
            ),
          )
          .toList();
    } finally {
      await conn.close();
    }
  }

  Future<List<UsageEvent>> allForWindow({
    DateTime? since,
    DateTime? until,
  }) async {
    return list(since: since, until: until, limit: 5000);
  }

  Future<void> _executeFile(Connection conn, String path) async {
    final contents = await File(path).readAsString();
    final statements = contents
        .split(';')
        .map((statement) => statement.trim())
        .where((statement) => statement.isNotEmpty);

    for (final statement in statements) {
      await conn.execute(statement);
    }
  }
}
