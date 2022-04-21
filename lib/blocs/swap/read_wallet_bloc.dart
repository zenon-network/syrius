import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:zenon_syrius_wallet_flutter/blocs/base_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/utils/constants.dart';
import 'package:zenon_syrius_wallet_flutter/utils/file_utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';
import 'package:znn_swap_utility/znn_swap_utility.dart' as znn_swap;

class ReadWalletBloc extends BaseBloc<List<znn_swap.SwapFileEntry>?> {
  Future<void> readWallet(String walletDatPath, String walletPass) async {
    try {
      addEvent(null);
      List<znn_swap.SwapFileEntry> swapFileEntries =
          await znn_swap.readSwapFile(
        await _getSwpFilePath(walletDatPath, walletPass),
      );
      await swapFileEntries[0].canDecryptWithAsync(walletPass);
      addEvent(swapFileEntries);
    } catch (e) {
      addError(e);
    }
  }

  Future<String> _getSwpFilePath(
      String walletDatPath, String walletPass) async {
    String swapWalletDirectoryPath = path.join(
      znnDefaultDirectory.path,
      kSwapWalletTempDirectory,
    );
    if (await Directory(swapWalletDirectoryPath).exists()) {
      await FileUtils.deleteDirectory(swapWalletDirectoryPath);
    }
    String walletSwpFilePath = path.join(
      swapWalletDirectoryPath,
      kNameWalletFile,
    );
    String walletSwapFilePathWithExtension = path.setExtension(
      walletSwpFilePath,
      '.swp',
    );
    if (!(await File(walletSwapFilePathWithExtension).exists())) {
      await _makeDatFileCopy(walletDatPath, swapWalletDirectoryPath);
      String response =
          await znn_swap.exportSwapFile(swapWalletDirectoryPath, walletPass);
      if (response.isNotEmpty) {
        throw response;
      }
    }
    return walletSwapFilePathWithExtension;
  }

  Future<void> _makeDatFileCopy(
    String walletDatPath,
    String swapWalletDirectoryPath,
  ) async {
    String walletDatCopyName = kNameWalletFile;
    String walletDatCopyPath = path.join(
      swapWalletDirectoryPath,
      walletDatCopyName,
    );
    String walletDatPathWithExtension = path.setExtension(
      walletDatCopyPath,
      '.dat',
    );
    if (!(await File(walletDatPathWithExtension).exists())) {
      await File(walletDatPathWithExtension).create(recursive: true);
      await File(walletDatPath).copy(walletDatPathWithExtension);
    }
  }
}
