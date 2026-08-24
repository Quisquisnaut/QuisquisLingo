import '../models/course_models.dart';

/// Learner-facing exercise labels and instructions.
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

  static String typeLabel(Course course, String type) {
    final c = _copy(course);
    return c['type.$type'] ?? c['type.default']!;
  }

  static String instruction(Course course, String type) {
    final c = _copy(course);
    return c['instruction.$type'] ?? c['instruction.default']!;
  }

  static String instructionForExercise(Course course, Exercise exercise) {
    final prompt=exercise.prompt.trim().toLowerCase();
    final c=_copy(course);
    if(prompt.contains('opposite')||prompt.contains('contrari')||prompt.contains('gegens')||prompt.contains('opuestos')||prompt.contains('opostos')||prompt.contains('tegenstell')||prompt.contains('vastakoht')||prompt.contains('croes')){
      if(exercise.type=='choice')return c['instruction.choice_opposite']??instruction(course,exercise.type);
      if(exercise.type=='super_match'||exercise.type=='matching')return c['instruction.super_match_opposite']??instruction(course,exercise.type);
    }
    return instruction(course,exercise.type);
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
    'type.choice': 'CHOOSE',
    'type.listening_choice': 'LISTEN AND CHOOSE',
    'type.listening_comprehension': 'LISTENING',
    'type.reading_comprehension': 'READING',
    'type.dialogue_response': 'DIALOGUE',
    'type.icon_choice': 'CHOOSE THE IMAGE',
    'type.flashcard': 'FLASHCARD',
    'type.fill_blank': 'COMPLETE',
    'type.gap_choice': 'COMPLETE THE SENTENCE',
    'type.word_order': 'BUILD THE SENTENCE',
    'type.image_word': 'BUILD THE WORD',
    'type.matching': 'MATCH',
    'type.word_match': 'MATCH',
    'type.super_match': 'MATCH',
    'type.missing_word': 'COMPLETE',
    'type.listening_spelling': 'WRITE WHAT YOU HEAR',
    'type.audio_match': 'MATCH THE AUDIO',
    'instruction.default': 'Complete the exercise.',
    'instruction.choice': 'Choose the correct answer.',
    'instruction.listening_choice': 'Listen and choose the correct answer.',
    'instruction.listening_comprehension': 'Listen and choose the correct answer.',
    'instruction.reading_comprehension': 'Read and choose the correct answer.',
    'instruction.dialogue_response': 'Read the dialogue and choose the best response.',
    'instruction.icon_choice': 'Choose the image that matches.',
    'instruction.flashcard': 'Study the word and its usage.',
    'instruction.fill_blank': 'Choose the word that completes the sentence.',
    'instruction.gap_choice': 'Choose the block that best completes the sentence.',
    'instruction.choice_opposite': 'Choose the opposite.',
    'instruction.super_match_opposite': 'Match each word with its opposite.',
    'instruction.word_order': 'Put the words in the correct order.',
    'instruction.image_word': 'Build the word shown in the image.',
    'instruction.matching': 'Match each item with its pair.',
    'instruction.word_match': 'Match each word with its translation.',
    'instruction.super_match': 'Match the corresponding items.',
    'instruction.missing_word': 'Listen and complete the missing word.',
    'instruction.listening_spelling': 'Listen and write what you hear.',
    'instruction.audio_match': 'Listen and match each sound with the correct word.',
  };

  static const _es = <String, String>{
    'type.default': 'EJERCICIO', 'type.choice': 'ELIGE', 'type.listening_choice': 'ESCUCHA Y ELIGE',
    'type.listening_comprehension': 'COMPRENSIÓN ORAL', 'type.reading_comprehension': 'LECTURA', 'type.dialogue_response': 'DIÁLOGO',
    'type.icon_choice': 'ELIGE LA IMAGEN', 'type.flashcard': 'TARJETA', 'type.fill_blank': 'COMPLETA', 'type.gap_choice': 'COMPLETA LA FRASE', 'type.word_order': 'FORMA LA FRASE',
    'type.image_word': 'FORMA LA PALABRA', 'type.matching': 'RELACIONA', 'type.word_match': 'RELACIONA', 'type.super_match': 'RELACIONA',
    'type.missing_word': 'COMPLETA', 'type.listening_spelling': 'ESCRIBE LO QUE OYES', 'type.audio_match': 'RELACIONA EL AUDIO',
    'instruction.default': 'Completa el ejercicio.', 'instruction.choice': 'Elige la respuesta correcta.',
    'instruction.listening_choice': 'Escucha y elige la respuesta correcta.', 'instruction.listening_comprehension': 'Escucha y elige la respuesta correcta.',
    'instruction.reading_comprehension': 'Lee y elige la respuesta correcta.', 'instruction.dialogue_response': 'Lee el diálogo y elige la mejor respuesta.',
    'instruction.icon_choice': 'Elige la imagen correcta.', 'instruction.flashcard': 'Estudia la palabra y su uso.',
    'instruction.fill_blank': 'Elige la palabra que completa la frase.', 'instruction.gap_choice': 'Elige el bloque que mejor completa la frase.', 'instruction.choice_opposite': 'Elige el contrario.', 'instruction.super_match_opposite': 'Relaciona cada palabra con su contrario.', 'instruction.word_order': 'Pon las palabras en el orden correcto.',
    'instruction.image_word': 'Forma la palabra que aparece en la imagen.', 'instruction.matching': 'Relaciona cada elemento con su pareja.',
    'instruction.word_match': 'Relaciona cada palabra con su traducción.', 'instruction.super_match': 'Relaciona los elementos correspondientes.',
    'instruction.missing_word': 'Escucha y completa la palabra que falta.', 'instruction.listening_spelling': 'Escucha y escribe lo que oyes.',
    'instruction.audio_match': 'Escucha y relaciona cada audio con la palabra correcta.',
  };

  static const _it = <String, String>{
    'type.default': 'ESERCIZIO', 'type.choice': 'SCEGLI', 'type.listening_choice': 'ASCOLTA E SCEGLI', 'type.listening_comprehension': 'ASCOLTO',
    'type.reading_comprehension': 'LETTURA', 'type.dialogue_response': 'DIALOGO', 'type.icon_choice': 'SCEGLI L’IMMAGINE', 'type.flashcard': 'FLASHCARD',
    'type.fill_blank': 'COMPLETA', 'type.gap_choice': 'COMPLETA LA FRASE', 'type.word_order': 'COMPONI LA FRASE', 'type.image_word': 'COMPONI LA PAROLA', 'type.matching': 'ABBINA',
    'type.word_match': 'ABBINA', 'type.super_match': 'ABBINA', 'type.missing_word': 'COMPLETA', 'type.listening_spelling': 'SCRIVI CIÒ CHE SENTI', 'type.audio_match': 'ABBINA L’AUDIO',
    'instruction.default': 'Completa l’esercizio.', 'instruction.choice': 'Scegli la risposta corretta.', 'instruction.listening_choice': 'Ascolta e scegli la risposta corretta.',
    'instruction.listening_comprehension': 'Ascolta e scegli la risposta corretta.', 'instruction.reading_comprehension': 'Leggi e scegli la risposta corretta.',
    'instruction.dialogue_response': 'Leggi il dialogo e scegli la risposta migliore.', 'instruction.icon_choice': 'Scegli l’immagine corretta.',
    'instruction.flashcard': 'Studia la parola e il suo uso.', 'instruction.fill_blank': 'Scegli la parola che completa la frase.', 'instruction.gap_choice': 'Scegli il blocco che completa meglio la frase.', 'instruction.choice_opposite': 'Scegli il contrario.', 'instruction.super_match_opposite': 'Abbina ogni parola al suo contrario.',
    'instruction.word_order': 'Metti le parole nell’ordine corretto.', 'instruction.image_word': 'Componi la parola mostrata nell’immagine.',
    'instruction.matching': 'Abbina ogni elemento alla sua coppia.', 'instruction.word_match': 'Abbina ogni parola alla sua traduzione.',
    'instruction.super_match': 'Abbina gli elementi corrispondenti.', 'instruction.missing_word': 'Ascolta e completa la parola mancante.',
    'instruction.listening_spelling': 'Ascolta e scrivi ciò che senti.', 'instruction.audio_match': 'Ascolta e abbina ogni audio alla parola corretta.',
  };

  static const _de = <String, String>{
    'type.default':'ÜBUNG','type.choice':'AUSWÄHLEN','type.listening_choice':'HÖREN UND AUSWÄHLEN','type.listening_comprehension':'HÖRVERSTEHEN','type.reading_comprehension':'LESEN','type.dialogue_response':'DIALOG','type.icon_choice':'BILD AUSWÄHLEN','type.flashcard':'KARTE','type.fill_blank':'ERGÄNZEN','type.gap_choice':'SATZ ERGÄNZEN','type.word_order':'SATZ BILDEN','type.image_word':'WORT BILDEN','type.matching':'ZUORDNEN','type.word_match':'ZUORDNEN','type.super_match':'ZUORDNEN','type.missing_word':'ERGÄNZEN','type.listening_spelling':'SCHREIBEN, WAS DU HÖRST','type.audio_match':'AUDIO ZUORDNEN',
    'instruction.default':'Bearbeite die Übung.','instruction.choice':'Wähle die richtige Antwort.','instruction.listening_choice':'Höre zu und wähle die richtige Antwort.','instruction.listening_comprehension':'Höre zu und wähle die richtige Antwort.','instruction.reading_comprehension':'Lies und wähle die richtige Antwort.','instruction.dialogue_response':'Lies den Dialog und wähle die beste Antwort.','instruction.icon_choice':'Wähle das passende Bild.','instruction.flashcard':'Lerne das Wort und seine Verwendung.','instruction.fill_blank':'Wähle das Wort, das den Satz vervollständigt.','instruction.gap_choice':'Wähle den Baustein, der den Satz am besten ergänzt.','instruction.choice_opposite':'Wähle das Gegenteil.','instruction.super_match_opposite':'Ordne jedes Wort seinem Gegenteil zu.','instruction.word_order':'Bringe die Wörter in die richtige Reihenfolge.','instruction.image_word':'Bilde das Wort auf dem Bild.','instruction.matching':'Ordne die passenden Elemente einander zu.','instruction.word_match':'Ordne jedes Wort seiner Übersetzung zu.','instruction.super_match':'Ordne die passenden Elemente einander zu.','instruction.missing_word':'Höre zu und ergänze das fehlende Wort.','instruction.listening_spelling':'Höre zu und schreibe, was du hörst.','instruction.audio_match':'Höre zu und ordne jeden Ton dem richtigen Wort zu.',
  };

  static const _pt = <String, String>{
    'type.default':'EXERCÍCIO','type.choice':'ESCOLHER','type.listening_choice':'OUVIR E ESCOLHER','type.listening_comprehension':'COMPREENSÃO ORAL','type.reading_comprehension':'LEITURA','type.dialogue_response':'DIÁLOGO','type.icon_choice':'ESCOLHER A IMAGEM','type.flashcard':'CARTÃO','type.fill_blank':'COMPLETAR','type.gap_choice':'COMPLETAR A FRASE','type.word_order':'FORMAR A FRASE','type.image_word':'FORMAR A PALAVRA','type.matching':'ASSOCIAR','type.word_match':'ASSOCIAR','type.super_match':'ASSOCIAR','type.missing_word':'COMPLETAR','type.listening_spelling':'ESCREVER O QUE OUVE','type.audio_match':'ASSOCIAR O ÁUDIO',
    'instruction.default':'Complete o exercício.','instruction.choice':'Escolha a resposta correta.','instruction.listening_choice':'Ouça e escolha a resposta correta.','instruction.listening_comprehension':'Ouça e escolha a resposta correta.','instruction.reading_comprehension':'Leia e escolha a resposta correta.','instruction.dialogue_response':'Leia o diálogo e escolha a melhor resposta.','instruction.icon_choice':'Escolha a imagem correta.','instruction.flashcard':'Estude a palavra e o seu uso.','instruction.fill_blank':'Escolha a palavra que completa a frase.','instruction.gap_choice':'Escolha o bloco que melhor completa a frase.','instruction.choice_opposite':'Escolha o oposto.','instruction.super_match_opposite':'Associe cada palavra ao seu oposto.','instruction.word_order':'Coloque as palavras na ordem correta.','instruction.image_word':'Forme a palavra mostrada na imagem.','instruction.matching':'Associe cada elemento ao seu par.','instruction.word_match':'Associe cada palavra à sua tradução.','instruction.super_match':'Associe os elementos correspondentes.','instruction.missing_word':'Ouça e complete a palavra em falta.','instruction.listening_spelling':'Ouça e escreva o que ouve.','instruction.audio_match':'Ouça e associe cada áudio à palavra correta.',
  };

  static const _nl = <String, String>{
    'type.default':'OEFENING','type.choice':'KIEZEN','type.listening_choice':'LUISTER EN KIES','type.listening_comprehension':'LUISTEREN','type.reading_comprehension':'LEZEN','type.dialogue_response':'DIALOOG','type.icon_choice':'KIES DE AFBEELDING','type.flashcard':'FLASHCARD','type.fill_blank':'AANVULLEN','type.gap_choice':'ZIN AANVULLEN','type.word_order':'MAAK DE ZIN','type.image_word':'MAAK HET WOORD','type.matching':'KOPPELEN','type.word_match':'KOPPELEN','type.super_match':'KOPPELEN','type.missing_word':'AANVULLEN','type.listening_spelling':'SCHRIJF WAT JE HOORT','type.audio_match':'KOPPEL DE AUDIO',
    'instruction.default':'Maak de oefening.','instruction.choice':'Kies het juiste antwoord.','instruction.listening_choice':'Luister en kies het juiste antwoord.','instruction.listening_comprehension':'Luister en kies het juiste antwoord.','instruction.reading_comprehension':'Lees en kies het juiste antwoord.','instruction.dialogue_response':'Lees de dialoog en kies het beste antwoord.','instruction.icon_choice':'Kies de juiste afbeelding.','instruction.flashcard':'Bestudeer het woord en het gebruik ervan.','instruction.fill_blank':'Kies het woord dat de zin aanvult.','instruction.gap_choice':'Kies het blok dat de zin het best aanvult.','instruction.choice_opposite':'Kies het tegenovergestelde.','instruction.super_match_opposite':'Koppel elk woord aan het tegenovergestelde.','instruction.word_order':'Zet de woorden in de juiste volgorde.','instruction.image_word':'Maak het woord dat op de afbeelding staat.','instruction.matching':'Koppel elk item aan het juiste paar.','instruction.word_match':'Koppel elk woord aan de vertaling.','instruction.super_match':'Koppel de bijbehorende items.','instruction.missing_word':'Luister en vul het ontbrekende woord aan.','instruction.listening_spelling':'Luister en schrijf wat je hoort.','instruction.audio_match':'Luister en koppel elk geluid aan het juiste woord.',
  };

  static const _fi = <String, String>{
    'type.default':'HARJOITUS','type.choice':'VALITSE','type.listening_choice':'KUUNTELE JA VALITSE','type.listening_comprehension':'KUUNTELU','type.reading_comprehension':'LUKEMINEN','type.dialogue_response':'DIALOGI','type.icon_choice':'VALITSE KUVA','type.flashcard':'MUISTIKORTTI','type.fill_blank':'TÄYDENNÄ','type.gap_choice':'TÄYDENNÄ LAUSE','type.word_order':'MUODOSTA LAUSE','type.image_word':'MUODOSTA SANA','type.matching':'YHDISTÄ','type.word_match':'YHDISTÄ','type.super_match':'YHDISTÄ','type.missing_word':'TÄYDENNÄ','type.listening_spelling':'KIRJOITA KUULEMASI','type.audio_match':'YHDISTÄ ÄÄNI',
    'instruction.default':'Tee harjoitus.','instruction.choice':'Valitse oikea vastaus.','instruction.listening_choice':'Kuuntele ja valitse oikea vastaus.','instruction.listening_comprehension':'Kuuntele ja valitse oikea vastaus.','instruction.reading_comprehension':'Lue ja valitse oikea vastaus.','instruction.dialogue_response':'Lue dialogi ja valitse paras vastaus.','instruction.icon_choice':'Valitse oikea kuva.','instruction.flashcard':'Opiskele sanaa ja sen käyttöä.','instruction.fill_blank':'Valitse sana, joka täydentää lauseen.','instruction.gap_choice':'Valitse lohko, joka täydentää lauseen parhaiten.','instruction.choice_opposite':'Valitse vastakohta.','instruction.super_match_opposite':'Yhdistä jokainen sana vastakohtaansa.','instruction.word_order':'Laita sanat oikeaan järjestykseen.','instruction.image_word':'Muodosta kuvassa näkyvä sana.','instruction.matching':'Yhdistä jokainen kohde oikeaan pariin.','instruction.word_match':'Yhdistä jokainen sana sen käännökseen.','instruction.super_match':'Yhdistä toisiaan vastaavat kohteet.','instruction.missing_word':'Kuuntele ja täydennä puuttuva sana.','instruction.listening_spelling':'Kuuntele ja kirjoita kuulemasi.','instruction.audio_match':'Kuuntele ja yhdistä jokainen ääni oikeaan sanaan.',
  };

  static const _cy = <String, String>{
    'type.default':'YMARFER','type.choice':'DEWIS','type.listening_choice':'GWRANDO A DEWIS','type.listening_comprehension':'GWRANDO','type.reading_comprehension':'DARLLEN','type.dialogue_response':'DEIALOG','type.icon_choice':'DEWIS Y DDELWEDD','type.flashcard':'CERDYN','type.fill_blank':'CWBLHAU','type.gap_choice':'CWBLHAU’R FRAWDDEG','type.word_order':'FFURFIO’R FRAW DDEG','type.image_word':'FFURFIO’R GAIR','type.matching':'PARU','type.word_match':'PARU','type.super_match':'PARU','type.missing_word':'CWBLHAU','type.listening_spelling':'YSGRIFENNU’R HYN A GLYWCH','type.audio_match':'PARU’R SAIN',
    'instruction.default':'Cwblhewch yr ymarfer.','instruction.choice':'Dewiswch yr ateb cywir.','instruction.listening_choice':'Gwrandewch a dewiswch yr ateb cywir.','instruction.listening_comprehension':'Gwrandewch a dewiswch yr ateb cywir.','instruction.reading_comprehension':'Darllenwch a dewiswch yr ateb cywir.','instruction.dialogue_response':'Darllenwch y deialog a dewiswch yr ateb gorau.','instruction.icon_choice':'Dewiswch y ddelwedd gywir.','instruction.flashcard':'Astudiwch y gair a’i ddefnydd.','instruction.fill_blank':'Dewiswch y gair sy’n cwblhau’r frawddeg.','instruction.gap_choice':'Dewiswch y bloc sy’n cwblhau’r frawddeg orau.','instruction.choice_opposite':'Dewiswch y gwrthwyneb.','instruction.super_match_opposite':'Parwch bob gair â’i wrthwyneb.','instruction.word_order':'Rhowch y geiriau yn y drefn gywir.','instruction.image_word':'Ffurfiwch y gair a ddangosir yn y ddelwedd.','instruction.matching':'Parwch bob eitem â’i phâr.','instruction.word_match':'Parwch bob gair â’i gyfieithiad.','instruction.super_match':'Parwch yr eitemau cyfatebol.','instruction.missing_word':'Gwrandewch a chwblhewch y gair coll.','instruction.listening_spelling':'Gwrandewch ac ysgrifennwch yr hyn a glywch.','instruction.audio_match':'Gwrandewch a pharwch bob sain â’r gair cywir.',
  };
}
