import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/habit.dart';
import '../main.dart'; // To access the global notificationService
import 'habit_detail_screen.dart'; // To navigate to the history screen

class HabitTrackerScreen extends StatefulWidget {
  const HabitTrackerScreen({Key? key}) : super(key: key);

  @override
  State<HabitTrackerScreen> createState() => _HabitTrackerScreenState();
}

class _HabitTrackerScreenState extends State<HabitTrackerScreen> {
  final _habitBox = Hive.box<Habit>('habitBox');

  void _showHabitDialog({Habit? habit, int? habitKey}) {
    final _nameController = TextEditingController(text: habit?.name ?? '');
    TimeOfDay? selectedTime = habit?.reminderMinutes != null
        ? TimeOfDay(
        hour: habit!.reminderMinutes! ~/ 60,
        minute: habit.reminderMinutes! % 60)
        : null;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(habit == null ? 'Add Habit' : 'Edit Habit'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _nameController,
                    autofocus: true,
                    decoration: const InputDecoration(labelText: 'Habit Name'),
                  ),
                  const SizedBox(height: 20),
                  ListTile(
                    leading: const Icon(Icons.alarm),
                    title: Text(selectedTime?.format(context) ?? 'Set Reminder'),
                    onTap: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: selectedTime ?? TimeOfDay.now(),
                      );
                      if (time != null) {
                        setDialogState(() {
                          selectedTime = time;
                        });
                      }
                    },
                    trailing: selectedTime != null
                        ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        setDialogState(() {
                          selectedTime = null;
                        });
                      },
                    )
                        : null,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                TextButton(
                  child: const Text('Save'),
                  onPressed: () {
                    final habitName = _nameController.text.trim();
                    if (habitName.isNotEmpty) {
                      final reminderMinutes = selectedTime != null
                          ? selectedTime!.hour * 60 + selectedTime!.minute
                          : null;

                      if (habit == null) {
                        final newHabit = Habit(
                          name: habitName,
                          startDate: DateTime.now(),
                          reminderMinutes: reminderMinutes,
                        );
                        _habitBox.add(newHabit).then((key) {
                          if (selectedTime != null) {
                            notificationService.scheduleDailyNotification(
                                id: key,
                                title: 'Habit Reminder',
                                body: habitName,
                                time: selectedTime!);
                          }
                        });
                      } else {
                        habit.name = habitName;
                        habit.reminderMinutes = reminderMinutes;
                        habit.save();

                        notificationService.cancelNotification(habitKey!);
                        if (selectedTime != null) {
                          notificationService.scheduleDailyNotification(
                              id: habitKey,
                              title: 'Habit Reminder',
                              body: habitName,
                              time: selectedTime!);
                        }
                      }
                      Navigator.of(context).pop();
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Habit Tracker'),
      ),
      body: ValueListenableBuilder(
        valueListenable: _habitBox.listenable(),
        builder: (context, Box<Habit> box, _) {
          if (box.values.isEmpty) {
            return const Center(
              child: Text("No habits yet. Add one to get started!"),
            );
          }
          // Sort habits by start date, newest first
          final sortedHabits = box.values.toList()
            ..sort((a, b) => b.startDate.compareTo(a.startDate));

          return ListView.builder(
            itemCount: sortedHabits.length,
            itemBuilder: (context, index) {
              final habit = sortedHabits[index];
              final habitKey = habit.key; // Get key directly from the habit object
              final isCompleted = habit.isCompletedToday();
              final reminderTime = habit.reminderMinutes != null
                  ? TimeOfDay(
                  hour: habit.reminderMinutes! ~/ 60,
                  minute: habit.reminderMinutes! % 60)
                  : null;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => HabitDetailScreen(habit: habit),
                      ),
                    );
                  },
                  leading: Checkbox(
                    value: isCompleted,
                    onChanged: (bool? value) {
                      final today = DateTime.now();
                      // First, remove any entry for today to prevent duplicates.
                      habit.completions.removeWhere((date) =>
                      date.year == today.year &&
                          date.month == today.month &&
                          date.day == today.day);

                      // If the checkbox is now checked, add today's date to the list.
                      if (value == true) {
                        habit.completions.add(today);
                      }

                      // Save the changes to Hive.
                      habit.save();
                    },
                  ),
                  title: Text(habit.name),
                  subtitle: Row(
                    children: [
                      Text('Streak: ${habit.currentStreak} days'),
                      if (reminderTime != null) ...[
                        const SizedBox(width: 8),
                        const Icon(Icons.alarm, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(reminderTime.format(context),
                            style: const TextStyle(color: Colors.grey)),
                      ]
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.grey),
                        onPressed: () =>
                            _showHabitDialog(habit: habit, habitKey: habitKey as int?),
                      ),
                      IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            notificationService.cancelNotification(habitKey);
                            _habitBox.delete(habitKey);
                          }
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showHabitDialog(),
        child: const Icon(Icons.add),
        tooltip: 'Add Habit',
      ),
    );
  }
}