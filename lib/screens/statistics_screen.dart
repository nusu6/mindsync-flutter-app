import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../models/mood_entry.dart';
import '../models/habit.dart';
import 'package:intl/intl.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({Key? key}) : super(key: key);

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  final _moodBox = Hive.box<MoodEntry>('moodBox');
  final _habitBox = Hive.box<Habit>('habitBox');

  // Helper to convert emoji to a numerical value for charting
  double _moodToValue(String mood) {
    switch (mood) {
      case '😄':
        return 5.0;
      case '😊':
        return 4.0;
      case '🙂':
      case '😐':
        return 3.0;
      case '😢':
        return 2.0;
      case '😭':
        return 1.5;
      case '😠':
        return 0.5;
      default:
        return 0.0;
    }
  }

  // Helper to convert chart value back to emoji
  String _valueToMood(double value) {
    switch (value.round()) {
      case 5:
        return '😄';
      case 4:
        return '😊';
      case 3:
        return '😐';
      case 2:
        return '😢';
      case 1.5:
        return '😭';
      case 0.5:
        return '😠';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistics & Insights'),
        backgroundColor: Colors.indigo,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Mood Over Last 30 Days'),
            _buildMoodChart(),
            const SizedBox(height: 32),
            _buildSectionTitle('Monthly Habit Completion'),
            _buildHabitCompletionRates(),
            const SizedBox(height: 32),
            _buildSectionTitle('Mood-Habit Correlation'),
            _buildMoodHabitCorrelations(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }

  // --- 1. Mood Over Time Chart ---
  Widget _buildMoodChart() {
    final now = DateTime.now();
    final last30Days = now.subtract(const Duration(days: 30));
    final entries = _moodBox.values
        .where((entry) => entry.date.isAfter(last30Days))
        .toList();

    if (entries.isEmpty) {
      return const Center(child: Text("Not enough mood data to show a chart."));
    }

    // Create data points for the chart
    List<FlSpot> spots = entries.map((entry) {
      return FlSpot(
        entry.date.day.toDouble(), // X-axis is the day of the month
        _moodToValue(entry.mood),   // Y-axis is the mood value
      );
    }).toList();

    return AspectRatio(
      aspectRatio: 1.7,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: LineChart(
            LineChartData(
              gridData: const FlGridData(show: true),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (value, meta) => Text(_valueToMood(value)), reservedSize: 28)),
                bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 22, getTitlesWidget: (value, meta) => Text(value.toInt().toString()))),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: true, border: Border.all(color: const Color(0xff37434d), width: 1)),
              minX: 1,
              maxX: 31,
              minY: 1,
              maxY: 5,
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  gradient: const LinearGradient(colors: [Colors.indigoAccent, Colors.blueAccent]),
                  barWidth: 5,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(show: true, gradient: LinearGradient(colors: [Colors.indigoAccent.withOpacity(0.3), Colors.blueAccent.withOpacity(0.3)])),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- 2. Habit Completion Rates ---
  Widget _buildHabitCompletionRates() {
    final habits = _habitBox.values.toList();
    if (habits.isEmpty) {
      return const Center(child: Text("No habits are being tracked yet."));
    }

    final now = DateTime.now();
    final daysInMonthSoFar = now.day;

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: habits.length,
      itemBuilder: (context, index) {
        final habit = habits[index];
        final completionsThisMonth = habit.completions
            .where((date) => date.month == now.month && date.year == now.year)
            .length;
        final percentage = (completionsThisMonth / daysInMonthSoFar).clamp(0.0, 1.0);

        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            title: Text(habit.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            trailing: CircularPercentIndicator(
              radius: 24.0,
              lineWidth: 5.0,
              percent: percentage,
              center: Text("${(percentage * 100).toInt()}%"),
              progressColor: Colors.lightGreen,
              backgroundColor: Colors.grey.shade300,
            ),
          ),
        );
      },
    );
  }

  // --- 3. Mood-Habit Correlation ---
  Widget _buildMoodHabitCorrelations() {
    final habits = _habitBox.values.toList();
    final moods = _moodBox.values.toList();

    if (habits.isEmpty || moods.isEmpty) {
      return const Center(child: Text("Not enough data for insights."));
    }

    // Create a map of dates to moods for quick lookup
    final moodMap = {
      for (var mood in moods)
        DateTime(mood.date.year, mood.date.month, mood.date.day): mood.mood
    };

    List<Widget> correlationWidgets = [];
    const positiveMoods = {'😄', '😊'};

    for (var habit in habits) {
      Map<String, int> moodCounts = {};
      for (var completionDate in habit.completions) {
        final dateKey = DateTime(completionDate.year, completionDate.month, completionDate.day);
        if (moodMap.containsKey(dateKey)) {
          final mood = moodMap[dateKey]!;
          moodCounts[mood] = (moodCounts[mood] ?? 0) + 1;
        }
      }

      if (moodCounts.length >= 3) {
        MapEntry<String, int>? topPositiveMood;
        int totalNegativeCount = 0;

        // Separate moods into positive and negative categories
        for (var entry in moodCounts.entries) {
          if (positiveMoods.contains(entry.key)) {
            if (topPositiveMood == null || entry.value > topPositiveMood.value) {
              topPositiveMood = entry;
            }
          } else {
            totalNegativeCount += entry.value;
          }
        }

        // 3. Generate an insight ONLY if a clear positive pattern exists
        // (i.e., the top positive mood occurs more often than all negative moods combined)
        if (topPositiveMood != null && topPositiveMood.value > totalNegativeCount) {
          correlationWidgets.add(
              Card(
                elevation: 2,
                color: Colors.indigo.shade50,
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: const Icon(Icons.psychology_outlined, color: Colors.indigo),
                  title: Text("Insight for '${habit.name}'", style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("Completing this habit often correlates with feeling ${topPositiveMood.key}"),
                ),
              )
          );
        }
      }
    }

    if (correlationWidgets.isEmpty) {
      return const Center(child: Text("Log more moods and habits on the same day to see insights here."));
    }

    return Column(children: correlationWidgets);
  }
}