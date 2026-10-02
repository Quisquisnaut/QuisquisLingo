import 'package:flutter/material.dart';

import '../models/course_models.dart';
import '../screens/home_screen.dart'
    show CoursePreviewScreen, openCoursePreview;
import '../services/course_service.dart';
import 'course_artwork.dart';
import 'flag_art.dart';

/// The Course's cover, or its flag, left of a Course Editor screen's title
/// (Build 261 Revision 2, owner decisions of 1 October 2026). A tap opens the
/// learner page on [course] in preview ([CoursePreviewScreen]); its "Preview ·
/// Exit" returns to this screen with the editing session as it was.
class CoursePreviewFlag extends StatelessWidget {
  const CoursePreviewFlag({super.key, required this.course, this.size = 32});

  /// The working copy as this screen holds it.
  final Course course;
  final double size;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: 'Preview as a learner',
    child: InkWell(
      key: const Key('course-preview-flag'),
      borderRadius: BorderRadius.circular(6),
      onTap: () => openCoursePreview(context, course),
      child: Course.coverImagePattern.hasMatch(course.coverImage)
          ? CourseArtwork(course: course, size: size)
          : CourseFlagBadge(
              course: course,
              fallbackCode: CourseService.codeForCourse(course),
              width: size,
              height: size * 27 / 38,
            ),
    ),
  );
}

/// A Course Editor screen title with the preview flag before it.
class CoursePreviewTitle extends StatelessWidget {
  const CoursePreviewTitle({
    super.key,
    required this.course,
    required this.title,
  });

  final Course? course;
  final Widget title;

  @override
  Widget build(BuildContext context) {
    final course = this.course;
    if (course == null) return title;
    return Row(
      children: [
        CoursePreviewFlag(course: course),
        const SizedBox(width: 10),
        Expanded(child: title),
      ],
    );
  }
}
