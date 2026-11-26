import 'dart:async';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/extensions/buildcontext_extension.dart';
import 'package:zenon_syrius_wallet_flutter/utils/app_colors.dart';

/// Allows the user to select a file either by clicking to browse or by
/// dragging and dropping a file onto the widget.
class SelectFileWidget extends StatefulWidget {
  /// Creates a [SelectFileWidget].
  const SelectFileWidget({
    required this._onPathFoundCallback,
    this._fileExtension,
    this._textStyle,
    super.key,
  });

  final void Function(String) _onPathFoundCallback;
  final String? _fileExtension;
  final TextStyle? _textStyle;

  @override
  SelectFileWidgetState createState() => SelectFileWidgetState();
}

/// State for [SelectFileWidget], exposing [resetMessageToUser] to clear the
/// displayed file path.
class SelectFileWidgetState extends State<SelectFileWidget> {
  bool _browseButtonHover = false;
  bool _dragging = false;
  String? _selectedFilePath;

  @override
  Widget build(BuildContext context) {
    final Color defaultBorderColor =
        Theme.of(context).textTheme.headlineSmall?.color ??
        Theme.of(context).colorScheme.onSurface;

    return DropTarget(
      onDragDone: (DropDoneDetails detail) {
        if (detail.files.isEmpty) {
          return;
        }
        // Do not gate on the file name here: a valid keystore may carry any
        // extension (or none), and an invalid file is rejected with a visible
        // error when it is parsed at decrypt time. The extension only narrows
        // the native file-picker dialog, it must not silently drop a dropped
        // file (see issue #136).
        final String walletFilePath = detail.files.first.path;
        setState(() {
          _selectedFilePath = walletFilePath;
        });
        widget._onPathFoundCallback(walletFilePath);
      },
      onDragEntered: (DropEventDetails detail) {
        setState(() {
          _dragging = true;
        });
      },
      onDragExited: (DropEventDetails detail) {
        setState(() {
          _dragging = false;
        });
      },
      child: GestureDetector(
        onTap: () => unawaited(_pickFile(context)),
        child: FocusableActionDetector(
          onShowHoverHighlight: (bool isHovered) {
            setState(() {
              _browseButtonHover = isHovered;
            });
          },
          child: DottedBorder(
            options: RoundedRectDottedBorderOptions(
              color: _browseButtonHover
                  ? AppColors.znnColor
                  : defaultBorderColor,
              strokeWidth: 2,
              dashPattern: const <double>[8, 5],
              radius: const Radius.circular(10),
            ),
            child: Container(
              height: 100,
              decoration: BoxDecoration(
                color: _dragging
                    ? Colors.blue.withValues(alpha: 0.4)
                    : Theme.of(context).colorScheme.primary,
                borderRadius: const BorderRadius.all(Radius.circular(10)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Expanded(
                    child: Text(
                      _selectedFilePath ??
                          context.l10n.clickToBrowseOrDragAndDropFile,
                      maxLines: 2,
                      style:
                          widget._textStyle ??
                          Theme.of(context).textTheme.headlineSmall,
                      softWrap: true,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickFile(BuildContext context) async {
    final String fileLabel = context.l10n.file;
    final String initialDirectory =
        (await getApplicationDocumentsDirectory()).path;
    final XFile? selectedFile = await openFile(
      acceptedTypeGroups: <XTypeGroup>[
        XTypeGroup(
          label: fileLabel,
          extensions: widget._fileExtension != null
              ? <String>[widget._fileExtension!]
              : null,
        ),
      ],
      initialDirectory: initialDirectory,
    );
    if (!mounted || selectedFile == null) {
      return;
    }
    setState(() {
      _selectedFilePath = selectedFile.path;
    });
    widget._onPathFoundCallback(selectedFile.path);
  }

  /// Resets the displayed file path back to the initial prompt message.
  void resetMessageToUser() => setState(() {
    _selectedFilePath = null;
  });
}
