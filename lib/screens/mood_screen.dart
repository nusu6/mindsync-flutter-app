import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../models/mood_entry.dart';

class MoodTrackerScreen extends StatefulWidget {
  const MoodTrackerScreen({Key? key}) : super(key: key);

  @override
  State<MoodTrackerScreen> createState() => _MoodTrackerScreenState();
}

class _MoodTrackerScreenState extends State<MoodTrackerScreen> {
  final _moodBox = Hive.box<MoodEntry>('moodBox');
  final List<String> _moods = ['😄', '😊', '😐', '😢', '😭', '🙂','😠'];

  void _logMood(String mood) {
    final today = DateTime.now();
    // Check if a mood is already logged for today
    final todayEntryIndex = _moodBox.values.toList().indexWhere((entry) =>
    entry.date.year == today.year &&
        entry.date.month == today.month &&
        entry.date.day == today.day); //

    if (todayEntryIndex != -1) {
      // Update today's entry
      final key = _moodBox.keyAt(todayEntryIndex);
      _moodBox.put(key, MoodEntry(date: today, mood: mood));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Today's mood updated!")),
      );
    } else {
      // Add a new entry for today
      _moodBox.add(MoodEntry(date: today, mood: mood));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Mood for today logged!")),
      );
    }
    setState(() {}); // Refresh UI
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mood Tracker'),
      ),
      body: Column(
        children: [
          // Section to log today's mood
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "How are you feeling right now?",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: _moods.map((mood) {
                    return IconButton(
                      icon: Text(mood, style: const TextStyle(fontSize: 32)),
                      onPressed: () => _logMood(mood),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const Divider(),
          // Section to show mood history
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              "Mood History",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: ValueListenableBuilder(
              valueListenable: _moodBox.listenable(),
              builder: (context, Box<MoodEntry> box, _) {
                if (box.values.isEmpty) {
                  return const Center(child: Text("No mood history yet."));
                }
                // Sort entries by date, newest first
                final sortedEntries = box.values.toList()
                  ..sort((a, b) => b.date.compareTo(a.date));

                return ListView.builder(
                  itemCount: sortedEntries.length,
                  itemBuilder: (context, index) {
                    final entry = sortedEntries[index];
                    return ListTile(
                      leading: Text(entry.mood, style: const TextStyle(fontSize: 24)),
                      title: Text(DateFormat.yMMMd().format(entry.date)),
                      subtitle: Text('Logged on ${DateFormat.jm().format(entry.date)}'),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}