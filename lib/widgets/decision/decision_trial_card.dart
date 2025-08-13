import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/decision_trial.dart';

class DecisionTrialCard extends StatefulWidget {
  final DecisionTrial trial;
  final void Function(DecisionResponse response) onAnswered;

  const DecisionTrialCard({
    super.key,
    required this.trial,
    required this.onAnswered,
  });

  @override
  State<DecisionTrialCard> createState() => _DecisionTrialCardState();
}

class _DecisionTrialCardState extends State<DecisionTrialCard> {
  late int _remaining;
  Timer? _timer;
  late final Stopwatch _stopwatch;

  @override
  void initState() {
    super.initState();
    _remaining = widget.trial.timeLimitSeconds;
    _stopwatch = Stopwatch()..start();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_remaining <= 1) {
        t.cancel();
        _submitTimeout();
      } else {
        setState(() => _remaining -= 1);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _submit(String side, DecisionOption option) {
    if (!_stopwatch.isRunning) return;
    _stopwatch.stop();
    _timer?.cancel();
    widget.onAnswered(
      DecisionResponse(
        trialId: widget.trial.id,
        chosenLabel: side,
        choseRisky: option.isRisky,
        responseTime: _stopwatch.elapsed,
        timedOut: false,
      ),
    );
  }

  void _submitTimeout() {
    if (!_stopwatch.isRunning) return;
    _stopwatch.stop();
    widget.onAnswered(
      DecisionResponse(
        trialId: widget.trial.id,
        chosenLabel: 'timeout',
        choseRisky: false,
        responseTime: _stopwatch.elapsed,
        timedOut: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Time left: $_remaining s',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontWeight: FontWeight.w600,
                  color: Colors.blue.shade700,
                ),
              ),
              const Icon(Icons.timer, color: Colors.blue),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            widget.trial.prompt,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.blue.shade900,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _DecisionOptionButton(
                  color: Colors.green.shade50,
                  border: Colors.green.shade300,
                  title: widget.trial.left.label,
                  subtitle: widget.trial.left.description,
                  onTap: () => _submit('left', widget.trial.left),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DecisionOptionButton(
                  color: Colors.orange.shade50,
                  border: Colors.orange.shade300,
                  title: widget.trial.right.label,
                  subtitle: widget.trial.right.description,
                  onTap: () => _submit('right', widget.trial.right),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DecisionOptionButton extends StatelessWidget {
  final Color color;
  final Color border;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _DecisionOptionButton({
    required this.color,
    required this.border,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color,
          border: Border.all(color: border),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 12,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
