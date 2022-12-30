import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/screens/screens.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/buttons/onboarding_button.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/progress_bars.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/select_file_widget.dart';

class SwapImportScreen extends StatefulWidget {
  const SwapImportScreen({Key? key}) : super(key: key);

  @override
  _SwapImportScreenState createState() => _SwapImportScreenState();
}

class _SwapImportScreenState extends State<SwapImportScreen> {
  String? _path;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: const EdgeInsets.symmetric(
          vertical: 30.0,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            const ProgressBar(
              currentLevel: 2,
              numLevels: 4,
            ),
            Text(
              'Swap wallet',
              style: Theme.of(context).textTheme.headline1,
            ),
            Text(
              'Click browse to select your legacy \'wallet.dat\' file',
              style: Theme.of(context).textTheme.headline4,
            ),
            _getUploadWalletFileContainer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                _getPassiveButton(),
                kSpacingBetweenActionButtons,
                _getActionButton()
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _getUploadWalletFileContainer() {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: 20.0,
      ),
      child: SelectFileWidget(
          fileExtension: 'dat',
          onPathFoundCallback: (String path) {
            setState(() {
              _path = path;
            });
          }),
    );
  }

  Widget _getActionButton() {
    return OnboardingButton(
      onPressed: _path != null
          ? () {
              NavigationUtils.push(
                context,
                SwapPasswordScreen(_path!),
              );
            }
          : null,
      text: 'Continue',
    );
  }

  Widget _getPassiveButton() {
    return OnboardingButton(
      onPressed: () {
        Navigator.pop(context);
      },
      text: 'Go back',
    );
  }
}
