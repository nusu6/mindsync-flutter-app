import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/diary_entry.dart';
import 'models/habit.dart';
import 'models/mood_entry.dart';
import 'screens/home_screen.dart';
import 'services/notification_service.dart';

final NotificationService notificationService = NotificationService();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await notificationService.initialize();

  await Hive.initFlutter();

  Hive.registerAdapter(DiaryEntryAdapter());
  Hive.registerAdapter(HabitAdapter());
  Hive.registerAdapter(MoodEntryAdapter());

  await Hive.openBox<DiaryEntry>('diaryBox');
  await Hive.openBox<Habit>('habitBox');
  await Hive.openBox<MoodEntry>('moodBox');

  runApp(MindSyncApp());
}

class MindSyncApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MindSync',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        scaffoldBackgroundColor: Colors.white,
      ),
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
