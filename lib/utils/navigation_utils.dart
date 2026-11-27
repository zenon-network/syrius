import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/model/model.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/notifications/notifications.dart';

/// Utilities for external URL launching and imperative route navigation.
class NavigationUtils {
  /// Launches [url] in the system browser, prepending `https://` if no HTTP
  /// scheme is present, and records an error notification on failure.
  static Future<void> openUrl(String url) async {
    final String normalizedUrl = RegExp('^http').hasMatch(url)
        ? url
        : 'https://$url';
    final Uri uri = Uri.parse(normalizedUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      await sl.get<NotificationsBloc>().addNotification(
            WalletNotification(
              title: 'Error while trying to open $normalizedUrl',
              timestamp: DateTime.now().millisecondsSinceEpoch,
              details:
                  'Something went wrong while trying to open $normalizedUrl',
              type: NotificationType.error,
            ),
          );
    }
  }

  // TODO(maznnwell): check if there is a desire to impose a right-to-left
  // transition.
  /// Pushes [child] onto the navigator associated with [context].
  static void push(BuildContext context, Widget child) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => child,
      ),
    );
  }

  /// Replaces the current route on [context]'s navigator with [child].
  static void pushReplacement(BuildContext context, Widget child) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute<void>(
        builder: (_) => child,
      ),
    );
  }

  /// Pops [times] routes from the navigator associated with [context].
  static void popRepeated(BuildContext context, int times) {
    int count = 0;
    Navigator.popUntil(context, (Route<dynamic> route) => count++ == times);
  }
}
