import 'dart:async';
import 'dart:io';

import 'package:ai_barcode_scanner/ai_barcode_scanner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:logging/logging.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/services/i_web3wallet_service.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';

/// Returns the first valid WalletConnect v2 URI found in [barcodeValues], or
/// `null` if none of the scanned payloads contain a valid URI.
@visibleForTesting
String? extractWalletConnectUriFromBarcodes(
  Iterable<String?> barcodeValues, {
  bool isWindows = false,
}) {
  for (final String? rawValue in barcodeValues) {
    if (rawValue == null) {
      continue;
    }
    final String? extracted = extractWalletConnectUri(
      rawValue,
      isWindows: isWindows,
    );
    if (extracted != null) {
      return extracted;
    }
  }
  return null;
}

/// Card allowing macOS users to scan a WalletConnect QR code via the built-in
/// camera and pair with the corresponding dApp.
class WalletConnectCameraCard extends StatelessWidget {
  /// Creates a [WalletConnectCameraCard].
  const WalletConnectCameraCard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<WalletConnectPairBloc>(
      create: (_) =>
          WalletConnectPairBloc(web3WalletService: sl<IWeb3WalletService>()),
      child: const _View(),
    );
  }
}

class _View extends StatelessWidget {
  const _View();

  @override
  Widget build(BuildContext context) {
    return NewCardScaffold(
      data: CardData(
        title: context.l10n.cameraQrScanner,
        description: context.l10n.scanWalletConnectQrUsingCamera,
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
          final bool isLoading =
              state.status == WalletConnectPairStatus.loading;
          return _buildCardBody(context: context, isLoading: isLoading);
        },
      ),
    );
  }

  Widget _buildCardBody({
    required BuildContext context,
    required bool isLoading,
  }) {
    return Padding(
      padding: const EdgeInsets.all(15),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          const CircleAvatar(
            radius: 60,
            backgroundColor: Colors.white12,
            child: Icon(
              Icons.camera_alt_outlined,
              color: AppColors.znnColor,
              size: 60,
            ),
          ),
          if (Platform.isMacOS)
            _buildScanButton(context: context, isLoading: isLoading)
          else
            Text(
              context.l10n.onlyMacOsSupported,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
        ],
      ),
    );
  }

  Widget _buildScanButton({
    required BuildContext context,
    required bool isLoading,
  }) {
    if (isLoading) {
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
        unawaited(_openScanner(context));
      },
      minimumSize: kLoadingButtonMinSize,
    );
  }

  Future<void> _openScanner(BuildContext context) async {
    final String? scannedUri = await Navigator.of(context).push<String>(
      MaterialPageRoute<String>(builder: (_) => const _CameraScannerPage()),
    );
    if (scannedUri == null || !context.mounted) {
      return;
    }

    context.read<WalletConnectPairBloc>().add(
      WalletConnectPairRequested(
        rawUri: scannedUri,
        isWindows: Platform.isWindows,
      ),
    );
  }
}

class _CameraScannerPage extends StatefulWidget {
  const _CameraScannerPage();

  @override
  State<_CameraScannerPage> createState() => _CameraScannerPageState();
}

class _CameraScannerPageState extends State<_CameraScannerPage> {
  final Logger _logger = Logger('WalletConnectCameraCard');
  final AiBarcodeScannerController _controller = AiBarcodeScannerController(
    facing: CameraFacing.front,
  );
  Timer? _errorPopTimer;
  bool _hasDetected = false;

  @override
  void dispose() {
    _errorPopTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  String? _extractFromCapture(BarcodeCapture capture) {
    return extractWalletConnectUriFromBarcodes(
      capture.barcodes.map(
        (Barcode barcode) => barcode.rawValue ?? barcode.displayValue,
      ),
      isWindows: Platform.isWindows,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AiBarcodeScanner(
      controller: _controller,
      validator: (BarcodeCapture capture) =>
          _extractFromCapture(capture) != null,
      onDetect: (BarcodeCapture capture) {
        if (_hasDetected) {
          return;
        }
        final String? wcUri = _extractFromCapture(capture);
        if (wcUri == null) {
          return;
        }
        _hasDetected = true;
        _logger.info('Detected valid WalletConnect QR code via camera');
        if (mounted && Navigator.of(context).canPop()) {
          Navigator.of(context).pop(wcUri);
        }
      },
      onDispose: () {
        _logger.fine('Camera barcode scanner disposed');
      },
      errorBuilder: (BuildContext errorContext, MobileScannerException error) {
        _errorPopTimer ??= Timer(const Duration(seconds: 10), () {
          if (mounted && Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
        });
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                '${error.errorCode}',
                style: Theme.of(errorContext).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              const Icon(
                MaterialCommunityIcons.camera_off,
                size: 32,
                color: AppColors.errorColor,
              ),
            ],
          ),
        );
      },
    );
  }
}
