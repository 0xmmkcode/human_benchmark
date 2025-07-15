import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(MaterialApp(home: ReactionTimePage()));
}

class ReactionTimePage extends StatefulWidget {
  @override
  _ReactionTimePageState createState() => _ReactionTimePageState();
}

enum GameState { ready, waiting, go, result }

class _ReactionTimePageState extends State<ReactionTimePage> {
  GameState _state = GameState.ready;
  Timer? _timer;
  DateTime? _startTime;
  int? _reactionTime;
  int? _highScore;
  final Random _random = Random();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _loadHighScore();

  }
  void _startGame() {
    setState(() {
      _state = GameState.waiting;
      _reactionTime = null;
    });

    int delay = 2000 + _random.nextInt(3000); // 2 to 5 seconds
    _timer = Timer(Duration(milliseconds: delay), () {
      setState(() {
        _state = GameState.go;
        _startTime = DateTime.now();
      });
    });
  }

  void _onScreenTap() async{

    if (_state == GameState.waiting) {
      _timer?.cancel();
      setState(() {
        _state = GameState.result;
        _reactionTime = -1; // Too early
      });
    } else if (_state == GameState.go) {
      final now = DateTime.now();

      setState(() {
        _state = GameState.result;
        _reactionTime = now.difference(_startTime!).inMilliseconds;
      });
      if (_reactionTime == null || _reactionTime! < (_highScore ?? 999999)) {
        _highScore = _reactionTime;
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setInt('highScore', _highScore!);
      }
    } else if (_state == GameState.result) {
      setState(() {
        _state = GameState.ready;
      });
    }
  }

  Future<void> _loadHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _highScore = prefs.getInt('highScore');
    });
  }

  @override
  Widget build(BuildContext context) {
    String message = '';
    Color bgColor = Colors.grey.shade800;

    switch (_state) {
      case GameState.ready:
        message = 'Tap to Start';
        break;
      case GameState.waiting:
        message = 'Wait for Green...';
        bgColor = Colors.red;
        break;
      case GameState.go:
        message = 'TAP NOW!';
        bgColor = Colors.green;
        break;
      case GameState.result:
        if (_reactionTime == -1) {
          message = 'Too Soon!\nTap to Try Again';
          bgColor = Colors.red.shade900;
        } else {
          message = 'Your Reaction Time: $_reactionTime ms\nTap to Retry';
          bgColor = Colors.blueGrey;
        }
        break;
    }

    return GestureDetector(
      onTap: () {
        if (_state == GameState.ready) {
          _startGame();
        } else {
          _onScreenTap();
        }
      },
      child: Scaffold(
        backgroundColor: bgColor,
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_highScore != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Text(
                  '🏆 Best: $_highScore ms',
                  style: TextStyle(fontSize: 20, color: Colors.white70),
                ),
              ),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 32, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
