import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:zenon_syrius_wallet_flutter/utils/app_colors.dart';
import 'package:zenon_syrius_wallet_flutter/utils/constants.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';

class CommunityCard extends StatelessWidget {
  const CommunityCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CardScaffold(
      title: 'Community',
      description:
          'This card displays information about Zenon community resources',
      childBuilder: () => _getWidgetBody(context),
    );
  }

  Widget _getWidgetBody(BuildContext context) {
    return ListView(
      physics: const ClampingScrollPhysics(),
      shrinkWrap: true,
      children: [
        CustomExpandablePanel(
          'Websites',
          _getWebsitesExpandableChild(context),
        ),
        CustomExpandablePanel(
          'Explorers',
          _getExplorersExpandableChild(context),
        ),
        CustomExpandablePanel(
          'Social Media',
          _getSocialMediaExpandableChild(context),
        ),
        CustomExpandablePanel(
          'Documentation',
          _getDocumentationExpandableChild(context),
        ),
      ],
    );
  }

  Widget _getWebsitesExpandableChild(BuildContext context) {
    return ListView(
      physics: const ClampingScrollPhysics(),
      shrinkWrap: true,
      children: [
        _getListViewChild(
          iconData: MaterialCommunityIcons.home,
          title: 'Zenon Network',
          url: kWebsite,
          context: context,
        ),
        _getListViewChild(
          iconData: MaterialCommunityIcons.forum,
          title: 'Zenon ORG Community Forum',
          url: kOrgCommunityForum,
          context: context,
        ),
        _getListViewChild(
          iconData: MaterialCommunityIcons.tools,
          title: 'Zenon Tools',
          url: kTools,
          context: context,
        ),
        _getListViewChild(
          iconData: MaterialCommunityIcons.web,
          title: 'Zenon ORG Community',
          url: kOrgCommunityWebsite,
          context: context,
        ),
        _getListViewChild(
          iconData: MaterialCommunityIcons.lan,
          title: 'Zenon Hub',
          url: kHubCommunityWebsite,
          context: context,
        ),
      ],
    );
  }

  Widget _getExplorersExpandableChild(BuildContext context) {
    return ListView(
      physics: const ClampingScrollPhysics(),
      shrinkWrap: true,
      children: [
        _getListViewChild(
          iconData: Icons.explore,
          title: 'Zenon Explorer',
          url: kExplorer,
          context: context,
        ),
        _getListViewChild(
          iconData: Icons.explore_off_outlined,
          title: 'Zenon Hub Explorer',
          url: kHubCommunityExplorer,
          context: context,
        )
      ],
    );
  }

  Widget _getSocialMediaExpandableChild(BuildContext context) {
    return ListView(
      physics: const ClampingScrollPhysics(),
      shrinkWrap: true,
      children: [
        _getListViewChild(
          iconData: MaterialCommunityIcons.twitter,
          title: 'Zenon Twitter',
          url: kTwitter,
          context: context,
        ),
        _getListViewChild(
          iconData: MaterialCommunityIcons.discord,
          title: 'Zenon Discord',
          url: kDiscord,
          context: context,
        ),
        _getListViewChild(
          iconData: Icons.telegram,
          title: 'Zenon Telegram',
          url: kTelegram,
          context: context,
        ),
        _getListViewChild(
          iconData: Icons.article,
          title: 'Zenon Medium',
          url: kMedium,
          context: context,
        ),
        _getListViewChild(
          iconData: MaterialCommunityIcons.github,
          title: 'Zenon Github',
          url: kGithub,
          context: context,
        ),
        _getListViewChild(
          iconData: MaterialCommunityIcons.bitcoin,
          title: 'Zenon Bitcoin Talk',
          url: kBitcoinTalk,
          context: context,
        ),
        _getListViewChild(
          iconData: MaterialCommunityIcons.reddit,
          title: 'Zenon Reddit',
          url: kReddit,
          context: context,
        ),
        _getListViewChild(
          iconData: MaterialCommunityIcons.youtube,
          title: 'Zenon Youtube',
          url: kYoutube,
          context: context,
        ),
      ],
    );
  }

  Widget _getDocumentationExpandableChild(BuildContext context) {
    return ListView(
      physics: const ClampingScrollPhysics(),
      shrinkWrap: true,
      children: [
        _getListViewChild(
          iconData: MaterialCommunityIcons.book_open_page_variant,
          title: 'Zenon Wiki',
          url: kWiki,
          context: context,
        ),
        _getListViewChild(
          iconData: MaterialCommunityIcons.book_multiple,
          title: 'ZenonORG Community Wiki',
          url: kOrgCommunityWiki,
          context: context,
        ),
        _getListViewChild(
          iconData: MaterialCommunityIcons.file_document,
          title: 'Zenon Whitepaper',
          url: kWhitepaper,
          context: context,
        ),
      ],
    );
  }

  Widget _getListViewChild({
    required IconData iconData,
    required String title,
    required String url,
    required BuildContext context,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Icon(
          iconData,
          color: AppColors.znnColor,
          size: 20.0,
        ),
        const SizedBox(
          width: 10.0,
        ),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(
          width: 10.0,
        ),
        LinkIcon(url: url),
      ],
    );
  }
}
