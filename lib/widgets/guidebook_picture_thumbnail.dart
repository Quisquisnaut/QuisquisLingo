import 'package:flutter/material.dart';

import '../models/course_models.dart';
import 'course_media_image.dart';
import 'plural_picture.dart';

/// The small picture of a GuideBook Words & Expressions entry (Build 266):
/// in the learner GuideBook, on Review vocabulary cards, in the Word Lookup
/// card and on the module page's rows. A picture marked Plural is drawn as
/// stacked copies (`PluralPicture`), so "i gatti" never shows one cat.
class GuidebookPictureThumbnail extends StatelessWidget {
  const GuidebookPictureThumbnail({
    super.key,
    required this.courseId,
    required this.picture,
    this.size = 48,
    this.semanticLabel,
  });

  final String courseId;
  final GuidebookPicture picture;
  final double size;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final decode = (size * MediaQuery.devicePixelRatioOf(context)).ceil();
    return SizedBox.square(
      dimension: size,
      child: PluralPicture.wrap(
        plural: picture.plural,
        child: CourseMediaImage(
          courseId: courseId,
          asset: picture.asset,
          width: size,
          height: size,
          cacheWidth: decode,
          semanticLabel: semanticLabel,
          missing: Icon(
            Icons.broken_image_outlined,
            size: size * .6,
            color: Theme.of(context).colorScheme.outline,
          ),
        ),
      ),
    );
  }
}
