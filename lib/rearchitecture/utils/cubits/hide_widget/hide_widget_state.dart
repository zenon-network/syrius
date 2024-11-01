part of 'hide_widget_cubit.dart';

enum HideWidgetStatus {
  failure,
  initial,
  loading,
  success,
}

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

  final SyriusException? exception;
  final bool? isHidden;
  final HideWidgetStatus status;

  @override
  List<Object?> get props => [isHidden, exception, status];

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
