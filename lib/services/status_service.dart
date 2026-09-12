/// Long-term Status ranks used by QuisquisLingo.
/// Status is calculated independently for every learner + target language.
class StatusRank {
  final int index;
  final String name;
  final int threshold;
  final int? nextThreshold;
  final double progressToNext;
  const StatusRank({
    required this.index,
    required this.name,
    required this.threshold,
    required this.nextThreshold,
    required this.progressToNext,
  });
}

class StatusService {
  static const names = <String>[
    'Apprentice',
    'Wanderer',
    'Squire',
    'Wordsmith',
    'Knight',
    'Lorekeeper',
    'Language Wizard',
    'Grand Master',
    'Sage',
    'Guru',
  ];
  static const colorValues = <int>[
    0xFF2EAD5B,
    0xFF7AC943,
    0xFFF2C230,
    0xFFF28C28,
    0xFFE85D4A,
    0xFFD83A56,
    0xFFC044A4,
    0xFF8E5AC8,
    0xFF5964D8,
    0xFF2878D0,
  ];
  // Deliberately long-term progression. The old thresholds were at least ten
  // times faster and allowed sample rounds to advance Status too quickly.
  // Apprentice is the first visible Status from zero progress. The former
  // display-only Learner rank was removed without changing the thresholds of
  // Wanderer and every later rank.
  static const thresholds = <int>[
    0,
    6500,
    12000,
    20000,
    30000,
    43000,
    59000,
    79000,
    105000,
    140000,
  ];

  static const progressionExplanation =
      'Status is calculated separately for each learner and learning '
      'language. Status points are your XP plus 40 points per current streak '
      'day, 25 per distinct study day, 15 per completed Round, and 20 per '
      'Laurel. Your current Status is the highest threshold your total has '
      'reached. Every Status has a vivid color that automatically becomes '
      'your avatar T-shirt color.';

  /// Weighted score. XP is the base currency; streak, distinct study days and
  /// completed rounds reward regularity and sustained practice as well.
  int score({
    required int xp,
    required int streak,
    required int daysStudied,
    required int roundsCompleted,
    int laurelCrowns = 0,
  }) {
    final safeXp = xp.clamp(0, 100000000).toInt();
    final safeStreak = streak.clamp(0, 10000).toInt();
    final safeDays = daysStudied.clamp(0, 100000).toInt();
    final safeRounds = roundsCompleted.clamp(0, 100000).toInt();
    final safeLaurels = laurelCrowns.clamp(0, 100000).toInt();
    return safeXp +
        safeStreak * 40 +
        safeDays * 25 +
        safeRounds * 15 +
        safeLaurels * 20;
  }

  StatusRank rank({
    required int xp,
    required int streak,
    required int daysStudied,
    required int roundsCompleted,
    int laurelCrowns = 0,
  }) {
    final value = score(
      xp: xp,
      streak: streak,
      daysStudied: daysStudied,
      roundsCompleted: roundsCompleted,
      laurelCrowns: laurelCrowns,
    );
    var index = 0;
    for (var i = 0; i < thresholds.length; i++) {
      if (value >= thresholds[i]) index = i;
    }
    final next = index + 1 < thresholds.length ? thresholds[index + 1] : null;
    final progress = next == null
        ? 1.0
        : ((value - thresholds[index]) / (next - thresholds[index]))
              .clamp(0.0, 1.0)
              .toDouble();
    return StatusRank(
      index: index,
      name: names[index],
      threshold: thresholds[index],
      nextThreshold: next,
      progressToNext: progress,
    );
  }
}
