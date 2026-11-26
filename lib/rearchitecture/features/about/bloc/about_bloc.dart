import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/about/model/about_node_info.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

part 'about_event.dart';
part 'about_state.dart';

class _RpcResult<T> {
  const _RpcResult({this.value, this.error, this.stackTrace});

  final T? value;
  final Object? error;
  final StackTrace? stackTrace;
}

/// Loads node and runtime statistics displayed in the About card.
class AboutBloc extends Bloc<AboutEvent, AboutState> {
  /// Creates an [AboutBloc] backed by the given [Zenon] client.
  AboutBloc({required this._zenon}) : super(const AboutInitial()) {
    on<AboutRequested>(_onAboutRequested, transformer: droppable());
  }

  final Zenon _zenon;

  Future<void> _onAboutRequested(
    AboutRequested event,
    Emitter<AboutState> emit,
  ) async {
    emit(const AboutLoading());

    final (
      _RpcResult<Momentum> momentumResult,
      _RpcResult<ProcessInfo> processInfoResult,
      _RpcResult<OsInfo> osInfoResult,
    ) = await (
      _fetchOptional<Momentum>(_zenon.ledger.getFrontierMomentum),
      _fetchOptional<ProcessInfo>(_zenon.stats.processInfo),
      _fetchOptional<OsInfo>(_zenon.stats.osInfo),
    ).wait;

    if (emit.isDone) {
      return;
    }

    final List<_RpcResult<Object>> results = <_RpcResult<Object>>[
      momentumResult,
      processInfoResult,
      osInfoResult,
    ];

    SyriusException? firstException;
    for (final _RpcResult<Object> result in results) {
      final Object? error = result.error;
      if (error != null) {
        addError(error, result.stackTrace ?? StackTrace.current);
        firstException ??= error is SyriusException
            ? error
            : FailureException();
      }
    }

    final AboutNodeInfo nodeInfo = AboutNodeInfo(
      frontierMomentum: momentumResult.value,
      processInfo: processInfoResult.value,
      osInfo: osInfoResult.value,
    );

    if (nodeInfo.isUnavailable) {
      emit(AboutFailure(exception: firstException ?? FailureException()));
      return;
    }

    emit(AboutPopulated(nodeInfo: nodeInfo, nodeError: firstException));
  }

  Future<_RpcResult<T>> _fetchOptional<T>(Future<T> Function() call) async {
    try {
      return _RpcResult<T>(value: await call());
    } on Object catch (error, stackTrace) {
      return _RpcResult<T>(error: error, stackTrace: stackTrace);
    }
  }
}
