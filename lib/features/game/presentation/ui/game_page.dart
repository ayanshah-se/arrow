import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/theme/app_colors.dart';
import '../controllers/game_controller.dart';
import 'widgets/game_hud.dart';
import 'widgets/overlays.dart';

class GamePage extends GetView<GameController> {
  const GamePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Obx(() {
          return Column(
            children: [
              Obx(
                () => GameHud(
                  level: controller.level.value,
                  hearts: controller.hearts.value,
                  maxHearts: GameController.maxHearts,
                  gridOn: controller.showGrid.value,
                  canUndo: controller.canUndo.value,
                  onPause: controller.togglePause,
                  onToggleGrid: controller.toggleGrid,
                  onUndo: controller.undo,
                  onZoomIn: controller.zoomIn,
                  onZoomOut: controller.zoomOut,
                  onResetZoom: controller.resetZoom,
                ),
              ),
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    RepaintBoundary(
                      child: GameWidget(game: controller.game),
                    ),
                    Obx(() {
                      if (controller.isPaused.value &&
                          !controller.isLevelComplete.value &&
                          !controller.isGameOver.value) {
                        return PauseOverlay(
                          onResume: controller.togglePause,
                          onRestart: controller.retry,
                        );
                      }
                      if (controller.isLevelComplete.value) {
                        return LevelCompleteOverlay(
                          onNext: controller.nextLevel,
                        );
                      }
                      if (controller.isGameOver.value) {
                        return GameOverOverlay(onRetry: controller.retry);
                      }
                      return const SizedBox.shrink();
                    }),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 4, 20, 14),
                child: Text(
                  'Lift off the arrow to cancel · Undo a miss tap',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}
