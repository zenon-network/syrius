import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/app_colors.dart';
import 'package:zenon_syrius_wallet_flutter/utils/constants.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';

/// Displays categorized links to Zenon Network community resources.
class CommunityCard extends StatelessWidget {
  /// Creates a [CommunityCard].
  const CommunityCard({super.key});

  @override
  Widget build(BuildContext context) {
    return NewCardScaffold(
      data: CardData(
        title: context.l10n.community,
        description: context.l10n.displaysZenonCommunityResources,
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    return ListView(
      physics: const ClampingScrollPhysics(),
      shrinkWrap: true,
      children: <Widget>[
        CustomExpandablePanel(
          context.l10n.websites,
          _buildWebsitesSection(context),
        ),
        CustomExpandablePanel(
          context.l10n.explorers,
          _buildExplorersSection(context),
        ),
        CustomExpandablePanel(
          context.l10n.socialMedia,
          _buildSocialMediaSection(context),
        ),
        CustomExpandablePanel(
          context.l10n.documentation,
          _buildDocumentationSection(context),
        ),
      ],
    );
  }

  Widget _buildWebsitesSection(BuildContext context) {
    return ListView(
      physics: const ClampingScrollPhysics(),
      shrinkWrap: true,
      children: <Widget>[
        _buildResourceRow(
          context: context,
          iconData: MaterialCommunityIcons.home,
          title: context.l10n.zenonNetwork,
          url: kWebsite,
        ),
        _buildResourceRow(
          context: context,
          iconData: MaterialCommunityIcons.forum,
          title: context.l10n.zenonOrgCommunityForum,
          url: kOrgCommunityForum,
        ),
        _buildResourceRow(
          context: context,
          iconData: MaterialCommunityIcons.tools,
          title: context.l10n.zenonTools,
          url: kTools,
        ),
        _buildResourceRow(
          context: context,
          iconData: MaterialCommunityIcons.web,
          title: context.l10n.zenonOrgCommunity,
          url: kOrgCommunityWebsite,
        ),
        _buildResourceRow(
          context: context,
          iconData: MaterialCommunityIcons.lan,
          title: context.l10n.zenonHub,
          url: kHubCommunityWebsite,
        ),
      ],
    );
  }

  Widget _buildExplorersSection(BuildContext context) {
    return ListView(
      physics: const ClampingScrollPhysics(),
      shrinkWrap: true,
      children: <Widget>[
        _buildResourceRow(
          context: context,
          iconData: Icons.explore,
          title: context.l10n.zenonExplorer,
          url: kExplorer,
        ),
        _buildResourceRow(
          context: context,
          iconData: Icons.explore_off_outlined,
          title: context.l10n.zenonHubExplorer,
          url: kHubCommunityExplorer,
        ),
      ],
    );
  }

  Widget _buildSocialMediaSection(BuildContext context) {
    return ListView(
      physics: const ClampingScrollPhysics(),
      shrinkWrap: true,
      children: <Widget>[
        _buildResourceRow(
          context: context,
          iconData: MaterialCommunityIcons.twitter,
          title: context.l10n.zenonTwitter,
          url: kTwitter,
        ),
        _buildResourceRow(
          context: context,
          iconData: MaterialCommunityIcons.discord,
          title: context.l10n.zenonDiscord,
          url: kDiscord,
        ),
        _buildResourceRow(
          context: context,
          iconData: Icons.telegram,
          title: context.l10n.zenonTelegram,
          url: kTelegram,
        ),
        _buildResourceRow(
          context: context,
          iconData: Icons.article,
          title: context.l10n.zenonMedium,
          url: kMedium,
        ),
        _buildResourceRow(
          context: context,
          iconData: MaterialCommunityIcons.github,
          title: context.l10n.zenonGithub,
          url: kGithub,
        ),
        _buildResourceRow(
          context: context,
          iconData: MaterialCommunityIcons.bitcoin,
          title: context.l10n.zenonBitcoinTalk,
          url: kBitcoinTalk,
        ),
        _buildResourceRow(
          context: context,
          iconData: MaterialCommunityIcons.reddit,
          title: context.l10n.zenonReddit,
          url: kReddit,
        ),
        _buildResourceRow(
          context: context,
          iconData: MaterialCommunityIcons.youtube,
          title: context.l10n.zenonYoutube,
          url: kYoutube,
        ),
      ],
    );
  }

  Widget _buildDocumentationSection(BuildContext context) {
    return ListView(
      physics: const ClampingScrollPhysics(),
      shrinkWrap: true,
      children: <Widget>[
        _buildResourceRow(
          context: context,
          iconData: MaterialCommunityIcons.book_open_page_variant,
          title: context.l10n.zenonWiki,
          url: kWiki,
        ),
        _buildResourceRow(
          context: context,
          iconData: MaterialCommunityIcons.book_multiple,
          title: context.l10n.zenonOrgCommunityWiki,
          url: kOrgCommunityWiki,
        ),
        _buildResourceRow(
          context: context,
          iconData: MaterialCommunityIcons.file_document,
          title: context.l10n.zenonWhitepaper,
          url: kWhitepaper,
        ),
      ],
    );
  }

  Widget _buildResourceRow({
    required BuildContext context,
    required IconData iconData,
    required String title,
    required String url,
  }) {
    return Row(
      children: <Widget>[
        Icon(iconData, color: AppColors.znnColor, size: 20),
        kHorizontalGap8,
        Flexible(
          child: Text(title, style: Theme.of(context).textTheme.titleMedium),
        ),
        kHorizontalGap8,
        LinkIcon(url: url),
      ],
    );
  }
}
