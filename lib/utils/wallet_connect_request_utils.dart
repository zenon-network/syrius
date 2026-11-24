import 'dart:convert';

import 'package:reown_walletkit/reown_walletkit.dart';

/// Converts a WalletConnect request handler error into a [JsonRpcError],
/// preserving SDK/core error codes when available instead of collapsing all
/// failures into a generic error code.
JsonRpcError walletConnectErrorToJsonRpcError(Object error) {
  if (error is JsonRpcError) {
    return error;
  }
  if (error is ReownSignError) {
    return JsonRpcError(code: error.code, message: error.message);
  }
  if (error is ReownCoreError) {
    return JsonRpcError(code: error.code, message: error.message);
  }
  return JsonRpcError(code: 5000, message: error.toString());
}

/// Builds the single-flight key for an interactive WalletConnect request.
///
/// The JSON-RPC [requestId] is the canonical identity of a request: two
/// concurrent requests with identical params are still distinct requests and
/// must each get their own approval flow. The params fingerprint is only a
/// last-resort bridge for callers that do not know the request id.
String interactiveRequestKey({
  required String method,
  required String topic,
  required dynamic params,
  required int? requestId,
}) {
  if (requestId != null) {
    return '$method:$topic:#$requestId';
  }
  final String paramsFingerprint = requestParamsFingerprint(params);
  return '$method:$topic:$paramsFingerprint';
}

/// Canonical JSON fingerprint of request params: map keys are sorted
/// recursively so logically equal params produce the same fingerprint.
String requestParamsFingerprint(dynamic params) {
  try {
    return jsonEncode(_canonicalJsonValue(params));
  } on Object {
    return params.toString();
  }
}

dynamic _canonicalJsonValue(dynamic value) {
  if (value is Map) {
    final List<MapEntry<String, dynamic>> entries =
        value.entries
            .map(
              (MapEntry<dynamic, dynamic> entry) =>
                  MapEntry<String, dynamic>(entry.key.toString(), entry.value),
            )
            .toList()
          ..sort(
            (MapEntry<String, dynamic> left, MapEntry<String, dynamic> right) =>
                left.key.compareTo(right.key),
          );
    return <String, dynamic>{
      for (final MapEntry<String, dynamic> entry in entries)
        entry.key: _canonicalJsonValue(entry.value),
    };
  }
  if (value is Iterable) {
    return value.map<dynamic>(_canonicalJsonValue).toList();
  }
  return value;
}
