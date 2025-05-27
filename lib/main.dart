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
  List<int> _counters = List.filled(4, 0);
  List<TextEditingController> _textControllers = List.generate(
    4,
    (index) => TextEditingController(text: 'Untitled'),
  );

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
    for (var controller in _textControllers) {
      controller.dispose();
    }
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
        child: Column(
          children: [
            // Top section with water circle (2/6 of the screen)
            SizedBox(
              height: MediaQuery.of(context).size.height * 2 / 6,
              child: Center(
                child: GestureDetector(
                  onTap: () => _addWater(100),
                  onLongPress: () async {
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
                  child: SizedBox(
                    width: 200,
                    height: 200,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.blue,
                              width: 2,
                            ),
                          ),
                        ),
                        AnimatedBuilder(
                          animation: _waterAnimation,
                          builder: (context, child) {
                            return CustomPaint(
                              size: const Size(200, 200),
                              painter: WaterPainter(
                                waterLevel: _waterAnimation.value,
                              ),
                            );
                          },
                        ),
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
              ),
            ),
            // Bottom section with 5 squares (4/6 of the screen)
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: 4,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _counters[index]++;
                      });
                    },
                    onLongPress: () {
                      setState(() {
                        _counters[index] = 0;
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          GestureDetector(
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Edit Title'),
                                  content: TextField(
                                    controller: _textControllers[index],
                                    decoration: const InputDecoration(
                                      hintText: 'Enter title',
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        setState(() {});
                                        Navigator.pop(context);
                                      },
                                      child: const Text('Save'),
                                    ),
                                  ],
                                ),
                              );
                            },
                            child: Text(
                              _textControllers[index].text,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${_counters[index]}',
                            style: const TextStyle(
                              fontSize: 24,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
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
