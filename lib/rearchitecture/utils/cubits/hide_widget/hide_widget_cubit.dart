import 'package:equatable/equatable.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:logging/logging.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/exceptions/exceptions.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

part 'hide_widget_cubit.g.dart';

part 'hide_widget_state.dart';

/// A cubit that handles saving whether a widget is hidden or not
///
/// When the user wants to make the widget visible, it checks that the provided
/// wallet password is correct
class HideWidgetCubit extends HydratedCubit<HideWidgetState> {
  /// Creates a new instance with an initial state
  HideWidgetCubit() : super(const HideWidgetState.initial());

  @override
  HideWidgetState? fromJson(Map<String, dynamic> json) =>
      HideWidgetState.fromJson(json);

  /// A method that handles saving the widget as hidden or not
  Future<void> saveValue({
    required bool isHidden,
    required String widgetTitle,
    String? password,
  }) async {
    emit(state.copyWith(status: HideWidgetStatus.loading));
    try {
      if (!isHidden) {
        // TODO(maznnwell): use an Isolate
        await WalletUtils.decryptWalletFile(kWalletPath!, password!);
      }
      await _markWidgetAsHidden(widgetTitle, isHidden);
      emit(
        state.copyWith(
          isHidden: isHidden,
          status: HideWidgetStatus.success,
        ),
      );
    } on IncorrectPasswordException catch (e, stackTrace) {
      emit(
        state.copyWith(
          status: HideWidgetStatus.failure,
          exception: SyriusException(kIncorrectPasswordNotificationTitle),
        ),
      );
      addError(kIncorrectPasswordNotificationTitle, stackTrace);
    } catch (error, stackTrace) {
      emit(
        state.copyWith(
          status: HideWidgetStatus.failure,
          exception: CubitFailureException(),
        ),
      );
      addError(error, stackTrace);
    }
  }

  Future<void> _markWidgetAsHidden(String widgetTitle, bool isHidden) async {
    await sharedPrefsService!.put(
      WidgetUtils.isWidgetHiddenKey(widgetTitle),
      isHidden,
    );
  }

  @override
  Map<String, dynamic>? toJson(HideWidgetState state) => state.toJson();

  @override
  void onError(Object error, StackTrace stackTrace) {
    Logger('HideWidgetCubit').warning(
      'onError triggered',
      error,
      stackTrace,
    );
    super.onError(error, stackTrace);
  }
}
