import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/routes/app_pages.dart';
import '../../../../app/theme/app_colors.dart';
import '../../data/level_generator.dart';
import '../../data/progress_service.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const _months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  String _difficultyLabel(int level) {
    return switch (LevelScaling.forLevel(level).difficulty) {
      LevelDifficulty.easy => 'EASY',
      LevelDifficulty.medium => 'MEDIUM',
      LevelDifficulty.hard => 'HARD',
      LevelDifficulty.expert => 'SUPER HARD',
    };
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final level = progressService.getCurrentLevel();
    final coins = 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFFFBF5),
              AppColors.background,
              Color(0xFFE7EFE4),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              children: [
                _TopBar(coins: coins),
                const SizedBox(height: 8),
                const Align(
                  alignment: Alignment.centerRight,
                  child: _RemoveAdsButton(),
                ),
                const Spacer(flex: 2),
                _DailyChallengeCard(
                  month: _months[now.month - 1],
                  day: now.day,
                  onStart: () => Get.toNamed(AppPages.game),
                ),
                const Spacer(flex: 3),
                _ContinueButton(
                  level: level,
                  difficulty: _difficultyLabel(level),
                  onPressed: () => Get.toNamed(AppPages.game),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.coins});

  final int coins;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(6, 6, 16, 6),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: AppColors.border),
            boxShadow: const [
              BoxShadow(
                color: Color(0x14000000),
                blurRadius: 10,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFE8C547),
                ),
                child: const Icon(
                  Icons.arrow_upward_rounded,
                  color: Color(0xFF6B4E12),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '$coins',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.text,
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        _RoundIconButton(
          icon: Icons.settings_rounded,
          onPressed: () {},
        ),
      ],
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      shape: const CircleBorder(),
      elevation: 2,
      shadowColor: const Color(0x14000000),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.border),
          ),
          child: Icon(icon, color: AppColors.textMuted),
        ),
      ),
    );
  }
}

class _RemoveAdsButton extends StatelessWidget {
  const _RemoveAdsButton();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {},
      child: Column(
        children: [
          SizedBox(
            width: 56,
            height: 56,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  Icons.movie_creation_rounded,
                  size: 36,
                  color: AppColors.textMuted.withValues(alpha: 0.85),
                ),
                const Icon(
                  Icons.block_rounded,
                  size: 40,
                  color: AppColors.danger,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.accent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Remove Ads',
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DailyChallengeCard extends StatelessWidget {
  const _DailyChallengeCard({
    required this.month,
    required this.day,
    required this.onStart,
  });

  final String month;
  final int day;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          Container(
            width: 220,
            margin: const EdgeInsets.only(top: 28),
            padding: const EdgeInsets.fromLTRB(20, 48, 20, 18),
            decoration: BoxDecoration(
              color: const Color(0xFFD8E8D6),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: AppColors.border),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1A000000),
                  blurRadius: 18,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                const Text(
                  'Daily Challenge',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF3D5A40),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  month,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: AppColors.surface,
                    height: 1.05,
                  ),
                ),
                Text(
                  '$day',
                  style: const TextStyle(
                    fontSize: 52,
                    fontWeight: FontWeight.w900,
                    color: AppColors.surface,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: onStart,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.surface,
                      foregroundColor: AppColors.accent,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text('Start'),
                  ),
                ),
              ],
            ),
          ),
          const _CalendarBadge(),
        ],
      ),
    );
  }
}

class _CalendarBadge extends StatelessWidget {
  const _CalendarBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 68,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            height: 16,
            decoration: const BoxDecoration(
              color: AppColors.danger,
              borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
            ),
          ),
          const Expanded(
            child: Center(
              child: Icon(
                Icons.star_rounded,
                color: Color(0xFFE8C547),
                size: 32,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContinueButton extends StatelessWidget {
  const _ContinueButton({
    required this.level,
    required this.difficulty,
    required this.onPressed,
  });

  final int level;
  final String difficulty;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Stack(
        alignment: Alignment.topCenter,
        clipBehavior: Clip.none,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 14),
            child: Material(
              color: AppColors.accent,
              borderRadius: BorderRadius.circular(22),
              elevation: 4,
              shadowColor: const Color(0x33000000),
              child: InkWell(
                onTap: onPressed,
                borderRadius: BorderRadius.circular(22),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: const Color(0xFFE8C547),
                      width: 2,
                    ),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Continue',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          height: 1.1,
                        ),
                      ),
                      Text(
                        'Level $level',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white.withValues(alpha: 0.82),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFE8C547),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                difficulty,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF5A4310),
                  letterSpacing: 0.4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
