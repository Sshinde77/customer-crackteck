import 'package:flutter/material.dart';

import '../models/reward_coupon_model.dart';
import 'reward_card_widget.dart';

class RewardListItem extends StatelessWidget {
  final RewardCoupon reward;
  final VoidCallback? onTap;

  const RewardListItem({
    super.key,
    required this.reward,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        RewardCardWidget(
          reward: reward,
          isCompact: true,
          onTap: onTap,
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              reward.scratched ? 'Unlocked' : 'Pending',
              style: const TextStyle(
                color: Colors.white,
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
