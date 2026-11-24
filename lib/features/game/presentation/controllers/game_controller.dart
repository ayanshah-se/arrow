import 'package:get/get.dart';

import '../../data/haptic_service.dart';
import '../../data/heart_loss_audio.dart';
import '../../data/progress_service.dart';
import '../../domain/arrow.dart';
import '../flame/arrow_escape_game.dart';

class GameController extends GetxController {
  static const maxHearts = ArrowEscapeGame.maxHearts;

  final level = 1.obs;
  final hearts = maxHearts.obs;
  final hasStarted = false.obs;
  final isPaused = false.obs;
  final isLevelComplete = false.obs;
  final isGameOver = false.obs;
  final showGrid = true.obs;
  final canUndo = false.obs;

  late final ArrowEscapeGame game;

  @override
  void onInit() {
    super.onInit();
    level.value = progressService.getCurrentLevel();
    game = ArrowEscapeGame(
      onArrowTapped: (_) {},
      onArrowEscaped: _onArrowEscaped,
      onArrowBlocked: _onArrowBlocked,
      onLevelComplete: _onLevelComplete,
    )..loadLevel(level.value);
    game.showGrid = showGrid.value;
  }

  @override
  void onReady() {
    super.onReady();
    startGame();
  }

  void startGame() {
    hasStarted.value = true;
    isPaused.value = false;
    isLevelComplete.value = false;
    isGameOver.value = false;
    hearts.value = maxHearts;
    canUndo.value = false;
    game.setInputLocked(false);
    game.resumeEngine();
  }

  void _onArrowEscaped(Arrow arrow) {
    canUndo.value = game.canUndo;
    hapticService.light();
  }

  void _onArrowBlocked(Arrow arrow) {
    if (!hasStarted.value || isPaused.value || isGameOver.value) return;
    if (hearts.value <= 0) return;

    hearts.value--;
    canUndo.value = true;
    heartLossAudio.play();
    final gameOver = hearts.value <= 0;
    hapticService.blocked(gameOver: gameOver);
    if (gameOver) {
      isGameOver.value = true;
      game.setInputLocked(true);
      game.pauseEngine();
    }
  }

  void _onLevelComplete() {
    if (!hasStarted.value || isGameOver.value) return;
    isLevelComplete.value = true;
    game.setInputLocked(true);
    game.pauseEngine();
    progressService.incrementLevelsCleared();
  }

  void nextLevel() {
    level.value++;
    isLevelComplete.value = false;
    isGameOver.value = false;
    hearts.value = maxHearts;
    canUndo.value = false;
    progressService.saveCurrentLevel(level.value);
    game.loadLevel(level.value);
    game.showGrid = showGrid.value;
    game.setInputLocked(false);
    game.resumeEngine();
  }

  void retry() {
    hasStarted.value = true;
    isLevelComplete.value = false;
    isGameOver.value = false;
    isPaused.value = false;
    hearts.value = maxHearts;
    canUndo.value = false;
    game.resetLevel();
    game.showGrid = showGrid.value;
    game.setInputLocked(false);
    game.resumeEngine();
  }

  void togglePause() {
    if (!hasStarted.value || isLevelComplete.value || isGameOver.value) {
      return;
    }
    isPaused.toggle();
    if (isPaused.value) {
      game.setInputLocked(true);
      game.pauseEngine();
    } else {
      game.setInputLocked(false);
      game.resumeEngine();
    }
  }

  void toggleGrid() {
    showGrid.toggle();
    game.showGrid = showGrid.value;
  }

  void undo() {
    if (!hasStarted.value || isPaused.value) return;
    if (!game.canUndo) return;

    if (isGameOver.value) {
      isGameOver.value = false;
      game.setInputLocked(false);
      game.resumeEngine();
    }
    if (isLevelComplete.value) {
      isLevelComplete.value = false;
      game.setInputLocked(false);
      game.resumeEngine();
    }

    final restoreHeart = game.willUndoBlocked;
    game.undoLast();
    if (restoreHeart && hearts.value < maxHearts) {
      hearts.value++;
    }
    canUndo.value = game.canUndo;
  }

  void resetZoom() => game.resetCamera();

  void zoomIn() => game.zoomIn();

  void zoomOut() => game.zoomOut();

  void goHome() {
    hasStarted.value = false;
    isPaused.value = false;
    isLevelComplete.value = false;
    isGameOver.value = false;
    canUndo.value = false;
  }
}
