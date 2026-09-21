import 'package:flutter/material.dart';

import '../models/course_models.dart';
import '../services/course_media_store.dart';
import '../services/course_service.dart';
import 'course_media_image.dart';
import 'flag_art.dart';

/// A fixed square slot showing the Course cover, or the Course flag when the
/// Course has no cover or its cover cannot be shown. The slot never changes
/// size, so rows stay aligned whichever artwork they get.
class CourseArtwork extends StatelessWidget {
  const CourseArtwork({
    super.key,
    required this.course,
    this.size = 64,
    this.mediaStore,
  });

  final Course course;
  final double size;
  final CourseMediaStore? mediaStore;

  @override
  Widget build(BuildContext context) {
    final flag = Center(
      key: ValueKey('course-artwork-flag-${course.courseId}'),
      child: CourseFlagBadge(
        course: course,
        fallbackCode: CourseService.codeForCourse(course),
        width: size * 0.69,
        height: size * 0.48,
      ),
    );
    final hasCover = Course.coverImagePattern.hasMatch(course.coverImage);
    return SizedBox.square(
      key: ValueKey('course-artwork-${course.courseId}'),
      dimension: size,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: hasCover
            ? CourseMediaImage(
                key: ValueKey('course-artwork-cover-${course.courseId}'),
                courseId: course.courseId,
                asset: course.coverImage,
                width: size,
                height: size,
                fit: BoxFit.cover,
                // Bounded decode: a list thumbnail never needs the full cover.
                cacheWidth: (size * MediaQuery.devicePixelRatioOf(context))
                    .ceil(),
                semanticLabel: '${course.title} cover',
                missing: flag,
                mediaStore: mediaStore,
              )
            : flag,
      ),
    );
  }
}
