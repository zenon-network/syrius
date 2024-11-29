part of 'hide_widget_cubit.dart';

/// The status of hiding or un-hiding the widget.
enum HideWidgetStatus {
  /// Operation failed.
  failure,
  /// Operation not started.
  initial,
  /// Operation is in progress.
  loading,
  /// Operation succeeded.
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

  /// Creates a copy of the current state with the option to modify specific
  /// fields.
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
