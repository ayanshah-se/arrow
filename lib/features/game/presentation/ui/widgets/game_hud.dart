import 'package:flutter/material.dart';

import '../../../../../app/theme/app_colors.dart';

class GameHud extends StatelessWidget {
  const GameHud({
    super.key,
    required this.level,
    required this.hearts,
    required this.maxHearts,
    required this.gridOn,
    required this.canUndo,
    required this.onPause,
    required this.onToggleGrid,
    required this.onUndo,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onResetZoom,
  });

  final int level;
  final int hearts;
  final int maxHearts;
  final bool gridOn;
  final bool canUndo;
  final VoidCallback onPause;
  final VoidCallback onToggleGrid;
  final VoidCallback onUndo;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onResetZoom;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 12, 6),
      child: Row(
        children: [
          Text(
            'Level $level',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.text,
            ),
          ),
          const SizedBox(width: 14),
          Row(
            children: [
              for (var i = 0; i < maxHearts; i++)
                Padding(
                  padding: const EdgeInsets.only(right: 2),
                  child: Icon(
                    i < hearts ? Icons.favorite : Icons.favorite_border,
                    size: 22,
                    color: i < hearts ? AppColors.heart : AppColors.heartEmpty,
                  ),
                ),
            ],
          ),
          const Spacer(),
          _HudButton(
            icon: Icons.undo_rounded,
            label: 'Undo miss tap',
            onTap: canUndo ? onUndo : null,
          ),
          const SizedBox(width: 6),
          _HudButton(
            icon: gridOn ? Icons.grid_on_rounded : Icons.grid_off_rounded,
            label: 'Toggle grid',
            onTap: onToggleGrid,
          ),
          const SizedBox(width: 6),
          // _HudButton(
          //   icon: Icons.zoom_out_rounded,
          //   label: 'Zoom out',
          //   onTap: onZoomOut,
          // ),
          // const SizedBox(width: 4),
          // _HudButton(
          //   icon: Icons.zoom_in_rounded,
          //   label: 'Zoom in',
          //   onTap: onZoomIn,
          // ),
          // const SizedBox(width: 4),
          _HudButton(
            icon: Icons.center_focus_strong_rounded,
            label: 'Reset zoom',
            onTap: onResetZoom,
          ),
          const SizedBox(width: 6),
          _HudButton(icon: Icons.pause_rounded, label: 'Pause', onTap: onPause),
        ],
      ),
    );
  }
}

class _HudButton extends StatelessWidget {
  const _HudButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: SizedBox(
            width: 35,
            height: 35,
            child: Icon(
              icon,
              color: onTap == null
                  ? AppColors.textMuted.withValues(alpha: 0.35)
                  : AppColors.textMuted,
              size: 22,
            ),
          ),
        ),
      ),
    );
  }
}
