import 'package:zenon_syrius_wallet_flutter/blocs/base_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/utils/global.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/main_app_container.dart';

enum LockEvent {
  countDown,
  navigateToLock,
  resetTimer,
  navigateToDashboard,
  navigateToPreviousTab,
}

class LockBloc extends BaseBloc<LockEvent> {
  @override
  void addEvent(event) {
    if (!(kCurrentPage == Tabs.lock && event == LockEvent.resetTimer)) {
      super.addEvent(event);
    }
  }
}
