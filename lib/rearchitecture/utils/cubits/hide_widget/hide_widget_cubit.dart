import 'package:equatable/equatable.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:logging/logging.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/exceptions/exceptions.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/wallet_file.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

part 'hide_widget_cubit.g.dart';

part 'hide_widget_state.dart';

/// A bloc that handles saving whether a widget is hidden or not
///
/// When the user wants to make the widget visible, it checks that the provided
/// wallet password is correct
class HideWidgetCubit extends HydratedCubit<HideWidgetState> {
  /// Creates a new instance with an initial state
  HideWidgetCubit({
    Future<WalletFile> Function(String walletPath, String password)?
    decryptWalletFile,
    String? Function()? walletPathProvider,
    Future<void> Function(String widgetTitle, {required bool isHidden})?
    markWidgetAsHidden,
  }) : _decryptWalletFile = decryptWalletFile ?? WalletUtils.decryptWalletFile,
       _walletPathProvider = walletPathProvider ?? _defaultWalletPath,
       _markWidgetAsHiddenCallback = markWidgetAsHidden,
       super(const HideWidgetState.initial());

  final Future<WalletFile> Function(String walletPath, String password)
  _decryptWalletFile;
  final String? Function() _walletPathProvider;
  final Future<void> Function(String widgetTitle, {required bool isHidden})?
  _markWidgetAsHiddenCallback;

  static String? _defaultWalletPath() => kWalletPath;

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
        final WalletFile walletFile = await _decryptWalletFile(
          _walletPathProvider()!,
          password!,
        );
        try {
          await walletFile.close();
        } on Object catch (closeError, closeStackTrace) {
          Logger('HideWidgetCubit').warning(
            'Failed to close temporary WalletFile',
            closeError,
            closeStackTrace,
          );
        }
      }
      await _markWidgetAsHidden(widgetTitle, isHidden: isHidden);
      emit(
        state.copyWith(isHidden: isHidden, status: HideWidgetStatus.success),
      );
    } on IncorrectPasswordException catch (e, stackTrace) {
      final LocalizedSyriusException exception = LocalizedSyriusException(
        SyriusErrorCode.incorrectPassword,
      );
      emit(
        state.copyWith(status: HideWidgetStatus.failure, exception: exception),
      );
      addError(exception, stackTrace);
    } on Object catch (error, stackTrace) {
      emit(
        state.copyWith(
          status: HideWidgetStatus.failure,
          exception: FailureException(),
        ),
      );
      addError(error, stackTrace);
    }
  }

  Future<void> _markWidgetAsHidden(
    String widgetTitle, {
    required bool isHidden,
  }) async {
    final Future<void> Function(String widgetTitle, {required bool isHidden})?
    customMarkWidgetAsHidden = _markWidgetAsHiddenCallback;
    if (customMarkWidgetAsHidden != null) {
      await customMarkWidgetAsHidden(widgetTitle, isHidden: isHidden);
      return;
    }
    await sharedPrefsService!.put(
      WidgetUtils.isWidgetHiddenKey(widgetTitle),
      isHidden,
    );
  }

  @override
  Map<String, dynamic>? toJson(HideWidgetState state) => state.toJson();

  @override
  void onError(Object error, StackTrace stackTrace) {
    Logger('HideWidgetCubit').warning('onError triggered', error, stackTrace);
    super.onError(error, stackTrace);
  }
}
