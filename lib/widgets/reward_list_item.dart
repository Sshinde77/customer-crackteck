import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../models/reward_coupon_model.dart';
import 'reward_card_widget.dart';

class RewardListItem extends StatelessWidget {
  final RewardCoupon reward;
  final VoidCallback? onTap;
  final VoidCallback? onCopyCode;

  const RewardListItem({
    super.key,
    required this.reward,
    this.onTap,
    this.onCopyCode,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        RewardCardWidget(
          reward: reward,
          isCompact: true,
          onTap: onTap,
          onCopyCode: onCopyCode,
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: AppColors.primary.withOpacity(0.12),
              ),
            ),
            child: Text(
              reward.scratched ? 'Unlocked' : 'Pending',
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
      ],
    );
  }
}
