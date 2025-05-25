import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => StreakProvider(),
      child: const MyApp(),
    ),
  );
}

class StreakProvider extends ChangeNotifier {
  final List<Streak> _streaks = [];
  late SharedPreferences _prefs;

  List<Streak> get streaks => _streaks;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _loadStreaks();
  }

  void _loadStreaks() {
    final streakData = _prefs.getStringList('streaks') ?? [];
    _streaks.clear();
    for (final data in streakData) {
      _streaks.add(Streak.fromJson(data));
    }
    notifyListeners();
  }

  void addStreak(String name, double target) {
    _streaks.add(Streak(name: name, target: target));
    _saveStreaks();
    notifyListeners();
  }

  void updateProgress(int index, double progress) {
    if (index >= 0 && index < _streaks.length) {
      _streaks[index].updateProgress(progress);
      _saveStreaks();
      notifyListeners();
    }
  }

  void _saveStreaks() {
    final streakData = _streaks.map((s) => s.toJson()).toList();
    _prefs.setStringList('streaks', streakData);
  }
}

class Streak {
  final String name;
  final double target;
  double currentProgress;
  final List<bool> monthlyStreak;

  Streak({
    required this.name,
    required this.target,
    this.currentProgress = 0,
    List<bool>? monthlyStreak,
  }) : monthlyStreak = monthlyStreak ?? List.filled(31, false);

  void updateProgress(double progress) {
    currentProgress = progress;
    final today = DateTime.now().day - 1;
    if (today >= 0 && today < 31) {
      monthlyStreak[today] = progress >= target;
    }
  }

  String toJson() {
    return '$name|$target|$currentProgress|${monthlyStreak.join(',')}';
  }

  factory Streak.fromJson(String json) {
    final parts = json.split('|');
    return Streak(
      name: parts[0],
      target: double.parse(parts[1]),
      currentProgress: double.parse(parts[2]),
      monthlyStreak: parts[3].split(',').map((e) => e == 'true').toList(),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Streak Zero',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
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

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    Provider.of<StreakProvider>(context, listen: false).init();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Streak Zero'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Consumer<StreakProvider>(
        builder: (context, provider, child) {
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.streaks.length,
            itemBuilder: (context, index) {
              final streak = provider.streaks[index];
              return StreakCard(streak: streak, index: index);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddStreakDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddStreakDialog(BuildContext context) {
    final nameController = TextEditingController();
    final targetController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Streak'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: targetController,
              decoration: const InputDecoration(labelText: 'Daily Target'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (nameController.text.isNotEmpty && targetController.text.isNotEmpty) {
                Provider.of<StreakProvider>(context, listen: false).addStreak(
                  nameController.text,
                  double.parse(targetController.text),
                );
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

class StreakCard extends StatelessWidget {
  final Streak streak;
  final int index;

  const StreakCard({
    super.key,
    required this.streak,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              streak.name,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: streak.currentProgress / streak.target,
              minHeight: 8,
            ),
            const SizedBox(height: 8),
            Text(
              '${streak.currentProgress.toStringAsFixed(1)} / ${streak.target}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(31, (i) {
                return Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: streak.monthlyStreak[i]
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  onPressed: () {
                    final controller = TextEditingController();
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Update Progress'),
                        content: TextField(
                          controller: controller,
                          decoration: const InputDecoration(labelText: 'Progress'),
                          keyboardType: TextInputType.number,
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () {
                              if (controller.text.isNotEmpty) {
                                Provider.of<StreakProvider>(context, listen: false)
                                    .updateProgress(index, double.parse(controller.text));
                                Navigator.pop(context);
                              }
                            },
                            child: const Text('Update'),
                          ),
                        ],
                      ),
                    );
                  },
                  icon: const Icon(Icons.edit),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
