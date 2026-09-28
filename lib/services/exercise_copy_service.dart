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

  /// The learner instruction for an exercise of [kind].
  static String instruction(Course course, LearnerExerciseKind kind) {
    final c = _copy(course);
    return c['instruction.${kind.name}'] ?? c['instruction.default']!;
  }

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
    if (prompt.contains('opposite') ||
        prompt.contains('contrari') ||
        prompt.contains('gegens') ||
        prompt.contains('opuestos') ||
        prompt.contains('opostos') ||
        prompt.contains('tegenstell') ||
        prompt.contains('vastakoht') ||
        prompt.contains('croes')) {
      if (kind == LearnerExerciseKind.select) {
        return c['instruction.select_opposite'] ?? instruction(course, kind);
      }
      if (kind == LearnerExerciseKind.match ||
          kind == LearnerExerciseKind.matchTranslation) {
        return c['instruction.match_opposite'] ?? instruction(course, kind);
      }
    }
    return instruction(course, kind);
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
        'Enter the complete missing word. The first letter shown is a hint.',
    'instruction.selectCharacter':
        'Choose the option that matches the character.',
    'instruction.select': 'Choose the correct answer.',
    'instruction.selectListen': 'Listen and choose the correct answer.',
    'instruction.selectListenPassage': 'Listen and choose the correct answer.',
    'instruction.selectRead': 'Read and choose the correct answer.',
    'instruction.selectDialogue':
        'Read the dialogue and choose the best response.',
    'instruction.selectImage': 'Choose the image that matches.',
    'instruction.presentation': 'Study the word and its usage.',
    'instruction.dialogueLine': 'Read or listen, then continue.',
    'instruction.storyCover': 'A story begins. Continue when you are ready.',
    'instruction.inputComplete': 'Choose the word that completes the sentence.',
    'instruction.selectComplete':
        'Choose the block that best completes the sentence.',
    'instruction.select_opposite': 'Choose the opposite.',
    'instruction.match_opposite': 'Match each word with its opposite.',
    'instruction.arrangeSentence': 'Put the words in the correct order.',
    'instruction.arrangeLines': 'Put the sentences in the correct order.',
    'instruction.arrangeWord': 'Build the word shown in the image.',
    'instruction.matchTranslation': 'Match each word with its translation.',
    'instruction.match': 'Match the corresponding items.',
    'instruction.inputListenGaps': 'Listen and complete the missing word.',
    'instruction.inputListenWrite': 'Listen and write what you hear.',
    'instruction.matchAudio':
        'Listen and match each sound with the correct word.',
    'instruction.inputTranslation': 'Type the translation.',
    'instruction.arrangeTranslation':
        'Build the translation from the word blocks.',
    'instruction.selectContext':
        'Use the context to choose the correct answer.',
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
    'type.matchTranslation': 'RELACIONA',
    'type.match': 'RELACIONA',
    'type.inputListenGaps': 'COMPLETA',
    'type.inputListenWrite': 'ESCRIBE LO QUE OYES',
    'type.matchAudio': 'RELACIONA EL AUDIO',
    'instruction.default': 'Completa el ejercicio.',
    'instruction.inputMissingWord':
        'Escribe la palabra completa que falta. La primera letra mostrada es una pista.',
    'instruction.selectCharacter':
        'Elige la opción que corresponde al carácter.',
    'instruction.select': 'Elige la respuesta correcta.',
    'instruction.selectListen': 'Escucha y elige la respuesta correcta.',
    'instruction.selectListenPassage': 'Escucha y elige la respuesta correcta.',
    'instruction.selectRead': 'Lee y elige la respuesta correcta.',
    'instruction.selectDialogue': 'Lee el diálogo y elige la mejor respuesta.',
    'instruction.selectImage': 'Elige la imagen correcta.',
    'instruction.presentation': 'Estudia la palabra y su uso.',
    'instruction.dialogueLine': 'Lee o escucha, luego continúa.',
    'instruction.storyCover':
        'Empieza una historia. Continúa cuando estés listo.',
    'instruction.inputComplete': 'Elige la palabra que completa la frase.',
    'instruction.selectComplete':
        'Elige el bloque que mejor completa la frase.',
    'instruction.select_opposite': 'Elige el contrario.',
    'instruction.match_opposite': 'Relaciona cada palabra con su contrario.',
    'instruction.arrangeSentence': 'Pon las palabras en el orden correcto.',
    'instruction.arrangeLines': 'Pon las frases en el orden correcto.',
    'instruction.arrangeWord': 'Forma la palabra que aparece en la imagen.',
    'instruction.matchTranslation': 'Relaciona cada palabra con su traducción.',
    'instruction.match': 'Relaciona los elementos correspondientes.',
    'instruction.inputListenGaps': 'Escucha y completa la palabra que falta.',
    'instruction.inputListenWrite': 'Escucha y escribe lo que oyes.',
    'instruction.matchAudio':
        'Escucha y relaciona cada audio con la palabra correcta.',
    'type.inputTranslation': 'ESCRIBE LA TRADUCCIÓN',
    'type.arrangeTranslation': 'FORMA LA TRADUCCIÓN',
    'type.selectContext': 'CONTEXTO',
    'instruction.inputTranslation': 'Escribe la traducción.',
    'instruction.arrangeTranslation':
        'Forma la traducción con los bloques de palabras.',
    'instruction.selectContext':
        'Usa el contexto para elegir la respuesta correcta.',
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
    'type.matchTranslation': 'ABBINA',
    'type.match': 'ABBINA',
    'type.inputListenGaps': 'COMPLETA',
    'type.inputListenWrite': 'SCRIVI CIÒ CHE SENTI',
    'type.matchAudio': 'ABBINA L’AUDIO',
    'instruction.default': 'Completa l’esercizio.',
    'instruction.inputMissingWord':
        'Scrivi la parola mancante completa. La prima lettera mostrata è un suggerimento.',
    'instruction.selectCharacter':
        'Scegli l’opzione che corrisponde al carattere.',
    'instruction.select': 'Scegli la risposta corretta.',
    'instruction.selectListen': 'Ascolta e scegli la risposta corretta.',
    'instruction.selectListenPassage': 'Ascolta e scegli la risposta corretta.',
    'instruction.selectRead': 'Leggi e scegli la risposta corretta.',
    'instruction.selectDialogue':
        'Leggi il dialogo e scegli la risposta migliore.',
    'instruction.selectImage': 'Scegli l’immagine corretta.',
    'instruction.presentation': 'Studia la parola e il suo uso.',
    'instruction.dialogueLine': 'Leggi o ascolta, poi continua.',
    'instruction.storyCover': 'Inizia una storia. Continua quando sei pronto.',
    'instruction.inputComplete': 'Scegli la parola che completa la frase.',
    'instruction.selectComplete':
        'Scegli il blocco che completa meglio la frase.',
    'instruction.select_opposite': 'Scegli il contrario.',
    'instruction.match_opposite': 'Abbina ogni parola al suo contrario.',
    'instruction.arrangeSentence': 'Metti le parole nell’ordine corretto.',
    'instruction.arrangeLines': 'Metti le frasi nell’ordine corretto.',
    'instruction.arrangeWord': 'Componi la parola mostrata nell’immagine.',
    'instruction.matchTranslation': 'Abbina ogni parola alla sua traduzione.',
    'instruction.match': 'Abbina gli elementi corrispondenti.',
    'instruction.inputListenGaps': 'Ascolta e completa la parola mancante.',
    'instruction.inputListenWrite': 'Ascolta e scrivi ciò che senti.',
    'instruction.matchAudio':
        'Ascolta e abbina ogni audio alla parola corretta.',
    'type.inputTranslation': 'SCRIVI LA TRADUZIONE',
    'type.arrangeTranslation': 'COMPONI LA TRADUZIONE',
    'type.selectContext': 'CONTESTO',
    'instruction.inputTranslation': 'Scrivi la traduzione.',
    'instruction.arrangeTranslation':
        'Componi la traduzione con i blocchi di parole.',
    'instruction.selectContext':
        'Usa il contesto per scegliere la risposta corretta.',
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
    'type.matchTranslation': 'ZUORDNEN',
    'type.match': 'ZUORDNEN',
    'type.inputListenGaps': 'ERGÄNZEN',
    'type.inputListenWrite': 'SCHREIBEN, WAS DU HÖRST',
    'type.matchAudio': 'AUDIO ZUORDNEN',
    'instruction.default': 'Bearbeite die Übung.',
    'instruction.inputMissingWord':
        'Schreibe das vollständige fehlende Wort. Der angezeigte erste Buchstabe ist ein Hinweis.',
    'instruction.selectCharacter': 'Wähle die Option, die zum Zeichen passt.',
    'instruction.select': 'Wähle die richtige Antwort.',
    'instruction.selectListen': 'Höre zu und wähle die richtige Antwort.',
    'instruction.selectListenPassage':
        'Höre zu und wähle die richtige Antwort.',
    'instruction.selectRead': 'Lies und wähle die richtige Antwort.',
    'instruction.selectDialogue':
        'Lies den Dialog und wähle die beste Antwort.',
    'instruction.selectImage': 'Wähle das passende Bild.',
    'instruction.presentation': 'Lerne das Wort und seine Verwendung.',
    'instruction.dialogueLine': 'Lies oder höre zu, dann weiter.',
    'instruction.storyCover':
        'Eine Geschichte beginnt. Weiter, wenn du bereit bist.',
    'instruction.inputComplete':
        'Wähle das Wort, das den Satz vervollständigt.',
    'instruction.selectComplete':
        'Wähle den Baustein, der den Satz am besten ergänzt.',
    'instruction.select_opposite': 'Wähle das Gegenteil.',
    'instruction.match_opposite': 'Ordne jedes Wort seinem Gegenteil zu.',
    'instruction.arrangeSentence':
        'Bringe die Wörter in die richtige Reihenfolge.',
    'instruction.arrangeLines': 'Bringe die Sätze in die richtige Reihenfolge.',
    'instruction.arrangeWord': 'Bilde das Wort auf dem Bild.',
    'instruction.matchTranslation': 'Ordne jedes Wort seiner Übersetzung zu.',
    'instruction.match': 'Ordne die passenden Elemente einander zu.',
    'instruction.inputListenGaps': 'Höre zu und ergänze das fehlende Wort.',
    'instruction.inputListenWrite': 'Höre zu und schreibe, was du hörst.',
    'instruction.matchAudio':
        'Höre zu und ordne jeden Ton dem richtigen Wort zu.',
    'type.inputTranslation': 'ÜBERSETZUNG EINGEBEN',
    'type.arrangeTranslation': 'ÜBERSETZUNG BILDEN',
    'type.selectContext': 'KONTEXT',
    'instruction.inputTranslation': 'Gib die Übersetzung ein.',
    'instruction.arrangeTranslation':
        'Bilde die Übersetzung aus den Wortbausteinen.',
    'instruction.selectContext':
        'Nutze den Kontext, um die richtige Antwort auszuwählen.',
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
    'type.matchTranslation': 'ASSOCIAR',
    'type.match': 'ASSOCIAR',
    'type.inputListenGaps': 'COMPLETAR',
    'type.inputListenWrite': 'ESCREVER O QUE OUVE',
    'type.matchAudio': 'ASSOCIAR O ÁUDIO',
    'instruction.default': 'Complete o exercício.',
    'instruction.inputMissingWord':
        'Escreve a palavra em falta completa. A primeira letra apresentada é uma pista.',
    'instruction.selectCharacter':
        'Escolhe a opção que corresponde ao carácter.',
    'instruction.select': 'Escolha a resposta correta.',
    'instruction.selectListen': 'Ouça e escolha a resposta correta.',
    'instruction.selectListenPassage': 'Ouça e escolha a resposta correta.',
    'instruction.selectRead': 'Leia e escolha a resposta correta.',
    'instruction.selectDialogue': 'Leia o diálogo e escolha a melhor resposta.',
    'instruction.selectImage': 'Escolha a imagem correta.',
    'instruction.presentation': 'Estude a palavra e o seu uso.',
    'instruction.dialogueLine': 'Leia ou ouça, depois continue.',
    'instruction.storyCover':
        'Começa uma história. Continue quando estiver pronto.',
    'instruction.inputComplete': 'Escolha a palavra que completa a frase.',
    'instruction.selectComplete':
        'Escolha o bloco que melhor completa a frase.',
    'instruction.select_opposite': 'Escolha o oposto.',
    'instruction.match_opposite': 'Associe cada palavra ao seu oposto.',
    'instruction.arrangeSentence': 'Coloque as palavras na ordem correta.',
    'instruction.arrangeLines': 'Coloque as frases na ordem correta.',
    'instruction.arrangeWord': 'Forme a palavra mostrada na imagem.',
    'instruction.matchTranslation': 'Associe cada palavra à sua tradução.',
    'instruction.match': 'Associe os elementos correspondentes.',
    'instruction.inputListenGaps': 'Ouça e complete a palavra em falta.',
    'instruction.inputListenWrite': 'Ouça e escreva o que ouve.',
    'instruction.matchAudio': 'Ouça e associe cada áudio à palavra correta.',
    'type.inputTranslation': 'ESCREVER A TRADUÇÃO',
    'type.arrangeTranslation': 'FORMAR A TRADUÇÃO',
    'type.selectContext': 'CONTEXTO',
    'instruction.inputTranslation': 'Escreva a tradução.',
    'instruction.arrangeTranslation':
        'Forme a tradução com os blocos de palavras.',
    'instruction.selectContext':
        'Use o contexto para escolher a resposta correta.',
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
    'type.matchTranslation': 'KOPPELEN',
    'type.match': 'KOPPELEN',
    'type.inputListenGaps': 'AANVULLEN',
    'type.inputListenWrite': 'SCHRIJF WAT JE HOORT',
    'type.matchAudio': 'KOPPEL DE AUDIO',
    'instruction.default': 'Maak de oefening.',
    'instruction.inputMissingWord':
        'Typ het volledige ontbrekende woord. De getoonde eerste letter is een aanwijzing.',
    'instruction.selectCharacter': 'Kies de optie die bij het teken hoort.',
    'instruction.select': 'Kies het juiste antwoord.',
    'instruction.selectListen': 'Luister en kies het juiste antwoord.',
    'instruction.selectListenPassage': 'Luister en kies het juiste antwoord.',
    'instruction.selectRead': 'Lees en kies het juiste antwoord.',
    'instruction.selectDialogue': 'Lees de dialoog en kies het beste antwoord.',
    'instruction.selectImage': 'Kies de juiste afbeelding.',
    'instruction.presentation': 'Bestudeer het woord en het gebruik ervan.',
    'instruction.dialogueLine': 'Lees of luister, en ga dan verder.',
    'instruction.storyCover':
        'Er begint een verhaal. Ga verder als je klaar bent.',
    'instruction.inputComplete': 'Kies het woord dat de zin aanvult.',
    'instruction.selectComplete': 'Kies het blok dat de zin het best aanvult.',
    'instruction.select_opposite': 'Kies het tegenovergestelde.',
    'instruction.match_opposite': 'Koppel elk woord aan het tegenovergestelde.',
    'instruction.arrangeSentence': 'Zet de woorden in de juiste volgorde.',
    'instruction.arrangeLines': 'Zet de zinnen in de juiste volgorde.',
    'instruction.arrangeWord': 'Maak het woord dat op de afbeelding staat.',
    'instruction.matchTranslation': 'Koppel elk woord aan de vertaling.',
    'instruction.match': 'Koppel de bijbehorende items.',
    'instruction.inputListenGaps': 'Luister en vul het ontbrekende woord aan.',
    'instruction.inputListenWrite': 'Luister en schrijf wat je hoort.',
    'instruction.matchAudio':
        'Luister en koppel elk geluid aan het juiste woord.',
    'type.inputTranslation': 'TYPE DE VERTALING',
    'type.arrangeTranslation': 'MAAK DE VERTALING',
    'type.selectContext': 'CONTEXT',
    'instruction.inputTranslation': 'Typ de vertaling.',
    'instruction.arrangeTranslation': 'Maak de vertaling met de woordblokken.',
    'instruction.selectContext':
        'Gebruik de context om het juiste antwoord te kiezen.',
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
    'type.matchTranslation': 'YHDISTÄ',
    'type.match': 'YHDISTÄ',
    'type.inputListenGaps': 'TÄYDENNÄ',
    'type.inputListenWrite': 'KIRJOITA KUULEMASI',
    'type.matchAudio': 'YHDISTÄ ÄÄNI',
    'instruction.default': 'Tee harjoitus.',
    'instruction.inputMissingWord':
        'Kirjoita puuttuva sana kokonaan. Näytetty ensimmäinen kirjain on vihje.',
    'instruction.selectCharacter': 'Valitse merkkiä vastaava vaihtoehto.',
    'instruction.select': 'Valitse oikea vastaus.',
    'instruction.selectListen': 'Kuuntele ja valitse oikea vastaus.',
    'instruction.selectListenPassage': 'Kuuntele ja valitse oikea vastaus.',
    'instruction.selectRead': 'Lue ja valitse oikea vastaus.',
    'instruction.selectDialogue': 'Lue dialogi ja valitse paras vastaus.',
    'instruction.selectImage': 'Valitse oikea kuva.',
    'instruction.presentation': 'Opiskele sanaa ja sen käyttöä.',
    'instruction.dialogueLine': 'Lue tai kuuntele, sitten jatka.',
    'instruction.storyCover': 'Tarina alkaa. Jatka, kun olet valmis.',
    'instruction.inputComplete': 'Valitse sana, joka täydentää lauseen.',
    'instruction.selectComplete':
        'Valitse lohko, joka täydentää lauseen parhaiten.',
    'instruction.select_opposite': 'Valitse vastakohta.',
    'instruction.match_opposite': 'Yhdistä jokainen sana vastakohtaansa.',
    'instruction.arrangeSentence': 'Laita sanat oikeaan järjestykseen.',
    'instruction.arrangeLines': 'Laita lauseet oikeaan järjestykseen.',
    'instruction.arrangeWord': 'Muodosta kuvassa näkyvä sana.',
    'instruction.matchTranslation': 'Yhdistä jokainen sana sen käännökseen.',
    'instruction.match': 'Yhdistä toisiaan vastaavat kohteet.',
    'instruction.inputListenGaps': 'Kuuntele ja täydennä puuttuva sana.',
    'instruction.inputListenWrite': 'Kuuntele ja kirjoita kuulemasi.',
    'instruction.matchAudio':
        'Kuuntele ja yhdistä jokainen ääni oikeaan sanaan.',
    'type.inputTranslation': 'KIRJOITA KÄÄNNÖS',
    'type.arrangeTranslation': 'MUODOSTA KÄÄNNÖS',
    'type.selectContext': 'KONTEKSTI',
    'instruction.inputTranslation': 'Kirjoita käännös.',
    'instruction.arrangeTranslation': 'Muodosta käännös sanalohkoista.',
    'instruction.selectContext': 'Valitse oikea vastaus kontekstin avulla.',
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
    'type.matchTranslation': 'PARU',
    'type.match': 'PARU',
    'type.inputListenGaps': 'CWBLHAU',
    'type.inputListenWrite': 'YSGRIFENNU’R HYN A GLYWCH',
    'type.matchAudio': 'PARU’R SAIN',
    'instruction.default': 'Cwblhewch yr ymarfer.',
    'instruction.inputMissingWord':
        'Teipiwch y gair coll yn llawn. Mae’r llythyren gyntaf a ddangosir yn gliw.',
    'instruction.selectCharacter': 'Dewiswch yr opsiwn sy’n cyfateb i’r nod.',
    'instruction.select': 'Dewiswch yr ateb cywir.',
    'instruction.selectListen': 'Gwrandewch a dewiswch yr ateb cywir.',
    'instruction.selectListenPassage': 'Gwrandewch a dewiswch yr ateb cywir.',
    'instruction.selectRead': 'Darllenwch a dewiswch yr ateb cywir.',
    'instruction.selectDialogue':
        'Darllenwch y deialog a dewiswch yr ateb gorau.',
    'instruction.selectImage': 'Dewiswch y ddelwedd gywir.',
    'instruction.presentation': 'Astudiwch y gair a’i ddefnydd.',
    'instruction.dialogueLine': 'Darllenwch neu gwrandewch, yna parhewch.',
    'instruction.storyCover':
        'Mae stori yn dechrau. Parhewch pan fyddwch yn barod.',
    'instruction.inputComplete': 'Dewiswch y gair sy’n cwblhau’r frawddeg.',
    'instruction.selectComplete':
        'Dewiswch y bloc sy’n cwblhau’r frawddeg orau.',
    'instruction.select_opposite': 'Dewiswch y gwrthwyneb.',
    'instruction.match_opposite': 'Parwch bob gair â’i wrthwyneb.',
    'instruction.arrangeSentence': 'Rhowch y geiriau yn y drefn gywir.',
    'instruction.arrangeLines': 'Rhowch y brawddegau yn y drefn gywir.',
    'instruction.arrangeWord': 'Ffurfiwch y gair a ddangosir yn y ddelwedd.',
    'instruction.matchTranslation': 'Parwch bob gair â’i gyfieithiad.',
    'instruction.match': 'Parwch yr eitemau cyfatebol.',
    'instruction.inputListenGaps': 'Gwrandewch a chwblhewch y gair coll.',
    'instruction.inputListenWrite':
        'Gwrandewch ac ysgrifennwch yr hyn a glywch.',
    'instruction.matchAudio': 'Gwrandewch a pharwch bob sain â’r gair cywir.',
    'type.inputTranslation': 'TEIPIO’R CYFIEITHIAD',
    'type.arrangeTranslation': 'FFURFIO’R CYFIEITHIAD',
    'type.selectContext': 'CYD-DESTUN',
    'instruction.inputTranslation': 'Teipiwch y cyfieithiad.',
    'instruction.arrangeTranslation':
        'Ffurfiwch y cyfieithiad gyda’r blociau geiriau.',
    'instruction.selectContext':
        'Defnyddiwch y cyd-destun i ddewis yr ateb cywir.',
  };
}
