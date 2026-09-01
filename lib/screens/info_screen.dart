import 'package:flutter/material.dart';
import '../services/alpha_lifecycle_service.dart';
import 'credits_screen.dart';

/// Human-readable explanation of learning metrics and game rules.
class InfoScreen extends StatelessWidget {
  const InfoScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Info')),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
      children: [
        Semantics(
          image: true,
          label: 'QuisquisLingo logo',
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Image.asset(
              'assets/branding/quisquislingo_logo.png',
              key: const Key('app-info-full-logo'),
              width: double.infinity,
              height: 96,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
            ),
          ),
        ),
        _InfoSection(
          title: 'Choosing and opening courses',
          body:
              'The learner page course selector lists the current course, recently opened courses, bundled courses and My custom courses. Each learner resumes the last Lesson selected in that course, or the first Lesson when no saved selection is valid. Use the Lesson selector to see the complete course.',
        ),
        _InfoSection(
          title: 'Course identity and progress',
          body:
              'Every course has an immutable globally unique Course ID. Updates to the same course keep that ID and retain course progress. Importing a course with an existing Course ID lets you replace or update it, create a separate derived copy with a new ID, or cancel. Derived copies may record their parent Course ID and source version. Course completions, Review history, laurels and Language Duel wins are separate per Course ID. Language XP, streaks and study days remain shared by target language, while Week XP remains a total across all courses and languages.',
        ),
        _InfoSection(
          title: 'Progress, Week XP and Gamification',
          body:
              'Language XP, streak, total study days and Status are stored separately for each learner and target language. Completed Rounds and laurel crowns are stored separately for each learner and Course ID. Week XP is different: it is the total XP earned by that learner across all courses during the current week. Profile > Gamification contains Weekly XP Target · All courses, Last Week XP · All courses and the Local leaderboard · All courses. Last Week XP refers to the previous completed week; tap your own Last Week XP to see the XP breakdown for each course. The local leaderboard ranks participating learner profiles on this device by their total XP across all courses during that same completed week. Participation can be turned off without deleting the learner’s XP history.',
        ),
        _InfoSection(
          title: 'Streak and the freeze rule',
          body:
              'Your streak increases when you study that language on a new day. If you spend a day studying a different language, this language streak is frozen: it does not increase and it does not reset. A full day with no study in any language breaks active streaks.',
        ),
        _InfoSection(
          title: 'Days studied',
          body:
              'This is the total number of distinct calendar days on which you studied the selected language. Several rounds on the same day still count as one study day.',
        ),
        _InfoSection(
          title: 'Laurel crowns',
          body:
              'A round earns a laurel crown when you complete one full attempt with zero errors. This can happen from the normal course path or from Review. Once earned, the crown is permanent even if a later attempt contains errors. A newly earned crown also plays the victory sound when sound effects are enabled.',
        ),
        _InfoSection(
          title: 'Skipping TTS exercises',
          body:
              'Settings > TTS Settings can skip every exercise that uses text-to-speech. If you complete the remaining exercises with zero errors, the round gets a separate leaf-style completion mark rather than a laurel crown. If you later complete the full round with TTS enabled and zero errors, the normal permanent laurel crown is awarded.',
        ),
        _InfoSection(
          title: 'Alpha expiry',
          body: AlphaLifecycleService.isAlphaBuild
              ? 'This is a time-limited alpha build. It expires on ${AlphaLifecycleService.expiryIsoDate}. After expiry, learner exercises and Review are blocked until a newer alpha is installed. Local progress, courses, course edits and settings are not deleted, and Course Editor remains available.'
              : 'This is not a time-limited alpha build.',
        ),
        _InfoSection(
          title: 'Status',
          body:
              'Status is a long-term rank calculated separately for each language from XP, streak, total study days, completed rounds and laurel crowns. Progression is deliberately slow. The ranks and level numbers are Apprentice (lev. 0), Wanderer (lev. 1), Squire (lev. 2), Wordsmith (lev. 3), Knight (lev. 4), Lorekeeper (lev. 5), Language Wizard (lev. 6), Grand Master (lev. 7), Sage (lev. 8) and Guru (lev. 9).',
        ),
        _InfoSection(
          title: 'Avatar appearance',
          body:
              'Profile > Avatar contains Avatar skin color and Avatar hair color. These controls customize only the profile avatar. They do not describe the learner. The same avatar appearance is used across languages, while Status itself changes by language.',
        ),
        _InfoSection(
          title: 'Review',
          body:
              'QuisquisLingo remembers up to 50 distinct recent Rounds for each learner and Course ID. Review prioritizes Rounds where the latest attempt contained more errors. Ties are ordered by recency. Repeating a Round updates its latest error count and can also earn a permanent laurel crown.',
        ),
        _InfoSection(
          title: 'Guidebooks',
          body:
              'Every Lesson has its own GuideBook with explanations and reference material. The GuideBook is the first node on the current Lesson path and opens only when you select it.',
        ),
        _InfoSection(
          title: 'Language Duels',
          body:
              'Each Lesson has its own Duel. A standard Duel uses 25 suitable exercises from that Lesson and starts with 4 lives. Each incorrect answer costs one life. There is no score or separate pass threshold: complete all 25 questions before losing all four lives to win and unlock the next Lesson. If the Lesson does not contain 25 suitable exercises, its Duel is simply unavailable.',
        ),
        _InfoSection(
          title: 'Source and target languages',
          body:
              'The target language is the language you are learning. The source language is used for explanations and translations. Most sample courses use English as source; the English sample course uses Spanish as source.',
        ),
        _InfoSection(
          title: 'Export and import learner data',
          body:
              'Settings > User Data > Export my data creates a backup of the active learner profile, including learner-specific progress and preferences. It is saved directly in Documents/QuisquisLingo/Exports with an automatic filename; there is no Save As dialog. If that filename already exists, QuisquisLingo adds _2, _3 and later numeric suffixes. To import learner data, copy a supported backup to Documents/QuisquisLingo/Exports/learner_import.json and then choose Settings > User Data > Import my data. Course Editor projects, Image Bank packages and Audio Packs are separate authoring resources and are not part of this learner backup.',
        ),
        _InfoSection(
          title: 'Updates',
          body:
              'At the bottom of Settings, Current version is shown immediately before Update. Settings > Update displays the official QuisquisLingo GitHub repository https://github.com/Quisquisnaut/QuisquisLingo, lets you check the latest published GitHub Release manually, and can optionally check automatically at startup. Automatic checks are off by default. Update checks send no learner data or course data and never download or install software. If a newer release exists, the page shows release information and installation guidance in the fixed order Windows, macOS, Linux antiX, Android, iOS and Web, marking platforms that have no matching published release asset as not currently available.',
        ),
        _InfoSection(
          title: 'Crash Log and Diagnostic Log',
          body:
              'The Crash Log and Diagnostic Log are separate. The Crash Log is an automatic file created at app startup and updated after uncaught errors; Settings shows its actual path. The Diagnostic Log stores technical troubleshooting events internally and is not created as a file automatically. In Settings, use Export Diagnostic Log to write a snapshot to Documents/QuisquisLingo/Logs/quisquislingo_diagnostic_log.txt. Clearing the Diagnostic Log does not delete or reset the Crash Log.',
        ),
        _InfoSection(
          title: 'Course Editor',
          body:
              'For instructions on creating, editing, importing or exporting courses and using authoring tools, open Course Editor Help from inside the Course Editor.',
        ),
        _InfoSection(
          title: 'Course content and AI',
          body:
              'AI assistance is used only for software development. Official language courses and their educational content are created by human authors.',
        ),
        OutlinedButton.icon(
          onPressed: () => Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const CreditsScreen())),
          icon: const Icon(Icons.attribution_outlined),
          label: const Text('App and image credits'),
        ),
      ],
    ),
  );
}

class _InfoSection extends StatelessWidget {
  final String title;
  final String body;
  const _InfoSection({required this.title, required this.body});

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 12),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(body),
        ],
      ),
    ),
  );
}
