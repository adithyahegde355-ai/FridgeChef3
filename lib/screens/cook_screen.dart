import 'dart:async';
import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../models.dart';
import '../util.dart';

/// Countdown that survives swiping between steps. It tracks a deadline, so a
/// late tick never drifts the clock.
class StepTimer extends ChangeNotifier {
  StepTimer(this.total) : remaining = total;

  final int total;
  int remaining;
  VoidCallback? onDone;

  Timer? _ticker;
  DateTime? _endsAt;

  bool get running => _ticker != null;
  bool get finished => remaining == 0;

  void start() {
    if (running || finished) return;
    _endsAt = DateTime.now().add(Duration(seconds: remaining));
    _ticker = Timer.periodic(const Duration(milliseconds: 250), (_) => _tick());
    notifyListeners();
  }

  void _tick() {
    final left = _endsAt!.difference(DateTime.now()).inMilliseconds;
    final next = left <= 0 ? 0 : (left / 1000).ceil();
    if (next == remaining) return;
    remaining = next;
    if (remaining == 0) {
      _ticker?.cancel();
      _ticker = null;
      notifyListeners();
      onDone?.call();
      return;
    }
    notifyListeners();
  }

  void pause() {
    if (!running) return;
    _ticker?.cancel();
    _ticker = null;
    notifyListeners();
  }

  void reset() {
    _ticker?.cancel();
    _ticker = null;
    remaining = total;
    notifyListeners();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}

class CookScreen extends StatefulWidget {
  const CookScreen({super.key, required this.recipe});

  final Recipe recipe;

  @override
  State<CookScreen> createState() => _CookScreenState();
}

class _CookScreenState extends State<CookScreen> {
  final PageController _page = PageController();
  final Map<int, StepTimer> _timers = {};
  int _index = 0;

  List<CookStep> get _steps => widget.recipe.steps;

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable().catchError((Object _) {});
    for (var i = 0; i < _steps.length; i++) {
      final seconds = _steps[i].seconds;
      if (seconds != null) {
        _timers[i] = StepTimer(seconds)..onDone = () => _onTimerDone(i);
      }
    }
  }

  @override
  void dispose() {
    for (final t in _timers.values) {
      t.dispose();
    }
    _page.dispose();
    WakelockPlus.disable().catchError((Object _) {});
    super.dispose();
  }

  void _onTimerDone(int i) {
    if (!mounted) return;
    HapticFeedback.heavyImpact();
    SystemSound.play(SystemSoundType.alert);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('Timer finished for step ${i + 1}'),
          action: SnackBarAction(label: 'Go', onPressed: () => _goto(i)),
        ),
      );
  }

  void _goto(int i) {
    _page.animateToPage(
      i,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  Future<void> _finish() async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Bon appétit! 🍽️'),
        content: Text('Enjoy your ${widget.recipe.name}.'),
        actions: [
          FilledButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Done')),
        ],
      ),
    );
    if (mounted) Navigator.of(context).pop();
  }

  void _showIngredients() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          children: [
            Text(
              'Ingredients',
              style: Theme.of(ctx).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            for (final i in widget.recipe.ingredients)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: titleCase(i.name),
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
                      ),
                      TextSpan(text: '   ${i.qty}', style: const TextStyle(fontSize: 16)),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final last = _index == _steps.length - 1;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.recipe.name),
        leading: IconButton(
          tooltip: 'Exit cooking mode',
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            tooltip: 'Ingredients',
            icon: const Icon(Icons.list_alt),
            onPressed: _showIngredients,
          ),
        ],
      ),
      body: Column(
        children: [
          LinearProgressIndicator(value: (_index + 1) / _steps.length, minHeight: 6),
          Expanded(
            child: PageView.builder(
              controller: _page,
              itemCount: _steps.length,
              onPageChanged: (i) => setState(() => _index = i),
              itemBuilder: (context, i) => _StepPage(
                number: i + 1,
                total: _steps.length,
                step: _steps[i],
                timer: _timers[i],
              ),
            ),
          ),
          _RunningTimers(timers: _timers, current: _index, onTap: _goto),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                children: [
                  if (_index > 0) ...[
                    Expanded(
                      child: SizedBox(
                        height: 64,
                        child: OutlinedButton.icon(
                          onPressed: () => _goto(_index - 1),
                          icon: const Icon(Icons.arrow_back),
                          label: const Text('Back', style: TextStyle(fontSize: 18)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    flex: 2,
                    child: SizedBox(
                      height: 64,
                      child: FilledButton.icon(
                        onPressed: last ? _finish : () => _goto(_index + 1),
                        icon: Icon(last ? Icons.check : Icons.arrow_forward),
                        label: Text(last ? 'Finish' : 'Next step', style: const TextStyle(fontSize: 18)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepPage extends StatelessWidget {
  const _StepPage({
    required this.number,
    required this.total,
    required this.step,
    required this.timer,
  });

  final int number;
  final int total;
  final CookStep step;
  final StepTimer? timer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'STEP $number OF $total',
            style: theme.textTheme.labelLarge?.copyWith(
              letterSpacing: 1.5,
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            step.text,
            style: const TextStyle(fontSize: 28, height: 1.35, fontWeight: FontWeight.w600),
          ),
          if (timer != null) ...[
            const SizedBox(height: 28),
            _TimerCard(timer: timer!),
          ],
        ],
      ),
    );
  }
}

class _TimerCard extends StatelessWidget {
  const _TimerCard({required this.timer});

  final StepTimer timer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListenableBuilder(
      listenable: timer,
      builder: (context, _) {
        final done = timer.finished;
        return Card(
          color: done ? const Color(0xFFD3F9D8) : theme.colorScheme.primaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Text(
                  done ? "Time's up!" : formatClock(timer.remaining),
                  style: const TextStyle(
                    fontSize: 56,
                    fontWeight: FontWeight.w800,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (!done)
                      FilledButton.icon(
                        onPressed: timer.running ? timer.pause : timer.start,
                        icon: Icon(timer.running ? Icons.pause : Icons.play_arrow),
                        label: Text(timer.running ? 'Pause' : 'Start timer'),
                      ),
                    if (!done) const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: timer.reset,
                      icon: const Icon(Icons.replay),
                      label: const Text('Reset'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Chips for timers still running on other steps. Tap to jump there.
class _RunningTimers extends StatelessWidget {
  const _RunningTimers({required this.timers, required this.current, required this.onTap});

  final Map<int, StepTimer> timers;
  final int current;
  final void Function(int) onTap;

  @override
  Widget build(BuildContext context) {
    if (timers.isEmpty) return const SizedBox.shrink();
    return ListenableBuilder(
      listenable: Listenable.merge(timers.values.toList()),
      builder: (context, _) {
        final active = timers.entries
            .where((e) => e.key != current && e.value.running)
            .toList();
        if (active.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Wrap(
              spacing: 8,
              children: [
                for (final e in active)
                  ActionChip(
                    avatar: const Icon(Icons.timer, size: 18),
                    label: Text('Step ${e.key + 1} · ${formatClock(e.value.remaining)}'),
                    onPressed: () => onTap(e.key),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
