import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/diary_entry.dart';
import '../utils/sentiment_helper.dart';

class DiaryScreen extends StatefulWidget {
  // Parameters for handling editing
  final DiaryEntry? diaryEntry;
  final dynamic entryKey;

  const DiaryScreen({Key? key, this.diaryEntry, this.entryKey}) : super(key: key);

  @override
  State<DiaryScreen> createState() => _DiaryScreenState();
}

class _DiaryScreenState extends State<DiaryScreen> {
  final _entryController = TextEditingController();
  // ✅ FIX: Allow the selected mood to be null for new entries
  String? _selectedMood;

  @override
  void initState() {
    super.initState();
    // If we are editing an existing entry, pre-fill the fields.
    // Otherwise, _selectedMood remains null.
    if (widget.diaryEntry != null) {
      _entryController.text = widget.diaryEntry!.content;
      _selectedMood = widget.diaryEntry!.mood;
    }
  }

  void _saveEntry() async {
    final text = _entryController.text.trim();
    if (text.isEmpty) {
      return;
    }

    final box = Hive.box<DiaryEntry>('diaryBox');

    // --- LOGIC FOR EDITING AN EXISTING ENTRY ---
    if (widget.diaryEntry != null) {
      widget.diaryEntry!.content = text;
      // When editing, use the mood from the manual picker. A mood must be selected.
      widget.diaryEntry!.mood = _selectedMood ?? '😐'; // Fallback to neutral
      widget.diaryEntry!.save();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Entry updated!")),
      );
      Navigator.of(context).pop();
      return;
    }

    // --- LOGIC FOR CREATING A NEW ENTRY ---

    // ✅ FIX: Check if a mood was selected manually first.
    if (_selectedMood != null) {
      // --- SAVE WITH MANUALLY SELECTED MOOD ---
      final newEntry = DiaryEntry(
        date: DateTime.now(),
        mood: _selectedMood!,
        content: text,
        note: text,
      );
      await box.add(newEntry);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Entry saved with your mood!')));
    } else {
      // --- USE SENTIMENT ANALYSIS IF NO MOOD WAS MANUALLY SELECTED ---
      final analysis = analyzeText(text);
      final detectedMoodText = mapSentimentToMood(analysis);

      final userChoice = await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          title: Text('Detected Mood: ${moodEmoji(detectedMoodText)}'),
          content: Text(
              'We detected that your mood is "$detectedMoodText".\n\nWould you like to use this mood or pick one manually?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, detectedMoodText),
              child: const Text('Use Detected Mood'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, 'manual'),
              child: const Text('Pick Manually'),
            ),
          ],
        ),
      );

      String finalMoodText = detectedMoodText;

      if (userChoice == 'manual') {
        final manuallyPickedMood = await showModalBottomSheet<String>(
          context: context,
          builder: (_) {
            final moods = ['Very Happy', 'Happy', 'Neutral', 'Sad', 'Very Sad','Natural','Angry'];
            return SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: moods
                    .map((mood) => ListTile(
                  title: Text('$mood ${moodEmoji(mood)}'),
                  onTap: () => Navigator.pop(context, mood),
                ))
                    .toList(),
              ),
            );
          },
        );

        if (manuallyPickedMood != null) {
          finalMoodText = manuallyPickedMood;
        }
      }

      final finalMoodEmoji = moodEmoji(finalMoodText);
      final newEntry = DiaryEntry(
        date: DateTime.now(),
        mood: finalMoodEmoji,
        content: text,
        note: text,
      );
      await box.add(newEntry);

      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Entry saved')));
    }

    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _entryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.diaryEntry == null ? 'New Entry' : 'Edit Entry'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: _entryController,
                maxLines: 10,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Write your thoughts...',
                  hintText: 'Select a mood below, or save without one to have it detected automatically.',
                ),
              ),
              const SizedBox(height: 20),

              // ✅ FIX: The manual mood picker is now always visible.
              const Text(
                'Or, select a mood manually:',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 10),
              _buildMoodPicker(),
              const SizedBox(height: 20),

              ElevatedButton.icon(
                onPressed: _saveEntry,
                icon: const Icon(Icons.save),
                label: const Text('Save Entry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMoodPicker() {
    final moods = ['😄', '😊', '😐', '😢', '😭', '🙂','😠'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: moods.map((emoji) {
        bool isSelected = _selectedMood == emoji;
        return GestureDetector(
          onTap: () {
            setState(() {
              // Allow toggling the mood off by tapping it again
              if (isSelected) {
                _selectedMood = null;
              } else {
                _selectedMood = emoji;
              }
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: isSelected ? Colors.deepPurple.withOpacity(0.2) : Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: Text(
              emoji,
              style: TextStyle(fontSize: isSelected ? 38 : 32),
            ),
          ),
        );
      }).toList(),
    );
  }
}