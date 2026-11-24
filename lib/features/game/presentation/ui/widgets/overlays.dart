import 'package:flutter/material.dart';

import '../../../../../app/theme/app_colors.dart';

class PauseOverlay extends StatelessWidget {
  const PauseOverlay({
    super.key,
    required this.onResume,
    required this.onRestart,
  });

  final VoidCallback onResume;
  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black38,
      child: Center(
        child: _Card(
          title: 'Paused',
          children: [
            FilledButton(onPressed: onResume, child: const Text('Continue')),
            TextButton(
              onPressed: onRestart,
              child: const Text('Restart level'),
            ),
          ],
        ),
      ),
    );
  }
}

class LevelCompleteOverlay extends StatelessWidget {
  const LevelCompleteOverlay({super.key, required this.onNext});

  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black38,
      child: Center(
        child: _Card(
          title: 'Level clear!',
          children: [
            FilledButton(onPressed: onNext, child: const Text('Next level')),
          ],
        ),
      ),
    );
  }
}

class GameOverOverlay extends StatelessWidget {
  const GameOverOverlay({super.key, required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black38,
      child: Center(
        child: _Card(
          title: 'Out of hearts',
          subtitle: 'Try a different order.',
          children: [
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: onRetry,
                    child: const Text('Retry'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {},
                    child: const Text('Revive'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({
    required this.title,
    required this.children,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: AppColors.text,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              subtitle!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textMuted),
            ),
          ],
          const SizedBox(height: 18),
          ...children,
        ],
      ),
    );
  }
}
