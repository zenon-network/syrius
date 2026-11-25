part of 'pow_generating_status_bloc.dart';

/// State representing the current PoW plasma generation status.
final class PowGeneratingStatusState extends Equatable {
  /// Creates a [PowGeneratingStatusState].
  const PowGeneratingStatusState({this.status = PowStatus.done});

  /// Current PoW generation status.
  final PowStatus status;

  /// Whether PoW plasma is currently being generated.
  bool get isGenerating => status == PowStatus.generating;

  @override
  List<Object> get props => <Object>[status];
}
