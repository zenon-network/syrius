import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/blocs.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/cubits/cubit_with_refresh_mixin.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/cubits/indicator_state.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/exceptions/exceptions.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

/// A cubit used to manage reloading and updating indicator states.
/// This cubit can be used for any data-fetching operations that require
/// real-time updates from the Zenon SDK. In contrast with
/// [CubitWithRefreshMixin], this cubit emits a loading indicator state before
/// any data fetching.
abstract class CubitForReloadingIndicator<T, S extends IndicatorState<T>>
    extends HydratedCubit<S> with RefreshBlocMixin {

  /// Constructor for [CubitForReloadingIndicator].
  /// [callUpdateStream] determines if [updateStream] is called initially.
  CubitForReloadingIndicator(
      super.initialState, {
        required this.zenon,
        bool callUpdateStream = true,
      }) {
    if (callUpdateStream) {
      // Calls the [updateStream] method to fetch data initially and starts
      // listening for WebSocket restart events to trigger [updateStream].
      updateStream();
      listenToWsRestart(updateStream);
    }
  }

  /// An instance of [Zenon] used for data fetching and managing connections.
  final Zenon zenon;

  /// Abstract method [getData] that must be implemented by subclasses.
  Future<T> getData();

  /// [updateStream] is a method that fetches data and updates the state.
  Future<void> updateStream() async {
    try {
      // Emit a loading state before attempting to fetch data.
      emit(state.copyWith(status: IndicatorStatus.loading) as S);

      // Check if the WebSocket client is connected before fetching data.
      if (!zenon.wsClient.isClosed()) {
        final T data = await getData();

        // Emit a success state with the fetched data.
        emit(state.copyWith(data: data, status: IndicatorStatus.success) as S);
      } else {
        // Throws an exception if WebSocket is disconnected.
        throw noConnectionException;
      }
    } on SyriusException catch (e) {
      // If a [SyriusException] occurs, emit a failure state with the error.
      emit(state.copyWith(status: IndicatorStatus.failure, error: e) as S);
    } catch (e, stackTrace) {
      // For any unexpected errors, emit a failure state and log the error.
      emit(
        state.copyWith(
          status: IndicatorStatus.failure,
          error: CubitFailureException(),
        ) as S,
      );
      // Log unexpected errors along with their stack trace for debugging.
      addError(e, stackTrace);
    }
  }

  /// Overrides the [close] method to clean up resources.
  /// Cancels the WebSocket subscription before closing the cubit.
  @override
  Future<void> close() {
    cancelStreamSubscription();
    return super.close();
  }
}
