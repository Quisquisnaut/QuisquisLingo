import '../services/storage/qql_storage_layout.dart';
import 'localized_text.dart';

/// The text of the start page, the learner's page while no Course can be
/// studied (Build 272 Revision 17, owner decisions of 13 October 2026), in
/// English, Italian and Spanish: the learner's Help Language. QQL command
/// and screen names stay in English, as in translated Help. The page never
/// names a Course.
const startPageText = LocalizedText(
  english: _english,
  italian: _italian,
  spanish: _spanish,
  defaultValues: QqlStorageLayout.helpValues,
);

const _english = <String, String>{
  'title': 'Start here',
  'intro':
      'QuisquisLingo comes with no Course inside: you bring the Courses. '
      'Import one that someone made, or make your own.',
  'waiting.one':
      'You have 1 Course, but it cannot be studied yet: a Course must be '
      'Published before it can be studied, and a Publisher Course also '
      'needs its publisher verified. To publish a Course of your own, open '
      'it from Course Studio and choose Publish.',
  'waiting.many':
      'You have {count} Courses, but none can be studied yet: a Course must '
      'be Published before it can be studied, and a Publisher Course also '
      'needs its publisher verified. To publish a Course of your own, open '
      'it from Course Studio and choose Publish.',
  'where.title': 'Where do Courses come from?',
  'where.body':
      'A Course is a file: a .zip package, or a .json file when it has no '
      'pictures or recordings of its own. Whoever made it gives it to you: '
      'a friend, a teacher, your Team, a publisher. It can reach you by '
      'e-mail or chat, on a USB stick or through a shared folder. '
      'QuisquisLingo has no shop and downloads no Course by itself: save '
      'the file on this device, then import it.',
  'where.friend': 'A friend',
  'where.teacher': 'A teacher',
  'where.publisher': 'A publisher',
  'import.title': 'Import a Course',
  'import.step1':
      'Save the Course file on this device, for example in Downloads.',
  'import.step2': 'Tap Import a Course below.',
  'import.step3':
      'Tap Open from… and choose the file. Or use Quick Import: it reads a '
      'file named import.zip (import.json for a .json file) from '
      '{folderCourseImports}.',
  'import.step4':
      'QuisquisLingo checks the file, shows what it found and asks before '
      'it adds the Course. Once imported, a Published Course can be studied '
      'at once.',
  'create.title': 'Make your own Course',
  'create.body':
      'Courses are written in Course Studio, with the Course Editor. Both '
      'stay hidden until you turn them on for your profile.',
  'create.step1': 'Open Settings: the gear at the top of this page.',
  'create.step2':
      'Tap Version and Build ten times, until QuisquisLingo says Course '
      'Studio unlocked.',
  'create.step3':
      'Come back here and tap New Course. The Course Wizard asks for the '
      'two languages and a title, then guides you through Lessons, '
      'GuideBooks and Rounds.',
  'create.step4':
      'To change a Course later, open Course Studio and tap the Course: the '
      'Course Editor opens. Switch its access state to Edit to make '
      'changes.',
  'create.step5':
      'A new Course is a Draft and cannot be studied yet. Publish it (the '
      'Course Wizard’s last step, or Publish in the Course Editor): then it '
      'appears here, ready to study.',
  'create.on': 'Course Studio is on for your profile.',
  'create.off':
      'Course Studio is off for your profile: follow steps 1 and 2 first.',
  'device.title': 'Courses already on this device',
  'device.some.one':
      'This device already has 1 Course you can study that is not among '
      'your courses. Open All Courses and choose Add to my courses: no file '
      'is needed.',
  'device.some.many':
      'This device already has {count} Courses you can study that are not '
      'among your courses. Open All Courses and choose Add to my courses: '
      'no file is needed.',
  'device.none':
      'All Courses lists the Courses of this device. When another learner '
      'of this device makes or imports one, you can add it to your courses '
      'there, without a file. Right now there is none to add and study.',
};

const _italian = <String, String>{
  'title': 'Comincia da qui',
  'intro':
      'QuisquisLingo non contiene nessun corso: i corsi li porti tu. '
      'Importane uno fatto da altri, oppure creane uno tuo.',
  'waiting.one':
      'Hai 1 corso, ma non si può ancora studiare: un corso va pubblicato '
      '(Published) prima di poterlo studiare, e un Publisher Course richiede '
      'anche la verifica del suo editore. Per pubblicare un tuo corso, '
      'aprilo da Course Studio e scegli Publish.',
  'waiting.many':
      'Hai {count} corsi, ma nessuno si può ancora studiare: un corso va '
      'pubblicato (Published) prima di poterlo studiare, e un Publisher '
      'Course richiede anche la verifica del suo editore. Per pubblicare un '
      'tuo corso, aprilo da Course Studio e scegli Publish.',
  'where.title': 'Da dove arrivano i corsi?',
  'where.body':
      'Un corso è un file: un pacchetto .zip, oppure un file .json quando '
      'non ha immagini o registrazioni proprie. Te lo dà chi lo ha creato: '
      'un amico, un insegnante, il tuo Team, un editore. Può arrivarti per '
      'e-mail o in chat, su una chiavetta USB o in una cartella condivisa. '
      'QuisquisLingo non ha un negozio e non scarica corsi da solo: salva '
      'il file su questo dispositivo, poi importalo.',
  'where.friend': 'Un amico',
  'where.teacher': 'Un insegnante',
  'where.publisher': 'Un editore',
  'import.title': 'Importare un corso',
  'import.step1':
      'Salva il file del corso su questo dispositivo, per esempio in '
      'Download.',
  'import.step2': 'Tocca Import a Course qui sotto.',
  'import.step3':
      'Tocca Open from… e scegli il file. Oppure usa Quick Import: legge un '
      'file chiamato import.zip (import.json per un file .json) nella '
      'cartella {folderCourseImports}.',
  'import.step4':
      'QuisquisLingo controlla il file, mostra che cosa ha trovato e chiede '
      'conferma prima di aggiungere il corso. Dopo l’importazione, un corso '
      'pubblicato (Published) si può studiare subito.',
  'create.title': 'Creare un tuo corso',
  'create.body':
      'I corsi si scrivono in Course Studio, con il Course Editor. Tutti e '
      'due restano nascosti finché non li attivi per il tuo profilo.',
  'create.step1': 'Apri Settings: l’ingranaggio in alto in questa pagina.',
  'create.step2':
      'Tocca Version and Build dieci volte, finché QuisquisLingo non dice '
      'Course Studio unlocked.',
  'create.step3':
      'Torna qui e tocca New Course. Il Course Wizard chiede le due lingue '
      'e un titolo, poi ti guida tra Lesson, GuideBook e Round.',
  'create.step4':
      'Per modificare un corso in seguito, apri Course Studio e tocca il '
      'corso: si apre il Course Editor. Per fare modifiche, porta il suo '
      'stato di accesso su Edit.',
  'create.step5':
      'Un corso nuovo è un Draft e non si può ancora studiare. Pubblicalo '
      '(l’ultimo passo del Course Wizard, oppure Publish nel Course '
      'Editor): allora compare qui, pronto da studiare.',
  'create.on': 'Course Studio è attivo per il tuo profilo.',
  'create.off':
      'Course Studio non è attivo per il tuo profilo: segui prima i passi 1 '
      'e 2.',
  'device.title': 'Corsi già presenti su questo dispositivo',
  'device.some.one':
      'Su questo dispositivo c’è già 1 corso che puoi studiare e che non è '
      'tra i tuoi. Apri All Courses e scegli Add to my courses: non serve '
      'nessun file.',
  'device.some.many':
      'Su questo dispositivo ci sono già {count} corsi che puoi studiare e '
      'che non sono tra i tuoi. Apri All Courses e scegli Add to my '
      'courses: non serve nessun file.',
  'device.none':
      'All Courses elenca i corsi di questo dispositivo. Quando un altro '
      'studente di questo dispositivo ne crea o ne importa uno, lì puoi '
      'aggiungerlo ai tuoi, senza file. Per ora non ce n’è nessuno da '
      'aggiungere e studiare.',
};

const _spanish = <String, String>{
  'title': 'Empieza aquí',
  'intro':
      'QuisquisLingo no trae ningún curso: los cursos los pones tú. '
      'Importa uno hecho por otra persona o crea el tuyo.',
  'waiting.one':
      'Tienes 1 curso, pero todavía no se puede estudiar: un curso debe '
      'estar publicado (Published) antes de poder estudiarlo, y un '
      'Publisher Course necesita además la verificación de su editorial. '
      'Para publicar un curso tuyo, ábrelo desde Course Studio y elige '
      'Publish.',
  'waiting.many':
      'Tienes {count} cursos, pero ninguno se puede estudiar todavía: un '
      'curso debe estar publicado (Published) antes de poder estudiarlo, y '
      'un Publisher Course necesita además la verificación de su '
      'editorial. Para publicar un curso tuyo, ábrelo desde Course Studio y '
      'elige Publish.',
  'where.title': '¿De dónde vienen los cursos?',
  'where.body':
      'Un curso es un archivo: un paquete .zip, o un archivo .json cuando '
      'no tiene imágenes ni grabaciones propias. Te lo da quien lo creó: un '
      'amigo, un profesor, tu Team, una editorial. Puede llegarte por correo '
      'electrónico o por chat, en una memoria USB o en una carpeta '
      'compartida. QuisquisLingo no tiene tienda y no descarga cursos por '
      'su cuenta: guarda el archivo en este dispositivo y luego impórtalo.',
  'where.friend': 'Un amigo',
  'where.teacher': 'Un profesor',
  'where.publisher': 'Una editorial',
  'import.title': 'Importar un curso',
  'import.step1':
      'Guarda el archivo del curso en este dispositivo, por ejemplo en '
      'Descargas.',
  'import.step2': 'Toca Import a Course aquí abajo.',
  'import.step3':
      'Toca Open from… y elige el archivo. O usa Quick Import: lee un '
      'archivo llamado import.zip (import.json si es un archivo .json) en '
      'la carpeta {folderCourseImports}.',
  'import.step4':
      'QuisquisLingo comprueba el archivo, muestra lo que ha encontrado y '
      'pide confirmación antes de añadir el curso. Una vez importado, un '
      'curso publicado (Published) se puede estudiar enseguida.',
  'create.title': 'Crear tu propio curso',
  'create.body':
      'Los cursos se escriben en Course Studio, con el Course Editor. Los '
      'dos permanecen ocultos hasta que los activas para tu perfil.',
  'create.step1':
      'Abre Settings: el engranaje de la parte superior de esta página.',
  'create.step2':
      'Toca Version and Build diez veces, hasta que QuisquisLingo diga '
      'Course Studio unlocked.',
  'create.step3':
      'Vuelve aquí y toca New Course. El Course Wizard pide las dos lenguas '
      'y un título, y luego te guía por las Lessons, los GuideBooks y los '
      'Rounds.',
  'create.step4':
      'Para cambiar un curso más adelante, abre Course Studio y toca el '
      'curso: se abre el Course Editor. Para hacer cambios, pon su estado '
      'de acceso en Edit.',
  'create.step5':
      'Un curso nuevo es un Draft y todavía no se puede estudiar. '
      'Publícalo (el último paso del Course Wizard, o Publish en el Course '
      'Editor): entonces aparece aquí, listo para estudiar.',
  'create.on': 'Course Studio está activo para tu perfil.',
  'create.off':
      'Course Studio no está activo para tu perfil: sigue primero los pasos '
      '1 y 2.',
  'device.title': 'Cursos que ya están en este dispositivo',
  'device.some.one':
      'En este dispositivo ya hay 1 curso que puedes estudiar y que no está '
      'entre los tuyos. Abre All Courses y elige Add to my courses: no hace '
      'falta ningún archivo.',
  'device.some.many':
      'En este dispositivo ya hay {count} cursos que puedes estudiar y que '
      'no están entre los tuyos. Abre All Courses y elige Add to my '
      'courses: no hace falta ningún archivo.',
  'device.none':
      'All Courses muestra los cursos de este dispositivo. Cuando otro '
      'estudiante de este dispositivo cree o importe uno, allí podrás '
      'añadirlo a los tuyos, sin archivo. Por ahora no hay ninguno que '
      'puedas añadir y estudiar.',
};
