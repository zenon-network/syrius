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

@JsonSerializable()
/// A class that holds the state emitted by the [HideWidgetCubit]
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

  /// The exception that can be contained by a state emitted when the cubit
  /// encounters an error
  final SyriusException? exception;
  /// A field that tells if a widget should be hidden or not
  final bool? isHidden;
  /// The current status of hiding or un-hiding a widget
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
