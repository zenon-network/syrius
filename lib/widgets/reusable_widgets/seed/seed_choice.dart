import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:zenon_syrius_wallet_flutter/utils/app_colors.dart';

class SeedChoice extends StatefulWidget {

  const SeedChoice({
    required this.onSeed24Selected,
    required this.onSeed12Selected,
    required this.isSeed12Selected,
    super.key,
  });
  final VoidCallback onSeed24Selected;
  final VoidCallback onSeed12Selected;
  final bool isSeed12Selected;

  @override
  State<SeedChoice> createState() => _SeedChoiceState();
}

class _SeedChoiceState extends State<SeedChoice> {
  Color _seed12Color = AppColors.unselectedSeedChoiceColor;
  Color _seed24Color = AppColors.selectedSeedChoiceColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 8,
        horizontal: 20,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          InkWell(
            onTap: () {
              setState(() {
                _seed24Color = AppColors.selectedSeedChoiceColor;
                widget.onSeed24Selected();
              });
            },
            child: FocusableActionDetector(
              onShowHoverHighlight: (x) {
                if (x) {
                  setState(() {
                    _seed24Color = AppColors.znnColor;
                  });
                } else {
                  setState(() {
                    _seed24Color = AppColors.unselectedSeedChoiceColor;
                  });
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 5,
                  horizontal: 15,
                ),
                margin: const EdgeInsets.symmetric(
                  horizontal: 5,
                ),
                decoration: BoxDecoration(
                  color: widget.isSeed12Selected
                      ? Colors.transparent
                      : AppColors.znnColor,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: SvgPicture.asset(
                  'assets/svg/ic_seed_24.svg',
                  colorFilter: ColorFilter.mode(
                      widget.isSeed12Selected
                          ? _seed24Color
                          : AppColors.selectedSeedChoiceColor,
                      BlendMode.srcIn,),
                ),
              ),
            ),
          ),
          InkWell(
            onTap: () {
              setState(() {
                _seed24Color = AppColors.unselectedSeedChoiceColor;
                widget.onSeed12Selected();
              });
            },
            child: FocusableActionDetector(
              onShowHoverHighlight: (x) {
                if (x) {
                  setState(() {
                    _seed12Color = AppColors.znnColor;
                  });
                } else {
                  setState(() {
                    _seed12Color = AppColors.unselectedSeedChoiceColor;
                  });
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 5,
                  horizontal: 15,
                ),
                margin: const EdgeInsets.symmetric(
                  horizontal: 5,
                ),
                decoration: BoxDecoration(
                  color: widget.isSeed12Selected
                      ? AppColors.znnColor
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: SvgPicture.asset(
                  'assets/svg/ic_seed_12.svg',
                  colorFilter: ColorFilter.mode(
                      widget.isSeed12Selected
                          ? AppColors.selectedSeedChoiceColor
                          : _seed12Color,
                      BlendMode.srcIn,),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
