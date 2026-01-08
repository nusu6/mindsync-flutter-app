import 'package:hive/hive.dart';

part 'diary_entry.g.dart'; // This tells Hive where to generate the file

@HiveType(typeId: 0)
class DiaryEntry extends HiveObject {


  @HiveField(0)
  DateTime date;

  @HiveField(1)
  String mood;

  @HiveField(2)
  String note;

  @HiveField(3)
  String content;

  DiaryEntry({
    required this.date,
    required this.mood,
    required this.note,
    required this.content
  });
}
