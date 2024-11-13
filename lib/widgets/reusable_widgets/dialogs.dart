import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/utils/app_colors.dart';

Future<bool> showWarningDialog({
  required BuildContext context,
  required String title,
  required String description,
  required String buttonText,
  VoidCallback? onActionButtonPressed,
}) async {
  bool isPressed = false;
  await showDialog(
    context: context,
    builder: (BuildContext context) => AlertDialog(
      icon: const Icon(
        Icons.warning,
        size: 24,
        color: Colors.orange,
      ),
      title: Text(title),
      content: Text(description),
      actions: <Widget>[
        TextButton(
          onPressed: onActionButtonPressed ??
              () {
                Navigator.pop(context);
              },
          style: const ButtonStyle(
            backgroundColor: WidgetStatePropertyAll(Colors.amber),
          ),
          child: Text(
            'Cancel',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        TextButton(
          onPressed: onActionButtonPressed ??
              () {
                isPressed = true;
                Navigator.pop(context);
              },
          style: const ButtonStyle(
            backgroundColor: WidgetStatePropertyAll(Colors.orange),
          ),
          child: Text(
            buttonText.isEmpty ? 'OK' : buttonText,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    ),
    barrierDismissible: false,
  );
  return isPressed;
}

Future showDialogWithNoAndYesOptions({
  required BuildContext context,
  required String title,
  required VoidCallback onYesButtonPressed,
  required isBarrierDismissible,
  VoidCallback? onNoButtonPressed,
  Widget? content,
  String? description,
}) =>
    showDialog(
      barrierDismissible: isBarrierDismissible,
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(title),
        content: content ?? Text(description!),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              onNoButtonPressed?.call();
              Navigator.pop(context, false);
            },
            child: Text(
              'No',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
          TextButton(
            style: TextButton.styleFrom(
              backgroundColor: AppColors.errorColor,
            ),
            onPressed: () {
              onYesButtonPressed.call();
              Navigator.pop(context, true);
            },
            child: Text(
              'Yes',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ],
      ),
    );

Future<Object?> showCustomDialog({required BuildContext context, required Widget content}) =>
    showGeneralDialog(
      context: context,
      barrierLabel: '',
      barrierDismissible: true,
      pageBuilder: (BuildContext context, Animation<double> animation,
              Animation<double> secondaryAnimation,) =>
          Center(
        child: ClipRRect(
            borderRadius: BorderRadius.circular(15), child: content,),
      ),
    );
