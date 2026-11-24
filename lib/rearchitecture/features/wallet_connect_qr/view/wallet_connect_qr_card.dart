import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as path;
import 'package:pretty_qr_code/pretty_qr_code.dart';
import 'package:screen_capturer/screen_capturer.dart';
import 'package:window_manager/window_manager.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/blocs.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/model/database/notification_type.dart';
import 'package:zenon_syrius_wallet_flutter/model/database/wallet_notification.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/services/i_web3wallet_service.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';
import 'package:zxing2/qrcode.dart';

/// Card allowing the user to capture an on-screen WalletConnect QR code and
/// pair with the corresponding dApp.
class WalletConnectQrCard extends StatelessWidget {
  /// Creates a [WalletConnectQrCard].
  const WalletConnectQrCard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<WalletConnectPairBloc>(
      create: (_) =>
          WalletConnectPairBloc(web3WalletService: sl<IWeb3WalletService>()),
      child: const _View(),
    );
  }
}

class _View extends StatefulWidget {
  const _View();

  @override
  State<_View> createState() => _ViewState();
}

class _ViewState extends State<_View> {
  final ScreenCapturer _screenCapturer = ScreenCapturer.instance;
  bool _isScanning = false;

  @override
  Widget build(BuildContext context) {
    return NewCardScaffold(
      data: CardData(
        title: context.l10n.onScreenQrScanner,
        description: context.l10n.scanWalletConnectQrUsingOnScreenScanner,
      ),
      body: BlocConsumer<WalletConnectPairBloc, WalletConnectPairState>(
        listenWhen:
            (WalletConnectPairState previous, WalletConnectPairState current) =>
                current.status == WalletConnectPairStatus.failure &&
                current.error != null &&
                previous.errorCount != current.errorCount,
        listener: (BuildContext context, WalletConnectPairState state) {
          final Object? error = state.error;
          if (error != null) {
            unawaited(
              NotificationUtils.sendNotificationError(
                error,
                context.l10n.pairingFailed,
              ),
            );
          }
        },
        builder: (BuildContext context, WalletConnectPairState state) {
          final bool isBusy =
              _isScanning || state.status == WalletConnectPairStatus.loading;
          return _buildCardBody(context: context, isBusy: isBusy);
        },
      ),
    );
  }

  Widget _buildCardBody({required BuildContext context, required bool isBusy}) {
    return Padding(
      padding: const EdgeInsets.all(15),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          _buildQrPreview(context),
          _buildScanButton(context: context, isBusy: isBusy),
        ],
      ),
    );
  }

  Widget _buildQrPreview(BuildContext context) {
    return Container(
      height: 130,
      width: 130,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(15),
      ),
      child: PrettyQrView.data(
        data: context.l10n.scanWalletConnectQrFromDapp,
        decoration: const PrettyQrDecoration(
          shape: PrettyQrSmoothSymbol(
            roundFactor: 0,
            color: AppColors.znnColor,
          ),
          image: PrettyQrDecorationImage(
            scale: 0.3,
            padding: EdgeInsets.only(top: 10, bottom: 10),
            image: AssetImage('assets/images/qr_code_child_image_znn_cut.png'),
          ),
        ),
        errorCorrectLevel: QrErrorCorrectLevel.H,
      ),
    );
  }

  Widget _buildScanButton({
    required BuildContext context,
    required bool isBusy,
  }) {
    if (isBusy) {
      return const SizedBox(
        height: 40,
        child: Center(
          child: SyriusLoadingWidget(size: 24, strokeWidth: 2, padding: 2),
        ),
      );
    }

    return MyOutlinedButton(
      text: context.l10n.scanQr,
      onPressed: () {
        unawaited(_onScanPressed());
      },
      minimumSize: kLoadingButtonMinSize,
    );
  }

  Future<void> _onScanPressed() async {
    if (_isScanning) {
      return;
    }

    setState(() {
      _isScanning = true;
    });

    try {
      final bool hasPermission = await _checkPermissionForMacOS();
      if (!hasPermission || !mounted) {
        return;
      }

      await _captureAndDecodeQr();
    } finally {
      if (mounted) {
        setState(() {
          _isScanning = false;
        });
      }
    }
  }

  Future<void> _captureAndDecodeQr() async {
    File? imageFile;
    bool windowMinimized = false;
    bool windowRestored = false;

    Future<void> ensureWindowVisible() async {
      if (!windowMinimized || windowRestored) {
        return;
      }
      windowRestored = true;
      try {
        await windowManager.show();
      } on Object {
        // Best-effort window restore.
      }
    }

    try {
      await windowManager.minimize();
      windowMinimized = true;

      final Directory walletConnectDirectory = Directory(
        path.join(znnDefaultPaths.cache.path, walletConnectDirName),
      );

      if (!walletConnectDirectory.existsSync()) {
        walletConnectDirectory.createSync(recursive: true);
      }

      final String screenshotName =
          'screenshot-${DateTime.now().millisecondsSinceEpoch}';

      imageFile = await File(
        '${walletConnectDirectory.absolute.path}${path.separator}'
        '$screenshotName.png',
      ).create();

      final CapturedData? capturedData = await _screenCapturer.capture(
        imagePath: imageFile.absolute.path,
      );

      await ensureWindowVisible();
      if (!mounted) {
        return;
      }

      if (capturedData == null) {
        await sl<NotificationsBloc>().addErrorNotification(
          context.l10n.userCanceledQrScanning,
          context.l10n.userQrScanCanceled,
        );
        return;
      }

      final img.Image? image = img.decodePng(imageFile.readAsBytesSync());
      if (image == null) {
        await _notifyInvalidQr();
        return;
      }

      final Int32List pixels = Int32List(image.width * image.height);
      int offset = 0;
      for (final img.Pixel pixel in image) {
        pixels[offset++] =
            (pixel.r.toInt() << 16) | (pixel.g.toInt() << 8) | pixel.b.toInt();
      }
      final LuminanceSource source = RGBLuminanceSource(
        image.width,
        image.height,
        pixels,
      );
      final BinaryBitmap bitmap = BinaryBitmap(HybridBinarizer(source));
      final Result result = QRCodeReader().decode(bitmap);

      final bool hasRawBytes = result.rawBytes?.isNotEmpty ?? false;
      if (!hasRawBytes) {
        await sl<NotificationsBloc>().addNotification(
          WalletNotification(
            title: context.l10n.qrCodeScanFailed,
            timestamp: DateTime.now().millisecondsSinceEpoch,
            details: context.l10n.pleaseScanValidWalletConnectQr,
            type: NotificationType.error,
          ),
        );
        return;
      }

      final String? wcUri = extractWalletConnectUri(
        result.text,
        isWindows: Platform.isWindows,
      );
      if (wcUri == null) {
        await _notifyInvalidQr();
        return;
      }

      context.read<WalletConnectPairBloc>().add(
        WalletConnectPairRequested(
          rawUri: wcUri,
          isWindows: Platform.isWindows,
        ),
      );
    } on Object catch (e) {
      await ensureWindowVisible();
      if (mounted) {
        await sl<NotificationsBloc>().addErrorNotification(
          e,
          context.l10n.invalidQrCodeException,
        );
      }
    } finally {
      await ensureWindowVisible();
      if (imageFile != null && imageFile.existsSync()) {
        try {
          imageFile.deleteSync();
        } on Object {
          // Best-effort cleanup of temporary screenshot file.
        }
      }
    }
  }

  Future<void> _notifyInvalidQr() async {
    await sl<NotificationsBloc>().addNotification(
      WalletNotification(
        title: context.l10n.invalidQrCode,
        timestamp: DateTime.now().millisecondsSinceEpoch,
        details: context.l10n.pleaseScanValidWalletConnectQr,
        type: NotificationType.error,
      ),
    );
  }

  Future<bool> _checkPermissionForMacOS() async {
    if (!Platform.isMacOS) {
      return true;
    }

    final bool isAccessAllowed = await _screenCapturer.isAccessAllowed();
    if (!isAccessAllowed) {
      await _screenCapturer.requestAccess();
      if (mounted) {
        await sl<NotificationsBloc>().addNotification(
          WalletNotification(
            title: context.l10n.permissionRequired,
            timestamp: DateTime.now().millisecondsSinceEpoch,
            details: context.l10n.screenRecordingPermissionRequired,
            type: NotificationType.generatingPlasma,
          ),
        );
      }
      return false;
    }
    return true;
  }
}
