import 'dart:async';
import 'dart:math';
import 'package:sensors_plus/sensors_plus.dart';

/// Counts jumps/reps by detecting peaks in linear acceleration magnitude.
/// Uses `userAccelerometerEventStream` (gravity removed). Magnitude threshold
/// and debounce tuned for jumping jacks / squats; tweak per exercise later.
class JumpCounterSession {
  JumpCounterSession({
    this.threshold = 14.0,
    this.debounce = const Duration(milliseconds: 280),
  });

  final double threshold;
  final Duration debounce;

  final _ctrl = StreamController<int>.broadcast();
  StreamSubscription<UserAccelerometerEvent>? _sub;
  DateTime? _lastPeak;
  bool _aboveThreshold = false;
  int _count = 0;

  Stream<int> get stream => _ctrl.stream;
  int get count => _count;

  bool start() {
    try {
      _sub = userAccelerometerEventStream(
        samplingPeriod: const Duration(milliseconds: 20),
      ).listen(_onEvent, onError: (_) {
        _ctrl.addError('Sensor unavailable');
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  void _onEvent(UserAccelerometerEvent e) {
    final mag = sqrt(e.x * e.x + e.y * e.y + e.z * e.z);
    final now = DateTime.now();
    if (mag > threshold) {
      if (!_aboveThreshold &&
          (_lastPeak == null || now.difference(_lastPeak!) > debounce)) {
        _aboveThreshold = true;
        _lastPeak = now;
        _count++;
        _ctrl.add(_count);
      }
    } else if (mag < threshold * 0.6) {
      _aboveThreshold = false;
    }
  }

  Future<void> stop() async {
    await _sub?.cancel();
    _sub = null;
  }

  Future<void> dispose() async {
    await stop();
    await _ctrl.close();
  }
}
