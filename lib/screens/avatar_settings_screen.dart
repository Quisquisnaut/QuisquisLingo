import 'dart:async';

import 'package:flutter/material.dart';

import '../models/course_models.dart';
import '../services/course_service.dart';
import '../services/learner_status_events.dart';
import '../services/learner_status_level_service.dart';
import '../services/profile_service.dart';
import '../widgets/avatar_customization_content.dart';

class AvatarSettingsScreen extends StatefulWidget {
  final Course course;
  final ProfileService? profileService;
  final LearnerStatusLevelService? statusLevelService;

  const AvatarSettingsScreen({
    super.key,
    required this.course,
    this.profileService,
    this.statusLevelService,
  });

  @override
  State<AvatarSettingsScreen> createState() => _AvatarSettingsScreenState();
}

class _AvatarSettingsScreenState extends State<AvatarSettingsScreen> {
  late final ProfileService _profiles;
  late final LearnerStatusLevelService _statusLevels;
  StreamSubscription<LearnerStatusInvalidation>? _subscription;
  bool _loading = true;
  String _skinTone = 'medium';
  String _hairTone = 'dark';
  int _currentLevel = 0;
  int _loadGeneration = 0;

  @override
  void initState() {
    super.initState();
    _profiles = widget.profileService ?? ProfileService();
    _statusLevels = widget.statusLevelService ?? LearnerStatusLevelService();
    _subscription = LearnerStatusEvents.stream.listen((event) {
      if (event == LearnerStatusInvalidation.activeProfile ||
          event == LearnerStatusInvalidation.avatar ||
          event == LearnerStatusInvalidation.xp ||
          event == LearnerStatusInvalidation.activity ||
          event == LearnerStatusInvalidation.laurels ||
          event == LearnerStatusInvalidation.activeCourse) {
        _load();
      }
    });
    _load();
  }

  Future<void> _load() async {
    final generation = ++_loadGeneration;
    final skinTone = await _profiles.getSkinTone();
    final hairTone = await _profiles.getHairTone();
    var currentLevel = 0;
    try {
      currentLevel = (await _statusLevels.rankForActiveLearner(
        courseId: widget.course.courseId,
        courseCode: CourseService.codeForCourse(widget.course),
      )).index;
    } catch (_) {
      // A missing learner has the same initial presentation as zero progress.
    }
    if (!mounted || generation != _loadGeneration) return;
    setState(() {
      _skinTone = skinTone;
      _hairTone = hairTone;
      _currentLevel = currentLevel;
      _loading = false;
    });
  }

  Future<void> _setSkin(String value) async {
    await _profiles.setSkinTone(value);
    if (mounted) setState(() => _skinTone = value);
  }

  Future<void> _setHair(String value) async {
    await _profiles.setHairTone(value);
    if (mounted) setState(() => _hairTone = value);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Avatar Customization')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                AvatarCustomizationContent(
                  currentLevel: _currentLevel,
                  skinTone: _skinTone,
                  hairTone: _hairTone,
                  onSkinChanged: _setSkin,
                  onHairChanged: _setHair,
                ),
              ],
            ),
    );
  }
}
