import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';

class LinkIcon extends RawMaterialButton {
  LinkIcon({
    required String url,
    super.key,})
      : super(
          constraints: const BoxConstraints(
            minWidth: 40,
            minHeight: 40,
          ),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: const CircleBorder(),
          onPressed: () => NavigationUtils.openUrl(url),
          child: Container(
            height: 25,
            width: 25,
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white12,
            ),
            child: const Icon(
              SimpleLineIcons.link,
              size: 10,
              color: AppColors.znnColor,
            ),
          ),
        );
}
