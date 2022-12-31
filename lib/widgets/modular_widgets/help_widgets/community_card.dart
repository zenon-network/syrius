import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:zenon_syrius_wallet_flutter/utils/app_colors.dart';
import 'package:zenon_syrius_wallet_flutter/utils/constants.dart';
import 'package:zenon_syrius_wallet_flutter/utils/navigation_utils.dart';
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
      shrinkWrap: true,
      children: [
        CustomExpandablePanel(
          'Websites',
          _getWebsitesExpandableChild(context),
        ),
        CustomExpandablePanel(
          'Social Media',
          _getSocialMediaExpandableChild(context),
        ),
      ],
    );
  }

  Widget _getWebsitesExpandableChild(BuildContext context) {
    return ListView(
      shrinkWrap: true,
      children: [
        _getListViewChild(
          iconData: MaterialCommunityIcons.web,
          title: 'Zenon Network',
          url: kWebsite,
          context: context,
        ),
        _getListViewChild(
          iconData: Icons.explore,
          title: 'Zenon Explorer',
          url: kExplorer,
          context: context,
        ),
        _getListViewChild(
          iconData: MaterialCommunityIcons.cube,
          title: 'Zenonscraper',
          url: kScraper,
          context: context,
        ),
        _getListViewChild(
          iconData: MaterialCommunityIcons.book_multiple,
          title: 'Zenon Wiki',
          url: kWiki,
          context: context,
        ),
        _getListViewChild(
          iconData: MaterialCommunityIcons.book,
          title: 'Zenon Community Wiki',
          url: kCommunityWiki,
          context: context,
        ),
        _getListViewChild(
          iconData: MaterialCommunityIcons.tools,
          title: 'Zenon Tools',
          url: kTools,
          context: context,
        ),
        _getListViewChild(
          iconData: MaterialCommunityIcons.human_greeting,
          title: 'Zenon Community',
          url: kCommunityWebsite,
          context: context,
        ),
        _getListViewChild(
          iconData: MaterialCommunityIcons.web_box,
          title: 'ZenonORG Community',
          url: kOrgCommunityWebsite,
          context: context,
        ),
      ],
    );
  }

  Widget _getSocialMediaExpandableChild(BuildContext context) {
    return ListView(
      shrinkWrap: true,
      children: [
        _getListViewChild(
          iconData: SimpleLineIcons.social_twitter,
          title: 'Zenon Twitter',
          url: kTwitter,
          context: context,
        ),
        _getListViewChild(
          iconData: Icons.article,
          title: 'Zenon Medium',
          url: kMedium,
          context: context,
        ),
        _getListViewChild(
          iconData: Icons.telegram,
          title: 'Zenon Telegram',
          url: kTelegram,
          context: context,
        ),
        _getListViewChild(
          iconData: SimpleLineIcons.social_github,
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
          iconData: MaterialCommunityIcons.discord,
          title: 'Zenon Discord',
          url: kDiscord,
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
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.subtitle1,
          ),
        ),
        const SizedBox(
          width: 10.0,
        ),
        RawMaterialButton(
          constraints: const BoxConstraints(
            minWidth: 40.0,
            minHeight: 40.0,
          ),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: const CircleBorder(),
          onPressed: () => NavigationUtils.launchUrl(url, context),
          child: Container(
            height: 25.0,
            width: 25.0,
            padding: const EdgeInsets.all(4.0),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white12,
            ),
            child: const Icon(
              SimpleLineIcons.link,
              size: 10.0,
              color: AppColors.znnColor,
            ),
          ),
        ),
      ],
    );
  }
}
