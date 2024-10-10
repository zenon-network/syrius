import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/screens/screens.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';

/// This will be used to quickly initialize the app when testing in the
/// development phase

class DevelopmentInitializationScreen extends StatelessWidget {
  static const String route = 'development-initialization-screen';

  const DevelopmentInitializationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _initializeApp(context: context),
      builder: (_, snapshot) {
        if (snapshot.hasData) {
          final bool finished = snapshot.data!;
          if (finished) {
            _navigateToHomeScreen(context: context);
          } else {
            return Text('Error while initializing the app');
          }
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }

        return Center(child: CircularProgressIndicator());
      },
    );
  }

  Future<bool> _initializeApp({required BuildContext context}) async {
    try {
      await InitUtils.initApp(context);
      if (kWalletPath == null) {
        if (!context.mounted) return false;
        Navigator.pushReplacementNamed(
          context,
          AccessWalletScreen.route,
        );
      }
      return true;
    } on Exception catch (_) {
      rethrow;
    }
  }

  void _navigateToHomeScreen({required BuildContext context}) {
    Navigator.of(
      context,
      rootNavigator: true,
    ).pushReplacementNamed(MainAppContainer.route);
  }
}
