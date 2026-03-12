import 'package:flutter/material.dart';

import '../models/reward_coupon_model.dart';

class RewardCardWidget extends StatelessWidget {
  final RewardCoupon reward;
  final bool isCompact;
  final Widget? trailing;
  final VoidCallback? onTap;

  const RewardCardWidget({
    super.key,
    required this.reward,
    this.isCompact = false,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = _colorFromHex(reward.accentHex);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              colors: <Color>[
                accent,
                Color.lerp(accent, Colors.white, 0.35) ?? accent,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: accent.withOpacity(0.22),
                blurRadius: 22,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Container(
            padding: EdgeInsets.all(isCompact ? 16 : 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Container(
                      width: isCompact ? 44 : 52,
                      height: isCompact ? 44 : 52,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withOpacity(0.18)),
                      ),
                      child: Icon(
                        _iconForName(reward.iconName),
                        color: Colors.white,
                        size: isCompact ? 24 : 28,
                      ),
                    ),
                    const Spacer(),
                    if (trailing != null) trailing!,
                  ],
                ),
                SizedBox(height: isCompact ? 14 : 20),
                Text(
                  reward.title,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isCompact ? 20 : 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  reward.scratched ? reward.description : 'Scratch to reveal reward',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.96),
                    fontSize: isCompact ? 13 : 14,
                    height: 1.35,
                  ),
                ),
                SizedBox(height: isCompact ? 14 : 18),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.16),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withOpacity(0.18)),
                  ),
                  child: Row(
                    children: <Widget>[
                      const Icon(
                        Icons.confirmation_number_outlined,
                        color: Colors.white,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          reward.scratched ? 'CODE: ${reward.code}' : 'Scratch to reveal coupon code',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: isCompact ? 10 : 14),
                Text(
                  reward.scratched
                      ? 'Valid till ${reward.validTill}'
                      : 'Unlocked from ${reward.sourceType}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static IconData _iconForName(String iconName) {
    switch (iconName) {
      case 'build_circle':
        return Icons.build_circle_outlined;
      case 'currency_rupee':
        return Icons.currency_rupee;
      case 'local_shipping':
        return Icons.local_shipping_outlined;
      case 'redeem':
        return Icons.redeem_outlined;
      case 'local_offer':
      default:
        return Icons.local_offer_outlined;
    }
  }

  static Color _colorFromHex(String input) {
    final normalized = input.replaceAll('#', '');
    final buffer = StringBuffer();
    if (normalized.length == 6) {
      buffer.write('ff');
    }
    buffer.write(normalized);
    return Color(int.parse(buffer.toString(), radix: 16));
  }
}
