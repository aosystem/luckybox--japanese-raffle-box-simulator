import 'dart:async';
import 'package:flutter/material.dart';

class LoadingController {
  int _dotCount = 0;
  bool _isReady = false;
  late Timer _timer;

  bool get isReady => _isReady;

  set isReady(bool value) {
    _isReady = value;
  }

  void start(VoidCallback onUpdate) {
    _timer = Timer.periodic(const Duration(milliseconds: 500), (currentTimer) {
      if (!_isReady) {
        _dotCount = (_dotCount + 1) % 4;
        onUpdate();
      } else {
        currentTimer.cancel();
      }
    });
  }

  void dispose() {
    if (_timer.isActive) {
      _timer.cancel();
    }
  }

  Widget buildLoadingView() {
    final dots = "." * _dotCount;
    return Scaffold(
      backgroundColor: Colors.yellow[800],
      body: Center(
        child: Text(
          "$dots Starting up $dots",
          style: const TextStyle(fontSize: 24, color: Colors.white),
        ),
      ),
    );
  }
}
