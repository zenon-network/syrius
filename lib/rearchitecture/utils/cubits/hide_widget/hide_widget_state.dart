part of 'hide_widget_cubit.dart';

/// A class that represents the status of hiding a widget
enum HideWidgetStatus {
  /// The hiding process has failed
  failure,
  /// The hiding process has not started
  initial,
  /// The hiding process is ongoing
  loading,
  /// The hiding process has succeeded
  success,
}

/// A class designed to tell us the current state of the two operations:
/// hiding or un-hiding a widget
@JsonSerializable()
class HideWidgetState extends Equatable {
  /// Creates a new instance.
  const HideWidgetState({
    required this.status,
    this.exception,
    this.isHidden,
  });

  /// Creates a new instance with the [status] of [HideWidgetStatus.initial]
  const HideWidgetState.initial()
      : this(
          status: HideWidgetStatus.initial,
        );

  /// Creates a new instance from a JSON map.
  factory HideWidgetState.fromJson(Map<String, dynamic> json) =>
      _$HideWidgetStateFromJson(json);

  /// An exception that occurred during the hiding or un-hiding operation.
  final SyriusException? exception;
  /// Specifies if the current status is hidden or not.
  final bool? isHidden;
  /// The status of hiding or un-hiding the widget.
  final HideWidgetStatus status;

  @override
  List<Object?> get props => <Object?>[isHidden, exception, status];

  /// {@macro state_copy_with}
  HideWidgetState copyWith({
    SyriusException? exception,
    bool? isHidden,
    HideWidgetStatus? status,
  }) {
    return HideWidgetState(
      exception: exception ?? this.exception,
      isHidden: isHidden ?? this.isHidden,
      status: status ?? this.status,
    );
  }

  /// Converts this instance to a JSON map.
  Map<String, dynamic> toJson() => _$HideWidgetStateToJson(this);
}
