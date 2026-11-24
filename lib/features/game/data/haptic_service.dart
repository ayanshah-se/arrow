import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';

/// Native motor pulse via [arrows/haptics], then plugins, then Flutter haptics.
class HapticService {
  static const _channel = MethodChannel('arrows/haptics');

  Future<void> light() => _pulse(durationMs: 35, strong: false);

  Future<void> blocked({required bool gameOver}) =>
      _pulse(durationMs: gameOver ? 200 : 90, strong: true);

  Future<void> _pulse({required int durationMs, required bool strong}) async {
    try {
      await _channel.invokeMethod<void>('vibrate', {
        'duration': durationMs,
        'strong': strong,
      });
      return;
    } on MissingPluginException {
      // Desktop / widget tests — try remaining fallbacks.
    } catch (_) {}

    try {
      await Vibration.vibrate(
        duration: durationMs,
        amplitude: strong ? 255 : 128,
      );
      return;
    } catch (_) {}

    try {
      if (strong) {
        await HapticFeedback.heavyImpact();
        await HapticFeedback.vibrate();
      } else {
        await HapticFeedback.selectionClick();
      }
    } catch (_) {}

    if (kDebugMode && kIsWeb) {
      // No vibrator on web.
    }
  }
}

final hapticService = HapticService();
