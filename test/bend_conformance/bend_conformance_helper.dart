import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Loads Bend oracle conformance vectors for [domain] from the JSON file
/// referenced by the `BEND_VECTORS` environment variable.
///
/// Expected file structure:
/// ```json
/// {
///   "version": 1,
///   "domains": {
///     "<domain>": [
///       { "id": "...", "op": "...", "args": { ... }, "expected": ... }
///     ]
///   }
/// }
/// ```
///
/// Fails loudly (never silently skips) if `BEND_VECTORS` is unset, unreadable,
/// malformed, or missing vectors for [domain].
List<Map<String, dynamic>> loadBendVectors(String domain) {
  final String? path = Platform.environment['BEND_VECTORS'];
  if (path == null || path.isEmpty) {
    fail(
      'BEND_VECTORS environment variable is required to run Bend '
      'conformance tests. Run `./test/bend/run.sh` to execute Bend '
      'conformance tests, or `flutter test --exclude-tags chain,bend` for '
      'regular unit tests.',
    );
  }

  final File file = File(path);
  if (!file.existsSync()) {
    fail('BEND_VECTORS file does not exist: $path');
  }

  final Object? decoded;
  try {
    decoded = jsonDecode(file.readAsStringSync());
  } on Object catch (error) {
    fail('Failed to decode BEND_VECTORS JSON at $path: $error');
  }

  if (decoded is! Map<String, dynamic>) {
    fail('BEND_VECTORS root must be a JSON object: $path');
  }

  final Object? version = decoded['version'];
  if (version != 1) {
    fail('Unsupported BEND_VECTORS version=$version (expected 1): $path');
  }

  final Object? domains = decoded['domains'];
  if (domains is! Map<String, dynamic>) {
    fail('BEND_VECTORS missing "domains" object: $path');
  }

  final Object? rawCases = domains[domain];
  if (rawCases is! List<dynamic> || rawCases.isEmpty) {
    fail('BEND_VECTORS missing non-empty vector list for domain "$domain".');
  }

  final List<Map<String, dynamic>> cases = <Map<String, dynamic>>[];
  for (int i = 0; i < rawCases.length; i += 1) {
    final Object? entry = rawCases[i];
    if (entry is! Map<String, dynamic>) {
      fail('Malformed vector at $domain[$i]: expected JSON object.');
    }
    cases.add(entry);
  }
  return cases;
}

/// Asserts that [actual] produced by real Syrius Dart code matches [expected]
/// produced by the Bend oracle for [domain]/[caseId].
///
/// Emits the canonical `BEND_MISMATCH` prefix required by Stage 6 Dart
/// source-mutation verification.
void expectBendMatch({
  required String domain,
  required String caseId,
  required Object? actual,
  required Object? expected,
}) {
  if (!_deepEquals(actual, expected)) {
    fail(
      'BEND_MISMATCH [$domain/$caseId]: expected=$expected actual=$actual',
    );
  }
}

/// Extracts the required string case identifier from a vector entry.
String requireCaseId(Map<String, dynamic> vector) {
  final Object? id = vector['id'];
  if (id is! String || id.isEmpty) {
    fail('Bend vector missing non-empty string "id": $vector');
  }
  return id;
}

/// Extracts the required operation name from a vector entry.
String requireOp(Map<String, dynamic> vector) {
  final Object? op = vector['op'];
  if (op is! String || op.isEmpty) {
    fail('Bend vector missing non-empty string "op": $vector');
  }
  return op;
}

/// Extracts the required `args` JSON object from a vector entry.
Map<String, dynamic> requireArgs(Map<String, dynamic> vector) {
  final Object? args = vector['args'];
  if (args is! Map<String, dynamic>) {
    fail('Bend vector missing "args" object: $vector');
  }
  return args;
}

/// Reads a required [int] field [key] from [map].
int requireInt(Map<String, dynamic> map, String key) {
  final Object? value = map[key];
  if (value is int) {
    return value;
  }
  fail('Expected int for "$key" in $map, got $value');
}

/// Reads a required [bool] field [key] from [map].
bool requireBool(Map<String, dynamic> map, String key) {
  final Object? value = map[key];
  if (value is bool) {
    return value;
  }
  fail('Expected bool for "$key" in $map, got $value');
}

/// Reads a required [String] field [key] from [map].
String requireString(Map<String, dynamic> map, String key) {
  final Object? value = map[key];
  if (value is String) {
    return value;
  }
  fail('Expected String for "$key" in $map, got $value');
}

/// Reads a required [BigInt] field [key] (int or decimal string) from [map].
BigInt requireBigInt(Map<String, dynamic> map, String key) {
  final Object? value = map[key];
  if (value is int) {
    return BigInt.from(value);
  }
  if (value is String) {
    final BigInt? parsed = BigInt.tryParse(value);
    if (parsed != null) {
      return parsed;
    }
  }
  fail('Expected BigInt (int or numeric string) for "$key" in $map');
}

/// Reads a required [List] of [int] from [map] under [key].
List<int> requireIntList(Map<String, dynamic> map, String key) {
  final Object? value = map[key];
  if (value is! List<dynamic>) {
    fail('Expected List<int> for "$key" in $map, got $value');
  }
  final List<int> result = <int>[];
  for (final Object? element in value) {
    if (element is! int) {
      fail('Expected int element in "$key" of $map, got $element');
    }
    result.add(element);
  }
  return result;
}

bool _deepEquals(Object? a, Object? b) {
  if (a == b) {
    return true;
  }
  if (a is List<Object?> && b is List<Object?>) {
    if (a.length != b.length) {
      return false;
    }
    for (int i = 0; i < a.length; i += 1) {
      if (!_deepEquals(a[i], b[i])) {
        return false;
      }
    }
    return true;
  }
  if (a is Map<Object?, Object?> && b is Map<Object?, Object?>) {
    if (a.length != b.length) {
      return false;
    }
    for (final MapEntry<Object?, Object?> entry in a.entries) {
      if (!b.containsKey(entry.key) ||
          !_deepEquals(entry.value, b[entry.key])) {
        return false;
      }
    }
    return true;
  }
  return false;
}
