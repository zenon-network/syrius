import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/screens/screens.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';

/// This will be used to quickly initialize the app when testing in the
/// development phase

class DevelopmentInitializationScreen extends StatefulWidget {

  const DevelopmentInitializationScreen({super.key});
  static const String route = 'development-initialization-screen';

  @override
  State<DevelopmentInitializationScreen> createState() =>
      _DevelopmentInitializationScreenState();
}

class _DevelopmentInitializationScreenState
    extends State<DevelopmentInitializationScreen> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _checkIfWalletPathIsNull(context: context),
      builder: (_, snapshot) {
        if (snapshot.hasData) {
          final isWalletPathNull = snapshot.data!;

          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (isWalletPathNull) {
              _navigateToAccessWalletScreen(context: context);
            } else {
              _navigateToHomeScreen(context: context);
            }
          });

          return const SizedBox.shrink();
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }

        return const Center(child: CircularProgressIndicator());
      },
    );
  }

  Future<bool> _checkIfWalletPathIsNull({required BuildContext context}) async {
    try {
      await InitUtils.initApp(context);
      return kWalletPath == null;
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

  void _navigateToAccessWalletScreen({required BuildContext context}) {
    Navigator.pushReplacementNamed(
      context,
      AccessWalletScreen.route,
    );
  }
}
