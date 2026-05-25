import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:google_fonts/google_fonts.dart';
import 'services/user_storage.dart';
import 'services/workout_repository.dart';
import 'services/step_counter_service.dart';
import 'services/jump_counter_service.dart';

class WorkoutDetailPage extends StatefulWidget {
  const WorkoutDetailPage({
    super.key,
    required this.exercise,
    required this.weightKg,
  });

  final Exercise exercise;
  final int weightKg;

  @override
  State<WorkoutDetailPage> createState() => _WorkoutDetailPageState();
}

class _WorkoutDetailPageState extends State<WorkoutDetailPage> {
  Timer? _timer;
  int _elapsedSec = 0;
  bool _running = false;
  bool _completed = false;

  StepCounterSession? _stepSession;
  JumpCounterSession? _jumpSession;
  int _sensorCount = 0;
  bool _sensorError = false;

  bool get _isSensor =>
      widget.exercise.sensorReady &&
      widget.exercise.sensor != SensorType.timer;

  int get _sensorTarget {
    final ex = widget.exercise;
    if (ex.sensor == SensorType.step) return ex.targetSteps ?? ex.targetSec;
    if (ex.sensor == SensorType.jump) return ex.targetReps ?? ex.targetSec;
    return ex.targetSec;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _stepSession?.dispose();
    _jumpSession?.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    HapticFeedback.selectionClick();
    if (_isSensor && _sensorCount == 0 && !_sensorError) {
      final ok = await _initSensor();
      if (!ok) {
        setState(() => _sensorError = true);
      }
    }
    if (!mounted) return;
    setState(() => _running = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _elapsedSec++;
        if (!_isSensor && _elapsedSec >= widget.exercise.targetSec) {
          _autoComplete();
        }
      });
    });
  }

  Future<bool> _initSensor() async {
    final ex = widget.exercise;
    if (ex.sensor == SensorType.step) {
      _stepSession = StepCounterSession();
      final ok = await _stepSession!.start();
      if (!ok) return false;
      _stepSession!.stream.listen((steps) {
        if (!mounted) return;
        setState(() {
          _sensorCount = steps;
          if (_sensorCount >= _sensorTarget && !_completed) {
            _autoComplete();
          }
        });
      }, onError: (_) {
        if (!mounted) return;
        setState(() => _sensorError = true);
      });
      return true;
    }
    if (ex.sensor == SensorType.jump) {
      _jumpSession = JumpCounterSession(
        threshold: ex.category == 'high' ? 14.0 : 11.0,
        debounce: const Duration(milliseconds: 280),
      );
      final ok = _jumpSession!.start();
      if (!ok) return false;
      _jumpSession!.stream.listen((c) {
        if (!mounted) return;
        setState(() {
          _sensorCount = c;
          if (_sensorCount >= _sensorTarget && !_completed) {
            _autoComplete();
          }
        });
      }, onError: (_) {
        if (!mounted) return;
        setState(() => _sensorError = true);
      });
      return true;
    }
    return true;
  }

  void _pause() {
    HapticFeedback.selectionClick();
    _timer?.cancel();
    setState(() => _running = false);
  }

  void _reset() {
    HapticFeedback.lightImpact();
    _timer?.cancel();
    _stepSession?.stop();
    _jumpSession?.stop();
    _stepSession = null;
    _jumpSession = null;
    setState(() {
      _elapsedSec = 0;
      _sensorCount = 0;
      _running = false;
      _completed = false;
      _sensorError = false;
    });
  }

  void _autoComplete() {
    _timer?.cancel();
    _stepSession?.stop();
    _jumpSession?.stop();
    _completed = true;
    _running = false;
    HapticFeedback.heavyImpact();
  }

  Future<void> _markDone() async {
    HapticFeedback.mediumImpact();
    _timer?.cancel();
    _stepSession?.stop();
    _jumpSession?.stop();
    final duration =
        _elapsedSec > 0 ? _elapsedSec : widget.exercise.targetSec;
    final kcal = _kcalForDuration(duration);
    await UserStorage.addWorkout(
      exerciseId: widget.exercise.id,
      name: widget.exercise.name,
      durationSec: duration,
      kcal: kcal,
      expGain: kcal,
    );
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  int _kcalForDuration(int sec) {
    final minutes = sec / 60.0;
    return (widget.exercise.met * widget.weightKg * 3.5 / 200 * minutes)
        .round();
  }

  String _format(int sec) {
    final m = (sec ~/ 60).toString().padLeft(2, '0');
    final s = (sec % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final ex = widget.exercise;
    final estKcal = _kcalForDuration(
      _elapsedSec > 0 ? _elapsedSec : ex.targetSec,
    );
    final progress = _isSensor
        ? (_sensorCount / _sensorTarget).clamp(0.0, 1.0).toDouble()
        : (_elapsedSec / ex.targetSec).clamp(0.0, 1.0).toDouble();

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const ColoredBox(color: Color(0xFF5BA3D9)),
          ImageFiltered(
            imageFilter: ImageFilter.blur(
              sigmaX: 160,
              sigmaY: 160,
              tileMode: TileMode.clamp,
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Align(
                  alignment: Alignment.topCenter,
                  child: Image.asset('assets/Sky.png',
                      fit: BoxFit.fitWidth, width: double.infinity),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Image.asset('assets/Hill.png',
                      fit: BoxFit.fitWidth, width: double.infinity),
                ),
              ],
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildInfoCard(ex, estKcal),
                ),
                const SizedBox(height: 24),
                _buildRing(progress),
                const SizedBox(height: 24),
                _buildControls(),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  child: SizedBox(
                    width: double.infinity,
                    child: GestureDetector(
                      onTap: _markDone,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: _completed
                              ? const Color(0xFF2E7D32)
                              : const Color(0xFFF5A623),
                          borderRadius: BorderRadius.circular(50),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            _completed ? 'Save Workout' : 'Mark Done',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(false),
            child: const Icon(Icons.close_rounded,
                color: Colors.white, size: 28),
          ),
          Text(
            widget.exercise.name,
            style: GoogleFonts.jersey20(fontSize: 22, color: Colors.white),
          ),
          const SizedBox(width: 28),
        ],
      ),
    );
  }

  Widget _buildInfoCard(Exercise ex, int kcal) {
    final categoryLabel =
        ex.category == 'high' ? 'High Impact' : 'Low Impact';
    final categoryColor = ex.category == 'high'
        ? const Color(0xFFD9534F)
        : const Color(0xFF2E7D32);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: categoryColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Text(
                  categoryLabel,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: categoryColor,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _sensorBadge(ex.sensor, ex.sensorReady && !_sensorError),
              if (_sensorError) ...[
                const SizedBox(width: 6),
                Text(
                  'fallback',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: const Color(0xFFD9534F),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          Text(
            ex.detail,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.local_fire_department_rounded,
                  size: 16, color: Color(0xFFF5A623)),
              const SizedBox(width: 4),
              Text(
                'Est. $kcal kcal',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sensorBadge(SensorType s, bool ready) {
    final (label, icon) = switch (s) {
      SensorType.step => ('Step', Icons.directions_walk_rounded),
      SensorType.jump => ('Jump', Icons.fitness_center_rounded),
      SensorType.timer => ('Timer', Icons.timer_rounded),
    };
    final bg = ready
        ? const Color(0xFF5BA3D9).withValues(alpha: 0.15)
        : Colors.grey.shade200;
    final fg = ready ? const Color(0xFF1976D2) : Colors.black45;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(50),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: fg),
          const SizedBox(width: 4),
          Text(
            ready ? '$label · auto' : '$label · manual',
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRing(double progress) {
    final ex = widget.exercise;
    final unitLabel = switch (ex.sensor) {
      SensorType.step => 'steps',
      SensorType.jump => 'reps',
      SensorType.timer => '',
    };

    String main;
    String sub;
    if (_isSensor) {
      main = '$_sensorCount';
      sub = '$_sensorCount / $_sensorTarget $unitLabel · ${_format(_elapsedSec)}';
    } else {
      main = _format(_elapsedSec);
      final remaining =
          (ex.targetSec - _elapsedSec).clamp(0, ex.targetSec);
      sub = _completed
          ? 'Target hit'
          : 'Target ${_format(ex.targetSec)} · ${_format(remaining)} left';
    }

    return SizedBox(
      width: 220,
      height: 220,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 220,
            height: 220,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 10,
              backgroundColor: Colors.white.withValues(alpha: 0.25),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFFF5A623),
              ),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                main,
                style: GoogleFonts.jersey20(
                  fontSize: _isSensor ? 72 : 56,
                  color: Colors.white,
                  height: 1.0,
                ),
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  sub,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _ctrlButton(
          icon: _running ? Icons.pause_rounded : Icons.play_arrow_rounded,
          label: _running ? 'Pause' : (_elapsedSec > 0 ? 'Resume' : 'Start'),
          onTap: _running ? _pause : _start,
        ),
        const SizedBox(width: 16),
        _ctrlButton(
          icon: Icons.refresh_rounded,
          label: 'Reset',
          onTap: _reset,
        ),
      ],
    );
  }

  Widget _ctrlButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(50),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.black87, size: 20),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
