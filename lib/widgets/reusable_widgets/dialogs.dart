import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/utils/app_colors.dart';

showWarningDialog({
  required BuildContext context,
  required String title,
  required String description,
  required String buttonText,
  VoidCallback? onActionButtonPressed,
}) async {
  bool isPressed = false;
  await showDialog(
    context: context,
    builder: (context) => AlertDialog(
      icon: const Icon(
        Icons.warning,
        size: 24.0,
        color: Colors.orange,
      ),
      title: Text(title),
      content: Text(description),
      actions: [
        TextButton(
          onPressed: onActionButtonPressed ??
              () {
                isPressed = true;
                Navigator.pop(context);
              },
          style: const ButtonStyle(
            backgroundColor: MaterialStatePropertyAll(Colors.orange),
          ),
          child: Text(
            buttonText.isEmpty ? 'OK' : buttonText,
            style: Theme.of(context).textTheme.bodyText1,
          ),
        ),
      ],
    ),
    barrierDismissible: false,
  );
  return isPressed;
}

showDialogWithNoAndYesOptions({
  required BuildContext context,
  required String title,
  required String description,
  required VoidCallback onYesButtonPressed,
}) =>
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(description),
        actions: [
          TextButton(
            child: Text(
              'No',
              style: Theme.of(context).textTheme.bodyText1,
            ),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          TextButton(
            onPressed: onYesButtonPressed,
            style: Theme.of(context).textButtonTheme.style!.copyWith(
                  backgroundColor: MaterialStateColor.resolveWith(
                      (states) => AppColors.errorColor),
                ),
            child: Text(
              'Yes',
              style: Theme.of(context).textTheme.bodyText1,
            ),
          ),
        ],
      ),
    );
