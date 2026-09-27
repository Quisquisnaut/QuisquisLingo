import 'package:flutter/material.dart';

/// Shown whenever a picture whose maker QQL does not know joins a Course
/// (Build 255 Revision 7). A picture that came with QQL, or one whose credit
/// the image library records, needs no reminder.
const imageCreditReminder =
    'Did someone else make this picture? Credit them in Course Info › Media '
    'credits: author, licence and, if you know it, where it came from.';

/// Shows [imageCreditReminder] after [lead], a sentence saying what happened.
void showImageCreditReminder(BuildContext context, {String? lead}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      key: const Key('image-credit-reminder'),
      duration: const Duration(seconds: 10),
      content: Text(
        lead == null ? imageCreditReminder : '$lead $imageCreditReminder',
      ),
    ),
  );
}
