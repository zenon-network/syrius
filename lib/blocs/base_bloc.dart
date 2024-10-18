import 'dart:async';

import 'package:logging/logging.dart';
import 'package:rxdart/rxdart.dart';
import 'package:stacked/stacked.dart';

abstract class BaseBloc<T> extends BaseViewModel {
  final BehaviorSubject<T> _controller = BehaviorSubject();

  StreamSink<T?> get _sink => _controller.sink;

  Stream<T> get stream => _controller.stream;

  void addEvent(T event) {
    if (!_controller.isClosed) _sink.add(event);
  }

  FutureOr<Null> addError(Object error, StackTrace stackTrace) async {
    Logger('BaseBloc').log(Level.WARNING, 'addError', error, stackTrace);
    if (!_controller.isClosed) {
      _sink.addError(error);
    }
  }

  @override
  void dispose() {
    _controller.close();
    if (!super.disposed) {
      super.dispose();
    }
  }
}
