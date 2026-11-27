/// Route arguments passed when navigating to the Syrius error screen.
class CustomSyriusErrorWidgetArguments {
  /// Creates route arguments containing [errorText].
  CustomSyriusErrorWidgetArguments(this.errorText);

  /// Human-readable error message displayed by the error widget.
  final String errorText;
}
