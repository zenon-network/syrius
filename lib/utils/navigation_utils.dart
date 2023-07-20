import 'package:flutter/material.dart';
import 'package:page_transition/page_transition.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/blocs.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/model/model.dart';

class NavigationUtils {
  static Future<void> openUrl(String url) async {
    if (!RegExp(r'^http').hasMatch(url)) {
      url = 'http://$url';
    }
    var uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      sl.get<NotificationsBloc>().addNotification(
            WalletNotification(
              title: 'Error while trying to open $url',
              timestamp: DateTime.now().millisecondsSinceEpoch,
              details: 'Something went wrong while trying to open $url',
              type: NotificationType.error,
            ),
          );
    }
  }

  static void push(context, Widget child) {
    Navigator.push(
      context,
      PageTransition(
        child: child,
        type: PageTransitionType.rightToLeft,
      ),
    );
  }

  static void pushReplacement(context, Widget child) {
    Navigator.pushReplacement(
      context,
      PageTransition(
        child: child,
        type: PageTransitionType.rightToLeft,
      ),
    );
  }

  static void popRepeated(context, int times) {
    int count = 0;
    Navigator.popUntil(context, (route) => count++ == times);
  }
}
