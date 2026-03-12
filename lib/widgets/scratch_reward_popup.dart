import 'dart:math' as math;

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:scratcher/scratcher.dart';

import '../models/reward_coupon_model.dart';
import '../services/reward_local_service.dart';

class ScratchRewardPopup extends StatefulWidget {
  final RewardCoupon reward;
  final ValueChanged<RewardCoupon>? onRewardUpdated;

  const ScratchRewardPopup({
    super.key,
    required this.reward,
    this.onRewardUpdated,
  });

  static Future<RewardCoupon?> show(
    BuildContext context, {
    required RewardCoupon reward,
    ValueChanged<RewardCoupon>? onRewardUpdated,
  }) {
    return showDialog<RewardCoupon>(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 16),
          child: Center(
            child: ScratchRewardPopup(
              reward: reward,
              onRewardUpdated: onRewardUpdated,
            ),
          ),
        );
      },
    );
  }

  @override
  State<ScratchRewardPopup> createState() => _ScratchRewardPopupState();
}

class _ScratchRewardPopupState extends State<ScratchRewardPopup> {
  late final ConfettiController _confettiController;
  late RewardCoupon _reward;
  bool _showUnlockedMessage = false;

  @override
  void initState() {
    super.initState();
    _reward = widget.reward;
    _confettiController = ConfettiController(
      duration: const Duration(milliseconds: 1400),
    );

    if (_reward.scratched) {
      _showUnlockedMessage = true;
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _handleReveal() async {
    if (_reward.scratched) return;

    final updatedReward = await RewardLocalService.instance.markRewardScratched(_reward.id);
    if (!mounted) return;

    setState(() {
      _reward = updatedReward;
      _showUnlockedMessage = true;
    });

    widget.onRewardUpdated?.call(updatedReward);
    _confettiController.play();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Reward Unlocked!')),
    );
  }

  @override
  Widget build(BuildContext context) {
final bottomInset = MediaQuery.of(context).viewInsets.bottom * 0.5;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Stack(
              alignment: Alignment.center,           
               children: <Widget>[
              Container(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 28,
                      offset: const Offset(0, 16),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Center(
                      child: Text(
                        'Scratch & Win',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF202124),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Center(
                      child: Text(
                        _reward.scratched
                            ? 'Your reward is ready to use'
                            : 'Scratch the card to reveal your reward',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF5F6368),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: AspectRatio(
                        aspectRatio: 1.45,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: Stack(
                            fit: StackFit.expand,
                            children: <Widget>[
                              _RewardRevealFace(
                                reward: _reward,
                                showUnlockedMessage: _showUnlockedMessage,
                              ),
                              if (!_reward.scratched)
                                Scratcher(
                                  brushSize: 42,
                                  threshold: 45,
                                  color: const Color(0xFFB0BEC5),
                                  onThreshold: _handleReveal,
                                  child: Container(
                                    decoration: const BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: <Color>[
                                          Color(0xFF90A4AE),
                                          Color(0xFFB0BEC5),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                    ),
                                    child: const Center(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: <Widget>[
                                          Icon(
                                            Icons.pan_tool_alt_outlined,
                                            color: Colors.white,
                                            size: 32,
                                          ),
                                          SizedBox(height: 10),
                                          Text(
                                            'Scratch to reveal your reward',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(_reward),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1A73E8),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(_reward.scratched ? 'Add to My Rewards' : 'Keep Scratching'),
                      ),
                    ),
                  ],
                ),
              ),
              IgnorePointer(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConfettiWidget(
                    confettiController: _confettiController,
                    blastDirectionality: BlastDirectionality.explosive,
                    emissionFrequency: 0.04,
                    numberOfParticles: 18,
                    gravity: 0.22,
                    minBlastForce: 10,
                    maxBlastForce: 24,
                    colors: const <Color>[
                      Color(0xFF1A73E8),
                      Color(0xFF0F9D58),
                      Color(0xFFF9AB00),
                      Color(0xFFDB4437),
                    ],
                    createParticlePath: _drawStar,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Path _drawStar(Size size) {
    const int points = 5;
    final Path path = Path();
    final double radius = size.width / 2;
    final double innerRadius = radius / 2.4;

    for (int i = 0; i < points * 2; i++) {
      final double currentRadius = i.isEven ? radius : innerRadius;
      final double angle = (math.pi / points) * i - math.pi / 2;
      final double x = radius + currentRadius * math.cos(angle);
      final double y = radius + currentRadius * math.sin(angle);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    path.close();
    return path;
  }
}

class _RewardRevealFace extends StatelessWidget {
  final RewardCoupon reward;
  final bool showUnlockedMessage;

  const _RewardRevealFace({
    required this.reward,
    required this.showUnlockedMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[Color(0xFF1A73E8), Color(0xFF34A853)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          AnimatedOpacity(
            opacity: showUnlockedMessage ? 1 : 0.6,
            duration: const Duration(milliseconds: 250),
            child: const Text(
              'Congratulations!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const Spacer(),
          Text(
            reward.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            reward.description,
            style: TextStyle(
              color: Colors.white.withOpacity(0.94),
              fontSize: 14,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.16),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              reward.code,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.4,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Valid till ${reward.validTill}',
            style: TextStyle(
              color: Colors.white.withOpacity(0.88),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
