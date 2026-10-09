/// Spanish text for the standalone Help pages, App Info and Course Info.
/// QQL command, setting, mode and data labels remain in English so readers can
/// find the same labels in the current interface.
const Map<String, String> helpEs = {
  'editorHelp.coursesInLearnerMode.title': 'Cursos en el modo de estudio',
  'editorHelp.coursesInLearnerMode.body':
      'Course Library, al final de Course Selector, reúne todos los cursos del dispositivo. Por defecto oculta los cursos no disponibles o Draft. Sort by y Expanded / Compact / Minimal solo cambian la vista. Add to my courses añade un curso compartido a tu lista sin darte permiso para editarlo; Remove from my courses lo quita solo para tu perfil y conserva el progreso, salvo que elijas Reset my progress. Incluso entonces se conservan los XP, días de estudio y streak. Un Admin solo puede usar Remove Publisher Course from device si ningún otro perfil incluye ese curso. Import Course vuelve al estudio. Continue to Editor prepara un curso nuevo, que solo se guarda con Confirm course changes. Change course muestra los cursos Published de tu biblioteca personal. La página de estudio retoma la última Lesson Published activa; el selector de Section abre sus bloques consecutivos.',
  'editorHelp.courseOrigin.title': 'Origen del curso',
  'editorHelp.courseOrigin.body':
      'Los cursos oficiales incluidos son copias de origen verificadas e inmutables. Un Publisher Course importado necesita una firma Ed25519 válida de un editor aprobado. Los cursos externos que no se pueden verificar se conservan como Verification required y no llegan al estudiante. Los Custom Course se crean o importan sin origen oficial. Los cursos oficiales se abren en Official course - read only: puedes consultar Course Info, Audit, Preview, Version History y su contenido. Fork solo está disponible cuando derivativeWorksPolicy permite derivados; conserva el origen, pero crea IDs e historial propios. Copy as New Course inicia una línea independiente.',
  'editorHelp.localCourseEditsAndBackups.title':
      'Cambios locales y backups del curso',
  'editorHelp.localCourseEditsAndBackups.body':
      'Antes de confirmar un cambio en un Custom Course existente, QQL archiva la versión completa en {folderBackups}/Courses, en una carpeta por curso con su par de idiomas y su ID. En Android 7–10, QQL pide una vez permiso para usar esa carpeta; en Android, Version History muestra solo los backups que hizo esta instalación de QQL. El manifiesto incluye Course Model v12, Maintainer, Assigned Team, origen, versiones, autores, fecha UTC, notas opcionales, checksum y audios referenciados. Los backups no se eliminan automáticamente. Version History muestra la versión actual y los backups verificados del más nuevo al más antiguo, con Open backup folder y Export JSON. Solo el historial custom permite Restore into working copy; también requiere la confirmación final para guardar. El historial oficial conserva solo los orígenes del editor.',
  'editorHelp.androidDeviceBackupTechnical.title':
      'Backup del dispositivo Android (técnico)',
  'editorHelp.androidDeviceBackupTechnical.body':
      'QQL no tiene cuenta ni servidor. En Android, Auto Backup sigue activado para recuperar perfiles, progreso, XP, streaks, Review, cursos locales, Teams, ajustes, el verificador de Access PIN y User Recovery Key tras perder o cambiar de teléfono. Access PIN es una protección de acceso casual, no una barrera de seguridad. Image Banks, imágenes importadas y MP3 quedan fuera del backup en la nube por capacidad: el límite de Android es 25 MB y superarlo puede desactivar el backup completo. Conserva tus archivos originales y el Course JSON exportado. La transferencia directa entre teléfonos sí mueve esos medios. QQL no sube datos por sí mismo. Las reglas están en res/xml/data_extraction_rules.xml para API 31+ y res/xml/backup_rules.xml para API 30−; deben cambiarse juntas. Un reset local no puede borrar un backup que Android ya haya hecho. Los Course Backups están en {folderBackups}, fuera del Auto Backup de la app: se conservan si desinstalas QQL, y un teléfono restaurado no los recupera.',
  'editorHelp.officialCourseUpdates.title':
      'Actualizaciones de cursos oficiales',
  'editorHelp.officialCourseUpdates.body':
      'Una actualización oficial verificada se acepta solo con el mismo courseId y editor y un checksum válido. QQL archiva el origen anterior antes de sustituirlo. Los Fork custom existentes y sus historiales no cambian ni se fusionan. Las sustituciones oficiales antiguas de Build 225 no se usan, convierten ni borran. Una firma que no se pueda verificar bloquea la importación. Un curso ya guardado pero no verificado se conserva y necesita asociarse expresamente con una versión firmada más nueva para reactivarse.',
  'editorHelp.courseInfoEditorAndLicense.title':
      'Course Info Editor y licencia',
  'editorHelp.courseInfoEditorAndLicense.body':
      'Course Info Editor guarda Authors / Contributors, Rights Holder, la License del contenido y un enlace HTTPS opcional Buy a Coffee. Son datos distintos de la licencia MPL-2.0 del programa. Los créditos y derechos son descriptivos y no conceden permisos en QQL. Rights Holder puede ser una persona u organización sin perfil local. Las opciones son All rights reserved, CC0 1.0, CC BY 4.0, CC BY-SA 4.0, CC BY-NC 4.0, CC BY-NC-SA 4.0 y Other / Custom license; la licencia custom registra además la política de derivados para terceros. El contenido y origen oficiales son de solo lectura.',
  'editorHelp.courseResponsibilityPermissionsAndTeams.title':
      'Responsabilidad, permisos y Teams',
  'editorHelp.courseResponsibilityPermissionsAndTeams.body':
      'Original Course Creator, Course Maintainer, Assigned Team, Authors / Contributors, Rights Holder, License y el origen de Fork o Merge son datos separados. Todo Custom Course v12 tiene un creador original inmutable y un Maintainer individual. Solo ese Maintainer puede transferir el cargo o asignar y revocar un Team. Él y los miembros actuales de Assigned Team pueden administrar el contenido; los Team Leader gestionan miembros y roles del Team. Estos permisos solo rigen dentro de QQL: los créditos, derechos y origen no conceden acceso ni definen derechos de autor. Un usuario externo no puede modificar ni usar Copy as New Course; Fork depende de la licencia. Los cursos incluidos se consultan en el mismo Editor en solo lectura.',
  'editorHelp.importCustomCourse.title': 'Importar un curso personalizado',
  'editorHelp.importCustomCourse.body':
      'Copia un Course ZIP compatible en {folderCourseImports}/import.zip o, si no tiene medios, un Course Model v12 JSON en import.json. Deja solo uno. El ZIP suele contener course.json, qql-course-package.json y media/ en la raíz; también acepta una carpeta única con el mismo nombre que el ZIP sin .zip, con un aviso. En Course Studio, abre Course Import y elige Quick Import. QQL comprueba todo el paquete y Course Audit antes de instalar. Los Error bloquean; los Warning se muestran. Las imágenes de Shared Image Library viajan con el curso, sin añadirse a la biblioteca del dispositivo receptor. Un Publisher Course requiere firma aprobada. El archivo original permanece en {folderCourseImports}. JSON debe ser UTF-8 y de hasta 10 MB; el ZIP, de hasta 300 MB comprimido y expandido. No se migran formatos anteriores.',
  'editorHelp.exportCustomCourse.title': 'Exportar un curso personalizado',
  'editorHelp.exportCustomCourse.body':
      'Quick Export en Export Course guarda el JSON completo de Course Model v12 y las imágenes y grabaciones propias referenciadas en un ZIP en {folderCourseExports}. Los medios incluidos con la app siguen viniendo de QQL. Las imágenes de Shared Image Library usadas por el curso viajan como medios del curso con su ID, etiqueta, categoría, tags, origen y atribución disponible; importar el ZIP no las añade a la biblioteca compartida del destino. El JSON conserva creador, Maintainer, Team, autores, derechos, License, origen, estados Draft/Published y versión. Fork conserva la línea de origen; Copy as New Course crea otra. Save as… puede guardar el mismo ZIP mediante el diálogo del sistema.',
  'editorHelp.exportAsPublisherCourse.title': 'Exportar como curso de editor',
  'editorHelp.exportAsPublisherCourse.body':
      'Export as Publisher Course, en el menú de un curso personalizado en Course Studio, escribe el curso como Publisher Course del editor que indiques, cualquier editor: escribe su ID y su nombre exactamente como se aprobaron con su clave de firma. Obtienes las mismas Lessons, Rounds y ejercicios con los mismos ID, el editor como Original Course Creator, sin Maintainer, Team ni Course version, no privado, y la Course version como versión oficial, así que cada exportación tras un cambio confirmado es mayor. Autores, Rights Holders y License se mantienen. Solo puede hacerlo el Maintainer o un miembro del Team asignado, y solo con un curso publicado, con License y sin contenido Draft, errores de Audit ni linaje de Fork o fusión; la página indica qué lo impide. Quick Export escribe el ZIP en {folderCourseExports}; Save as… lo escribe donde elijas. El Publisher Course no está firmado y QQL rechaza un Publisher Course sin una firma válida: descomprímelo, firma course.json con tools/sign_course.dart y la clave del editor, y empaquétalo con su carpeta media (docs/PUBLISHER_SIGNING_GUIDE.md, sección 7). QQL solo lo instala donde la app confía en la clave de ese editor; la página avisa, sin detener la exportación, cuando esta versión de QQL no acepta al editor, ha revocado su clave de firma o lo conoce con otro nombre. Para una actualización, edita tu curso, confírmalo y expórtalo de nuevo con el mismo ID y el mismo nombre del editor, que QQL rellena con los de la última exportación del curso: quien estudia conserva su progreso. Tu curso nunca cambia; como el Publisher Course tiene el mismo Course ID, este dispositivo no puede instalarlo junto a tu curso.',
  'editorHelp.courseCreationRules.title': 'Pautas para crear cursos',
  'editorHelp.courseCreationRules.body':
      'Una Lesson debería tener normalmente al menos seis Rounds, quizá unos 48 Exercises. Es una pauta, no un requisito de validez ni de disponibilidad del Duel. Un Round normal tiene 15 Exercises. Evita repeticiones accidentales. Escribe las palabras aisladas en minúscula salvo que la lengua exija mayúscula. Sitúa los ejercicios de opuestos más tarde. Sentence Word Order funciona mejor con entre cero y dos distractores (una recomendación, no un límite): pocos al principio y más después, siempre plausibles pero claramente incorrectos. Las instrucciones para el estudiante van en la lengua base del curso. Los primeros Rounds presentan y consolidan; los posteriores pueden ser más difíciles.',
  'editorHelp.auditSeverityAndCodes.title': 'Gravedad y códigos de Audit',
  'editorHelp.auditSeverityAndCodes.body':
      'Course Audit clasifica Error, Warning e Info. Error bloquea publicación o importación; Warning pide revisión; Info no bloquea por sí solo. Puedes ordenar por Lesson, tipo de Exercise o Recently modified y abrirlo para un Course, una Lesson o un Round. El borde rojo señala Error o Warning y se propaga por su rama; el verde indica que no los hay. El distintivo azul Draft es independiente: un borde verde no significa Published. Un contenedor Draft mantiene ocultos sus hijos Published hasta guardarlo. Un problema de GuideBook afecta a su Lesson, no a la rama Rounds. Menos de tres Rounds es Info; menos de 25 Exercises aptos para Duel es Info solo con Create Duels en ON. La falta de comprensión lectora o auditiva no genera aviso, pero su contenido existente sí se valida. Course Editor Help > Technical reference > Audit Codes muestra las reglas, con filtros independientes Error, Warning e Info y búsqueda dentro de las categorías elegidas.',
  'editorHelp.courseAudit.title': 'Course Audit',
  'editorHelp.courseAudit.body':
      'Course Audit revisa estructura y autoría: campos inválidos, IDs repetidos, Word Block, audio sin correspondencia y errores de Missing Word. Un texto de Reading vacío es Error; con una o dos palabras léxicas aparece READING_PASSAGE_TOO_SHORT, y con tres o más no. HINT_REPEATS_PROMPT es Warning; revelar una respuesta correcta es Error. Audit no certifica gramática, traducción ni calidad pedagógica.',
  'editorHelp.createNewCourse.title': 'Crear un curso nuevo',
  'editorHelp.createNewCourse.body':
      'New Course abre la primera pantalla del Course Wizard: el título, las lenguas de origen y de destino y la variante opcional de lengua. Continue with Wizard guarda el Course enseguida, como Draft sin Lessons, y te guía por el resto paso a paso; Save for now lo pausa, y un toque en la fila del Course, o Continue Course Wizard, el primero de su menú ⋮, sigue donde se detuvo (Ayuda del Course Editor: ¿Cómo funciona el Course Wizard?). Continue by hand abre el formulario New Course con esos valores ya escritos. Source y Target empiezan vacíos: escribe el nombre completo de la lengua (English) o su código (en), o elígela de la lista; las mayúsculas no importan: una lengua de la lista de QQL se escribe con su nombre inglés, una escrita a mano empieza con mayúscula. El formulario crea un proyecto Course Model v12 independiente y lo abre en Course Editor. Ofrece License / Rights, Authors / Contributors, variante de lengua, niveles, descripción y datos de apoyo como Course Info Editor. El perfil activo es el Original Course Creator inmutable y, por defecto, Course Maintainer; puedes elegir a otra persona local como Maintainer. Assigned Team no se elige al crear. Number of Lessons empieza en 3 (1–100) y Rounds per Lesson en 1 (1–20). Los valores inválidos muestran un error y desactivan Create. La jerarquía inicial se crea de una vez con IDs nuevos y Rounds sin título, cada uno con un Exercise Draft de Pick the translation (to target). Revisa y guarda el contenido antes de publicar. El Course Not published solo existe en la copia de trabajo hasta que Confirm course changes crea la versión 1. Cancelar no guarda nada. Los cursos v11 importados deben declarar origen, Maintainer, estado Draft/Published y fechas UTC; no se convierten formatos anteriores.',
  'courseStudioHelp.findingCourses.title': 'Encontrar cursos',
  'courseStudioHelp.findingCourses.body':
      'Search filtra títulos y lenguas de origen o estudio en Course Studio, incluso en Favorites. Favorites muestra accesos rápidos a cursos de la biblioteca personal del estudiante activo; cada curso sigue en su sección normal. Sort by y Show unavailable se aplican a Favorites y a las demás secciones. Cada sección tiene su propio Expanded / Compact / Minimal, que QQL recuerda para cada estudiante, por separado en cada pestaña. Estos controles solo cambian la vista.',
  'courseStudioHelp.courseOperations.title': 'Operaciones con cursos',
  'courseStudioHelp.courseOperations.body':
      'Copy as New Course crea un Custom Course independiente a partir de uno que puedes administrar. Fork crea un derivado cuando la licencia lo permite; conserva el origen y recibe IDs nuevos. Merge combina Lessons de cursos compatibles en un tercero sin cambiar las fuentes. Delete course elimina un Custom Course del dispositivo tras dos confirmaciones y con los permisos necesarios. Remove Publisher Course from device es solo para Admin y se bloquea si otro perfil incluye el curso; conserva progreso y backups. Remove from my courses solo cambia tu biblioteca. Hide in Learner oculta un curso del Course Selector sin quitarlo de la biblioteca; Unhide in Learner lo vuelve a mostrar. Study convierte el curso en el actual y abre la página del estudiante; Review hace lo mismo y abre la página Review, cuando ya completaste un Round. Las operaciones no disponibles aparecen en gris con el motivo.',
  'editorHelp.qa.gettingStarted.title': 'Primeros pasos',
  'editorHelp.qa.accessModes.q':
      '¿Qué hacen Locked, View only, Inspection mode y Edit?',
  'editorHelp.qa.accessModes.a':
      'El control de acceso de la página del Course Editor decide qué puedes hacer. Locked mantiene cerradas las Lessons. View only, el modo por defecto, abre todos los formularios en solo lectura; Search, Help, los IDs internos, Preview y Audit siguen funcionando. Inspection mode abre los ejercicios en su presentación técnica, también en solo lectura. Edit te permite cambiar el Course, si tienes derecho a editarlo. Settings > Do Not Disturb > Course Editor opening mode elige el modo en que un Course se abre la primera vez que lo abres; después cada Course recuerda el suyo, y Edit se abre como View only donde no puedes editar.',
  'editorHelp.qa.whyNoEdit.q': '¿Por qué no puedo elegir Edit?',
  'editorHelp.qa.whyNoEdit.a':
      'Edit necesita permisos de edición: debes ser el Course Maintainer o miembro del Team asignado al Course. Los Courses oficiales, incluidos en QQL o de un Publisher, son siempre de solo lectura: para cambiar uno, usa Fork en Course Studio cuando su licencia permita obras derivadas. El Editor muestra por qué Edit no está disponible. Los créditos, las licencias y los Rights Holders nunca conceden permisos de edición.',
  'editorHelp.qa.viewOnlyNotice.q':
      '¿Por qué aparece un aviso la primera vez que abro un Course en View only?',
  'editorHelp.qa.viewOnlyNotice.a':
      'Explica que View only no cambia nada. Aparece una vez por usuario y Course; Show one-time notices again, en Settings, lo vuelve a mostrar sin cambiar el modo de acceso.',
  'editorHelp.qa.structure.q': '¿Cómo se organiza un Course?',
  'editorHelp.qa.structure.a':
      'Un Course contiene Lessons. Cada Lesson tiene un GuideBook (una lista de módulos breves), Rounds y un Duel; cada Round contiene ejercicios. En el Course Editor abre Lessons, luego una Lesson, sus Rounds y un Round. La ruta de navegación en la parte superior de cada página muestra dónde estás y te lleva de vuelta.',
  'editorHelp.qa.courseWizard.q': '¿Cómo funciona el Course Wizard?',
  'editorHelp.qa.courseWizard.a':
      'En Course Studio, New Course pide primero el título del Course, sus dos lenguas y, si quieres, la variante de lengua (por ejemplo American English). Después elige Continue with Wizard o Continue by hand. Continue by hand abre el formulario New Course con lo que has escrito y luego el Course Editor, como antes. Source y Target empiezan vacíos, y las mayúsculas no importan en ellos. El Course Wizard guarda el Course enseguida, como Draft sin Lessons, y te guía por sus pasos: Basics, Flag or cover image, About the Course (la descripción y los autores), Course options, Lessons, GuideBook, Rounds y Check and publish. Cada paso dice en una línea qué hace; Tell me more explica el resto. Lo que puede esperar está en Advanced, que dice dónde cambiarlo más tarde: el resto de Course Info, las Lesson Options y las secciones de las Lessons. El icono de cada Lesson se elige junto a su título, porque representa el tema de la Lesson. En Flag or cover image, sin portada solo se ve la bandera; una portada ocupa el lugar de la bandera en las listas de Courses, en Course Info y en el Course Editor, mientras que la barra superior de la página del estudiante siempre muestra la bandera. Solo el título, las lenguas, los títulos de las Lessons y los GuideBooks no pueden esperar: en el paso GuideBook cada Lesson necesita un módulo con al menos tres Words & Expressions, que el Round Wizard necesita, aprobado con This Lesson\'s GuideBook is ready (que guarda el GuideBook como Published; con menos de 3 módulos pregunta antes, y Ready anyway sigue). La página del módulo es la del Course Editor, con Paste list y las sugerencias de imágenes. En el paso GuideBook el chip de cada Lesson dice cuántos módulos tiene, con el contorno de la tarjeta GuideBook del Course Editor: verde sin Error ni Warning del Audit en el GuideBook, rojo si no (un GuideBook vacío es un Warning). Add a module, o un toque en el chip de una Lesson sin módulos, abre el Module Wizard, que escribe un módulo nuevo paso a paso (A Title, B Sentences, C Words & Expressions, D Overview) y después de Finish propone otro; un módulo ya escrito se abre en la página del módulo, que nombra su Lesson bajo el título, también en el Course Editor. Fill with an example rellena el paso con un Course de ejemplo, Italian at the bar (en el paso GuideBook abre el módulo de ejemplo en el Module Wizard); Clear all vacía el paso, preguntando antes. Next guarda un paso que ha cambiado como una versión normal del Course, con una copia de seguridad, así Version History puede volver a cualquier paso. Save for now guarda y cierra el Wizard: la fila del Course en Course Studio dice entonces dónde se detuvo, y un toque en la fila, o Continue Course Wizard, el primero de su menú ⋮, sigue desde allí; Edit, en el mismo menú, abre el Course Editor, cuya página muestra la misma línea con Continue. Continue by hand guarda, termina el Wizard y abre el Course Editor. New Course, en Course Studio o en el selector de Courses de la página del estudiante (en gris mientras Course Studio está bloqueado), muestra primero los Course Wizard todavía en pausa que puedes continuar: sigue uno con Continue, o Start a new Course. En el paso Rounds, Make Rounds abre el Round Wizard (Generate Rounds) en cada Lesson, con una breve nota encima sobre cómo serán los Rounds: primero muestra su plan, y los Rounds que crea son Drafts guardados en el Course; cada Lesson necesita Rounds. El último paso, Check and publish, resume cada Lesson (módulos, Rounds, ejercicios, preguntas del Duel, Drafts, errores y avisos del Audit), con Open the Audit y Preview (no registra nada). Publish guarda como Published, en un solo guardado, cada GuideBook, Round, ejercicio y Lesson sin errores del Audit, y después el Course, como lo permite el Publish del Course Editor; lo que un error indica sigue Draft y aparece en la lista con ese error. Finish, o Finish without publishing, termina el Wizard: un breve mensaje te felicita, dice qué encuentra todavía en rojo el Audit, recuerda pasar el Course Editor al modo Edit para cambiar el Course y dice si los estudiantes ya pueden estudiarlo o recuerda Publish; después se abre el Course Editor. El Wizard mantiene activado Use GuideBook, porque construye los Rounds a partir del GuideBook. El punto donde se detuvo se guarda solo en este dispositivo, nunca en el archivo del Course.',
  'editorHelp.qa.search.q': '¿Cómo encuentro un ejercicio?',
  'editorHelp.qa.search.a':
      'Usa el icono de Search en la página Lessons, Lesson, Rounds o Round. Desde Lessons busca en todo el Course; desde una Lesson o sus Rounds, en esa Lesson; desde un Round, solo en ese Round. Encuentra palabras completas, frases e IDs de ejercicio, sin distinguir mayúsculas ni acentos, y puede filtrar por tipo de ejercicio. Un resultado se abre en el formulario que corresponde al modo de acceso; Search nunca cambia el Course.',
  'editorHelp.qa.internalIds.q': '¿Cómo veo los IDs internos?',
  'editorHelp.qa.internalIds.a':
      'Toca el icono de credencial en la barra superior del Editor. Muestra u oculta los IDs estables del Course, las Lessons, los Rounds y los ejercicios en las páginas del Editor y en los resultados de Search, y no cambia nada en el Course.',
  'editorHelp.qa.findHelp.q': '¿Dónde encuentro ayuda mientras edito?',
  'editorHelp.qa.findHelp.a':
      'El icono de Help en la barra superior abre esta página. Cada campo de ejercicio tiene su propio botón Help, y Exercise Help junto al preset explica todo el tipo de ejercicio. La Referencia técnica, al principio de esta página, lleva a los tipos de ejercicio, los códigos del Audit y el Course Model.',
  'editorHelp.qa.savingAndVersions.title': 'Guardar y versiones',
  'editorHelp.qa.workingCopy.q': '¿Cuándo se guardan mis cambios?',
  'editorHelp.qa.workingCopy.a':
      'Mientras editas, cada cambio va a una copia de trabajo del Course. Save y Save as draft en una Lesson, un Round o un ejercicio lo guardan solo en esa copia de trabajo. Nada llega a los estudiantes, y no se crea ninguna versión ni backup, hasta que sales del Course Editor y eliges Confirm course changes.',
  'editorHelp.qa.saveOrDraft.q':
      '¿Qué diferencia hay entre Save y Save as draft?',
  'editorHelp.qa.saveOrDraft.a':
      'Save guarda un elemento como contenido normal; Save as draft lo guarda como Draft, que los estudiantes nunca ven. Un distintivo azul marca un Draft en el elemento y en sus contenedores. Una Lesson o un Round en Draft ocultan todo lo que contienen, incluso el contenido Published.',
  'editorHelp.qa.provisionalDraft.q':
      '¿Por qué una Lesson o un Round nuevos son Draft si nunca lo elegí?',
  'editorHelp.qa.provisionalDraft.a':
      'Una Lesson o un Round nuevos empiezan como Draft provisional y pasan a Published por sí solos cuando su contenido está completo y guardado: para un Round, sus ejercicios guardados como contenido normal; para una Lesson, sus Rounds y, mientras Use GuideBook esté activado, su GuideBook. Save as draft en la Lesson o el Round los mantiene en Draft hasta que uses Save. Las copias, los Fork y los Courses importados siguen en Draft para que los revises.',
  'editorHelp.qa.leaveEditor.q': '¿Qué pasa cuando salgo del Course Editor?',
  'editorHelp.qa.leaveEditor.a':
      'Si la copia de trabajo difiere del Course guardado, un único diálogo ofrece Confirm course changes o Cancel course changes, con una nota opcional para la versión. Confirm primero crea y comprueba un backup completo, luego guarda todo el Course y sube su versión en uno. Cancel descarta toda la copia de trabajo. Si fallan el backup o el guardado, la copia de trabajo sigue abierta y el Course guardado no cambia.',
  'editorHelp.qa.leaveExercise.q':
      '¿Qué pasa si salgo de un ejercicio sin guardar?',
  'editorHelp.qa.leaveExercise.a':
      'Eliges Keep editing, Discard changes, Save as draft o Save. Discard descarta solo los cambios de ese formulario; el resto de la copia de trabajo queda como está.',
  'editorHelp.qa.publishCourse.q':
      '¿Cómo pongo un Course a disposición de los estudiantes?',
  'editorHelp.qa.publishCourse.a':
      'Pon Course delivery status en Published en la página del Course Editor (Not published lo deja solo para la edición) y luego confirma los cambios del Course. Los Draft dentro de un Course Published siguen ocultos para los estudiantes.',
  'editorHelp.qa.backups.q': '¿Dónde se guardan las versiones anteriores?',
  'editorHelp.qa.backups.a':
      'Cada cambio confirmado archiva primero la versión anterior en {folderBackups}/Courses, en una carpeta por Course. Los backups nunca se borran automáticamente. En Android 7–10, QQL pide una vez permiso para usar esa carpeta; en Android, Version History muestra solo los backups que hizo esta instalación.',
  'editorHelp.qa.restore.q': '¿Cómo vuelvo a una versión anterior?',
  'editorHelp.qa.restore.a':
      'Abre Version History en el Course Editor. Muestra la versión actual y los backups, del más nuevo al más antiguo, con Open backup folder y Export JSON. Restore into working copy carga el backup de un Custom Course en la copia de trabajo; solo sustituye el Course guardado cuando confirmas los cambios del Course. Los Courses oficiales conservan solo las versiones de su editor.',
  'editorHelp.qa.courseSettings.title': 'Ajustes del Course',
  'editorHelp.qa.privateCourse.q': '¿Qué es un Private course?',
  'editorHelp.qa.privateCourse.a':
      'Un Course personalizado visible en QQL solo para su Course Maintainer y los miembros de su Team asignado: nadie más en este dispositivo lo ve en Course Library, el Course Selector o Course Studio, ni siquiera los admins. Activa o desactiva Private course en Course Info Editor. Un archivo exportado sigue siendo privado, así que en otro dispositivo solo su Maintainer y su Team pueden importarlo; QQL rechaza importar el Private course de otra persona o usarlo en un Merge. Fork y Copy as New Course empiezan como no privados. Un estudiante que es Maintainer de un Course no se puede eliminar hasta que cambie su Maintainer; Remove custom courses y Wipe out everything también eliminan los Private course, y su confirmación cuenta los que no ves.',
  'editorHelp.qa.courseLanguages.q': '¿Cómo elijo las lenguas del Course?',
  'editorHelp.qa.courseLanguages.a':
      'Tres ajustes de idioma actúan de forma independiente. La interfaz de QQL está en inglés. La ayuda y Course Info están en inglés, español o italiano: la Help Language de cada estudiante, elegida en QQL Guide. El panel para quien estudia de un Course (títulos y líneas de instrucción de los ejercicios, botones como Check y Continue, la respuesta a cada ejercicio, el resumen de fin de Round, el Duel y la página Review) está en la Source language del Course cuando es inglés, español, italiano, alemán, portugués, neerlandés o francés; si no, en inglés. Los mensajes sobre errores, ajustes de audio y versiones de la app siguen en inglés. En New Course, Source language y Target language muestran las lenguas con su nombre en inglés: escribe para encontrar una o abre la lista. Una lengua que no está en la lista se guarda tal como la escribes, con una etiqueta opcional como nap o pt-BR. El Course guarda cada nombre con su etiqueta, y la voz y la bandera automática siguen la Target language. El panel para quien estudia nombra las lenguas en su lengua: «Traduce al alemán.» Las lenguas no cambian después de crear el Course: Course Info solo puede añadir la etiqueta de una lengua que un Course anterior escribió por nombre, y Learning language name for learners cambia el nombre que usan las líneas.',
  'editorHelp.qa.courseInfo.q':
      '¿Dónde cambio el nombre y la descripción del Course?',
  'editorHelp.qa.courseInfo.a':
      'En Course Info Editor, disponible en Edit en la página del Course Editor. El nombre puede cambiar; el Course ID nunca. La lengua base y la lengua de estudio se muestran con sus códigos y no se pueden cambiar; un Course anterior puede añadir las etiquetas de sus lenguas desde la lista, y Learning language name for learners decide cómo las líneas para quien estudia nombran la lengua que enseñas. No se guarda nada hasta que guardas el diálogo y confirmas los cambios del Course.',
  'editorHelp.qa.license.q': '¿Qué licencia puedo elegir?',
  'editorHelp.qa.license.a':
      'All rights reserved, CC0 1.0, CC BY 4.0, CC BY-SA 4.0, CC BY-NC 4.0, CC BY-NC-SA 4.0 o bien Other / Custom license, que además indica si otros pueden crear obras derivadas. La licencia cubre el contenido de tu Course, no el software QuisquisLingo (MPL-2.0), y nunca concede permisos de edición en QQL.',
  'editorHelp.qa.authors.q':
      '¿Cómo doy crédito a los autores y a los titulares de derechos?',
  'editorHelp.qa.authors.a':
      'Course Info Editor guarda los Authors / Contributors con sus roles, uno o más Rights Holders y un enlace opcional Buy a Coffee (HTTPS). Describen el Course y nunca dan a nadie permisos de edición. El Original Course Creator, el Course Maintainer, el creador de un Fork y el Last Version Editor se registran por separado.',
  'editorHelp.qa.mediaCredits.q':
      '¿Cómo doy crédito a imágenes y grabaciones hechas por otros?',
  'editorHelp.qa.mediaCredits.a':
      'Añade los créditos en Media credits: el autor, la licencia y, cuando lo sepas, de dónde procede la obra. Cuando la biblioteca de imágenes sabe quién hizo una imagen (una imagen de QQL, o una con el crédito registrado), QQL añade el crédito por ti. El Audit avisa cuando un Course con medios propios no tiene Media credits.',
  'editorHelp.qa.cover.q': '¿Cómo le pongo una imagen de portada al Course?',
  'editorHelp.qa.cover.a':
      'Usa Cover image en Course Info Editor, en Create new course o en el paso Flag or cover image del Course Wizard. Choose image toma una imagen de la biblioteca de imágenes, Quick Import lee la única imagen de {folderImageImports} y Open from… usa el diálogo del sistema. En Crop the cover elige el cuadrado que muestra la portada; se guarda a 512 × 512 píxeles. Sin portada solo se ve la bandera. La portada sustituye la bandera en las listas, en Course Info y en la cabecera del Editor, pero la bandera se sigue viendo en la página del estudiante: en la barra superior y en el Flag Background. Remove cover deja de nuevo solo la bandera.',
  'editorHelp.qa.flag.q': '¿Cómo elijo la bandera del Course?',
  'editorHelp.qa.flag.a':
      'Create new course y Course Info Editor comparten un selector de banderas con búsqueda, con las banderas de QQL FlagPainter, WORLD Flags y Upload custom flag. Busca por nombre, alias, ID, código de lengua o código de territorio. Use Automatic elige la bandera de la lengua del Course. Abrir o buscar no cambia nada hasta que eliges.',
  'editorHelp.qa.customFlag.q': '¿Cómo uso mi propia bandera?',
  'editorHelp.qa.customFlag.a':
      'Copia un PNG o JPEG llamado flag.png, flag.jpg o flag.jpeg en {folderCourseFlagImports} y pulsa Upload custom flag en el selector de banderas. Puede ocupar hasta 2 MB y medir entre 64 × 40 y 4096 píxeles. QQL la reduce a 256 píxeles en su lado mayor, conserva la transparencia PNG y la guarda dentro del Course.',
  'editorHelp.qa.lessonOptions.q':
      '¿Dónde están Use GuideBook, Word Lookup, Create Duels y las opciones de etiquetas?',
  'editorHelp.qa.lessonOptions.a':
      'En Lesson Options, bajo el recuadro Lessons de la página del Course Editor. Con Use GuideBook desactivado, los estudiantes no ven los GuideBooks, cuyo contenido se conserva; Word Lookup, presente solo con Use GuideBook activado, permite al estudiante tocar una palabra para ver su traducción del GuideBook; con Create Duels desactivado, no ven Duels. Lesson label and numbering y Round label and numbering cambian cómo se muestran los nombres. Ninguna de estas opciones borra contenido, victorias, finalizaciones ni XP. Al desactivar Use GuideBook se pide confirmación y se explica por qué se recomienda el GuideBook.',
  'editorHelp.qa.labelsAndNumbering.q':
      '¿Cómo funcionan Lesson label and numbering y Round label and numbering?',
  'editorHelp.qa.labelsAndNumbering.a':
      'Ambos selectores están en Lesson Options. Cada uno ofrece Off, su propia etiqueta + número, Number only y Custom + number. Cambian el prefijo mostrado, no el título ni el ID. Cada Lesson debe tener un título; el título de un Round es opcional porque su tipo ya lo identifica. Un título asignado sigue visible con cualquier opción, incluso Off. Los números siguen la posición actual y el editor siempre muestra el orden. Los Courses antiguos conservan una etiqueta Lesson elegida anteriormente hasta que se seleccione una de las cuatro opciones actuales.',
  'editorHelp.qa.sections.q': '¿Cómo agrupo las Lessons en Sections?',
  'editorHelp.qa.sections.a':
      'En una Lesson, el selector de Section ofrece No section, los nombres existentes, Add new section… y Manage sections…. Las Lessons consecutivas con la misma Section forman un bloque en el recorrido del estudiante. Una Lesson nueva toma la Section de la Lesson anterior. No se puede quitar un nombre que todavía usa una Lesson. Las Sections no tienen progreso ni desbloqueos propios.',
  'editorHelp.qa.lessonIcon.q': '¿Cómo elijo el icono de una Lesson?',
  'editorHelp.qa.lessonIcon.a':
      'En el editor de la Lesson elige un Preinstalled icon, un Custom Course icon o Numbers; Choose from the image library toma como icono cualquier imagen QQL de la biblioteca (no una bandera), y un Course que use una necesita esta versión de QQL o posterior. Para Import custom icon, deja exactamente un PNG, JPG/JPEG o WebP de hasta 2 MB y 4096 píxeles en {folderLessonIconImports}; QQL lo centra en un cuadrado transparente de 256 × 256 y lo guarda en el Course. Sin icono, una Lesson muestra su número en un círculo del color de la Lesson: QQL da a cada Lesson uno de ocho colores según su posición, y los círculos de sus Rounds en el camino del estudiante usan el mismo color.',
  'editorHelp.qa.whoMayEdit.q': '¿Quién puede editar un Course?',
  'editorHelp.qa.whoMayEdit.a':
      'Su Course Maintainer y todos los miembros del Team asignado. Solo el Maintainer puede ceder el mantenimiento o asignar o quitar el Team, y un Team siempre conserva al menos un Team Leader. Otras personas pueden hacer Fork del Course en Course Studio solo cuando su licencia permite obras derivadas.',
  'editorHelp.qa.lessonsAndRounds.title': 'Lessons y Rounds',
  'editorHelp.qa.roundTypes.title': 'Tipos de Round',
  'editorHelp.qa.roundTypeContract.q': '¿Qué controla el tipo de Round?',
  'editorHelp.qa.roundTypeContract.a':
      'Cada Round tiene un tipo que determina su nombre e icono en el recorrido, las sugerencias del editor, las comprobaciones para publicar y, para Sequence, Story, FlashCard y Test, cómo se juega. El ejercicio sigue definido por sus datos canónicos; el preset solo ayuda a crearlo.',
  'editorHelp.qa.discover.q': '¿Cuándo uso Discover?',
  'editorHelp.qa.discover.a':
      'Discover introduce palabras, conceptos, estructuras o ejemplos. Puedes combinar explicaciones, tarjetas y primeros ejercicios guiados. Las preguntas muestran corrección inmediata y repaso normal de errores.',
  'editorHelp.qa.practice.q': '¿Cuándo uso Practice?',
  'editorHelp.qa.practice.a':
      'Practice es el Round general: normalmente mezcla las preguntas, muestra la corrección enseguida y repite los errores. Los Rounds ordinarios antiguos pasan a Practice.',
  'editorHelp.qa.listening.q': '¿Qué contiene un Round Listen?',
  'editorHelp.qa.listening.a':
      'Cada ejercicio obligatorio debe necesitar audio para responder. El selector ofrece presets compatibles y el editor canónico sigue disponible. El audio opcional no basta. El editor avisa y el Audit impide publicar contenido incompatible.',
  'editorHelp.qa.reading.q': '¿Qué contiene un Round Read?',
  'editorHelp.qa.reading.a':
      'Cada ejercicio obligatorio debe tener un texto de lectura y una pregunta verificables. Una respuesta copiada del texto no sirve. El selector ofrece presets de lectura y el editor canónico; el Audit impide publicar contenido incompatible.',
  'editorHelp.qa.flashcardRound.q': '¿Qué es un Round FlashCard?',
  'editorHelp.qa.flashcardRound.a':
      'Contiene solo Flashcard o Picture Flashcard válidas con término y significado. Cada tarjeta tiene dos caras y el estudiante les da la vuelta; las tarjetas avanzan una a una, sin puntuación de aciertos ni repaso normal de errores. El Audit rechaza otros contenidos.',
  'editorHelp.qa.testRound.q': '¿Cómo funciona un Test?',
  'editorHelp.qa.testRound.a':
      'Un Test admite solo ejercicios evaluables. El estudiante responde todo sin ver correcciones y después ve los resultados. Puedes fijar o mezclar el orden y elegir un porcentaje de aprobación opcional. El umbral cambia solo la etiqueta del resultado: finalización, XP, desbloqueos y Laurels siguen igual. La vista previa y la salida anticipada no registran nada.',
  'editorHelp.qa.timedRound.q': '¿Cómo funciona un Round Timed?',
  'editorHelp.qa.timedRound.a':
      'Elige Timed en New Round, fija un límite entre 30 segundos y 10 minutos y añade ejercicios compatibles. En Lesson Options puedes definir límites Timed predeterminados para el Curso: cada Round Timed nuevo los copia y los existentes conservan los suyos. En el editor puedes añadir límites distintos y ordenarlos. El siguiente se desbloquea tras completar el anterior a tiempo por primera vez. La cuenta atrás comienza al empezar a jugar, después de Before you start si existe. Al agotarse el tiempo, se bloquea la entrada, se conservan los XP de respuestas correctas y el Round queda incompleto para poder repetirlo. Completarlo antes de cero da los XP normales y, una sola vez por límite, un bono On Time separado de 10 XP. El Audit impide publicar límites ausentes, repetidos o inválidos y contenido que no puede terminar de forma fiable.',
  'editorHelp.qa.speakRound.q': '¿Puedo crear un Round Speak?',
  'editorHelp.qa.speakRound.a':
      'Speak aparece al final de New Round como Coming soon y no se puede elegir. Un Round Speak importado se puede leer, pero no publicar ni jugar en esta versión.',
  'editorHelp.qa.roundCompatibility.q': '¿Cómo se comprueba la compatibilidad?',
  'editorHelp.qa.roundCompatibility.a':
      'El selector filtra los presets sugeridos, pero la validación final examina el ejercicio canónico. Puedes guardar un Round incompleto como Draft; el Audit impide publicar Listen, Read, FlashCard, Test, Story, Sequence o Speak incompatibles.',
  'editorHelp.qa.roundNumbering.q': '¿Cómo funcionan los números de Round?',
  'editorHelp.qa.roundNumbering.a':
      'Round label and numbering en Lesson Options permite Off, Round + number, Number only y Custom + number. Con Off todavía aparecen el tipo y el título, por ejemplo «Practice · Saludos». El número sigue la posición en la Lesson, nunca el ID ni el progreso. El editor siempre muestra los números de orden.',
  'editorHelp.qa.newRound.q': '¿Cómo añado un Round?',
  'editorHelp.qa.newRound.a':
      'En la página Rounds de una Lesson pulsa New Round y elige el tipo; Speak aún no está disponible. Story abre su Wizard; los demás tipos empiezan como Draft provisionales, con un ejemplo solo para Discover, Practice y Sequence. El título puede quedar vacío: el estudiante sigue viendo el tipo. Round Wizard permanece junto a New Round para crear varios Rounds.',
  'editorHelp.qa.beforeYouStart.q':
      '¿Cómo escribo la nota Before you start de un Round?',
  'editorHelp.qa.beforeYouStart.a':
      'Añade una tarjeta Before you start: New Exercise en el editor del Round y elige Before you start (Cards and notes). Escribe la nota y, si el Curso usa GuideBooks, activa Open GuideBook button. La tarjeta va primero en el Round; los estudiantes la leen en una página propia antes de que empiece el Round, nunca en Review. Edítala, publícala o elimínala como cualquier ejercicio. El Round Wizard añade una tarjeta en Draft al primer Round que crea, y el Audit señala una Lesson cuyo primer Round no tiene ninguna.',
  'editorHelp.qa.roundWizard.q': '¿Cómo crea Rounds el Round Wizard?',
  'editorHelp.qa.roundWizard.a':
      'Pulsa Round Wizard en la página Rounds; necesita Use GuideBook activado. Elige el Focus module que practican los Rounds, o All modules, en orden: cada módulo tiene entonces sus propios Rounds, de Foundations a Practice y Use in context, y el número pasa a ser Rounds per module (1–12, como máximo 24 Rounds por vez; 3 por defecto) en lugar de Number of Rounds (1–12, 6 por defecto). Un módulo necesita al menos tres entradas de Words & Expressions; los demás aparecen en gris o quedan fuera, con su nombre. Elige de 1 a 15 ejercicios por Round (8 por defecto). Round titles, activado por defecto (desactivado cuando lo abre el Course Wizard), da a cada Round un título como Practice: Al bar; desactivado, los Rounds no tienen título y los estudiantes ven el tipo y el número del Round. El primer Round de cada módulo es Discover, el último un Test y los demás Practice (con dos Rounds Discover y Practice, con uno Practice). Listen Round, desactivado por defecto, convierte el Round central, de tres o más, en un Round Listen, donde cada ejercicio necesita audio: a quien lo abre con Audio Exercises desactivados se le pide activarlos (Turn on audio). Alrededor de un tercio de cada Round repasa los módulos anteriores de la Lección, del más cercano, nunca como primer ejercicio. Cada ejercicio muestra el Context de una entrada con su traducción, así tiene una sola respuesta correcta: las entradas que solo difieren por su Context se ofrecen como respuestas incorrectas, dos con el mismo Target o sinónimos (mismo Source y Context) nunca, y una respuesta escrita acepta cada sinónimo y las palabras opcionales {…}. Las Sentences dan Build the translation y Word order. Un módulo con al menos tres Words & Expressions con imagen añade Select the image, What is in the picture, Match pictures to words, Spell the word in the picture (la palabra sin artículo, hasta 12 letras, una ficha por letra), Name what you see (una entrada de dos o más palabras, con uno o dos bloques de más), Type what you see, Listen and pick the image y Picture flashcard, con sus marcas Plural; Prefer picture exercises, activado por defecto cuando un módulo tiene imágenes, hace que uno de cada dos ejercicios sea con imagen, mientras el repaso de los módulos anteriores conserva ejercicios que esos módulos pueden llenar. Un Round nunca pregunta dos veces lo mismo cuando el GuideBook tiene suficientes palabras y frases: un ejercicio toma otras entradas, u otro tipo de ejercicio de su grupo. El plan indica el foco y las palabras de cada Round; antes de generar puedes cambiar el foco o el tipo de un Round. Con Create Duels activado, el plan también cuenta las preguntas de Duel de la Lección una vez creados sus Rounds (un Duel necesita 25), aparte las que necesitan audio, y si son menos indica que subas los números. Cada Round registra su módulo de foco, donde se abre Open GuideBook, y los módulos anteriores que repasa; el primer Round de cada módulo se abre con una tarjeta Before you start que contiene una copia del Overview del módulo; cada ejercicio indica las entradas que usa. Las propuestas Read y Story no admitidas explican por qué no se pueden generar solo con el vocabulario. Los Rounds siguen en Draft hasta que los revises y apruebes.',
  'editorHelp.qa.sequence.q': '¿Qué es un Round Sequence?',
  'editorHelp.qa.sequence.a':
      'Elige Sequence en New Round. Su flujo lineal presenta los ejercicios en el orden escrito, sin mezclarlos ni repasar errores. El título opcional del flujo aparece al estudiante. Conserva New Exercise y Exercise Wizard; las preguntas aptas pueden entrar en el Duel. Elige Step by step o Scrolling en el editor.',
  'editorHelp.qa.story.q': '¿Qué es una Story?',
  'editorHelp.qa.story.a':
      'Una Story es un Round narrativo ordenado con portada, diálogos y ejercicios de comprensión. Solo los ejercicios evaluables puntúan; la finalización, XP y Laurels siguen las reglas normales. Sus preguntas quedan fuera del Duel.',
  'editorHelp.qa.newStory.q': '¿Cómo construyo una Story?',
  'editorHelp.qa.newStory.a':
      'Pulsa New Round → Story (no necesita GuideBook). Indica el título, la portada y la lectura en voz alta; revisa el narrador y los personajes del Course; luego construye pasos con Add line y Add exercise. Finish necesita al menos una línea y añade la Story a la copia de trabajo.',
  'editorHelp.qa.editStory.q': '¿Cómo cambio una Story después?',
  'editorHelp.qa.editStory.a':
      'Abre su Round. Add Step ofrece Title block (uno por Story), Dialogue line y Exercise. Las opciones de la Story fijan el título, Step by step o Scrolling, lo que conserva el registro del desplazamiento (Dialogue only o Everything) y la lectura en voz alta. “Needs the Story\'s audio” en el menú de un ejercicio marca uno que se omite con Audio Exercises desactivado; las líneas nunca se omiten.',
  'editorHelp.qa.characters.q': '¿Dónde están el narrador y los personajes?',
  'editorHelp.qa.characters.a':
      'En Story characters, en la página del Course Editor: un nombre, un avatar (una figura incluida, ninguno, o una imagen tuya recortada en cuadrado), una lengua y una preferencia de voz (cualquiera, masculina o femenina, buscada entre las voces del dispositivo). Un personaje que aún nombran líneas no se puede quitar.',
  'editorHelp.qa.guidebook.q': '¿Qué va en el GuideBook de una Lesson?',
  'editorHelp.qa.guidebook.a':
      'Un GuideBook es una lista de módulos, en el orden en que se enseñan. Un módulo es un tema breve con un Title (su propio nombre, por ejemplo Al bar), Sentences (frases de ejemplo, cada una con su traducción), Words & Expressions (palabras sueltas y expresiones fijas como buongiorno, cada una con su traducción) y un Overview breve. Cada entrada tiene un Target (el idioma de estudio), un Source (su traducción en el idioma del estudiante) y un Context opcional de 40 caracteres como máximo (el sentido, el ámbito, el registro o quién habla: restaurant o bank para il conto). Una palabra puede tener una imagen, elegida como la de un ejercicio y marcada Plural cuando significa varias cosas (i gatti, the cats); {io} marca las palabras que se pueden omitir, como un sujeto sobrentendido. Los estudiantes ven el GuideBook cuando está guardado como contenido normal y Use GuideBook está activado; Save Guidebook as draft lo mantiene oculto. Sus Words & Expressions alimentan la Review y Word Lookup, y el Round Wizard crea Rounds a partir de sus módulos. Un Round puede indicar su Focus module en el Round editor; Open GuideBook en su tarjeta Before you start se abre entonces en ese módulo.',
  'editorHelp.qa.guidebookEntries.q':
      '¿Cómo escribo las entradas del GuideBook?',
  'editorHelp.qa.guidebookEntries.a':
      'Abre un módulo desde la página del GuideBook. Add module abre una página de módulo vacía; Module Wizard, a su lado, escribe un módulo nuevo paso a paso, como el Course Wizard: A Title, B Sentences, C Words & Expressions, D Overview, con Back y Next. El título siempre hace falta; con menos de 2 Sentences o 5 Words & Expressions Next pregunta, y Continue anyway sigue; Fill with an example rellena, y Clear all vacía, solo el paso mostrado; una Overview vacía o de menos de 10 palabras pregunta antes de Finish; salir antes de Finish descarta el módulo, preguntando antes; después de Finish propone otro módulo. Las casillas Target y Source nombran las lenguas del Course, como Target: Italian y Source: English. Cada fila de Sentences y de Words & Expressions tiene un Target (el idioma de estudio), un Source (su traducción en el idioma del estudiante) y un Context opcional de 40 caracteres como máximo. El Context distingue los sentidos: en un Curso de inglés para italianos, string = stringa [informatica] y string = laccio [scarpe] son dos entradas, y el estudiante ve el Context en gris después de la traducción. Una palabra con varios sentidos son varias entradas. Escribe {…} alrededor de las palabras que se pueden omitir, como un sujeto sobrentendido: {io} sono stanco se ve (io) sono stanco y Word Lookup encuentra las dos formas; no se admite ninguna otra sintaxis de respuestas. Una entrada de Words & Expressions puede tener una imagen, elegida como la de un ejercicio; Plural marca una palabra que significa varias cosas (i gatti, the cats), y el estudiante ve copias superpuestas. En un Curso hacia el inglés o desde el inglés, el lado inglés de una palabra propone una imagen QQL al salir de la casilla: si una sola imagen tiene el nombre de la palabra (sin contar mayúsculas ni un a, an o the inicial) llena la fila con la marca Suggested; si ninguna lo tiene, se prueba el singular (cats encuentra Cat, marcada Plural y Suggested, plural) y luego el nombre antes de un paréntesis (baker encuentra Baker (man) y Baker (woman)). Si coinciden varias imágenes, N matching pictures abre la biblioteca ya buscada por la palabra. Nada se propone en lugar de una imagen que elegiste, una imagen que quitas sigue quitada hasta que la palabra cambie, y nunca se proponen letras, cifras, iconos de Lección ni nombres de una sola letra. Suggest pictures, bajo Words & Expressions, hace lo mismo para cada palabra sin imagen, también las escritas antes (si no, un módulo reabierto nunca recibe propuestas); una imagen que ya está se queda. Paste list añade muchas entradas a la vez, una por línea como target = source [context]; las líneas que no puede leer se enumeran y no se añaden. Fill with an example llena la página con un módulo de ejemplo completo (en italiano e inglés) y Clear all la vacía; ambos preguntan antes. Done conserva el módulo; una fila con Target y sin Source, o al revés, se señala, y una fila vacía se descarta. El GuideBook se guarda con Save Guidebook.',
  'editorHelp.qa.moduleLength.q': '¿Qué longitud debe tener un módulo?',
  'editorHelp.qa.moduleLength.a':
      'Breve: un tema coherente que el estudiante abarca de una vez, como los saludos o pedir en el bar, con un Overview de dos o tres frases. Un buen tamaño es de unas 8 Words & Expressions y 3–4 Sentences que las usen, con 4 módulos por Lesson: así el Round Wizard practica cada entrada 3–4 veces y nunca pregunta dos veces lo mismo en un Round. Lo que funciona: de 3 a 6 módulos, de 5 a 10 palabras y de 2 a 5 Sentences por módulo. Con menos, los Rounds repiten ejercicios; con más de 12 entradas en un módulo, algunas pueden quedarse sin ejercicio; más de 6 módulos hacen una Lesson larga. Cada Sentence debería contener al menos una palabra del módulo, para que Pick the missing word pueda usarla. Avisos en gris lo dicen en las páginas del GuideBook, en la página del módulo (que cuenta sus palabras y Sentences), en el Course Wizard y en el plan del Round Wizard, y la Audit indica GUIDEBOOK_MODULE_SIZE y GUIDEBOOK_MODULE_COUNT (Info). La página del módulo también cuenta los caracteres del Overview; a partir de 500 sugiere dividir el tema, y la Audit indica GUIDEBOOK_MODULE_OVERVIEW_LONG (Info). Ninguno impide guardar. Un tema más largo se lee mejor como dos módulos en orden: cada Round puede indicar su Focus module y Open GuideBook se abre en él. Un módulo sin entradas recibe el Warning GUIDEBOOK_MODULE_EMPTY.',
  'guidebookHelp.field.title.title': 'Title',
  'guidebookHelp.field.title.body':
      'El nombre propio del módulo: un tema breve, por ejemplo Al bar o Saluti. El estudiante lo ve como encabezado del módulo en el GuideBook, y el menú Focus module del Round editor lo enumera. Obligatorio: Done rechaza un módulo sin título.',
  'guidebookHelp.field.sentences.title': 'Sentences',
  'guidebookHelp.field.sentences.body':
      'Frases de ejemplo en uso, cada una con su traducción: Lei è stanca? = Are you tired?, con el Context formal, to a woman. Cada fila tiene un Target, un Source y un Context opcional. El estudiante las lee en el GuideBook y el Round Wizard crea ejercicios con ellas; Review y Word Lookup leen solo las Words & Expressions, y una frase no tiene imagen.',
  'guidebookHelp.field.words.title': 'Words & Expressions',
  'guidebookHelp.field.words.body':
      'Palabras sueltas y expresiones fijas (buongiorno, a la larga), cada una con su traducción. Una palabra con dos sentidos son dos entradas, distinguidas por su Context: il conto = the bill [restaurant] e il conto = the account [bank]. Una entrada puede tener una imagen. La Review del vocabulario y Word Lookup leen estas entradas, y el Round Wizard crea ejercicios con ellas.',
  'guidebookHelp.field.target.title': 'Target',
  'guidebookHelp.field.target.body':
      'La palabra, la expresión o la frase en el idioma que enseña el Curso, tal como el estudiante debe aprenderla: il caffè, buongiorno. Escribe {…} alrededor de las palabras que se pueden omitir, como un sujeto sobrentendido: {io} sono stanco se ve (io) sono stanco con io en gris, y Word Lookup encuentra las dos formas. Solo se admite {…}, sin anidar y nunca vacío; se rechazan [, ], | y <>.',
  'guidebookHelp.field.source.title': 'Source',
  'guidebookHelp.field.source.body':
      'Su traducción en el idioma del estudiante: espresso, good morning. Escribe la traducción de este sentido; otro sentido es otra entrada, con su propio Context.',
  'guidebookHelp.field.context.title': 'Context (opcional)',
  'guidebookHelp.field.context.body':
      'Una nota breve en el idioma del estudiante, de 40 caracteres como máximo: el sentido, el ámbito, formal o informal, quién habla. Ejemplos: restaurant y bank para il conto; formal, to a woman para Lei è stanca?. El estudiante la ve en gris después de la traducción, en el GuideBook, en las tarjetas de Review y en Word Lookup. Déjala vacía cuando la entrada no necesita nota.',
  'guidebookHelp.field.picture.title': 'Picture (opcional)',
  'guidebookHelp.field.picture.body':
      'El aspecto de una entrada de Words & Expressions, elegido como la imagen de un ejercicio: la biblioteca de imágenes, las imágenes del Curso o un archivo. Plural marca una palabra que significa varias cosas (i gatti, the cats): el estudiante ve copias superpuestas. El estudiante ve la imagen en el GuideBook, en las tarjetas de Review después de la respuesta y en Word Lookup. En un Curso cuyo Target o Source es el inglés, salir de la casilla de una palabra propone la imagen QQL que tiene el nombre de la palabra (sin contar mayúsculas ni un a, an o the inicial), marcada Suggested; luego su singular (cats encuentra Cat, marcada Suggested, plural); luego el nombre antes de un paréntesis (baker encuentra Baker (man) y Baker (woman)). Si coinciden varias imágenes, N matching pictures abre la biblioteca ya buscada por la palabra. Nada se propone en lugar de una imagen que elegiste; una imagen que quitas sigue quitada hasta que la palabra cambie; nunca se proponen letras, cifras, iconos de Lección ni nombres de una sola letra. Suggest pictures, bajo Words & Expressions, propone imágenes para cada palabra que no tiene, también las escritas antes; una imagen que ya está se queda.',
  'guidebookHelp.field.overview.title': 'Overview',
  'guidebookHelp.field.overview.body':
      'Dos o tres frases sobre el tema: de qué trata, una regla, una nota de uso. El estudiante lo lee después de las entradas. El contador muestra su longitud; a partir de 500 caracteres un aviso, y un Info en la Audit, sugieren dividir el tema en módulos más breves. Ninguno de los dos impide guardar.',
  'guidebookHelp.field.pasteList.title': 'Paste list',
  'guidebookHelp.field.pasteList.body':
      'Añade muchas entradas a la vez, una por línea: target = source [context], el Context entre corchetes al final y opcional. Además de = se leen los separadores →, - (con espacios) y :. Líneas de ejemplo: il conto = the bill [restaurant]; buongiorno = good morning. Cada entrada recibe su propio ID; las líneas que no se pueden leer se enumeran con el motivo y no se añaden. Las Words & Expressions pegadas reciben sus imágenes propuestas.',
  'editorHelp.qa.wordLookup.q':
      '¿Cómo usa Word Lookup el vocabulario del GuideBook?',
  'editorHelp.qa.wordLookup.a':
      'En una Round, las palabras del idioma de estudio que son entradas de Words & Expressions del GuideBook llevan un ligero subrayado de puntos, y el estudiante puede tocar una para ver las entradas que coinciden, de todo el curso: las de la Lesson actual si las hay, si no las de todas las Lessons, indicando la Lesson de una entrada que viene de otra Lesson. Una expresión entera escrita en el texto (il pane, l\'acqua) gana a la palabra sola; una palabra que solo aparece dentro de una expresión la muestra cuando las demás palabras de la expresión son artículos (gatto muestra il gatto, è no muestra dov\'è); las formas flexionadas no se encuentran, así que añade las formas que quieras que se puedan consultar. El texto en el idioma del estudiante, la Instruction or context y las notas de Before you start nunca se consultan, ni las opciones de respuesta, las Rounds de tipo Test o los Duels. La tarjeta muestra el Context de la entrada tras la traducción y su imagen, si la tiene; las Sentences nunca se consultan. La tarjeta dice que muestra una traducción posible. Word Lookup está activado por defecto; se desactiva en Lesson Options. Solo existe con Use GuideBook activado.',
  'editorHelp.qa.duel.q': '¿Cuándo está disponible el Duel de una Lesson?',
  'editorHelp.qa.duel.a':
      'Un Duel toma 25 ejercicios aptos y distintos de la Lesson (ejercicios de elección con una sola respuesta de sus Rounds, sin contar las Stories) y da cuatro vidas; ganas si respondes los 25 antes de perderlas. Con menos de 25 ejercicios aptos, el Duel simplemente no está disponible: es normal, no un error. El Duel de la última Lesson se muestra como Final Duel. Un Course nuevo empieza con Create Duels desactivado, en el Course Wizard igual que en New Course: actívalo en Lesson Options cuando las Lessons tengan suficientes ejercicios.',
  'editorHelp.qa.copyMove.q':
      '¿Cómo duplico, copio o muevo Lessons, Rounds y ejercicios?',
  'editorHelp.qa.copyMove.a':
      'Duplicate pone una copia independiente con IDs nuevos justo después del original. Copy to… y Move to… eligen una Lesson o un Round de este Course. Mover conserva los IDs y el estado; una copia recibe IDs nuevos y empieza en Draft. Todo ocurre en la copia de trabajo hasta que confirmas los cambios del Course.',
  'editorHelp.qa.preview.q':
      '¿Cómo pruebo el Course, una Lesson o un Round como estudiante?',
  'editorHelp.qa.preview.a':
      'Preview, en los editores de Lesson y de Round, reproduce la copia de trabajo tal como la ven los estudiantes, incluidos los Draft. Preview no guarda nada y nunca escribe progreso, XP, streaks, Laurels, Review ni resultados de Duel. La bandera (o la portada) del Course a la izquierda del título, en cada pantalla del Course Editor, abre la página del estudiante sobre la copia de trabajo: Draft incluidos, todas las Lessons abiertas, nada completado. Arriba hay una barra ámbar PREVIEW. Allí se pueden jugar Rounds, Stories, GuideBooks y Duels; abajo están Course Info, Theme y Flag background, cuyos cambios valen solo para la vista previa, y el Course que estudias no cambia. Exit vuelve a la misma pantalla con los cambios aún pendientes de la confirmación del Course. Desde un formulario de ejercicio la vista previa muestra lo que guardaste, no los cambios sin guardar del formulario.',
  'editorHelp.qa.exercises.title': 'Ejercicios',
  'editorHelp.qa.newExercise.q': '¿Cómo añado un ejercicio?',
  'editorHelp.qa.newExercise.a':
      'En un Round, New Exercise abre el selector de presets: elige un tipo de ejercicio, como Pick the translation o Name what you see, y rellena su formulario. En un ejercicio nuevo, Fill with an example pone en el formulario el ejemplo de ese tipo tomado de QQL Demo: Italian Exercise Lab (en inglés e italiano, sean cuales sean las lenguas del curso) y Clear all devuelve el formulario a como empieza el tipo; si cambias de tipo después de rellenar campos, un mensaje te pide que los revises todos. La última opción, Canonical editor, abre el editor canónico para cualquier primitiva, con los mismos dos botones: Fill with an example pone en él un ejemplo que funciona de la primitiva elegida y Clear all lo vacía de nuevo; su botón Help abre la sección de esa primitiva en la referencia Exercise primitives. El nombre del preset aparece en negrita en la parte superior del formulario.',
  'editorHelp.qa.pageCards.q':
      '¿Cómo creo una Page como la de un libro de texto?',
  'editorHelp.qa.pageCards.a':
      'En el editor del Round pulsa New Exercise y elige Page (Cards and notes). Añade bloques con Add block: títulos, párrafos, citas o ejemplos, listas con viñetas o numeradas, imágenes, audio y enlaces de vídeo; ordénalos con las flechas. En el texto escribe **negrita** y *cursiva* (la barra de herramientas rodea la selección). Cada bloque de texto tiene una alineación, un color de la paleta y una lectura en voz alta opcional; cada imagen un tamaño, una alineación y un pie de foto. Un enlace de vídeo abre una dirección https en el navegador del estudiante. La vista previa bajo los bloques muestra la Page tal como la ve el estudiante. Varias páginas seguidas son varias tarjetas Page; elige un Round Sequence para mantener su orden. Bajo cada Page los estudiantes encuentran Share, Save PDF y Print (en los ordenadores Print abre el PDF en el visor, que lo imprime); el PDF cita el Curso, el titular de los derechos y la licencia. Puedes desactivarlos en Course Info con Learners may share, save and print pages.',
  'editorHelp.qa.presetOrCanonical.q':
      '¿Qué diferencia hay entre un preset y el editor canónico?',
  'editorHelp.qa.presetOrCanonical.a':
      'Un preset es un formulario sencillo para un tipo de ejercicio; escribe datos de ejercicio ordinarios. El editor canónico muestra todos los campos de la primitiva del ejercicio (select, input, arrange, match, assign, etc.) con sus valores permitidos. Un ejercicio que ningún preset puede representar exactamente se abre en el editor canónico, así que no se pierde nada.',
  'editorHelp.qa.changeType.q': '¿Puedo cambiar el tipo de un ejercicio?',
  'editorHelp.qa.changeType.a':
      'No, el tipo queda fijado en cuanto el ejercicio existe. Crea un ejercicio del otro tipo y borra el antiguo.',
  'editorHelp.qa.exerciseWizard.q': '¿Cómo funciona el Exercise Wizard?',
  'editorHelp.qa.exerciseWizard.a':
      'En un Round, Exercise Wizard planifica 1–30 ejercicios: una mezcla equilibrada o aleatoria, algunas categorías, tipos concretos o un patrón repetido. Después de confirmar el plan, cada paso abre el formulario normal: Save comprueba y se queda, Next comprueba y avanza, Finish devuelve los ejercicios en el orden del plan. Si cancelas después de guardar, se te pregunta si quieres conservar los ejercicios ya guardados.',
  'editorHelp.qa.previewExercise.q': '¿Cómo previsualizo un ejercicio?',
  'editorHelp.qa.previewExercise.a':
      'Preview, junto a Save, reproduce el formulario actual tal como lo ven los estudiantes, incluso para un ejercicio nuevo o en Draft, sin guardar nada ni escribir progreso del estudiante. Al volver se recuperan los mismos valores.',
  'editorHelp.qa.inspection.q': '¿Qué muestra Inspection?',
  'editorHelp.qa.inspection.a':
      'Los datos técnicos del ejercicio, sus campos canónicos. Solo muestra: no guarda nada y no cambia nada.',
  'editorHelp.qa.navigate.q': '¿Cómo paso de un ejercicio a otro?',
  'editorHelp.qa.navigate.a':
      'Previous y Next siguen el orden del Round. Si sales con cambios sin guardar, se ofrecen Keep editing, Discard changes, Save as draft o Save; la ruta de navegación lleva de vuelta al Round, a la Lesson y al Course.',
  'editorHelp.qa.fieldHelp.q': '¿Qué explica el botón Help junto a un campo?',
  'editorHelp.qa.fieldHelp.a':
      'Para qué sirve el campo, qué escribir, cómo lo comprueba QQL y un ejemplo. Exercise Help junto al preset explica el tipo de ejercicio en conjunto.',
  'editorHelp.qa.editorNotes.q': '¿Qué son las Editor notes?',
  'editorHelp.qa.editorNotes.a':
      'Una nota opcional en un ejercicio, para ti y los demás autores, al final de su formulario (formulario del preset o editor canónico), de hasta 2.000 caracteres: qué revisar, una idea, una fuente. Los estudiantes nunca la ven. Un ejercicio con nota muestra un icono en su fila del editor del Round: pasa el ratón por encima, o mantenlo pulsado, para leerla. Las notas se guardan en el archivo del Course, así que viajan con la exportación, la importación, Copy as New Course y Fork, y un Course con notas necesita esta versión de QuisquisLingo o una posterior para abrirse. Export as Publisher Course las deja fuera.',
  'editorHelp.qa.manyAnswers.q': '¿Cómo acepto varias respuestas escritas?',
  'editorHelp.qa.manyAnswers.a':
      'Escribe una respuesta completa por línea. Las palabras opcionales van entre {…}, las alternativas en [a|b] y las palabras que pueden intercambiarse en (a <> b). Las respuestas formadas con bloques y las respuestas de los huecos de escucha son literales: escríbelas exactamente.',
  'editorHelp.qa.capitals.q':
      '¿Importan las mayúsculas en las respuestas formadas con bloques?',
  'editorHelp.qa.capitals.a':
      'No: QQL relaciona la respuesta con sus bloques sin importar las mayúsculas, así que las mayúsculas nunca bloquean Save. El Audit avisa (ARRANGE_ANSWER_CASE_DIFFERS) cuando difieren, porque los estudiantes forman la respuesta con los bloques tal como están escritos.',
  'editorHelp.qa.distractors.q': '¿Cuántos bloques extra puedo añadir?',
  'editorHelp.qa.distractors.a':
      'Pocos bloques extra funcionan mejor. Para Put the words in order, Build the translation y Name what you see se recomiendan 0, 1 o 2 bloques que no están en la respuesta, menos en los primeros Rounds de una Lesson: más hacen el ejercicio más lento de leer y difícil por la razón equivocada. Se admiten más, porque es una elección didáctica: el Course Audit los muestra como Info. Los presets de deletreo ofrecen solo los bloques de la palabra, y solo esos se recomiendan; también se admite un ejercicio de deletreo con bloques extra (hecho en el canonical editor o importado). Se recomienda un distractor en el idioma de la respuesta.',
  'editorHelp.qa.difficulty.q': '¿Qué indican las barras de dificultad?',
  'editorHelp.qa.difficulty.a':
      'QQL calcula la dificultad de cada ejercicio a partir de lo que hace quien estudia, de 0 a 4: 0 una tarjeta para leer (Flashcard, Note card, Page); 1 reconocer el significado (elegir o emparejar una respuesta en la lengua de partida o una imagen); 2 reconocer la lengua (elegir, emparejar o clasificar formas de la lengua meta); 3 construir con bloques (poner bloques en orden o en huecos); 4 escribir (teclear la respuesta). El Round editor muestra cuatro barras junto a cada ejercicio, llenas hasta su nivel; la página Rounds muestra la media de cada Round. Las tarjetas Before you start, las portadas de las Story y las Dialogue line no tienen nivel. El nivel nunca se guarda: si cambias un ejercicio, cambia también su nivel. Normalmente una Lesson funciona mejor de los Round más fáciles a los más difíciles: empieza por el reconocimiento y deja la escritura para los Round posteriores, mezclando de todos modos los tipos en cada Round. En el primer completado de un Round, cada ejercicio acertado al primer intento da a quien estudia 1 XP por nivel como bonificación por dificultad.',
  'editorHelp.qa.firstLetter.q':
      '¿Qué hace Show the first letter en Type the missing word?',
  'editorHelp.qa.firstLetter.a':
      'Activado, el hueco muestra la primera letra de la palabra, así que cada palabra aceptada debe empezar por ella. Desactivado, el estudiante escribe la palabra entera y las palabras aceptadas pueden empezar por letras distintas.',
  'editorHelp.qa.readAndAnswer.q':
      '¿Cómo escribo un ejercicio Read and answer?',
  'editorHelp.qa.readAndAnswer.a':
      'Escribe la situación en Text to read, en la lengua base de los estudiantes; añade líneas de diálogo en la lengua de estudio, un “Speaker: texto” por línea, y elige si se leen en voz alta automáticamente, a petición o nunca; luego escribe la pregunta y las respuestas en la lengua de estudio. El texto para leer nunca se lee en voz alta, y la lectura en voz alta nunca lo convierte en un ejercicio de audio.',
  'editorHelp.qa.pictures.q': '¿Qué ejercicios usan una imagen?',
  'editorHelp.qa.pictures.a':
      'What is in the picture (elegir el nombre), Name what you see (formar el nombre con bloques de palabras), Type what you see (escribir el nombre), Spell the word in the picture y Picture flashcard: elige la imagen en Exercise image. Match pictures to words tiene en cambio una imagen por palabra, elegida debajo de sus palabras, y Select the image y Listen and pick the image, una imagen por respuesta, elegida debajo de las respuestas: estos tres no tienen Exercise image. El aspecto de las imágenes de Select the image y Listen and pick the image se elige para todo el curso en Lesson Options › Picture answers (Picture size, Picture shape, Pictures per row, Picture border; sin una elección cuadrados grandes, dos por fila, con una línea gris fina en un Course nuevo), y cada ejercicio puede elegir el suyo en su formulario. Square muestra cada imagen recortada en un cuadrado: Crop square bajo una imagen elige la parte y el zoom y guarda la copia recortada en el curso.',
  'editorHelp.qa.allTypes.q': '¿Dónde se explica cada tipo de ejercicio?',
  'editorHelp.qa.allTypes.a':
      'En Referencia técnica › Exercise types, al principio de esta página, y con Exercise Help junto a cada preset.',
  'editorHelp.qa.picturesAndSound.title': 'Imágenes y sonido',
  'editorHelp.qa.audioModes.q': '¿Qué modos de audio puede usar un Course?',
  'editorHelp.qa.audioModes.a':
      'En Audio Library elige On-Device TTS (la voz del dispositivo, sin grabaciones), Recorded MP3 (solo tus grabaciones) o Hybrid (las grabaciones y, si faltan, la voz del dispositivo). Import MP3, Open from… y Check unused MP3 files aparecen solo con Recorded MP3 e Hybrid.',
  'editorHelp.qa.addRecordings.q': '¿Cómo añado grabaciones?',
  'editorHelp.qa.addRecordings.a':
      'Copia archivos MP3 en {folderAudioImports} y pulsa Import MP3, o usa Open from… para elegir hasta 100 archivos (250 MB) a la vez. Cada uno debe ser un MP3 real de 50 MB como máximo, sin imagen de portada incrustada. Se copia en la carpeta de medios propia del Course, derivada del Course ID estable, y se nombra según su contenido, así que la misma grabación se guarda una sola vez; los metadatos y las referencias pertenecen al Course. Después asocia cada grabación a la palabra o frase exacta que dice.',
  'editorHelp.qa.recordingsTravel.q': '¿Las grabaciones viajan con el Course?',
  'editorHelp.qa.recordingsTravel.a':
      'Sí, en un Course ZIP exportado, y los backups verificados de las versiones del Course también copian las grabaciones referenciadas. Un Course JSON por sí solo guarda los metadatos de los clips y las referencias a su contenido, no los bytes de los MP3.',
  'editorHelp.qa.addPictures.q': '¿Cómo añado imágenes a un Course?',
  'editorHelp.qa.addPictures.a':
      'En la Image Library del Course Editor, Add images to this Course añade una o más imágenes, o un Image Bank ZIP completo, solo a este Course. La Shared Image Library, que gestiona un Admin, toma imágenes de {folderImageImports} o con Open image files from… y Open Image Bank ZIP from…. Una imagen elegida para un ejercicio desde la Shared Image Library se copia en el Course; en ambos casos viaja en el Course ZIP.',
  'editorHelp.qa.findPicture.q': '¿Cómo encuentro una imagen?',
  'editorHelp.qa.findPicture.a':
      'En la biblioteca de imágenes escribe en Search: busca en nombres, etiquetas, Local words y categorías. Con Search all marcado (por defecto) busca en todas las categorías; desmárcalo para buscar solo en la categoría que estás viendo. Las categorías están sobre las imágenes, las afines reunidas en grupos (People, Food & drink, Nature & animals…): un grupo abre una segunda fila con sus categorías, como hace Characters con las escrituras, la puntuación, los signos de moneda y de matemáticas y las letras de bloques de juguete. Una categoría muestra también las imágenes con su nombre como etiqueta, y singular y plural cuentan como uno (“dogs” encuentra los perros); el signo de interrogación arriba en la biblioteca abre su Ayuda. En la vista grande de una imagen, la categoría es un enlace que la abre, y también cada etiqueta: una etiqueta muestra solo las imágenes que la llevan (o que se llaman así), en todas las categorías, bajo un chip Tag; quita el chip o elige una categoría para volver. Al escribir en Search se encuentran todas las palabras que contienen lo que escribes. Las banderas son las World Flags, siempre enteras. Recognize characters abre la biblioteca en los caracteres.',
  'editorHelp.qa.pictureRules.q': '¿Qué imágenes acepta QQL?',
  'editorHelp.qa.pictureRules.a':
      'Imágenes fijas PNG, JPEG o WebP de 4096 × 4096 píxeles como máximo, sin daños y sin metadatos excesivos; QQL comprueba el contenido, no el nombre del archivo. Una imagen de ejercicio importada de {folderImageImports} puede ocupar hasta 300 KB; unos 256 × 256 píxeles y 15 KB es un buen tamaño.',
  'editorHelp.qa.imageBank.q': '¿Qué es un Image Bank?',
  'editorHelp.qa.imageBank.a':
      'Un ZIP de imágenes con un manifiesto, image_bank_manifest.json, que enumera cada imagen: un id, una etiqueta (primary_term), su nombre de archivo y, si quieres, palabras clave y una atribución. El ZIP contiene solo el manifiesto y las imágenes que enumera. Import Image Bank ZIP lee el único ZIP de {folderImageImports}; Open Image Bank ZIP from… usa el diálogo del sistema. Límites: un ZIP de 50 MB, 2500 imágenes y 300 KB por imagen. Una categoría que la biblioteca no tiene la asigna el Admin a una de sus categorías, o a Other: no se crea ninguna categoría nueva. Una imagen cuya única etiqueta es su nombre se señala, para que el Admin añada otra.',
  'editorHelp.qa.pictureDetails.q': '¿Cómo veo los detalles de una imagen?',
  'editorHelp.qa.pictureDetails.a':
      'Ábrela a tamaño completo y pasa el cursor sobre la imagen en un ordenador, o mantenla pulsada en un teléfono: nombre de archivo, tamaño, dimensiones, formato, fecha en que se añadió, Image Bank y atribución.',
  'editorHelp.qa.removePicture.q': '¿Cómo quito una imagen de un Course?',
  'editorHelp.qa.removePicture.a':
      'En la Image Library del Course Editor, Remove from this Course elimina todos los usos de la imagen; el archivo sale del Course cuando se confirman los cambios del Course.',
  'editorHelp.qa.checkingTheCourse.title': 'Revisar el Course',
  'editorHelp.qa.runAudit.q': '¿Cómo reviso un Course?',
  'editorHelp.qa.runAudit.a':
      'Ejecuta Audit en la página del Course Editor para todo el Course, o desde el menú (⋮) de una Lesson o de un Round en las páginas Lessons y Rounds, o de un ejercicio en el editor del Round (lo que pone en rojo su tarjeta). Muestra Error, Warning e Info, ordenados por Lesson, por tipo de ejercicio o por el cambio más reciente.',
  'editorHelp.qa.severities.q':
      '¿Qué diferencia hay entre un Error, un Warning e Info?',
  'editorHelp.qa.severities.a':
      'Un Error señala contenido no válido: no se puede guardar como contenido normal, publicar ni importar. Un Warning señala un probable problema que conviene revisar. Info es una orientación o un dato neutro y nunca bloquea nada.',
  'editorHelp.qa.borders.q':
      '¿Qué significan los bordes rojos y verdes y el distintivo azul?',
  'editorHelp.qa.borders.a':
      'Un borde rojo señala un Error o un Warning en algún lugar de esa rama; un borde verde indica que no hay ninguno (puede quedar Info). El distintivo azul señala contenido Draft en la rama. Verde no significa Published.',
  'editorHelp.qa.auditCodes.q': '¿Dónde están todos los códigos del Audit?',
  'editorHelp.qa.auditCodes.a':
      'En Referencia técnica › Audit Codes, al principio de esta página: todas las reglas por gravedad, con búsqueda.',
  'editorHelp.qa.auditLimits.q':
      '¿El Audit revisa la gramática o las traducciones?',
  'editorHelp.qa.auditLimits.a':
      'No. Revisa la estructura y la autoría: campos, IDs, bloques, audio, imágenes y similares. No certifica la gramática, la exactitud de las traducciones ni la calidad didáctica: previsualiza y revisa tus ejercicios.',
  'editorHelp.qa.searchLabel': 'Buscar en las preguntas',
  'editorHelp.qa.noResults': 'Ninguna pregunta coincide con tu búsqueda.',
  'editorHelp.title': 'Ayuda de Course Editor',
  'courseStudioHelp.title': 'Ayuda de Course Studio',
  'editorHelp.technicalReference.title': 'Referencia técnica',
  'editorHelp.technicalReference.body':
      'En desarrollo. Estas páginas describen la implementación actual de Course Model v12, aparte de las instrucciones prácticas de Course Editor.',
  'courseStudioHelp.courseTypes.title': 'Tipos de curso',
  'courseStudioHelp.courseTypes.intro': 'En QQL hay tres tipos de curso:',
  'courseStudioHelp.courseTypes.type1':
      '1. Official Bundled Course: viene con QQL y se confía en él por la distribución de la app.',
  'courseStudioHelp.courseTypes.type2':
      '2. Publisher Course: lo distribuye un editor por separado y se importa en QQL. La verificación del editor es un estado aparte.',
  'courseStudioHelp.courseTypes.type3':
      '3. Custom Course: lo crean o importan los usuarios; incluye copias, Fork y Merge.',
  'courseStudioHelp.courseTypes.row1.col1': 'Aspecto',
  'courseStudioHelp.courseTypes.row1.col2': 'Official Bundled',
  'courseStudioHelp.courseTypes.row1.col3': 'Publisher Course',
  'courseStudioHelp.courseTypes.row1.col4': 'Custom',
  'courseStudioHelp.courseTypes.row2.col1': 'Origen',
  'courseStudioHelp.courseTypes.row2.col2': 'Incluido en QQL',
  'courseStudioHelp.courseTypes.row2.col3': 'Versión importada de un editor',
  'courseStudioHelp.courseTypes.row2.col4': 'Creado o importado por usuarios',
  'courseStudioHelp.courseTypes.row3.col1': 'Confianza',
  'courseStudioHelp.courseTypes.row3.col2': 'Distribución de la app',
  'courseStudioHelp.courseTypes.row3.col3':
      'Firma válida de un editor aprobado',
  'courseStudioHelp.courseTypes.row3.col4':
      'Sin verificación oficial de editor',
  'courseStudioHelp.courseTypes.row4.col1': 'Edición',
  'courseStudioHelp.courseTypes.row4.col2': 'Solo lectura',
  'courseStudioHelp.courseTypes.row4.col3': 'Solo lectura',
  'courseStudioHelp.courseTypes.row4.col4':
      'Course Maintainer / Assigned Team autorizados',
  'courseStudioHelp.courseTypes.row5.col1': 'Copia',
  'courseStudioHelp.courseTypes.row5.col2': 'Fork si la licencia lo permite',
  'courseStudioHelp.courseTypes.row5.col3': 'Fork si la licencia lo permite',
  'courseStudioHelp.courseTypes.row5.col4': 'Copy as New Course con permiso',
  'courseStudioHelp.courseTypes.row6.col1': 'Fork',
  'courseStudioHelp.courseTypes.row6.col2': 'Solo si se permiten derivados',
  'courseStudioHelp.courseTypes.row6.col3': 'Solo si se permiten derivados',
  'courseStudioHelp.courseTypes.row6.col4': 'Solo si se permiten derivados',
  'courseStudioHelp.courseTypes.row7.col1': 'Merge',
  'courseStudioHelp.courseTypes.row7.col2': 'No es fuente custom',
  'courseStudioHelp.courseTypes.row7.col3': 'No es fuente custom',
  'courseStudioHelp.courseTypes.row7.col4':
      'Dos fuentes custom; nuevo resultado custom',
  'courseStudioHelp.courseTypes.row8.col1': 'Mantenimiento',
  'courseStudioHelp.courseTypes.row8.col2': 'Editor de QQL',
  'courseStudioHelp.courseTypes.row8.col3': 'Editor externo',
  'courseStudioHelp.courseTypes.row8.col4': 'Course Maintainer / Assigned Team',
  'courseStudioHelp.courseTypes.row9.col1': 'Publicación',
  'courseStudioHelp.courseTypes.row9.col2': 'Versión de la app',
  'courseStudioHelp.courseTypes.row9.col3': 'Distribución del editor',
  'courseStudioHelp.courseTypes.row9.col4': 'Published o Not published',
  'courseStudioHelp.courseTypes.row10.col1': 'Eliminación',
  'courseStudioHelp.courseTypes.row10.col2':
      'Solo quitar de la biblioteca personal',
  'courseStudioHelp.courseTypes.row10.col3':
      'Quitar de la biblioteca; desinstalación por Admin si nadie más lo usa',
  'courseStudioHelp.courseTypes.row10.col4':
      'Delete course en Course Studio con permiso',
  'courseStudioHelp.courseTypes.row11.col1': 'Actualizaciones',
  'courseStudioHelp.courseTypes.row11.col2': 'Nueva versión de QQL',
  'courseStudioHelp.courseTypes.row11.col3':
      'Versión más reciente con el mismo Course ID y editor',
  'courseStudioHelp.courseTypes.row11.col4': 'Versiones custom independientes',
  'courseStudioHelp.courseTypes.note1':
      'Un Publisher Course importado necesita una firma verificada. Se conservan los cursos ya guardados que no se pueden verificar y su progreso, con Verification required. Consulta Publisher signing and approval en Technical reference.',
  'courseStudioHelp.courseTypes.note2':
      'Bundled y External son dos orígenes oficiales; verified / unverified describe autenticidad, no un cuarto tipo. Un archivo no verificado no se acepta como Publisher Course nuevo.',
  'courseStudioHelp.courseTypes.note3':
      'Copy crea un Custom Course independiente. Fork también es custom, conserva el origen y sigue sujeto a la licencia original. Ninguno se vuelve oficial por venir de una fuente oficial.',
  'courseStudioHelp.courseTypes.note4':
      'Merge crea un Custom Course nuevo a partir de dos cursos custom sin cambiar las fuentes. Creado, importado, copiado, derivado o fusionado describen el origen, no otros tipos.',
  'courseStudioHelp.courseTypes.contact':
      'Para distribuir un curso con la app o pedir aprobación como editor externo, contacta con el equipo QQL. La guía de firmas explica el proceso.',
  'appInfo.versionAndBuild.title': 'Versión y Build',
  'appInfo.versionAndBuild.body': '{version}',
  'appInfo.choosingAndOpeningCourses.title': 'Elegir y abrir cursos',
  'appInfo.choosingAndOpeningCourses.body':
      'Course Selector muestra el curso actual, los recientes, los Favorites y después los demás cursos, incluidos o locales; el curso actual no se repite entre ellos. Cada fila muestra la portada del curso o, si no tiene, su bandera. Cada fila tiene Course Info y Remove from my courses. Course Library permite volver a añadir cursos con el progreso conservado. Import Course vuelve directamente al estudio. Con Animations activadas, cambiar a otro curso muestra brevemente su bandera válida antes de Learner Panel; si no hay bandera declarada usa la bandera habitual del código del curso. Cada estudiante retoma la última Lesson válida o la primera. El control inferior de Lesson alterna Expanded, Collapse completed y Focused; Section selector sigue siendo la navegación entre Sections.',
  'appInfo.courseIdentityAndProgress.title': 'Identidad del curso y progreso',
  'appInfo.courseIdentityAndProgress.body':
      'Cada curso tiene un Course ID único e inmutable. Actualizar el mismo curso conserva el ID y el progreso. Al importar otro con ese ID puedes reemplazarlo o actualizarlo, crear una copia derivada con ID nuevo o cancelar. La copia puede registrar la fuente y su versión. Completados, Review, laureles y victorias de Language Duel se separan por Course ID. Language XP, streaks y días de estudio se comparten por lengua de estudio; Week XP suma todos los cursos y lenguas.',
  'appInfo.progressWeekXpAndGamification.title':
      'Progreso, Week XP y Gamification',
  'appInfo.progressWeekXpAndGamification.body':
      'Language XP, streak, Study Days y Status se guardan por estudiante y lengua de estudio. Profile > Statistics muestra Total Study Days y, por cada lengua, bandera, nombre, ID, Study Days, Current Streak y Max Streak. Los Rounds completados y laureles se guardan por Course ID. Week XP suma los XP de todos los cursos de la semana actual. Profile > Gamification incluye Weekly XP Target · All courses, Last Week XP · All courses y Local leaderboard · All courses. Last Week XP corresponde a la semana anterior completa; toca tu cifra para ver el desglose por curso. La clasificación local usa ese total semanal. Puedes dejar de participar sin borrar XP. Un Round o una Story sin ejercicios puntuados (solo tarjetas, portadas o líneas de diálogo) cuenta como completado pero no otorga XP ni Laurel. La primera vez que completas un Round, cada ejercicio que aciertas al primer intento también da una bonificación por dificultad: 1 XP por nivel de dificultad, de 1 (reconocer el significado) a 4 (escribir). Una breve explosión de confeti celebra alcanzar tu Weekly XP Target, ganar un Duel y superar un Round Test (alcanzado su umbral o, sin umbral, todas las respuestas correctas), salvo que las Animations estén desactivadas en Do Not Disturb o el dispositivo pida reducir el movimiento.',
  'appInfo.streakAndFreezeRule.title': 'Streak y pausa',
  'appInfo.streakAndFreezeRule.body':
      'El streak de una lengua sube cuando la estudias en un día nuevo. Si estudias otra lengua durante un día, el streak de la primera queda en pausa: no sube ni se reinicia. Un día completo sin estudiar ninguna lengua rompe los streaks activos.',
  'appInfo.daysStudied.title': 'Días de estudio',
  'appInfo.daysStudied.body':
      'Study Day es un día del calendario local en que completas estudio. Varios Rounds en el mismo día cuentan como uno. Total Study Days cuenta fechas distintas entre todas las lenguas; estudiar dos en un día solo suma un día.',
  'appInfo.laurelCrowns.title': 'Coronas de laurel',
  'appInfo.laurelCrowns.body':
      'Un Round gana una corona cuando completas un intento entero sin errores, desde el curso o Review. La corona permanece aunque después cometas errores. Al ganarla suena la victoria si los efectos de sonido están activados.',
  'appInfo.pathColours.title': 'Código de colores del camino',
  'appInfo.pathColours.enlarge': 'Ampliar la imagen',
  'appInfo.pathColours.body':
      'Cada Lesson tiene su propio color, uno de ocho que vuelven a empezar después de la Lesson 8; la imagen los muestra en el tema claro y en el oscuro. El círculo con el número de la Lesson es de su color, como los círculos de sus Rounds y de su Duel.\n• Un círculo claro con borde del color: un Round aún no completado (Learn).\n• Un círculo lleno: un Round completado; Completed se escribe en otro tono del color.\n• Un círculo verde con laurel: un Round Perfect, completado sin errores.\nLearn es siempre azul y Perfect siempre verde, sea cual sea el color de la Lesson.',
  'appInfo.pathColours.picture':
      'Los ocho colores de las Lessons en el tema claro y en el oscuro: un Round no completado, un Round completado y la palabra Completed.',
  'appInfo.audioSettings.title': 'Audio Settings',
  'appInfo.audioSettings.body':
      'Settings > Audio Settings ofrece Enable Audio Exercises, Text-to-speech, selector de voz TTS y Test Voice. Las dos opciones empiezan en Off por estudiante; la voz empieza en System. Test Voice lee solo el texto que escribas, con la lengua del curso seleccionado. Con audio en Off se omiten ejercicios MP3, TTS y Hybrid antes de preparar su fuente. Con audio en On, Text-to-speech controla TTS sin desactivar grabaciones válidas. Preview de autoría no escribe progreso ni usa estos ajustes. Completar solo la parte no sonora de un Round no concede la corona plena.',
  'appInfo.betaExpiry.title': 'Caducidad de la beta',
  'appInfo.betaExpiry.active':
      'Esta beta caduca el {expiryDate}. Después se bloquean los ejercicios y Review hasta instalar una beta nueva. El progreso, los cursos, sus cambios y los ajustes no se borran; Course Editor sigue disponible.',
  'appInfo.betaExpiry.inactive': 'Esta versión no tiene caducidad de beta.',
  'appInfo.status.title': 'Status',
  'appInfo.status.body':
      'Status se calcula por estudiante y lengua. Sus puntos suman XP, 40 por día del streak actual, 25 por Study Day, 15 por Round completado y 20 por laurel. Tu Status es el nivel más alto alcanzado. Su color aparece en la camiseta del avatar. Los niveles son Apprentice, Wanderer, Squire, Wordsmith, Knight, Lorekeeper, Language Wizard, Grand Master, Sage y Guru.',
  'appInfo.avatarAppearance.title': 'Aspecto del avatar',
  'appInfo.avatarAppearance.body':
      'Profile > Avatar Customization permite elegir piel y pelo. El color de la camiseta sigue automáticamente el color del Status actual de la lengua seleccionada; no es una preferencia aparte.',
  'appInfo.review.title': 'Review',
  'appInfo.review.body':
      'QQL recuerda hasta 50 Rounds recientes distintos por estudiante y Course ID. Review prioriza aquellos cuyo último intento tuvo más errores y, en caso de empate, los más antiguos. Repetir un Round actualiza ese número y puede dar un laurel permanente.',
  'appInfo.guidebooks.title': 'GuideBooks',
  'appInfo.guidebooks.body':
      'Cada Lesson tiene un GuideBook hecho de módulos breves: cada uno tiene frases de ejemplo (Sentences) y palabras y expresiones (Words & Expressions) con su traducción, algunas con una imagen, y un Overview breve. Es el primer elemento del recorrido de esa Lesson y solo se abre cuando lo seleccionas.',
  'appInfo.wordLookup.title': 'Word Lookup',
  'appInfo.wordLookup.body':
      'En una Round, las palabras del idioma que estudias que explica el GuideBook del curso llevan un ligero subrayado de puntos; toca una para ver su traducción, con su imagen y una breve nota sobre su sentido cuando las tiene, y, si viene de otra Lesson, esa Lesson. Solo algunos tipos de ejercicio tienen estas palabras. La tarjeta muestra una traducción posible, una ayuda que no siempre coincide con la respuesta del ejercicio. Cuando el GuideBook tiene una expresión entera, se muestra esa en lugar de la palabra sola; en una palabra que el GuideBook no tiene no pasa nada. Word Lookup funciona en todas las Rounds salvo las de tipo Test, y nunca en un Duel; no da XP ni cambia tu progreso. Solo está cuando el curso usa GuideBooks, y su autor puede desactivarlo.',
  'appInfo.languageDuels.title': 'Language Duels',
  'appInfo.languageDuels.body':
      'Cada Lesson tiene un Duel. El normal elige 25 ejercicios adecuados y empieza con cuatro vidas. Cada error cuesta una vida. Completa las 25 preguntas antes de perderlas todas para ganar y desbloquear la siguiente Lesson. Si faltan ejercicios adecuados, el Duel no está disponible.',
  'appInfo.sourceAndTargetLanguages.title': 'Lengua base y lengua de estudio',
  'appInfo.sourceAndTargetLanguages.body':
      'La lengua de estudio es la que aprendes; la lengua base se usa para explicaciones y traducciones. La mayoría de cursos de muestra parten del inglés; el curso de inglés parte del español.',
  'appInfo.exportAndImportLearnerData.title': 'Exportar e importar tus datos',
  'appInfo.exportAndImportLearnerData.body':
      'Profile > User Data > Export my data guarda un backup del perfil activo, con su progreso y preferencias, en {folderLearnerDataExports}. El nombre es automático; si ya existe, añade _2, _3, etc. Para importar, copia un backup compatible a {folderLearnerDataImports}/learner_import.json y elige Profile > User Data > Import my data. Los proyectos de Course Editor, Image Bank y Audio Packs son recursos aparte.',
  'appInfo.updates.title': 'Actualizaciones',
  'appInfo.updates.body':
      'Al final de Settings aparecen Version y Build antes de Update. Settings > Update muestra el repositorio público https://github.com/Quisquisnaut/QuisquisLingo, consulta a mano las GitHub Releases y puede comprobarlas al iniciar. La comprobación automática empieza activada. No envía datos del estudiante ni del curso y nunca descarga ni instala software. Si hay una versión más nueva, muestra información e instrucciones por plataforma en el orden Windows, macOS, Linux, Android, iOS y Web.',
  'appInfo.crashLogAndDiagnosticLog.title': 'Crash Log y Diagnostic Log',
  'appInfo.crashLogAndDiagnosticLog.body':
      'Settings > Debug ofrece ambos registros. Usa Crash Log para cierres inesperados. Para problemas sin cierre, reproduce el fallo si puedes y exporta Diagnostic Log justo después. Borrarlo antes es opcional; si el problema es intermitente, exporta primero. Quick Export guarda copias del Diagnostic Log y del Crash Log en {folderDiagnosticLogExports}; Settings > Debug también muestra dónde está el Crash Log activo. El diagnóstico de audio registra códigos y estados breves sin guardar el texto leído, las respuestas, el contenido de cursos ni rutas completas.',
  'appInfo.courseStudioAndCourseEditor.title': 'Course Studio y Course Editor',
  'appInfo.courseStudioAndCourseEditor.body':
      'Course Studio se abre desde Course Selector, no desde Settings. Gestiona los cursos: los oficiales permiten consulta, Fork según licencia, Audit y Export; los custom permiten Edit, Copy as New Course, Merge, Audit, Export y Delete según tus permisos. Fork conserva el origen; Copy as New Course inicia otro. Para las operaciones de la biblioteca, abre Course Studio Help. Para crear y modificar cursos, abre Editor Help desde una página de Course Editor.',
  'appInfo.courseContentAndAi.title': 'Contenido de cursos e IA',
  'appInfo.courseContentAndAi.body':
      'Los cursos de demostración incluidos (Demo en el título) son demostraciones generadas con IA y sin revisión; no son cursos fiables para estudiar. El contenido real de QuisquisLingo está pensado para ser escrito y revisado por personas. Esto no clasifica a otros cursos oficiales o custom.',
  'appInfo.creditsButton': 'App and image credits',
  'appInfo.title': 'Información de la app',
  'courseInfo.title': 'Course Info',
  'courseInfo.authorSupportMissing':
      'Este curso no incluye un enlace para apoyar a sus autores.',
  'courseInfo.authorSupportOpenFailed':
      'No se pudo abrir el enlace de apoyo a los autores.',
  'courseInfo.authorsContributors': 'Authors / Contributors: {value}',
  'courseInfo.notSpecified': 'No indicado',
  'courseInfo.notRecorded': 'No registrado',
  'courseInfo.contributors': 'Colaboradores',
  'courseInfo.illustrators': 'Ilustradores',
  'courseInfo.origin.bundledOfficial': 'Oficial incluido',
  'courseInfo.origin.publisherCourse': 'Publisher Course',
  'courseInfo.origin.customCourse': 'Custom Course',
  'courseInfo.origin.label': 'Origen: {value}',
  'courseInfo.publisher': 'Editor: {value}',
  'courseInfo.originalCourseCreated': 'Original Course Created: {value}',
  'courseInfo.lastVersionEditor': 'Last Version Editor: {value}',
  'courseInfo.modified': 'Modificado: {value}',
  'courseInfo.officialCourseVersion': 'Versión oficial del curso: {value}',
  'courseInfo.officialRelease': 'Publicación oficial: {value}',
  'courseInfo.distributionChannel': 'Canal de distribución: {value}',
  'courseInfo.publisherVerification': 'Verificación del editor: {value}',
  'courseInfo.verificationRequired':
      'Verification required. Se conservan el curso guardado y su progreso. Importa una versión verificada del editor para reactivarlo.',
  'courseInfo.signatureScope':
      'La firma cubre el JSON del curso. Los medios separados no quedan autenticados por esta firma.',
  'courseInfo.officialChecksum': 'Checksum oficial: {value}',
  'courseInfo.officialReadOnly': 'Official course - read only',
  'courseInfo.courseVersion': 'Versión del curso: {value}',
  'courseInfo.unconfirmed': 'Sin confirmar',
  'courseInfo.versionNotes': 'Notas de versión:\n{value}',
  'courseInfo.internalCourseData': 'Datos internos del curso',
  'courseInfo.enlargeImage': 'Ampliar la imagen del curso',
  'courseInfo.courseModel': 'Course Model: v{value}',
  'courseInfo.temporarySample.title': 'Private course',
  'courseInfo.temporarySample.body':
      'Este curso solo es visible en QQL para su Course Maintainer y los miembros de su Team asignado. Desactiva Private course en Course Info para mostrarlo a todos en este dispositivo.',
  'courseInfo.authorshipAndDescriptiveCredits':
      'Autoría y créditos descriptivos',
  'courseInfo.teamLeaderTooltip':
      'Esta información es solo descriptiva. Para asignar o cambiar Team Leader en QQL, usa Team Manager.',
  'courseInfo.languages': 'Lenguas',
  'courseInfo.learningLanguage': 'Lengua de estudio: {value}',
  'courseInfo.baseLanguage': 'Lengua base: {value}',
  'courseInfo.licenseRights': 'License / Rights',
  'courseInfo.license': 'License: {value}',
  'courseInfo.rightsHolder': 'Rights Holder: {value}',
  'courseInfo.derivativeWorks': 'Obras derivadas: {value}',
  'courseInfo.rightsHolderDisclaimer':
      'Rights Holder son datos legales descriptivos y no controlan los permisos de QQL.',
  'courseInfo.mediaCredits': 'Créditos de medios',
  'courseInfo.mediaCreditsDisclaimer':
      'Los créditos de medios son descriptivos y no controlan los permisos de QQL.',
  'courseInfo.source': 'Fuente: {value}',
  'courseInfo.courseDetails': 'Detalles del curso',
  'courseInfo.lessons': 'Lessons: {value}',
  'courseInfo.estimatedStudyTime': 'Tiempo estimado de estudio: {value} {unit}',
  'courseInfo.hour': 'hora',
  'courseInfo.hours': 'horas',
  'courseInfo.minimumAge': 'Edad mínima: {value}+',
  'courseInfo.keywords': 'Palabras clave: {value}',
  'courseInfo.requiresBuild':
      'Requiere QuisquisLingo Build {value} o posterior',
  'courseInfo.publisherContact': 'Contacto del editor',
  'courseInfo.website': 'Sitio web: {value}',
  'courseInfo.email': 'Correo electrónico: {value}',
  'courseInfo.buyACoffee': 'Buy a Coffee',
  'courseInfo.supportAuthors': 'Apoya a los autores de este curso.',
  'courseInfo.governance.title':
      'Responsabilidad del curso, Assigned Team y permisos',
  'courseInfo.governance.officialPublisher': 'Editor oficial: {value}',
  'courseInfo.governance.originalCreator': 'Original Course Creator: {value}',
  'courseInfo.governance.maintainer': 'Course Maintainer: {value}',
  'courseInfo.governance.assignedTeam': 'Assigned Team: {value}',
  'courseInfo.governance.teamLeaders': 'Team Leaders: {value}',
  'courseInfo.governance.teamMembers': 'Team Members: {value}',
  'courseInfo.governance.none': 'Ninguno',
  'courseInfo.governance.noneAvailable': 'Ninguno disponible',
  'courseInfo.governance.disclaimer':
      'El mantenimiento del Course y la gestión del Team son asuntos separados. El origen, los créditos y los derechos no conceden permisos de edición.',
  'courseInfo.fork.title': 'Origen de Fork',
  'courseInfo.fork.notRecorded': 'No registrado',
  'courseInfo.fork.fromCourseId': 'Forked From Course ID: {value}',
  'courseInfo.fork.sourceCourse': 'Curso de origen: {value}',
  'courseInfo.fork.sourceCourseVersion': 'Versión del curso de origen: {value}',
  'courseInfo.fork.sourcePublisher': 'Editor de origen: {value}',
  'courseInfo.fork.sourcePublisherId': 'ID del editor de origen: {value}',
  'courseInfo.fork.sourceAuthors': 'Autores de origen:\n{value}',
  'courseInfo.fork.sourceOfficialChecksum':
      'Checksum oficial de origen: {value}',
  'courseInfo.fork.createdBy': 'Fork Created By: {value}',
  'courseInfo.fork.createdDate': 'Fecha de creación de Fork: {value}',
  'courseInfo.fork.disclaimer':
      'El origen de Fork es inmutable. Rights Holder y los créditos son distintos de los permisos de QQL.',
  'courseInfo.fork.creatorUser': 'Usuario creador de Fork',
  'locale.label': 'Locale',
  'locale.english': 'English',
  'locale.italian': 'Italiano',
  'locale.spanish': 'Español',
  'allCoursesHelp.title': 'Cursos de este dispositivo',
  'allCoursesHelp.allCoursesPageTitle': 'All Courses — Ayuda',
  'allCoursesHelp.courseLibraryPageTitle': 'Course Library — Ayuda',
  'allCoursesHelp.intro1':
      'All Courses muestra todos los Courses instalados o guardados en este dispositivo QQL, incluso los que no están en tu biblioteca personal. Cada estudiante elige los suyos.',
  'allCoursesHelp.intro2':
      'Puedes importar un Course creado en otro dispositivo. Por ejemplo, un amigo puede enviarte el suyo o un editor puede distribuirte o venderte un Publisher Course. QQL solo importa el paquete; no vende ni licencia Courses.',
  'allCoursesHelp.intro3':
      'Si no tienes cursos disponibles para estudiar, Home mantiene Settings y All Courses. Puedes desbloquear Course Studio para tu perfil tocando Version diez veces en Settings. All Courses te permite volver a añadir cursos. No aparece ninguna bandera hasta que elijas un curso utilizable.',
  'allCoursesHelp.categories.title': 'Categorías',
  'allCoursesHelp.categories.body':
      'Favorites: accesos rápidos que también aparecen en sus secciones normales. Bundled Courses: incluidos con QQL. Publisher Courses: versiones instaladas de editores. My Local Courses: cursos custom creados por tu perfil. Other Local Courses: cursos custom de otro perfil o importados. Cada sección muestra su cantidad. Los títulos de Bundled Courses aparecen en negrita negra, Publisher Courses en púrpura y Custom Courses en naranja.',
  'allCoursesHelp.courseDetails.title': 'Datos del curso',
  'allCoursesHelp.courseDetails.body':
      'Cada fila muestra la portada o, si no hay, la bandera; también las lenguas, Version, Last edited, Maintainer y, si se declaró, Duration. Bundled y Publisher Courses muestran la versión publicada; los custom, su versión propia. Maintainer indica el perfil local responsable o el editor. Si el perfil no está en este dispositivo, se muestra su ID.',
  'allCoursesHelp.availability.title': 'Disponibilidad',
  'allCoursesHelp.availability.body':
      'Show unavailable empieza activado y muestra cursos Not published, con Verification required o con contenido Draft. Desactívalo para filtrarlos en ambas pestañas; la sección indica cuántos quedan visibles. Las etiquetas azules Draft, Unpublished y Verification required no vuelven utilizable ni verificado un curso. Solo los cursos Published pueden estudiarse. Los Publisher Courses también necesitan firma verificada.',
  'allCoursesHelp.sortingAndCompactView.title':
      'Orden y vistas de las secciones',
  'allCoursesHelp.sortingAndCompactView.body':
      'Sort by ordena cada sección por Title, Language, Maintainer, Most recent o Duration, sin mover las secciones. Most recent muestra primero la última edición; Duration, primero los cursos más cortos y al final los que no indican duración. El botón de cada sección pasa de Expanded a Compact y a Minimal, solo en esa sección: Compact oculta versión, fecha, Maintainer y Duration; Minimal oculta los cursos y solo muestra cuántos se ven y cuántos tiene la sección. QQL recuerda la vista de cada sección para cada estudiante, por separado en All Courses y Course Studio. Search filtra títulos y lenguas, incluso en Favorites. Sort by y Search duran mientras la página está abierta.',
  'allCoursesHelp.personalLibrary.title': 'Biblioteca personal',
  'allCoursesHelp.personalLibrary.body':
      'Add to my courses añade un curso instalado a Course Selector y Course Studio para tu perfil. No copia el curso ni da permiso de edición. Added · Remove y Remove from my courses lo quitan solo de tu biblioteca, con confirmación y opción de Reset my progress. Por defecto se conserva el progreso. Si lo reinicias, solo se borran los Rounds y Lessons completados, resultados Perfect, Duels ganados, GuideBooks leídos y entradas recientes de ese curso. Se conservan XP, Weekly XP, días de estudio, streak y backups; tampoco se resta el XP ganado. Otros estudiantes y el archivo compartido no cambian.',
  'allCoursesHelp.coursesInLearnerMode.title': 'Cursos en el modo de estudio',
  'allCoursesHelp.coursesInLearnerMode.body':
      'Hide in Learner mantiene el curso en tu biblioteca y Course Studio, pero lo quita de Course Selector. Unhide in Learner lo devuelve. No puedes ocultar el curso actual hasta cambiar a otro. Favorites son accesos propios de cada estudiante y no añaden cursos a la biblioteca. All Courses sigue mostrando los ocultos con Hidden in Learner para poder restaurarlos. Study en el menú de un curso lo añade a tu biblioteca si falta, lo convierte en el actual y abre la página del estudiante; Review hace lo mismo y abre la página Review, cuando ya completaste un Round.',
  'allCoursesHelp.importing.title': 'Importar cursos',
  'allCoursesHelp.importing.body':
      'Los Courses pueden transferirse como paquetes QQL. Los Custom Courses importados conservan sus reglas de propietario y origen. Los Publisher Courses siguen sujetos a verificación del editor.',
  'allCoursesHelp.removingPublisherCourse.title':
      'Quitar un Publisher Course del dispositivo',
  'allCoursesHelp.removingPublisherCourse.body':
      'Solo un Admin puede usar Remove Publisher Course from device desde el menú de Course Studio. Se bloquea si otro perfil incluye ese curso en su biblioteca. La eliminación física conserva progreso y backups de versión para una futura reinstalación.',
  'technical.courseModel.title': 'QuisquisLingo Course Model v12',
  'technical.courseModel.status.title': 'Estado',
  'technical.courseModel.status.body':
      'En desarrollo. QuisquisLingo usa formatVersion 12 como único Course Model nativo. Los formatos anteriores se rechazan sin migrarlos ni borrarlos. Cada Custom Course necesita un Original Course Creator inmutable y un Course Maintainer individual; Assigned Team es opcional y distinto.',
  'technical.courseModel.hierarchy.title': 'Jerarquía',
  'technical.courseModel.hierarchy.body':
      'Course > Lesson > GuideBook (módulos) + Round > Content. Cada Lesson tiene su GuideBook y Duel. Exercise es un tipo de Content, pero no el único permitido en un Round.',
  'technical.courseModel.content.title': 'Content',
  'technical.courseModel.content.body':
      'Los tipos actuales incluyen exercise, presentation, explanation, example, vocabulary, text y dialogue. Content tiene un ID estable y puede ser obligatorio para completar. Lesson, Round y Exercise llevan fechas UTC updatedAt obligatorias. Presentation Content puede ser interactivo sin resultado correcto/incorrecto.',
  'technical.courseModel.guidebook.title': 'GuideBook',
  'technical.courseModel.guidebook.body':
      'El GuideBook de cada Lesson es una lista ordenada de módulos (Build 266). Un módulo tiene un ID estable, un título, Sentences, Words & Expressions y un Overview; cada entrada tiene un ID estable, target, source, un context opcional de 40 caracteres como máximo y, solo en Words & Expressions, una imagen opcional (asset, sharedImageSource opcional, plural). Las entradas sirven al estudiante y son la fuente del vocabulario de la Review y de Word Lookup (solo Words & Expressions) y de la generación de Rounds Draft con sus sourceRefs.',
  'technical.courseModel.completionAndProgression.title':
      'Completado y progresión',
  'technical.courseModel.completionAndProgression.body':
      'required indica que el contenido es necesario para completar normalmente. Completado, corrección y desbloqueo son estados distintos. Completar una Lesson o ganar su Duel disponible puede desbloquear la siguiente sin marcar Content omitido como completado.',
  'technical.courseModel.languageDuel.title': 'Language Duel',
  'technical.courseModel.languageDuel.body':
      'La identidad de Duel pertenece a la Lesson. QQL elige 25 Exercises aptos y distintos y empieza con cuatro vidas. No hay puntuación ni umbral aparte. Si el conjunto real tiene menos de 25, ese Duel no está disponible; la Lesson sigue siendo válida.',
  'technical.courseModel.friendlyEditorTemplates.title':
      'Plantillas claras del Editor',
  'technical.courseModel.friendlyEditorTemplates.body':
      'El Editor usa nombres como Choose a picture, What do you hear?, Build the sentence y Match the sounds. editorTemplate es metadato opcional de autoría; el estudiante ejecuta la representación primitiva.',
  'technical.exercisePrimitives.title': 'Primitivas de Exercise',
  'technical.exercisePrimitives.status.title': 'Estado',
  'technical.exercisePrimitives.status.body':
      'Course Model v12 (Build 256). Cada ejercicio es una de las nueve primitivas, con opciones tipadas, elementos del prompt, items, targets, un layout inline, un modo de evaluación y un feedback opcional. Los presets son recetas sobre estos datos y nunca cambian cómo se juega o se evalúa un ejercicio; desde la Build 261 el título que el estudiante ve en un ejercicio es el nombre del preset que lo representa, reconocido por su contenido (nunca por el preset guardado), en la lengua del panel del estudiante. Una Story no muestra títulos, solo las instrucciones.',
  'technical.exercisePrimitives.exerciseAnatomy.title': 'Anatomía de Exercise',
  'technical.exercisePrimitives.exerciseAnatomy.body':
      'Exercise = primitive + options + prompt[] + items[] + targets[] + layout[] + evaluation + feedback, con hint opcional. Los elementos del prompt son text, audio o image con una función (primary, question, passage, situation, clue, context, dialogue_turn, picture, character; una presentation tiene las suyas: term, meaning, usage, intro, line, title, block; el editor canónico las ofrece en un menú y dice para qué sirve cada una) y los atributos language (source o target), playback (automatic o manual) y required. Un texto primary (si no, un clue) sin lengua es la Instruction or context: el estudiante lo ve en lugar de la línea de instrucciones estándar bajo el encabezado; con una lengua es material, por ejemplo un texto que traducir. Los items son lo que el estudiante elige, ordena, coloca o empareja; un item de Match tiene un lado. Los targets son los huecos, casillas o regiones que el estudiante rellena, y el layout los sitúa en el texto. Items y targets tienen IDs estables, nunca posiciones.',
  'technical.exercisePrimitives.primitives.title': 'Las nueve primitivas',
  'technical.exercisePrimitives.primitives.body':
      'select: el estudiante elige uno o varios items. input: el estudiante escribe texto o un número en un campo o en huecos inline. arrange: el estudiante ordena bloques o los arrastra a huecos. match: el estudiante empareja items de la izquierda y de la derecha. assign: el estudiante clasifica items en grupos, rellena casillas o los huecos de un texto tocando un item y luego su destino (los presets Sort into groups y Fill the slots; los huecos se crean en el editor canónico; regiones de una imagen y celdas de una cuadrícula en una versión futura). speak: el estudiante habla (solo definiciones). ink: el estudiante escribe a mano (solo definiciones). submit: el estudiante entrega una respuesta libre para autoevaluación o revisión (solo definiciones). presentation: una tarjeta o nota sin respuesta, como una Flashcard. La primitiva queda fija cuando el ejercicio existe.',
  'technical.exercisePrimitives.primitiveSelect.title': 'Select',
  'technical.exercisePrimitives.primitiveSelect.body':
      'El estudiante elige la respuesta correcta, o varias, entre los items: Choose the answer, Pick the translation, True or false, Listen and choose y la mayoría de los ejercicios con imágenes son Select. En el editor canónico: el Prompt contiene la pregunta (función question) y, si hace falta, una instrucción (primary), un texto que leer (passage) o una grabación (audio, primary); cada Item es una respuesta; la Evaluation exactItem marca el item correcto, exactSet varios (con selectionMode multiple). Las opciones eligen el layout (list, grid o huecos inline) y si los items se mezclan. La imagen muestra el ejemplo que escribe Fill with an example, tal como lo ve el estudiante.',
  'technical.exercisePrimitives.primitiveInput.title': 'Input',
  'technical.exercisePrimitives.primitiveInput.body':
      'El estudiante escribe la respuesta: en un campo (Type the translation, Type what you hear) o en los huecos de una frase (Type the missing word, Complete the text). En el editor canónico: el Prompt contiene la pregunta o la frase; la Evaluation enumera las respuestas aceptadas, una por línea, donde {a|b} acepta una u otra palabra, y las respuestas literales se quedan como están escritas; para los huecos, añade Targets, colócalos con el Layout y da las respuestas de cada target. Las opciones caseHandling, punctuationHandling, whitespaceHandling, accentHandling y typoTolerance deciden lo estricta que es la comparación. La imagen muestra el ejemplo que escribe Fill with an example, tal como lo ve el estudiante.',
  'technical.exercisePrimitives.primitiveArrange.title': 'Arrange',
  'technical.exercisePrimitives.primitiveArrange.body':
      'El estudiante ordena bloques: palabras en una frase (Word order, Build the translation), letras en una palabra (Spell the word, joiner none), líneas en un texto, o bloques en los huecos de una frase. En el editor canónico: cada Item es un bloque; un bloque que queda fuera del orden correcto es un distractor (dos como máximo); la Evaluation contiene uno o varios órdenes correctos, cada uno con el texto de la respuesta y los IDs de los items en orden. La imagen muestra el ejemplo que escribe Fill with an example, tal como lo ve el estudiante.',
  'technical.exercisePrimitives.primitiveMatch.title': 'Match',
  'technical.exercisePrimitives.primitiveMatch.body':
      'El estudiante empareja cada item de la izquierda con uno de la derecha: palabras y traducciones (Match the words), sonidos y palabras, imágenes y palabras. En el editor canónico: cada Item tiene un lado, Left o Right; la Evaluation enumera los pares, un item Left y su item Right. Las opciones pueden mezclar uno u otro lado. La imagen muestra el ejemplo que escribe Fill with an example, tal como lo ve el estudiante.',
  'technical.exercisePrimitives.primitiveAssign.title': 'Assign',
  'technical.exercisePrimitives.primitiveAssign.body':
      'El estudiante coloca los items en su sitio, tocando un item y luego su destino: en grupos (Sort into groups), en casillas (Fill the slots) o en los huecos de un texto. En el editor canónico: la opción targetMode dice qué son los targets (categories, slots o gaps); cada Target es un grupo, una casilla o un hueco, y el Layout pone los huecos en el texto; los Items son las palabras que colocar; la Evaluation dice qué IDs de items van en cada target. Las regiones de una imagen y las celdas de una cuadrícula llegarán en una versión futura. La imagen muestra el ejemplo que escribe Fill with an example, tal como lo ve el estudiante.',
  'technical.exercisePrimitives.primitiveSpeak.title': 'Speak',
  'technical.exercisePrimitives.primitiveSpeak.body':
      'El estudiante dice algo en voz alta, por ejemplo un saludo. El Prompt contiene qué decir. Los ejercicios Speak se guardan y se comprueban, pero esta versión no puede jugarlos: en los Rounds el estudiante los salta, y una Story o una vista previa muestran en su lugar la tarjeta de la imagen.',
  'technical.exercisePrimitives.primitiveInk.title': 'Ink',
  'technical.exercisePrimitives.primitiveInk.body':
      'El estudiante escribe a mano, por ejemplo repasando una letra. El Prompt contiene qué escribir. Los ejercicios Ink se guardan y se comprueban, pero esta versión no puede jugarlos: en los Rounds el estudiante los salta, y una Story o una vista previa muestran en su lugar la tarjeta de la imagen.',
  'technical.exercisePrimitives.primitiveSubmit.title': 'Submit',
  'technical.exercisePrimitives.primitiveSubmit.body':
      'El estudiante entrega una respuesta libre, por ejemplo una grabación o un texto, para comprobarla solo o para que la revisen. El Prompt contiene la tarea y la opción submissionType dice qué se entrega. Los ejercicios Submit se guardan y se comprueban, pero esta versión no puede jugarlos: en los Rounds el estudiante los salta, y una Story o una vista previa muestran en su lugar la tarjeta de la imagen.',
  'technical.exercisePrimitives.primitivePresentation.title': 'Presentation',
  'technical.exercisePrimitives.primitivePresentation.body':
      'Nada que responder: el estudiante lee una tarjeta y sigue. Una Flashcard tiene Texts con las funciones term y meaning, usage y usage_translation para un ejemplo, y un elemento audio con la función audio para la lectura en voz alta; los presets Before you start, Dialogue line, Story cover y Page también son presentations, con sus propias funciones (intro, line, title, block). La opción completionMode decide cómo sigue el estudiante. Una presentation no da XP y nunca impide un Round perfecto. La imagen muestra el ejemplo que escribe Fill with an example, tal como lo ve el estudiante.',
  'technical.exercisePrimitives.primitiveOptions.title':
      'Opciones de las primitivas',
  'technical.exercisePrimitives.primitiveOptions.body':
      'Las opciones son tipadas y pertenecen a una primitiva: selectionMode, selectionTarget, minimumSelections, maximumSelections, itemReuse, layout, evaluationTiming y shuffleItems para select; inputMode, cardinality, caseHandling, punctuationHandling, whitespaceHandling, accentHandling y typoTolerance para input; placementMode, unusedItems y joiner para arrange; relationship, interactionStyle, shuffleLeft y shuffleRight para match; completionMode, navigation y mediaPlayback para presentation. El JSON del Course guarda solo los valores definidos; una opción omitida vale el valor predeterminado del registro. El registro de capacidades enumera cada valor permitido, las opciones obligatorias y las combinaciones que rechaza; una opción desconocida o un valor no permitido es un error de formato y nunca se corrige en silencio.',
  'technical.exercisePrimitives.layouts.title': 'Layouts',
  'technical.exercisePrimitives.layouts.body':
      'list y grid muestran los items como opciones; inline coloca los items elegidos en huecos del texto. field e inlineGaps son respuestas escritas: un campo, o un campo por hueco. sequence pone los bloques ordenados en fila e inlineGaps los arrastra a huecos. El Match dropdown empareja cada item de la izquierda con uno de la derecha. El layout inline es una secuencia de trozos de texto y huecos target; un target puede revelar su primera letra, como hace Type the missing word.',
  'technical.exercisePrimitives.evaluationModes.title': 'Modos de evaluación',
  'technical.exercisePrimitives.evaluationModes.body':
      'El modo de evaluación dice cómo se comprueba la respuesta y qué datos de respuesta se aplican: exactItem y exactSet (IDs de los items correctos); exactText, acceptedTexts y expression (answers con variantes {a|b}, literalAnswers que nunca se expanden, o targetAnswers por hueco); regex (pattern); numericExact, numericRange y numericTolerance; exactOrder y acceptedOrders (correctOrders con IDs de items); gapAssignments y exactAssignments (assignments por target); exactRelations (relations entre IDs de la izquierda y de la derecha); acceptedTargets; none para presentaciones. La normalización de input viene de las opciones, no de la evaluación. La tabla de soporte del runtime decide qué combinaciones puede jugar esta versión; un ejercicio legible pero no jugable permanece en el Course tal cual.',
  'technical.exercisePrimitives.promptAndItemMedia.title':
      'Medios de Prompt e Item',
  'technical.exercisePrimitives.promptAndItemMedia.body':
      'Los elementos text, audio e image llevan funciones y atributos. Un audio con required: true convierte el ejercicio en ejercicio de audio, que Audio Exercises Off retira de Rounds y Duels; un audio con required: false es opcional, como el botón de lectura de Pick the translation. Una imagen con la función character es una muestra de Recognize characters; cualquier otra imagen es una ilustración. Los medios de los items siguen las mismas reglas.',
  'technical.exercisePrimitives.presentationContent.title':
      'Presentation Content',
  'technical.exercisePrimitives.presentationContent.body':
      'Una Flashcard o una nota es un ejercicio de primitiva presentation con modo de evaluación none y un completionMode (continue, acknowledge o understoodReview). No da XP, no cuenta como correcta ni como incorrecta y nunca impide un Round perfecto.',
  'technical.exercisePrimitives.presets.title': 'Presets como recetas',
  'technical.exercisePrimitives.presets.body':
      'Un preset es una receta: su formulario pide pocos campos y escribe datos canónicos ordinarios. El ejercicio lleva el preset solo como metadato de autoría (presetId); el runtime del estudiante, el Duel y la Audit leen los datos canónicos. En cada guardado QQL comprueba si el preset sigue representando exactamente el ejercicio. Si lo hace otro preset, se nombra ese; si ninguno lo hace, el ejercicio queda sin preset y se abre en el editor canónico. Los demás metadatos de autoría se eliminan en cuanto cambia el contenido.',
  'technical.exercisePrimitives.canonicalEditor.title': 'El editor canónico',
  'technical.exercisePrimitives.canonicalEditor.body':
      'El editor canónico (New Exercise › Canonical editor) muestra cada campo canónico de cualquier primitiva con los valores que permite el registro de capacidades: Primitive, Options, Prompt, Items, Targets, Layout, Evaluation por modo, Feedback y hint. Indica si esta versión puede jugar el ejercicio, rechaza las combinaciones que rechaza el registro, muestra la vista previa con el runtime del estudiante y guarda como un formulario de preset (Save as draft, o Save con la Audit). Un ejercicio que ningún preset representa se abre ahí. Role es un menú de las funciones que QQL lee para el tipo del elemento, con para qué sirve cada una; una función guardada fuera de la lista se mantiene y se señala. Un ejercicio nuevo tiene Fill with an example y Clear all (vuelve a los valores predeterminados de la primitiva); si cambias la primitiva con campos ya rellenados, un mensaje te pide que los revises. La primera vez que una primitiva se abre en un curso, una ventana la explica (una vez por usuario y curso; Show one-time notices again la hace volver), y el botón Help abre su sección en esta página.',
  'technical.jsonStructure.title': 'Estructura de datos JSON',
  'technical.jsonStructure.status.title': 'Estado',
  'technical.jsonStructure.status.body':
      'En desarrollo. QuisquisLingo escribe formatVersion: 12.',
  'technical.jsonStructure.root.title': 'Raíz',
  'technical.jsonStructure.root.body':
      'La raíz contiene formatVersion, metadatos de Course y lessons[]. Los cursos incluidos y custom usan el modelo nativo v12; uno fusionado también lleva mergeProvenance. Un custom exige originalCourseCreator inmutable y un maintainer individual. assignedTeamId es opcional; la lista de miembros del Team vive fuera del Course JSON. No se leen ni migran modelos anteriores.',
  'technical.jsonStructure.guidebook.title': 'GuideBook',
  'technical.jsonStructure.guidebook.body':
      'Cada Lesson contiene un guidebook con publicationState opcional y guidebook.modules[]: cada módulo {id, title, sentences[], words[], overview}, cada entrada {id, target, source, context?, picture?}, donde picture es {asset, sharedImageSource?, plural?} y solo está en words. Un target puede marcar palabras opcionales con {…}; no se admite otra sintaxis de respuestas. Los antiguos guidebook.content e insights se rechazan. Sin publicationState se considera Published; Draft excluye todo el GuideBook de la entrega al estudiante. Su Internal ID visible deriva de lessonId con el sufijo _guidebook; los ID de módulos y entradas son estables y únicos en el curso. useGuidebook cambia el acceso del estudiante y las reglas del Audit sobre el GuideBook, nunca el contenido guardado.',
  'technical.jsonStructure.lessonAndRound.title': 'Lesson y Round',
  'technical.jsonStructure.lessonAndRound.body':
      'Course, Lesson, GuideBook, Round y Exercise tienen estado Draft/Published. Lesson, Round y Exercise exigen fechas UTC updatedAt. Course guarda Lesson label and numbering, Round label and numbering y los iconos custom de Lesson. La Lesson contiene lessonId, un título obligatorio, Section opcional, tema, guidebook, rounds[] e identidad de Duel. Un Round puede guardar focusModuleId y supportingModuleIds, módulos del GuideBook de su Lesson (el que practica y los anteriores que repasa); solo los lee Open GuideBook. El título de Round es opcional; sin él, el tipo sigue dándole un nombre sin cambiar el ID.',
  'technical.jsonStructure.exerciseContent.title': 'Content de Exercise',
  'technical.jsonStructure.exerciseContent.body':
      'Exercise Content guarda editorTemplate y exercise.prompt[], exercise.interaction y exercise.evaluation. La corrección usa IDs estables de Item, no posiciones visibles. Build the translation guarda uno o más correctOrders literales con texto e IDs ordenados; correctOrder antiguo se rechaza.',
  'technical.jsonStructure.duel.title': 'Duel',
  'technical.jsonStructure.duel.body':
      'La Lesson guarda un ID y título estables de Duel. Su disponibilidad se calcula al ejecutar según Exercises aptos y distintos, no se serializa ni depende de la cantidad de Rounds. createDuels y useGuidebook empiezan en true y solo se escriben si son false. sectionNames conserva nombres no vacíos; worldFlagId referencia el SVG oficial incluido y se omite si está vacío.',
  'technical.jsonStructure.compatibility.title': 'Compatibilidad',
  'technical.jsonStructure.compatibility.body':
      'Los cursos incluidos y custom usan Course Model v12. Los formatos anteriores no se leen, migran, convierten ni borran. Créditos, origen y Rights Holder nunca conceden permisos ni implican Assigned Team.',
  'imageLibraryHelp.title': 'Ayuda de la biblioteca de imágenes',
  'imageLibraryHelp.saving.title': 'Guardar los cambios',
  'imageLibraryHelp.saving.paragraph1':
      'En la Image Library de un Course, los cambios se conservan mientras los haces y se aplican al salir de la pantalla, así que no hay botón Save. Se escriben en el Course solo cuando confirmas los cambios del Course al salir del Course Editor. Si cancelas el Course se descartan, y las imágenes añadidas en esa sesión se quitan de nuevo.',
  'imageLibraryHelp.saving.paragraph2':
      'Shared Images, la biblioteca de este dispositivo que gestionan los Admin, guarda cada cambio al instante.',
  'imageLibraryHelp.finding.title': 'Encontrar una imagen',
  'imageLibraryHelp.finding.paragraph1':
      'Escribe en Search: busca en nombres, etiquetas, Local words y categorías, y encuentra toda palabra que contenga lo que escribes. Singular y plural cuentan como uno, así que “dogs” también encuentra las imágenes de perros. Con Search all marcado (por defecto) busca en todas las categorías; desmárcalo para buscar solo en la categoría que estás viendo.',
  'imageLibraryHelp.finding.paragraph2':
      'Las categorías están sobre las imágenes. Las categorías afines están reunidas en grupos: People, Food & drink, Body & health, Home & things, Places & travel, Numbers & time, Language & grammar, Society & culture, History & stories, Free time y Nature & animals. Un grupo muestra todas sus imágenes y abre una segunda fila con sus categorías (el primer chip, “all …”, vuelve al grupo entero), como hace Characters con las escrituras, la puntuación, los signos de moneda y de matemáticas y las letras de bloques de juguete. Cada imagen conserva su única categoría: los grupos solo las reúnen. Escribir en Search el nombre entero de un grupo, por ejemplo “food & drink” o “food and drink”, encuentra sus imágenes. Una categoría muestra también las imágenes que llevan su nombre como etiqueta: Restaurant (en Food & drink) muestra sus imágenes y toda imagen con la etiqueta “restaurant”, así que una imagen puede aparecer en más de una categoría.',
  'imageLibraryHelp.finding.paragraph3':
      'En la vista grande de una imagen, la categoría y cada etiqueta son enlaces. Una etiqueta muestra solo las imágenes que la llevan, en singular o en plural, o que se llaman así, en todas las categorías, bajo un chip Tag; la categoría del mismo nombre cuenta como esa etiqueta. Quita el chip o elige una categoría para volver.',
  'imageLibraryHelp.finding.paragraph4':
      'El número a la derecha de la fila de insignias indica cuántas imágenes se muestran, según la categoría, la etiqueta, la búsqueda y la insignia que elegiste.',
  'imageLibraryHelp.badges.title': 'Insignias',
  'imageLibraryHelp.badges.paragraph1':
      'QQL marca las imágenes que trae la app; DEVICE las que un Admin añadió a este dispositivo; COURSE una imagen guardada en este Course; IN USE una imagen que el Course usa. La fila de insignias filtra por ellas.',
  'imageLibraryHelp.badges.paragraph2':
      'Una imagen DEVICE usada en un Course se copia en el Course y viaja en su ZIP; las imágenes QQL forman parte de la app en todos los dispositivos y no entran en el ZIP.',
  'imageLibraryHelp.details.title': 'Los detalles de una imagen',
  'imageLibraryHelp.details.paragraph1':
      'Abre una imagen a tamaño completo y pasa el ratón por encima en un ordenador, o mantenla pulsada en un teléfono, para ver el nombre del archivo, el tamaño, las dimensiones, el formato, la fecha en que se añadió, el Image Bank y la atribución.',
  'deviceAdminHelp.title': 'Ayuda de Advanced (Admin)',
  'deviceAdminHelp.whatThisPageIs.title': 'Qué es esta página',
  'deviceAdminHelp.whatThisPageIs.paragraph1':
      'Advanced (Admin) reúne las funciones de Admin de esta instalación de QQL. Solo afecta a este dispositivo: QQL no tiene cuenta en línea.',
  'deviceAdminHelp.whatThisPageIs.paragraph2':
      'Estas funciones siguen disponibles donde estaban antes. Solo los Admin pueden abrir esta página; los demás estudiantes la ven en gris en Settings, con una descripción emergente de lo que contiene.',
  'deviceAdminHelp.whoIsAnAdmin.title': 'Quién es Admin',
  'deviceAdminHelp.whoIsAnAdmin.paragraph1':
      'El primer estudiante creado en el dispositivo es Admin. QQL siempre mantiene al menos uno. Un Admin puede nombrar a otros y renunciar a su función si queda otro.',
  'deviceAdminHelp.whatAdminsCanDo.title': 'Qué pueden hacer los Admin',
  'deviceAdminHelp.whatAdminsCanDo.bullet1': 'Nombrar Admin a otro estudiante.',
  'deviceAdminHelp.whatAdminsCanDo.bullet2':
      'Eliminar un estudiante con su progreso y ajustes locales, respetando los límites indicados abajo.',
  'deviceAdminHelp.whatAdminsCanDo.bullet3':
      'Restablecer el PIN de otro estudiante. Se borra el PIN para que elija uno nuevo; hasta entonces cualquiera puede abrir ese perfil.',
  'deviceAdminHelp.whatAdminsCanDo.bullet4':
      'Cambiar el nombre del dispositivo QQL mostrado en Learner Profiles.',
  'deviceAdminHelp.whatAdminsCanDo.bullet5':
      'Elegir si QQL pregunta quién estudia al iniciar.',
  'deviceAdminHelp.whatAdminsCanDo.bullet6':
      'Administrar Shared Image Library y sus metadatos. Solo los Admin pueden modificar esa biblioteca común. Quien edite un curso puede usar Import custom image para su propio Exercise sin añadir la imagen a la biblioteca compartida.',
  'deviceAdminHelp.whatAdminsCanDo.bullet7':
      'Usar las opciones Reset después de crear un PIN de Admin y escribirlo en cada operación.',
  'deviceAdminHelp.whatAdminsCannotDo.title': 'Qué no pueden hacer los Admin',
  'deviceAdminHelp.whatAdminsCannotDo.bullet1':
      'Eliminar al único Admin o dejar el cargo si no queda otro. Nombra primero a otra persona o usa Wipe out everything.',
  'deviceAdminHelp.whatAdminsCannotDo.bullet2':
      'Ver un PIN. Se guarda de forma que ni QQL puede leerlo; solo se puede restablecer.',
  'deviceAdminHelp.whatAdminsCannotDo.bullet3':
      'Restablecer su propio PIN desde Learner Profiles. Debe hacerlo otro Admin.',
  'deviceAdminHelp.whatAdminsCannotDo.bullet4':
      'Hacer un Reset sin PIN. Cada operación vuelve a pedirlo.',
  'deviceAdminHelp.whatAdminsCannotDo.bullet5':
      'Adquirir propiedad de cursos. Ser Admin no permite editar ni borrar el curso de otra persona; se requieren derechos como Maintainer o miembro de Assigned Team.',
  'deviceAdminHelp.whatAdminsCannotDo.bullet6':
      'Eliminar a quien mantiene un curso o es el único Team Leader. Transfiere antes el cargo o asciende a otro Team Leader.',
  'deviceAdminHelp.whatAdminsCannotDo.bullet7':
      'Editar o borrar cursos oficiales incluidos. Son de solo lectura para todos; Fork depende de la licencia.',
  'deviceAdminHelp.whatAdminsCannotDo.bullet8':
      'Administrar Teams. Sus líderes y miembros lo hacen desde Course Studio.',
  'deviceAdminHelp.whatAdminsCannotDo.bullet9':
      'Actuar en otros dispositivos. El permiso de Admin solo vale en esta instalación.',
  'deviceAdminHelp.whatAdminsCannotDo.bullet10':
      'Deshacer un Reset o una eliminación. Los datos solo vuelven desde un backup anterior.',
  'deviceAdminHelp.inventory.title': 'Inventory',
  'deviceAdminHelp.inventory.paragraph1':
      'Inventory muestra lo que QQL ha guardado por acciones de los usuarios para que sepas qué borraría un Reset y dónde están los archivos. Muestra ruta, tamaño, última modificación y, cuando se conoce, el estudiante propietario.',
  'deviceAdminHelp.inventory.bullet1':
      'Estudiantes y cursos custom están dentro de los ajustes de QQL y no tienen ruta propia. Cada curso muestra Maintainer o creador.',
  'deviceAdminHelp.inventory.bullet2':
      'Export: cursos exportados, copias de estudiantes, User Recovery Keys e informes de Audit. Backups: los Course Backups que Course Editor crea automáticamente antes de guardar cambios, que muestra Version History.',
  'deviceAdminHelp.inventory.bullet3':
      'Import y ToBeMerged: archivos que copiaste desde fuera de QQL. Las carpetas de versiones anteriores (Imports, Exports, Merges) aparecen en una sección aparte; QQL ya no las lee.',
  'deviceAdminHelp.inventory.bullet4':
      'Imágenes, Image Banks y MP3 importados: copias guardadas por QQL. El audio indica su curso.',
  'deviceAdminHelp.inventory.bullet5':
      'Logs: las copias del Crash Log y del Diagnostic Log guardadas con Quick Export. El Crash Log activo y el marcador de sesión son privados de QQL y aparecen en una sección aparte.',
  'deviceAdminHelp.inventory.bullet6':
      'Otros archivos en la carpeta de QQL: los añadidos desde el sistema operativo que QQL no creó ni usa.',
  'deviceAdminHelp.inventory.bullet7':
      'No aparecen los medios incluidos con la app. En listas muy grandes se muestran los 500 archivos más recientes por sección.',
  'deviceAdminHelp.inventory.bullet8':
      'Delete, Forget y Open folder: cada elemento tiene Delete (un archivo, un estudiante, un Curso, un Image Bank) o Forget (un dato de los ajustes de QQL: un Favorito, una marca de Curso recibido, un editor recordado) donde corresponde, y Open folder en Windows, macOS y Linux. Cada Delete y Forget dice qué elimina, pide el PIN del admin y sigue las mismas reglas que el resto de QQL: no se pueden eliminar el único admin ni un estudiante que mantiene un Curso, un Curso solo su Maintainer o su Team (uno que esta versión no puede abrir también un admin), los medios de un Curso solo cuando ningún Curso guardado los usa, y el Crash Log en uso se queda.',
  'deviceAdminHelp.qqlTools.title': 'QQL-Tools',
  'deviceAdminHelp.qqlTools.paragraph1':
      'QQL-Tools es un proyecto complementario opcional que valida de forma independiente archivos Course JSON y paquetes ZIP de QQL. Sus resultados no sustituyen Course Audit, la validación de importaciones ni los controles de seguridad de QQL.',
  'deviceAdminHelp.qqlTools.paragraph2':
      'En Advanced (Admin), un Admin usa Browse... para configurar el ejecutable QQL-Tools una vez por dispositivo; Test lo comprueba y Clear borra la configuración. Validate with QQL-Tools... se ejecuta en segundo plano mientras QQL permanece abierto. No modifica ni importa el Course seleccionado. Not available on mobile devices.',
  'deviceAdminHelp.updates.title': 'Updates',
  'deviceAdminHelp.updates.paragraph1':
      'Update abre la misma página que Settings > Update: comprueba GitHub y muestra instrucciones de instalación. Solo un Admin puede cambiar Check automatically at startup porque afecta a todo el dispositivo.',
  'deviceAdminHelp.updates.paragraph2':
      'Si aparece una versión nueva al iniciar, cada estudiante recibe un aviso como máximo una vez al día. Not today aplaza el suyo hasta el día siguiente; los demás estudiantes siguen recibiendo el suyo.',
  'deviceAdminHelp.askWhoIsLearningAtStartup.title':
      'Ask who is learning at startup',
  'deviceAdminHelp.askWhoIsLearningAtStartup.paragraph1':
      'Off (inicial): QQL abre el último perfil usado. Conviene si una persona usa el dispositivo.',
  'deviceAdminHelp.askWhoIsLearningAtStartup.paragraph2':
      'On: al iniciar aparece la lista de estudiantes y cada uno elige su perfil. Conviene en dispositivos compartidos. No afecta si solo hay un estudiante; quien tenga PIN debe escribirlo.',
  'deviceAdminHelp.resetOptions.title': 'Opciones de Reset',
  'deviceAdminHelp.resetOptions.paragraph1':
      'Reset borra datos definitivamente. Su sección está bloqueada hasta crear tu PIN de cuatro cifras. Cada operación muestra las cantidades reales, ofrece hacer backup y pide el PIN antes de borrar. Remove imported media y Wipe out everything permiten elegir qué borrar. La eliminación total exige escribir NUKE EVERYTHING exactamente antes del PIN.',
  'deviceAdminHelp.resetOptions.bullet1':
      'Reset learner progress: borra XP, streaks y Lessons completadas de todos. Conserva estudiantes, PIN, ajustes y cursos.',
  'deviceAdminHelp.resetOptions.bullet2':
      'Remove all learners except admins: elimina perfiles no Admin y sus datos; quita la lista de Team si nombra a alguno. Se rechaza mientras alguno sea Maintainer de un Course: cambia antes el Course Maintainer o borra el Course.',
  'deviceAdminHelp.resetOptions.bullet3':
      'Remove imported media: elige imágenes, MP3 o ambos; al principio no hay nada marcado. Solo borra copias creadas por QQL. Los medios incluidos con la app siguen y los originales externos no se tocan. Las etiquetas y categorías de imágenes compartidas vuelven a sus valores iniciales.',
  'deviceAdminHelp.resetOptions.bullet4':
      'Remove custom courses: borra cursos custom e instalados, Teams y todos los medios importados. También borra los Private course de otros estudiantes, que no ves; la confirmación los cuenta. Conserva estudiantes.',
  'deviceAdminHelp.resetOptions.bullet5':
      'Wipe out everything: devuelve QQL al estado de una instalación nueva, incluidos estudiantes y Admin. Puedes conservar la carpeta Export, la carpeta Logs, las carpetas Import y ToBeMerged y la carpeta Backups; todas vienen marcadas para conservarse. Backups contiene los Course Backups automáticos.',
  'deviceAdminHelp.beforeResetBackups.title': 'Backups antes de Reset',
  'deviceAdminHelp.beforeResetBackups.paragraph1':
      'Profile > User Data exporta solo el perfil activo. Un Admin no puede exportar los datos de otros: pídeles que hagan su backup antes de un Reset que les afecte. Los cursos se exportan uno a uno desde Course Studio. Las exportaciones quedan en {folderExport}, que Wipe out everything conserva salvo que la desmarques.',
  'deviceAdminHelp.forgottenPin.title': 'PIN olvidado',
  'deviceAdminHelp.forgottenPin.paragraph1':
      'Otro Admin puede restablecer tu PIN desde Learner Profiles. Si eres el único Admin y lo olvidas, no podrás recuperar el acceso al perfil ni usar Reset. Elige un PIN que recuerdes y considera nombrar a otra persona Admin.',
  'debugHelp.title': 'Ayuda de Debug',
  'debugHelp.crashLog.title': 'Crash Log',
  'debugHelp.crashLog.body':
      'Esta beta guarda automáticamente un Crash Log local para investigar cierres y problemas técnicos graves. Si QQL se cierra de forma inesperada, vuelve a abrirlo y envía el archivo completo con una breve descripción de lo que pulsaste justo antes; una captura de pantalla no basta. El Crash Log activo está en el almacenamiento privado de QQL; Settings > Debug muestra dónde. Quick Export guarda una copia llamada QQL_crash_log.txt en {folderLogs}, sustituyendo la anterior; Save log copy as… te deja elegir dónde guardarla y, en los teléfonos, Share la envía directamente. El registro contiene datos técnicos del sistema, inicios de sesión, errores no capturados y trazas. No está pensado para guardar nombres de estudiantes, respuestas o contenido de cursos. Si se borra, QQL lo vuelve a crear al iniciar o escribir otro fallo.\n\nSave&Open (Windows, macOS, Linux), bajo los iconos, guarda una copia nueva en {folderLogs} y abre esa carpeta, para adjuntar el archivo a un informe enseguida.',
  'debugHelp.diagnosticLog.title': 'Diagnostic Log',
  'debugHelp.diagnosticLog.body':
      'Para problemas que no cierran QQL, como audio, TTS, Recorded MP3 o reproducción inesperada, reproduce el fallo si puedes y exporta Diagnostic Log poco después. Puedes borrarlo antes para aislar un problema repetible, pero no es obligatorio. Si el fallo es intermitente, exporta el registro actual antes de borrarlo.\n\nDesde la Build 266 también registra cada error que nada más capturó (una entrada breve; el informe completo está en el Crash Log) y cada Curso guardado que esta versión no puede abrir (una vez por sesión, con el nombre del archivo y el motivo). Save&Open (Windows, macOS, Linux), bajo los iconos, guarda una copia nueva en {folderLogs} y abre esa carpeta.',
  'debugHelp.privacy.title': 'Privacidad',
  'debugHelp.privacy.body':
      'El diagnóstico de audio del estudiante está diseñado para no guardar texto hablado, respuestas, contenido de cursos ni rutas completas de archivos personales.',
  'publisherSigningHelp.title': 'Publisher signing and approval',
  'publisherSigningHelp.status.title':
      'Estado: verificación de firmas implementada',
  'publisherSigningHelp.status.body':
      r'''QQL verifica firmas Ed25519 al importar Publisher Courses, tanto con Quick Import como desde el diálogo del sistema. La comprobación se repite antes de instalar. Se rechazan firmas ausentes, inválidas, desconocidas o revocadas. El registro normal aún no contiene editores externos aprobados; Dummy solo se usa en builds de prueba activadas expresamente. Desde Build 262 el registro tiene un lugar para QuisquisLingo Courses (com.quisquislingo, key ID qqlc-2026-1), el editor de los cursos del propietario; su clave pública sigue vacía, así que la app aún no confía en ninguno de sus cursos.

La aprobación es un proceso manual del propietario de QQL. Este mantiene las claves públicas en lib/services/trusted_publishers.dart y distribuye los cambios con una actualización. No hay portal de aprobación ni botón de firma en la app. La firma se hace fuera de QQL con una herramienta de desarrollo y OpenSSL.

Course Model usa v12; los Publisher Courses v11 requieren tools/convert_course_to_v12.dart y una firma nueva. El protocolo es qql-ed25519-v1.''',
  'publisherSigningHelp.rolesAndTools.title': '1. Funciones y herramientas',
  'publisherSigningHelp.rolesAndTools.body':
      r'''El editor crea y protege su par de claves Ed25519, pide aprobación y firma sus versiones. El propietario de QQL no recibe la clave privada ni firma cada curso. Comprueba por separado la identidad del editor y la posesión de la clave, asigna publisherId y registra la clave pública en la app.

Necesitas OpenSSL 3.x mantenido, terminal, editor de texto plano, gestor de contraseñas, backup cifrado fuera de línea y un canal de comunicación verificado. Comprueba OpenSSL con openssl version. En PowerShell, una ruta con espacios se invoca como & 'FULL PATH TO openssl.exe'. Para firmar cursos necesitas también este repositorio, un Dart SDK compatible y tools/sign_course.dart; ejecuta flutter pub get antes del primer uso. OpenSSL no debe firmar JSON arbitrario: la herramienta QQL prepara los bytes exactos. User Recovery Key no está relacionada con estas claves.

Usa una carpeta privada por editor, fuera de Git y de carpetas compartidas o de medios de QQL. Detente ante cada error y emplea nombres de salida nuevos; nunca sobrescribas claves.''',
  'publisherSigningHelp.createAndProtectKey.title':
      '2. Editor: crear y proteger la clave',
  'publisherSigningHelp.createAndProtectKey.body':
      r'''Comprueba que openssl version indica OpenSSL 3.x. Crea una clave privada Ed25519 cifrada con una frase secreta fuerte y única, y exporta la pública:

openssl genpkey -algorithm ED25519 -aes-256-cbc -out publisher-private.pem
openssl pkey -in publisher-private.pem -pubout -out publisher-public.pem

Calcula la huella SHA-256 del DER SubjectPublicKeyInfo, no del texto PEM:

openssl pkey -pubin -in publisher-public.pem -outform DER -out publisher-public.der
openssl dgst -sha256 publisher-public.der

Guarda la frase secreta en un gestor y la clave privada en un backup cifrado fuera de línea. Prueba restaurarlo en otra carpeta segura y comprueba la misma huella. Puedes compartir la clave pública y la huella; nunca envíes la privada ni la frase al propietario, las incluyas en Course JSON o backups, las subas a Git ni las pegues en webs o chats. Sin clave ni backup no podrás firmar nuevas versiones con esa identidad.''',
  'publisherSigningHelp.requestApproval.title': '3. Editor: pedir aprobación',
  'publisherSigningHelp.requestApproval.body':
      r'''Usa el canal acordado directamente con el propietario de QQL; esta guía no indica una dirección pública. Envía nombre del editor y representante autorizado, pruebas de identidad comprobables, contacto, publisherId propuesto, publisher-public.pem y su huella SHA-256, IDs y títulos previstos, canal de distribución y declaración de derechos sobre contenido y medios.

El propietario verificará tu identidad y enviará un archivo de desafío de un solo uso. Antes de firmarlo, comprueba publisherId, huella, propósito y caducidad. No firmes archivos arbitrarios de un remitente no verificado. Aprobar la clave no avala todo el contenido ni sus licencias.''',
  'publisherSigningHelp.verifyIdentityChallenge.title':
      '4. Propietario: verificar identidad y crear el desafío',
  'publisherSigningHelp.verifyIdentityChallenge.body':
      r'''Mantén un registro privado. Comprueba al representante por un canal establecido de forma independiente; una dirección de correo o una clave por sí solas no prueban identidad. Guarda la clave pública, comprueba que sea Ed25519 con:

openssl pkey -pubin -in publisher-public.pem -text -noout

Calcula y compara la huella por el canal independiente. Rechaza claves defectuosas, algoritmos erróneos y conflictos de publisherId. Asigna un ID de solicitud único y publisherId estable. Genera un nonce nuevo:

openssl rand -hex 32

Crea qql-approval-challenge.txt en UTF-8 con Purpose, Request ID, Publisher ID, Public key SHA-256, Nonce y Expires UTC, sustituyendo todos los marcadores. Usa una caducidad corta, por ejemplo 48 horas. Conserva exactamente los bytes enviados y marca el estado pendiente, usado o caducado. Nunca reformatees ni reutilices el desafío; el propietario aporta el nonce.''',
  'publisherSigningHelp.proveKeyPossession.title':
      '5. Editor y propietario: probar posesión de la clave',
  'publisherSigningHelp.proveKeyPossession.body':
      r'''Editor: guarda el desafío original sin cambiar sus saltos de línea, compruébalo y fírmalo localmente:

openssl pkeyutl -sign -rawin -inkey publisher-private.pem -in qql-approval-challenge.txt -out qql-approval-proof.sig

Devuelve solo qql-approval-proof.sig y el ID de solicitud, nunca la clave privada. Esta prueba no es una firma de Course. Propietario: verifica con el desafío original y la clave pública ya comprobada:

openssl pkeyutl -verify -rawin -pubin -inkey publisher-public.pem -in qql-approval-challenge.txt -sigfile qql-approval-proof.sig

Exige código de salida 0; en PowerShell, consulta $LASTEXITCODE de inmediato. Comprueba además que la solicitud siga pendiente, vigente y sin usar, con la identidad y huella verificadas. Si falla, no apruebes: investiga o emite un desafío nuevo. Una prueba válida demuestra control de la clave, no identidad legal; se necesitan ambas comprobaciones.''',
  'publisherSigningHelp.recordApproval.title':
      '6. Propietario: registrar la aprobación',
  'publisherSigningHelp.recordApproval.body':
      r'''Guarda en privado publisherId, nombre aprobado, PEM y huella, contacto, método y fecha de verificación, desafío, prueba, decisión y estado de clave. Marca usados los desafíos aceptados. No publiques pruebas de identidad ni contactos privados en la app.

Asigna keyId estable (1–64 caracteres ASCII: letras, dígitos, punto, guion bajo o guion). Convierte el PEM público a DER. Ed25519 SubjectPublicKeyInfo DER ocupa 44 bytes: cabecera de 12 bytes 302a300506032b6570032100 y 32 bytes de clave. En publicKeyBase64 guarda Base64 solo de esos 32 bytes. Tras comprobar cabecera y longitud, PowerShell puede obtener el valor con:

[Convert]::ToBase64String(([System.IO.File]::ReadAllBytes('C:/QQL-Publisher/publisher-public.der'))[12..43])

Añade TrustedPublisherKey a TrustedPublishers.application() en lib/services/trusted_publishers.dart con publisherId, publisherName exacto, keyId, publicKeyBase64 y revoked: false. Mantén Dummy fuera del registro normal. Nunca apruebes una clave tomada solo de un curso ni alterando publisherVerificationStatus en JSON. Revisa el cambio; prueba firmas válidas, alteradas, ausentes y de clave errónea. Distribuye la actualización y comunica al editor los IDs, huella y primera versión que confía en él. La aprobación autentica al editor, no su propiedad de cada Course ID ni cada licencia.''',
  'publisherSigningHelp.signAndDistribute.title':
      '7. Editor: firmar y distribuir un curso',
  'publisherSigningHelp.signAndDistribute.body':
      r'''Prepara un externalOfficial JSON válido de Course Model v12 con publisherId y publisherName aprobados, origen, courseId estable y datos de versión. Para actualizar, conserva ID y origen y aumenta officialCourseVersion. Resuelve errores de Course Audit y revisa licencias. La herramienta no convierte cursos custom ni inventa datos del editor.

Desde Build 262 QQL puede crear ese JSON a partir de un curso custom que mantienes: en Course Studio, Export as Publisher Course en el menú del curso escribe un ZIP normal del curso cuyo course.json es el Publisher Course sin firmar (cada ID conservado, el publisherId y el publisherName aprobados que escribes, la Course version como officialCourseVersion) y cuya carpeta media guarda sus medios con su nombre SHA-256. Descomprímelo y usa course.json y la carpeta media en los comandos siguientes. Para una actualización, exporta de nuevo el mismo curso tras un cambio confirmado.

Desde el repositorio QQL, sustituye dummy-1 por tu keyId y usa tus rutas:

dart run tools/sign_course.dart prepare C:/QQL-Publisher/course.json dummy-1 C:/QQL-Publisher/payload.bin
openssl pkeyutl -sign -rawin -inkey C:/QQL-Publisher/publisher-private.pem -in C:/QQL-Publisher/payload.bin -out C:/QQL-Publisher/signature.bin
openssl pkey -pubin -in C:/QQL-Publisher/publisher-public.pem -outform DER -out C:/QQL-Publisher/publisher-public.der
dart run tools/sign_course.dart attach C:/QQL-Publisher/course.json dummy-1 C:/QQL-Publisher/signature.bin C:/QQL-Publisher/publisher-public.der C:/QQL-Publisher/course-signed.json

Coloca cada imagen o grabación referenciada en C:/QQL-Publisher/media/ con su nombre SHA-256, por ejemplo <sha256>.mp3. Crea el paquete:

dart run tools/sign_course.dart package C:/QQL-Publisher/course-signed.json C:/QQL-Publisher/media C:/QQL-Publisher/publisher-public.der C:/QQL-Publisher/course-signed.zip

Comprueba código 0 tras cada comando ($LASTEXITCODE en PowerShell). No cambies course.json entre prepare y attach; cualquier cambio exige preparar y firmar de nuevo. Usa nombres de salida nuevos: OpenSSL puede sobrescribir. La verificación con la clave aportada no equivale a aprobación en el registro QQL. Importa el ZIP en una app que conozca tu clave, comprueba editor, versión, contenido y medios, y prueba la actualización y el progreso. Distribuye ese mismo ZIP. La firma cubre el JSON normalizado y las referencias SHA-256; el ZIP comprueba los bytes de los medios. La firma dentro de QQL aún no está disponible.''',
  'publisherSigningHelp.mediaRules.title':
      '7a. Medios que puede llevar un Publisher Course',
  'publisherSigningHelp.mediaRules.body':
      r'''Un Course ZIP contiene course.json, el manifiesto y solo los medios externos usados por el Course. Los assets integrados vienen con QQL. Los iconos custom de Lesson, banderas custom e imágenes Recognize characters van dentro de course.json. Los MP3 y las imágenes importadas de Exercise viajan como archivos nombrados por contenido. También viajan las imágenes usadas de Shared Image Library, sin añadirse a la biblioteca compartida del receptor.

El editor necesita derechos para distribuir cada archivo. Si el Course tiene referencias media:, usa el ZIP completo: el JSON solo no basta. Se rechazan medios ausentes, alterados o demasiado grandes antes de instalar. Una actualización hace backup del Course oficial anterior y sus medios; después borra los que la nueva versión ya no usa. Desinstalar conserva medios y backups para reinstalar más adelante.''',
  'publisherSigningHelp.mediaCredits.title': '7b. Créditos de medios',
  'publisherSigningHelp.mediaCredits.body':
      r'''Registra autor y licencia de imágenes o grabaciones ajenas en Course Info Editor > License / Rights. Las entradas mediaAttributions quedan dentro del contenido firmado. Las imágenes añadidas por Admin a Shared Image Library también pueden llevar créditos propios que viajan con el Course y el manifiesto ZIP. Course Audit avisa si hay medios propios sin créditos, pero no bloquea Export ni Import. Los medios integrados con QuisquisLingo ya tienen créditos en la app.''',
  'publisherSigningHelp.importPolicy.title':
      '8. Reglas de importación y cursos existentes',
  'publisherSigningHelp.importPolicy.body':
      r'''Un externalOfficial nuevo necesita firma válida de una clave activa y aprobada. Se rechazan firmas ausentes, defectuosas, inválidas, revocadas o desconocidas. Si usa media:, debe llegar como ZIP completo; se comprueba cada archivo contra su digest firmado. La app calcula el estado de verificación: un campo verified en JSON no lo demuestra. Ni una versión oficial igual o anterior ni otro editor pueden sustituir un curso oficial instalado. Un archivo sin firma no puede degradar uno verificado.

Los custom siguen sin firma y pasan la validación normal. Un oficial no verificado no se convierte automáticamente en custom. Los Publisher Courses existentes no verificables se conservan con Verification required y progreso intacto, pero no se entregan al estudiante. Para reactivarlos, importa una versión firmada más nueva de la misma identidad y confirma la asociación. La autenticidad se comprueba de nuevo al leer cursos y backups; revocación o alteración quitan la verificación sin borrar archivos. Los backups no eluden estas reglas.

Los cursos oficiales incluidos confían en la distribución de la app y conservan sus comprobaciones de origen y checksum; un JSON externo que diga bundledOfficial se rechaza. Las firmas no cifran contenido, impiden copiarlo, cobran, prueban calidad didáctica ni establecen derechos de autor.''',
  'publisherSigningHelp.keyRotation.title':
      '9. Claves perdidas, rotación y revocación',
  'publisherSigningHelp.keyRotation.body':
      r'''Editor: restaura la clave desde el backup protegido. Si no es posible o sospechas una filtración, deja de usarla y contacta al propietario por el canal independiente. Indica publisherId, huella antigua, versiones afectadas y detalles; nunca envíes la clave privada.

Propietario: registra el incidente, vuelve a verificar al representante y exige nuevo par de claves con desafío y prueba nuevos. No aceptes una sustitución solo por coincidir nombre o ID. Asigna keyId nuevo. En una rotación prevista, conserva la entrada anterior si quieres seguir confiando en firmas históricas. Si hay compromiso, marca la clave antigua como revoked en el registro y publica una actualización.

Una clave revocada no sirve para nuevas importaciones y sus cursos guardados o backups pasan a no verificados, sin importar la fecha que declaren. Una nueva versión válida y asociada expresamente puede reactivar el curso conservado. No hay sistema de marcas de tiempo confiables para aceptar firmas antiguas de una clave revocada. Los dispositivos sin conexión conocen la revocación solo al actualizar la app. No hace falta borrar el progreso del estudiante.''',
  'publisherSigningHelp.protocolReferences.title':
      '10. Protocolo y referencias',
  'publisherSigningHelp.protocolReferences.body':
      r'''publisherSignature tiene la forma qql-ed25519-v1:<keyId>:<signatureBase64>. La firma ocupa 64 bytes en Base64 estándar canónico. El mensaje UTF-8 firmado contiene QQL-COURSE-SIGNATURE-V1, publisherId, keyId y officialChecksum en minúsculas, cada uno en línea terminada en LF, incluida la final. No lleva BOM.

El checksum es SHA-256 del Course.toJson() normalizado, sin officialChecksum, publisherSignature ni publisherVerificationStatus, con claves de objeto ordenadas recursivamente y JSON compacto. El orden de arrays se conserva. Es la normalización QQL, no RFC 8785/JCS. Los campos desconocidos descartados por el modelo quedan fuera de la firma. Usa la herramienta QQL: otra serialización no tiene compatibilidad garantizada.

Editor: protege clave y backup, consigue aprobación, revisa Audit y licencias, prepara bytes, firma, adjunta firma, empaqueta medios, prueba Import/Update y distribuye el ZIP probado. Propietario: verifica identidad y huella, desafío único, decisión y registro, pruebas válidas e inválidas y créditos de medios. Mantén Dummy desactivado en builds normales.

Referencias:
https://docs.openssl.org/3.0/man1/openssl-genpkey/
https://docs.openssl.org/3.0/man1/openssl-pkey/
https://docs.openssl.org/3.0/man1/openssl-pkeyutl/
https://pub.dev/documentation/cryptography/latest/cryptography/Ed25519-class.html''',
  'publisherSigningHelp.dummyPublisherTesting.title':
      '11. Dummy publisher: pruebas automáticas y manuales',
  'publisherSigningHelp.dummyPublisherTesting.body':
      r'''Dummy Publisher — TEST ONLY usa publisherId org.quisquislingo.test.dummy y keyId dummy-1. Su par de claves y archivos de prueba están en test/fixtures/publishers. La clave privada es pública a propósito para pruebas: nunca la uses para un editor real. No es un asset de la app.

Los tests inyectan el registro Dummy. Las builds normales no confían en él. Para probar manualmente, activa la opción de compilación:

flutter run -d windows --dart-define=QQL_ENABLE_DUMMY_PUBLISHER=true
flutter build windows --release --dart-define=QQL_ENABLE_DUMMY_PUBLISHER=true

Estas builds muestran TEST ONLY. No las distribuyas como versiones públicas; compila la versión normal sin la opción y en una salida limpia. Importa test/fixtures/publishers/dummy-signed-media.zip desde Course Studio > Course Import > Open from… o como {folderCourseImports}/import.zip. Debe confirmarse el editor y la grabación. dummy-signed-v2.json prueba una actualización que elimina ese medio. dummy-unsigned.json y un título firmado alterado deben rechazarse. Una build normal sin la opción rechaza los archivos Dummy como clave desconocida. Estas pruebas no requieren la aprobación de un editor real.''',
  'exerciseHelp.title': 'Ayuda de Exercise',
  'exerciseHelp.search': 'Search Exercise Help',
  'exerciseHelp.clearSearch': 'Clear search',
  'exerciseHelp.noResults':
      'No hay resultados de Exercise Help para tu búsqueda.',
  'exerciseHelp.supplement.canonicalEditor.title': 'Editor canónico',
  'exerciseHelp.supplement.canonicalEditor.body':
      'Dos maneras de crear un ejercicio. New Exercise: formularios de preset listos para los tipos de ejercicio más comunes; elige uno, rellena pocos campos, guarda. Canonical editor (la última opción de New Exercise): la estructura básica de cualquier ejercicio, editada directamente; potente, a veces compleja. Cada formulario de preset escribe datos canónicos ordinarios. El editor canónico (New Exercise › Canonical editor) los muestra todos para cualquier primitiva: opciones, elementos del prompt con funciones e idiomas, items, targets, layout, el modo de evaluación con sus datos de respuesta, feedback y hint, e indica si esta versión puede jugar el resultado. Un ejercicio que ningún preset representa exactamente se abre ahí; el formulario de preset lo muestra en solo lectura y ofrece Open. Las definiciones están en Exercise primitives de la QQL Guide.',
  'exerciseHelp.supplement.answerVariants.title': 'Variantes de respuesta',
  'exerciseHelp.supplement.answerVariants.body':
      'Puedes escribir respuestas completas equivalentes en líneas separadas. La sintaxis compacta es opcional: {Io} hace opcional Io; [prendo|vorrei] elige una alternativa; (non arrivo <> oggi) intercambia solo las partes indicadas. Los grupos [*:il|i] [*:tuo|tuoi] [*:denaro|soldi] se enlazan por posición: admiten il tuo denaro e i tuoi soldi, no mezclas. Necesitas al menos dos grupos enlazados con la misma cantidad de opciones. Se combinan con {}, [] normales y <> válidos. La puntuación final permanece al final. La expansión elimina duplicados y rechaza sintaxis inválida o más de 128 variantes.',
  'exerciseHelp.supplement.textEvaluationAndCorrections.title':
      'Evaluación de texto y correcciones',
  'exerciseHelp.supplement.textEvaluationAndCorrections.body':
      'QQL acepta las respuestas completas configuradas y sus variantes tras normalizar mayúsculas, puntuación, espacios, apóstrofos y acentos. Type the translation también tolera una letra repetida omitida o duplicada en una palabra de al menos cinco caracteres si todo lo demás coincide. Ante un error muestra hasta tres respuestas válidas ordenadas por similitud y Some possible translations si hay más. Ante una respuesta correcta muestra hasta dos alternativas distintas de la respuesta aceptada. El orden de autor resuelve empates; la clasificación no cambia qué se acepta. Los demás presets escritos mantienen Correct answer. El feedback solo menciona diferencias reales.',
  'exerciseHelp.supplement.contextualComprehensionExample.title':
      'Ejemplo de Read and answer',
  'exerciseHelp.supplement.contextualComprehensionExample.body':
      'Question: What does Jane mean?\n\nContext:\nJane: I thought Jim was coming with us.\nJim: I changed my mind.\nJane: That’s just great.\n\nQuestion y Context son independientes. Context puede ser texto, audio o ambos. El diálogo es opcional; también sirve un anuncio, pasaje o situación breve. Configura las respuestas por separado.',
  'exerciseHelp.preset.choice_target.body':
      'El estudiante lee una pregunta, o una frase que completar, y elige la respuesta correcta entre alternativas de texto en la lengua de estudio; la pregunta puede estar en cualquiera de las dos lenguas. Puede ser cualquier cosa que necesite el curso: una forma gramatical, un dato cultural, un significado, una traducción. Escribe la pregunta, al menos dos respuestas de texto y una respuesta correcta (un ejercicio nuevo empieza con la respuesta 1; con Multiple correct answers pueden ser varias, y el Audit avisa si todas las respuestas son correctas). Una línea Instruction or context opcional, en la lengua del estudiante, se muestra en lugar de la línea estándar “Find the correct answer.”. Un audio o una imagen opcionales pueden acompañar la pregunta. Haz que los distractores sean plausibles pero claramente incorrectos. Su gemelo Choose the answer (to source) pregunta y responde en la lengua base.',
  'exerciseHelp.preset.choice_source.body':
      'El estudiante lee una pregunta, o una frase que completar, escrita en la lengua base y elige la respuesta correcta entre alternativas en la lengua base: una regla gramatical, un dato cultural, el significado de una expresión, todo lo que conviene preguntar en la lengua que el estudiante ya conoce. Escribe la pregunta, al menos dos respuestas de texto y una respuesta correcta (un ejercicio nuevo empieza con la respuesta 1; con Multiple correct answers pueden ser varias, y el Audit avisa si todas las respuestas son correctas). Una línea Instruction or context opcional, en la lengua del estudiante, se muestra en lugar de la línea estándar “Find the correct answer.”. El audio opcional del prompt se lee con la voz de la lengua base y una imagen puede acompañar la pregunta. Haz que los distractores sean plausibles pero claramente incorrectos. Su gemelo Choose the answer (to target) pregunta y responde en la lengua de estudio.',
  'exerciseHelp.preset.listening_choose_target.body':
      'El estudiante escucha audio en la lengua de estudio y elige lo que oyó entre alternativas escritas en la lengua de estudio. No hay pregunta; una instrucción o un contexto opcionales describen la situación y sustituyen la línea estándar. Audio text contiene exactamente lo que se oye y se reproduce como en Listen and answer (to target), con On-Device TTS, Recorded MP3 o Hybrid. Ofrece las alternativas y una respuesta correcta sin revelar el audio visualmente. Para hacer una pregunta sobre lo que se oye, usa Listen and answer. Su gemelo Listen and choose (to source) responde con el significado en la lengua base.',
  'exerciseHelp.preset.listening_choose_source.body':
      'El estudiante escucha audio en la lengua de estudio y elige su significado entre alternativas escritas en la lengua base. No hay pregunta; una instrucción o un contexto opcionales describen la situación y sustituyen la línea estándar. Audio text, On-Device TTS, Recorded MP3 e Hybrid funcionan como en Listen and answer (to target). Ofrece las alternativas y una respuesta correcta sin revelar el audio visualmente.',
  'exerciseHelp.preset.listening_answer_target.body':
      'El estudiante escucha audio en la lengua de estudio y elige la respuesta entre alternativas escritas en la lengua de estudio. La pregunta es obligatoria: el estudiante la responde sobre lo que oyó, así que haz el pasaje suficientemente largo. Para que elija lo que oyó, sin pregunta, usa Listen and choose. Audio text debe contener exactamente lo que se oye. On-Device TTS usa la voz del dispositivo; Recorded MP3 busca asociaciones de texto en Course Editor > Audio Library; Hybrid prueba primero los MP3 completos y después TTS. Para MP3, importa archivos en {folderAudioImports} con Import MP3 y usa Associate recording. No se adjunta MP3 a cada Exercise. El JSON solo guarda referencias, no bytes. Ofrece varias respuestas escritas y una correcta sin revelar el audio visualmente. Su gemelo Listen and answer (to source) pregunta y responde en la lengua base.',
  'exerciseHelp.preset.listening_answer_source.body':
      'El estudiante escucha audio en la lengua de estudio y responde a una pregunta formulada en la lengua base, eligiendo entre alternativas escritas en la lengua base. Escribe Audio text en la lengua de estudio, la pregunta (obligatoria), las alternativas y una respuesta correcta. Para el significado solo, sin pregunta, usa Listen and choose (to source). Audio text, On-Device TTS, Recorded MP3 e Hybrid funcionan como en Listen and answer (to target). No reveles el audio visualmente.',
  'exerciseHelp.preset.reading_answer_target.body':
      'El estudiante lee un texto breve en la lengua base que explica la situación, luego líneas de diálogo en la lengua de estudio (un turno “Speaker: texto” por línea), y responde una pregunta en la lengua de estudio eligiendo entre alternativas en la lengua de estudio. Escribe el texto, el diálogo o ambos, la pregunta, al menos dos respuestas y una correcta. Read the dialogue aloud: Automatically lee cada línea por turno con una breve pausa cuando aparece el ejercicio; On request añade el botón Play dialogue; No read-aloud lo deja en silencio. El texto para leer nunca se lee en voz alta y la lectura nunca convierte el ejercicio en un ejercicio de audio. Una imagen del Exercise puede acompañarlo. Este preset sustituye a Reading comprehension, Dialogue response y Contextual comprehension; Read and answer (to source) se retiró y se abre aquí.',
  'exerciseHelp.preset.type_translation_to_target.body':
      'El estudiante traduce libremente un texto de la lengua base. Escribe el texto y una o más traducciones completas aceptadas; Hint es opcional. Usa minúsculas salvo nombres propios. Se admiten variantes {}, [a|b], grupos enlazados [*:a|b] y cambios de orden <>. Expand answers muestra una vista previa sin guardar; Use expanded answers añade líneas explícitas sin modificar la expresión original. Se rechazan más de 128 variantes sin cambios parciales. El feedback muestra respuestas válidas por similitud, sin cambiar cuáles se aceptan. Se tolera de forma conservadora una letra repetida omitida o duplicada, no palabras ausentes ni sustituciones. Su gemelo Type the translation (to source) muestra un texto en la lengua de estudio y acepta una traducción en la lengua base.',
  'exerciseHelp.preset.type_translation_to_source.body':
      'El estudiante ve un texto en la lengua de estudio y escribe libremente su traducción en la lengua base. Escribe el texto que traducir en la lengua de estudio, una o más traducciones completas aceptadas en la lengua base y un Hint opcional. Las respuestas aceptadas usan la misma sintaxis, expansión, feedback y tolerancia a erratas que Type the translation (to target): {} opcional, alternativas independientes [a|b], grupos enlazados [*:a|b], ámbitos <> de reordenación, Expand answers y Use expanded answers, 128 respuestas como máximo. Usa minúsculas salvo nombres propios.',
  'exerciseHelp.preset.build_translation_to_target.body':
      'El estudiante forma una traducción con bloques de palabras. Escribe el texto de origen, los bloques literales y una o más traducciones completas correctas. Cada respuesta debe poder construirse con bloques distintos; una palabra repetida requiere bloques repetidos. Se recomienda que sobren como máximo dos bloques. No se aplica la sintaxis de Type the translation ni tolerancia a erratas. Su gemelo Build the translation (to source) muestra un texto en la lengua de estudio y usa bloques en la lengua base.',
  'exerciseHelp.preset.build_translation_to_source.body':
      'El estudiante ve un texto en la lengua de estudio y construye su traducción en la lengua base con bloques de palabras. Escribe el texto que traducir en la lengua de estudio, los bloques literales disponibles en la lengua base y una o más traducciones completas correctas. Las respuestas se pueden añadir, quitar y reordenar; cada una debe poder construirse con ocurrencias distintas de los bloques. Una palabra repetida requiere bloques repetidos y pocos distractores funcionan mejor: se recomienda que sobren como máximo dos bloques, menos en los primeros Rounds de una Lesson; se admiten más. No se aplica la sintaxis de Type the translation, ni tolerancia a erratas ni similitud.',
  'exerciseHelp.preset.picture_flashcard.body':
      'Una tarjeta de dos caras: la primera vez que se hace un Round el anverso muestra la palabra en la lengua de estudio con su botón de lectura, y el reverso la imagen con la traducción en la lengua base, luego el ejemplo de uso opcional con su traducción. Cuando el estudiante repite un Round ya completado, y en Review, el anverso muestra la imagen con la traducción y el reverso la palabra con su lectura. El estudiante da la vuelta a la tarjeta tocándola, con Turn over, Intro o Espacio. Escribe la imagen (Image), la palabra y la traducción, si quieres las líneas de uso, y elige Automatically, On request o No read-aloud; rellena Pronunciation TTS (if different) solo cuando el texto leído deba diferir de la palabra. La tarjeta nunca es un Exercise de audio y se muestra con Audio Exercises apagado. Got it en el anverso salta una tarjeta que el estudiante ya conoce; tras darle la vuelta, Got it completa la tarjeta y Review again la repite una vez.',
  'exerciseHelp.preset.true_false.body':
      'El estudiante lee una afirmación en la lengua de estudio, opcionalmente la escucha, y elige entre la palabra para verdadero y la palabra para falso en la lengua base. Escribe la afirmación, una afirmación hablada opcional, las dos respuestas (prellenadas en la lengua base cuando QQL la conoce) y el número de la respuesta correcta: 1 si la afirmación es verdadera, 2 si es falsa.',
  'exerciseHelp.preset.one_word_fills_all.body':
      'El estudiante lee frases con dos o más huecos ___ y elige la única palabra que los rellena todos; una vez elegida aparece en cada hueco. Escribe las frases con ___ (tres guiones bajos) para cada hueco, las palabras de respuesta y el número de la respuesta correcta; solo una palabra debe encajar en todos los huecos. Para un solo hueco usa Pick the missing word. Una Instruction or context opcional ocupa el lugar de la línea estándar.',
  'exerciseHelp.preset.complete_text.body':
      'El estudiante lee un texto con uno o más huecos y escribe lo que va en cada uno. Escribe el texto con ___ (tres guiones bajos) para cada hueco y en Missing words una línea por hueco, en orden. Una línea puede aceptar varias respuestas: [il|un] gatto acepta il gatto y un gatto. Una Instruction or context opcional describe la escena y sustituye la línea estándar; una pista opcional ayuda sin revelar las palabras. Las respuestas usan la normalización normal de Input. No hay audio: para huecos escuchados usa Listen and fill the gaps.',
  'exerciseHelp.preset.missing_letters.body':
      'El estudiante ve palabras con letras que faltan y escribe las letras. Escribe el texto completo y pon las letras que faltan entre guiones bajos: My cat doesn’t dr_ink_ milk. El estudiante ve dr___ milk, un guion por letra, y escribe ink. Puede haber varios huecos. Un texto hablado opcional lee la frase entera, una imagen opcional la ilustra y una pista opcional ayuda sin revelar las letras.',
  'exerciseHelp.preset.gap_blocks.body':
      'El estudiante ve una frase con huecos y toca una palabra para cada hueco; cada palabra rellena un hueco, sale de la reserva y debe ir al hueco correcto. Escribe la frase con cada respuesta entre guiones bajos: Io _vorrei_ un caffè. Una palabra que hace falta dos veces se escribe en ambos huecos y se ofrece dos veces. Añade palabras distractoras (se recomiendan 0, 1 o 2) y un audio opcional. Este preset reúne los anteriores Pick the words for the gaps y Drag the blocks into the gaps.',
  'exerciseHelp.preset.sentence_order.body':
      'El estudiante ve las líneas de una historia breve o un diálogo como bloques y las ordena. Escribe las líneas una sola vez, en el orden correcto, y las líneas que no pertenecen a nada (se recomiendan 0, 1 o 2). La Instruction or context puede dar la situación que decide el orden; una pista opcional ayuda sin revelarlo.',
  'exerciseHelp.preset.sort_into_groups.body':
      'El estudiante toca una palabra y luego el grupo al que pertenece; una palabra colocada se puede retirar; Check evalúa todos los grupos a la vez. Escribe una instrucción o un contexto opcionales y un grupo por línea como “Nombre del grupo: palabra, palabra, …” (al menos dos, cada uno con al menos una palabra). Cada palabra pertenece a un grupo, y solo a uno. Sort into groups nunca es un ejercicio de audio.',
  'exerciseHelp.preset.fill_the_slots.body':
      'El estudiante toca una palabra y luego la casilla que rellena; una segunda palabra sustituye a la primera; Check evalúa todas las casillas a la vez. Escribe una instrucción o un contexto opcionales y una casilla por línea como “lo que ve el estudiante = la palabra que la rellena”, por ejemplo “… gatto = il”. Las palabras extra que no rellenan ninguna casilla son opcionales. Activa “A word may fill more than one slot” cuando la misma palabra es la respuesta de varias casillas: se queda en el banco tras cada uso.',
  'exerciseHelp.preset.listening_image_choice.body':
      'El estudiante escucha el texto hablado y elige la imagen que nombra. Escribe el texto hablado, una instrucción o un contexto opcionales, las etiquetas de las respuestas (una por línea) y una imagen por respuesta, elegida con los selectores bajo las respuestas; marca la respuesta correcta. Las etiquetas se muestran bajo las imágenes.',
  'exerciseHelp.preset.spell_heard.body':
      'El estudiante escucha una palabra y la deletrea ordenando fichas de letras o sílabas. Escribe la palabra hablada y sus fichas en orden, una por línea (divide la palabra en letras o sílabas como prefieras). No hace falta imagen; las fichas se unen sin espacios.',
  'exerciseHelp.preset.picture_choice.body':
      'El estudiante ve una imagen y elige entre respuestas de texto la palabra o la frase que la nombra. Escribe la imagen (Image, obligatoria), una instrucción o un contexto opcionales como ¿Qué es esto?, al menos dos respuestas y la correcta.',
  'exerciseHelp.preset.picture_name.body':
      'El estudiante ve una imagen y escribe lo que muestra. Escribe la imagen (Image, obligatoria), una instrucción o un contexto opcionales, una o más respuestas aceptadas con la misma sintaxis que Type the translation ({} opcional, alternativas [a|b], grupos enlazados, ámbitos de reordenación) y una pista opcional. Las respuestas usan la normalización normal de Input y la tolerancia a erratas.',
  'exerciseHelp.preset.picture_blocks.body':
      'El estudiante ve una imagen y forma su nombre tocando los bloques de palabras en orden; un bloque colocado se puede retirar; Check evalúa el orden. Escribe la imagen (Exercise image, obligatoria), una instrucción o un contexto opcionales como What is this?, los bloques del nombre en orden (una palabra por línea) y hasta dos bloques de más que no forman parte del nombre, más una pista opcional. Los bloques se unen con espacios. Si las mayúsculas del nombre y de los bloques difieren, el Audit da un aviso. Type what you see es el mismo ejercicio con la respuesta escrita.',
  'exerciseHelp.preset.spell_word.body':
      'El estudiante lee una pista en la lengua base, la palabra misma o una definición, y deletrea la palabra en la lengua de estudio ordenando fichas de letras o sílabas. Escribe la pista y las fichas de la palabra en orden, una por línea; la imagen es opcional.',
  'exerciseHelp.preset.picture_word_match.body':
      'El estudiante relaciona cada imagen de la izquierda con una palabra de la derecha. Escribe las palabras, una por línea, y una imagen por palabra con los selectores de abajo; al menos dos pares. Cuentan las relaciones entre pares, no las posiciones.',
  'exerciseHelp.preset.dialogue_line.body':
      'Una línea de diálogo en una Historia. Elige quién habla (el narrador o un personaje definido en Story characters del Course Editor), escribe la línea y elige si el estudiante la lee, la escucha o ambas cosas. La lectura en voz alta sigue el ajuste de la Historia salvo que la línea lo cambie; con texto y audio puedes ocultar el texto hasta que el audio se haya reproducido. Una línea nunca se salta: sin audio el estudiante la lee. No hay respuesta ni puntuación; Continue avanza.',
  'exerciseHelp.preset.before_you_start.body':
      'La nota que el estudiante lee antes de que empiece el Round, en una página propia con Continue to Round. Escribe la nota y, si quieres, activa Open GuideBook button: la tarjeta ofrece entonces el GuideBook de la Lesson (los estudiantes ven el botón solo mientras el Curso usa GuideBooks y el GuideBook está publicado). La tarjeta va primero en el Round, nunca es uno de sus pasos y nunca se muestra en Review; no hay respuesta ni puntuación. Una tarjeta por Round: el Audit avisa de una segunda.',
  'exerciseHelp.preset.page.body':
      'Una página que el estudiante lee y luego continúa, hecha de bloques: títulos, párrafos, citas o ejemplos, listas con viñetas o numeradas, imágenes, audio y enlaces de vídeo. En el texto escribe **negrita** y *cursiva* (la barra de herramientas rodea la selección); elige para cada bloque la alineación (inicio, centro, final, justificado para el texto) y un color de una paleta legible en el tema claro y en el oscuro; un bloque de texto puede ofrecer lectura en voz alta. Las imágenes son pequeñas, medianas, grandes o a todo el ancho, con pie de foto; un enlace de vídeo abre una dirección https en el navegador. Sin respuesta ni puntuación.',
  'exerciseHelp.preset.story_cover.body':
      'La primera tarjeta de una Historia. Elige la imagen de portada y, si quieres, una línea de título; el título de la Historia de las opciones del Round se muestra encima. El estudiante pulsa Continue. Crea una Story con New Round → Story.',
  'exerciseHelp.preset.note_card.body':
      'Una tarjeta con un título y una nota: un consejo, un punto gramatical, una observación cultural. El estudiante la lee y pulsa Continue; no hay respuesta, puntuación ni audio. Escribe en la lengua que tus estudiantes leen mejor.',
  'exerciseHelp.preset.gap_choice.body':
      'El estudiante ve una frase con ___ y elige la palabra o expresión que falta. Escribe un hueco, bloques de respuesta y una respuesta correcta. Procura que solo una opción sea correcta en significado y gramática. Una Instruction or context opcional, como el significado de una frase breve (Completa la frase que significa el perro.), ocupa el lugar de la línea estándar.',
  'exerciseHelp.preset.icon_choice.body':
      'El estudiante ve una pregunta y varias imágenes, y elige la que corresponde. Añade texto o icono para cada opción y el número de la respuesta correcta. Todas las opciones necesitan imagen.',
  'exerciseHelp.preset.script_recognition.body':
      'Cada opción relaciona la imagen de un carácter con su texto. En Image to text se elige el texto que corresponde a la imagen; en Text to image se elige la imagen del texto. El texto puede ser nombre, sonido, pronunciación o transliteración. Da al menos dos opciones y una sola correcta. Puedes mostrar varias imágenes del carácter. Usa imágenes incluidas o importadas portátiles, nunca rutas absolutas. Preview emplea la interacción Select normal.',
  'exerciseHelp.preset.translation_choice_to_target.body':
      'Select, una respuesta y comprobación inmediata. QQL crea la instrucción Choose the correct [Target language] translation según las lenguas del curso. Escribe el texto de origen, de dos a cinco traducciones diferentes y una correcta. Puedes añadir imagen. Elegir mal muestra la respuesta. Después se puede oír la correcta con TTS disponible; el Exercise no depende de audio. Usa distractores plausibles y claramente incorrectos.',
  'exerciseHelp.preset.translation_choice_to_source.body':
      'Select, una respuesta y comprobación inmediata. QQL crea la instrucción Choose the correct [Source language] translation. Escribe el texto en la lengua de estudio, de dos a cinco traducciones diferentes a la lengua base y una correcta. Puedes añadir imagen. Elegir mal muestra la respuesta. Se puede escuchar el texto de la lengua de estudio con TTS disponible; el Exercise no depende de audio.',
  'exerciseHelp.preset.type_missing_word.body':
      'Escribe una frase con un hueco ___ y las palabras completas aceptadas. Con Show the first letter activo, el hueco muestra la primera letra como pista: QQL obtiene automáticamente el primer grafema Unicode y todas las respuestas deben empezar por el mismo. Con el interruptor apagado, el hueco está vacío y el estudiante escribe la palabra sin ayuda. En ambos casos el estudiante escribe la palabra completa, con la normalización y el feedback normales de Input. Ejemplo: con la pista, el estudiante ve é______ y escribe école, no cole. Tras comprobar se muestra la frase completa. Los Exercises creados con el antiguo preset Fill-in se abren aquí.',
  'exerciseHelp.preset.listening_spelling.body':
      'El estudiante oye audio y escribe lo que escuchó. Introduce Audio text: siempre se acepta como respuesta. Other accepted spellings (optional) enumera otras formas de escribir las mismas palabras, como alle 9 por alle nove. Return o Enter envía la respuesta.',
  'exerciseHelp.preset.missing_word.body':
      'El estudiante escucha audio y lee una transcripción con uno o más huecos, luego escribe las palabras ausentes. Introduce la transcripción y Audio text completos, y cada Missing word en orden. Todas deben aparecer en la transcripción.',
  'exerciseHelp.preset.word_match.body':
      'El estudiante relaciona palabras de la lengua base con sus traducciones. Escribe al menos dos pares de texto; tres es el número habitual. Cada elemento visible debe ser único tras la normalización. Los Exercises creados con el antiguo preset Matching se abren aquí.',
  'exerciseHelp.preset.super_match.body':
      'El estudiante relaciona elementos de la lengua de estudio, como sinónimos u opuestos. Escribe exactamente tres pares y una instrucción o un contexto opcionales que indiquen la relación, en la lengua del estudiante. No mezcles reglas distintas.',
  'exerciseHelp.preset.audio_match.body':
      'El estudiante reproduce tres audios y relaciona cada uno con un texto. Escribe exactamente tres pares audio-texto, sin distractores. Cada audio y respuesta visible debe ser único.',
  'exerciseHelp.preset.word_order.body':
      'El estudiante ordena bloques de la lengua de estudio. Escribe los bloques y el orden correcto. Se recomiendan como máximo dos distractores distintos; este preset evalúa orden, no traducción.',
  'exerciseHelp.preset.image_word.body':
      'El estudiante ve una imagen y ordena letras o sílabas para formar su palabra. Escribe la imagen, la instrucción y los bloques de la palabra en orden, uno por línea; el estudiante recibe exactamente esos bloques, mezclados. No se permiten distractores.',
  'exerciseHelp.preset.flashcard.body':
      'La tarjeta tiene dos caras. La primera vez que se hace un Round, el anverso muestra la palabra o expresión en la lengua de estudio con su botón de lectura; el reverso muestra la palabra en pequeño, su traducción en la lengua base y el ejemplo de uso opcional con su traducción (el ejemplo se escucha solo a petición). Cuando el estudiante repite un Round ya completado, y en Review, la tarjeta se invierte: la traducción está en el anverso y la palabra, con su lectura, en el reverso. La vista previa del editor siempre muestra primero la palabra. El estudiante da la vuelta a la tarjeta tocándola, con Turn over, Intro o Espacio; Got it en el anverso salta una tarjeta que ya conoce, y tras darle la vuelta elige Review again o Got it. Aporta material de estudio, no una respuesta puntuable; elige Automatically, On request o No read-aloud (Automatically lee la palabra cuando aparece: en el anverso, o en el reverso de una tarjeta invertida); rellena Pronunciation TTS (if different) solo cuando el texto leído deba diferir de la palabra. La lectura en voz alta nunca convierte la tarjeta en un ejercicio de audio. Presentation Content no da XP de respuesta correcta.',
  'exerciseHelp.preset.choice_target.description':
      'El estudiante lee una pregunta y elige la respuesta entre opciones en la lengua de estudio: gramática, cultura o significado, no solo traducciones.',
  'exerciseHelp.preset.choice_source.description':
      'El estudiante lee una pregunta en la lengua base y elige la respuesta: reglas, cultura y significados preguntados en la lengua que ya conoce.',
  'exerciseHelp.preset.listening_choose_target.description':
      'El estudiante escucha audio en la lengua de estudio y elige lo que oyó entre respuestas en la lengua de estudio; no hay pregunta.',
  'exerciseHelp.preset.listening_choose_source.description':
      'El estudiante escucha audio en la lengua de estudio y elige su significado entre respuestas en la lengua base; no hay pregunta.',
  'exerciseHelp.preset.listening_answer_target.description':
      'El estudiante escucha audio en la lengua de estudio y responde a una pregunta sobre el pasaje, eligiendo entre respuestas en la lengua de estudio.',
  'exerciseHelp.preset.listening_answer_source.description':
      'El estudiante escucha audio en la lengua de estudio y responde a una pregunta en la lengua base, eligiendo entre respuestas en la lengua base.',
  'exerciseHelp.preset.reading_answer_target.description':
      'El estudiante lee una situación en la lengua base y líneas de diálogo en la lengua de estudio, y responde una pregunta en la lengua de estudio.',
  'exerciseHelp.preset.type_translation_to_target.description':
      'El estudiante escribe una traducción en la lengua de estudio.',
  'exerciseHelp.preset.type_translation_to_source.description':
      'El estudiante lee un texto en la lengua de estudio y escribe su traducción en la lengua base.',
  'exerciseHelp.preset.build_translation_to_target.description':
      'El estudiante construye una traducción con bloques de palabras.',
  'exerciseHelp.preset.build_translation_to_source.description':
      'El estudiante lee un texto en la lengua de estudio y construye su traducción en la lengua base con bloques de palabras.',
  'exerciseHelp.preset.picture_flashcard.description':
      'El estudiante repasa una imagen con su palabra, su significado y un ejemplo de uso opcional, con lectura en voz alta opcional.',
  'exerciseHelp.preset.true_false.description':
      'El estudiante lee (o escucha) una afirmación en la lengua de estudio y responde verdadero o falso.',
  'exerciseHelp.preset.one_word_fills_all.description':
      'El estudiante elige la única palabra que rellena todos los huecos de las frases.',
  'exerciseHelp.preset.complete_text.description':
      'El estudiante escribe las palabras que faltan en un texto con huecos marcados con ___; sin audio, con instrucción y pista opcionales.',
  'exerciseHelp.preset.missing_letters.description':
      'El estudiante escribe las letras que faltan dentro de las palabras (be__); texto hablado o imagen opcionales.',
  'exerciseHelp.preset.gap_blocks.description':
      'El estudiante rellena los huecos de una frase fija tocando palabras; cada palabra rellena un hueco.',
  'exerciseHelp.preset.sentence_order.description':
      'El estudiante ordena las líneas de una historia o un diálogo.',
  'exerciseHelp.preset.sort_into_groups.description':
      'El estudiante clasifica palabras en grupos, como masculino y femenino o animales y plantas.',
  'exerciseHelp.preset.fill_the_slots.description':
      'El estudiante pone la palabra correcta en cada casilla, por ejemplo el artículo delante de cada nombre.',
  'exerciseHelp.preset.listening_image_choice.description':
      'El estudiante escucha una palabra o una frase y elige la imagen correspondiente.',
  'exerciseHelp.preset.spell_heard.description':
      'El estudiante escucha una palabra y la deletrea con fichas de letras o sílabas.',
  'exerciseHelp.preset.picture_choice.description':
      'El estudiante ve una imagen y elige la palabra o la frase que la nombra.',
  'exerciseHelp.preset.picture_name.description':
      'El estudiante ve una imagen y escribe su nombre; varias respuestas aceptadas.',
  'exerciseHelp.preset.picture_blocks.description':
      'El estudiante ve una imagen y forma su nombre con bloques de palabras; hasta dos bloques de más.',
  'exerciseHelp.preset.spell_word.description':
      'El estudiante deletrea una palabra con fichas de letras o sílabas tras una pista en la lengua base.',
  'exerciseHelp.preset.picture_word_match.description':
      'El estudiante relaciona imágenes con sus palabras.',
  'exerciseHelp.preset.dialogue_line.description':
      'Una línea de una Historia, dicha por el narrador o un personaje como texto, audio o ambos; el estudiante lee o escucha y continúa.',
  'exerciseHelp.preset.before_you_start.description':
      'Una nota que se muestra antes de que empiece el Round, con un botón Open GuideBook opcional; nunca se muestra en Review.',
  'exerciseHelp.preset.page.description':
      'Una página como la de un libro de texto: títulos, párrafos con negrita y cursiva, citas, listas, imágenes, audio y enlaces de vídeo, con alineación y colores; el estudiante la lee y continúa.',
  'exerciseHelp.preset.story_cover.description':
      'La tarjeta de apertura de una Historia: su imagen y una línea de título opcional; el estudiante continúa.',
  'exerciseHelp.preset.note_card.description':
      'Un consejo, una nota gramatical o cultural que el estudiante lee y continúa.',
  'exerciseHelp.preset.gap_choice.description':
      'El estudiante elige la palabra o expresión que falta.',
  'exerciseHelp.preset.icon_choice.description':
      'El estudiante elige la imagen que corresponde al prompt.',
  'exerciseHelp.preset.script_recognition.description':
      'Reconoce caracteres impresos o manuscritos: Image to text o Text to image.',
  'exerciseHelp.preset.translation_choice_to_target.description':
      'Select: el estudiante ve texto en la lengua base y elige su traducción.',
  'exerciseHelp.preset.translation_choice_to_source.description':
      'Select: el estudiante ve texto en la lengua de estudio y elige su traducción a la lengua base.',
  'exerciseHelp.preset.type_missing_word.description':
      'El estudiante escribe la palabra que falta en una frase; la primera letra puede mostrarse como pista.',
  'exerciseHelp.preset.listening_spelling.description':
      'El estudiante escucha y escribe la palabra o pasaje oído.',
  'exerciseHelp.preset.missing_word.description':
      'El estudiante escucha y completa huecos en una transcripción.',
  'exerciseHelp.preset.word_match.description':
      'El estudiante relaciona palabras y traducciones.',
  'exerciseHelp.preset.super_match.description':
      'El estudiante relaciona elementos de la lengua de estudio.',
  'exerciseHelp.preset.audio_match.description':
      'El estudiante relaciona audios con sus elementos.',
  'exerciseHelp.preset.word_order.description':
      'El estudiante pone bloques en la lengua de estudio en el orden correcto.',
  'exerciseHelp.preset.image_word.description':
      'El estudiante forma la palabra que representa una imagen.',
  'exerciseHelp.preset.flashcard.description':
      'Presenta material de estudio sin una respuesta puntuable normal.',
  'exerciseHelp.category.vocabulary': 'Vocabulary',
  'exerciseHelp.category.grammarAndSentences': 'Grammar and sentences',
  'exerciseHelp.category.listening': 'Listening',
  'exerciseHelp.category.readingAndDialogue': 'Reading and dialogue',
  'exerciseHelp.category.picturesAndCharacters': 'Pictures and characters',
  'exerciseHelp.category.cardsAndNotes': 'Cards and notes',
  'exerciseHelp.category.comingLater': 'Coming later',
  'exerciseHelp.comingLater': 'En una versión posterior:',
  'exerciseHelp.field.build_translation_to_source.correctTranslation.body':
      'Define una respuesta completa y literal en la lengua base para Build the translation (to source).\n\nQué escribir\nCada entrada de respuesta contiene una frase completa en la lengua base. Usa Add correct translation para otra respuesta y el asa para reordenar.\n\nComprobaciones\nHace falta al menos una respuesta no vacía. Las respuestas deben ser únicas tras normalizar mayúsculas, espacios y puntuación final, y construibles con ocurrencias distintas de los bloques disponibles. No se aplican expresiones opcionales, alternativas ni de reordenación, ni similitud ni tolerancia a erratas.\n\nEjemplo\nI would like a coffee.',
  'exerciseHelp.field.build_translation_to_source.tokens.body':
      'Bloques en la lengua base con los que se construyen las traducciones correctas.\n\nQué escribir\nUn bloque literal por línea, en la lengua base. Las líneas vacías se ignoran. Incluye suficientes ocurrencias distintas para construir cada traducción correcta; una palabra repetida requiere líneas repetidas. Con Inline gaps activo, este campo solo añade distractores opcionales.\n\nComprobaciones\nCada traducción correcta debe poder construirse con estos bloques. Pocos distractores funcionan mejor: se recomienda que como máximo 2 bloques queden sin usar por todas las traducciones correctas, menos en los primeros Rounds de una Lesson; se admiten más.\n\nEjemplo\nI\nwould\nlike\na\ncoffee\ntea',
  'exerciseHelp.field.choice_source.answers.body':
      'Las alternativas, escritas en la lengua base.\n\nQué escribir\nUna respuesta literal por línea, al menos dos líneas no vacías, en la lengua que el estudiante ya conoce. Las líneas vacías se ignoran. La primera línea no vacía es la respuesta 1.\n\nComprobaciones\nElige un Correct answer number válido. Evita respuestas duplicadas y haz que los distractores sean plausibles pero claramente incorrectos.\n\nEjemplo\nel de antes de vocal\nel de antes de consonante\nninguno',
  'exerciseHelp.field.listening_answer.question.body':
      'La pregunta que el estudiante responde sobre lo que oye.\n\nQué escribir\nUna pregunta sobre la grabación: quién, qué, dónde, cuántos. Listen and answer (to source) la formula en la lengua base. Para que el estudiante elija solo lo que oyó, sin pregunta, usa Listen and choose.\n\nComprobaciones\nObligatoria: un guardado Published la rechaza vacía. Haz la grabación lo bastante larga para responder y marca la respuesta correcta.\n\nEjemplo\nDove fa la spesa Maria?',
  'exerciseHelp.field.one_word_fills_all.question.body':
      'Las frases que el estudiante completa con una palabra que encaja en cada hueco.\n\nQué escribir\nEscribe las frases en la lengua de estudio con ___ (tres guiones bajos) donde va la misma palabra; al menos dos huecos. La palabra elegida aparece en cada hueco.\n\nComprobaciones\nObligatorio: un guardado Published lo rechaza sin dos o más huecos. Para un solo hueco usa Pick the missing word.\n\nEjemplo\n___ gatto dorme. ___ cane mangia.',
  'exerciseHelp.field.choice_source.question.body':
      'La pregunta, o la frase que completar, escrita en la lengua base.\n\nQué escribir\nUna pregunta en la lengua que el estudiante ya conoce, o una frase con ___ donde va la respuesta: una regla gramatical, un dato cultural, el significado de una expresión. La instrucción o el contexto van en Instruction or context.\n\nComprobaciones\nLas respuestas también están en la lengua base; marca la correcta (o varias con Multiple correct answers).\n\nEjemplo\n¿Qué artículo italiano acompaña a un sustantivo masculino que empieza por vocal?',
  'exerciseHelp.field.reading_answer.prompt.body':
      'El texto que explica la situación, en la lengua del estudiante.\n\nQué escribir\nUn texto breve en la lengua base: dónde están los hablantes, quiénes son, qué pasa. Varias líneas o párrafos forman parte del texto. Se muestra antes del diálogo y nunca se lee en voz alta.\n\nComprobaciones\nHace falta un texto con palabras o líneas de diálogo; la puntuación sola no basta.\n\nEjemplo\nAnna and Luca are in the kitchen after lunch.',
  'exerciseHelp.field.reading_answer.dialogueReadAloud.body':
      'Si las líneas del diálogo se leen en voz alta.\n\nQué escribir\nAutomatically: cada línea se lee por turno, con una breve pausa, cuando aparece el ejercicio. On request: el botón Play dialogue las lee. No read-aloud: el diálogo solo se lee.\n\nComprobaciones\nLa lectura es opcional: el ejercicio nunca es de audio y queda en silencio con Audio Exercises o Text-to-speech desactivados. Las líneas se leen en la lengua de estudio; los nombres de los hablantes no se leen.\n\nEjemplo\nAutomatically, line by line',
  'exerciseHelp.field.type_missing_word.revealFirstLetter.body':
      'Decide si el hueco muestra la primera letra de la palabra ausente como pista.\n\nQué escribir\nOn: el estudiante ve la primera letra seguida de un espacio y escribe la palabra entera. Off: el hueco está vacío y el estudiante escribe la palabra sin ayuda. En ambos casos, escribe la palabra completa entre las respuestas aceptadas.\n\nComprobaciones\nCon la pista activa, cada palabra aceptada debe empezar por la misma primera letra. El ajuste forma parte del Exercise, así que el Audit lo lee del propio Exercise.\n\nEjemplo\nOn: é______ para école. Off: ______ para école.',
  'exerciseHelp.field.type_translation_to_source.accepted.body':
      'Define las traducciones completas en la lengua base aceptadas para el texto en la lengua de estudio.\n\nQué escribir\nRespuestas completas equivalentes en líneas separadas, en la lengua base. Las líneas vacías se ignoran. Se aplica la misma sintaxis que en Type the translation (to target): {} opcional, alternativas [a|b], grupos enlazados [*:a|b] con el mismo número de alternativas y ámbitos <> de reordenación.\n\nComprobaciones\nHace falta al menos una respuesta aceptada. Las expresiones malformadas se rechazan; la expansión es determinista y se limita a 128 respuestas. Declara explícitamente las respuestas equivalentes.\n\nEjemplo\nI would like a coffee.\nI’d like a coffee.',
  'exerciseHelp.field.type_translation_to_source.prompt.body':
      'El texto que el estudiante traduce a la lengua base.\n\nQué escribir\nUna frase o un pasaje en la lengua de estudio. Los saltos de línea pertenecen al mismo prompt; las respuestas aceptadas o las traducciones correctas van en sus propios campos.\n\nComprobaciones\nEscribe un texto no vacío en la lengua de estudio y respuestas completas equivalentes en la lengua base. Mantén el significado sin ambigüedad.\n\nEjemplo\nVorrei un caffè.',
  'exerciseHelp.field.answer_pictures.body':
      'Una imagen por respuesta.\n\nQué escribir\nUsa el selector bajo cada respuesta: una imagen plana de la biblioteca compartida, una imagen importada o una imagen del Course. Las imágenes se copian al Course. Marca Plural bajo una imagen cuando su respuesta indica varias cosas (gatti, gatos): el alumno ve copias superpuestas de la imagen, sin números ni palabras.\n\nComprobaciones\nCada respuesta necesita su imagen; si no, el Audit avisa. Las imágenes del Course viajan con el paquete del Course.\n\nEjemplo\n1. gatto: la imagen de un gato',
  'exerciseHelp.field.picture_answers.body':
      'El aspecto de las imágenes entre las que el alumno elige: el tamaño, la forma, cuántas hay en una fila y si una línea las rodea.\n\nQué escribir\nAs in Lesson Options sigue el curso (Course Editor › Lesson Options › Picture answers); cualquier otro valor es solo de este ejercicio. Sin una elección las imágenes son cuadrados grandes, dos por fila. Picture size: Large o Normal. Picture shape: Square, cropped, o Round. Pictures per row: de 1 a 3, o las que quepan. Picture border: Thin grey line, una línea gris fina que sigue la forma redonda o cuadrada y hace destacar una imagen clara, o None; un Course nuevo tiene la línea, los Courses creados antes no. Una última fila incompleta queda en el centro. Crop square bajo una imagen elige la parte que se muestra y el zoom, y guarda la copia recortada en el curso.\n\nComprobaciones\nNinguna.\n\nEjemplo\nLarge, Square, cropped, 2 por fila',
  'exerciseHelp.field.complete_text.missingWords.body':
      'Lo que va en cada hueco, en orden.\n\nQué escribir\nUna línea por cada hueco ___, en el orden en que aparecen. Una línea puede aceptar varias respuestas: [il|un] gatto acepta il gatto y un gatto; {il} gatto acepta gatto con o sin il.\n\nComprobaciones\nTantas líneas como huecos. Se rechazan alternativas malformadas. Las respuestas usan la normalización normal de Input.\n\nEjemplo\ncaffè\n[il|un] treno',
  'exerciseHelp.field.complete_text.prompt.body':
      'El texto que completa el estudiante; cada ___ es un hueco.\n\nQué escribir\nEscribe el texto y pon ___ (tres guiones bajos) donde va cada palabra o expresión que falta. Varias frases están bien.\n\nComprobaciones\nAl menos un hueco, y tantos huecos como líneas en Missing words.\n\nEjemplo\nAnna beve un ___ al bar. Poi prende ___.',
  'exerciseHelp.field.gap_blocks.tokens.body':
      'Bloques que no rellenan ningún hueco, ofrecidos junto a las respuestas.\n\nQué escribir\nUn bloque extra por línea. Pocos distractores funcionan mejor: se recomiendan 0, 1 o 2, menos en los primeros Rounds de una Lesson.\n\nComprobaciones\nUn distractor no debe repetir el texto de ninguna respuesta.\n\nEjemplo\nsempre',
  'exerciseHelp.field.missing_letters.prompt.body':
      'El texto completo con las letras que faltan marcadas entre guiones bajos.\n\nQué escribir\nEscribe el texto y pon las letras que ocultar entre guiones bajos, un par por hueco: My cat doesn’t dr_ink_ milk.\n\nComprobaciones\nAl menos un hueco, ninguno vacío. El estudiante ve un guion por cada letra oculta y escribe las letras.\n\nEjemplo\nIl ga_tt_o dor_me_ sul divano.',
  'exerciseHelp.field.dialogue_line.speaker.body':
      'Quién dice la línea.\n\nQué escribir\nEl narrador o uno de los personajes de Historia del Curso (Course Editor › Story characters).\n\nComprobaciones\nEl personaje debe existir en el Curso; el Audit señala el que falta.\n\nEjemplo\nAnna',
  'exerciseHelp.field.dialogue_line.prompt.body':
      'La línea en sí.\n\nQué escribir\nUna línea de diálogo, en la lengua de quien habla. Se muestra, se lee en voz alta o ambas cosas, según el modo.\n\nComprobaciones\nObligatoria.\n\nEjemplo\nBuongiorno! Un caffè, per favore.',
  'exerciseHelp.field.dialogue_line.lineMode.body':
      'Si el estudiante lee la línea, la escucha o ambas cosas.\n\nQué escribir\nText and audio, Text only o Audio only. Audio only convierte la línea en un paso de escucha; cuando el audio no está disponible se muestra el texto.\n\nComprobaciones\nNinguna.\n\nEjemplo\nText and audio',
  'exerciseHelp.field.dialogue_line.readAloud.body':
      'Cuándo se reproduce el audio de la línea.\n\nQué escribir\nStory default (la opción Read-aloud del Round), Automatic (suena cuando aparece la línea) u On request (el estudiante toca).\n\nComprobaciones\nNinguna.\n\nEjemplo\nStory default',
  'exerciseHelp.field.dialogue_line.textReveal.body':
      'Si el texto espera al audio.\n\nQué escribir\nImmediately, o After listening: el texto aparece cuando el audio se ha reproducido (solo con texto y audio).\n\nComprobaciones\nNinguna.\n\nEjemplo\nImmediately',
  'exerciseHelp.field.dialogue_line.language.body':
      'La lengua de la línea.\n\nQué escribir\nLa lengua de quien habla (predeterminada), o Target / Source para cambiarla solo en esta línea.\n\nComprobaciones\nNinguna.\n\nEjemplo\nSpeaker’s',
  'exerciseHelp.field.before_you_start.prompt.body':
      'Lo que el estudiante lee antes de que empiece el Round.\n\nQué escribir\nUnas frases: qué practica el Round, un consejo, un recordatorio, en la lengua que tus estudiantes leen mejor.\n\nComprobaciones\nObligatoria: una tarjeta vacía es un error del Audit.\n\nEjemplo\nEste Round practica los saludos.',
  'exerciseHelp.field.before_you_start.guidebookButton.body':
      'Si la tarjeta ofrece el GuideBook de la Lesson.\n\nQué escribir\nActivado o no. Los estudiantes ven Open GuideBook solo mientras el Curso usa GuideBooks (Lesson Options) y el GuideBook está publicado; Preview lo muestra también para un GuideBook en Draft.\n\nComprobaciones\nDesactivado mientras el Curso no usa GuideBooks.\n\nEjemplo\nActivado',
  'exerciseHelp.field.page.blocks.body':
      'Los bloques de la Page, de arriba abajo.\n\nQué escribir\nAñade bloques con Add block y ordénalos con las flechas. En párrafos, citas y listas escribe **negrita** y *cursiva*; una lista lleva un elemento por línea; \\* muestra un asterisco. Elige alineación y color para cada bloque de texto, tamaño y pie de foto para cada imagen, el texto hablado de un bloque de audio, y la etiqueta y la dirección https de un enlace de vídeo.\n\nComprobaciones\nUna Page sin contenido es un error del Audit; una marca sin cierre es un aviso; un enlace debe ser una dirección https.\n\nEjemplo\nHeading 1: Saludos',
  'exerciseHelp.field.story_cover.prompt.body':
      'Una línea de título opcional en la portada.\n\nQué escribir\nUna línea breve; el título de la Historia (opciones del Round) se muestra encima de la portada de todos modos.\n\nComprobaciones\nOpcional.\n\nEjemplo\nEn el café',
  'exerciseHelp.field.story_cover.image.body':
      'La imagen de portada.\n\nQué escribir\nUna imagen del Curso, de la Shared Image Library o una imagen integrada.\n\nComprobaciones\nRecomendada; una portada sin imagen muestra solo el título.\n\nEjemplo\nLa terraza de un café',
  'exerciseHelp.field.sort_into_groups.groups.body':
      'Los grupos y sus palabras.\n\nQué escribir\nUn grupo por línea: el nombre del grupo, dos puntos y luego sus palabras separadas por comas. Al menos dos grupos, cada uno con al menos una palabra.\n\nComprobaciones\nUna palabra solo puede estar en un grupo; una línea sin dos puntos, sin nombre o sin palabras se rechaza antes de Preview o Save.\n\nEjemplo\nAnimals: gatto, cane\nPlants: rosa, pino',
  'exerciseHelp.field.fill_the_slots.slots.body':
      'Las casillas y la palabra que rellena cada una.\n\nQué escribir\nUna casilla por línea: lo que ve el estudiante, un signo igual y luego la palabra. Al menos una casilla. Usa … o ___ para la parte que falta.\n\nComprobaciones\nCada línea necesita las dos partes. La misma palabra en dos casillas necesita “A word may fill more than one slot”.\n\nEjemplo\n… gatto = il\n… casa = la',
  'exerciseHelp.field.fill_the_slots.extraWords.body':
      'Palabras ofrecidas que no rellenan ninguna casilla.\n\nQué escribir\nUna palabra por línea; opcional.\n\nComprobaciones\nUna palabra extra no puede repetir la palabra de una casilla.\n\nEjemplo\nlo',
  'exerciseHelp.field.fill_the_slots.slotReuse.body':
      'Si una palabra puede rellenar varias casillas.\n\nQué escribir\nOff: cada palabra se ofrece una vez y rellena una casilla. On: la palabra se queda en el banco tras cada uso, así que la misma palabra puede ser la respuesta de varias casillas.\n\nComprobaciones\nNinguna.\n\nEjemplo\nOn, para “… cane = il” y “… libro = il”',
  'exerciseHelp.field.flashcard.readAloud.body':
      'Si la palabra se lee en voz alta y cuándo.\n\nQué escribir\nAutomatically (cuando aparece la palabra: en el anverso, o en el reverso de una tarjeta que muestra primero el significado), On request (el estudiante toca el altavoz) o No read-aloud. El texto leído es la palabra o expresión misma, salvo que Pronunciation TTS (if different) diga otra cosa, con el modo de audio del Course.\n\nComprobaciones\nNinguna. La lectura en voz alta nunca convierte la tarjeta en un ejercicio de audio.\n\nEjemplo\nOn request',
  'exerciseHelp.field.flashcard.tts.body':
      'Lo que la lectura en voz alta dice cuando debe diferir de la palabra o expresión.\n\nQué escribir\nDéjalo vacío: la lectura en voz alta dice la palabra o expresión de arriba. Escribe un texto solo cuando la forma hablada difiere, por ejemplo una abreviatura leída completa. Sin ruta de grabación; las grabaciones se gestionan en Course Audio Library.\n\nComprobaciones\nOpcional. Si se indica, el modo de audio del Course debe poder reproducirlo.\n\nEjemplo\ndottore (para la abreviatura Dott.)',
  'exerciseHelp.field.note_card.prompt.body':
      'El título de la tarjeta.\n\nQué escribir\nUn título breve, en la lengua que prefieras.\n\nComprobaciones\nObligatorio.\n\nEjemplo\n¿Tu o Lei?',
  'exerciseHelp.field.note_card.question.body':
      'La nota que el estudiante lee.\n\nQué escribir\nTexto sencillo; varios párrafos están bien.\n\nComprobaciones\nObligatoria. No hay respuesta ni puntuación; Continue cierra la tarjeta.\n\nEjemplo\nUsa Lei con personas que no conoces bien.',
  'exerciseHelp.field.picture_name.accepted.body':
      'Los nombres de lo que muestra la imagen que el estudiante puede escribir.\n\nQué escribir\nRespuestas completas en líneas separadas, con la sintaxis de Type the translation: {} opcional, alternativas [a|b], grupos enlazados [*:a|b], ámbitos <> de reordenación.\n\nComprobaciones\nAl menos una respuesta aceptada. La expansión se limita a 128 respuestas.\n\nEjemplo\n[il|un] gatto\ngatto',
  'exerciseHelp.field.picture_blocks.order.body':
      'El nombre de lo que muestra la imagen, en bloques de palabras.\n\nQué escribir\nUna palabra por línea, en el orden correcto; el estudiante recibe estos bloques mezclados, con los bloques de más.\n\nComprobaciones\nObligatorio, con la Exercise image. Los bloques unidos con espacios son la respuesta.\n\nEjemplo\nil\npane',
  'exerciseHelp.field.image_word.extraWords.body':
      'Bloques ofrecidos con la palabra que no forman parte de ella: distractores.\n\nQué escribir\nUna letra o sílaba por línea; opcional.\n\nComprobaciones\nSe recomiendan solo los bloques de la palabra: añade bloques extra a propósito, menos en los primeros Rounds de una Lesson. El Course Audit los muestra como Info. El estudiante debe dejarlos fuera.\n\nEjemplo\ne',
  'exerciseHelp.field.picture_blocks.extraWords.body':
      'Palabras ofrecidas con el nombre que no forman parte de él.\n\nQué escribir\nUna palabra por línea; opcional.\n\nComprobaciones\nPocos funcionan mejor: se recomiendan dos como máximo; se admiten más y el Course Audit los muestra como Info. El estudiante debe dejarlos fuera.\n\nEjemplo\nla',
  'exerciseHelp.field.picture_word_match.answers.body':
      'Las palabras de los pares; cada una recibe una imagen debajo.\n\nQué escribir\nUna palabra por línea, en la lengua de estudio. Al menos dos.\n\nComprobaciones\nCada palabra necesita su imagen; las palabras deben ser únicas.\n\nEjemplo\ngatto\ncane\ncasa',
  'exerciseHelp.field.sentence_order.order.body':
      'Las líneas de la historia o el diálogo, en el orden que el estudiante debe encontrar.\n\nQué escribir\nUna frase o línea por línea, en el orden correcto; el estudiante las recibe mezcladas. Las líneas que no pertenecen a nada van en Extra lines.\n\nComprobaciones\nAl menos dos líneas para publicar. El mismo texto dos veces cuenta como dos líneas.\n\nEjemplo\nAnna entra nel bar.\nOrdina un caffè.\nPaga e saluta.',
  'exerciseHelp.field.sentence_order.extraWords.body':
      'Líneas ofrecidas con las demás que no pertenecen a nada; el estudiante debe dejarlas fuera.\n\nQué escribir\nUna línea por línea. Pocas funcionan mejor: se recomiendan 0, 1 o 2.\n\nComprobaciones\nOpcionales. Deben ser plausibles pero claramente fuera de lugar.\n\nEjemplo\nIl treno parte alle nove.',
  'exerciseHelp.field.spell_heard.tts.body':
      'La palabra que el estudiante escucha y deletrea.\n\nQué escribir\nEscribe la palabra como texto; se lee con la voz de la lengua de estudio o se asocia a una grabación del Course.\n\nComprobaciones\nObligatoria. Las fichas deben deletrear exactamente esta palabra.\n\nEjemplo\ngatto',
  'exerciseHelp.field.spell_word.prompt.body':
      'La pista que nombra la palabra que deletrear.\n\nQué escribir\nUna pista breve en la lengua base: la palabra misma o una definición.\n\nComprobaciones\nObligatoria salvo que una imagen o una palabra hablada nombre la palabra.\n\nEjemplo\ncat (the animal)',
  'exerciseHelp.field.true_false.answers.body':
      'Las dos respuestas: la palabra para verdadero y la palabra para falso.\n\nQué escribir\nDos líneas en la lengua base, primero verdadero. QQL las prellena cuando conoce la lengua; puedes cambiar las palabras.\n\nComprobaciones\nExactamente dos líneas; el Audit avisa si hay más o menos.\n\nEjemplo\nVerdadero\nFalso',
  'exerciseHelp.field.true_false.question.body':
      'La afirmación que el estudiante juzga verdadera o falsa.\n\nQué escribir\nUna afirmación en la lengua de estudio, en texto sencillo. Hazla claramente verdadera o claramente falsa.\n\nComprobaciones\nObligatoria. El número de la respuesta correcta es 1 si la afirmación es verdadera y 2 si es falsa.\n\nEjemplo\nRoma è la capitale d’Italia.',
  'exerciseHelp.field.choice.question.body':
      'Lo que responde el estudiante: una pregunta, o una frase con un hueco que las respuestas completan.\n\nQué escribir\nUna pregunta, o una frase con ___ donde va la respuesta, en texto; una instrucción o el contexto van en Instruction or context. En Choose the answer (to target) las respuestas están en la lengua de estudio y la pregunta puede estar en cualquiera de las dos lenguas; en Choose the answer (to source), pregunta y respuestas están en la lengua base.\n\nComprobaciones\nObligatoria. Añade respuestas correspondientes y marca la correcta (o varias con Multiple correct answers).\n\nEjemplo\nWhich article goes with casa?\nIeri ___ al cinema. (con Instruction or context: Pick the verb form that fits.)',
  'exerciseHelp.field.choice.answers.body':
      'Alternativas visibles para el estudiante.\n\nQué escribir\nUna respuesta literal por línea, al menos dos. Se ignoran líneas vacías; la primera no vacía es la respuesta 1. La sintaxis de variantes no crea opciones.\n\nComprobaciones\nElige un Correct answer válido. Evita duplicados y distractores ambiguos. Select the image requiere una imagen por respuesta en el mismo orden.\n\nEjemplo\ncaffè\nacqua\npane',
  'exerciseHelp.field.choice.correct.body':
      'Indica la opción o las opciones correctas.\n\nQué escribir\nUn número entero contando desde 1 las líneas no vacías. Con Multiple correct answers, separa los números con comas, por ejemplo 1, 3.\n\nComprobaciones\nCada número debe estar entre 1 y la cantidad de respuestas. Revísalo al reordenar o borrar líneas.\n\nEjemplo\n2 elige la segunda línea no vacía.',
  'exerciseHelp.field.choice.requiredSelections.body':
      'Cantidad mínima de opciones que se deben elegir antes de comprobar una Choice múltiple.\n\nQué escribir\nUn entero entre 1 y la cantidad de respuestas, o déjalo vacío para usar la cantidad de correctas.\n\nComprobaciones\nCheck sigue desactivado hasta llegar a ese mínimo. Se pueden elegir más; para acertar debe coincidir el conjunto exacto.\n\nEjemplo\n2',
  'exerciseHelp.field.choice.gapLayout.body':
      'Frase fija con uno o más huecos que el estudiante rellena en orden tocando opciones.\n\nQué escribir\nEscribe la frase y pon cada palabra o expresión de respuesta entre guiones bajos: _answer_. Ejemplo: I _am_ going _to_ London. Las opciones que no responden a ningún hueco van en Distractor options (optional).\n\nComprobaciones\nHace falta al menos un hueco _…_ y cada uno debe contener texto. Un _ suelto no puede aparecer en otro lugar de la frase.\n\nEjemplo\nI _am_ going _to_ London.',
  'exerciseHelp.field.choice.tokens.body':
      'Opciones que no responden a ningún hueco.\n\nQué escribir\nUna opción extra por línea. Pocos distractores funcionan mejor: se recomiendan cero, una o dos, menos en los primeros Rounds de una Lesson.\n\nComprobaciones\nNo repitas el texto de una respuesta de hueco.\n\nEjemplo\nperhaps',
  'exerciseHelp.field.choice.tts.body':
      'Texto que escucha el estudiante.\n\nQué escribir\nEscribe las palabras habladas, no una ruta ni nombre de MP3. Varias líneas forman un pasaje. Course Audio Library usa On-Device TTS, Recorded MP3 o Hybrid y asocia grabaciones a palabras o expresiones exactas.\n\nComprobaciones\nLos ejercicios de escucha necesitan Audio text. Revisa Preview y los avisos de Audit sobre grabaciones faltantes.\n\nEjemplo\nVorrei un caffè, per favore.',
  'exerciseHelp.field.choice.image.body':
      'Añade una imagen al prompt o Context.\n\nQué escribir\nElige una imagen de Shared Image Library o deja un PNG, JPEG o WebP en {folderImageImports} y pulsa Import custom image. La importación copia los bytes sin redimensionar ni recortar y no añade la imagen a la biblioteca compartida.\n\nComprobaciones\nMáximo 300 KB; 256 × 256 píxeles y 15 KB son recomendaciones. Solo Image-prompt ordering la exige. Preview comprueba que se vea. Course JSON guarda la ruta, no los bytes.\n\nEjemplo\nassets/exercise_images/house.webp',
  'exerciseHelp.field.gap_choice.question.body':
      'Frase que se completa eligiendo un bloque.\n\nQué escribir\nSustituye la palabra o expresión por ___ (tres guiones bajos), por ejemplo Vorrei un ___, per favore. Escribe las opciones en líneas separadas.\n\nComprobaciones\nHace falta al menos un ___; más de uno genera Warning. Con la respuesta correcta, la frase debe tener al menos dos palabras.\n\nEjemplo\nVorrei un ___, per favore.',
  'exerciseHelp.field.gap_choice.correct.body':
      'Número de la única opción correcta.\n\nQué escribir\nUn entero contando desde 1 las líneas no vacías, no el texto ni un índice JSON.\n\nComprobaciones\nDebe estar dentro de la lista; Dialogue Response solo acepta 1 o 2. Revísalo al cambiar el orden.\n\nEjemplo\n2 elige la segunda línea no vacía.',
  'exerciseHelp.field.gap_choice.hint.body':
      'Pista útil para el estudiante.\n\nQué escribir\nTexto opcional; déjalo vacío si no hace falta. Los saltos de línea siguen en la misma pista.\n\nComprobaciones\nNo reveles la respuesta correcta ni repitas solo el prompt.\n\nEjemplo\nPiensa en una bebida caliente servida en taza pequeña.',
  'exerciseHelp.field.icon_choice.question.body':
      'Pregunta concreta que responde el estudiante.\n\nQué escribir\nUna pregunta en texto, aparte del Context de lectura, audio o diálogo. Los saltos de línea no crean preguntas nuevas.\n\nComprobaciones\nRead and answer requiere pregunta separada. Haz que coincida con la respuesta correcta.\n\nEjemplo\nHow are you?',
  'exerciseHelp.field.icon_choice.icons.body':
      'Asocia cada respuesta de Select the image a una imagen.\n\nQué escribir\nUna clave de icono o ruta assets/ incluida por línea, en el mismo orden que las respuestas. Se ignoran líneas vacías. Hay claves como water, home, coffee, person, hello, sun, moon, tree, bread, train y book.\n\nComprobaciones\nDebe haber tantas claves como respuestas. Una clave desconocida muestra un icono genérico: revisa cada opción con Preview. La imagen general del Exercise es distinta.\n\nEjemplo\ncoffee\nwater\nassets/exercise_images/house.webp',
  'exerciseHelp.field.script_recognition.scriptMode.body':
      'Elige cómo se reconoce un carácter o sílaba.\n\nQué escribir\nImage to text muestra imágenes y respuestas de texto. Text to image muestra texto y respuestas de imagen. Cambiar el modo conserva ambos grupos de campos durante esta edición; Save usa el modo seleccionado.\n\nComprobaciones\nAmbos usan Select con al menos dos opciones y exactamente una correcta.\n\nEjemplo\nMuestra varias formas manuscritas de 가 y pide elegir ga.',
  'exerciseHelp.field.script_recognition.scriptPrompt.body':
      'La pregunta o la frase que nombra el carácter que buscar entre las imágenes.\n\nQué escribir\nEscribe el carácter, la sílaba o el sonido, como pregunta o como frase. Las imágenes de respuesta van en sus campos.\n\nComprobaciones\nText to image requiere una pregunta o una frase, al menos dos opciones de imagen y una correcta.\n\nEjemplo\nChoose the character pronounced ga.',
  'exerciseHelp.field.script_recognition.scriptPromptImages.body':
      'Una o más representaciones del mismo carácter o sílaba.\n\nQué escribir\nAñade letra impresa, manuscrita u otras formas desde Image Bank o importando PNG, JPEG o WebP. Los bytes importados pertenecen al curso; no se guarda una ruta local absoluta.\n\nComprobaciones\nImage to text exige una imagen legible y dos opciones de texto. Cada imagen importada debe ocupar hasta 50 KB y medir como máximo 4096 píxeles por lado. Datos inválidos bloquean Save y Preview.\n\nEjemplo\n가 impresa y manuscrita sobre ga y na.',
  'exerciseHelp.field.script_recognition.scriptTextOptions.body':
      'Lecturas posibles de las imágenes.\n\nQué escribir\nUna lectura o etiqueta literal por opción. Los controles adyacentes añaden, borran o reordenan sin perder la identidad ni la opción correcta.\n\nComprobaciones\nImage to text necesita al menos dos textos no vacíos y una sola opción correcta. La sintaxis de variantes no se expande en Select.\n\nEjemplo\nOption 1: ga\nOption 2: na',
  'exerciseHelp.field.script_recognition.scriptImageOptions.body':
      'Imágenes entre las que elige el estudiante.\n\nQué escribir\nElige una imagen portátil de Image Bank o importada para cada opción. Reordenar conserva la identidad y la respuesta correcta.\n\nComprobaciones\nText to image necesita dos imágenes legibles y una correcta. Cada importada puede ocupar hasta 50 KB y medir como máximo 4096 píxeles por lado. Se rechazan rutas absolutas y datos inválidos.\n\nEjemplo\nPara ga, ofrece imágenes de 가 y 나.',
  'exerciseHelp.field.script_recognition.scriptCorrect.body':
      'Marca la única opción correcta.\n\nQué escribir\nSelecciona el círculo junto a ella. Elegir otra sustituye la anterior. Reordenarla conserva su estado; si la borras, elige otra.\n\nComprobaciones\nDebe haber exactamente una opción existente correcta. Un Draft puede estar incompleto, pero Preview y Save como Published la requieren.\n\nEjemplo\nMarca ga para la imagen 가.',
  'exerciseHelp.field.listening_choice.tts.body':
      'Escribe exactamente lo que debe oír el estudiante.\n\nQué escribir\nOn-Device TTS lee este texto sin archivo. Recorded MP3 busca grabaciones asociadas; Hybrid prueba una secuencia completa y después TTS. Escribe palabras, no ruta MP3. Para grabar, usa Course Editor > Audio Library, Import MP3 y Associate recording.\n\nComprobaciones\nLas grabaciones se guardan por lengua y pertenecen al Course. El backup de versión incluye las referenciadas; Course JSON no contiene bytes MP3.\n\nEjemplo\nBuongiorno, come stai?',
  'exerciseHelp.field.reading_comprehension.prompt.body':
      'Pasaje necesario para una pregunta de comprensión aparte.\n\nQué escribir\nUn texto que puede tener varias líneas o párrafos.\n\nComprobaciones\nDebe contener palabras; una o dos generan Warning y se recomiendan al menos tres. La pregunta debe evaluar su comprensión.\n\nEjemplo\nMaria prende il treno. Va a Roma.',
  'exerciseHelp.field.dialogue_response.prompt.body':
      'Situación para elegir la mejor respuesta de diálogo.\n\nQué escribir\nUna situación en la lengua de estudio; Question va aparte, con dos respuestas exactas.\n\nComprobaciones\nContext, Question y ambas respuestas deben estar completos; marca una correcta.\n\nEjemplo\nUn amico ti saluta al mattino.',
  'exerciseHelp.field.dialogue_response.answers.body':
      'Dos respuestas posibles a la situación.\n\nQué escribir\nExactamente dos líneas no vacías en la lengua de estudio, una respuesta completa por línea.\n\nComprobaciones\nCorrect response number debe ser 1 o 2. El orden visible se mezcla, pero la correcta no cambia.\n\nEjemplo\nBuongiorno!\nBuonanotte!',
  'exerciseHelp.field.contextual_comprehension.contextMode.body':
      'Modo de presentación del Context.\n\nQué escribir\nElige Text, Audio o Text and audio. Los modos de texto muestran Context text y Dialogue opcional; los de audio muestran Context audio text.\n\nComprobaciones\nDebe haber Context útil y Question con respuestas aparte. Una imagen sola no basta. Revisa el modo en Preview.\n\nEjemplo\nText: Marta takes the train to work every morning.',
  'exerciseHelp.field.contextual_comprehension.context.body':
      'Pasaje o situación para responder la pregunta.\n\nQué escribir\nTexto normal, con párrafos si ayudan. Usa Structured dialogue para turnos identificados; Question va en otro campo.\n\nComprobaciones\nHace falta texto, audio o diálogo utilizable. Con Text and audio, ambas versiones deben dar el Context previsto.\n\nEjemplo\nMarta takes the train to work every morning.',
  'exerciseHelp.field.contextual_comprehension.dialogue.body':
      'Context presentado como turnos de hablantes.\n\nQué escribir\nUn turno por línea como Speaker: text. Los primeros dos puntos separan hablante y texto. Deja vacío si no hay diálogo.\n\nComprobaciones\nCada turno necesita hablante y texto; las etiquetas no crean voces separadas.\n\nEjemplo\nJane: Are you coming?\nJim: I changed my mind.',
  'exerciseHelp.field.type_translation.prompt.body':
      'Texto que traduce el estudiante.\n\nQué escribir\nUna frase o pasaje en la lengua base. Los saltos de línea forman parte del mismo prompt; las traducciones van en sus campos.\n\nComprobaciones\nDebe haber texto y respuestas completas equivalentes en la lengua de estudio, sin ambigüedad.\n\nEjemplo\nI would like a coffee.',
  'exerciseHelp.field.type_translation.accepted.body':
      'Traducciones completas aceptadas.\n\nQué escribir\nUna respuesta equivalente por línea. Puedes usar texto opcional {Io}, alternativas [prendo|vorrei], grupos enlazados [*:il|i] [*:tuo|tuoi] y orden intercambiable (non arrivo <> oggi). Los grupos enlazados deben ser al menos dos y tener igual cantidad de opciones. Usa minúsculas salvo nombres propios.\n\nComprobaciones\nSe necesita una respuesta. Se rechazan expresiones inválidas o más de 128 expansiones; se eliminan duplicados. La sintaxis no inventa traducciones.\n\nEjemplo\n{Io} [prendo|vorrei] un cappuccino',
  'exerciseHelp.field.build_translation.tokens.body':
      'Bloques para construir las traducciones correctas.\n\nQué escribir\nUn bloque literal por línea. Repite la línea si una respuesta necesita esa palabra varias veces. Con Inline gaps, este campo pasa a Extra distractor blocks: las respuestas de hueco están en _answer_.\n\nComprobaciones\nCada traducción debe poder formarse; pocos distractores funcionan mejor: se recomienda que sobren como máximo dos bloques, menos en los primeros Rounds de una Lesson; se admiten más. La sintaxis de variantes no se expande.\n\nEjemplo\nIo\nprendo\nvorrei\nun\ncaffè',
  'exerciseHelp.field.build_translation.correctTranslation.body':
      'Una respuesta literal completa para Build the translation.\n\nQué escribir\nUna frase en la lengua de estudio por entrada. Usa Add correct translation para añadir otra y el control de arrastre para ordenarlas.\n\nComprobaciones\nHace falta una respuesta no vacía. Deben ser distintas tras normalizar mayúsculas, espacios y puntuación final y construibles con bloques disponibles. No hay variantes, similitud ni tolerancia a erratas.\n\nEjemplo\nIo vorrei un caffè.',
  'exerciseHelp.field.build_translation.gapLayout.body':
      'Frase fija con uno o más huecos que el estudiante rellena con palabras, una por hueco.\n\nQué escribir\nEscribe la frase fija y pon cada palabra o expresión de respuesta entre guiones bajos: _answer_. Ejemplo: I _am_ going _to_ London. Cada segmento _…_ es a la vez el hueco y su respuesta correcta. Las palabras distractoras que no rellenan ningún hueco van en Extra distractor words (optional).\n\nComprobaciones\nHace falta al menos un hueco _…_ y cada uno debe contener texto. Un _ suelto no puede aparecer en otro lugar de la frase.\n\nEjemplo\nI _am_ going _to_ London.',
  'exerciseHelp.field.translation_choice_to_target.question.body':
      'Texto en la lengua base que se traduce.\n\nQué escribir\nUna palabra, frase u oración. No escribas la instrucción: QQL añade Choose the correct [Target language] translation.\n\nComprobaciones\nEs obligatorio, con opciones en la lengua de estudio y exactamente una correcta.',
  'exerciseHelp.field.translation_choice_to_target.answers.body':
      'Traducciones entre las que se elige.\n\nQué escribir\nDe dos a cinco traducciones completas en la lengua de estudio, una por línea. Se ignoran líneas vacías; el orden visible se mezcla.\n\nComprobaciones\nNo repitas frases tras normalizar mayúsculas, espacios y puntuación final. Marca una correcta y usa distractores plausibles.',
  'exerciseHelp.field.translation_choice_to_target.correct.body':
      'Número de la única opción correcta.\n\nQué escribir\nUn entero contando desde 1 las líneas no vacías.\n\nComprobaciones\nDebe estar entre 1 y la cantidad de respuestas. Revísalo al reordenar o borrar líneas.',
  'exerciseHelp.field.translation_choice_to_target.image.body':
      'Imagen opcional del prompt o Context.\n\nQué escribir\nElige una imagen de Shared Image Library o importa un PNG, JPEG o WebP con Import custom image desde {folderImageImports}. Se copia sin cambiar bytes y no entra en la biblioteca compartida.\n\nComprobaciones\nMáximo 300 KB; 256 × 256 píxeles y 15 KB son recomendaciones. Preview debe mostrarla. Course JSON guarda la ruta, no los bytes.',
  'exerciseHelp.field.translation_choice_to_source.question.body':
      'Texto en la lengua de estudio que se traduce.\n\nQué escribir\nUna palabra, frase u oración. QQL añade Choose the correct [Source language] translation automáticamente. Puede reproducirse con TTS, pero el Exercise no lo requiere.\n\nComprobaciones\nEs obligatorio, con opciones en la lengua base y una correcta.',
  'exerciseHelp.field.translation_choice_to_source.answers.body':
      'Traducciones en la lengua base entre las que se elige.\n\nQué escribir\nDe dos a cinco traducciones completas, una por línea. El orden visible se mezcla.\n\nComprobaciones\nNo dejes opciones vacías ni repitas frases tras normalizar; marca una sola correcta y usa distractores claros.',
  'exerciseHelp.field.fill_blank.question.body':
      'Palabra o frase que se completa escribiendo.\n\nQué escribir\nUna palabra o frase incompleta con hueco visible si ayuda. En Accepted answers escribe lo que debe teclear el estudiante, no opciones para elegir.\n\nComprobaciones\nHace falta una respuesta aceptada. Este preset no revela automáticamente la primera letra.\n\nEjemplo\nVorrei un ___.\nAccepted answer: caffè',
  'exerciseHelp.field.fill_blank.accepted.body':
      'Texto completo admitido para llenar el hueco.\n\nQué escribir\nUna respuesta equivalente por línea. Se admiten {Io} opcional, [prendo|vorrei], grupos enlazados [*:il|i] [*:tuo|tuoi] y cambios de orden (non arrivo <> oggi). Usa minúsculas salvo nombres propios.\n\nComprobaciones\nSe necesita una respuesta. Expresiones inválidas o más de 128 expansiones se rechazan; se eliminan duplicados. La sintaxis no inventa traducciones.\n\nEjemplo\ncaffè\nun caffè',
  'exerciseHelp.field.fill_blank.tts.body':
      'Texto opcional de pronunciación de la frase completa.\n\nQué escribir\nUna frase con la respuesta incluida, o déjalo vacío. Es texto para hablar, no ruta de grabación.\n\nComprobaciones\nDebe corresponder a la frase incompleta y las respuestas. Prueba la pronunciación en Preview.\n\nEjemplo\nVorrei un caffè.',
  'exerciseHelp.field.type_missing_word.prompt.body':
      'La palabra ausente completa; la primera letra se muestra como pista cuando Show the first letter está activo.\n\nQué escribir\nUna frase con exactamente un hueco ___ y palabras completas aceptadas, una por línea. QQL obtiene automáticamente el primer grafema Unicode; el estudiante escribe la palabra completa.\n\nComprobaciones\nCon la pista activa, todas las respuestas deben compartir exactamente ese primer grafema. La pista no se añade a la respuesta.\n\nEjemplo\nJe vais à l’___. Respuesta: école. El estudiante ve é______ y escribe école.',
  'exerciseHelp.field.listening_spelling.missingWords.body':
      'Otras formas de escribir lo que oye el estudiante; Audio text siempre se acepta.\n\nQué escribir\nDéjalo vacío cuando Audio text solo se escribe de una manera. Si no, una grafía completa por línea: todo el texto oído, no una sola palabra. Alternativas dentro de una línea: alle [9|nove]. Mayúsculas, puntuación y espacios se ignoran de todos modos.\n\nComprobaciones\nOpcional. Cada línea debe tener las mismas palabras que se oyen; no aceptes palabras que no se oyen. Se rechazan alternativas malformadas.\n\nEjemplo\narrivo alle 8',
  'exerciseHelp.field.missing_word.prompt.body':
      'Transcripción completa desde la que se crean huecos.\n\nQué escribir\nIncluye las palabras que se ocultarán. Usa texto normal, sin puntos o guiones de hueco; los saltos de línea forman el mismo pasaje.\n\nComprobaciones\nCada Missing word debe aparecer en Passage transcript. Audio text debe coincidir con lo que se oye.\n\nEjemplo\nVorrei un caffè, per favore.\nMissing word: caffè',
  'exerciseHelp.field.missing_word.missingWords.body':
      'Palabras o expresiones ocultas en la transcripción.\n\nQué escribir\nUna palabra o expresión literal por línea. Varias líneas crean varios huecos, no respuestas alternativas; no pongas marcadores en la transcripción.\n\nComprobaciones\nAl menos una entrada y todas presentes en Passage transcript, sin distinguir mayúsculas. Los duplicados generan Warning. Aquí no se expande sintaxis de variantes.\n\nEjemplo\ncaffè\nper favore',
  'exerciseHelp.field.instruction.body':
      'Una línea opcional en la lengua del estudiante: qué hacer, la situación o el significado que necesita el ejercicio.\n\nQué escribir\nUna línea en la lengua del estudiante, o nada. En un Round ocupa el lugar de la línea de instrucciones estándar bajo el encabezado; déjala vacía para conservar esa línea. Puede describir la escena (Anna va al mercado por la mañana) o dar el significado (Anna lee un libro). La pregunta, la frase y las respuestas van en sus propios campos.\n\nComprobaciones\nOpcional. Se guarda sin lengua, así que nunca convierte el ejercicio en una traducción. Debe corresponder al resto del ejercicio y no revelar la respuesta.\n\nEjemplo\nOrdena el diálogo en el bar.',
  'exerciseHelp.field.matching.pairs.body':
      'Elementos de las dos columnas para relacionar.\n\nQué escribir\nUn par por línea como left = right. El primer signo igual separa los lados.\n\nComprobaciones\nHace falta al menos un par con ambos lados y separador. Corrige líneas incompletas antes de Preview o Save.\n\nEjemplo\ncasa = house\npane = bread',
  'exerciseHelp.field.word_match.pairs.body':
      'Relaciona palabras de la lengua base con sus traducciones.\n\nQué escribir\nAl menos dos líneas no vacías como source = target (tres es lo habitual); el primer igual separa los lados.\n\nComprobaciones\nCada par necesita ambos lados y correspondencia única, sin ambigüedad.\n\nEjemplo\nhouse = casa\nbread = pane\nwater = acqua',
  'exerciseHelp.field.super_match.pairs.body':
      'Relaciona palabras de la lengua de estudio, como sinónimos u opuestos.\n\nQué escribir\nExactamente tres líneas left = right, ambos lados en la lengua de estudio. Indica la relación en Instruction or context, en la lengua del estudiante.\n\nComprobaciones\nCada par necesita separador y debe seguir la misma relación sin ambigüedad.\n\nEjemplo\ngrande = piccolo\ncaldo = freddo\naperto = chiuso',
  'exerciseHelp.field.audio_match.pairs.body':
      'Relaciona tres audios de la lengua de estudio con sus textos visibles.\n\nQué escribir\nExactamente tres líneas audio text = visible text. El texto visible puede ser la misma lengua o traducción. No hay distractores.\n\nComprobaciones\nAmbos lados son obligatorios y únicos, incluso tras ignorar solo mayúsculas o puntuación. Usa Course Audio Library para grabaciones.\n\nEjemplo\ncasa = house\npane = bread\nacqua = water',
  'exerciseHelp.field.word_order.tokens.body':
      'Bloques para ordenar la frase.\n\nQué escribir\nUn bloque literal en la lengua de estudio por línea. Repite líneas para palabras repetidas. En Inline gaps este campo se llama Extra distractor blocks; las respuestas vienen de {answer} en Sentence with gaps.\n\nComprobaciones\nIncluye cada bloque de Correct sentence. Pocos distractores funcionan mejor: se recomiendan hasta dos no usados, menos en los primeros Rounds de una Lesson; se admiten más. Conserva escritura y puntuación interna.\n\nEjemplo\nIo\nbevo\nun\ncaffè\ntè',
  'exerciseHelp.field.word_order.order.body':
      'Orden correcto de los bloques.\n\nQué escribir\nUn bloque por línea, no toda la frase en una línea. Se unen con espacios. No se usa con Inline gaps, donde las respuestas están en _answer_.\n\nComprobaciones\nCada línea debe coincidir con un bloque disponible, incluidas repeticiones. Es un orden literal: no se expanden variantes.\n\nEjemplo\nIo\nbevo\nun\ncaffè',
  'exerciseHelp.field.image_word.order.body':
      'Los bloques que forman la palabra, en orden.\n\nQué escribir\nUna letra o sílaba por línea, en el orden de la respuesta; el estudiante recibe exactamente estos bloques, mezclados. Repite una línea para una letra que aparece dos veces. Los bloques se unen sin espacios.\n\nComprobaciones\nAl menos dos bloques. Los bloques que no forman parte de la palabra van en Extra blocks. Spell the word in the picture necesita además una Exercise image.\n\nEjemplo\nca\nsa\nEstos bloques forman casa.',
  'exerciseHelp.field.flashcard.prompt.body':
      'La palabra o expresión que enseña la tarjeta, en la lengua de estudio.\n\nQué escribir\nUna palabra o expresión en la lengua que se aprende. La traducción va en el campo de abajo; Read aloud, si está activo, lee este texto.\n\nComprobaciones\nObligatoria. Flashcard es presentación y no tiene una respuesta puntuada normal.\n\nEjemplo\nbuongiorno',
  'exerciseHelp.field.flashcard.question.body':
      'La traducción o el significado, en la lengua base.\n\nQué escribir\nUna traducción o explicación en texto en la lengua de los estudiantes; varias líneas siguen siendo una explicación.\n\nComprobaciones\nUna traducción vacía genera Warning de Audit. Comprueba que coincida con la palabra de arriba.\n\nEjemplo\ngood morning',
  'exerciseHelp.field.flashcard.answers.body':
      'Ejemplo de uso de la palabra de Flashcard.\n\nQué escribir\nPrimera línea no vacía: frase de ejemplo. Segunda línea opcional: traducción. La vista del estudiante añade Usage: automáticamente.\n\nComprobaciones\nSin frase de uso, Audit muestra Warning. Son datos de presentación, no respuestas a elegir.\n\nEjemplo\nBuongiorno, Maria!\nGood morning, Maria!',
};
