import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mindsync/screens/sticker_screen.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

// --- Import your existing files ---
import '../models/diary_entry.dart';
import 'diary_screen.dart';
import 'habit_screen.dart';
import 'mood_screen.dart';
import 'breathing_screen.dart';
import 'statistics_screen.dart';

// --- Helper: Mood Colors ---
Color _getMoodColor(String mood) {
  switch (mood) {
    case '😄':
    case '😊': return const Color(0xFF81C784); // Soft Green
    case '😐':
    case '🙂': return const Color(0xFF64B5F6); // Soft Blue
    case '😢':
    case '😭': return const Color(0xFFF06292); // Soft Pink
    case '😠': return const Color(0xFFE57373); // Soft Red
    default: return const Color(0xFF4DB6AC);   // Teal
  }
}

// ==========================================
// MAIN NAVIGATION CONTAINER
// ==========================================
class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const HomeDashboardTab(),
    const CalendarViewTab(),
    const StatisticsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.pink.shade200,
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      // ✅ REMOVED: FloatingActionButton is gone.
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        backgroundColor: Colors.white,
        elevation: 3,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_filled),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'Calendar',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Insights',
          ),
        ],
      ),
    );
  }
}

// ==========================================
// TAB 1: HOME DASHBOARD
// ==========================================
class HomeDashboardTab extends StatelessWidget {
  const HomeDashboardTab({Key? key}) : super(key: key);

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: CustomScrollView(
        slivers: [
          // 1. Header Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 30, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getGreeting(),
                    style: TextStyle(fontSize: 16, color: Colors.grey[600], fontWeight: FontWeight.w500),
                  ),
                  const Text(
                    "MindSync",
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                ],
              ),
            ),
          ),

          // 2. Wellness Tools (Horizontal Scroll) WITH NEW ENTRY BUTTON
          SliverToBoxAdapter(
            child: Container(
              height: 110,
              margin: const EdgeInsets.only(bottom: 20),
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  // ✅ NEW: "Add Entry" is now a card here
                  _buildToolCard(
                      context, "New Entry", Icons.edit_note, Colors.deepPurple,
                          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DiaryScreen()))
                  ),
                  _buildToolCard(
                      context, "Mood", Icons.sentiment_satisfied_alt, Colors.orangeAccent,
                          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MoodTrackerScreen()))
                  ),
                  _buildToolCard(
                      context, "Habits", Icons.check_circle_outline, Colors.green,
                          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HabitTrackerScreen()))
                  ),

                  _buildToolCard(
                      context, "Breathe", Icons.air, Colors.teal,
                          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BreathingScreen()))
                  ),
    _buildToolCard(
    context, "Stickers", Icons.star_outline_rounded, Colors.pinkAccent,
    () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StickerGalleryScreen()))
    ),
                ],
              ),
            ),
          ),

          // 3. Section Title
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Recent Journals", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  TextButton(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const FullHistoryScreen()));
                    },
                    child: const Text("View All"),
                  ),
                ],
              ),
            ),
          ),

          // 4. Recent Entries List
          ValueListenableBuilder(
            valueListenable: Hive.box<DiaryEntry>('diaryBox').listenable(),
            builder: (context, Box<DiaryEntry> box, _) {
              final entries = box.values.toList()..sort((a, b) => b.date.compareTo(a.date));
              final recentEntries = entries.take(5).toList();

              if (recentEntries.isEmpty) {
                return SliverToBoxAdapter(child: _buildEmptyState());
              }

              return SliverList(
                delegate: SliverChildBuilderDelegate(
                      (context, index) => _DiaryEntryCard(entry: recentEntries[index], box: box),
                  childCount: recentEntries.length,
                ),
              );
            },
          ),

          const SliverPadding(padding: EdgeInsets.only(bottom: 20)),
        ],
      ),
    );
  }

  Widget _buildToolCard(BuildContext context, String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: const [
          Icon(Icons.book, size: 40, color: Colors.grey),
          SizedBox(height: 10),
          Text("No entries yet", style: TextStyle(fontSize: 16, color: Colors.grey)),
        ],
      ),
    );
  }
}

// ==========================================
// TAB 2: CALENDAR TAB
// ==========================================
class CalendarViewTab extends StatefulWidget {
  const CalendarViewTab({Key? key}) : super(key: key);

  @override
  State<CalendarViewTab> createState() => _CalendarViewTabState();
}

class _CalendarViewTabState extends State<CalendarViewTab> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
            ),
            child: TableCalendar<DiaryEntry>(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              calendarFormat: _calendarFormat,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              },
              onFormatChanged: (format) {
                if (_calendarFormat != format) setState(() => _calendarFormat = format);
              },
              onPageChanged: (focusedDay) => _focusedDay = focusedDay,
              headerStyle: const HeaderStyle(formatButtonVisible: false, titleCentered: true),
              calendarStyle: const CalendarStyle(
                todayDecoration: BoxDecoration(color: Colors.deepPurpleAccent, shape: BoxShape.circle),
                selectedDecoration: BoxDecoration(color: Colors.deepPurple, shape: BoxShape.circle),
                markerDecoration: BoxDecoration(color: Colors.orange, shape: BoxShape.circle),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 20, bottom: 10),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Entries for ${DateFormat.MMMEd().format(_selectedDay!)}",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87),
              ),
            ),
          ),
          Expanded(
            child: ValueListenableBuilder(
              valueListenable: Hive.box<DiaryEntry>('diaryBox').listenable(),
              builder: (context, Box<DiaryEntry> box, _) {
                final dailyEntries = box.values.where((entry) {
                  return isSameDay(entry.date, _selectedDay);
                }).toList();

                if (dailyEntries.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.edit_off, size: 40, color: Colors.grey),
                        SizedBox(height: 10),
                        Text('Nothing written this day', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: dailyEntries.length,
                  itemBuilder: (context, index) {
                    return _DiaryEntryCard(entry: dailyEntries[index], box: box);
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

// ==========================================
// FULL HISTORY SCREEN WITH FILTER
// ==========================================
class FullHistoryScreen extends StatefulWidget {
  const FullHistoryScreen({Key? key}) : super(key: key);

  @override
  State<FullHistoryScreen> createState() => _FullHistoryScreenState();
}

class _FullHistoryScreenState extends State<FullHistoryScreen> {
  String? selectedMood;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text("All Memories", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: [
          // ✅ NEW: Filter Button / Section
          Container(
            color: Colors.white,
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Filter by Mood", style: TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 5),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedMood,
                      hint: const Text("Show All"),
                      isExpanded: true,
                      icon: const Icon(Icons.filter_list),
                      items: [
                        const DropdownMenuItem(value: null, child: Text("Show All Entries")),
                        ...['😄', '😊', '😐', '😢', '😭', '🙂', '😠'].map((mood) {
                          return DropdownMenuItem(
                              value: mood,
                              child: Row(
                                children: [
                                  Text(mood, style: const TextStyle(fontSize: 20)),
                                  const SizedBox(width: 10),
                                  Text("Mood: $mood"),
                                ],
                              )
                          );
                        }).toList(),
                      ],
                      onChanged: (val) {
                        setState(() {
                          selectedMood = val;
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Filtered List
          Expanded(
            child: ValueListenableBuilder(
              valueListenable: Hive.box<DiaryEntry>('diaryBox').listenable(),
              builder: (context, Box<DiaryEntry> box, _) {
                // Apply Filter
                final entries = box.values.where((entry) {
                  if (selectedMood == null) return true;
                  return entry.mood == selectedMood;
                }).toList()
                  ..sort((a, b) => b.date.compareTo(a.date));

                if (entries.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.filter_alt_off, size: 50, color: Colors.grey),
                        SizedBox(height: 10),
                        Text("No matching entries found.", style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(top: 10),
                  itemCount: entries.length,
                  itemBuilder: (context, index) => _DiaryEntryCard(entry: entries[index], box: box),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// REUSABLE: PRETTY ENTRY CARD
// ==========================================
class _DiaryEntryCard extends StatelessWidget {
  final DiaryEntry entry;
  final Box<DiaryEntry> box;

  const _DiaryEntryCard({Key? key, required this.entry, required this.box}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.grey.shade200, blurRadius: 10, offset: const Offset(0, 5)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => DiaryScreen(diaryEntry: entry, entryKey: entry.key)));
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Mood Indicator
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _getMoodColor(entry.mood).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(entry.mood, style: const TextStyle(fontSize: 24)),
                ),
                const SizedBox(width: 16),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat('EEEE, MMM d').format(entry.date),
                        style: TextStyle(color: Colors.grey[600], fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        entry.content,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 15, height: 1.4, color: Colors.black87),
                      ),
                    ],
                  ),
                ),
                // Time & Menu
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      DateFormat('j:mm a').format(entry.date),
                      style: TextStyle(color: Colors.grey[400], fontSize: 10),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () => _deleteEntry(context, entry.key),
                      child: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent),
                    )
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _deleteEntry(BuildContext context, dynamic key) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Memory?"),
        content: const Text("This cannot be undone."),
        actions: [
          TextButton(child: const Text("Cancel"), onPressed: () => Navigator.pop(ctx)),
          TextButton(
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
            onPressed: () {
              box.delete(key);
              Navigator.pop(ctx);
            },
          ),
        ],
      ),
    );
  }
}