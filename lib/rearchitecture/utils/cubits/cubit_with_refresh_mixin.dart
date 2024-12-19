import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/blocs.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/cubits/cubit_with_refresh_mixin_state.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/exceptions/exceptions.dart';
import 'package:zenon_syrius_wallet_flutter/utils/global.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

/// A cubit used to manage reloading and updating indicator states.
///
/// This cubit can be used for any data-fetching operations that require
/// real-time updates from the Zenon SDK.
abstract class CubitWithRefreshMixin<T, S extends CubitWithRefreshMixinState<T>>
    extends HydratedCubit<S> with RefreshBlocMixin {
  /// Constructor for [CubitWithRefreshMixin].
  CubitWithRefreshMixin({
    required S initialState,
    required this.zenon,
  }) : super(initialState) {
    listenToWsRestart(
      () => updateStream(
        address: Address.parse(kSelectedAddress!),
      ),
    );
  }

  /// An instance of [Zenon] used for data fetching and managing connections.
  final Zenon zenon;

  /// Abstract method [getData] that subclasses must implement.
  Future<T> getData({required Address address});

  /// [updateStream] handles the data fetching process and updates the state
  /// accordingly.
  ///
  /// It emits a loading state only if the previous status was
  /// not successful, then attempts to fetch data using [getData].
  Future<void> updateStream({required Address address}) async {
    try {
      // Proceed with data fetching only if the WebSocket connection is open.
      if (!zenon.wsClient.isClosed()) {
        final T? data = await getData(
          address: address,
        );

        emit(
          state.copyWith(
            data: data,
            status: CubitWithRefreshMixinStatus.success,
          ) as S,
        );
      } else {
        // Throw an exception if there is no WebSocket connection.
        throw SyriusException(noConnectionException.message!);
      }
    } on SyriusException catch (e, stackTrace) {
      // Emit a failure state with the specific error.
      emit(
        state.copyWith(
          status: CubitWithRefreshMixinStatus.failure,
          error: e,
        ) as S,
      );
      addError(e, stackTrace);
    } catch (e, stackTrace) {
      // For unexpected errors, emit a failure state with a generic error.
      emit(
        state.copyWith(
          status: CubitWithRefreshMixinStatus.failure,
          error: SyriusException(e.toString() + stackTrace.toString()),
        ) as S,
      );
      // Log unexpected errors and their stack traces for further investigation.
      addError(e, stackTrace);
    }
  }

  /// Overrides the [close] method to perform cleanup before closing the cubit.
  ///
  /// Cancels any active WebSocket subscriptions managed by the mixin.
  @override
  Future<void> close() {
    cancelStreamSubscription();
    return super.close();
  }
}
