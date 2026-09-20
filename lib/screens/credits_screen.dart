import 'package:flutter/material.dart';
import '../models/course_models.dart';

class CreditsScreen extends StatelessWidget {
  final Course? course;
  const CreditsScreen({super.key, this.course});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Credits')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 28),
        children: [
          Text('Project', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 10),
          const _CreditCard(
            title: 'QuisquisLingo',
            text:
                'Project and code design: Quisquisnaut (Quisquis on Discord)\nCode generation and software development assistance: ChatGPT\n\nThe bundled courses titled AI-Slop Demo are AI-generated, unreviewed demonstrations and are not reliable learning courses. Real QuisquisLingo course content is intended to be authored and reviewed by humans. This classification does not apply to other official or custom courses.',
          ),
          const SizedBox(height: 22),
          Text(
            'Course authors',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 10),
          const _CreditCard(
            title: 'Italian course',
            text: 'Course authors: To be added',
          ),
          const SizedBox(height: 8),
          const _CreditCard(
            title: 'German course',
            text: 'Course authors: To be added',
          ),
          const SizedBox(height: 8),
          const _CreditCard(
            title: 'Spanish course',
            text: 'Course authors: To be added',
          ),
          const SizedBox(height: 8),
          const _CreditCard(
            title: 'English course (Spanish → English)',
            text: 'Course authors: To be added',
          ),
          const SizedBox(height: 8),
          const _CreditCard(
            title:
                'Welsh / Dutch / Portuguese / Finnish / Korean / Neapolitan courses',
            text:
                'Temporary AI-generated sample content; human course authors are still to be added.',
          ),
          const SizedBox(height: 22),
          ListTile(
            leading: const Icon(Icons.collections_outlined),
            title: const Text(
              'Image credits',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            subtitle: const Text(
              'Images and decorative artwork actually used by QuisquisLingo.',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ImageCreditsScreen()),
            ),
          ),
          const SizedBox(height: 14),
          Text('Sounds', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 10),
          const _CreditCard(
            title: 'Result / achievement sounds',
            text:
                'Original synthesized tones created specifically for QuisquisLingo; no third-party recordings are used. The win sound is used for Duel victories, Course Manager unlock and a newly earned laurel crown.',
          ),
          const SizedBox(height: 22),
          if (course != null) ...[
            Text(
              'Current course',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            _CreditCard(
              key: const Key('credits-current-course'),
              title: course!.title,
              text: [
                'Course author(s): ${course!.authors.isNotEmpty ? course!.authors.map((a) => '${a.name} (${a.roles.join(', ')})').join(', ') : 'Not specified'}',
                'Content license: ${course!.license.trim().isEmpty ? 'Not specified' : course!.license.trim()}',
                // The course's own media credits belong where a learner looks
                // for credits, not only inside the authoring editor.
                if (course!.mediaAttributions.isNotEmpty) ...[
                  'Media credits:',
                  for (final credit in course!.mediaAttributions)
                    [
                      '  ',
                      if (credit.title.isNotEmpty) '${credit.title} — ',
                      credit.author,
                      ', ',
                      credit.license,
                      if (credit.appliesTo.isNotEmpty) ' (${credit.appliesTo})',
                    ].join(),
                ],
              ].join('\n'),
            ),
            const SizedBox(height: 22),
          ],
          Text('Licensing', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          const Text(
            'The QuisquisLingo software source is licensed under the Mozilla Public License 2.0 (MPL-2.0). Course content, the Image Bank and other assets are not covered by the QuisquisLingo software license and retain their own stated licenses or rights. Third-party components keep their own licenses and notices. See LICENSE and THIRD_PARTY_NOTICES.md.',
          ),
        ],
      ),
    );
  }
}

class ImageCreditsScreen extends StatelessWidget {
  const ImageCreditsScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Image credits')),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 28),
      children: const [
        _CreditCard(
          title: 'Lesson theme icons',
          text:
              'The flat multicolor Lesson theme icons were generated specifically for QuisquisLingo with OpenAI ImageGen; no third-party source artwork is used. Exercise images remain separate Image Bank content. Only images actually used by the app belong in this list.',
        ),
        SizedBox(height: 8),
        _CreditCard(
          title: 'World and language-related flags',
          text:
              'The 249 ISO flags and eight shortlist flags come from lipis/flag-icons v7.5.0 (MIT). Twenty-four community or regional flags associated with languages come from Wikimedia Commons.\n\nAttribution-required artwork:\nAragonese: Willtron — CC BY-SA 3.0\nFriulian: Ipankonin — CC BY-SA 3.0\nMirandese: ItsGandaM1ke — CC BY 4.0\nSardinian: Angelus — CC BY-SA 3.0\nVenetian: F l a n k e r — CC BY-SA 3.0\n\nThe other nineteen language-related files are public domain or CC0. Exact source pages, authors, licenses and pinned checksums are recorded in assets/world_flags/LICENSE-language-related-flags.md.',
        ),
        SizedBox(height: 8),
        _CreditCard(
          title: 'Status avatars',
          text:
              'Status avatars are drawn programmatically by QuisquisLingo. Avatar skin color and Avatar hair color customize only the avatar and do not describe the learner.',
        ),
        SizedBox(height: 8),
        _CreditCard(
          title: 'Flat Image Bank',
          text:
              'Built-in flat vocabulary images are original lightweight QuisquisLingo assets. Imported course-creator images keep their own rights status and must carry any attribution required by their license.',
        ),
      ],
    ),
  );
}

class _CreditCard extends StatelessWidget {
  final String title;
  final String text;
  const _CreditCard({super.key, required this.title, required this.text});

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 5),
          SelectableText(text),
        ],
      ),
    ),
  );
}
