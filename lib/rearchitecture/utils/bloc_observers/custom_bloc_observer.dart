import 'package:bloc/bloc.dart';
import 'package:logging/logging.dart';

/// A custom bloc observer that helps log the errors
class CustomBlocObserver extends BlocObserver {
  @override
  void onError(BlocBase<dynamic> bloc, Object error, StackTrace stackTrace) {
    Logger('Bloc: ${bloc.runtimeType}').warning('onError: ', error, stackTrace);
    super.onError(bloc, error, stackTrace);
  }
}
