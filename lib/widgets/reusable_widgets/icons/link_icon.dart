import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';

class LinkIcon extends RawMaterialButton {
  LinkIcon({
    required String url,
    Key? key})
      : super(
          key: key,
          constraints: const BoxConstraints(
            minWidth: 40.0,
            minHeight: 40.0,
          ),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: const CircleBorder(),
          onPressed: () => NavigationUtils.openUrl(url),
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
        );
}
