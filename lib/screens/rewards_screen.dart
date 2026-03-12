import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants/app_colors.dart';
import '../models/reward_coupon_model.dart';
import '../services/reward_local_service.dart';
import '../widgets/reward_list_item.dart';
import '../widgets/scratch_reward_popup.dart';

class RewardsScreen extends StatefulWidget {
  const RewardsScreen({super.key});

  @override
  State<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends State<RewardsScreen> {
  bool _isLoading = true;
  List<RewardCoupon> _rewards = <RewardCoupon>[];

  @override
  void initState() {
    super.initState();
    _loadRewards();
  }

  Future<void> _loadRewards() async {
    final rewards = await RewardLocalService.instance.getRewards();
    if (!mounted) return;

    setState(() {
      _rewards = rewards;
      _isLoading = false;
    });
  }

  Future<void> _openReward(RewardCoupon reward) async {
    final updatedReward = await ScratchRewardPopup.show(
      context,
      reward: reward,
      onRewardUpdated: _updateReward,
    );

    if (updatedReward != null) {
      _updateReward(updatedReward);
    }
  }

  void _updateReward(RewardCoupon updatedReward) {
    if (!mounted) return;

    setState(() {
      _rewards = _rewards.map((reward) {
        return reward.id == updatedReward.id ? updatedReward : reward;
      }).toList();
    });
  }

  Future<void> _copyRewardCode(RewardCoupon reward) async {
    if (!reward.scratched) return;

    await Clipboard.setData(ClipboardData(text: reward.code));
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${reward.code} copied to clipboard')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final unlockedCount = _rewards.where((reward) => reward.scratched).length;
    final pendingCount = _rewards.length - unlockedCount;

    return Scaffold(
      backgroundColor: const Color(0xFFF7FBF8),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'My Rewards',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadRewards,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      color: AppColors.primary.withOpacity(0.06),
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.10),
                      ),
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.05),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: const Icon(
                                Icons.card_giftcard_rounded,
                                color: AppColors.primary,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'My Rewards',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'You have $unlockedCount unlocked reward${unlockedCount == 1 ? '' : 's'} and '
                          '$pendingCount scratch card${pendingCount == 1 ? '' : 's'}.',
                          style: TextStyle(
                            color: Colors.black87.withOpacity(0.70),
                            fontSize: 14,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  if (_rewards.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: AppColors.primary.withOpacity(0.10),
                        ),
                      ),
                      child: Column(
                        children: <Widget>[
                          Icon(
                            Icons.redeem_outlined,
                            size: 40,
                            color: AppColors.primary.withOpacity(0.55),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'No rewards yet',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Delivered orders and completed services will unlock scratch cards here.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.black87.withOpacity(0.60),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ..._rewards.map((reward) {
                      return RewardListItem(
                        reward: reward,
                        onTap: () => _openReward(reward),
                        onCopyCode: reward.scratched ? () => _copyRewardCode(reward) : null,
                      );
                    }),
                ],
              ),
            ),
    );
  }
}
