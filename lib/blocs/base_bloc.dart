import 'dart:async';

import 'package:rxdart/rxdart.dart';
import 'package:stacked/stacked.dart';
import 'package:zenon_syrius_wallet_flutter/utils/logger.dart';

abstract class BaseBloc<T> extends BaseViewModel {
  final BehaviorSubject<T> _controller = BehaviorSubject();

  StreamSink<T?> get _sink => _controller.sink;

  Stream<T> get stream => _controller.stream;

  void addEvent(T event) {
    if (!_controller.isClosed) _sink.add(event);
  }

  void addError(error) {
    if (!_controller.isClosed) {
      Logger.logError(error);
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
