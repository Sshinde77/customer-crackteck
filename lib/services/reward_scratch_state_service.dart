import 'package:shared_preferences/shared_preferences.dart';

class RewardScratchStateService {
  RewardScratchStateService._();

  static final RewardScratchStateService instance =
      RewardScratchStateService._();

  static const String _storageKey = 'scratched_reward_ids_v1';

  Future<Set<String>> getScratchedRewardIds() async {
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList(_storageKey) ?? <String>[];
    return ids.map((id) => id.trim()).where((id) => id.isNotEmpty).toSet();
  }

  Future<bool> isScratched(String rewardId) async {
    final scratchedIds = await getScratchedRewardIds();
    return scratchedIds.contains(rewardId);
  }

  Future<void> markScratched(String rewardId) async {
    if (rewardId.trim().isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final scratchedIds = await getScratchedRewardIds();
    scratchedIds.add(rewardId);
    await prefs.setStringList(_storageKey, scratchedIds.toList());
  }
}
