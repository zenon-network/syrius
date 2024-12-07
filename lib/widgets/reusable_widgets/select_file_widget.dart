import 'package:desktop_drop/desktop_drop.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:zenon_syrius_wallet_flutter/utils/app_colors.dart';

const String _kInitialMessage = 'Click to browse or drag and drop a file';

class SelectFileWidget extends StatefulWidget {

  const SelectFileWidget({
    required this.onPathFoundCallback,
    this.fileExtension,
    this.textStyle,
    super.key,
  });
  final void Function(String) onPathFoundCallback;
  final String? fileExtension;
  final TextStyle? textStyle;

  @override
  SelectFileWidgetState createState() => SelectFileWidgetState();
}

class SelectFileWidgetState extends State<SelectFileWidget> {
  bool _browseButtonHover = false;
  bool _dragging = false;

  String _messageToUser = _kInitialMessage;

  @override
  Widget build(BuildContext context) {
    return DropTarget(
      onDragDone: (DropDoneDetails detail) {
        final String walletFilePath = detail.files.first.path;
        if (walletFilePath.contains(widget.fileExtension ?? '')) {
          setState(() {
            widget.onPathFoundCallback(walletFilePath);
            _messageToUser = walletFilePath;
          });
        }
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
        onTap: () async {
          String? initialDirectory;
          initialDirectory = (await getApplicationDocumentsDirectory()).path;
          final XFile? selectedFile = await openFile(
            acceptedTypeGroups: <XTypeGroup>[
              XTypeGroup(
                label: 'file',
                extensions: widget.fileExtension != null
                    ? <String>[
                        widget.fileExtension!,
                      ]
                    : null,
              ),
            ],
            initialDirectory: initialDirectory,
          );
          if (selectedFile != null) {
            setState(() {
              widget.onPathFoundCallback(selectedFile.path);
              _messageToUser = selectedFile.path;
            });
          }
        },
        child: FocusableActionDetector(
          onShowHoverHighlight: (bool x) {
            if (x) {
              setState(() {
                _browseButtonHover = true;
              });
            } else {
              setState(() {
                _browseButtonHover = false;
              });
            }
          },
          child: DottedBorder(
            borderType: BorderType.RRect,
            color: _browseButtonHover
                ? AppColors.znnColor
                : Theme.of(context).textTheme.headlineSmall!.color!,
            strokeWidth: 2,
            dashPattern: const <double>[8, 5],
            radius: const Radius.circular(10),
            child: Container(
              height: 100,
              decoration: BoxDecoration(
                color: _dragging
                    ? Colors.blue.withOpacity(0.4)
                    : Theme.of(context).colorScheme.primary,
                borderRadius: const BorderRadius.all(
                  Radius.circular(10),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Expanded(
                    child: Text(
                      _messageToUser,
                      maxLines: 2,
                      style: widget.textStyle ??
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

  void resetMessageToUser() => setState(() {
        _messageToUser = _kInitialMessage;
      });
}
