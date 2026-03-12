import 'package:flutter/material.dart';

class ClaimRewardButton extends StatelessWidget {
  final bool hasClaimed;
  final VoidCallback onPressed;

  const ClaimRewardButton({
    super.key,
    required this.hasClaimed,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: <Color>[Color(0xFFE8F0FE), Color(0xFFF1F8E9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: const Color(0xFF1A73E8).withOpacity(0.1),
            blurRadius: 18,
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
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.card_giftcard_rounded,
                  color: Color(0xFF1A73E8),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  hasClaimed ? 'Reward already added' : 'You unlocked a reward',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF202124),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            hasClaimed
                ? 'Open your scratch card and reveal the coupon anytime from My Rewards.'
                : 'Scratch to reveal your coupon and save it to My Rewards.',
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF5F6368),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onPressed,
              icon: Icon(hasClaimed ? Icons.visibility_outlined : Icons.redeem_outlined),
              label: Text(hasClaimed ? 'View Reward' : 'Claim Reward'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A73E8),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
