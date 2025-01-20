import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stream_transform/stream_transform.dart';

/// Helps with filtering events, making sure that only one is emitted in the
/// interval defined by [duration] parameter
EventTransformer<E> throttleDroppable<E>(Duration duration) {
  return (Stream<E> events, EventMapper<E> mapper) {
    return droppable<E>().call(events.throttle(duration), mapper);
  };
}
