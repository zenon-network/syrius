import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/extensions/buildcontext_extension.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/theming/syrius_theme_tokens.dart';
import 'package:zenon_syrius_wallet_flutter/utils/app_colors.dart';

/// Displays a non-dismissible warning dialog and returns whether the user
/// confirmed the action.
Future<bool> showWarningDialog({
  required BuildContext context,
  required String title,
  required String description,
  required String buttonText,
  VoidCallback? onActionButtonPressed,
}) async {
  bool isPressed = false;
  await showDialog<void>(
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
          onPressed:
              onActionButtonPressed ??
              () {
                Navigator.pop(context);
              },
          style: const ButtonStyle(
            backgroundColor: WidgetStatePropertyAll<Color>(Colors.amber),
          ),
          child: Text(
            'Cancel',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        TextButton(
          onPressed:
              onActionButtonPressed ??
              () {
                isPressed = true;
                Navigator.pop(context);
              },
          style: const ButtonStyle(
            backgroundColor: WidgetStatePropertyAll<Color>(Colors.orange),
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

/// Displays a confirmation dialog with "No" and "Yes" actions.
Future<bool?> showDialogWithNoAndYesOptions({
  required BuildContext context,
  required String title,
  required bool isBarrierDismissible,
  Widget? content,
  String? description,
}) => showDialog<bool>(
  barrierDismissible: isBarrierDismissible,
  context: context,
  builder: (BuildContext context) => AlertDialog(
    title: Text(title),
    content: content ?? Text(description!),
    actions: <Widget>[
      TextButton(
        key: const Key('dialog_no_button'),
        style: TextButton.styleFrom(
          backgroundColor: AppColors.znnColor,
        ),
        onPressed: () {
          Navigator.pop(context, false);
        },
        child: Text(
          'No',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ),
      TextButton(
        key: const Key('dialog_yes_button'),
        style: TextButton.styleFrom(
          backgroundColor: AppColors.errorColor,
        ),
        onPressed: () {
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

/// Displays a centered card dialog styled with the redesigned theme and blurred
/// backdrop.
Future<T?> showCustomDialog<T>({
  required BuildContext context,
  required Widget content,
}) => showGeneralDialog<T>(
  context: context,
  barrierLabel: '',
  barrierDismissible: true,
  barrierColor: context.syriusTheme.modalBarrierColor,
  pageBuilder:
      (
        BuildContext context,
        Animation<double> animation,
        Animation<double> secondaryAnimation,
      ) {
        final SyriusThemeTokens tokens = context.syriusTheme;
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 7, sigmaY: 7),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: context.customDialogMaxHeight,
                maxWidth: context.customDialogMaxWidth,
              ),
              child: Theme(
                data: context.newThemeData,
                child: Container(
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: tokens.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: tokens.border),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: SingleChildScrollView(child: content),
                  ),
                ),
              ),
            ),
          ),
        );
      },
);
