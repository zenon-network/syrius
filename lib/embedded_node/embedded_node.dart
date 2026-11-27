import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';
import 'dart:ui';

import 'package:ffi/ffi.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as path;
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

/// Exception thrown when the native `libznn` shared library cannot be found.
ZnnSdkException invalidZnnLibPathException =
    ZnnSdkException('Library libznn could not be found');

typedef _StopNodeFunc = Pointer<Utf8> Function();
_StopNodeFunc? _stopNodeFunction;

typedef _RunNodeFunc = Pointer<Utf8> Function();
_RunNodeFunc? _runNodeFunction;

/// Manages loading, running, and stopping the embedded Zenon node library.
class EmbeddedNode {
  /// Locates and loads the native `libznn` dynamic library and its symbols.
  static void initializeNodeLib() {
    final String insideSdk = path.join(
      'syrius',
      'lib',
      'embedded_node',
      'blobs',
    );
    final List<String> currentPathListParts =
        path.split(Directory.current.path)..removeLast();
    final List<String> executablePathListParts =
        path.split(Platform.resolvedExecutable)..removeLast();
    final List<String> possiblePaths = <String>[
      Directory.current.path,
      path.join(
        Directory.current.path,
        'lib',
        'embedded_node',
        'blobs',
      ),
      path.joinAll(executablePathListParts),
    ];
    executablePathListParts.removeLast();
    possiblePaths
      ..add(path.join(path.joinAll(executablePathListParts), 'Resources'))
      ..add(path.join(path.joinAll(currentPathListParts), insideSdk));

    String libraryPath = '';
    bool found = false;

    for (final String currentPath in possiblePaths) {
      libraryPath = path.join(currentPath, 'libznn.so');

      if (Platform.isMacOS) {
        libraryPath = path.join(currentPath, 'libznn.dylib');
      }
      if (Platform.isWindows) {
        libraryPath = path.join(currentPath, 'libznn.dll');
      }

      final File libFile = File(libraryPath);

      if (libFile.existsSync()) {
        found = true;
        break;
      }
    }

    Logger('EmbeddedNode')
        .log(Level.INFO, 'Loading libznn from path $libraryPath');

    if (!found) {
      Logger('EmbeddedNode').log(Level.SEVERE, 'Could not load libznn');
      throw invalidZnnLibPathException;
    }

    // Open the dynamic library
    final DynamicLibrary dylib = DynamicLibrary.open(libraryPath);

    final Pointer<NativeFunction<_StopNodeFunc>> stopNodeFunctionPointer =
        dylib.lookup<NativeFunction<_StopNodeFunc>>('StopNode');
    _stopNodeFunction =
        stopNodeFunctionPointer.asFunction<Pointer<Utf8> Function()>();

    final Pointer<NativeFunction<_RunNodeFunc>> runNodeFunctionPointer =
        dylib.lookup<NativeFunction<_RunNodeFunc>>('RunNode');
    _runNodeFunction =
        runNodeFunctionPointer.asFunction<Pointer<Utf8> Function()>();
  }

  /// Starts the embedded node inside an isolate and awaits a stop signal.
  static Future<void> runNode(List<String> args) async {
    final ReceivePort commandsPort = ReceivePort();
    final SendPort sendPort = commandsPort.sendPort;

    IsolateNameServer.registerPortWithName(sendPort, 'embeddedIsolate');

    if (_runNodeFunction == null) {
      initializeNodeLib();
    }
    _runNodeFunction!();

    final Completer<void> embeddedIsolateCompleter = Completer<void>();
    commandsPort.listen((dynamic event) {
      _stopNodeFunction!();
      IsolateNameServer.removePortNameMapping('embeddedIsolate');
      commandsPort.close();
      embeddedIsolateCompleter.complete();
    });
    await embeddedIsolateCompleter.future;
  }

  /// Invokes the native stop function directly in the current isolate.
  static void stopNodeIsolate() {
    if (_stopNodeFunction == null) {
      initializeNodeLib();
    }
    _stopNodeFunction!();
  }

  /// Signals the running embedded node isolate to stop.
  ///
  /// Returns `true` if a registered isolate port was found and signaled.
  static bool stopNode() {
    final SendPort? embeddedIsolate =
        IsolateNameServer.lookupPortByName('embeddedIsolate');
    if (embeddedIsolate != null) {
      embeddedIsolate.send('stop');
      return true;
    }
    return false;
  }
}
