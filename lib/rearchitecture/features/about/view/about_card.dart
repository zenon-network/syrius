import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:open_filex/open_filex.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/model/model.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/about/bloc/about_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/metadata.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

/// Displays detailed version, build, node, path, and host metadata.
class AboutCard extends StatelessWidget {
  /// Creates an [AboutCard].
  const AboutCard({
    @visibleForTesting this._bloc,
    @visibleForTesting this._onOpenPath,
    @visibleForTesting this._onOpenUrl,
    super.key,
  });

  final AboutBloc? _bloc;
  final Future<void> Function(String path)? _onOpenPath;
  final void Function(String url)? _onOpenUrl;

  @override
  Widget build(BuildContext context) {
    final AboutBloc? injectedBloc = _bloc;
    if (injectedBloc != null) {
      return BlocProvider<AboutBloc>.value(
        value: injectedBloc,
        child: _View(onOpenPath: _onOpenPath, onOpenUrl: _onOpenUrl),
      );
    }

    return BlocProvider<AboutBloc>(
      create: (_) => AboutBloc(zenon: zenon!)..add(const AboutRequested()),
      child: _View(onOpenPath: _onOpenPath, onOpenUrl: _onOpenUrl),
    );
  }
}

class _View extends StatelessWidget {
  const _View({required this._onOpenPath, required this._onOpenUrl});

  final Future<void> Function(String path)? _onOpenPath;
  final void Function(String url)? _onOpenUrl;

  @override
  Widget build(BuildContext context) {
    return NewCardScaffold(
      data: CardData(
        title: context.l10n.about,
        description: context.l10n.detailedInfoAboutWalletComponents,
      ),
      onRefreshPressed: () {
        context.read<AboutBloc>().add(const AboutRequested());
      },
      body: BlocBuilder<AboutBloc, AboutState>(
        builder: (BuildContext context, AboutState state) {
          return switch (state) {
            AboutInitial() || AboutLoading() => const SyriusLoadingWidget(),
            AboutFailure(:final SyriusException exception) => SyriusErrorWidget(
              exception,
            ),
            AboutPopulated(:final GeneralStats stats) => _Populated(
              stats: stats,
              onOpenPath: _onOpenPath,
              onOpenUrl: _onOpenUrl,
            ),
          };
        },
      ),
    );
  }
}

class _Populated extends StatelessWidget {
  const _Populated({
    required this._stats,
    required this._onOpenPath,
    required this._onOpenUrl,
  });

  final GeneralStats _stats;
  final Future<void> Function(String path)? _onOpenPath;
  final void Function(String url)? _onOpenUrl;

  @override
  Widget build(BuildContext context) {
    return ListView(
      shrinkWrap: true,
      children: <Widget>[
        CustomExpandablePanel(
          context.l10n.syriusWalletVersion,
          _buildTextRow(context, kWalletVersion),
        ),
        CustomExpandablePanel(
          context.l10n.zenonNodeChainIdentifier,
          _buildTextRow(
            context,
            _stats.frontierMomentum.chainIdentifier.toString(),
          ),
        ),
        CustomExpandablePanel(
          context.l10n.clientChainIdentifier,
          _buildTextRow(context, getChainIdentifier().toString()),
        ),
        CustomExpandablePanel(
          context.l10n.zenonSdkVersion,
          _buildTextRow(context, znnSdkVersion),
        ),
        CustomExpandablePanel(
          context.l10n.zenonNodeBuildVersion,
          _buildTextRow(context, _stats.processInfo.version),
        ),
        CustomExpandablePanel(
          context.l10n.zenonNodeGitCommitHash,
          _buildTextRow(context, _stats.processInfo.commit),
        ),
        CustomExpandablePanel(
          context.l10n.syriusGitOriginUrl,
          _buildLinkRow(context, gitOriginUrl),
        ),
        CustomExpandablePanel(
          context.l10n.syriusGitBranchName,
          _buildTextRow(context, gitBranchName),
        ),
        CustomExpandablePanel(
          context.l10n.syriusGitCommitHash,
          _buildTextRow(context, gitCommitHash),
        ),
        CustomExpandablePanel(
          context.l10n.syriusGitCommitMessage,
          _buildTextRow(context, gitCommitMessage),
        ),
        CustomExpandablePanel(
          context.l10n.syriusGitCommitDate,
          _buildTextRow(context, gitCommitDate),
        ),
        CustomExpandablePanel(
          context.l10n.zenonNodeKernelVersion,
          _buildTextRow(context, _stats.osInfo.kernelVersion),
        ),
        CustomExpandablePanel(
          context.l10n.zenonNodeOperatingSystem,
          _buildTextRow(context, _stats.osInfo.os),
        ),
        CustomExpandablePanel(
          context.l10n.zenonNodePlatform,
          _buildTextRow(context, _stats.osInfo.platform),
        ),
        CustomExpandablePanel(
          context.l10n.zenonNodePlatformVersion,
          _buildTextRow(context, _stats.osInfo.platformVersion),
        ),
        CustomExpandablePanel(
          context.l10n.zenonNodeNumberOfProcessors,
          _buildTextRow(context, _stats.osInfo.numCPU.toString()),
        ),
        CustomExpandablePanel(
          context.l10n.zenonMainDataPath,
          _buildOpenPathRow(context, znnDefaultPaths.main.absolute.path),
        ),
        CustomExpandablePanel(
          context.l10n.syriusCachePath,
          _buildOpenPathRow(context, znnDefaultPaths.cache.absolute.path),
        ),
        CustomExpandablePanel(
          context.l10n.syriusWalletPath,
          _buildOpenPathRow(context, znnDefaultPaths.wallet.absolute.path),
        ),
        CustomExpandablePanel(
          context.l10n.syriusWalletType,
          _buildTextRow(context, kWalletFile?.walletType ?? '-'),
        ),
        CustomExpandablePanel(
          context.l10n.clientHostname,
          _buildTextRow(context, Platform.localHostname),
        ),
        CustomExpandablePanel(
          context.l10n.clientLocalIpAddress,
          _buildTextRow(context, kLocalIpAddress ?? '-'),
        ),
        CustomExpandablePanel(
          context.l10n.clientOperatingSystem,
          _buildTextRow(context, Platform.operatingSystem),
        ),
        CustomExpandablePanel(
          context.l10n.clientOperatingSystemVersion,
          _buildTextRow(context, Platform.operatingSystemVersion),
        ),
        CustomExpandablePanel(
          context.l10n.clientNumberOfProcessors,
          _buildTextRow(context, Platform.numberOfProcessors.toString()),
        ),
      ],
    );
  }

  Widget _buildTextRow(BuildContext context, String value, {Widget? trailing}) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Tooltip(
            message: value,
            child: Text(
              value,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.subtitleColor),
            ),
          ),
        ),
        kHorizontalGap8,
        CopyToClipboardButton(value),
        ?trailing,
      ],
    );
  }

  Widget _buildLinkRow(BuildContext context, String url) {
    return _buildTextRow(
      context,
      url,
      trailing: IconButton(
        splashRadius: 16,
        onPressed: () {
          final void Function(String url)? openUrl = _onOpenUrl;
          if (openUrl != null) {
            openUrl(url);
          } else {
            unawaited(NavigationUtils.openUrl(url));
          }
        },
        icon: const Icon(Icons.link, size: 16, color: AppColors.znnColor),
      ),
    );
  }

  Widget _buildOpenPathRow(BuildContext context, String path) {
    return _buildTextRow(
      context,
      path,
      trailing: IconButton(
        splashRadius: 16,
        onPressed: () {
          final Future<void> Function(String path)? openPath = _onOpenPath;
          if (openPath != null) {
            unawaited(openPath(path));
          } else {
            unawaited(OpenFilex.open(path));
          }
        },
        icon: const Icon(
          Icons.open_in_new,
          size: 16,
          color: AppColors.znnColor,
        ),
      ),
    );
  }
}
