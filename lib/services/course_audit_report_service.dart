import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';

import '../models/course_models.dart';
import 'app_metadata.dart';
import 'course_audit_service.dart';
import 'custom_course_transfer_service.dart';

class CourseAuditReportService {
  CourseAuditReportService({
    Future<Directory> Function()? exportDirectory,
    Future<void> Function(String text)? copyText,
    DateTime Function()? clock,
  }) : _exportDirectory =
           exportDirectory ?? CustomCourseTransferService().transferDirectory,
       _copyText =
           copyText ?? ((text) => Clipboard.setData(ClipboardData(text: text))),
       _clock = clock ?? DateTime.now;

  final Future<Directory> Function() _exportDirectory;
  final Future<void> Function(String text) _copyText;
  final DateTime Function() _clock;

  String buildReport({
    required Course course,
    required CourseAuditResult result,
    required String scope,
    required AuditSortMode sortMode,
    DateTime? generatedAt,
  }) {
    final generated = (generatedAt ?? _clock()).toLocal();
    final ordered = result.sorted(sortMode);
    final buffer = StringBuffer()
      ..writeln('QuisquisLingo Course Audit report')
      ..writeln('Application version: ${AppMetadata.version}')
      ..writeln('Generated: ${generated.toIso8601String()}')
      ..writeln('Course name: ${course.title}')
      ..writeln('Course ID: ${course.courseId}')
      ..writeln('Audit scope: $scope')
      ..writeln('Sort mode: ${_sortLabel(sortMode)}')
      ..writeln('Errors: ${result.count(AuditSeverity.error)}')
      ..writeln('Warnings: ${result.count(AuditSeverity.warning)}')
      ..writeln('Info: ${result.count(AuditSeverity.info)}')
      ..writeln('Findings: ${result.issues.length}')
      ..writeln();

    if (ordered.isEmpty) {
      buffer.writeln('No findings.');
      return buffer.toString().trimRight();
    }

    for (var index = 0; index < ordered.length; index++) {
      final issue = ordered[index];
      final context = _contextFor(course, issue);
      buffer
        ..writeln('${index + 1}. ${issue.severity.name.toUpperCase()}')
        ..writeln('Code: ${issue.code}')
        ..writeln('Message: ${issue.message}')
        ..writeln('Location: ${issue.location}');
      if (context.lesson != null) {
        buffer.writeln(
          'Lesson: ${context.lesson!.title} (${context.lesson!.lessonId})',
        );
      }
      if (context.round != null) {
        buffer.writeln('Round: ${context.round!.title} (${context.round!.id})');
      }
      if (context.exercise != null) {
        buffer
          ..writeln(
            'Exercise: ${context.exerciseNumber} (${context.exercise!.id})',
          )
          ..writeln(
            'Exercise type: ${context.exercise!.editorTemplate} '
            '(${context.exercise!.type})',
          );
      }
      if (index + 1 < ordered.length) buffer.writeln();
    }
    return buffer.toString().trimRight();
  }

  Future<void> copyReport({
    required Course course,
    required CourseAuditResult result,
    required String scope,
    required AuditSortMode sortMode,
  }) => _copyText(
    buildReport(
      course: course,
      result: result,
      scope: scope,
      sortMode: sortMode,
    ),
  );

  Future<String> exportReport({
    required Course course,
    required CourseAuditResult result,
    required String scope,
    required AuditSortMode sortMode,
  }) async {
    final generatedAt = _clock().toLocal();
    final report = buildReport(
      course: course,
      result: result,
      scope: scope,
      sortMode: sortMode,
      generatedAt: generatedAt,
    );
    final directory = await _exportDirectory();
    final stamp = generatedAt
        .toIso8601String()
        .replaceAll(RegExp(r'[^0-9]'), '')
        .padRight(17, '0')
        .substring(0, 17);
    final coursePart = _safePart(course.title, fallback: 'course');
    final idPart = _safePart(course.courseId, fallback: 'unknown_id');
    final baseName = 'quisquislingo_audit_${coursePart}_${idPart}_$stamp';
    var output = File(
      '${directory.path}${Platform.pathSeparator}$baseName.txt',
    );
    var suffix = 2;
    while (await output.exists()) {
      output = File(
        '${directory.path}${Platform.pathSeparator}${baseName}_$suffix.txt',
      );
      suffix += 1;
    }
    await output.writeAsBytes(utf8.encode(report), flush: true);
    return output.path;
  }

  String _sortLabel(AuditSortMode mode) => switch (mode) {
    AuditSortMode.lesson => 'By Lesson',
    AuditSortMode.exerciseType => 'By Exercise type',
  };

  String _safePart(String value, {required String fallback}) {
    final safe = value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9_-]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    return safe.isEmpty ? fallback : safe;
  }

  _AuditIssueContext _contextFor(Course course, CourseAuditIssue issue) {
    Lesson? lesson;
    LearningRound? round;
    Exercise? exercise;
    int? exerciseNumber;

    for (
      var lessonIndex = 0;
      lessonIndex < course.lessons.length;
      lessonIndex++
    ) {
      final candidate = course.lessons[lessonIndex];
      final lessonPrefix = 'Lesson ${lessonIndex + 1} ·';
      if (issue.location.startsWith(lessonPrefix)) lesson = candidate;
      for (final candidateRound in candidate.rounds) {
        if (candidateRound.id == issue.roundId) {
          lesson = candidate;
          round = candidateRound;
        }
        for (var index = 0; index < candidateRound.exercises.length; index++) {
          final candidateExercise = candidateRound.exercises[index];
          if (candidateExercise.id == issue.exerciseId) {
            lesson = candidate;
            round = candidateRound;
            exercise = candidateExercise;
            exerciseNumber = index + 1;
          }
        }
      }
    }
    return _AuditIssueContext(
      lesson: lesson,
      round: round,
      exercise: exercise,
      exerciseNumber: exerciseNumber,
    );
  }
}

class _AuditIssueContext {
  const _AuditIssueContext({
    this.lesson,
    this.round,
    this.exercise,
    this.exerciseNumber,
  });

  final Lesson? lesson;
  final LearningRound? round;
  final Exercise? exercise;
  final int? exerciseNumber;
}
