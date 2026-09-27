import 'localized_text.dart';

/// The Welcome Wizard's text in English, Italian and Spanish (Build 255
/// Revision 7). The learner chooses the language in Create Profile; QQL
/// command and screen names stay in English, as in translated Help.
const welcomeText = LocalizedText(
  english: _english,
  italian: _italian,
  spanish: _spanish,
);

const _english = <String, String>{
  'step': 'Step {current} of {total}',
  'back': 'Back',
  'skip': 'Skip',
  'next': 'Next',
  'start': 'Start learning',
  'step1.title': 'Welcome aboard!',
  'step1.body':
      'QuisquisLingo is a language school that fits in your pocket: no '
      'account, no ads, no cloud. Everything you learn stays on this device.',
  'step2.title': 'Courses made by others',
  'step2.body':
      'Friends, teachers and publishers can make Courses too, and share them '
      'as a file. Tap the flag at the top, choose Import Course, and start '
      'learning from what they made.',
  'step3.title': 'Lessons, Rounds, Laurels',
  'step3.body':
      'A Lesson is a path of short Rounds. Finish a Round without mistakes to '
      "earn a Laurel. Feeling brave? Win the Lesson's Duel to jump ahead.",
  'step4.title': 'Little and often',
  'step4.body':
      'Five minutes a day keeps your streak alive and your Weekly XP growing. '
      'Review brings back the Rounds that gave you the most trouble.',
  'step5.title': 'Make your own Course',
  'step5.body':
      'Anyone can write a Course with Course Studio, the editor QuisquisLingo '
      'keeps hidden. Psst: to wake it up, tap Version and Build in Settings '
      'ten times.',
};

const _italian = <String, String>{
  'step': 'Passo {current} di {total}',
  'back': 'Indietro',
  'skip': 'Salta',
  'next': 'Avanti',
  'start': 'Inizia a imparare',
  'step1.title': 'Ti diamo il benvenuto!',
  'step1.body':
      'QuisquisLingo è una scuola di lingue che sta in tasca: niente account, '
      'niente pubblicità, niente cloud. Tutto quello che impari resta su '
      'questo dispositivo.',
  'step2.title': 'Corsi fatti da altri',
  'step2.body':
      'Anche amici, insegnanti ed editori possono creare corsi e condividerli '
      'come file. Tocca la bandiera in alto, scegli Import Course e comincia '
      'a imparare da quello che hanno preparato.',
  'step3.title': 'Lesson, Round, Laurel',
  'step3.body':
      'Una Lesson è un percorso di Round brevi. Completa un Round senza errori '
      'e guadagni un Laurel. Ti va una sfida? Vinci il Duel della Lesson per '
      'saltare avanti.',
  'step4.title': 'Poco ma spesso',
  'step4.body':
      'Cinque minuti al giorno tengono viva la tua streak e fanno crescere i '
      'Weekly XP. Review ti ripropone i Round che ti hanno dato più filo da '
      'torcere.',
  'step5.title': 'Crea il tuo corso',
  'step5.body':
      "Chiunque può scrivere un corso con Course Studio, l'editor che "
      'QuisquisLingo tiene nascosto. Psst: per svegliarlo, tocca dieci volte '
      'Version and Build in Settings.',
};

const _spanish = <String, String>{
  'step': 'Paso {current} de {total}',
  'back': 'Atrás',
  'skip': 'Omitir',
  'next': 'Siguiente',
  'start': 'Empezar a aprender',
  'step1.title': '¡Te damos la bienvenida!',
  'step1.body':
      'QuisquisLingo es una escuela de idiomas que cabe en el bolsillo: sin '
      'cuenta, sin anuncios, sin nube. Todo lo que aprendes se queda en este '
      'dispositivo.',
  'step2.title': 'Cursos hechos por otras personas',
  'step2.body':
      'Amigos, profesores y editoriales también pueden crear cursos y '
      'compartirlos como archivo. Toca la bandera de arriba, elige Import '
      'Course y empieza a aprender con lo que han preparado.',
  'step3.title': 'Lessons, Rounds, Laurels',
  'step3.body':
      'Una Lesson es un camino de Rounds cortos. Termina un Round sin errores '
      'y ganarás un Laurel. ¿Te apetece un reto? Gana el Duel de la Lesson '
      'para avanzar de un salto.',
  'step4.title': 'Poco y a menudo',
  'step4.body':
      'Cinco minutos al día mantienen viva tu streak y hacen crecer tus Weekly '
      'XP. Review te devuelve los Rounds que más te costaron.',
  'step5.title': 'Crea tu propio curso',
  'step5.body':
      'Cualquiera puede escribir un curso con Course Studio, el editor que '
      'QuisquisLingo mantiene oculto. Psst: para despertarlo, toca diez veces '
      'Version and Build en Settings.',
};
