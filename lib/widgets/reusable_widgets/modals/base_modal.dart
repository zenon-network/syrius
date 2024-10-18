import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/utils/app_colors.dart';

class BaseModal extends StatelessWidget {

  const BaseModal({
    required this.title, required this.child, super.key,
    this.subtitle = '',
  });
  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      child: SingleChildScrollView(
        child: Material(
          child: AnimatedSize(
            duration: const Duration(milliseconds: 100),
            curve: Curves.easeInOut,
            child: Container(
              width: 570,
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(25),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                fontSize: 18,
                              ),
                            ),
                            Visibility(
                              visible: subtitle.isNotEmpty,
                              child: const SizedBox(
                                height: 3,
                              ),
                            ),
                            Visibility(
                              visible: subtitle.isNotEmpty,
                              child: Text(subtitle),
                            ),
                          ],
                        ),
                        MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: GestureDetector(
                            onTap: () => Navigator.of(context).pop(),
                            child: const Icon(
                              Icons.clear,
                              color: AppColors.lightSecondary,
                              size: 22,
                            ),
                          ),
                        ),
                      ],
                    ),
                    child,
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
