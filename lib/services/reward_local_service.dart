import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/reward_coupon_model.dart';

class RewardLocalService {
  RewardLocalService._();

  static final RewardLocalService instance = RewardLocalService._();

  static const String _storageKey = 'local_reward_coupons_v1';

  final ValueNotifier<List<RewardCoupon>> rewardsListenable =
      ValueNotifier<List<RewardCoupon>>(<RewardCoupon>[]);

  bool _isInitialized = false;

  Future<void> ensureInitialized() async {
    if (_isInitialized) return;

    final prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString(_storageKey);

    if (raw == null || raw.trim().isEmpty) {
      final seededRewards = _seedRewards();
      await _saveRewards(seededRewards);
      rewardsListenable.value = seededRewards;
    } else {
      rewardsListenable.value = _decodeRewards(raw);
    }

    _isInitialized = true;
  }

  Future<List<RewardCoupon>> getRewards() async {
    await ensureInitialized();
    return List<RewardCoupon>.from(rewardsListenable.value);
  }

  Future<RewardCoupon?> getRewardBySource({
    required String sourceType,
    required String sourceId,
  }) async {
    await ensureInitialized();

    for (final reward in rewardsListenable.value) {
      if (reward.sourceType == sourceType && reward.sourceId == sourceId) {
        return reward;
      }
    }

    return null;
  }

  Future<RewardCoupon> createOrGetReward({
    required String sourceType,
    required String sourceId,
  }) async {
    await ensureInitialized();

    final existing = await getRewardBySource(
      sourceType: sourceType,
      sourceId: sourceId,
    );
    if (existing != null) {
      return existing;
    }

    final reward = _buildReward(
      sourceType: sourceType,
      sourceId: sourceId,
      indexSeed: sourceId.hashCode.abs(),
    );
    final updatedRewards = <RewardCoupon>[reward, ...rewardsListenable.value];
    await _saveRewards(updatedRewards);
    rewardsListenable.value = updatedRewards;
    return reward;
  }

  Future<RewardCoupon> markRewardScratched(String rewardId) async {
    await ensureInitialized();

    final existingReward = rewardsListenable.value.cast<RewardCoupon?>().firstWhere(
          (reward) => reward?.id == rewardId,
          orElse: () => null,
        );
    if (existingReward == null) {
      throw StateError('Reward not found for id $rewardId');
    }

    RewardCoupon? updatedReward;
    final updatedRewards = rewardsListenable.value.map((reward) {
      if (reward.id != rewardId) {
        return reward;
      }

      updatedReward = reward.copyWith(scratched: true);
      return updatedReward!;
    }).toList();

    await _saveRewards(updatedRewards);
    rewardsListenable.value = updatedRewards;
    return updatedReward ?? existingReward;
  }

  List<RewardCoupon> _seedRewards() {
    return <RewardCoupon>[
      _buildReward(
        sourceType: 'order',
        sourceId: 'DEMO-ORDER-101',
        indexSeed: 0,
      ),
      _buildReward(
        sourceType: 'service',
        sourceId: 'DEMO-SERVICE-202',
        indexSeed: 1,
      ).copyWith(scratched: true),
    ];
  }

  RewardCoupon _buildReward({
    required String sourceType,
    required String sourceId,
    required int indexSeed,
  }) {
    const templates = <Map<String, String>>[
      <String, String>{
        'title': '10% OFF',
        'description': 'Get 10% off on your next order',
        'code': 'CRACK10',
        'validTill': '30 Mar',
        'accentHex': '#1A73E8',
        'iconName': 'local_offer',
      },
      <String, String>{
        'title': '15% OFF',
        'description': 'Get 15% off on your next service booking',
        'code': 'SERV15',
        'validTill': '12 Apr',
        'accentHex': '#0F9D58',
        'iconName': 'build_circle',
      },
      <String, String>{
        'title': '\u20B950 OFF',
        'description': 'Save \u20B950 on your next order',
        'code': 'SAVE50',
        'validTill': '08 Apr',
        'accentHex': '#F9AB00',
        'iconName': 'currency_rupee',
      },
      <String, String>{
        'title': 'Free Delivery',
        'description': 'Unlock free delivery on your next order',
        'code': 'SHIPFREE',
        'validTill': '18 Apr',
        'accentHex': '#DB4437',
        'iconName': 'local_shipping',
      },
      <String, String>{
        'title': '20% OFF up to \u20B9100',
        'description': 'Save 20% up to \u20B9100 on your next checkout',
        'code': 'WIN100',
        'validTill': '27 Apr',
        'accentHex': '#7C4DFF',
        'iconName': 'redeem',
      },
    ];

    final template = templates[indexSeed % templates.length];
    return RewardCoupon(
      id: 'reward_${sourceType}_$sourceId',
      title: template['title']!,
      description: template['description']!,
      code: '${template['code']}_$sourceId',
      sourceType: sourceType,
      sourceId: sourceId,
      scratched: false,
      validTill: template['validTill']!,
      accentHex: template['accentHex']!,
      iconName: template['iconName']!,
      createdAt: DateTime.now().toIso8601String(),
    );
  }

  List<RewardCoupon> _decodeRewards(String raw) {
    final decoded = jsonDecode(raw);
    if (decoded is! List) return <RewardCoupon>[];

    return decoded
        .whereType<Map>()
        .map(
          (item) => RewardCoupon.fromJson(
            Map<String, dynamic>.from(item),
          ),
        )
        .toList();
  }

  Future<void> _saveRewards(List<RewardCoupon> rewards) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(
      rewards.map((reward) => reward.toJson()).toList(),
    );
    await prefs.setString(_storageKey, encoded);
  }
}
