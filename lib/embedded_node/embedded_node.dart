import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';
import 'dart:ui';

import 'package:ffi/ffi.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as path;
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

ZnnSdkException invalidZnnLibPathException =
    ZnnSdkException('Library libznn could not be found');

typedef _StopNodeFunc = Pointer<Utf8> Function();
_StopNodeFunc? _stopNodeFunction;

typedef _RunNodeFunc = Pointer<Utf8> Function();
_RunNodeFunc? _runNodeFunction;

class EmbeddedNode {
  static void initializeNodeLib() {
    final String insideSdk = path.join('syrius', 'lib', 'embedded_node', 'blobs');
    final List<String> currentPathListParts = path.split(Directory.current.path);
    currentPathListParts.removeLast();
    final List<String> executablePathListParts = path.split(Platform.resolvedExecutable);
    executablePathListParts.removeLast();
    final List<String> possiblePaths = List<String>.empty(growable: true);
    possiblePaths.add(Directory.current.path);
    possiblePaths.add(
      path.join(
        Directory.current.path,
        'lib',
        'embedded_node',
        'blobs',
      ),
    );
    possiblePaths.add(path.joinAll(executablePathListParts));
    executablePathListParts.removeLast();
    possiblePaths
        .add(path.join(path.joinAll(executablePathListParts), 'Resources'));
    possiblePaths.add(path.join(path.joinAll(currentPathListParts), insideSdk));

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
    _stopNodeFunction = stopNodeFunctionPointer.asFunction<Pointer<Utf8> Function()>();

    final Pointer<NativeFunction<_RunNodeFunc>> runNodeFunctionPointer =
        dylib.lookup<NativeFunction<_RunNodeFunc>>('RunNode');
    _runNodeFunction = runNodeFunctionPointer.asFunction<Pointer<Utf8> Function()>();
  }

  static Future<void> runNode(List<String> args) async {
    final ReceivePort commandsPort = ReceivePort();
    final SendPort sendPort = commandsPort.sendPort;

    IsolateNameServer.registerPortWithName(sendPort, 'embeddedIsolate');

    if (_runNodeFunction == null) {
      initializeNodeLib();
    }
    _runNodeFunction!();

    final Completer embeddedIsolateCompleter = Completer();
    commandsPort.listen((event) {
      _stopNodeFunction!();
      IsolateNameServer.removePortNameMapping('embeddedIsolate');
      commandsPort.close();
      embeddedIsolateCompleter.complete();
    });
    await embeddedIsolateCompleter.future;
  }

  static void stopNodeIsolate() {
    if (_stopNodeFunction == null) {
      initializeNodeLib();
    }
    _stopNodeFunction!();
  }

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
