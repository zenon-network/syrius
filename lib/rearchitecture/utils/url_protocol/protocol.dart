part of 'api.dart';

/// An abstract calls that helps manage a custom URL scheme used to open the
/// app
abstract class ProtocolHandler {
  /// Registers the scheme.
  void register(String scheme, {String? executable, List<String>? arguments});
  /// Unregisters the scheme.
  void unregister(String scheme);
  /// Gets arguments from the scheme.
  List<String> getArguments(List<String>? arguments) {
    if (arguments == null) return ['%s'];

    if (arguments.isEmpty && !arguments.any((e) => e.contains('%s'))) {
      throw ArgumentError('arguments must contain at least 1 instance of "%s"');
    }

    return arguments;
  }
}
