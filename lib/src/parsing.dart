DateTime parseDateTime(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    throw FormatException('Empty date value');
  }
  final parsed = DateTime.tryParse(trimmed);
  if (parsed != null) {
    return parsed;
  }

  final dateOnly = DateTime.tryParse('${trimmed}T00:00:00Z');
  if (dateOnly != null) {
    return dateOnly;
  }

  throw FormatException('Invalid date: $value');
}
