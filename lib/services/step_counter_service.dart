import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';

/// Session-relative step counter. Subtracts a baseline (first event seen
/// after `start`) from raw cumulative step count so each workout starts at 0.
class StepCounterSession {
  StepCounterSession();

  final _ctrl = StreamController<int>.broadcast();
  StreamSubscription<StepCount>? _sub;
  int? _baseline;
  int _current = 0;

  Stream<int> get stream => _ctrl.stream;
  int get steps => _current;

  Future<bool> start() async {
    if (defaultTargetPlatform != TargetPlatform.android &&
        defaultTargetPlatform != TargetPlatform.iOS) {
      return false;
    }
    final status = await Permission.activityRecognition.request();
    if (!status.isGranted) return false;
    try {
      _sub = Pedometer.stepCountStream.listen(_onEvent, onError: (_) {
        _ctrl.addError('Sensor unavailable');
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  void _onEvent(StepCount event) {
    _baseline ??= event.steps;
    _current = event.steps - _baseline!;
    if (_current < 0) _current = 0;
    _ctrl.add(_current);
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
