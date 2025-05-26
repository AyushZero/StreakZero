import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math' as math;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Watah',
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.black,
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white, fontFamily: 'Inter'),
          bodyMedium: TextStyle(color: Colors.white, fontFamily: 'Inter'),
          titleLarge: TextStyle(color: Colors.white, fontFamily: 'Inter'),
        ),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  double _currentWater = 0;
  static const double _dailyGoal = 3000; // 3L in ml
  late SharedPreferences _prefs;
  late AnimationController _animationController;
  late Animation<double> _waterAnimation;

  @override
  void initState() {
    super.initState();
    _loadWaterData();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _waterAnimation = Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadWaterData() async {
    _prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentWater = _prefs.getDouble('water') ?? 0;
    });
  }

  Future<void> _addWater(double amount) async {
    final previousWater = _currentWater;
    setState(() {
      _currentWater = (_currentWater + amount).clamp(0, _dailyGoal);
    });
    await _prefs.setDouble('water', _currentWater);

    // Animate the water level change
    _waterAnimation = Tween<double>(
      begin: previousWater / _dailyGoal,
      end: _currentWater / _dailyGoal,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    _animationController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Water Tracker',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w300,
                ),
              ),
              const SizedBox(height: 40),
              // Water circle visualization
              SizedBox(
                width: 250,
                height: 250,
                child: GestureDetector(
                  onDoubleTap: () async {
                    setState(() {
                      _currentWater = 0;
                    });
                    await _prefs.setDouble('water', 0);
                    _waterAnimation = Tween<double>(
                      begin: 1,
                      end: 0,
                    ).animate(
                      CurvedAnimation(
                        parent: _animationController,
                        curve: Curves.easeInOut,
                      ),
                    );
                    _animationController.forward(from: 0);
                  },
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Circle border
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.blue,
                            width: 2,
                          ),
                        ),
                      ),
                      // Animated water level
                      AnimatedBuilder(
                        animation: _waterAnimation,
                        builder: (context, child) {
                          return CustomPaint(
                            size: const Size(250, 250),
                            painter: WaterPainter(
                              waterLevel: _waterAnimation.value,
                            ),
                          );
                        },
                      ),
                      // Water level text
                      Text(
                        '${(_currentWater / 1000).toStringAsFixed(1)}L',
                        style: const TextStyle(
                          fontSize: 32,
                          color: Colors.white,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),
              // Water intake buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () => _addWater(250),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                    ),
                    child: const Text('1 Glass (250ml)'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: () => _addWater(500),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                    ),
                    child: const Text('500ml'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class WaterPainter extends CustomPainter {
  final double waterLevel;

  WaterPainter({required this.waterLevel});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Create circular clip path
    final clipPath = Path()
      ..addOval(Rect.fromCircle(center: center, radius: radius));
    canvas.clipPath(clipPath);

    // Calculate water height
    final waterHeight = size.height * (1 - waterLevel);
    
    // Create water path with wave effect
    final waterPath = Path();
    waterPath.moveTo(0, waterHeight);
    
    // Create wave effect
    for (double i = 0; i <= size.width; i++) {
      final waveHeight = math.sin((i / size.width) * math.pi * 2) * 5;
      waterPath.lineTo(i, waterHeight + waveHeight);
    }
    
    waterPath.lineTo(size.width, size.height);
    waterPath.lineTo(0, size.height);
    waterPath.close();

    // Draw water
    final waterPaint = Paint()
      ..color = Colors.blue.withOpacity(0.5)
      ..style = PaintingStyle.fill;
    canvas.drawPath(waterPath, waterPaint);

    // Add water shine effect
    final shinePaint = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..style = PaintingStyle.fill;
    
    final shinePath = Path();
    final shineHeight = waterHeight + 20;
    shinePath.moveTo(0, shineHeight);
    for (double i = 0; i <= size.width; i++) {
      final waveHeight = math.sin((i / size.width) * math.pi * 2) * 3;
      shinePath.lineTo(i, shineHeight + waveHeight);
    }
    shinePath.lineTo(size.width, size.height);
    shinePath.lineTo(0, size.height);
    shinePath.close();
    
    canvas.drawPath(shinePath, shinePaint);
  }

  @override
  bool shouldRepaint(WaterPainter oldDelegate) => waterLevel != oldDelegate.waterLevel;
}
