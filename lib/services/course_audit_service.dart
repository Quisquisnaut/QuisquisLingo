import '../models/course_models.dart';
import 'duel_eligibility_service.dart';

enum AuditSeverity { error, warning, suggestion }

class CourseAuditIssue {
  final AuditSeverity severity;
  final String code;
  final String message;
  final String location;
  final String? roundId;
  final String? exerciseId;
  const CourseAuditIssue({required this.severity,required this.message,required this.location,this.code='GENERAL',this.roundId,this.exerciseId});
}

class CourseAuditResult {
  final List<CourseAuditIssue> issues;
  final DateTime runAt;
  CourseAuditResult(this.issues):runAt=DateTime.now();
  int count(AuditSeverity s)=>issues.where((i)=>i.severity==s).length;
}

/// Author-facing static audit.
///
/// This validates structure, editor invariants, common exercise mistakes and a
/// few high-confidence consistency rules. It intentionally does not claim to
/// certify grammar, translation quality or pedagogy.
class CourseAuditService {
  static const supportedTypes={
    'choice','gap_choice','flashcard','icon_choice','fill_blank','word_order','matching',
    'listening_choice','listening_comprehension','reading_comprehension','audio_match','missing_word','listening_spelling','image_word','dialogue_response','word_match','super_match'
  };
  static const choiceTypes={'choice','gap_choice','icon_choice','listening_choice','listening_comprehension','reading_comprehension','dialogue_response'};

  String _courseSourceCode(Course course) {
    final source = course.sourceLanguage.trim().toLowerCase();
    const names = <String,String>{'english':'EN','spanish':'ES','italian':'IT','german':'DE','portuguese':'PT','dutch':'NL','finnish':'FI','welsh':'CY'};
    return names[source] ?? course.interfaceLanguage.trim().toUpperCase();
  }

  String? _legacyInstructionLanguage(String prompt) {
    const languages = <String,String>{
      'Choose the correct translation.':'EN',
      'Build the target-language word shown in the image.':'EN',
      'Build the word shown in the image.':'EN',
      'Match each translation.':'EN',
      'Match each sound to the word.':'EN',
      'Match the opposites.':'EN',
      'Abbina i contrari.':'IT',
      'Ordne die Gegensätze zu.':'DE',
      'Relaciona los contrarios.':'ES',
      'Associe os opostos.':'PT',
      'Koppel de tegenstellingen.':'NL',
      'Yhdistä vastakohdat.':'FI',
      'Parwch y geiriau croes.':'CY',
    };
    return languages[prompt.trim()];
  }

  CourseAuditResult auditCourse(Course course){
    final issues=<CourseAuditIssue>[];
    final ids=<String>{};
    final pendingSourceRefs=<MapEntry<String,String>>[];
    void idCheck(String id,String location,{String? roundId,String? exerciseId}){
      if(id.trim().isEmpty){issues.add(CourseAuditIssue(severity:AuditSeverity.error,message:'Missing ID.',location:location,roundId:roundId,exerciseId:exerciseId));}
      else if(!ids.add(id)){issues.add(CourseAuditIssue(severity:AuditSeverity.error,message:'Duplicate ID: $id',location:location,roundId:roundId,exerciseId:exerciseId));}
    }

    idCheck(course.courseId,'Course');
    if(course.sourceLanguage.trim().isEmpty||course.targetLanguage.trim().isEmpty){issues.add(const CourseAuditIssue(severity:AuditSeverity.error,message:'Source and target languages must be defined.',location:'Course'));}
    if(course.sourceLanguage.toLowerCase()==course.targetLanguage.toLowerCase()){issues.add(const CourseAuditIssue(severity:AuditSeverity.warning,message:'Source and target languages are identical.',location:'Course'));}
    if(course.authors.length>50){issues.add(const CourseAuditIssue(severity:AuditSeverity.warning,code:'COURSE_AUTHORS_MANY',message:'Course has more than 50 author entries. Check for accidental duplicates.',location:'Course info'));}
    for(final author in course.authors){
      if(author.name.trim().isEmpty)issues.add(const CourseAuditIssue(severity:AuditSeverity.warning,code:'COURSE_AUTHOR_EMPTY',message:'Course author name is empty.',location:'Course info'));
      if(author.name.length>120||author.roles.any((r)=>r.length>120))issues.add(const CourseAuditIssue(severity:AuditSeverity.warning,code:'COURSE_AUTHOR_LONG',message:'Course author name or role is unusually long and may not display well.',location:'Course info'));
      if(author.roles.isEmpty)issues.add(const CourseAuditIssue(severity:AuditSeverity.warning,code:'COURSE_AUTHOR_ROLE_EMPTY',message:'Course author has no role. Add at least one role or use Contributor.',location:'Course info'));
      if(author.roles.length>12)issues.add(const CourseAuditIssue(severity:AuditSeverity.warning,code:'COURSE_AUTHOR_ROLES_MANY',message:'Course author has an unusually large number of roles. Check for accidental duplicates.',location:'Course info'));
    }
    if(course.courseDescription.length>5000)issues.add(const CourseAuditIssue(severity:AuditSeverity.warning,code:'COURSE_DESCRIPTION_LONG',message:'Course description exceeds 5,000 characters and may be difficult to edit or display.',location:'Course info'));
    if(course.lastUpdated.trim().isNotEmpty){
      final raw=course.lastUpdated.trim();
      final validShape=RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(raw);
      final parsed=DateTime.tryParse(raw);
      if(!validShape||parsed==null||parsed.year.toString().padLeft(4,'0')!=raw.substring(0,4)||parsed.month.toString().padLeft(2,'0')!=raw.substring(5,7)||parsed.day.toString().padLeft(2,'0')!=raw.substring(8,10)){
        issues.add(const CourseAuditIssue(severity:AuditSeverity.warning,code:'COURSE_DATE_INVALID',message:'Last updated should be a valid date in YYYY-MM-DD format.',location:'Course info'));
      }
    }
    if(course.topics.isEmpty){issues.add(const CourseAuditIssue(severity:AuditSeverity.warning,message:'Course has no Topics yet. This is valid while a course is being authored.',location:'Course'));}
    final audioKeys=<String>{};
    for(final clip in course.audioLibrary){
      final key=clip.text.trim().toLowerCase();
      if(key.isEmpty){issues.add(const CourseAuditIssue(severity:AuditSeverity.warning,message:'Orphan MP3 is not associated with any word or expression.',location:'Audio Library'));continue;}
      if(!audioKeys.add(key))issues.add(CourseAuditIssue(severity:AuditSeverity.error,message:'Duplicate recorded-audio mapping for “${clip.text}”.',location:'Audio Library'));
    }
    if(course.audioMode=='recorded'&&course.audioLibrary.isEmpty)issues.add(const CourseAuditIssue(severity:AuditSeverity.error,message:'Recorded MP3 mode is enabled but the Audio Library is empty.',location:'Audio Library'));

    for(var ti=0;ti<course.topics.length;ti++){
      final t=course.topics[ti];final tl='Topic ${ti+1} · ${t.title}';idCheck(t.id,tl);idCheck(t.duel.id,'$tl · Duel');
      final gb=t.guidebook;
      for(var gi=0;gi<gb.content.length;gi++){final content=gb.content[gi];final location='$tl · Guidebook Content ${gi+1}';idCheck(content.id,location);for(final ref in content.sourceRefs){pendingSourceRefs.add(MapEntry(ref,location));}}
      if(gb.content.isEmpty)issues.add(CourseAuditIssue(severity:AuditSeverity.warning,code:'TOPIC_GUIDEBOOK_EMPTY',message:'Topic Guidebook is empty. Add learner-facing vocabulary, examples or explanations before generating Rounds.',location:'$tl · Guidebook'));
      if(t.rounds.isEmpty)issues.add(CourseAuditIssue(severity:AuditSeverity.warning,message:'Topic has no rounds yet.',location:tl));
      if(t.rounds.length<6)issues.add(CourseAuditIssue(severity:AuditSeverity.suggestion,code:'TOPIC_ROUND_GUIDANCE',message:'Topics should normally contain at least 6 Rounds. This is author guidance and does not determine Duel availability.',location:tl));
      if(t.rounds.isNotEmpty){
        final intro=t.rounds.first.content.where((content)=>content.role=='topic_intro').toList();
        if(intro.isEmpty)issues.add(CourseAuditIssue(severity:AuditSeverity.suggestion,code:'TOPIC_INTRO_MISSING',message:'The first Round has no short Topic introduction drawn from the Topic Guidebook.',location:'$tl · Round 1'));
      }
      for(var ri=0;ri<t.rounds.length;ri++){
        final r=t.rounds[ri];final rl='$tl · Round ${ri+1} · ${r.title}';idCheck(r.id,rl,roundId:r.id);
        if(r.content.isEmpty)issues.add(CourseAuditIssue(severity:AuditSeverity.error,message:'Round has no Content.',location:rl,roundId:r.id));
        if(r.content.length>10)issues.add(CourseAuditIssue(severity:AuditSeverity.warning,message:'Round has ${r.content.length} Content items; standard sample length is 10.',location:rl,roundId:r.id));
        if(r.content.length<8&&r.content.isNotEmpty)issues.add(CourseAuditIssue(severity:AuditSeverity.suggestion,message:'Round has ${r.content.length} Content items; standard sample length is 10.',location:rl,roundId:r.id));
        for(var contentIndex=0;contentIndex<r.content.length;contentIndex++){final content=r.content[contentIndex];final location='$rl · Content ${contentIndex+1}';idCheck(content.id,location,roundId:r.id,exerciseId:content.kind=='exercise'?content.id:null);for(final ref in content.sourceRefs){pendingSourceRefs.add(MapEntry(ref,location));}}

        final readingCount=r.exercises.where((e)=>e.type=='reading_comprehension').length;
        final listeningCount=r.exercises.where((e)=>e.type=='listening_comprehension').length;
        if(readingCount==0)issues.add(CourseAuditIssue(severity:AuditSeverity.warning,message:'Round has no Reading comprehension exercise.',location:rl,roundId:r.id));
        if(listeningCount==0)issues.add(CourseAuditIssue(severity:AuditSeverity.warning,message:'Round has no Listening comprehension exercise.',location:rl,roundId:r.id));

        final duplicatePrompts=<String>{};
        for(var ei=0;ei<r.exercises.length;ei++){
          final ex=r.exercises[ei];final el='$rl · Exercise ${ei+1}';
          final instructionLanguage=_legacyInstructionLanguage(ex.prompt);
          if(instructionLanguage!=null&&instructionLanguage!=_courseSourceCode(course)){
            issues.add(CourseAuditIssue(severity:AuditSeverity.warning,message:'Exercise instruction appears to be in the wrong language. Learner instructions must use the course source language.',location:el,roundId:r.id,exerciseId:ex.id));
          }
          issues.addAll(auditExercise(ex,location:el,roundId:r.id));
          final prompt=ex.prompt.trim();
          final isOpposite=(ex.type=='super_match'&&prompt.toLowerCase().contains('opposit'))||prompt.toLowerCase().contains('contrar')||prompt.toLowerCase().contains('gegenteil')||prompt.toLowerCase().contains('opuesto');
          if(ri<2&&isOpposite)issues.add(CourseAuditIssue(severity:AuditSeverity.warning,code:'OPPOSITE_TOO_EARLY',message:'Opposite exercises should not be used in the first rounds of a Topic.',location:el,roundId:r.id,exerciseId:ex.id));
          final isolated=[prompt,ex.question.trim(),...ex.answers].where((v)=>v.isNotEmpty&&!v.contains(RegExp(r'\s')));
          if(_courseSourceCode(course)!='DE'&&isolated.any((v)=>RegExp(r'^[A-ZÀ-ÖØ-Þ]').hasMatch(v)))issues.add(CourseAuditIssue(severity:AuditSeverity.suggestion,code:'SINGLE_WORD_CASE',message:'An isolated word starts with a capital letter. Use lowercase unless capitalization is linguistically required.',location:el,roundId:r.id,exerciseId:ex.id));
          final key='${ex.type}|${ex.prompt.trim().toLowerCase()}|${ex.question.trim().toLowerCase()}';
          if(!duplicatePrompts.add(key))issues.add(CourseAuditIssue(severity:AuditSeverity.warning,code:'ROUND_DUPLICATE_CONTENT',message:'Same exercise prompt/question appears more than once in this round.',location:el,roundId:r.id,exerciseId:ex.id));
        }
      }
      final eligibility=const DuelEligibilityService().evaluate(t);
      if(!eligibility.isAvailable)issues.add(CourseAuditIssue(severity:AuditSeverity.suggestion,code:'DUEL_UNAVAILABLE',message:'Duel is unavailable with ${eligibility.eligibleCount} suitable exercises; ${eligibility.requiredCount} are required. This is normal supported behavior.',location:'$tl · Duel'));
    }
    for(final pending in pendingSourceRefs){if(!ids.contains(pending.key))issues.add(CourseAuditIssue(severity:AuditSeverity.error,code:'SOURCE_REF_MISSING',message:'sourceRefs references missing Content ID: ${pending.key}',location:pending.value));}
    return CourseAuditResult(issues);
  }

  String? _languageHint(String raw) {
    final token = raw.toLowerCase().replaceAll(RegExp(r"[^a-zà-öø-ÿąćęłńóśźżäöüß']"), '');
    if (token.isEmpty) return null;
    const sets = <String, Set<String>>{
      'en': {'the','a','an','i','you','he','she','we','they','my','your','good','morning','hello','thank','please','house','water','book','friend','woman','man','work','study','eat','drink','right','left','where','what','name','am','is','are','to','from','with','yes','no','come'},
      'it': {'il','lo','la','i','gli','le','un','una','io','tu','grazie','buongiorno','piacere','amico','uomo','donna','acqua','libro','casa','vado','lavoro','studio','mangio','bevo','destra','sinistra','dove','come','sono'},
      'de': {'der','die','das','ein','eine','ich','du','danke','guten','morgen','freut','mich','freund','mann','frau','wasser','buch','haus','fahre','arbeite','lerne','esse','trinke','rechts','links','wo','wie','bin','am'},
      'es': {'el','la','los','las','un','una','yo','tú','hola','gracias','buenos','buenas','días','tardes','mujer','hombre','amigo','libro','casa','agua','café','trabajar','estudiar','comer','beber','dónde','qué','soy','me','llamo','por','favor','de'},
      'pt': {'o','a','os','as','um','uma','eu','você','olá','obrigado','obrigada','bom','dia','casa','água','livro','amigo','mulher','homem'},
      'nl': {'de','het','een','ik','jij','hallo','dank','goed','morgen','huis','water','boek','vriend','vrouw','man'},
      'fi': {'minä','sinä','hei','kiitos','hyvää','huomenta','talo','vesi','kirja','ystävä','nainen','mies'},
      'cy': {'y','yr','un','fi','ti','helo','diolch','bore','da','tŷ','dŵr','llyfr','ffrind'},
    };
    String? hit;
    for (final entry in sets.entries) {
      if (!entry.value.contains(token)) continue;
      if (hit != null && hit != entry.key) return null;
      hit = entry.key;
    }
    return hit;
  }

  /// High-confidence Word Block language check. It deliberately reports only
  /// cases where both the answer and the distractor contain unambiguous common
  /// words from different supported languages; ambiguous vocabulary is left to
  /// human review rather than guessed.
  void _auditWordBlockLanguage(Exercise ex, void Function(AuditSeverity,String) add) {
    if (ex.type != 'word_order') return;
    final counts = <String,int>{};
    for (final t in ex.tokens) { counts[t] = (counts[t] ?? 0) + 1; }
    for (final t in ex.orderAnswer) { counts[t] = (counts[t] ?? 0) - 1; }
    final extras = counts.entries.where((e) => e.value > 0).toList();
    if (extras.isEmpty) return;
    final answerLanguages = ex.orderAnswer.map(_languageHint).whereType<String>().toSet();
    if (answerLanguages.length != 1) return;
    for (final extra in extras) {
      final distractorLanguage = _languageHint(extra.key);
      if (distractorLanguage != null && !answerLanguages.contains(distractorLanguage)) {
        add(AuditSeverity.error, 'Word-block distractor appears to be in a different language from the answer blocks.');
        return;
      }
    }
  }

  List<CourseAuditIssue> auditExercise(Exercise ex,{String location='Exercise',String? roundId}){
    final out=<CourseAuditIssue>[];
    void add(AuditSeverity s,String m,{String code='GENERAL'})=>out.add(CourseAuditIssue(severity:s,code:code,message:m,location:location,roundId:roundId,exerciseId:ex.id));
    if(!supportedTypes.contains(ex.type))add(AuditSeverity.error,'Unknown exercise type: ${ex.type}');
    if(ex.prompt.length>1200||ex.question.length>800)add(AuditSeverity.warning,'Very long text may be difficult to read on small screens.');

    // Fields not belonging to an exercise type are flagged so the editor does
    // not accumulate hidden stale data. IDs/type are common and omitted here.
    void unexpected(bool condition,String field){if(condition)add(AuditSeverity.warning,'Unexpected field for ${ex.type}: $field.');}
    final usesAnswers=choiceTypes.contains(ex.type)||ex.type=='flashcard'||ex.type=='audio_match';
    unexpected(!usesAnswers&&ex.answers.isNotEmpty,'answers');
    unexpected(!choiceTypes.contains(ex.type)&&ex.correct!=null,'correct answer');
    unexpected(!const{'fill_blank','listening_spelling'}.contains(ex.type)&&ex.accepted.isNotEmpty,'accepted answers');
    unexpected(!const{'word_order','image_word'}.contains(ex.type)&&ex.tokens.isNotEmpty,'word blocks');
    unexpected(!const{'word_order','image_word'}.contains(ex.type)&&ex.orderAnswer.isNotEmpty,'correct sentence/order');
    unexpected(!const{'matching','audio_match','word_match','super_match'}.contains(ex.type)&&ex.pairs.isNotEmpty,'pairs');
    unexpected(ex.type!='fill_blank'&&ex.hint.isNotEmpty,'hint');
    unexpected(ex.type!='missing_word'&&ex.missingWords.isNotEmpty,'missing words');
    unexpected(ex.type!='icon_choice'&&ex.icons.isNotEmpty,'icons');

    if(choiceTypes.contains(ex.type)){
      if(ex.answers.length<2)add(AuditSeverity.error,'Choice exercise needs at least two answers.');
      if(ex.type=='dialogue_response'&&ex.answers.length!=2)add(AuditSeverity.error,'Dialogue Response requires exactly two response options.');
      if(ex.type=='dialogue_response'&&ex.prompt.trim().isEmpty)add(AuditSeverity.error,'Dialogue Response needs a context sentence.');
      if(ex.type=='dialogue_response'&&ex.question.trim().isEmpty)add(AuditSeverity.error,'Dialogue Response needs a question.');
      if(ex.correct==null||ex.correct!<0||ex.correct!>=ex.answers.length)add(AuditSeverity.error,'Correct answer is missing or outside the answer list.');
      if(ex.answers.any((e)=>e.trim().isEmpty))add(AuditSeverity.error,'Answer options cannot be blank.');
      if(ex.answers.map((e)=>e.trim().toLowerCase()).toSet().length!=ex.answers.length)add(AuditSeverity.warning,'Answer options contain duplicates.');
      const placeholderAnswers={'xyz','abc','placeholder','test answer','dummy'};
      if(ex.answers.any((e)=>placeholderAnswers.contains(e.trim().toLowerCase())))add(AuditSeverity.error,'Answer options contain placeholder text. Replace it with a real course-language distractor.',code:'PLACEHOLDER_ANSWER');
      final normalizedPrompt=ex.prompt.trim().toLowerCase();
      if(normalizedPrompt=='choose the correct translation.'||normalizedPrompt=='elige la traducción correcta.')add(AuditSeverity.error,'Translation prompt does not identify the word or expression to translate.',code:'TRANSLATION_PROMPT_MISSING_SOURCE');
      if(ex.evaluation.correctItemIds.isNotEmpty&&ex.correct==null)add(AuditSeverity.error,'Correct Item ID does not resolve to a visible answer option.',code:'CORRECT_ITEM_UNRESOLVED');
      if(ex.type=='reading_comprehension'&&ex.question.toLowerCase().contains('which option best fits the topic vocabulary')&&ex.correct!=null&&ex.correct!>=0&&ex.correct!<ex.answers.length){
        final correctText=ex.answers[ex.correct!].trim().toLowerCase();
        final passage=ex.prompt.trim().toLowerCase();
        if(correctText.isNotEmpty&&!passage.contains(correctText))add(AuditSeverity.warning,'The declared correct option does not occur in the reading passage. Review this generated Reading exercise for a likely vocabulary mismatch.',code:'READING_OPTION_NOT_IN_PASSAGE');
      }
    }
    if((ex.type.startsWith('listening')||ex.type=='missing_word')&&(ex.tts==null||ex.tts!.trim().isEmpty))add(AuditSeverity.error,'Listening exercise has no audio text.');
    if(ex.type=='gap_choice'){
      if(ex.question.trim().isEmpty)add(AuditSeverity.error,'Gap Choice needs a target-language sentence.');
      if(!ex.question.contains('___'))add(AuditSeverity.error,'Gap Choice sentence must contain the ___ gap marker.');
      if(ex.question.split('___').length!=2)add(AuditSeverity.warning,'Gap Choice should normally contain exactly one gap.');
    }
    if(ex.type=='listening_spelling'&&ex.accepted.isEmpty)add(AuditSeverity.error,'Listening Spelling needs at least one accepted text answer.',code:'LISTENING_SPELLING_NO_ANSWER');
    if(ex.type=='missing_word'){
      if(ex.prompt.trim().isEmpty)add(AuditSeverity.error,'Missing Word exercise needs a passage transcript.');
      if(ex.missingWords.isEmpty)add(AuditSeverity.error,'Missing Word exercise needs at least one missing word.');
      final passage=ex.prompt.toLowerCase();
      for(final word in ex.missingWords){if(!passage.contains(word.toLowerCase()))add(AuditSeverity.error,'Missing word “$word” does not occur in the passage transcript.');}
      if(ex.missingWords.map((e)=>e.trim().toLowerCase()).toSet().length!=ex.missingWords.length)add(AuditSeverity.warning,'Missing Word exercise contains duplicate missing-word entries.');
    }
    if(ex.type=='reading_comprehension'&&ex.prompt.trim().split(RegExp(r'\s+')).length<5)add(AuditSeverity.suggestion,'Reading comprehension passage is very short; make sure it tests comprehension rather than visual matching.');
    if(ex.type=='listening_comprehension'&&(ex.tts??'').trim().split(RegExp(r'\s+')).length<5)add(AuditSeverity.suggestion,'Listening comprehension passage is very short; make sure it tests comprehension.');

    if(ex.type=='fill_blank'){
      if(ex.accepted.isEmpty)add(AuditSeverity.error,'Fill-in exercise needs at least one accepted answer.');
      final hint=ex.hint.toLowerCase();
      if(ex.accepted.any((a){final v=a.trim().toLowerCase();return v.length>=3&&hint.contains(v);}))add(AuditSeverity.error,'Hint contains an accepted answer. A hint must not reveal the solution.',code:'HINT_REVEALS_ANSWER');
    }
    if(const{'word_order','image_word'}.contains(ex.type)){
      if(ex.tokens.isEmpty||ex.orderAnswer.isEmpty)add(AuditSeverity.error,'Word-block exercise needs available blocks and a correct sentence.');
      final pool=<String,int>{};for(final t in ex.tokens){pool[t]=(pool[t]??0)+1;}
      var impossible=false;
      for(final t in ex.orderAnswer){pool[t]=(pool[t]??0)-1;if((pool[t]??0)<0){impossible=true;break;}}
      if(impossible)add(AuditSeverity.error,'Correct sentence uses a block not available in the token pool.');
      final extraCount=ex.tokens.length-ex.orderAnswer.length;
      final maxDistractors=ex.type=='image_word'?0:2;
      if(extraCount<0||extraCount>maxDistractors){
        add(AuditSeverity.error,ex.type=='image_word'
          ?'Letter/syllable word-building exercises must contain only the blocks needed for the answer; found $extraCount extra blocks.'
          :'Word-order exercise may contain 0, 1 or 2 extra distractor blocks; found $extraCount.');
      }
      if(extraCount>=0&&extraCount<=maxDistractors){
        final counts=<String,int>{};for(final t in ex.tokens){counts[t]=(counts[t]??0)+1;}for(final t in ex.orderAnswer){counts[t]=(counts[t]??0)-1;}
        final extraEntries=counts.entries.where((e)=>e.value>0).toList();
        final extras=extraEntries.fold<int>(0,(sum,e)=>sum+e.value);
        if(extras!=extraCount)add(AuditSeverity.error,'The token multiset does not contain the expected usable distractor blocks. Repeated words must keep their required occurrence counts.');
        if(extras>0){
          final answerKeys=ex.orderAnswer.map((e)=>e.trim().toLowerCase()).toSet();
          if(extraEntries.any((e)=>answerKeys.contains(e.key.trim().toLowerCase())))add(AuditSeverity.error,'Distractor must be a different visible word/block, not an extra copy of a required block.');
        }
      }
      _auditWordBlockLanguage(ex, add);
    }
    if(ex.type=='flashcard'){
      if(ex.prompt.trim().isEmpty)add(AuditSeverity.error,'Flashcard needs a target word or phrase.');
      if(ex.question.trim().isEmpty)add(AuditSeverity.warning,'Flashcard meaning is empty.');
      if(ex.answers.isEmpty||ex.answers.first.trim().isEmpty)add(AuditSeverity.warning,'Flashcard has no usage sentence.');
      if(ex.tts==null||ex.tts!.trim().isEmpty)add(AuditSeverity.warning,'Flashcard has no pronunciation TTS text.');
    }
    if(ex.type=='matching'&&ex.pairs.isEmpty)add(AuditSeverity.error,'Matching exercise needs at least one pair.');
    if(ex.type=='audio_match'){
      if(ex.pairs.length!=3)add(AuditSeverity.error,'Audio Match requires exactly 3 sound/text pairs.');
      if(ex.answers.length!=ex.pairs.length)add(AuditSeverity.error,'Audio Match must have one visible answer for each sound and no distractors.');
      final visibleKeys=ex.answers.map((e)=>e.trim().toLowerCase()).toList();
      final visible=visibleKeys.toSet();
      if(visible.length!=visibleKeys.length)add(AuditSeverity.error,'Audio Match visible choices contain duplicates.');
      if(ex.pairs.any((p)=>p.length!=2||p[0].trim().isEmpty||p[1].trim().isEmpty))add(AuditSeverity.error,'Audio Match contains an empty sound or match.');
      if(ex.pairs.any((p)=>!visible.contains(p[1].trim().toLowerCase())))add(AuditSeverity.error,'Every Audio Match value must appear among the visible choices.');
      String normalizedAudioMatchText(String value)=>value.toLowerCase().replaceAll(RegExp(r'[^\p{L}\p{N}\s]',unicode:true),'').replaceAll(RegExp(r'\s+'),' ').trim();
      final soundKeys=ex.pairs.map((p)=>normalizedAudioMatchText(p[0])).toList();
      final matchKeys=ex.pairs.map((p)=>normalizedAudioMatchText(p[1])).toList();
      if(soundKeys.toSet().length!=soundKeys.length)add(AuditSeverity.error,'Audio Match repeats the same target audio.');
      if(matchKeys.toSet().length!=matchKeys.length)add(AuditSeverity.error,'Audio Match repeats the same matching text.');
    }
    if(ex.type=='word_match'||ex.type=='super_match'){
      if(ex.pairs.length!=3)add(AuditSeverity.error,'${ex.type=='word_match'?'Word Match':'Super Match'} requires exactly 3 pairs.');
      if(ex.pairs.any((p)=>p.length!=2||p[0].trim().isEmpty||p[1].trim().isEmpty))add(AuditSeverity.error,'Match exercise contains an empty pair.');
      String normalizedMatchText(String value)=>value.toLowerCase().replaceAll(RegExp(r'[^\p{L}\p{N}\s]',unicode:true),'').replaceAll(RegExp(r'\s+'),' ').trim();
      final left=ex.pairs.where((p)=>p.length==2).map((p)=>normalizedMatchText(p[0])).toList();
      final right=ex.pairs.where((p)=>p.length==2).map((p)=>normalizedMatchText(p[1])).toList();
      if(left.toSet().length!=left.length)add(AuditSeverity.error,'Match exercise repeats the same left-side item after ignoring case and punctuation.');
      if(right.toSet().length!=right.length)add(AuditSeverity.error,'Match exercise repeats the same right-side item after ignoring case and punctuation.');
    }
    if(ex.type=='image_word'){
      if(ex.imageAsset.trim().isEmpty)add(AuditSeverity.error,'Image Word exercise requires an image.');
      if(ex.orderAnswer.isEmpty)add(AuditSeverity.error,'Image Word exercise requires a correct target-language word.');
      if(ex.orderAnswer.join().trim().isEmpty)add(AuditSeverity.error,'Image Word correct word cannot be blank.');
    }
    if(ex.type=='icon_choice'&&ex.icons.length!=ex.answers.length)add(AuditSeverity.error,'Icon count must match answer count.');
    return out;
  }


}
