import 'dart:math';
import 'package:flutter/material.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with SingleTickerProviderStateMixin {
  // Game State
  int _score = 0;
  int _wickets = 0;
  int _ballsBowled = 0;
  final int _totalOvers = 2; // Short game for demo
  List<String> _commentary = [];
  
  // Animation
  late AnimationController _ballController;
  late Animation<double> _ballAnimation;
  bool _isBowling = false;
  String _lastShotResult = "Ready to Play";

  @override
  void initState() {
    super.initState();
    // Ball moves from top (0.0) to bottom (1.0)
    _ballController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500), // Speed of the ball
    );

    _ballAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ballController, curve: Curves.linear),
    );

    _ballController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        // Ball passed the batsman without being hit
        _handleMissedBall();
      }
    });
  }

  @override
  void dispose() {
    _ballController.dispose();
    super.dispose();
  }

  void _startBowling() {
    if (_isBowling || _wickets >= 10 || _ballsBowled >= _totalOvers * 6) return;

    setState(() {
      _isBowling = true;
      _lastShotResult = "Bowling...";
    });
    _ballController.forward(from: 0.0);
  }

  void _handleMissedBall() {
    setState(() {
      _isBowling = false;
      _ballsBowled++;
      _lastShotResult = "Missed! Dot Ball.";
      _addCommentary("•");
      _checkGameOver();
    });
  }

  void _hitBall() {
    if (!_isBowling) return;

    double ballPosition = _ballController.value;
    _ballController.stop();
    
    int runs = 0;
    String resultText = "";
    bool isWicket = false;

    // Hit Logic based on position (0.0 is bowler, 1.0 is batsman)
    // Sweet spot is around 0.85 - 0.95 (just before reaching the batsman)
    
    if (ballPosition >= 0.85 && ballPosition <= 0.95) {
      // Perfect Timing
      runs = 6;
      resultText = "PERFECT! 6 RUNS!";
    } else if (ballPosition >= 0.75 && ballPosition < 0.85) {
      // Good Timing
      runs = 4;
      resultText = "Great Shot! 4 Runs!";
    } else if (ballPosition >= 0.65 && ballPosition < 0.75) {
      // Early Timing
      runs = 2;
      resultText = "Good running. 2 Runs.";
    } else if (ballPosition > 0.95) {
      // Too Late
      isWicket = true;
      resultText = "BOWLED! Too Late!";
    } else {
      // Too Early
      // Random chance of catch or just a miss
      if (Random().nextBool()) {
        isWicket = true;
        resultText = "CAUGHT! Too Early!";
      } else {
        runs = 0;
        resultText = "Swing and a miss!";
      }
    }

    setState(() {
      _isBowling = false;
      _ballsBowled++;
      if (isWicket) {
        _wickets++;
        _addCommentary("W");
      } else {
        _score += runs;
        _addCommentary("$runs");
      }
      _lastShotResult = resultText;
      _checkGameOver();
    });
  }

  void _addCommentary(String event) {
    _commentary.insert(0, event);
    if (_commentary.length > 6) {
      _commentary.removeLast();
    }
  }

  void _checkGameOver() {
    if (_wickets >= 10 || _ballsBowled >= _totalOvers * 6) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text("Innings Over"),
          content: Text("Final Score: $_score/$_wickets\nOvers: ${_getOversDisplay()}"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _resetGame();
              },
              child: const Text("Play Again"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context); // Go to home
              },
              child: const Text("Exit"),
            ),
          ],
        ),
      );
    }
  }

  void _resetGame() {
    setState(() {
      _score = 0;
      _wickets = 0;
      _ballsBowled = 0;
      _commentary.clear();
      _lastShotResult = "Ready to Play";
    });
  }

  String _getOversDisplay() {
    int overs = _ballsBowled ~/ 6;
    int balls = _ballsBowled % 6;
    return "$overs.$balls";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green[800],
      appBar: AppBar(
        title: const Text("Super Cricket"),
        backgroundColor: Colors.green[900],
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Scoreboard
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.black26,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    const Text("SCORE", style: TextStyle(color: Colors.white70, fontSize: 12)),
                    Text("$_score/$_wickets", style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                  ],
                ),
                Column(
                  children: [
                    const Text("OVERS", style: TextStyle(color: Colors.white70, fontSize: 12)),
                    Text("${_getOversDisplay()} / $_totalOvers", style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                  ],
                ),
                Column(
                  children: [
                    const Text("LAST BALL", style: TextStyle(color: Colors.white70, fontSize: 12)),
                    Text(_commentary.isNotEmpty ? _commentary.first : "-", style: const TextStyle(color: Colors.yellow, fontSize: 24, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
          
          // Commentary / Status
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8),
            color: Colors.black12,
            child: Text(
              _lastShotResult,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500),
            ),
          ),

          // Game Field
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Pitch
                Container(
                  width: 120,
                  height: double.infinity,
                  margin: const EdgeInsets.symmetric(vertical: 20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD2B48C), // Tan/Dirt color
                    border: Border.all(color: Colors.white30, width: 2),
                  ),
                ),
                
                // Crease Lines
                Positioned(top: 40, child: Container(width: 120, height: 2, color: Colors.white)),
                Positioned(bottom: 60, child: Container(width: 120, height: 2, color: Colors.white)),

                // Wickets (Bowler End)
                const Positioned(
                  top: 20,
                  child: Icon(Icons.sports_bar, color: Colors.white, size: 30), // Placeholder for wickets
                ),

                // Wickets (Batsman End)
                const Positioned(
                  bottom: 40,
                  child: Icon(Icons.sports_bar, color: Colors.white, size: 30),
                ),

                // Bowler
                const Positioned(
                  top: 10,
                  child: Icon(Icons.person, color: Colors.blue, size: 40),
                ),

                // Batsman
                const Positioned(
                  bottom: 20,
                  child: Icon(Icons.sports_cricket, color: Colors.yellow, size: 50),
                ),

                // The Ball (Animated)
                AnimatedBuilder(
                  animation: _ballController,
                  builder: (context, child) {
                    // Calculate vertical position based on animation value
                    // We need to map 0.0-1.0 to the pitch height
                    // Let's assume the pitch area is roughly the full height minus some padding
                    final double startY = 50; // Near bowler
                    final double endY = MediaQuery.of(context).size.height * 0.5; // Adjust based on screen, simplified
                    
                    // Using LayoutBuilder would be more precise, but for MVP we can use relative positioning in the Stack
                    // Actually, let's use Align for simplicity in a fixed height container context
                    
                    return Align(
                      alignment: Alignment(0, -0.9 + (_ballController.value * 1.7)), // Moves from top (-0.9) to bottom (0.8)
                      child: _isBowling ? Container(
                        width: 15,
                        height: 15,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(2, 2))]
                        ),
                      ) : const SizedBox(),
                    );
                  },
                ),
                
                // Hit Zone Indicator (Visual Guide)
                Positioned(
                  bottom: 80, // Approximate sweet spot area
                  child: Opacity(
                    opacity: 0.2,
                    child: Container(
                      width: 120,
                      height: 60,
                      color: Colors.greenAccent,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Controls
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isBowling ? null : _startBowling,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    child: const Text("BOWL", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isBowling ? _hitBall : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    child: const Text("HIT", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
