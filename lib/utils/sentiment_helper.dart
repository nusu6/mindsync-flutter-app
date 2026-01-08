import 'package:sentiment_dart/sentiment_dart.dart';

// ✅ FIX: Instantiate SentimentAnalyzer, not Sentiment.
//final sentiment = Sentiment();

Map<String, dynamic> analyzeText(String text) {
  // ✅ FIX: The method is analyze(), not analysis().
  final result = Sentiment.analysis(text);

  // Convert SentimentResult to a simple Map for easier handling
  return {
    'score': result.score,
    'comparative': result.comparative,
    //'positive': result.positive,
    //'negative': result.negative,
  };
}

String mapSentimentToMood(Map<String, dynamic> result) {
  final comp = (result['comparative'] is num)
      ? (result['comparative'] as num).toDouble()
      : 0.0;
  if (comp >= 0.5) return 'Very Happy';
  if (comp >= 0.2) return 'Happy';
  if (comp > -0.2) return 'Neutral';
  if (comp > -0.5) return 'Sad';
  return 'Very Sad';
}

String moodEmoji(String mood) {
  switch (mood) {
    case 'Very Happy':
      return '😄';
    case 'Happy':
      return '😊';
    case 'Neutral':
      return '😐';
    case 'Sad':
      return '😢';
    case 'Very Sad':
      return '😭';
    case 'Angry':
      return '😠';
    default:
      return '🙂';
  }
}