import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:zenon_syrius_wallet_flutter/model/model.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

part 'about_event.dart';
part 'about_state.dart';

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
    try {
      final Momentum frontierMomentum = await _zenon.ledger
          .getFrontierMomentum();
      final ProcessInfo processInfo = await _zenon.stats.processInfo();
      final NetworkInfo networkInfo = await _zenon.stats.networkInfo();
      final OsInfo osInfo = await _zenon.stats.osInfo();

      emit(
        AboutPopulated(
          stats: GeneralStats(
            frontierMomentum: frontierMomentum,
            processInfo: processInfo,
            networkInfo: networkInfo,
            osInfo: osInfo,
          ),
        ),
      );
    } on SyriusException catch (e, stackTrace) {
      addError(e, stackTrace);
      emit(AboutFailure(exception: e));
    } on Object catch (e, stackTrace) {
      addError(e, stackTrace);
      emit(AboutFailure(exception: FailureException()));
    }
  }
}
