// Ordered semantic IDs shared by all Help languages.
const editorHelpSectionIds = <String>[
  'temporarySampleContent',
  'courseEditorLockAndStructure',
  'courseEditorSearch',
  'optionalLessonLearningPaths',
  'sectionAssignmentsAndNames',
  'courseFlagSources',
  'oneCourseEditorTransaction',
  'provisionalAndExplicitParentDrafts',
  'confirmOrCancelCompleteCourse',
  'localCourseEditsAndBackups',
  'courseInfoEditorAndLicense',
  'importCustomFlag',
  'generateRoundsFromLessonGuidebook',
  'exerciseCreationWizard',
  'duplicateCopyMoveExercises',
  'exercisePreviewAndNavigation',
  'fieldHelpAndUntitledRounds',
  'audioLibrary',
  'imageBank',
  'lessonThemeIconsAndPreview',
  'exerciseImageSpecifications',
  'newExerciseTypes',
  'languageDuel',
  'listeningSpelling',
  'lessonGuidebook',
  'courseMetadataAndAuthors',
  'auditSeverityAndCodes',
  'courseAudit',
];

const courseStudioHelpSectionIds = <String>[
  'courseOrigin',
  'officialCourseUpdates',
  'createNewCourse',
  'courseCreationRules',
  'importCustomCourse',
  'exportCustomCourse',
  'courseResponsibilityPermissionsAndTeams',
  'androidDeviceBackupTechnical',
  'courseAudit',
  'auditSeverityAndCodes',
  'localCourseEditsAndBackups',
  'courseInfoEditorAndLicense',
];

const appInfoSectionIds = <String>[
  'versionAndBuild',
  'choosingAndOpeningCourses',
  'courseIdentityAndProgress',
  'progressWeekXpAndGamification',
  'streakAndFreezeRule',
  'daysStudied',
  'laurelCrowns',
  'audioSettings',
  'betaExpiry',
  'status',
  'avatarAppearance',
  'review',
  'guidebooks',
  'languageDuels',
  'sourceAndTargetLanguages',
  'exportAndImportLearnerData',
  'updates',
  'crashLogAndDiagnosticLog',
  'courseStudioAndCourseEditor',
  'courseContentAndAi',
];

const allCoursesHelpSectionIds = <String>[
  'categories',
  'courseDetails',
  'availability',
  'sortingAndCompactView',
  'personalLibrary',
  'coursesInLearnerMode',
  'importing',
  'removingPublisherCourse',
];

const courseModelHelpSectionIds = <String>[
  'status',
  'hierarchy',
  'content',
  'guidebook',
  'completionAndProgression',
  'languageDuel',
  'friendlyEditorTemplates',
];

const exercisePrimitivesHelpSectionIds = <String>[
  'status',
  'exerciseAnatomy',
  'interactions',
  'evaluations',
  'promptAndItemMedia',
  'presentationContent',
  'friendlyTemplates',
];

const jsonStructureHelpSectionIds = <String>[
  'status',
  'root',
  'guidebook',
  'lessonAndRound',
  'exerciseContent',
  'duel',
  'compatibility',
];

const deviceAdminHelpSectionIds = <String>[
  'whatThisPageIs',
  'whoIsAnAdmin',
  'whatAdminsCanDo',
  'whatAdminsCannotDo',
  'inventory',
  'qqlTools',
  'updates',
  'askWhoIsLearningAtStartup',
  'resetOptions',
  'beforeResetBackups',
  'forgottenPin',
];

const deviceAdminHelpSectionShape = <String, ({int paragraphs, int bullets})>{
  'whatThisPageIs': (paragraphs: 2, bullets: 0),
  'whoIsAnAdmin': (paragraphs: 1, bullets: 0),
  'whatAdminsCanDo': (paragraphs: 0, bullets: 7),
  'whatAdminsCannotDo': (paragraphs: 0, bullets: 10),
  'inventory': (paragraphs: 1, bullets: 7),
  'qqlTools': (paragraphs: 2, bullets: 0),
  'updates': (paragraphs: 2, bullets: 0),
  'askWhoIsLearningAtStartup': (paragraphs: 2, bullets: 0),
  'resetOptions': (paragraphs: 1, bullets: 5),
  'beforeResetBackups': (paragraphs: 1, bullets: 0),
  'forgottenPin': (paragraphs: 1, bullets: 0),
};

const debugHelpSectionIds = <String>['crashLog', 'diagnosticLog', 'privacy'];

const publisherSigningHelpSectionIds = <String>[
  'status',
  'rolesAndTools',
  'createAndProtectKey',
  'requestApproval',
  'verifyIdentityChallenge',
  'proveKeyPossession',
  'recordApproval',
  'signAndDistribute',
  'mediaRules',
  'mediaCredits',
  'importPolicy',
  'keyRotation',
  'protocolReferences',
  'dummyPublisherTesting',
];

const exerciseHelpSupplementIds = <String>[
  'answerVariants',
  'textEvaluationAndCorrections',
  'contextualComprehensionExample',
];

const exerciseHelpCategoryIds = <String>[
  'multipleChoice',
  'translation',
  'textInput',
  'matching',
  'ordering',
  'presentation',
];

const exerciseHelpPresetIds = <String>[
  'choice',
  'gap_choice',
  'icon_choice',
  'script_recognition',
  'listening_choice',
  'listening_comprehension',
  'reading_comprehension',
  'dialogue_response',
  'contextual_comprehension',
  'type_translation',
  'build_translation',
  'translation_choice_to_target',
  'translation_choice_to_source',
  'fill_blank',
  'type_missing_word',
  'listening_spelling',
  'missing_word',
  'matching',
  'word_match',
  'super_match',
  'audio_match',
  'word_order',
  'image_word',
  'flashcard',
];

/// Each visible Exercise Help field resolves to one shared guide body.
const exerciseHelpFieldKeyByPresetAndField = <String, String>{
  'choice.prompt': 'exerciseHelp.field.choice.prompt.body',
  'choice.question': 'exerciseHelp.field.choice.question.body',
  'choice.answers': 'exerciseHelp.field.choice.answers.body',
  'choice.correct': 'exerciseHelp.field.choice.correct.body',
  'choice.requiredSelections':
      'exerciseHelp.field.choice.requiredSelections.body',
  'choice.gapLayout': 'exerciseHelp.field.choice.gapLayout.body',
  'choice.tokens': 'exerciseHelp.field.choice.tokens.body',
  'choice.tts': 'exerciseHelp.field.choice.tts.body',
  'choice.image': 'exerciseHelp.field.choice.image.body',
  'gap_choice.question': 'exerciseHelp.field.gap_choice.question.body',
  'gap_choice.answers': 'exerciseHelp.field.choice.answers.body',
  'gap_choice.correct': 'exerciseHelp.field.gap_choice.correct.body',
  'gap_choice.hint': 'exerciseHelp.field.gap_choice.hint.body',
  'gap_choice.image': 'exerciseHelp.field.choice.image.body',
  'icon_choice.question': 'exerciseHelp.field.icon_choice.question.body',
  'icon_choice.answers': 'exerciseHelp.field.choice.answers.body',
  'icon_choice.correct': 'exerciseHelp.field.gap_choice.correct.body',
  'icon_choice.icons': 'exerciseHelp.field.icon_choice.icons.body',
  'icon_choice.image': 'exerciseHelp.field.choice.image.body',
  'script_recognition.scriptMode':
      'exerciseHelp.field.script_recognition.scriptMode.body',
  'script_recognition.scriptPrompt':
      'exerciseHelp.field.script_recognition.scriptPrompt.body',
  'script_recognition.scriptPromptImages':
      'exerciseHelp.field.script_recognition.scriptPromptImages.body',
  'script_recognition.scriptTextOptions':
      'exerciseHelp.field.script_recognition.scriptTextOptions.body',
  'script_recognition.scriptImageOptions':
      'exerciseHelp.field.script_recognition.scriptImageOptions.body',
  'script_recognition.scriptCorrect':
      'exerciseHelp.field.script_recognition.scriptCorrect.body',
  'listening_choice.tts': 'exerciseHelp.field.listening_choice.tts.body',
  'listening_choice.question': 'exerciseHelp.field.icon_choice.question.body',
  'listening_choice.answers': 'exerciseHelp.field.choice.answers.body',
  'listening_choice.correct': 'exerciseHelp.field.gap_choice.correct.body',
  'listening_choice.image': 'exerciseHelp.field.choice.image.body',
  'listening_comprehension.tts': 'exerciseHelp.field.choice.tts.body',
  'listening_comprehension.question':
      'exerciseHelp.field.icon_choice.question.body',
  'listening_comprehension.answers': 'exerciseHelp.field.choice.answers.body',
  'listening_comprehension.correct':
      'exerciseHelp.field.gap_choice.correct.body',
  'listening_comprehension.image': 'exerciseHelp.field.choice.image.body',
  'reading_comprehension.prompt':
      'exerciseHelp.field.reading_comprehension.prompt.body',
  'reading_comprehension.question':
      'exerciseHelp.field.icon_choice.question.body',
  'reading_comprehension.answers': 'exerciseHelp.field.choice.answers.body',
  'reading_comprehension.correct': 'exerciseHelp.field.gap_choice.correct.body',
  'reading_comprehension.image': 'exerciseHelp.field.choice.image.body',
  'dialogue_response.prompt':
      'exerciseHelp.field.dialogue_response.prompt.body',
  'dialogue_response.question': 'exerciseHelp.field.icon_choice.question.body',
  'dialogue_response.answers':
      'exerciseHelp.field.dialogue_response.answers.body',
  'dialogue_response.correct': 'exerciseHelp.field.gap_choice.correct.body',
  'dialogue_response.image': 'exerciseHelp.field.choice.image.body',
  'contextual_comprehension.contextMode':
      'exerciseHelp.field.contextual_comprehension.contextMode.body',
  'contextual_comprehension.context':
      'exerciseHelp.field.contextual_comprehension.context.body',
  'contextual_comprehension.tts': 'exerciseHelp.field.choice.tts.body',
  'contextual_comprehension.dialogue':
      'exerciseHelp.field.contextual_comprehension.dialogue.body',
  'contextual_comprehension.question':
      'exerciseHelp.field.icon_choice.question.body',
  'contextual_comprehension.answers': 'exerciseHelp.field.choice.answers.body',
  'contextual_comprehension.correct':
      'exerciseHelp.field.gap_choice.correct.body',
  'contextual_comprehension.image': 'exerciseHelp.field.choice.image.body',
  'type_translation.prompt': 'exerciseHelp.field.type_translation.prompt.body',
  'type_translation.accepted':
      'exerciseHelp.field.type_translation.accepted.body',
  'type_translation.hint': 'exerciseHelp.field.gap_choice.hint.body',
  'type_translation.image': 'exerciseHelp.field.choice.image.body',
  'build_translation.prompt': 'exerciseHelp.field.type_translation.prompt.body',
  'build_translation.tokens':
      'exerciseHelp.field.build_translation.tokens.body',
  'build_translation.correctTranslation':
      'exerciseHelp.field.build_translation.correctTranslation.body',
  'build_translation.gapLayout':
      'exerciseHelp.field.build_translation.gapLayout.body',
  'build_translation.tts': 'exerciseHelp.field.choice.tts.body',
  'build_translation.image': 'exerciseHelp.field.choice.image.body',
  'translation_choice_to_target.question':
      'exerciseHelp.field.translation_choice_to_target.question.body',
  'translation_choice_to_target.answers':
      'exerciseHelp.field.translation_choice_to_target.answers.body',
  'translation_choice_to_target.correct':
      'exerciseHelp.field.translation_choice_to_target.correct.body',
  'translation_choice_to_target.image':
      'exerciseHelp.field.translation_choice_to_target.image.body',
  'translation_choice_to_source.question':
      'exerciseHelp.field.translation_choice_to_source.question.body',
  'translation_choice_to_source.answers':
      'exerciseHelp.field.translation_choice_to_source.answers.body',
  'translation_choice_to_source.correct':
      'exerciseHelp.field.translation_choice_to_target.correct.body',
  'translation_choice_to_source.image':
      'exerciseHelp.field.translation_choice_to_target.image.body',
  'fill_blank.question': 'exerciseHelp.field.fill_blank.question.body',
  'fill_blank.accepted': 'exerciseHelp.field.fill_blank.accepted.body',
  'fill_blank.hint': 'exerciseHelp.field.gap_choice.hint.body',
  'fill_blank.tts': 'exerciseHelp.field.fill_blank.tts.body',
  'fill_blank.image': 'exerciseHelp.field.choice.image.body',
  'type_missing_word.prompt':
      'exerciseHelp.field.type_missing_word.prompt.body',
  'type_missing_word.accepted':
      'exerciseHelp.field.type_missing_word.prompt.body',
  'type_missing_word.hint': 'exerciseHelp.field.gap_choice.hint.body',
  'type_missing_word.image': 'exerciseHelp.field.choice.image.body',
  'listening_spelling.prompt':
      'exerciseHelp.field.listening_spelling.prompt.body',
  'listening_spelling.tts': 'exerciseHelp.field.choice.tts.body',
  'listening_spelling.missingWords':
      'exerciseHelp.field.listening_spelling.missingWords.body',
  'listening_spelling.image': 'exerciseHelp.field.choice.image.body',
  'missing_word.prompt': 'exerciseHelp.field.missing_word.prompt.body',
  'missing_word.tts': 'exerciseHelp.field.choice.tts.body',
  'missing_word.missingWords':
      'exerciseHelp.field.missing_word.missingWords.body',
  'missing_word.image': 'exerciseHelp.field.choice.image.body',
  'matching.prompt': 'exerciseHelp.field.matching.prompt.body',
  'matching.pairs': 'exerciseHelp.field.matching.pairs.body',
  'matching.image': 'exerciseHelp.field.choice.image.body',
  'word_match.prompt': 'exerciseHelp.field.matching.prompt.body',
  'word_match.pairs': 'exerciseHelp.field.word_match.pairs.body',
  'word_match.image': 'exerciseHelp.field.choice.image.body',
  'super_match.prompt': 'exerciseHelp.field.matching.prompt.body',
  'super_match.pairs': 'exerciseHelp.field.super_match.pairs.body',
  'super_match.image': 'exerciseHelp.field.choice.image.body',
  'audio_match.prompt': 'exerciseHelp.field.matching.prompt.body',
  'audio_match.pairs': 'exerciseHelp.field.audio_match.pairs.body',
  'audio_match.image': 'exerciseHelp.field.choice.image.body',
  'word_order.prompt': 'exerciseHelp.field.matching.prompt.body',
  'word_order.gapLayout': 'exerciseHelp.field.build_translation.gapLayout.body',
  'word_order.tokens': 'exerciseHelp.field.word_order.tokens.body',
  'word_order.order': 'exerciseHelp.field.word_order.order.body',
  'word_order.tts': 'exerciseHelp.field.choice.tts.body',
  'word_order.image': 'exerciseHelp.field.choice.image.body',
  'image_word.prompt': 'exerciseHelp.field.matching.prompt.body',
  'image_word.tokens': 'exerciseHelp.field.image_word.tokens.body',
  'image_word.order': 'exerciseHelp.field.image_word.order.body',
  'image_word.image': 'exerciseHelp.field.choice.image.body',
  'flashcard.prompt': 'exerciseHelp.field.flashcard.prompt.body',
  'flashcard.question': 'exerciseHelp.field.flashcard.question.body',
  'flashcard.tts': 'exerciseHelp.field.flashcard.tts.body',
  'flashcard.answers': 'exerciseHelp.field.flashcard.answers.body',
  'flashcard.image': 'exerciseHelp.field.choice.image.body',
};
