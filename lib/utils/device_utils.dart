import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';

class DeviceUtils {
  static Future<Map<String, dynamic>> getDeviceInfo() async {
    DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();
    if (Platform.isLinux) {
      return _readLinuxDeviceInfo(await deviceInfoPlugin.linuxInfo);
    }
    if (Platform.isWindows) {
      return _readWindowsDeviceInfo(await deviceInfoPlugin.windowsInfo);
    }
    if (Platform.isMacOS) {
      return _readMacOsDeviceInfo(await deviceInfoPlugin.macOsInfo);
    }
    return {'info': 'device not supported'};
  }

  static Map<String, dynamic> _readLinuxDeviceInfo(LinuxDeviceInfo data) {
    return <String, dynamic>{
      'name': data.name,
      'version': data.version,
      'id': data.id,
      'idLike': data.idLike,
      'versionCodename': data.versionCodename,
      'versionId': data.versionId,
      'prettyName': data.prettyName,
      'buildId': data.buildId,
      'variant': data.variant,
      'variantId': data.variantId,
      'machineId': data.machineId,
    };
  }

  static Map<String, dynamic> _readMacOsDeviceInfo(MacOsDeviceInfo data) {
    return <String, dynamic>{
      'computerName': data.computerName,
      'hostName': data.hostName,
      'arch': data.arch,
      'model': data.model,
      'kernelVersion': data.kernelVersion,
      'osRelease': data.osRelease,
      'activeCPUs': data.activeCPUs,
      'memorySize': data.memorySize,
      'cpuFrequency': data.cpuFrequency,
    };
  }

  static Map<String, dynamic> _readWindowsDeviceInfo(WindowsDeviceInfo data) {
    return <String, dynamic>{
      'numberOfCores': data.numberOfCores,
      'computerName': data.computerName,
      'systemMemoryInMegabytes': data.systemMemoryInMegabytes,
    };
  }

  static Future<Map<String, dynamic>> getPackageInfo() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    return {
      'appName': packageInfo.appName,
      'packageName': packageInfo.packageName,
      'appVersion': packageInfo.version,
      'buildNumber': packageInfo.buildNumber,
    };
  }

  static Future<Map<String, String>> getGitInfo() async {
    final head = await rootBundle.loadString('.git/HEAD');
    final branchName = head.split('/').last;
    final commitHash = await rootBundle.loadString('.git/ORIG_HEAD');
    return {'branchName': branchName, 'commitHash': commitHash};
  }
}
