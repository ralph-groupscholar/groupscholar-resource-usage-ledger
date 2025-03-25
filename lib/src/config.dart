import 'dart:io';

import 'package:postgres/postgres.dart';

class DatabaseConfig {
  DatabaseConfig({
    required this.host,
    required this.port,
    required this.database,
    required this.username,
    required this.password,
    required this.sslMode,
  });

  final String host;
  final int port;
  final String database;
  final String username;
  final String password;
  final SslMode sslMode;

  factory DatabaseConfig.fromEnv() {
    final env = Platform.environment;
    final host = env['PGHOST'];
    final port = env['PGPORT'];
    final database = env['PGDATABASE'];
    final username = env['PGUSER'];
    final password = env['PGPASSWORD'];
    if (host == null ||
        port == null ||
        database == null ||
        username == null ||
        password == null) {
      throw StateError(
        'Missing database environment variables. '
        'Set PGHOST, PGPORT, PGDATABASE, PGUSER, and PGPASSWORD.',
      );
    }

    final sslMode = _parseSslMode(env['PGSSLMODE']);
    return DatabaseConfig(
      host: host,
      port: int.tryParse(port) ?? 5432,
      database: database,
      username: username,
      password: password,
      sslMode: sslMode,
    );
  }
}

SslMode _parseSslMode(String? value) {
  switch (value?.toLowerCase()) {
    case 'disable':
      return SslMode.disable;
    case 'require':
      return SslMode.require;
    case 'verify-full':
      return SslMode.verifyFull;
    default:
      return SslMode.require;
  }
}
