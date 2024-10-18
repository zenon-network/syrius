import 'package:zenon_syrius_wallet_flutter/blocs/blocs.dart';
import 'package:zenon_syrius_wallet_flutter/utils/global.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';

enum LockEvent {
  countDown,
  navigateToLock,
  resetTimer,
  navigateToDashboard,
  navigateToPreviousTab,
}

class LockBloc extends BaseBloc<LockEvent> {
  @override
  void addEvent(LockEvent event) {
    if (!(kCurrentPage == Tabs.lock && event == LockEvent.resetTimer)) {
      super.addEvent(event);
    }
  }
}
