import '../models/course_models.dart';
import '../models/exercise_features.dart';

/// Learner-facing exercise labels and instructions, keyed by the
/// [LearnerExerciseKind] derived from canonical data (Build 256).
///
/// These strings are derived from the course source language, so authoring
/// data cannot accidentally show a target-language instruction to learners.
class ExerciseCopyService {
  const ExerciseCopyService._();

  static String _languageCode(Course course) {
    final source = course.sourceLanguage.trim().toLowerCase();
    const byName = <String, String>{
      'english': 'EN',
      'spanish': 'ES',
      'italian': 'IT',
      'german': 'DE',
      'portuguese': 'PT',
      'dutch': 'NL',
      'finnish': 'FI',
      'welsh': 'CY',
    };
    return byName[source] ?? course.interfaceLanguage.trim().toUpperCase();
  }

  static Map<String, String> _copy(Course course) {
    switch (_languageCode(course)) {
      case 'ES':
        return _es;
      case 'IT':
        return _it;
      case 'DE':
        return _de;
      case 'PT':
        return _pt;
      case 'NL':
        return _nl;
      case 'FI':
        return _fi;
      case 'CY':
        return _cy;
      default:
        return _en;
    }
  }

  /// The learner heading for an exercise of [kind].
  static String typeLabel(Course course, LearnerExerciseKind kind) {
    final c = _copy(course);
    return c['type.${kind.name}'] ?? c['type.default']!;
  }

  /// The learner instruction for an exercise of [kind]. Without an
  /// exercise, a translation line names the target language.
  static String instruction(Course course, LearnerExerciseKind kind) {
    final c = _copy(course);
    return _withLanguage(
      course,
      c['instruction.${kind.name}'] ?? c['instruction.default']!,
    );
  }

  /// [text] with `{language}` replaced by the Course's name for the
  /// language a translation is written in: the source language when the
  /// text to translate is in the target language, else the target language
  /// (Build 259 Revision 7; the names are the Course's own, as Pick the
  /// translation's line uses them).
  static String _withLanguage(
    Course course,
    String text, [
    ExerciseFeatures? features,
  ]) {
    if (!text.contains('{language}')) return text;
    final intoSource = features?.promptLanguage == TextLanguage.target;
    final name = intoSource ? course.sourceLanguage : course.targetLanguage;
    final fallback = intoSource
        ? course.interfaceLanguage
        : course.learningLanguage;
    return text.replaceAll(
      '{language}',
      name.trim().isEmpty ? fallback.trim() : name.trim(),
    );
  }

  /// The instruction [variant] (a key such as `selectListenHeard`), else
  /// [kind]'s. The Exercise editor quotes a variant for the presets whose
  /// exercises always get it (Build 259 Revision 3).
  static String instructionVariant(
    Course course,
    String variant,
    LearnerExerciseKind kind,
  ) => _copy(course)['instruction.$variant'] ?? instruction(course, kind);

  /// The instruction for [exercise]: its kind's, or the "opposites" variant
  /// when the exercise's own text says so. Both come from canonical data;
  /// nothing here reads a preset (Build 256, plan A.3).
  static String instructionForExercise(Course course, Exercise exercise) {
    final features = ExerciseFeatures(exercise);
    final kind = features.kind;
    final prompt = [
      features.primaryText,
      features.questionText,
      features.clueText,
      features.passageText,
      features.situationText,
      features.contextText,
    ].join(' ').toLowerCase();
    final c = _copy(course);
    if (kind == LearnerExerciseKind.dialogueLine) {
      // The instruction follows the line's mode and whether its text waits
      // for the audio (owner review, 28 September 2026).
      final variant = features.lineMode == 'text'
          ? 'dialogueLineText'
          : features.lineMode == 'audio'
          ? 'dialogueLineAudio'
          : features.textReveal == TextReveal.afterAudio
          ? 'dialogueLineAfterAudio'
          : 'dialogueLine';
      return c['instruction.$variant'] ?? instruction(course, kind);
    }
    // Typed gaps (Build 259 Revision 3, owner decision of 30 September
    // 2026): letters inside words, one word, or several words.
    if (kind == LearnerExerciseKind.inputComplete) {
      final targets = features.gapFieldTargets;
      final inWord = features.gapsInWord;
      final variant =
          targets.isNotEmpty &&
              targets.every((target) => inWord[target.id] ?? false)
          ? 'inputCompleteLetters'
          : targets.length <= 1
          ? 'inputCompleteOne'
          : null;
      if (variant != null) {
        return c['instruction.$variant'] ?? instruction(course, kind);
      }
    }
    // Listening (Build 259 Revision 3): a question is answered; without one
    // the learner picks the sentence heard, or its meaning among
    // source-language answers. Picture answers and gaps keep their line.
    if (kind == LearnerExerciseKind.selectListen ||
        kind == LearnerExerciseKind.selectListenPassage) {
      final variant = features.questionText.isNotEmpty
          ? 'selectListenQuestion'
          : kind == LearnerExerciseKind.selectListen &&
                !features.hasInlineTargets &&
                !features.hasImageItems &&
                !features.hasIconItems
          ? (features.itemLanguage == TextLanguage.source
                ? 'selectListenMeaning'
                : 'selectListenHeard')
          : null;
      if (variant != null) {
        return c['instruction.$variant'] ?? instruction(course, kind);
      }
    }
    // Spelling without a picture (Build 259 Revision 4): heard, or from a
    // clue.
    if (kind == LearnerExerciseKind.arrangeWord &&
        features.illustrationImages.isEmpty) {
      final variant = features.automaticAudio != null
          ? 'arrangeWordHeard'
          : 'arrangeWordClue';
      return c['instruction.$variant'] ?? instruction(course, kind);
    }
    // Words picked for the gaps of a sentence (Build 259 Revision 4).
    if (kind == LearnerExerciseKind.arrangeSentence &&
        features.hasInlineTargets) {
      return c['instruction.arrangeGaps'] ?? instruction(course, kind);
    }
    if (prompt.contains('opposite') ||
        prompt.contains('contrari') ||
        prompt.contains('gegens') ||
        prompt.contains('opuestos') ||
        prompt.contains('opostos') ||
        prompt.contains('tegenstell') ||
        prompt.contains('vastakoht') ||
        prompt.contains('croes')) {
      // A Match keeps its generic line (owner decision, 29 September 2026):
      // Match by meaning takes opposites, synonyms and more, and an authored
      // instruction is drawn in the line's place anyway.
      if (kind == LearnerExerciseKind.select) {
        return c['instruction.select_opposite'] ?? instruction(course, kind);
      }
    }
    // Type and Build the translation name the language of the answer.
    return _withLanguage(
      course,
      c['instruction.${kind.name}'] ?? c['instruction.default']!,
      features,
    );
  }

  /// Old demo courses sometimes stored a generic instruction in `prompt`.
  /// The Round screen now renders the localized instruction separately, so
  /// suppress only these exact legacy instruction strings to avoid duplicates.
  static bool isLegacyInstruction(String prompt) {
    final value = prompt.trim();
    if (value.isEmpty) return false;
    return _legacyInstructions.contains(value);
  }

  /// Keeps authored content intact while localizing the instruction prefix in
  /// old Spanish-source demo exercises that used English `Translate:` text.
  static String displayPrompt(Course course, String prompt) {
    final value = prompt.trim();
    if (_languageCode(course) == 'ES' && value.startsWith('Translate:')) {
      return 'Traduce:${value.substring('Translate:'.length)}';
    }
    return prompt;
  }

  static const _legacyInstructions = <String>{
    'Choose the correct translation.',
    'Build the target-language word shown in the image.',
    'Build the word shown in the image.',
    'Match each translation.',
    'Match each sound to the word.',
    'Match the opposites.',
    'Abbina i contrari.',
    'Ordne die Gegensätze zu.',
    'Relaciona los contrarios.',
    'Associe os opostos.',
    'Koppel de tegenstellingen.',
    'Yhdistä vastakohdat.',
    'Parwch y geiriau croes.',
  };

  static const _en = <String, String>{
    'type.default': 'EXERCISE',
    'type.inputMissingWord': 'TYPE THE MISSING WORD',
    'type.selectCharacter': 'RECOGNIZE CHARACTERS',
    'type.select': 'CHOOSE',
    'type.selectListen': 'LISTEN AND CHOOSE',
    'type.selectListenPassage': 'LISTENING',
    'type.selectRead': 'READING',
    'type.selectDialogue': 'DIALOGUE',
    'type.selectImage': 'CHOOSE THE IMAGE',
    'type.presentation': 'FLASHCARD',
    'type.dialogueLine': 'DIALOGUE',
    'type.storyCover': 'STORY',
    'type.inputComplete': 'COMPLETE',
    'type.selectComplete': 'COMPLETE THE SENTENCE',
    'type.arrangeSentence': 'BUILD THE SENTENCE',
    'type.arrangeLines': 'PUT THE SENTENCES IN ORDER',
    'type.arrangeWord': 'BUILD THE WORD',
    'type.inputPictureName': 'NAME WHAT YOU SEE',
    'type.arrangePictureName': 'NAME WHAT YOU SEE',
    'type.matchTranslation': 'MATCH',
    'type.match': 'MATCH',
    'type.inputListenGaps': 'COMPLETE',
    'type.inputListenWrite': 'WRITE WHAT YOU HEAR',
    'type.matchAudio': 'MATCH THE AUDIO',
    'type.inputTranslation': 'TYPE THE TRANSLATION',
    'type.arrangeTranslation': 'BUILD THE TRANSLATION',
    'type.selectContext': 'CONTEXT',
    'instruction.default': 'Complete the exercise.',
    'instruction.inputMissingWord':
        'The first letter is given: type the whole word.',
    'instruction.selectCharacter':
        'Choose the option that matches the character.',
    'instruction.select': 'Find the correct answer.',
    'instruction.selectListen': 'Find the answer that matches what you hear.',
    'instruction.selectListenPassage': 'Listen and choose the correct answer.',
    'instruction.selectRead': 'Read and choose the correct answer.',
    'instruction.selectDialogue':
        'Read the dialogue and choose the best response.',
    'instruction.selectImage': 'Find the matching picture.',
    'instruction.presentation': 'Study the word and its usage.',
    'instruction.dialogueLine': 'Read or listen, then continue.',
    'instruction.dialogueLineText': 'Read, then continue.',
    'instruction.dialogueLineAudio': 'Listen, then continue.',
    'instruction.dialogueLineAfterAudio':
        'Listen first; the text appears after.',
    'instruction.storyCover': 'A story begins. Continue when you are ready.',
    'instruction.inputComplete': 'Type the words that complete the sentence.',
    'instruction.selectComplete': 'Pick the block that fits the gap.',
    'instruction.select_opposite': 'Find the opposite.',
    'instruction.arrangeSentence': 'Put the words in the correct order.',
    'instruction.arrangeLines': 'Arrange the lines in a logical order.',
    'instruction.arrangeWord': 'Spell what the picture shows.',
    'instruction.inputPictureName': 'Type the name of the picture.',
    'instruction.arrangePictureName':
        'Put the blocks in order to name the picture.',
    'instruction.matchTranslation': 'Pair each word with its translation.',
    'instruction.match': 'Pair the items that belong together.',
    'type.assignGroups': 'SORT INTO GROUPS',
    'type.assignSlots': 'FILL THE SLOTS',
    'type.assignGaps': 'FILL THE GAPS',
    'instruction.assignGroups': 'Tap an item, then the group it belongs to.',
    'instruction.assignSlots': 'Tap an item, then its slot.',
    'instruction.assignGaps': 'Tap a word, then the gap it fills.',
    'instruction.inputListenGaps': 'Listen and complete the missing word.',
    'instruction.inputListenWrite': 'Type every word you hear.',
    'instruction.matchAudio': 'Pair each sound with its word.',
    'instruction.inputTranslation': 'Translate into {language}.',
    'instruction.arrangeTranslation':
        'Translate into {language} with the word blocks.',
    'instruction.selectContext':
        'Use the context to choose the correct answer.',
    'instruction.inputCompleteOne':
        'Type the word that completes the sentence.',
    'instruction.inputCompleteLetters': 'Type the missing letters.',
    'instruction.selectListenQuestion': 'Listen and answer the question.',
    'instruction.selectListenHeard': 'Select the sentence that you heard.',
    'instruction.selectListenMeaning': 'Select the meaning of what you heard.',
    'type.selectPicture': 'WHAT IS IN THE PICTURE?',
    'instruction.selectPicture': 'Choose the option that fits best.',
    'instruction.arrangeWordHeard': 'Spell the word you hear.',
    'instruction.arrangeWordClue': 'Spell the word the clue describes.',
    'instruction.arrangeGaps': 'Pick a word for each gap.',
    'type.selectCompleteAll': 'ONE WORD FILLS ALL',
    'instruction.selectCompleteAll': 'Choose the word that fills every gap.',
  };

  static const _es = <String, String>{
    'type.default': 'EJERCICIO',
    'type.inputMissingWord': 'ESCRIBE LA PALABRA QUE FALTA',
    'type.selectCharacter': 'RECONOCE CARACTERES',
    'type.select': 'ELIGE',
    'type.selectListen': 'ESCUCHA Y ELIGE',
    'type.selectListenPassage': 'COMPRENSIÓN ORAL',
    'type.selectRead': 'LECTURA',
    'type.selectDialogue': 'DIÁLOGO',
    'type.selectImage': 'ELIGE LA IMAGEN',
    'type.presentation': 'TARJETA',
    'type.dialogueLine': 'DIÁLOGO',
    'type.storyCover': 'HISTORIA',
    'type.inputComplete': 'COMPLETA',
    'type.selectComplete': 'COMPLETA LA FRASE',
    'type.arrangeSentence': 'FORMA LA FRASE',
    'type.arrangeLines': 'ORDENA LAS FRASES',
    'type.arrangeWord': 'FORMA LA PALABRA',
    'type.inputPictureName': 'NOMBRA LO QUE VES',
    'type.arrangePictureName': 'NOMBRA LO QUE VES',
    'type.matchTranslation': 'RELACIONA',
    'type.match': 'RELACIONA',
    'type.inputListenGaps': 'COMPLETA',
    'type.inputListenWrite': 'ESCRIBE LO QUE OYES',
    'type.matchAudio': 'RELACIONA EL AUDIO',
    'instruction.default': 'Completa el ejercicio.',
    'instruction.inputMissingWord':
        'La primera letra ya está: escribe la palabra entera.',
    'instruction.selectCharacter':
        'Elige la opción que corresponde al carácter.',
    'instruction.select': 'Encuentra la respuesta correcta.',
    'instruction.selectListen':
        'Encuentra la respuesta que corresponde a lo que oyes.',
    'instruction.selectListenPassage': 'Escucha y elige la respuesta correcta.',
    'instruction.selectRead': 'Lee y elige la respuesta correcta.',
    'instruction.selectDialogue': 'Lee el diálogo y elige la mejor respuesta.',
    'instruction.selectImage': 'Encuentra la imagen correspondiente.',
    'instruction.presentation': 'Estudia la palabra y su uso.',
    'instruction.dialogueLine': 'Lee o escucha, luego continúa.',
    'instruction.dialogueLineText': 'Lee, luego continúa.',
    'instruction.dialogueLineAudio': 'Escucha, luego continúa.',
    'instruction.dialogueLineAfterAudio':
        'Escucha primero; el texto aparece después.',
    'instruction.storyCover':
        'Empieza una historia. Continúa cuando estés listo.',
    'instruction.inputComplete': 'Escribe las palabras que completan la frase.',
    'instruction.selectComplete': 'Elige el bloque que encaja en el hueco.',
    'instruction.select_opposite': 'Encuentra el contrario.',
    'instruction.arrangeSentence': 'Pon las palabras en el orden correcto.',
    'instruction.arrangeLines': 'Ordena las líneas de forma lógica.',
    'instruction.arrangeWord': 'Deletrea lo que muestra la imagen.',
    'instruction.inputPictureName': 'Escribe el nombre de la imagen.',
    'instruction.arrangePictureName':
        'Ordena los bloques para nombrar la imagen.',
    'instruction.matchTranslation': 'Empareja cada palabra con su traducción.',
    'instruction.match': 'Empareja los elementos que van juntos.',
    'type.assignGroups': 'ORDENA EN GRUPOS',
    'type.assignSlots': 'RELLENA LAS CASILLAS',
    'type.assignGaps': 'RELLENA LOS HUECOS',
    'instruction.assignGroups':
        'Toca un elemento y luego el grupo al que pertenece.',
    'instruction.assignSlots': 'Toca un elemento y luego su casilla.',
    'instruction.assignGaps': 'Toca una palabra y luego el hueco que rellena.',
    'instruction.inputListenGaps': 'Escucha y completa la palabra que falta.',
    'instruction.inputListenWrite': 'Escribe cada palabra que oyes.',
    'instruction.matchAudio': 'Empareja cada audio con su palabra.',
    'type.inputTranslation': 'ESCRIBE LA TRADUCCIÓN',
    'type.arrangeTranslation': 'FORMA LA TRADUCCIÓN',
    'type.selectContext': 'CONTEXTO',
    'instruction.inputTranslation': 'Traduce al {language}.',
    'instruction.arrangeTranslation':
        'Traduce al {language} con los bloques de palabras.',
    'instruction.selectContext':
        'Usa el contexto para elegir la respuesta correcta.',
    'instruction.inputCompleteOne': 'Escribe la palabra que completa la frase.',
    'instruction.inputCompleteLetters': 'Escribe las letras que faltan.',
    'instruction.selectListenQuestion': 'Escucha y responde a la pregunta.',
    'instruction.selectListenHeard': 'Selecciona la frase que has oído.',
    'instruction.selectListenMeaning':
        'Selecciona el significado de lo que has oído.',
    'type.selectPicture': '¿QUÉ HAY EN LA IMAGEN?',
    'instruction.selectPicture': 'Elige la opción más adecuada.',
    'instruction.arrangeWordHeard': 'Deletrea la palabra que oyes.',
    'instruction.arrangeWordClue': 'Deletrea la palabra que describe la pista.',
    'instruction.arrangeGaps': 'Elige una palabra para cada hueco.',
    'type.selectCompleteAll': 'UNA PALABRA PARA TODOS',
    'instruction.selectCompleteAll':
        'Elige la palabra que completa todos los huecos.',
  };

  static const _it = <String, String>{
    'type.default': 'ESERCIZIO',
    'type.inputMissingWord': 'SCRIVI LA PAROLA MANCANTE',
    'type.selectCharacter': 'RICONOSCI I CARATTERI',
    'type.select': 'SCEGLI',
    'type.selectListen': 'ASCOLTA E SCEGLI',
    'type.selectListenPassage': 'ASCOLTO',
    'type.selectRead': 'LETTURA',
    'type.selectDialogue': 'DIALOGO',
    'type.selectImage': 'SCEGLI L’IMMAGINE',
    'type.presentation': 'FLASHCARD',
    'type.dialogueLine': 'DIALOGO',
    'type.storyCover': 'STORIA',
    'type.inputComplete': 'COMPLETA',
    'type.selectComplete': 'COMPLETA LA FRASE',
    'type.arrangeSentence': 'COMPONI LA FRASE',
    'type.arrangeLines': 'ORDINA LE FRASI',
    'type.arrangeWord': 'COMPONI LA PAROLA',
    'type.inputPictureName': 'NOMINA CIÒ CHE VEDI',
    'type.arrangePictureName': 'NOMINA CIÒ CHE VEDI',
    'type.matchTranslation': 'ABBINA',
    'type.match': 'ABBINA',
    'type.inputListenGaps': 'COMPLETA',
    'type.inputListenWrite': 'SCRIVI CIÒ CHE SENTI',
    'type.matchAudio': 'ABBINA L’AUDIO',
    'instruction.default': 'Completa l’esercizio.',
    'instruction.inputMissingWord':
        'La prima lettera è data: scrivi la parola intera.',
    'instruction.selectCharacter':
        'Scegli l’opzione che corrisponde al carattere.',
    'instruction.select': 'Trova la risposta corretta.',
    'instruction.selectListen':
        'Trova la risposta che corrisponde a ciò che senti.',
    'instruction.selectListenPassage': 'Ascolta e scegli la risposta corretta.',
    'instruction.selectRead': 'Leggi e scegli la risposta corretta.',
    'instruction.selectDialogue':
        'Leggi il dialogo e scegli la risposta migliore.',
    'instruction.selectImage': 'Trova l’immagine corrispondente.',
    'instruction.presentation': 'Studia la parola e il suo uso.',
    'instruction.dialogueLine': 'Leggi o ascolta, poi continua.',
    'instruction.dialogueLineText': 'Leggi, poi continua.',
    'instruction.dialogueLineAudio': 'Ascolta, poi continua.',
    'instruction.dialogueLineAfterAudio':
        'Ascolta prima; il testo compare dopo.',
    'instruction.storyCover': 'Inizia una storia. Continua quando sei pronto.',
    'instruction.inputComplete': 'Scrivi le parole che completano la frase.',
    'instruction.selectComplete': 'Scegli il blocco adatto allo spazio vuoto.',
    'instruction.select_opposite': 'Trova il contrario.',
    'instruction.arrangeSentence': 'Metti le parole nell’ordine corretto.',
    'instruction.arrangeLines': 'Metti le righe in un ordine logico.',
    'instruction.arrangeWord': 'Compita ciò che mostra l’immagine.',
    'instruction.inputPictureName': 'Scrivi il nome dell’immagine.',
    'instruction.arrangePictureName':
        'Metti in ordine i blocchi per dare il nome all’immagine.',
    'instruction.matchTranslation': 'Accoppia ogni parola alla sua traduzione.',
    'instruction.match': 'Accoppia gli elementi che vanno insieme.',
    'type.assignGroups': 'SMISTA IN GRUPPI',
    'type.assignSlots': 'RIEMPI LE CASELLE',
    'type.assignGaps': 'RIEMPI GLI SPAZI',
    'instruction.assignGroups':
        'Tocca un elemento, poi il gruppo a cui appartiene.',
    'instruction.assignSlots': 'Tocca un elemento, poi la sua casella.',
    'instruction.assignGaps': 'Tocca una parola, poi lo spazio che riempie.',
    'instruction.inputListenGaps': 'Ascolta e completa la parola mancante.',
    'instruction.inputListenWrite': 'Scrivi ogni parola che senti.',
    'instruction.matchAudio': 'Accoppia ogni audio alla sua parola.',
    'type.inputTranslation': 'SCRIVI LA TRADUZIONE',
    'type.arrangeTranslation': 'COMPONI LA TRADUZIONE',
    'type.selectContext': 'CONTESTO',
    'instruction.inputTranslation': 'Traduci in {language}.',
    'instruction.arrangeTranslation':
        'Traduci in {language} con i blocchi di parole.',
    'instruction.selectContext':
        'Usa il contesto per scegliere la risposta corretta.',
    'instruction.inputCompleteOne': 'Scrivi la parola che completa la frase.',
    'instruction.inputCompleteLetters': 'Scrivi le lettere mancanti.',
    'instruction.selectListenQuestion': 'Ascolta e rispondi alla domanda.',
    'instruction.selectListenHeard': 'Seleziona la frase che hai sentito.',
    'instruction.selectListenMeaning':
        'Seleziona il significato di ciò che hai sentito.',
    'type.selectPicture': 'COSA C’È NELL’IMMAGINE?',
    'instruction.selectPicture': 'Scegli l’opzione più adatta.',
    'instruction.arrangeWordHeard': 'Compita la parola che senti.',
    'instruction.arrangeWordClue': 'Compita la parola descritta dall’indizio.',
    'instruction.arrangeGaps': 'Scegli una parola per ogni spazio.',
    'type.selectCompleteAll': 'UNA PAROLA PER TUTTI',
    'instruction.selectCompleteAll':
        'Scegli la parola che completa tutti gli spazi.',
  };

  static const _de = <String, String>{
    'type.default': 'ÜBUNG',
    'type.inputMissingWord': 'ERGÄNZE DAS WORT',
    'type.selectCharacter': 'ZEICHEN ERKENNEN',
    'type.select': 'AUSWÄHLEN',
    'type.selectListen': 'HÖREN UND AUSWÄHLEN',
    'type.selectListenPassage': 'HÖRVERSTEHEN',
    'type.selectRead': 'LESEN',
    'type.selectDialogue': 'DIALOG',
    'type.selectImage': 'BILD AUSWÄHLEN',
    'type.presentation': 'KARTE',
    'type.dialogueLine': 'DIALOG',
    'type.storyCover': 'GESCHICHTE',
    'type.inputComplete': 'ERGÄNZEN',
    'type.selectComplete': 'SATZ ERGÄNZEN',
    'type.arrangeSentence': 'SATZ BILDEN',
    'type.arrangeLines': 'SÄTZE ORDNEN',
    'type.arrangeWord': 'WORT BILDEN',
    'type.inputPictureName': 'BENENNE, WAS DU SIEHST',
    'type.arrangePictureName': 'BENENNE, WAS DU SIEHST',
    'type.matchTranslation': 'ZUORDNEN',
    'type.match': 'ZUORDNEN',
    'type.inputListenGaps': 'ERGÄNZEN',
    'type.inputListenWrite': 'SCHREIBEN, WAS DU HÖRST',
    'type.matchAudio': 'AUDIO ZUORDNEN',
    'instruction.default': 'Bearbeite die Übung.',
    'instruction.inputMissingWord':
        'Der erste Buchstabe ist vorgegeben: Schreibe das ganze Wort.',
    'instruction.selectCharacter': 'Wähle die Option, die zum Zeichen passt.',
    'instruction.select': 'Finde die richtige Antwort.',
    'instruction.selectListen':
        'Finde die Antwort, die zu dem passt, was du hörst.',
    'instruction.selectListenPassage':
        'Höre zu und wähle die richtige Antwort.',
    'instruction.selectRead': 'Lies und wähle die richtige Antwort.',
    'instruction.selectDialogue':
        'Lies den Dialog und wähle die beste Antwort.',
    'instruction.selectImage': 'Finde das passende Bild.',
    'instruction.presentation': 'Lerne das Wort und seine Verwendung.',
    'instruction.dialogueLine': 'Lies oder höre zu, dann weiter.',
    'instruction.dialogueLineText': 'Lies, dann weiter.',
    'instruction.dialogueLineAudio': 'Hör zu, dann weiter.',
    'instruction.dialogueLineAfterAudio':
        'Hör zuerst zu; der Text erscheint danach.',
    'instruction.storyCover':
        'Eine Geschichte beginnt. Weiter, wenn du bereit bist.',
    'instruction.inputComplete':
        'Schreibe die Wörter, die den Satz vervollständigen.',
    'instruction.selectComplete': 'Wähle den Baustein, der in die Lücke passt.',
    'instruction.select_opposite': 'Finde das Gegenteil.',
    'instruction.arrangeSentence':
        'Bringe die Wörter in die richtige Reihenfolge.',
    'instruction.arrangeLines':
        'Bringe die Zeilen in eine logische Reihenfolge.',
    'instruction.arrangeWord': 'Buchstabiere, was das Bild zeigt.',
    'instruction.inputPictureName': 'Schreibe den Namen des Bildes.',
    'instruction.arrangePictureName':
        'Ordne die Bausteine, um das Bild zu benennen.',
    'instruction.matchTranslation':
        'Bilde Paare aus jedem Wort und seiner Übersetzung.',
    'instruction.match': 'Bilde Paare aus den Elementen, die zusammengehören.',
    'type.assignGroups': 'IN GRUPPEN SORTIEREN',
    'type.assignSlots': 'FELDER FÜLLEN',
    'type.assignGaps': 'LÜCKEN FÜLLEN',
    'instruction.assignGroups':
        'Tippe auf ein Element und dann auf seine Gruppe.',
    'instruction.assignSlots': 'Tippe auf ein Element und dann auf sein Feld.',
    'instruction.assignGaps':
        'Tippe auf ein Wort und dann auf die Lücke, die es füllt.',
    'instruction.inputListenGaps': 'Höre zu und ergänze das fehlende Wort.',
    'instruction.inputListenWrite': 'Schreibe jedes Wort, das du hörst.',
    'instruction.matchAudio': 'Bilde Paare aus jedem Ton und seinem Wort.',
    'type.inputTranslation': 'ÜBERSETZUNG EINGEBEN',
    'type.arrangeTranslation': 'ÜBERSETZUNG BILDEN',
    'type.selectContext': 'KONTEXT',
    'instruction.inputTranslation': 'Übersetze auf {language}.',
    'instruction.arrangeTranslation':
        'Übersetze mit den Wortbausteinen auf {language}.',
    'instruction.selectContext':
        'Nutze den Kontext, um die richtige Antwort auszuwählen.',
    'instruction.inputCompleteOne':
        'Schreibe das Wort, das den Satz vervollständigt.',
    'instruction.inputCompleteLetters': 'Schreibe die fehlenden Buchstaben.',
    'instruction.selectListenQuestion': 'Höre zu und beantworte die Frage.',
    'instruction.selectListenHeard': 'Wähle den Satz, den du gehört hast.',
    'instruction.selectListenMeaning':
        'Wähle die Bedeutung dessen, was du gehört hast.',
    'type.selectPicture': 'WAS IST AUF DEM BILD?',
    'instruction.selectPicture': 'Wähle die passendste Option.',
    'instruction.arrangeWordHeard': 'Buchstabiere das Wort, das du hörst.',
    'instruction.arrangeWordClue':
        'Buchstabiere das Wort, das der Hinweis beschreibt.',
    'instruction.arrangeGaps': 'Wähle für jede Lücke ein Wort.',
    'type.selectCompleteAll': 'EIN WORT FÜR ALLE',
    'instruction.selectCompleteAll': 'Wähle das Wort, das in jede Lücke passt.',
  };

  static const _pt = <String, String>{
    'type.default': 'EXERCÍCIO',
    'type.inputMissingWord': 'ESCREVE A PALAVRA EM FALTA',
    'type.selectCharacter': 'RECONHECE CARACTERES',
    'type.select': 'ESCOLHER',
    'type.selectListen': 'OUVIR E ESCOLHER',
    'type.selectListenPassage': 'COMPREENSÃO ORAL',
    'type.selectRead': 'LEITURA',
    'type.selectDialogue': 'DIÁLOGO',
    'type.selectImage': 'ESCOLHER A IMAGEM',
    'type.presentation': 'CARTÃO',
    'type.dialogueLine': 'DIÁLOGO',
    'type.storyCover': 'HISTÓRIA',
    'type.inputComplete': 'COMPLETAR',
    'type.selectComplete': 'COMPLETAR A FRASE',
    'type.arrangeSentence': 'FORMAR A FRASE',
    'type.arrangeLines': 'ORDENAR AS FRASES',
    'type.arrangeWord': 'FORMAR A PALAVRA',
    'type.inputPictureName': 'NOMEIE O QUE VÊ',
    'type.arrangePictureName': 'NOMEIE O QUE VÊ',
    'type.matchTranslation': 'ASSOCIAR',
    'type.match': 'ASSOCIAR',
    'type.inputListenGaps': 'COMPLETAR',
    'type.inputListenWrite': 'ESCREVER O QUE OUVE',
    'type.matchAudio': 'ASSOCIAR O ÁUDIO',
    'instruction.default': 'Complete o exercício.',
    'instruction.inputMissingWord':
        'A primeira letra é dada: escreva a palavra inteira.',
    'instruction.selectCharacter':
        'Escolhe a opção que corresponde ao carácter.',
    'instruction.select': 'Encontre a resposta correta.',
    'instruction.selectListen':
        'Encontre a resposta que corresponde ao que ouve.',
    'instruction.selectListenPassage': 'Ouça e escolha a resposta correta.',
    'instruction.selectRead': 'Leia e escolha a resposta correta.',
    'instruction.selectDialogue': 'Leia o diálogo e escolha a melhor resposta.',
    'instruction.selectImage': 'Encontre a imagem correspondente.',
    'instruction.presentation': 'Estude a palavra e o seu uso.',
    'instruction.dialogueLine': 'Leia ou ouça, depois continue.',
    'instruction.dialogueLineText': 'Leia, depois continue.',
    'instruction.dialogueLineAudio': 'Ouça, depois continue.',
    'instruction.dialogueLineAfterAudio':
        'Ouça primeiro; o texto aparece depois.',
    'instruction.storyCover':
        'Começa uma história. Continue quando estiver pronto.',
    'instruction.inputComplete': 'Escreva as palavras que completam a frase.',
    'instruction.selectComplete': 'Escolha o bloco que encaixa na lacuna.',
    'instruction.select_opposite': 'Encontre o oposto.',
    'instruction.arrangeSentence': 'Coloque as palavras na ordem correta.',
    'instruction.arrangeLines': 'Coloque as linhas numa ordem lógica.',
    'instruction.arrangeWord': 'Soletre o que a imagem mostra.',
    'instruction.inputPictureName': 'Escreva o nome da imagem.',
    'instruction.arrangePictureName': 'Ordene os blocos para nomear a imagem.',
    'instruction.matchTranslation':
        'Emparelhe cada palavra com a sua tradução.',
    'instruction.match': 'Emparelhe os elementos que andam juntos.',
    'type.assignGroups': 'ORDENAR EM GRUPOS',
    'type.assignSlots': 'PREENCHER AS CASAS',
    'type.assignGaps': 'PREENCHER AS LACUNAS',
    'instruction.assignGroups':
        'Toque num item e depois no grupo a que pertence.',
    'instruction.assignSlots': 'Toque num item e depois na sua casa.',
    'instruction.assignGaps':
        'Toque numa palavra e depois na lacuna que ela preenche.',
    'instruction.inputListenGaps': 'Ouça e complete a palavra em falta.',
    'instruction.inputListenWrite': 'Escreva cada palavra que ouve.',
    'instruction.matchAudio': 'Emparelhe cada áudio com a sua palavra.',
    'type.inputTranslation': 'ESCREVER A TRADUÇÃO',
    'type.arrangeTranslation': 'FORMAR A TRADUÇÃO',
    'type.selectContext': 'CONTEXTO',
    'instruction.inputTranslation': 'Traduza para {language}.',
    'instruction.arrangeTranslation':
        'Traduza para {language} com os blocos de palavras.',
    'instruction.selectContext':
        'Use o contexto para escolher a resposta correta.',
    'instruction.inputCompleteOne': 'Escreva a palavra que completa a frase.',
    'instruction.inputCompleteLetters': 'Escreva as letras que faltam.',
    'instruction.selectListenQuestion': 'Ouça e responda à pergunta.',
    'instruction.selectListenHeard': 'Selecione a frase que ouviu.',
    'instruction.selectListenMeaning': 'Selecione o significado do que ouviu.',
    'type.selectPicture': 'O QUE HÁ NA IMAGEM?',
    'instruction.selectPicture': 'Escolha a opção mais adequada.',
    'instruction.arrangeWordHeard': 'Soletre a palavra que ouve.',
    'instruction.arrangeWordClue': 'Soletre a palavra que a pista descreve.',
    'instruction.arrangeGaps': 'Escolha uma palavra para cada lacuna.',
    'type.selectCompleteAll': 'UMA PALAVRA PARA TODAS',
    'instruction.selectCompleteAll':
        'Escolha a palavra que preenche todas as lacunas.',
  };

  static const _nl = <String, String>{
    'type.default': 'OEFENING',
    'type.inputMissingWord': 'VUL HET ONTBREKENDE WOORD AAN',
    'type.selectCharacter': 'HERKEN TEKENS',
    'type.select': 'KIEZEN',
    'type.selectListen': 'LUISTER EN KIES',
    'type.selectListenPassage': 'LUISTEREN',
    'type.selectRead': 'LEZEN',
    'type.selectDialogue': 'DIALOOG',
    'type.selectImage': 'KIES DE AFBEELDING',
    'type.presentation': 'FLASHCARD',
    'type.dialogueLine': 'DIALOOG',
    'type.storyCover': 'VERHAAL',
    'type.inputComplete': 'AANVULLEN',
    'type.selectComplete': 'ZIN AANVULLEN',
    'type.arrangeSentence': 'MAAK DE ZIN',
    'type.arrangeLines': 'ZET DE ZINNEN OP VOLGORDE',
    'type.arrangeWord': 'MAAK HET WOORD',
    'type.inputPictureName': 'BENOEM WAT JE ZIET',
    'type.arrangePictureName': 'BENOEM WAT JE ZIET',
    'type.matchTranslation': 'KOPPELEN',
    'type.match': 'KOPPELEN',
    'type.inputListenGaps': 'AANVULLEN',
    'type.inputListenWrite': 'SCHRIJF WAT JE HOORT',
    'type.matchAudio': 'KOPPEL DE AUDIO',
    'instruction.default': 'Maak de oefening.',
    'instruction.inputMissingWord':
        'De eerste letter staat er al: typ het hele woord.',
    'instruction.selectCharacter': 'Kies de optie die bij het teken hoort.',
    'instruction.select': 'Zoek het juiste antwoord.',
    'instruction.selectListen': 'Zoek het antwoord dat past bij wat je hoort.',
    'instruction.selectListenPassage': 'Luister en kies het juiste antwoord.',
    'instruction.selectRead': 'Lees en kies het juiste antwoord.',
    'instruction.selectDialogue': 'Lees de dialoog en kies het beste antwoord.',
    'instruction.selectImage': 'Zoek de bijpassende afbeelding.',
    'instruction.presentation': 'Bestudeer het woord en het gebruik ervan.',
    'instruction.dialogueLine': 'Lees of luister, en ga dan verder.',
    'instruction.dialogueLineText': 'Lees, en ga dan verder.',
    'instruction.dialogueLineAudio': 'Luister, en ga dan verder.',
    'instruction.dialogueLineAfterAudio':
        'Luister eerst; de tekst verschijnt daarna.',
    'instruction.storyCover':
        'Er begint een verhaal. Ga verder als je klaar bent.',
    'instruction.inputComplete': 'Typ de woorden die de zin aanvullen.',
    'instruction.selectComplete': 'Kies het blok dat in het gat past.',
    'instruction.select_opposite': 'Zoek het tegenovergestelde.',
    'instruction.arrangeSentence': 'Zet de woorden in de juiste volgorde.',
    'instruction.arrangeLines': 'Zet de regels in een logische volgorde.',
    'instruction.arrangeWord': 'Spel wat de afbeelding toont.',
    'instruction.inputPictureName': 'Typ de naam van de afbeelding.',
    'instruction.arrangePictureName':
        'Zet de blokken op volgorde om de afbeelding te benoemen.',
    'instruction.matchTranslation': 'Zet elk woord bij zijn vertaling.',
    'instruction.match': 'Zet de items bij elkaar die bij elkaar horen.',
    'type.assignGroups': 'IN GROEPEN SORTEREN',
    'type.assignSlots': 'VAKJES VULLEN',
    'type.assignGaps': 'GATEN VULLEN',
    'instruction.assignGroups':
        'Tik op een item en dan op de groep waar het bij hoort.',
    'instruction.assignSlots': 'Tik op een item en dan op zijn vakje.',
    'instruction.assignGaps':
        'Tik op een woord en dan op het gat dat het vult.',
    'instruction.inputListenGaps': 'Luister en vul het ontbrekende woord aan.',
    'instruction.inputListenWrite': 'Typ elk woord dat je hoort.',
    'instruction.matchAudio': 'Zet elk geluid bij zijn woord.',
    'type.inputTranslation': 'TYPE DE VERTALING',
    'type.arrangeTranslation': 'MAAK DE VERTALING',
    'type.selectContext': 'CONTEXT',
    'instruction.inputTranslation': 'Vertaal naar het {language}.',
    'instruction.arrangeTranslation':
        'Vertaal naar het {language} met de woordblokken.',
    'instruction.selectContext':
        'Gebruik de context om het juiste antwoord te kiezen.',
    'instruction.inputCompleteOne': 'Typ het woord dat de zin aanvult.',
    'instruction.inputCompleteLetters': 'Typ de ontbrekende letters.',
    'instruction.selectListenQuestion': 'Luister en beantwoord de vraag.',
    'instruction.selectListenHeard': 'Kies de zin die je hebt gehoord.',
    'instruction.selectListenMeaning':
        'Kies de betekenis van wat je hebt gehoord.',
    'type.selectPicture': 'WAT IS ER OP DE AFBEELDING?',
    'instruction.selectPicture': 'Kies de optie die het best past.',
    'instruction.arrangeWordHeard': 'Spel het woord dat je hoort.',
    'instruction.arrangeWordClue': 'Spel het woord dat de hint beschrijft.',
    'instruction.arrangeGaps': 'Kies een woord voor elk gat.',
    'type.selectCompleteAll': 'ÉÉN WOORD VOOR ALLES',
    'instruction.selectCompleteAll': 'Kies het woord dat in elk gat past.',
  };

  static const _fi = <String, String>{
    'type.default': 'HARJOITUS',
    'type.inputMissingWord': 'TÄYDENNÄ PUUTTUVA SANA',
    'type.selectCharacter': 'TUNNISTA MERKIT',
    'type.select': 'VALITSE',
    'type.selectListen': 'KUUNTELE JA VALITSE',
    'type.selectListenPassage': 'KUUNTELU',
    'type.selectRead': 'LUKEMINEN',
    'type.selectDialogue': 'DIALOGI',
    'type.selectImage': 'VALITSE KUVA',
    'type.presentation': 'MUISTIKORTTI',
    'type.dialogueLine': 'VUOROPUHELU',
    'type.storyCover': 'TARINA',
    'type.inputComplete': 'TÄYDENNÄ',
    'type.selectComplete': 'TÄYDENNÄ LAUSE',
    'type.arrangeSentence': 'MUODOSTA LAUSE',
    'type.arrangeLines': 'JÄRJESTÄ LAUSEET',
    'type.arrangeWord': 'MUODOSTA SANA',
    'type.inputPictureName': 'NIMEÄ, MITÄ NÄET',
    'type.arrangePictureName': 'NIMEÄ, MITÄ NÄET',
    'type.matchTranslation': 'YHDISTÄ',
    'type.match': 'YHDISTÄ',
    'type.inputListenGaps': 'TÄYDENNÄ',
    'type.inputListenWrite': 'KIRJOITA KUULEMASI',
    'type.matchAudio': 'YHDISTÄ ÄÄNI',
    'instruction.default': 'Tee harjoitus.',
    'instruction.inputMissingWord':
        'Ensimmäinen kirjain on annettu: kirjoita koko sana.',
    'instruction.selectCharacter': 'Valitse merkkiä vastaava vaihtoehto.',
    'instruction.select': 'Etsi oikea vastaus.',
    'instruction.selectListen': 'Etsi vastaus, joka vastaa kuulemaasi.',
    'instruction.selectListenPassage': 'Kuuntele ja valitse oikea vastaus.',
    'instruction.selectRead': 'Lue ja valitse oikea vastaus.',
    'instruction.selectDialogue': 'Lue dialogi ja valitse paras vastaus.',
    'instruction.selectImage': 'Etsi sopiva kuva.',
    'instruction.presentation': 'Opiskele sanaa ja sen käyttöä.',
    'instruction.dialogueLine': 'Lue tai kuuntele, sitten jatka.',
    'instruction.dialogueLineText': 'Lue, sitten jatka.',
    'instruction.dialogueLineAudio': 'Kuuntele, sitten jatka.',
    'instruction.dialogueLineAfterAudio':
        'Kuuntele ensin; teksti tulee näkyviin sen jälkeen.',
    'instruction.storyCover': 'Tarina alkaa. Jatka, kun olet valmis.',
    'instruction.inputComplete': 'Kirjoita sanat, jotka täydentävät lauseen.',
    'instruction.selectComplete': 'Valitse lohko, joka sopii aukkoon.',
    'instruction.select_opposite': 'Etsi vastakohta.',
    'instruction.arrangeSentence': 'Laita sanat oikeaan järjestykseen.',
    'instruction.arrangeLines': 'Järjestä rivit loogiseen järjestykseen.',
    'instruction.arrangeWord': 'Tavaa, mitä kuva esittää.',
    'instruction.inputPictureName': 'Kirjoita kuvan nimi.',
    'instruction.arrangePictureName': 'Järjestä lohkot nimetäksesi kuvan.',
    'instruction.matchTranslation':
        'Yhdistä pariksi jokainen sana ja sen käännös.',
    'instruction.match': 'Yhdistä pariksi yhteen kuuluvat kohteet.',
    'type.assignGroups': 'LAJITTELE RYHMIIN',
    'type.assignSlots': 'TÄYTÄ PAIKAT',
    'type.assignGaps': 'TÄYTÄ AUKOT',
    'instruction.assignGroups':
        'Napauta kohdetta ja sitten ryhmää, johon se kuuluu.',
    'instruction.assignSlots': 'Napauta kohdetta ja sitten sen paikkaa.',
    'instruction.assignGaps':
        'Napauta sanaa ja sitten aukkoa, jonka se täyttää.',
    'instruction.inputListenGaps': 'Kuuntele ja täydennä puuttuva sana.',
    'instruction.inputListenWrite': 'Kirjoita jokainen kuulemasi sana.',
    'instruction.matchAudio': 'Yhdistä pariksi jokainen ääni ja sen sana.',
    'type.inputTranslation': 'KIRJOITA KÄÄNNÖS',
    'type.arrangeTranslation': 'MUODOSTA KÄÄNNÖS',
    'type.selectContext': 'KONTEKSTI',
    'instruction.inputTranslation': 'Käännä kielelle {language}.',
    'instruction.arrangeTranslation':
        'Käännä kielelle {language} sanalohkoilla.',
    'instruction.selectContext': 'Valitse oikea vastaus kontekstin avulla.',
    'instruction.inputCompleteOne': 'Kirjoita sana, joka täydentää lauseen.',
    'instruction.inputCompleteLetters': 'Kirjoita puuttuvat kirjaimet.',
    'instruction.selectListenQuestion': 'Kuuntele ja vastaa kysymykseen.',
    'instruction.selectListenHeard': 'Valitse lause, jonka kuulit.',
    'instruction.selectListenMeaning': 'Valitse sen merkitys, mitä kuulit.',
    'type.selectPicture': 'MITÄ KUVASSA ON?',
    'instruction.selectPicture': 'Valitse parhaiten sopiva vaihtoehto.',
    'instruction.arrangeWordHeard': 'Tavaa sana, jonka kuulet.',
    'instruction.arrangeWordClue': 'Tavaa sana, jota vihje kuvaa.',
    'instruction.arrangeGaps': 'Valitse sana jokaiseen aukkoon.',
    'type.selectCompleteAll': 'YKSI SANA KAIKKIIN',
    'instruction.selectCompleteAll':
        'Valitse sana, joka sopii jokaiseen aukkoon.',
  };

  static const _cy = <String, String>{
    'type.default': 'YMARFER',
    'type.inputMissingWord': 'CWBLHAU’R GAIR COLL',
    'type.selectCharacter': 'ADNABOD NODAU',
    'type.select': 'DEWIS',
    'type.selectListen': 'GWRANDO A DEWIS',
    'type.selectListenPassage': 'GWRANDO',
    'type.selectRead': 'DARLLEN',
    'type.selectDialogue': 'DEIALOG',
    'type.selectImage': 'DEWIS Y DDELWEDD',
    'type.presentation': 'CERDYN',
    'type.dialogueLine': 'DEIALOG',
    'type.storyCover': 'STORI',
    'type.inputComplete': 'CWBLHAU',
    'type.selectComplete': 'CWBLHAU’R FRAWDDEG',
    'type.arrangeSentence': 'FFURFIO’R FRAW DDEG',
    'type.arrangeLines': 'RHOWCH Y BRAWDDEGAU MEWN TREFN',
    'type.arrangeWord': 'FFURFIO’R GAIR',
    'type.inputPictureName': 'ENWCH YR HYN A WELWCH',
    'type.arrangePictureName': 'ENWCH YR HYN A WELWCH',
    'type.matchTranslation': 'PARU',
    'type.match': 'PARU',
    'type.inputListenGaps': 'CWBLHAU',
    'type.inputListenWrite': 'YSGRIFENNU’R HYN A GLYWCH',
    'type.matchAudio': 'PARU’R SAIN',
    'instruction.default': 'Cwblhewch yr ymarfer.',
    'instruction.inputMissingWord':
        'Mae’r llythyren gyntaf wedi’i rhoi: teipiwch y gair cyfan.',
    'instruction.selectCharacter': 'Dewiswch yr opsiwn sy’n cyfateb i’r nod.',
    'instruction.select': 'Dewch o hyd i’r ateb cywir.',
    'instruction.selectListen':
        'Dewch o hyd i’r ateb sy’n cyfateb i’r hyn a glywch.',
    'instruction.selectListenPassage': 'Gwrandewch a dewiswch yr ateb cywir.',
    'instruction.selectRead': 'Darllenwch a dewiswch yr ateb cywir.',
    'instruction.selectDialogue':
        'Darllenwch y deialog a dewiswch yr ateb gorau.',
    'instruction.selectImage': 'Dewch o hyd i’r llun cyfatebol.',
    'instruction.presentation': 'Astudiwch y gair a’i ddefnydd.',
    'instruction.dialogueLine': 'Darllenwch neu gwrandewch, yna parhewch.',
    'instruction.dialogueLineText': 'Darllenwch, yna parhewch.',
    'instruction.dialogueLineAudio': 'Gwrandewch, yna parhewch.',
    'instruction.dialogueLineAfterAudio':
        'Gwrandewch yn gyntaf; mae’r testun yn ymddangos wedyn.',
    'instruction.storyCover':
        'Mae stori yn dechrau. Parhewch pan fyddwch yn barod.',
    'instruction.inputComplete': 'Teipiwch y geiriau sy’n cwblhau’r frawddeg.',
    'instruction.selectComplete': 'Dewiswch y bloc sy’n ffitio’r bwlch.',
    'instruction.select_opposite': 'Dewch o hyd i’r gwrthwyneb.',
    'instruction.arrangeSentence': 'Rhowch y geiriau yn y drefn gywir.',
    'instruction.arrangeLines': 'Rhowch y llinellau mewn trefn resymegol.',
    'instruction.arrangeWord': 'Sillafwch yr hyn y mae’r llun yn ei ddangos.',
    'instruction.inputPictureName': 'Teipiwch enw’r llun.',
    'instruction.arrangePictureName':
        'Rhowch y blociau mewn trefn i enwi’r llun.',
    'instruction.matchTranslation': 'Rhowch bob gair gyda’i gyfieithiad.',
    'instruction.match': 'Rhowch yr eitemau sy’n perthyn gyda’i gilydd.',
    'type.assignGroups': 'DIDOLI I GRWPIAU',
    'type.assignSlots': 'LLENWI’R SLOTIAU',
    'type.assignGaps': 'LLENWI’R BYLCHAU',
    'instruction.assignGroups':
        'Tapiwch eitem, yna’r grŵp y mae’n perthyn iddo.',
    'instruction.assignSlots': 'Tapiwch eitem, yna ei slot.',
    'instruction.assignGaps': 'Tapiwch air, yna’r bwlch y mae’n ei lenwi.',
    'instruction.inputListenGaps': 'Gwrandewch a chwblhewch y gair coll.',
    'instruction.inputListenWrite': 'Teipiwch bob gair a glywch.',
    'instruction.matchAudio': 'Rhowch bob sain gyda’i air.',
    'type.inputTranslation': 'TEIPIO’R CYFIEITHIAD',
    'type.arrangeTranslation': 'FFURFIO’R CYFIEITHIAD',
    'type.selectContext': 'CYD-DESTUN',
    'instruction.inputTranslation': 'Cyfieithwch i’r {language}.',
    'instruction.arrangeTranslation':
        'Cyfieithwch i’r {language} gyda’r blociau geiriau.',
    'instruction.selectContext':
        'Defnyddiwch y cyd-destun i ddewis yr ateb cywir.',
    'instruction.inputCompleteOne': 'Teipiwch y gair sy’n cwblhau’r frawddeg.',
    'instruction.inputCompleteLetters': 'Teipiwch y llythrennau coll.',
    'instruction.selectListenQuestion': 'Gwrandewch ac atebwch y cwestiwn.',
    'instruction.selectListenHeard': 'Dewiswch y frawddeg a glywsoch.',
    'instruction.selectListenMeaning': 'Dewiswch ystyr yr hyn a glywsoch.',
    'type.selectPicture': 'BETH SYDD YN Y LLUN?',
    'instruction.selectPicture': 'Dewiswch yr opsiwn sy’n gweddu orau.',
    'instruction.arrangeWordHeard': 'Sillafwch y gair a glywch.',
    'instruction.arrangeWordClue':
        'Sillafwch y gair y mae’r cliw yn ei ddisgrifio.',
    'instruction.arrangeGaps': 'Dewiswch air ar gyfer pob bwlch.',
    'type.selectCompleteAll': 'UN GAIR I BOB UN',
    'instruction.selectCompleteAll': 'Dewiswch y gair sy’n llenwi pob bwlch.',
  };
}
