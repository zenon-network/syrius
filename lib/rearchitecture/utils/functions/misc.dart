import 'dart:io';

/// Tells us if the app is running on a desktop platform
bool isDesktopPlatform() =>
    Platform.isMacOS || Platform.isLinux || Platform.isWindows;
