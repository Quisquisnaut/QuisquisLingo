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
  'storiesAndStoryWizard',
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
  'primitives',
  'primitiveOptions',
  'layouts',
  'evaluationModes',
  'promptAndItemMedia',
  'presentationContent',
  'presets',
  'canonicalEditor',
  'stories',
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
  'canonicalEditor',
];

const exerciseHelpCategoryIds = <String>[
  'vocabulary',
  'grammarAndSentences',
  'listening',
  'readingAndDialogue',
  'picturesAndCharacters',
  'cardsAndNotes',
  'comingLater',
];

const exerciseHelpPresetIds = <String>[
  'translation_choice_to_target',
  'translation_choice_to_source',
  'type_translation_to_target',
  'type_translation_to_source',
  'build_translation_to_target',
  'build_translation_to_source',
  'word_match',
  'super_match',
  'flashcard',
  'choice_target',
  'choice_source',
  'gap_choice',
  'type_missing_word',
  'word_order',
  'listening_answer_target',
  'listening_answer_source',
  'listening_spelling',
  'missing_word',
  'audio_match',
  'reading_answer_target',
  'reading_answer_source',
  'icon_choice',
  'script_recognition',
  'image_word',
  'picture_flashcard',
  'true_false',
  'gap_choice_inline',
  'complete_text',
  'missing_letters',
  'gap_blocks',
  'sentence_order',
  'sort_into_groups',
  'fill_the_slots',
  'listening_image_choice',
  'spell_heard',
  'picture_choice',
  'picture_name',
  'spell_word',
  'picture_word_match',
  'note_card',
  'dialogue_line',
  'story_cover',
];

/// Each visible Exercise Help field resolves to one shared guide body.
const exerciseHelpFieldKeyByPresetAndField = <String, String>{
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
  'type_translation_to_target.prompt':
      'exerciseHelp.field.type_translation.prompt.body',
  'type_translation_to_target.accepted':
      'exerciseHelp.field.type_translation.accepted.body',
  'type_translation_to_target.hint': 'exerciseHelp.field.gap_choice.hint.body',
  'type_translation_to_target.image': 'exerciseHelp.field.choice.image.body',
  'type_translation_to_source.prompt':
      'exerciseHelp.field.type_translation_to_source.prompt.body',
  'type_translation_to_source.accepted':
      'exerciseHelp.field.type_translation_to_source.accepted.body',
  'type_translation_to_source.hint': 'exerciseHelp.field.gap_choice.hint.body',
  'type_translation_to_source.image': 'exerciseHelp.field.choice.image.body',
  'build_translation_to_target.prompt':
      'exerciseHelp.field.type_translation.prompt.body',
  'build_translation_to_target.tokens':
      'exerciseHelp.field.build_translation.tokens.body',
  'build_translation_to_target.correctTranslation':
      'exerciseHelp.field.build_translation.correctTranslation.body',
  'build_translation_to_target.gapLayout':
      'exerciseHelp.field.build_translation.gapLayout.body',
  'build_translation_to_target.tts': 'exerciseHelp.field.choice.tts.body',
  'build_translation_to_target.image': 'exerciseHelp.field.choice.image.body',
  'build_translation_to_source.prompt':
      'exerciseHelp.field.type_translation_to_source.prompt.body',
  'build_translation_to_source.tokens':
      'exerciseHelp.field.build_translation_to_source.tokens.body',
  'build_translation_to_source.correctTranslation':
      'exerciseHelp.field.build_translation_to_source.correctTranslation.body',
  'build_translation_to_source.gapLayout':
      'exerciseHelp.field.build_translation.gapLayout.body',
  'build_translation_to_source.tts': 'exerciseHelp.field.choice.tts.body',
  'build_translation_to_source.image': 'exerciseHelp.field.choice.image.body',
  'word_match.prompt': 'exerciseHelp.field.matching.prompt.body',
  'word_match.pairs': 'exerciseHelp.field.word_match.pairs.body',
  'word_match.image': 'exerciseHelp.field.choice.image.body',
  'super_match.prompt': 'exerciseHelp.field.matching.prompt.body',
  'super_match.pairs': 'exerciseHelp.field.super_match.pairs.body',
  'super_match.image': 'exerciseHelp.field.choice.image.body',
  'flashcard.prompt': 'exerciseHelp.field.flashcard.prompt.body',
  'flashcard.question': 'exerciseHelp.field.flashcard.question.body',
  'flashcard.readAloud': 'exerciseHelp.field.flashcard.readAloud.body',
  'flashcard.tts': 'exerciseHelp.field.flashcard.tts.body',
  'flashcard.answers': 'exerciseHelp.field.flashcard.answers.body',
  'flashcard.image': 'exerciseHelp.field.choice.image.body',
  'choice_target.prompt': 'exerciseHelp.field.choice.prompt.body',
  'choice_target.question': 'exerciseHelp.field.choice.question.body',
  'choice_target.answers': 'exerciseHelp.field.choice.answers.body',
  'choice_target.correct': 'exerciseHelp.field.choice.correct.body',
  'choice_target.requiredSelections':
      'exerciseHelp.field.choice.requiredSelections.body',
  'choice_target.gapLayout': 'exerciseHelp.field.choice.gapLayout.body',
  'choice_target.tokens': 'exerciseHelp.field.choice.tokens.body',
  'choice_target.tts': 'exerciseHelp.field.choice.tts.body',
  'choice_target.image': 'exerciseHelp.field.choice.image.body',
  'choice_source.prompt': 'exerciseHelp.field.choice.prompt.body',
  'choice_source.question': 'exerciseHelp.field.choice_source.question.body',
  'choice_source.answers': 'exerciseHelp.field.choice_source.answers.body',
  'choice_source.correct': 'exerciseHelp.field.choice.correct.body',
  'choice_source.requiredSelections':
      'exerciseHelp.field.choice.requiredSelections.body',
  'choice_source.gapLayout': 'exerciseHelp.field.choice.gapLayout.body',
  'choice_source.tokens': 'exerciseHelp.field.choice.tokens.body',
  'choice_source.tts': 'exerciseHelp.field.choice.tts.body',
  'choice_source.image': 'exerciseHelp.field.choice.image.body',
  'gap_choice.question': 'exerciseHelp.field.gap_choice.question.body',
  'gap_choice.answers': 'exerciseHelp.field.choice.answers.body',
  'gap_choice.correct': 'exerciseHelp.field.gap_choice.correct.body',
  'gap_choice.hint': 'exerciseHelp.field.gap_choice.hint.body',
  'gap_choice.image': 'exerciseHelp.field.choice.image.body',
  'type_missing_word.revealFirstLetter':
      'exerciseHelp.field.type_missing_word.revealFirstLetter.body',
  'type_missing_word.prompt':
      'exerciseHelp.field.type_missing_word.prompt.body',
  'type_missing_word.accepted':
      'exerciseHelp.field.type_missing_word.prompt.body',
  'type_missing_word.hint': 'exerciseHelp.field.gap_choice.hint.body',
  'type_missing_word.image': 'exerciseHelp.field.choice.image.body',
  'word_order.prompt': 'exerciseHelp.field.matching.prompt.body',
  'word_order.gapLayout': 'exerciseHelp.field.build_translation.gapLayout.body',
  'word_order.tokens': 'exerciseHelp.field.word_order.tokens.body',
  'word_order.order': 'exerciseHelp.field.word_order.order.body',
  'word_order.tts': 'exerciseHelp.field.choice.tts.body',
  'word_order.image': 'exerciseHelp.field.choice.image.body',
  'listening_answer_target.tts': 'exerciseHelp.field.listening_choice.tts.body',
  'listening_answer_target.question':
      'exerciseHelp.field.icon_choice.question.body',
  'listening_answer_target.answers': 'exerciseHelp.field.choice.answers.body',
  'listening_answer_target.correct':
      'exerciseHelp.field.gap_choice.correct.body',
  'listening_answer_target.image': 'exerciseHelp.field.choice.image.body',
  'listening_answer_source.tts': 'exerciseHelp.field.listening_choice.tts.body',
  'listening_answer_source.question':
      'exerciseHelp.field.choice_source.question.body',
  'listening_answer_source.answers':
      'exerciseHelp.field.choice_source.answers.body',
  'listening_answer_source.correct':
      'exerciseHelp.field.gap_choice.correct.body',
  'listening_answer_source.image': 'exerciseHelp.field.choice.image.body',
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
  'audio_match.prompt': 'exerciseHelp.field.matching.prompt.body',
  'audio_match.pairs': 'exerciseHelp.field.audio_match.pairs.body',
  'audio_match.image': 'exerciseHelp.field.choice.image.body',
  'reading_answer_target.prompt':
      'exerciseHelp.field.reading_answer.prompt.body',
  'reading_answer_target.tts': 'exerciseHelp.field.choice.tts.body',
  'reading_answer_target.dialogue':
      'exerciseHelp.field.contextual_comprehension.dialogue.body',
  'reading_answer_target.question':
      'exerciseHelp.field.icon_choice.question.body',
  'reading_answer_target.answers': 'exerciseHelp.field.choice.answers.body',
  'reading_answer_target.correct': 'exerciseHelp.field.gap_choice.correct.body',
  'reading_answer_target.image': 'exerciseHelp.field.choice.image.body',
  'reading_answer_source.prompt':
      'exerciseHelp.field.reading_answer.prompt.body',
  'reading_answer_source.tts': 'exerciseHelp.field.choice.tts.body',
  'reading_answer_source.dialogue':
      'exerciseHelp.field.contextual_comprehension.dialogue.body',
  'reading_answer_source.question':
      'exerciseHelp.field.choice_source.question.body',
  'reading_answer_source.answers':
      'exerciseHelp.field.choice_source.answers.body',
  'reading_answer_source.correct': 'exerciseHelp.field.gap_choice.correct.body',
  'reading_answer_source.image': 'exerciseHelp.field.choice.image.body',
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
  'image_word.prompt': 'exerciseHelp.field.matching.prompt.body',
  'image_word.order': 'exerciseHelp.field.image_word.order.body',
  'image_word.image': 'exerciseHelp.field.choice.image.body',
  'picture_flashcard.prompt': 'exerciseHelp.field.flashcard.prompt.body',
  'picture_flashcard.question': 'exerciseHelp.field.flashcard.question.body',
  'picture_flashcard.readAloud': 'exerciseHelp.field.flashcard.readAloud.body',
  'picture_flashcard.tts': 'exerciseHelp.field.flashcard.tts.body',
  'picture_flashcard.answers': 'exerciseHelp.field.flashcard.answers.body',
  'picture_flashcard.image': 'exerciseHelp.field.choice.image.body',
  'true_false.question': 'exerciseHelp.field.true_false.question.body',
  'true_false.tts': 'exerciseHelp.field.choice.tts.body',
  'true_false.answers': 'exerciseHelp.field.true_false.answers.body',
  'true_false.correct': 'exerciseHelp.field.gap_choice.correct.body',
  'true_false.image': 'exerciseHelp.field.choice.image.body',
  'gap_choice_inline.prompt': 'exerciseHelp.field.matching.prompt.body',
  'gap_choice_inline.gapLayout': 'exerciseHelp.field.choice.gapLayout.body',
  'gap_choice_inline.tokens': 'exerciseHelp.field.choice.tokens.body',
  'gap_choice_inline.tts': 'exerciseHelp.field.choice.tts.body',
  'gap_choice_inline.image': 'exerciseHelp.field.choice.image.body',
  'complete_text.prompt': 'exerciseHelp.field.complete_text.prompt.body',
  'complete_text.missingWords':
      'exerciseHelp.field.complete_text.missingWords.body',
  'complete_text.image': 'exerciseHelp.field.choice.image.body',
  'missing_letters.prompt': 'exerciseHelp.field.missing_letters.prompt.body',
  'missing_letters.tts': 'exerciseHelp.field.choice.tts.body',
  'missing_letters.hint': 'exerciseHelp.field.gap_choice.hint.body',
  'missing_letters.image': 'exerciseHelp.field.choice.image.body',
  'gap_blocks.prompt': 'exerciseHelp.field.matching.prompt.body',
  'gap_blocks.gapLayout': 'exerciseHelp.field.build_translation.gapLayout.body',
  'gap_blocks.tokens': 'exerciseHelp.field.gap_blocks.tokens.body',
  'gap_blocks.tts': 'exerciseHelp.field.choice.tts.body',
  'gap_blocks.image': 'exerciseHelp.field.choice.image.body',
  'sentence_order.prompt': 'exerciseHelp.field.matching.prompt.body',
  'sentence_order.tokens': 'exerciseHelp.field.sentence_order.tokens.body',
  'sentence_order.order': 'exerciseHelp.field.sentence_order.order.body',
  'sentence_order.image': 'exerciseHelp.field.choice.image.body',
  'listening_image_choice.tts': 'exerciseHelp.field.listening_choice.tts.body',
  'listening_image_choice.question':
      'exerciseHelp.field.icon_choice.question.body',
  'listening_image_choice.answers': 'exerciseHelp.field.choice.answers.body',
  'listening_image_choice.correct':
      'exerciseHelp.field.gap_choice.correct.body',
  'listening_image_choice.icons': 'exerciseHelp.field.answer_pictures.body',
  'listening_image_choice.image': 'exerciseHelp.field.choice.image.body',
  'spell_heard.tts': 'exerciseHelp.field.spell_heard.tts.body',
  'spell_heard.order': 'exerciseHelp.field.image_word.order.body',
  'spell_heard.image': 'exerciseHelp.field.choice.image.body',
  'picture_choice.question': 'exerciseHelp.field.icon_choice.question.body',
  'picture_choice.answers': 'exerciseHelp.field.choice.answers.body',
  'picture_choice.correct': 'exerciseHelp.field.gap_choice.correct.body',
  'picture_choice.image': 'exerciseHelp.field.choice.image.body',
  'picture_name.question': 'exerciseHelp.field.icon_choice.question.body',
  'picture_name.accepted': 'exerciseHelp.field.picture_name.accepted.body',
  'picture_name.hint': 'exerciseHelp.field.gap_choice.hint.body',
  'picture_name.image': 'exerciseHelp.field.choice.image.body',
  'spell_word.prompt': 'exerciseHelp.field.spell_word.prompt.body',
  'spell_word.order': 'exerciseHelp.field.image_word.order.body',
  'spell_word.image': 'exerciseHelp.field.choice.image.body',
  'picture_word_match.prompt': 'exerciseHelp.field.matching.prompt.body',
  'picture_word_match.answers':
      'exerciseHelp.field.picture_word_match.answers.body',
  'picture_word_match.icons': 'exerciseHelp.field.answer_pictures.body',
  'picture_word_match.image': 'exerciseHelp.field.choice.image.body',
  'note_card.prompt': 'exerciseHelp.field.note_card.prompt.body',
  'note_card.question': 'exerciseHelp.field.note_card.question.body',
  'note_card.image': 'exerciseHelp.field.choice.image.body',
  'dialogue_line.speaker': 'exerciseHelp.field.dialogue_line.speaker.body',
  'dialogue_line.prompt': 'exerciseHelp.field.dialogue_line.prompt.body',
  'dialogue_line.lineMode': 'exerciseHelp.field.dialogue_line.lineMode.body',
  'dialogue_line.readAloud': 'exerciseHelp.field.dialogue_line.readAloud.body',
  'dialogue_line.textReveal':
      'exerciseHelp.field.dialogue_line.textReveal.body',
  'dialogue_line.language': 'exerciseHelp.field.dialogue_line.language.body',
  'dialogue_line.image': 'exerciseHelp.field.choice.image.body',
  'story_cover.prompt': 'exerciseHelp.field.story_cover.prompt.body',
  'story_cover.image': 'exerciseHelp.field.story_cover.image.body',
  'sort_into_groups.question':
      'exerciseHelp.field.sort_into_groups.question.body',
  'sort_into_groups.groups': 'exerciseHelp.field.sort_into_groups.groups.body',
  'sort_into_groups.leftover':
      'exerciseHelp.field.sort_into_groups.leftover.body',
  'sort_into_groups.image': 'exerciseHelp.field.choice.image.body',
  'fill_the_slots.question': 'exerciseHelp.field.fill_the_slots.question.body',
  'fill_the_slots.slots': 'exerciseHelp.field.fill_the_slots.slots.body',
  'fill_the_slots.extraWords':
      'exerciseHelp.field.fill_the_slots.extraWords.body',
  'fill_the_slots.slotReuse':
      'exerciseHelp.field.fill_the_slots.slotReuse.body',
  'fill_the_slots.image': 'exerciseHelp.field.choice.image.body',
};
