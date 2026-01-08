import 'dart:async'; // Import for the Timer
import 'package:flutter/material.dart';

class BreathingScreen extends StatefulWidget {
  const BreathingScreen({Key? key}) : super(key: key);

  @override
  State<BreathingScreen> createState() => _BreathingScreenState();
}

// ✅ Add TickerProviderStateMixin for animation
class _BreathingScreenState extends State<BreathingScreen>
    with SingleTickerProviderStateMixin {

  // --- Animation State ---
  late AnimationController _controller;
  late Animation<double> _animation;
  String _instructionText = "Select a duration to begin";

  // --- Timer State ---
  Timer? _timer;
  int _selectedDuration = 0; // in seconds
  int _remainingTime = 0;
  bool _isSessionActive = false;

  @override
  void initState() {
    super.initState();

    // 1. Initialize the Animation Controller
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4), // 4 seconds to breathe in
    );

    // 2. Create a Tween for scaling animation (from small to large)
    _animation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    // 3. Add a listener to reverse animation and update text
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() => _instructionText = "Breathe Out...");
        _controller.reverse();
      } else if (status == AnimationStatus.dismissed) {
        setState(() => _instructionText = "Breathe In...");
        _controller.forward();
      }
    });
  }

  void _startSession(int durationInMinutes) {
    setState(() {
      _selectedDuration = durationInMinutes * 60;
      _remainingTime = _selectedDuration;
      _isSessionActive = true;
      _instructionText = "Breathe In...";
    });

    _controller.forward(); // Start the animation cycle

    // Start the countdown timer
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingTime > 0) {
        setState(() {
          _remainingTime--;
        });
      } else {
        _stopSession();
      }
    });
  }

  void _stopSession() {
    _timer?.cancel();
    _controller.stop();
    setState(() {
      _isSessionActive = false;
      _instructionText = "Session Complete. Well done!";
      _remainingTime = 0;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Breathing Exercise"),
        backgroundColor: Colors.teal,
      ),
      body: Container(
        // ✅ STYLE: Add a calming gradient background
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.teal.shade200, Colors.teal.shade500],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // The animated circle
              AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _animation.value,
                    child: child,
                  );
                },
                child: Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.3),
                  ),
                ),
              ),
              const SizedBox(height: 40),

              // Instructional text
              Text(
                _instructionText,
                style: const TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              // Timer display
              if (_isSessionActive)
                Text(
                  "${(_remainingTime ~/ 60).toString().padLeft(2, '0')}:${(_remainingTime % 60).toString().padLeft(2, '0')}",
                  style: const TextStyle(fontSize: 42, color: Colors.white),
                ),
              const SizedBox(height: 60),

              // Control buttons
              if (!_isSessionActive)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildDurationButton(1),
                    _buildDurationButton(3),
                    _buildDurationButton(5),
                  ],
                )
              else
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _stopSession,
                  icon: const Icon(Icons.stop),
                  label: const Text("Stop Session"),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper widget for the duration buttons
  Widget _buildDurationButton(int minutes) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        shape: const CircleBorder(),
        padding: const EdgeInsets.all(24),
        backgroundColor: Colors.white.withOpacity(0.8),
        foregroundColor: Colors.teal.shade800,
      ),
      onPressed: () => _startSession(minutes),
      child: Text("$minutes\nmin", textAlign: TextAlign.center),
    );
  }
}