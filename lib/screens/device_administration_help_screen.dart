import 'package:flutter/material.dart';

/// Help for the Device Administration page. Everything is ordinary visible
/// text so it can be read on any device, and each statement here reflects a
/// rule the app actually enforces.
class DeviceAdministrationHelpScreen extends StatelessWidget {
  const DeviceAdministrationHelpScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Device Administration Help')),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            key: const Key('admin-help-list'),
            padding: const EdgeInsets.all(16),
            children: const [
              _Section(
                title: 'What this page is',
                paragraphs: [
                  'Device Administration gathers the administrator features of this QQL installation in one place. It only exists on this device: QQL has no online account, so an admin looks after the learners and data stored here and nothing else.',
                  'Every feature on this page is also still available where it always was. Only admins can see the page.',
                ],
              ),
              _Section(
                title: 'Who is an admin',
                paragraphs: [
                  'The first learner created on a device is automatically an admin. QQL always has at least one admin. An admin can make other learners admins, and an admin can give up their own admin role as long as another admin remains.',
                ],
              ),
              _Section(
                title: 'What admins CAN do',
                bullets: [
                  'Make another learner an admin.',
                  'Delete any learner, together with that learner’s local progress and settings (see the limits below).',
                  'Reset another learner’s PIN. This removes the PIN so the learner can choose a new one. Note that until a new PIN is set, anyone can open that profile.',
                  'Change the QQL device name shown in the Learner Profiles list.',
                  'Choose whether QQL asks who is learning each time it starts.',
                  'Manage the shared image library and its descriptive metadata (Shared Image Library). It holds the images available to every course on this device, and only admins can add to or change it. Anyone who can edit a course can still add their own image to an exercise with Import custom image; that image is not added to the shared library.',
                  'Run the reset options on this page, after setting an admin PIN and entering it for each reset.',
                ],
              ),
              _Section(
                title: 'What admins CANNOT do',
                bullets: [
                  'Delete the only admin, or give up the admin role when they are the only admin. To remove the last admin, make another learner an admin first, or use “Wipe out everything”.',
                  'See any PIN. PINs are stored in a scrambled form that even QQL cannot read back. A forgotten PIN can only be reset, never recovered.',
                  'Reset their own PIN from the Learner Profiles list. Only another admin can reset an admin’s PIN.',
                  'Run any reset without a PIN. An admin who has not set a PIN cannot use the reset options at all, and the PIN is asked again for every reset.',
                  'Take ownership of courses. Being an admin gives no special right to edit or delete another person’s course. Course rights come only from being its Owner or a member of its owning Team.',
                  'Delete a learner who is the maintainer of a course, or the only Team Leader of a Team. Change the course maintainer or promote another Team Leader first.',
                  'Edit or delete the bundled official courses. They are read-only for everyone; like any learner, an admin can only fork them where their license allows it.',
                  'Manage Teams. Teams are run by their own Leads and members from Course Manager, not by device admins.',
                  'Act on other devices. Admin rights apply only to this installation.',
                  'Undo a reset or a deleted learner. Deleted data can only come back from a backup you made earlier.',
                ],
              ),
              _Section(
                title: 'Inventory',
                paragraphs: [
                  'The Inventory button lists everything QQL has stored because of what people did, so you know what a reset would remove and where your files are. For every file it shows the full location (which you can select and copy), the size, the date it was last changed and, when it can be determined, the learner it belongs to.',
                ],
                bullets: [
                  'Learners and custom courses are kept inside QQL’s own settings, not as files, so they show no path. Each course shows its maintainer or creator.',
                  'Exports and backups: learner backups, User Recovery Keys, course exports, and the course backups the Course Editor makes automatically before saving a change.',
                  'Imports and Merges: files you copied into those folders from outside QQL.',
                  'Imported images, image banks and imported audio (MP3) files: the copies QQL made in its own storage. Audio shows the course it belongs to.',
                  'Logs: the crash log, diagnostic export and session marker.',
                  'Other files in the QQL folder: anything added directly to the QuisquisLingo folder with the operating system, which QQL did not create and does not use.',
                  'Media and files that come with the app itself are not listed. Very large lists show the 500 most recent files per section.',
                ],
              ),
              _Section(
                title: 'Updates',
                paragraphs: [
                  'The Update entry opens the same page every learner can reach in Settings > Update: it checks GitHub for a newer release and shows the installation instructions. Only an admin can change “Check automatically at startup”, because it applies to the whole device.',
                  'When a newer version is found at startup, each learner is told about it once a day: the popup offers “Not today”, and reminds that learner again the next day. Other learners on the device are still told.',
                ],
              ),
              _Section(
                title: 'Ask who is learning at startup',
                paragraphs: [
                  'Off (default): QQL opens directly as the learner who used it last. This suits a device used by one person.',
                  'On: every time QQL starts, the learner list is shown and nobody is resumed automatically, so each person chooses their own profile. This suits shared devices. It has no effect when the device has only one learner. Learners with a PIN still have to enter it.',
                ],
              ),
              _Section(
                title: 'The reset options',
                paragraphs: [
                  'Resets delete data permanently. For that reason the Reset section is locked until you set your own 4-digit PIN. Each reset then walks you through: an explanation with the real numbers for this device, an offer to back up first, and finally your PIN. Nothing is deleted until you have finished every step. Remove imported media and the full wipe let you choose in the first step (see below), and the full wipe asks you to type NUKE EVERYTHING, exactly, before the PIN.',
                ],
                bullets: [
                  'Reset learner progress: clears XP, streaks and completed lessons for every learner. Learners, PINs, settings and courses stay.',
                  'Remove all learners except admins: deletes every non-admin learner and their data, and removes the Team list if it names any of them.',
                  'Remove imported media: you choose whether to remove the imported images, the imported audio files (recorded MP3 files), or both; nothing is ticked at first. It deletes only the copies QQL made in its own storage. Media that comes with QQL itself (the built-in image library, flags, icons and the bundled courses’ recordings) is part of the app and is never removed; edits to the shared image library’s tags and labels go back to the defaults. Your original files are not touched.',
                  'Remove custom courses: deletes all custom and installed courses, all Teams and all imported media, meaning every imported image and every imported recorded MP3 audio file. Learners stay.',
                  'Wipe out everything: returns QQL to a brand-new installation, including all learners and admins. You can keep the Exports, Logs and Imports folders; all three are kept unless you untick them in the first step. Imports holds the original files you copied there yourself.',
                ],
              ),
              _Section(
                title: 'Before you reset: backups',
                paragraphs: [
                  'Learner data is exported from Profile → User Data, and each backup covers only the learner who is logged in: an admin cannot export other learners’ data, so before a reset that affects other learners, ask each of them to export their own. Courses are exported one at a time from Course Manager. Exports are saved in the QuisquisLingo/Exports folder, which the full wipe keeps unless you untick it.',
                ],
              ),
              _Section(
                title: 'Forgotten PIN',
                paragraphs: [
                  'If another admin exists, they can reset your PIN from the Learner Profiles list. If you are the only admin and forget your PIN, there is no way to recover it: you cannot open your profile or use the reset options. Choose a PIN you will remember, and consider making a second person an admin.',
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _Section extends StatelessWidget {
  final String title;
  final List<String> paragraphs;
  final List<String> bullets;

  const _Section({
    required this.title,
    this.paragraphs = const [],
    this.bullets = const [],
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 6),
        for (final paragraph in paragraphs)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(paragraph),
          ),
        for (final bullet in bullets)
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('•  '),
                Expanded(child: Text(bullet)),
              ],
            ),
          ),
      ],
    ),
  );
}
