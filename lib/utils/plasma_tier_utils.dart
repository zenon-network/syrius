import 'package:znn_sdk_dart/znn_sdk_dart.dart';

/// Minimum plasma required for average-tier transactions (e.g. token issuance).
const int kPlasmaAverageThreshold = 189000;

/// Minimum plasma required for high-tier transactions (e.g. Pillar operations).
const int kPlasmaHighThreshold = 252000;

/// Discrete plasma sufficiency tiers displayed across Syrius UI indicators.
enum PlasmaTier {
  /// Below [minPlasmaAmount] (`< 21000`).
  insufficient,

  /// Within `[21000, 189000)`.
  low,

  /// Within `[189000, 252000)`.
  average,

  /// At least `252000`.
  high,
}

/// Classifies [currentPlasma] into one of four exhaustive, mutually exclusive,
/// monotone [PlasmaTier] bands.
PlasmaTier classifyPlasmaTier(int currentPlasma) {
  if (currentPlasma >= kPlasmaHighThreshold) {
    return PlasmaTier.high;
  }
  if (currentPlasma >= kPlasmaAverageThreshold) {
    return PlasmaTier.average;
  }
  if (currentPlasma >= minPlasmaAmount.toInt()) {
    return PlasmaTier.low;
  }
  return PlasmaTier.insufficient;
}
