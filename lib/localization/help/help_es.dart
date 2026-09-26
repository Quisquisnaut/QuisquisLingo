/// Spanish text for the standalone Help pages, App Info and Course Info.
/// QQL command, setting, mode and data labels remain in English so readers can
/// find the same labels in the current interface.
const Map<String, String> helpEs = {
  'editorHelp.coursesInLearnerMode.title': 'Cursos en el modo de estudio',
  'editorHelp.coursesInLearnerMode.body':
      'Course Library, al final de Course Selector, reúne todos los cursos del dispositivo. Por defecto oculta los cursos no disponibles o Draft. Sort by y Expanded / Compact solo cambian la vista. Add to my courses añade un curso compartido a tu lista sin darte permiso para editarlo; Remove from my courses lo quita solo para tu perfil y conserva el progreso, salvo que elijas Reset my progress. Incluso entonces se conservan los XP, días de estudio y streak. Un Admin solo puede usar Remove Publisher Course from device si ningún otro perfil incluye ese curso. Import Course vuelve al estudio. Continue to Editor prepara un curso nuevo, que solo se guarda con Confirm course changes. Change course muestra los cursos Published de tu biblioteca personal. La página de estudio retoma la última Lesson Published activa; el selector de Section abre sus bloques consecutivos.',
  'editorHelp.courseOrigin.title': 'Origen del curso',
  'editorHelp.courseOrigin.body':
      'Los cursos oficiales incluidos son copias de origen verificadas e inmutables. Un Publisher Course importado necesita una firma Ed25519 válida de un editor aprobado. Los cursos externos que no se pueden verificar se conservan como Verification required y no llegan al estudiante. Los Custom Course se crean o importan sin origen oficial. Los cursos oficiales se abren en Official course - read only: puedes consultar Course Info, Audit, Preview, Version History y su contenido. Fork solo está disponible cuando derivativeWorksPolicy permite derivados; conserva el origen, pero crea IDs e historial propios. Copy as New Course inicia una línea independiente.',
  'editorHelp.temporarySampleContent.title': 'Contenido de muestra temporal',
  'editorHelp.temporarySampleContent.body':
      'Course Editor empieza en View only si aún no se ha elegido un modo de acceso para ese curso. Usa Edit solo para el curso que vayas a modificar. TEMPORARY SAMPLE indica material de desarrollo o demostración. View Course Info mantiene esa descripción. Sustituye las muestras por contenido revisado antes de publicar o distribuir el curso.',
  'editorHelp.courseEditorLockAndStructure.title':
      'Acceso y estructura de Course Editor',
  'editorHelp.courseEditorLockAndStructure.body':
      'El control de acceso está en la raíz de Course Editor. Locked mantiene visible esa pantalla y bloquea Lessons. View only es el modo inicial: permite Search, Help, Show/Hide IDs, Preview y Audit, y abre el formulario de Exercise en solo lectura. Inspection mode muestra primero la vista técnica; su control Inspection puede mostrar el formulario normal, todavía en solo lectura. Edit permite crear contenido solo si ya tienes permiso como Course Maintainer o miembro de Assigned Team. El control no concede permisos. Los cursos oficiales y otros usuarios no autorizados solo ofrecen los modos de consulta. Show one-time notices again restablece el aviso inicial sin cambiar el modo. Cada Lesson conserva su GuideBook y Duel. Duplicar una Lesson, Round o Exercise crea nuevos IDs y contenido Draft. El tipo de Exercise no se puede cambiar después de crearlo.',
  'editorHelp.courseEditorSearch.title': 'Buscar en Course Editor',
  'editorHelp.courseEditorSearch.body':
      'Search aparece en Lessons, Lesson, Rounds y Round cuando Course Editor no está en Locked. En Lessons busca en todo el curso; en Lesson y Rounds, en la Lesson actual; en Round, solo en ese Round. Admite palabras completas, frases contiguas e IDs de Exercise completos o parciales, sin distinguir mayúsculas ni acentos. Exercise Type empieza en All exercise types. Los resultados muestran Lesson, Round, tipo, fragmento e ID cuando Internal IDs está visible. View only abre el formulario en solo lectura; Inspection mode, la vista técnica; Edit, el formulario editable. Search no modifica el curso.',
  'editorHelp.optionalLessonLearningPaths.title':
      'Rutas opcionales de la Lesson',
  'editorHelp.optionalLessonLearningPaths.body':
      'Use GuideBook y Create Duels están en Lessons y empiezan en ON. Desactivar Use GuideBook conserva el contenido, el estado Draft y las referencias, pero oculta sus acciones al estudiante y en Preview. Solo se omite LESSON_GUIDEBOOK_EMPTY; los errores de contenido siguen en Course Audit. Create Duels usa 25 Exercises aptos y distintos. Si está desactivado o faltan ejercicios, no aparece la tarjeta Duel. DUEL_UNAVAILABLE es Info solo con Create Duels en ON. Ninguna de las dos opciones borra contenido, victorias, completados ni XP.',
  'editorHelp.sectionAssignmentsAndNames.title':
      'Asignación y nombres de Section',
  'editorHelp.sectionAssignmentsAndNames.body':
      'El selector de Section ofrece No section, los nombres existentes, Add new section... y Manage sections.... Los nombres nuevos se recortan y no pueden quedar vacíos. No puedes borrar un nombre que usa una Lesson; cambia primero sus asignaciones. También se protege el nombre elegido en una Lesson aún sin guardar. Una Lesson nueva hereda la Section de la Lesson anterior, si la hay. No section borra la asignación. Las asignaciones consecutivas forman los bloques visibles; Section no tiene IDs, progreso ni desbloqueos propios.',
  'editorHelp.courseFlagSources.title': 'Origen de la bandera del curso',
  'editorHelp.courseFlagSources.body':
      'Create new course y Course Info Editor comparten el selector de banderas. Distingue QQL FlagPainter Flag, WORLD Flag y Custom Flag, y ofrece Upload custom flag y ambos catálogos. Puedes buscar por nombre, alias, ID o código. Abrir, buscar o cancelar no cambia nada; elegir una bandera, Use Automatic o Upload custom flag sí cambia la selección de la copia de trabajo. Use Automatic prefiere la bandera QQL asociada y después la WORLD principal. WORLD Flags guarda worldFlagId; QQL FlagPainter Flags, flagCode; una bandera personalizada guarda PNG validado en flagImageBase64.',
  'editorHelp.oneCourseEditorTransaction.title':
      'Una sola transacción en Course Editor',
  'editorHelp.oneCourseEditorTransaction.body':
      'Un Custom Course se abre como copia de trabajo junto a una instantánea inmutable de lo guardado. View only e Inspection mode no la modifican. En Edit, Course Info Editor y los editores de Lesson, Round, Exercise y GuideBook solo cambian esa copia. Save y Save as draft guardan elementos en ella; no cambian lo que ve el estudiante, no crean backup ni aumentan la versión. Un formulario de Exercise sin guardar ofrece Keep editing, Discard changes, Save as draft o Save. Discard changes afecta solo a ese formulario. Salir de Edit con cambios pendientes pide confirmar o cancelar. La confirmación final aparece solo al salir del Course Editor principal.',
  'editorHelp.provisionalAndExplicitParentDrafts.title':
      'Draft provisionales y explícitos',
  'editorHelp.provisionalAndExplicitParentDrafts.body':
      'Una Lesson o Round creados automáticamente pueden ser Draft provisionales. Su distintivo azul incluye el contenedor aunque todos los hijos tengan borde verde de Audit. Un Round provisional puede pasar a Published al guardar Exercises revisados si todo su contenido obligatorio está listo. Una Lesson provisional también necesita Rounds Published y, con Use GuideBook en ON, un GuideBook Published y válido. La reconciliación sigue los cambios de la copia de trabajo, pero nunca publica un Exercise o GuideBook por ti. Save as draft hace explícito el Draft y desactiva esa promoción automática. Los Draft importados, copiados o antiguos siguen necesitando su propio Save. Nada llega a los estudiantes antes de Confirm course changes.',
  'editorHelp.confirmOrCancelCompleteCourse.title':
      'Confirmar o cancelar el curso completo',
  'editorHelp.confirmOrCancelCompleteCourse.body':
      'Al salir del Course Editor principal se compara toda la copia de trabajo con el curso original. Si son iguales, se cierra. Si hay cambios, un único diálogo ofrece Confirm course changes o Cancel course changes y una nota de versión opcional. Confirm crea y verifica un backup completo, aumenta la versión interna exactamente en uno y guarda la copia completa. Cancel descarta todo sin backup ni aumento de versión. Si falla el backup o el guardado, el editor sigue abierto y el curso guardado no cambia.',
  'editorHelp.localCourseEditsAndBackups.title':
      'Cambios locales y backups del curso',
  'editorHelp.localCourseEditsAndBackups.body':
      'Antes de confirmar un cambio en un Custom Course existente, QQL archiva la versión completa en su almacenamiento privado, en una carpeta por cada Course ID. El manifiesto incluye Course Model v11, Maintainer, Assigned Team, origen, versiones, autores, fecha UTC, notas opcionales, checksum y audios referenciados. Los backups no se eliminan automáticamente. Version History muestra la versión actual y los backups verificados del más nuevo al más antiguo, con Open backup folder y Export JSON. Solo el historial custom permite Restore into working copy; también requiere la confirmación final para guardar. El historial oficial conserva solo los orígenes del editor.',
  'editorHelp.androidDeviceBackupTechnical.title':
      'Backup del dispositivo Android (técnico)',
  'editorHelp.androidDeviceBackupTechnical.body':
      'QQL no tiene cuenta ni servidor. En Android, Auto Backup sigue activado para recuperar perfiles, progreso, XP, streaks, Review, cursos locales, Teams, ajustes, el verificador de Access PIN y User Recovery Key tras perder o cambiar de teléfono. Access PIN es una protección de acceso casual, no una barrera de seguridad. Image Banks, imágenes importadas y MP3 quedan fuera del backup en la nube por capacidad: el límite de Android es 25 MB y superarlo puede desactivar el backup completo. Conserva tus archivos originales y el Course JSON exportado. La transferencia directa entre teléfonos sí mueve esos medios. QQL no sube datos por sí mismo. Las reglas están en res/xml/data_extraction_rules.xml para API 31+ y res/xml/backup_rules.xml para API 30−; deben cambiarse juntas. Un reset local no puede borrar un backup que Android ya haya hecho.',
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
      'Original Course Creator, Course Maintainer, Assigned Team, Authors / Contributors, Rights Holder, License y el origen de Fork o Merge son datos separados. Todo Custom Course v11 tiene un creador original inmutable y un Maintainer individual. Solo ese Maintainer puede transferir el cargo o asignar y revocar un Team. Él y los miembros actuales de Assigned Team pueden administrar el contenido; los Team Leader gestionan miembros y roles del Team. Estos permisos solo rigen dentro de QQL: los créditos, derechos y origen no conceden acceso ni definen derechos de autor. Un usuario externo no puede modificar ni usar Copy as New Course; Fork depende de la licencia. Los cursos incluidos se consultan en el mismo Editor en solo lectura.',
  'editorHelp.importCustomCourse.title': 'Importar un curso personalizado',
  'editorHelp.importCustomCourse.body':
      'Copia un Course ZIP compatible en {folderCourseImports}/import.zip o, si no tiene medios, un Course Model v11 JSON en import.json. Deja solo uno. El ZIP suele contener course.json, qql-course-package.json y media/ en la raíz; también acepta una carpeta única con el mismo nombre que el ZIP sin .zip, con un aviso. En Course Studio, abre Course Import y elige Quick Import. QQL comprueba todo el paquete y Course Audit antes de instalar. Los Error bloquean; los Warning se muestran. Las imágenes de Shared Image Library viajan con el curso, sin añadirse a la biblioteca del dispositivo receptor. Un Publisher Course requiere firma aprobada. El archivo original permanece en {folderCourseImports}. JSON debe ser UTF-8 y de hasta 10 MB; el ZIP, de hasta 300 MB comprimido y expandido. No se migran formatos anteriores.',
  'editorHelp.exportCustomCourse.title': 'Exportar un curso personalizado',
  'editorHelp.exportCustomCourse.body':
      'Quick Export en Export Course guarda el JSON completo de Course Model v11 y las imágenes y grabaciones propias referenciadas en un ZIP en {folderCourseExports}. Los medios incluidos con la app siguen viniendo de QQL. Las imágenes de Shared Image Library usadas por el curso viajan como medios del curso con su ID, etiqueta, categoría, tags, origen y atribución disponible; importar el ZIP no las añade a la biblioteca compartida del destino. El JSON conserva creador, Maintainer, Team, autores, derechos, License, origen, estados Draft/Published y versión. Fork conserva la línea de origen; Copy as New Course crea otra. Save as… puede guardar el mismo ZIP mediante el diálogo del sistema.',
  'editorHelp.importCustomFlag.title': 'Importar una bandera personalizada',
  'editorHelp.importCustomFlag.body':
      'Copia un PNG o JPEG válido en {folderCourseFlagImports} como flag.png, flag.jpg o flag.jpeg y pulsa Upload custom flag. Si hay varios, QQL usa el primero en ese orden. Límite: 2 MB; dimensiones entre 64 × 40 y 4096 píxeles por lado. QQL verifica el formato y reduce proporcionalmente las imágenes de más de 256 píxeles en su lado mayor. No agranda las pequeñas, no recorta ni añade fondo cuadrado. Conserva la transparencia PNG y convierte el primer fotograma a PNG. Los datos quedan en el Course y sobreviven al exportar, importar o duplicar el JSON. El archivo original permanece. Si falta, está dañado, supera los límites o falla la conversión, la importación se detiene.',
  'editorHelp.generateRoundsFromLessonGuidebook.title':
      'Generar Rounds desde GuideBook',
  'editorHelp.generateRoundsFromLessonGuidebook.body':
      'En una Lesson, elige Generate Rounds from GuideBook. Se usan solo pares de vocabulario y ejemplos de su GuideBook; hacen falta al menos tres pares válidos. Elige 1–12 Rounds y 1–15 Exercises por Round (por defecto 6 y 8). Revisa las cantidades, la progresión de dificultad y los tipos previstos antes de generar. Los primeros borradores favorecen reconocimiento guiado, los intermedios añaden construcción y contexto y los últimos, producción más libre. Los Rounds generados siguen en Draft: revísalos, edítalos, usa Preview y apruébalos expresamente antes de añadir copias con IDs nuevos. La corrección didáctica requiere revisión humana.',
  'editorHelp.exerciseCreationWizard.title': 'Exercise Creation Wizard',
  'editorHelp.exerciseCreationWizard.body':
      'En un Round, Exercise Wizard está junto a New exercise. Elige de 1 a 30 Exercises y Balanced mix, Random mix, categorías, tipos concretos o un patrón repetido. Revisar el plan no crea ejercicios. Después de confirmar, cada paso abre el editor normal de su preset. Save valida y mantiene el paso; Preview vuelve al mismo borrador; Next valida y avanza; Finish devuelve los ejercicios creados en orden. Si cancelas tras guardar algunos, decide si conservar solo los válidos ya guardados. No se insertan marcadores futuros o inválidos.',
  'editorHelp.duplicateCopyMoveExercises.title':
      'Duplicar, copiar y mover ejercicios',
  'editorHelp.duplicateCopyMoveExercises.body':
      'Duplicate inserta una copia independiente con ID nuevo tras el original. Move Exercise to… y Copy Exercise to… eligen Course > Lesson > Round dentro de la copia de trabajo; Move Round to… y Copy Round to… eligen una Lesson. Move conserva ID, contenido y estado Draft/Published y quita el original de su padre anterior. Copy crea IDs nuevos en todo el contenido propio y ajusta sus referencias; las copias empiezan en Draft. Las referencias a imágenes y audios se conservan y sus archivos permanecen en la carpeta del Course. Nada se guarda definitivamente antes de Confirm course changes.',
  'editorHelp.exercisePreviewAndNavigation.title':
      'Preview y navegación del Exercise',
  'editorHelp.exercisePreviewAndNavigation.body':
      'Preview junto a Inspection y Save usa el formulario actual, incluso sin guardar o en Draft, con la presentación del estudiante. No guarda contenido ni escribe progreso, XP, streak, Review o Duel. Inspection solo cambia la vista técnica local; al volver, los valores del formulario siguen intactos. El formulario es editable solo con Edit y permisos reales. Si faltan datos para Preview, aparece una validación sin perder cambios. Previous y Next siguen el orden del Round y se detienen en sus extremos. Back y la navegación protegen los cambios pendientes con Keep editing, Discard changes, Save as draft o Save. Aquí Save solo cambia la copia de trabajo. Las rutas muestran Course, Lesson, Round y Exercise legibles.',
  'editorHelp.fieldHelpAndUntitledRounds.title':
      'Ayuda de campos y Rounds sin título',
  'editorHelp.fieldHelpAndUntitledRounds.body':
      'Usa Help junto a un campo de Exercise para ver su función, cantidad de entradas, formato, validación y ejemplos. Context mode, cada entrada de traducción correcta y la imagen tienen ayuda propia; Exercise Help cubre el preset completo. Las respuestas escritas admiten expresiones de respuesta, pero las listas Arrange y de huecos de escucha son literales. Un Round puede dejar el título vacío en Create y Edit Round: sigue la indicación para no escribir nada. La etiqueta visible Round N depende de la posición y no crea un título guardado.',
  'editorHelp.audioLibrary.title': 'Audio Library',
  'editorHelp.audioLibrary.body':
      'Elige On-Device TTS, Recorded MP3 o Hybrid. Solo los dos últimos muestran Check unused MP3 files, Import MP3 y Open MP3 from.... Copia MP3 en {folderAudioImports} y pulsa Import MP3, o usa Open from… para elegir hasta 100 archivos y 250 MB por vez. Ambos caminos hacen las mismas comprobaciones y guardan en los medios propios del Course. Cada archivo puede ocupar hasta 50 MB; QQL lo nombra por contenido y omite los duplicados. Debe ser un MP3 real con tramas MPEG Layer III completas; admite etiquetas ID3 o APE de hasta 2 MB en total, pero rechaza archivos dañados, truncados o con imagen de portada. En la carpeta fija, un archivo inválido detiene toda la importación. Los archivos originales permanecen. Comprueba cada grabación con Preview y asígnala a la palabra o expresión exacta. Recorded MP3 combina fragmentos compatibles; Hybrid usa TTS si no puede completar la secuencia. Course JSON guarda referencias, no bytes MP3: para transferir grabaciones usa el Course ZIP. Los backups de versión incluyen los audios referenciados; Export my data no incluye estos medios.',
  'editorHelp.imageBank.title': 'Image Bank',
  'editorHelp.imageBank.body':
      'Importa imágenes o Image Bank ZIP desde {folderImageImports} o con Open image files from… y Open Image Bank ZIP from…. Se comprueba el contenido: PNG, JPEG o WebP fijo, sin daños ni metadatos excesivos, hasta 4096 × 4096 píxeles. En Image Library de Course Editor, Add images to this Course añade archivos o un banco solo a ese curso; viajan en su ZIP y no entran en Shared Image Library. Para un Image Bank ZIP, incluye image_bank_manifest.json en UTF-8 y solo las imágenes que enumera. El manifiesto puede ser una lista o un objeto con images y attribution. Cada imagen necesita id único, primary_term o label, y filename seguro; puede tener hasta 32 keywords. Se rechazan rutas inseguras, enlaces, ZIP cifrados y archivos extra. Un Admin decide qué hacer con categorías nuevas y con conflictos de ID: Skip, Replace o Keep both. Las imágenes idénticas se omiten. Límites: ZIP de 50 MB, manifiesto de 2 MB, 5000 entradas, 2500 imágenes, 50 KB por imagen y 50 MB de imágenes extraídas. Los archivos originales permanecen. En la vista grande, pasa el cursor o mantén pulsado para ver los detalles; un archivo ausente muestra File missing. Elegir una imagen para Exercise crea una copia propia del Course; Course JSON guarda su referencia, no sus bytes.',
  'editorHelp.lessonThemeIconsAndPreview.title': 'Iconos de Lesson y Preview',
  'editorHelp.lessonThemeIconsAndPreview.body':
      'Cada Lesson puede usar Preinstalled icon, Custom Course icon o Numbers. Para Import custom icon, deja un solo PNG, JPEG o WebP en {folderLessonIconImports}, de hasta 2 MB y dimensiones de 1–4096 píxeles. QQL decodifica el primer fotograma y lo centra, escalado sin recortar, en un PNG transparente de 256 × 256. Conserva la transparencia existente, pero no elimina un fondo opaco. Un archivo ausente, extra, inválido o demasiado grande detiene la importación; el original permanece. El icono queda dentro del Course y sobrevive al exportar, importar y duplicar el JSON. Sin icono explícito, se muestra un círculo del color del tema con el número de Lesson. Las opciones ocupan 84 × 84 en la vista del estudiante. Preview no escribe progreso.',
  'editorHelp.exerciseImageSpecifications.title':
      'Requisitos de imagen del Exercise',
  'editorHelp.exerciseImageSpecifications.body':
      'Para Import custom image, deja un solo PNG, JPEG o WebP en {folderImageImports}, de hasta 50 KB. Se recomiendan 256 × 256 píxeles y 15 KB, pero este importador no limita dimensiones ni cambia tamaño, recorte o transparencia. Comprueba extensión, número y tamaño y copia los bytes sin modificarlos; el original permanece. Preview avisa si la imagen falta o no se puede leer. El Exercise usa una copia en los medios del Course, nombrada por contenido. Course JSON guarda la referencia, no la imagen: exportar solo el JSON no la transfiere. La imagen es opcional salvo en el ordenamiento con imagen como prompt.',
  'editorHelp.newExerciseTypes.title': 'Nuevos tipos de Exercise',
  'editorHelp.newExerciseTypes.body':
      'Missing Word reproduce audio y oculta palabras de la transcripción. Image Word pide formar una palabra a partir de bloques de letras o sílabas, sin distractores. Dialogue Response usa una frase, una pregunta y dos respuestas posibles en la lengua de estudio, en orden aleatorio. Word Match presenta tres pares de traducción; Super Match, tres pares en la lengua de estudio y una relación explícita; Audio Match, tres audios y tres textos correspondientes, sin distractores. Listening Spelling / Type what you hear pide escribir lo escuchado y Return/Enter confirma. Sentence Word Order admite de cero a dos distractores. Gap Choice pide elegir el único bloque correcto por significado y gramática para completar una frase.',
  'editorHelp.languageDuel.title': 'Language Duel',
  'editorHelp.languageDuel.body':
      'Cada Lesson tiene su Duel. El de la última se presenta como Final Duel, con Final challenge for the last Lesson, pero usa las mismas reglas y no promete desbloquear otra Lesson. Un Duel normal elige 25 Exercises aptos y distintos de esa Lesson y empieza con cuatro vidas. Cada error cuesta una vida. Ganas si completas las 25 preguntas antes de perder las cuatro. Si hay menos de 25 Exercises aptos, no aparece el Duel; es una situación normal, no un error del curso.',
  'editorHelp.courseCreationRules.title': 'Pautas para crear cursos',
  'editorHelp.courseCreationRules.body':
      'Una Lesson debería tener normalmente al menos seis Rounds, quizá unos 48 Exercises. Es una pauta, no un requisito de validez ni de disponibilidad del Duel. Un Round normal tiene 15 Exercises. Evita repeticiones accidentales. Escribe las palabras aisladas en minúscula salvo que la lengua exija mayúscula. Sitúa los ejercicios de opuestos más tarde. Sentence Word Order permite entre cero y dos distractores: pocos al principio y más después, siempre plausibles pero claramente incorrectos. Las instrucciones para el estudiante van en la lengua base del curso. Los primeros Rounds presentan y consolidan; los posteriores pueden ser más difíciles.',
  'editorHelp.listeningSpelling.title': 'Listening Spelling',
  'editorHelp.listeningSpelling.body':
      'Type what you hear usa Audio text para reproducir y Missing word para las respuestas admitidas, una palabra o fragmento completo por línea. Passage transcript se muestra tal como lo escribes; el preset no oculta automáticamente la respuesta. Revisa el prompt con Preview para que no revele la solución. Si quieres ocultar palabras en una transcripción completa, usa Listen for missing words.',
  'editorHelp.lessonGuidebook.title': 'GuideBook de la Lesson',
  'editorHelp.lessonGuidebook.body':
      'Cada Lesson tiene un GuideBook para estudiantes cuando está Published y Use GuideBook está en ON. Sus campos son Overview, Usage examples, Vocabulary y Grammar. Insights abre otra página de secciones ordenadas con Title y Text. Los cambios permanecen en la copia de trabajo hasta Save Guidebook o Save Guidebook as draft; borrar una sección pide confirmación. Draft no se entrega a estudiantes y muestra un distintivo azul en los elementos contenedores. El distintivo es independiente de Audit: los Error o Warning mantienen el borde rojo; un Draft sin problemas queda verde con distintivo azul. El Editor puede usar su vocabulario y ejemplos para proponer ejercicios.',
  'editorHelp.courseMetadataAndAuthors.title': 'Metadatos y autores del curso',
  'editorHelp.courseMetadataAndAuthors.body':
      'Course Info está disponible en Locked, View only e Inspection mode. Course Info Editor exige Edit y permiso de edición. Puedes cambiar el nombre visible sin cambiar Course ID. Base language y Learning language son de solo lectura. Original Course Created es origen inmutable; Last Version Editor y Modified describen la versión actual. Abrir el editor no cambia estos datos. Automatic quita la bandera explícita y usa la de la lengua. Authors / Contributors y Rights Holder son descriptivos; Original Course Creator y Course Maintainer tienen identidades separadas. Course Info obtiene Assigned Team, Team Leaders y Team Members de Team Manager. Internal IDs muestra sus IDs y la versión de Course Model. El origen de Fork identifica creador, fecha y fuente inmediata. En cursos oficiales permanecen editor, versión, notas, canal, checksum y verificación. Lesson numbering, en Lessons y Edit, cambia etiquetas visibles sin cambiar títulos guardados, IDs, progreso ni desbloqueos.',
  'editorHelp.auditSeverityAndCodes.title': 'Gravedad y códigos de Audit',
  'editorHelp.auditSeverityAndCodes.body':
      'Course Audit clasifica Error, Warning e Info. Error bloquea publicación o importación; Warning pide revisión; Info no bloquea por sí solo. Puedes ordenar por Lesson, tipo de Exercise o Recently modified y abrirlo para un Course, una Lesson o un Round. El borde rojo señala Error o Warning y se propaga por su rama; el verde indica que no los hay. El distintivo azul Draft es independiente: un borde verde no significa Published. Un contenedor Draft mantiene ocultos sus hijos Published hasta guardarlo. Un problema de GuideBook afecta a su Lesson, no a la rama Rounds. Menos de tres Rounds es Info; menos de 25 Exercises aptos para Duel es Info solo con Create Duels en ON. La falta de comprensión lectora o auditiva no genera aviso, pero su contenido existente sí se valida. Course Editor Help > Technical reference > Audit Codes muestra las reglas, con filtros independientes Error, Warning e Info y búsqueda dentro de las categorías elegidas.',
  'editorHelp.courseAudit.title': 'Course Audit',
  'editorHelp.courseAudit.body':
      'Course Audit revisa estructura y autoría: campos inválidos, IDs repetidos, Word Block, audio sin correspondencia y errores de Missing Word. Un texto de Reading vacío es Error; con una o dos palabras léxicas aparece READING_PASSAGE_TOO_SHORT, y con tres o más no. HINT_REPEATS_PROMPT es Warning; revelar una respuesta correcta es Error. Audit no certifica gramática, traducción ni calidad pedagógica.',
  'editorHelp.createNewCourse.title': 'Crear un curso nuevo',
  'editorHelp.createNewCourse.body':
      'Course Studio crea un proyecto Course Model v11 independiente y lo abre en Course Editor. New Course ofrece License / Rights, Authors / Contributors, variante de lengua, niveles, descripción y datos de apoyo como Course Info Editor. El perfil activo es el Original Course Creator inmutable y, por defecto, Course Maintainer; puedes elegir a otra persona local como Maintainer. Assigned Team no se elige al crear. Number of Lessons empieza en 3 (1–100) y Rounds per Lesson en 1 (1–20). Los valores inválidos muestran un error y desactivan Create. La jerarquía inicial se crea de una vez con IDs nuevos y Rounds sin título, cada uno con un Exercise Draft de Pick the translation (to target). Revisa y guarda el contenido antes de publicar. El Course Not published solo existe en la copia de trabajo hasta que Confirm course changes crea la versión 1. Cancelar no guarda nada. Los cursos v11 importados deben declarar origen, Maintainer, estado Draft/Published y fechas UTC; no se convierten formatos anteriores.',
  'courseStudioHelp.findingCourses.title': 'Encontrar cursos',
  'courseStudioHelp.findingCourses.body':
      'Search filtra títulos y lenguas de origen o estudio en Course Studio, incluso en Favorites. Favorites muestra accesos rápidos a cursos de la biblioteca personal del estudiante activo; cada curso sigue en su sección normal. Sort by y Show unavailable se aplican a Favorites y a las demás secciones. Cada sección tiene su propio Expanded / Compact. Estos controles solo cambian la vista.',
  'courseStudioHelp.courseOperations.title': 'Operaciones con cursos',
  'courseStudioHelp.courseOperations.body':
      'Copy as New Course crea un Custom Course independiente a partir de uno que puedes administrar. Fork crea un derivado cuando la licencia lo permite; conserva el origen y recibe IDs nuevos. Merge combina Lessons de cursos compatibles en un tercero sin cambiar las fuentes. Delete course elimina un Custom Course del dispositivo tras dos confirmaciones y con los permisos necesarios. Remove Publisher Course from device es solo para Admin y se bloquea si otro perfil incluye el curso; conserva progreso y backups. Remove from my courses solo cambia tu biblioteca. Hide in Learner oculta un curso del Course Selector sin quitarlo de la biblioteca; Unhide in Learner lo vuelve a mostrar. Las operaciones no disponibles aparecen en gris con el motivo.',
  'editorHelp.title': 'Ayuda de Course Editor',
  'courseStudioHelp.title': 'Ayuda de Course Studio',
  'editorHelp.technicalReference.title': 'Referencia técnica',
  'editorHelp.technicalReference.body':
      'En desarrollo. Estas páginas describen la implementación actual de Course Model v11, aparte de las instrucciones prácticas de Course Editor.',
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
      'Course Selector muestra el curso actual, los recientes, los incluidos y los locales. Cada fila tiene Course Info y Remove from my courses. Course Library permite volver a añadir cursos con el progreso conservado. Import Course vuelve directamente al estudio. Con Animations activadas, cambiar a otro curso muestra brevemente su bandera válida antes de Learner Panel; si no hay bandera declarada usa la bandera habitual del código del curso. Cada estudiante retoma la última Lesson válida o la primera. El control inferior de Lesson alterna Expanded, Collapse completed y Focused; Section selector sigue siendo la navegación entre Sections.',
  'appInfo.courseIdentityAndProgress.title': 'Identidad del curso y progreso',
  'appInfo.courseIdentityAndProgress.body':
      'Cada curso tiene un Course ID único e inmutable. Actualizar el mismo curso conserva el ID y el progreso. Al importar otro con ese ID puedes reemplazarlo o actualizarlo, crear una copia derivada con ID nuevo o cancelar. La copia puede registrar la fuente y su versión. Completados, Review, laureles y victorias de Language Duel se separan por Course ID. Language XP, streaks y días de estudio se comparten por lengua de estudio; Week XP suma todos los cursos y lenguas.',
  'appInfo.progressWeekXpAndGamification.title':
      'Progreso, Week XP y Gamification',
  'appInfo.progressWeekXpAndGamification.body':
      'Language XP, streak, Study Days y Status se guardan por estudiante y lengua de estudio. Profile > Statistics muestra Total Study Days y, por cada lengua, bandera, nombre, ID, Study Days, Current Streak y Max Streak. Los Rounds completados y laureles se guardan por Course ID. Week XP suma los XP de todos los cursos de la semana actual. Profile > Gamification incluye Weekly XP Target · All courses, Last Week XP · All courses y Local leaderboard · All courses. Last Week XP corresponde a la semana anterior completa; toca tu cifra para ver el desglose por curso. La clasificación local usa ese total semanal. Puedes dejar de participar sin borrar XP.',
  'appInfo.streakAndFreezeRule.title': 'Streak y pausa',
  'appInfo.streakAndFreezeRule.body':
      'El streak de una lengua sube cuando la estudias en un día nuevo. Si estudias otra lengua durante un día, el streak de la primera queda en pausa: no sube ni se reinicia. Un día completo sin estudiar ninguna lengua rompe los streaks activos.',
  'appInfo.daysStudied.title': 'Días de estudio',
  'appInfo.daysStudied.body':
      'Study Day es un día del calendario local en que completas estudio. Varios Rounds en el mismo día cuentan como uno. Total Study Days cuenta fechas distintas entre todas las lenguas; estudiar dos en un día solo suma un día.',
  'appInfo.laurelCrowns.title': 'Coronas de laurel',
  'appInfo.laurelCrowns.body':
      'Un Round gana una corona cuando completas un intento entero sin errores, desde el curso o Review. La corona permanece aunque después cometas errores. Al ganarla suena la victoria si los efectos de sonido están activados.',
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
      'Cada Lesson tiene un GuideBook con explicaciones y material de consulta. Es el primer elemento del recorrido de esa Lesson y solo se abre cuando lo seleccionas.',
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
      'Los cursos incluidos llamados AI-Slop Demo son demostraciones generadas con IA y sin revisión; no son cursos fiables para estudiar. El contenido real de QuisquisLingo está pensado para ser escrito y revisado por personas. Esto no clasifica a otros cursos oficiales o custom.',
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
  'courseInfo.courseModel': 'Course Model: v{value}',
  'courseInfo.temporarySample.title': 'Temporary Sample',
  'courseInfo.temporarySample.body':
      'Este curso está marcado TEMPORARY SAMPLE. El contenido precargado solo sirve para demostrar y probar el editor. Sustitúyelo por contenido revisado antes de publicar o distribuir el curso.',
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
  'allCoursesHelp.sortingAndCompactView.title': 'Orden y vista compacta',
  'allCoursesHelp.sortingAndCompactView.body':
      'Sort by ordena cada sección por Title, Language, Maintainer, Most recent o Duration, sin mover las secciones. Most recent muestra primero la última edición; Duration, primero los cursos más cortos y al final los que no indican duración. Expanded / Compact oculta o muestra versión, fecha, Maintainer y Duration en esa sección. Search filtra títulos y lenguas, incluso en Favorites. Estas elecciones duran mientras la página está abierta.',
  'allCoursesHelp.personalLibrary.title': 'Biblioteca personal',
  'allCoursesHelp.personalLibrary.body':
      'Add to my courses añade un curso instalado a Course Selector y Course Studio para tu perfil. No copia el curso ni da permiso de edición. Added · Remove y Remove from my courses lo quitan solo de tu biblioteca, con confirmación y opción de Reset my progress. Por defecto se conserva el progreso. Si lo reinicias, solo se borran los Rounds y Lessons completados, resultados Perfect, Duels ganados, GuideBooks leídos y entradas recientes de ese curso. Se conservan XP, Weekly XP, días de estudio, streak y backups; tampoco se resta el XP ganado. Otros estudiantes y el archivo compartido no cambian.',
  'allCoursesHelp.coursesInLearnerMode.title': 'Cursos en el modo de estudio',
  'allCoursesHelp.coursesInLearnerMode.body':
      'Hide in Learner mantiene el curso en tu biblioteca y Course Studio, pero lo quita de Course Selector. Unhide in Learner lo devuelve. No puedes ocultar el curso actual hasta cambiar a otro. Favorites son accesos propios de cada estudiante y no añaden cursos a la biblioteca. All Courses sigue mostrando los ocultos con Hidden in Learner para poder restaurarlos.',
  'allCoursesHelp.importing.title': 'Importar cursos',
  'allCoursesHelp.importing.body':
      'Los Courses pueden transferirse como paquetes QQL. Los Custom Courses importados conservan sus reglas de propietario y origen. Los Publisher Courses siguen sujetos a verificación del editor.',
  'allCoursesHelp.removingPublisherCourse.title':
      'Quitar un Publisher Course del dispositivo',
  'allCoursesHelp.removingPublisherCourse.body':
      'Solo un Admin puede usar Remove Publisher Course from device desde el menú de Course Studio. Se bloquea si otro perfil incluye ese curso en su biblioteca. La eliminación física conserva progreso y backups de versión para una futura reinstalación.',
  'technical.courseModel.title': 'QuisquisLingo Course Model v11',
  'technical.courseModel.status.title': 'Estado',
  'technical.courseModel.status.body':
      'En desarrollo. QuisquisLingo usa formatVersion 11 como único Course Model nativo. Los formatos anteriores se rechazan sin migrarlos ni borrarlos. Cada Custom Course necesita un Original Course Creator inmutable y un Course Maintainer individual; Assigned Team es opcional y distinto.',
  'technical.courseModel.hierarchy.title': 'Jerarquía',
  'technical.courseModel.hierarchy.body':
      'Course > Lesson > GuideBook + Round > Content. Cada Lesson tiene su GuideBook y Duel. Exercise es un tipo de Content, pero no el único permitido en un Round.',
  'technical.courseModel.content.title': 'Content',
  'technical.courseModel.content.body':
      'Los tipos actuales incluyen exercise, presentation, explanation, example, vocabulary, text y dialogue. Content tiene un ID estable y puede ser obligatorio para completar. Lesson, Round y Exercise llevan fechas UTC updatedAt obligatorias. Presentation Content puede ser interactivo sin resultado correcto/incorrecto.',
  'technical.courseModel.guidebook.title': 'GuideBook',
  'technical.courseModel.guidebook.body':
      'El GuideBook de cada Lesson es Content estructurado, no un bloque único. Vocabulario, ejemplos y explicaciones sirven al estudiante y pueden alimentar la generación de Rounds Draft de dificultad progresiva y sus sourceRefs.',
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
      'En desarrollo. El conjunto actual de primitivas es la base implementada en Course Model v11.',
  'technical.exercisePrimitives.exerciseAnatomy.title': 'Anatomía de Exercise',
  'technical.exercisePrimitives.exerciseAnatomy.body':
      'Exercise = Prompt[] + Interaction + Evaluation, con hint y feedback opcionales.',
  'technical.exercisePrimitives.interactions.title': 'Interacciones',
  'technical.exercisePrimitives.interactions.body':
      'select: elegir uno o varios Items. input: escribir una respuesta. arrange: ordenar Items. match: relacionar Items.',
  'technical.exercisePrimitives.evaluations.title': 'Evaluaciones',
  'technical.exercisePrimitives.evaluations.body':
      'selected_items comprueba IDs estables de Items elegidos; text_match compara texto aceptado con normalización explícita; ordered_items comprueba el orden; matched_items, las relaciones.',
  'technical.exercisePrimitives.promptAndItemMedia.title':
      'Medios de Prompt e Item',
  'technical.exercisePrimitives.promptAndItemMedia.body':
      'Las primitivas de medios son text, image y audio. Un elemento Prompt puede tener funciones como primary, passage, question, context o clue.',
  'technical.exercisePrimitives.presentationContent.title':
      'Presentation Content',
  'technical.exercisePrimitives.presentationContent.body':
      'Flashcard es Presentation Content, no Exercise. El estudiante elige understood o review_later. Ambas opciones completan la presentación; review_later pide repetirla y no cuenta como respuesta incorrecta.',
  'technical.exercisePrimitives.friendlyTemplates.title':
      'Plantillas y primitivas',
  'technical.exercisePrimitives.friendlyTemplates.body':
      'Las plantillas claras son una capa de autoría. Varias pueden usar las mismas primitivas. Límites de una plantilla, como cantidad de distractores, no se convierten en reglas universales.',
  'technical.jsonStructure.title': 'Estructura de datos JSON',
  'technical.jsonStructure.status.title': 'Estado',
  'technical.jsonStructure.status.body':
      'En desarrollo. QuisquisLingo escribe formatVersion: 11.',
  'technical.jsonStructure.root.title': 'Raíz',
  'technical.jsonStructure.root.body':
      'La raíz contiene formatVersion, metadatos de Course y lessons[]. Los cursos incluidos y custom usan el modelo nativo v11; uno fusionado también lleva mergeProvenance. Un custom exige originalCourseCreator inmutable y un maintainer individual. assignedTeamId es opcional; la lista de miembros del Team vive fuera del Course JSON. No se leen ni migran modelos anteriores.',
  'technical.jsonStructure.guidebook.title': 'GuideBook',
  'technical.jsonStructure.guidebook.body':
      'Cada Lesson contiene un guidebook con publicationState opcional y guidebook.content[] estructurado. Sin publicationState se considera Published; Draft lo excluye de la entrega al estudiante. Su Internal ID visible deriva de lessonId con el sufijo _guidebook; no se guarda otro ID. El Content del GuideBook conserva sus propios IDs. useGuidebook cambia el acceso del estudiante y el aviso por GuideBook vacío, nunca el contenido guardado.',
  'technical.jsonStructure.lessonAndRound.title': 'Lesson y Round',
  'technical.jsonStructure.lessonAndRound.body':
      'Course, Lesson, GuideBook, Round y Exercise tienen estado Draft/Published. Lesson, Round y Exercise exigen fechas UTC updatedAt. Course guarda Lesson numbering y los iconos custom de Lesson. La Lesson contiene lessonId, title, Section opcional, tema, guidebook, rounds[] e identidad de Duel. GuideBook puede tener Insights ordenados con Title y Text. El título de Round es opcional; si falta, se muestra Round N según su posición sin cambiar el ID.',
  'technical.jsonStructure.exerciseContent.title': 'Content de Exercise',
  'technical.jsonStructure.exerciseContent.body':
      'Exercise Content guarda editorTemplate y exercise.prompt[], exercise.interaction y exercise.evaluation. La corrección usa IDs estables de Item, no posiciones visibles. Build the translation guarda uno o más correctOrders literales con texto e IDs ordenados; correctOrder antiguo se rechaza.',
  'technical.jsonStructure.duel.title': 'Duel',
  'technical.jsonStructure.duel.body':
      'La Lesson guarda un ID y título estables de Duel. Su disponibilidad se calcula al ejecutar según Exercises aptos y distintos, no se serializa ni depende de la cantidad de Rounds. createDuels y useGuidebook empiezan en true y solo se escriben si son false. sectionNames conserva nombres no vacíos; worldFlagId referencia el SVG oficial incluido y se omite si está vacío.',
  'technical.jsonStructure.compatibility.title': 'Compatibilidad',
  'technical.jsonStructure.compatibility.body':
      'Los cursos incluidos y custom usan Course Model v11. Los formatos anteriores no se leen, migran, convierten ni borran. Créditos, origen y Rights Holder nunca conceden permisos ni implican Assigned Team.',
  'deviceAdminHelp.title': 'Ayuda de Device Administration',
  'deviceAdminHelp.whatThisPageIs.title': 'Qué es esta página',
  'deviceAdminHelp.whatThisPageIs.paragraph1':
      'Device Administration reúne las funciones de Admin de esta instalación de QQL. Solo afecta a este dispositivo: QQL no tiene cuenta en línea.',
  'deviceAdminHelp.whatThisPageIs.paragraph2':
      'Estas funciones siguen disponibles donde estaban antes. Solo los Admin pueden ver esta página.',
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
      'Export: cursos exportados, copias de estudiantes, User Recovery Keys e informes de Audit. Los backups que Course Editor crea antes de guardar cambios son privados de QQL y aparecen en una sección aparte.',
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
  'deviceAdminHelp.qqlTools.title': 'QQL-Tools',
  'deviceAdminHelp.qqlTools.paragraph1':
      'QQL-Tools es un proyecto complementario opcional que valida de forma independiente archivos Course JSON y paquetes ZIP de QQL. Sus resultados no sustituyen Course Audit, la validación de importaciones ni los controles de seguridad de QQL.',
  'deviceAdminHelp.qqlTools.paragraph2':
      'En Device Administration, un Admin usa Browse... para configurar el ejecutable QQL-Tools una vez por dispositivo; Test lo comprueba y Clear borra la configuración. Validate with QQL-Tools... se ejecuta en segundo plano mientras QQL permanece abierto. No modifica ni importa el Course seleccionado. Not available on mobile devices.',
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
      'Remove all learners except admins: elimina perfiles no Admin y sus datos; quita la lista de Team si nombra a alguno.',
  'deviceAdminHelp.resetOptions.bullet3':
      'Remove imported media: elige imágenes, MP3 o ambos; al principio no hay nada marcado. Solo borra copias creadas por QQL. Los medios incluidos con la app siguen y los originales externos no se tocan. Las etiquetas y categorías de imágenes compartidas vuelven a sus valores iniciales.',
  'deviceAdminHelp.resetOptions.bullet4':
      'Remove custom courses: borra cursos custom e instalados, Teams y todos los medios importados. Conserva estudiantes.',
  'deviceAdminHelp.resetOptions.bullet5':
      'Wipe out everything: devuelve QQL al estado de una instalación nueva, incluidos estudiantes y Admin. Puedes conservar la carpeta Export, la carpeta Logs y las carpetas Import y ToBeMerged; todas vienen marcadas para conservarse. Los backups de los cursos se eliminan siempre con los cursos.',
  'deviceAdminHelp.beforeResetBackups.title': 'Backups antes de Reset',
  'deviceAdminHelp.beforeResetBackups.paragraph1':
      'Profile > User Data exporta solo el perfil activo. Un Admin no puede exportar los datos de otros: pídeles que hagan su backup antes de un Reset que les afecte. Los cursos se exportan uno a uno desde Course Studio. Las exportaciones quedan en {folderExport}, que Wipe out everything conserva salvo que la desmarques.',
  'deviceAdminHelp.forgottenPin.title': 'PIN olvidado',
  'deviceAdminHelp.forgottenPin.paragraph1':
      'Otro Admin puede restablecer tu PIN desde Learner Profiles. Si eres el único Admin y lo olvidas, no podrás recuperar el acceso al perfil ni usar Reset. Elige un PIN que recuerdes y considera nombrar a otra persona Admin.',
  'debugHelp.title': 'Ayuda de Debug',
  'debugHelp.crashLog.title': 'Crash Log',
  'debugHelp.crashLog.body':
      'Esta beta guarda automáticamente un Crash Log local para investigar cierres y problemas técnicos graves. Si QQL se cierra de forma inesperada, vuelve a abrirlo y envía el archivo completo con una breve descripción de lo que pulsaste justo antes; una captura de pantalla no basta. El Crash Log activo está en el almacenamiento privado de QQL; Settings > Debug muestra dónde. Quick Export guarda una copia llamada QQL_crash_log.txt en {folderLogs}, sustituyendo la anterior; Save log copy as… te deja elegir dónde guardarla y, en los teléfonos, Share la envía directamente. El registro contiene datos técnicos del sistema, inicios de sesión, errores no capturados y trazas. No está pensado para guardar nombres de estudiantes, respuestas o contenido de cursos. Si se borra, QQL lo vuelve a crear al iniciar o escribir otro fallo.',
  'debugHelp.diagnosticLog.title': 'Diagnostic Log',
  'debugHelp.diagnosticLog.body':
      'Para problemas que no cierran QQL, como audio, TTS, Recorded MP3 o reproducción inesperada, reproduce el fallo si puedes y exporta Diagnostic Log poco después. Puedes borrarlo antes para aislar un problema repetible, pero no es obligatorio. Si el fallo es intermitente, exporta el registro actual antes de borrarlo.',
  'debugHelp.privacy.title': 'Privacidad',
  'debugHelp.privacy.body':
      'El diagnóstico de audio del estudiante está diseñado para no guardar texto hablado, respuestas, contenido de cursos ni rutas completas de archivos personales.',
  'publisherSigningHelp.title': 'Publisher signing and approval',
  'publisherSigningHelp.status.title':
      'Estado: verificación de firmas implementada',
  'publisherSigningHelp.status.body':
      r'''QQL verifica firmas Ed25519 al importar Publisher Courses, tanto con Quick Import como desde el diálogo del sistema. La comprobación se repite antes de instalar. Se rechazan firmas ausentes, inválidas, desconocidas o revocadas. El registro normal aún no contiene editores externos aprobados; Dummy solo se usa en builds de prueba activadas expresamente.

La aprobación es un proceso manual del propietario de QQL. Este mantiene las claves públicas en lib/services/trusted_publishers.dart y distribuye los cambios con una actualización. No hay portal de aprobación ni botón de firma en la app. La firma se hace fuera de QQL con una herramienta de desarrollo y OpenSSL.

Course Model usa v11; los Publisher Courses v9/v10 requieren tools/convert_course_to_v11.dart y una firma nueva. El protocolo es qql-ed25519-v1.''',
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
      r'''Prepara un externalOfficial JSON válido de Course Model v11 con publisherId y publisherName aprobados, origen, courseId estable y datos de versión. Para actualizar, conserva ID y origen y aumenta officialCourseVersion. Resuelve errores de Course Audit y revisa licencias. La herramienta no convierte cursos custom ni inventa datos del editor.

Desde el repositorio QQL, sustituye dummy-1 por tu keyId y usa tus rutas:

dart run tools/sign_course.dart prepare C:/QQL-Publisher/course.json dummy-1 C:/QQL-Publisher/payload.bin
openssl pkeyutl -sign -rawin -inkey C:/QQL-Publisher/publisher-private.pem -in C:/QQL-Publisher/payload.bin -out C:/QQL-Publisher/signature.bin
openssl pkey -pubin -in C:/QQL-Publisher/publisher-public.pem -outform DER -out C:/QQL-Publisher/publisher-public.der
dart run tools/sign_course.dart attach C:/QQL-Publisher/course.json dummy-1 C:/QQL-Publisher/signature.bin C:/QQL-Publisher/publisher-public.der C:/QQL-Publisher/course-signed.json

Coloca cada imagen o grabación referenciada en C:/QQL-Publisher/media/ con su nombre SHA-256, por ejemplo <sha256>.mp3. Crea el paquete:

dart run tools/sign_course.dart package C:/QQL-Publisher/course-signed.json C:/QQL-Publisher/media C:/QQL-Publisher/publisher-public.der C:/QQL-Publisher/course-signed.zip

Comprueba código 0 tras cada comando ($LASTEXITCODE en PowerShell). No cambies course.json entre prepare y attach; cualquier cambio exige preparar y firmar de nuevo. Usa nombres de salida nuevos: OpenSSL puede sobrescribir. La verificación con la clave aportada no equivale a aprobación en el registro QQL. Importa el ZIP en una app que conozca tu clave, comprueba editor, versión, contenido y medios, y prueba la actualización y el progreso. Distribuye ese mismo ZIP. La firma cubre el JSON normalizado y las referencias SHA-256; el ZIP comprueba los bytes de los medios. No existe interfaz de publicación dentro de la app.''',
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
  'exerciseHelp.supplement.answerVariants.title': 'Variantes de respuesta',
  'exerciseHelp.supplement.answerVariants.body':
      'Puedes escribir respuestas completas equivalentes en líneas separadas. La sintaxis compacta es opcional: {Io} hace opcional Io; [prendo|vorrei] elige una alternativa; (non arrivo <> oggi) intercambia solo las partes indicadas. Los grupos [*:il|i] [*:tuo|tuoi] [*:denaro|soldi] se enlazan por posición: admiten il tuo denaro e i tuoi soldi, no mezclas. Necesitas al menos dos grupos enlazados con la misma cantidad de opciones. Se combinan con {}, [] normales y <> válidos. La puntuación final permanece al final. La expansión elimina duplicados y rechaza sintaxis inválida o más de 128 variantes.',
  'exerciseHelp.supplement.textEvaluationAndCorrections.title':
      'Evaluación de texto y correcciones',
  'exerciseHelp.supplement.textEvaluationAndCorrections.body':
      'QQL acepta las respuestas completas configuradas y sus variantes tras normalizar mayúsculas, puntuación, espacios, apóstrofos y acentos. Type the translation también tolera una letra repetida omitida o duplicada en una palabra de al menos cinco caracteres si todo lo demás coincide. Ante un error muestra hasta tres respuestas válidas ordenadas por similitud y Some possible translations si hay más. Ante una respuesta correcta muestra hasta dos alternativas distintas de la respuesta aceptada. El orden de autor resuelve empates; la clasificación no cambia qué se acepta. Los demás presets escritos mantienen Correct answer. El feedback solo menciona diferencias reales.',
  'exerciseHelp.supplement.contextualComprehensionExample.title':
      'Ejemplo de comprensión contextual',
  'exerciseHelp.supplement.contextualComprehensionExample.body':
      'Question: What does Jane mean?\n\nContext:\nJane: I thought Jim was coming with us.\nJim: I changed my mind.\nJane: That’s just great.\n\nQuestion y Context son independientes. Context puede ser texto, audio o ambos. El diálogo es opcional; también sirve un anuncio, pasaje o situación breve. Configura las respuestas por separado.',
  'exerciseHelp.preset.choice.body':
      'El estudiante ve un prompt en la lengua base y elige su traducción en la lengua de estudio. Escribe un prompt claro, al menos dos respuestas y una correcta. Puedes añadir audio o imagen al prompt. Los distractores deben ser plausibles y claramente incorrectos.',
  'exerciseHelp.preset.gap_choice.body':
      'El estudiante ve una frase con ___ y elige la palabra o expresión que falta. Escribe un hueco, bloques de respuesta y una respuesta correcta. Procura que solo una opción sea correcta en significado y gramática.',
  'exerciseHelp.preset.icon_choice.body':
      'El estudiante ve una pregunta y varias imágenes, y elige la que corresponde. Añade texto o icono para cada opción y el número de la respuesta correcta. Todas las opciones necesitan imagen.',
  'exerciseHelp.preset.script_recognition.body':
      'Cada opción relaciona la imagen de un carácter con su texto. En Image to text se elige el texto que corresponde a la imagen; en Text to image se elige la imagen del texto. El texto puede ser nombre, sonido, pronunciación o transliteración. Da al menos dos opciones y una sola correcta. Puedes mostrar varias imágenes del carácter. Usa imágenes incluidas o importadas portátiles, nunca rutas absolutas. Preview emplea la interacción Select normal.',
  'exerciseHelp.preset.listening_choice.body':
      'El estudiante escucha audio y elige el texto correspondiente. Audio text debe contener exactamente lo que se oye. On-Device TTS usa la voz del dispositivo; Recorded MP3 busca asociaciones de texto en Course Editor > Audio Library; Hybrid prueba primero los MP3 completos y después TTS. Para MP3, importa archivos en {folderAudioImports} con Import MP3 y usa Associate recording. No se adjunta MP3 a cada Exercise. El JSON solo guarda referencias, no bytes. Ofrece varias respuestas escritas y una correcta sin revelar el audio visualmente.',
  'exerciseHelp.preset.listening_comprehension.body':
      'El estudiante escucha un pasaje y contesta una pregunta aparte. Escribe Audio text, la pregunta, alternativas y una respuesta correcta. La solución debe requerir comprender el pasaje.',
  'exerciseHelp.preset.reading_comprehension.body':
      'El estudiante lee un pasaje y contesta una pregunta aparte. Escribe el contexto, la pregunta, alternativas y una respuesta correcta. Puedes añadir imagen. El pasaje debe tener suficiente contenido para evaluar comprensión.',
  'exerciseHelp.preset.dialogue_response.body':
      'El estudiante lee una situación y una pregunta y elige la mejor de dos respuestas. Escribe Context, Question, exactamente dos respuestas y una correcta, todo en la lengua de estudio. El orden visible se mezcla.',
  'exerciseHelp.preset.contextual_comprehension.body':
      'El estudiante lee o escucha un Context y responde una pregunta de elección. Escribe Question, texto o audio de Context, alternativas y una correcta. Dialogue es opcional: una línea Speaker: text por turno. Puedes añadir una imagen.',
  'exerciseHelp.preset.type_translation.body':
      'El estudiante traduce libremente un texto de la lengua base. Escribe el texto y una o más traducciones completas aceptadas; Hint es opcional. Usa minúsculas salvo nombres propios. Se admiten variantes {}, [a|b], grupos enlazados [*:a|b] y cambios de orden <>. Expand answers muestra una vista previa sin guardar; Use expanded answers añade líneas explícitas sin modificar la expresión original. Se rechazan más de 128 variantes sin cambios parciales. El feedback muestra respuestas válidas por similitud, sin cambiar cuáles se aceptan. Se tolera de forma conservadora una letra repetida omitida o duplicada, no palabras ausentes ni sustituciones.',
  'exerciseHelp.preset.build_translation.body':
      'El estudiante forma una traducción con bloques de palabras. Escribe el texto de origen, los bloques literales y una o más traducciones completas correctas. Cada respuesta debe poder construirse con bloques distintos; una palabra repetida requiere bloques repetidos. Pueden sobrar como máximo dos bloques. No se aplica la sintaxis de Type the translation ni tolerancia a erratas.',
  'exerciseHelp.preset.translation_choice_to_target.body':
      'Select, una respuesta y comprobación inmediata. QQL crea la instrucción Pick the correct [Target language] translation según las lenguas del curso. Escribe el texto de origen, de dos a cinco traducciones diferentes y una correcta. Puedes añadir imagen. Elegir mal muestra la respuesta. Después se puede oír la correcta con TTS disponible; el Exercise no depende de audio. Usa distractores plausibles y claramente incorrectos.',
  'exerciseHelp.preset.translation_choice_to_source.body':
      'Select, una respuesta y comprobación inmediata. QQL crea la instrucción Pick the correct [Source language] translation. Escribe el texto en la lengua de estudio, de dos a cinco traducciones diferentes a la lengua base y una correcta. Puedes añadir imagen. Elegir mal muestra la respuesta. Se puede escuchar el texto de la lengua de estudio con TTS disponible; el Exercise no depende de audio.',
  'exerciseHelp.preset.fill_blank.body':
      'El estudiante ve una palabra o frase incompleta y escribe lo que falta. Escribe el prompt, una o más respuestas aceptadas, Hint opcional que no revele la solución y audio opcional de la frase completa. Las respuestas pueden usar variantes.',
  'exerciseHelp.preset.type_missing_word.body':
      'Escribe una frase con un hueco ___ y las palabras completas aceptadas. QQL muestra automáticamente la primera letra Unicode como pista; todas las respuestas deben empezar por la misma. El estudiante escribe la palabra completa, no solo lo que queda después de la pista. Tras comprobar se muestra la frase completa.',
  'exerciseHelp.preset.listening_spelling.body':
      'El estudiante oye audio y escribe lo que escuchó. Introduce Audio text y una transcripción aceptada. Return o Enter envía la respuesta.',
  'exerciseHelp.preset.missing_word.body':
      'El estudiante escucha audio y lee una transcripción con uno o más huecos, luego escribe las palabras ausentes. Introduce la transcripción y Audio text completos, y cada Missing word en orden. Todas deben aparecer en la transcripción.',
  'exerciseHelp.preset.matching.body':
      'El estudiante relaciona elementos de dos columnas mezcladas. Escribe pares no vacíos left = right. La corrección depende de las relaciones, no de las posiciones visibles.',
  'exerciseHelp.preset.word_match.body':
      'El estudiante relaciona palabras de la lengua base con sus traducciones. Escribe exactamente tres pares de texto. Cada elemento visible debe ser único tras la normalización.',
  'exerciseHelp.preset.super_match.body':
      'El estudiante relaciona elementos de la lengua de estudio, como sinónimos u opuestos. Escribe exactamente tres pares y una instrucción que indique la relación. No mezcles reglas distintas.',
  'exerciseHelp.preset.audio_match.body':
      'El estudiante reproduce tres audios y relaciona cada uno con un texto. Escribe exactamente tres pares audio-texto, sin distractores. Cada audio y respuesta visible debe ser único.',
  'exerciseHelp.preset.word_order.body':
      'El estudiante ordena bloques de la lengua de estudio. Escribe los bloques y el orden correcto. Permite como máximo dos distractores distintos; este preset evalúa orden, no traducción.',
  'exerciseHelp.preset.image_word.body':
      'El estudiante ve una imagen y ordena letras o sílabas para formar su palabra. Escribe imagen, instrucción, bloques y orden correcto. Incluye solo los bloques necesarios: no se permiten distractores.',
  'exerciseHelp.preset.flashcard.body':
      'El estudiante ve término, significado, uso opcional y pronunciación opcional y elige Understood o Review later. Aporta material de estudio, no una respuesta puntuable. Presentation Content no da XP de respuesta correcta.',
  'exerciseHelp.preset.choice.description':
      'El estudiante elige la traducción correcta entre varias opciones.',
  'exerciseHelp.preset.gap_choice.description':
      'El estudiante elige la palabra o expresión que falta.',
  'exerciseHelp.preset.icon_choice.description':
      'El estudiante elige la imagen que corresponde al prompt.',
  'exerciseHelp.preset.script_recognition.description':
      'Reconoce caracteres impresos o manuscritos: Image to text o Text to image.',
  'exerciseHelp.preset.listening_choice.description':
      'El estudiante escucha y elige el texto correspondiente.',
  'exerciseHelp.preset.listening_comprehension.description':
      'El estudiante escucha un pasaje y elige la respuesta correcta.',
  'exerciseHelp.preset.reading_comprehension.description':
      'El estudiante lee un pasaje y elige la respuesta correcta.',
  'exerciseHelp.preset.dialogue_response.description':
      'El estudiante lee una situación y elige la mejor respuesta.',
  'exerciseHelp.preset.contextual_comprehension.description':
      'El estudiante lee o escucha un Context y responde una pregunta aparte.',
  'exerciseHelp.preset.type_translation.description':
      'El estudiante escribe una traducción en la lengua de estudio.',
  'exerciseHelp.preset.build_translation.description':
      'El estudiante construye una traducción con bloques de palabras.',
  'exerciseHelp.preset.translation_choice_to_target.description':
      'Select: el estudiante ve texto en la lengua base y elige su traducción.',
  'exerciseHelp.preset.translation_choice_to_source.description':
      'Select: el estudiante ve texto en la lengua de estudio y elige su traducción a la lengua base.',
  'exerciseHelp.preset.fill_blank.description':
      'El estudiante escribe lo que falta en una palabra o frase.',
  'exerciseHelp.preset.type_missing_word.description':
      'Completa la palabra ausente después de ver su primera letra.',
  'exerciseHelp.preset.listening_spelling.description':
      'El estudiante escucha y escribe la palabra o pasaje oído.',
  'exerciseHelp.preset.missing_word.description':
      'El estudiante escucha y completa huecos en una transcripción.',
  'exerciseHelp.preset.matching.description':
      'El estudiante relaciona elementos de texto correspondientes.',
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
  'exerciseHelp.category.multipleChoice': 'Multiple choice',
  'exerciseHelp.category.translation': 'Translation',
  'exerciseHelp.category.textInput': 'Text input',
  'exerciseHelp.category.matching': 'Matching',
  'exerciseHelp.category.ordering': 'Ordering',
  'exerciseHelp.category.presentation': 'Presentation',
  'exerciseHelp.field.choice.prompt.body':
      'Instrucción visible para el estudiante.\n\nQué escribir\nEscribe aquí la instrucción y pon la palabra o frase a traducir en Question.\n\nComprobaciones\nLa instrucción debe corresponder a la pregunta y las respuestas.\n\nEjemplo\nHow do you say this in Italian?',
  'exerciseHelp.field.choice.question.body':
      'Palabra o frase que el estudiante traduce.\n\nQué escribir\nPon el texto en la lengua base separado de Prompt.\n\nComprobaciones\nAñade respuestas correspondientes en la lengua de estudio y marca una correcta.\n\nEjemplo\nGood morning',
  'exerciseHelp.field.choice.answers.body':
      'Alternativas visibles para el estudiante.\n\nQué escribir\nUna respuesta literal por línea, al menos dos. Se ignoran líneas vacías; la primera no vacía es la respuesta 1. La sintaxis de variantes no crea opciones.\n\nComprobaciones\nElige un Correct answer válido. Evita duplicados y distractores ambiguos. Select the image requiere una imagen por respuesta en el mismo orden.\n\nEjemplo\ncaffè\nacqua\npane',
  'exerciseHelp.field.choice.correct.body':
      'Indica la opción o las opciones correctas.\n\nQué escribir\nUn número entero contando desde 1 las líneas no vacías. Con Multiple correct answers, separa los números con comas, por ejemplo 1, 3.\n\nComprobaciones\nCada número debe estar entre 1 y la cantidad de respuestas. Revísalo al reordenar o borrar líneas.\n\nEjemplo\n2 elige la segunda línea no vacía.',
  'exerciseHelp.field.choice.requiredSelections.body':
      'Cantidad mínima de opciones que se deben elegir antes de comprobar una Choice múltiple.\n\nQué escribir\nUn entero entre 1 y la cantidad de respuestas, o déjalo vacío para usar la cantidad de correctas.\n\nComprobaciones\nCheck sigue desactivado hasta llegar a ese mínimo. Se pueden elegir más; para acertar debe coincidir el conjunto exacto.\n\nEjemplo\n2',
  'exerciseHelp.field.choice.gapLayout.body':
      'Frase fija con huecos que el estudiante llena en orden tocando opciones.\n\nQué escribir\nPon cada respuesta entre llaves: I {am} going {to} London. Cada toque llena el primer hueco libre; la posición solo se comprueba al responder. Repite {Was} en cada hueco que lo requiera. Las opciones extra van en Distractor options.\n\nComprobaciones\nSe necesita al menos un hueco {…} no vacío. No uses llaves literales fuera de ellos.\n\nEjemplo\nI {am} going {to} London.',
  'exerciseHelp.field.choice.tokens.body':
      'Opciones que no responden a ningún hueco.\n\nQué escribir\nUna opción extra por línea: cero, una o dos como máximo.\n\nComprobaciones\nNo repitas el texto de una respuesta de hueco.\n\nEjemplo\nperhaps',
  'exerciseHelp.field.choice.tts.body':
      'Texto que escucha el estudiante.\n\nQué escribir\nEscribe las palabras habladas, no una ruta ni nombre de MP3. Varias líneas forman un pasaje. Course Audio Library usa On-Device TTS, Recorded MP3 o Hybrid y asocia grabaciones a palabras o expresiones exactas.\n\nComprobaciones\nLos ejercicios de escucha necesitan Audio text. Revisa Preview y los avisos de Audit sobre grabaciones faltantes.\n\nEjemplo\nVorrei un caffè, per favore.',
  'exerciseHelp.field.choice.image.body':
      'Añade una imagen al prompt o Context.\n\nQué escribir\nElige una imagen de Shared Image Library o deja un PNG, JPEG o WebP en {folderImageImports} y pulsa Import custom image. La importación copia los bytes sin redimensionar ni recortar y no añade la imagen a la biblioteca compartida.\n\nComprobaciones\nMáximo 50 KB; 256 × 256 píxeles y 15 KB son recomendaciones. Solo Image-prompt ordering la exige. Preview comprueba que se vea. Course JSON guarda la ruta, no los bytes.\n\nEjemplo\nassets/exercise_images/house.webp',
  'exerciseHelp.field.gap_choice.question.body':
      'Frase que se completa eligiendo un bloque.\n\nQué escribir\nSustituye la palabra o expresión por ___ (tres guiones bajos), por ejemplo Vorrei un ___, per favore. Escribe las opciones en líneas separadas.\n\nComprobaciones\nHace falta al menos un ___; más de uno genera Warning. Con la respuesta correcta, la frase debe tener al menos dos palabras.\n\nEjemplo\nVorrei un ___, per favore.',
  'exerciseHelp.field.gap_choice.correct.body':
      'Número de la única opción correcta.\n\nQué escribir\nUn entero contando desde 1 las líneas no vacías, no el texto ni un índice JSON.\n\nComprobaciones\nDebe estar dentro de la lista; Dialogue Response solo acepta 1 o 2. Revísalo al cambiar el orden.\n\nEjemplo\n2 elige la segunda línea no vacía.',
  'exerciseHelp.field.gap_choice.hint.body':
      'Pista útil para el estudiante.\n\nQué escribir\nTexto opcional; déjalo vacío si no hace falta. Los saltos de línea siguen en la misma pista.\n\nComprobaciones\nNo reveles la respuesta correcta ni repitas solo el prompt.\n\nEjemplo\nPiensa en una bebida caliente servida en taza pequeña.',
  'exerciseHelp.field.icon_choice.question.body':
      'Pregunta concreta que responde el estudiante.\n\nQué escribir\nUna pregunta en texto, aparte del Context de lectura, audio o diálogo. Los saltos de línea no crean preguntas nuevas.\n\nComprobaciones\nContextual Comprehension requiere pregunta separada. En Dialogue Response usa la lengua de estudio y haz que coincida con la respuesta correcta.\n\nEjemplo\nHow are you?',
  'exerciseHelp.field.icon_choice.icons.body':
      'Asocia cada respuesta de Select the image a una imagen.\n\nQué escribir\nUna clave de icono o ruta assets/ incluida por línea, en el mismo orden que las respuestas. Se ignoran líneas vacías. Hay claves como water, home, coffee, person, hello, sun, moon, tree, bread, train y book.\n\nComprobaciones\nDebe haber tantas claves como respuestas. Una clave desconocida muestra un icono genérico: revisa cada opción con Preview. La imagen general del Exercise es distinta.\n\nEjemplo\ncoffee\nwater\nassets/exercise_images/house.webp',
  'exerciseHelp.field.script_recognition.scriptMode.body':
      'Elige cómo se reconoce un carácter o sílaba.\n\nQué escribir\nImage to text muestra imágenes y respuestas de texto. Text to image muestra texto y respuestas de imagen. Cambiar el modo conserva ambos grupos de campos durante esta edición; Save usa el modo seleccionado.\n\nComprobaciones\nAmbos usan Select con al menos dos opciones y exactamente una correcta.\n\nEjemplo\nMuestra varias formas manuscritas de 가 y pide elegir ga.',
  'exerciseHelp.field.script_recognition.scriptPrompt.body':
      'Texto que el estudiante relaciona con una imagen.\n\nQué escribir\nEscribe carácter, sílaba, sonido o instrucción como texto. Las imágenes de respuesta van en sus campos.\n\nComprobaciones\nText to image requiere prompt no vacío, al menos dos opciones de imagen y una correcta.\n\nEjemplo\nChoose the character pronounced ga.',
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
      'Bloques para construir las traducciones correctas.\n\nQué escribir\nUn bloque literal por línea. Repite la línea si una respuesta necesita esa palabra varias veces. Con Inline gaps, este campo pasa a Extra distractor blocks: las respuestas de hueco están en {answer}.\n\nComprobaciones\nCada traducción debe poder formarse; pueden sobrar como máximo dos bloques. La sintaxis de variantes no se expande.\n\nEjemplo\nIo\nprendo\nvorrei\nun\ncaffè',
  'exerciseHelp.field.build_translation.correctTranslation.body':
      'Una respuesta literal completa para Build the translation.\n\nQué escribir\nUna frase en la lengua de estudio por entrada. Usa Add correct translation para añadir otra y el control de arrastre para ordenarlas.\n\nComprobaciones\nHace falta una respuesta no vacía. Deben ser distintas tras normalizar mayúsculas, espacios y puntuación final y construibles con bloques disponibles. No hay variantes, similitud ni tolerancia a erratas.\n\nEjemplo\nIo vorrei un caffè.',
  'exerciseHelp.field.build_translation.gapLayout.body':
      'Frase fija con huecos que se llenan con bloques.\n\nQué escribir\nEscribe cada respuesta dentro de llaves: I {am} going {to} London. Cada {…} es hueco y respuesta; no se necesita otro campo de respuesta en Inline gaps. Los distractores opcionales van en Extra distractor blocks.\n\nComprobaciones\nAl menos un hueco no vacío. No uses llaves literales en otra parte. Los ejercicios Arrange normales no cambian si Inline gaps está desactivado.\n\nEjemplo\nI {am} going {to} London.',
  'exerciseHelp.field.translation_choice_to_target.question.body':
      'Texto en la lengua base que se traduce.\n\nQué escribir\nUna palabra, frase u oración. No escribas la instrucción: QQL añade Pick the correct [Target language] translation.\n\nComprobaciones\nEs obligatorio, con opciones en la lengua de estudio y exactamente una correcta.',
  'exerciseHelp.field.translation_choice_to_target.answers.body':
      'Traducciones entre las que se elige.\n\nQué escribir\nDe dos a cinco traducciones completas en la lengua de estudio, una por línea. Se ignoran líneas vacías; el orden visible se mezcla.\n\nComprobaciones\nNo repitas frases tras normalizar mayúsculas, espacios y puntuación final. Marca una correcta y usa distractores plausibles.',
  'exerciseHelp.field.translation_choice_to_target.correct.body':
      'Número de la única opción correcta.\n\nQué escribir\nUn entero contando desde 1 las líneas no vacías.\n\nComprobaciones\nDebe estar entre 1 y la cantidad de respuestas. Revísalo al reordenar o borrar líneas.',
  'exerciseHelp.field.translation_choice_to_target.image.body':
      'Imagen opcional del prompt o Context.\n\nQué escribir\nElige una imagen de Shared Image Library o importa un PNG, JPEG o WebP con Import custom image desde {folderImageImports}. Se copia sin cambiar bytes y no entra en la biblioteca compartida.\n\nComprobaciones\nMáximo 50 KB; 256 × 256 píxeles y 15 KB son recomendaciones. Preview debe mostrarla. Course JSON guarda la ruta, no los bytes.',
  'exerciseHelp.field.translation_choice_to_source.question.body':
      'Texto en la lengua de estudio que se traduce.\n\nQué escribir\nUna palabra, frase u oración. QQL añade Pick the correct [Source language] translation automáticamente. Puede reproducirse con TTS, pero el Exercise no lo requiere.\n\nComprobaciones\nEs obligatorio, con opciones en la lengua base y una correcta.',
  'exerciseHelp.field.translation_choice_to_source.answers.body':
      'Traducciones en la lengua base entre las que se elige.\n\nQué escribir\nDe dos a cinco traducciones completas, una por línea. El orden visible se mezcla.\n\nComprobaciones\nNo dejes opciones vacías ni repitas frases tras normalizar; marca una sola correcta y usa distractores claros.',
  'exerciseHelp.field.fill_blank.question.body':
      'Palabra o frase que se completa escribiendo.\n\nQué escribir\nUna palabra o frase incompleta con hueco visible si ayuda. En Accepted answers escribe lo que debe teclear el estudiante, no opciones para elegir.\n\nComprobaciones\nHace falta una respuesta aceptada. Este preset no revela automáticamente la primera letra.\n\nEjemplo\nVorrei un ___.\nAccepted answer: caffè',
  'exerciseHelp.field.fill_blank.accepted.body':
      'Texto completo admitido para llenar el hueco.\n\nQué escribir\nUna respuesta equivalente por línea. Se admiten {Io} opcional, [prendo|vorrei], grupos enlazados [*:il|i] [*:tuo|tuoi] y cambios de orden (non arrivo <> oggi). Usa minúsculas salvo nombres propios.\n\nComprobaciones\nSe necesita una respuesta. Expresiones inválidas o más de 128 expansiones se rechazan; se eliminan duplicados. La sintaxis no inventa traducciones.\n\nEjemplo\ncaffè\nun caffè',
  'exerciseHelp.field.fill_blank.tts.body':
      'Texto opcional de pronunciación de la frase completa.\n\nQué escribir\nUna frase con la respuesta incluida, o déjalo vacío. Es texto para hablar, no ruta de grabación.\n\nComprobaciones\nDebe corresponder a la frase incompleta y las respuestas. Prueba la pronunciación en Preview.\n\nEjemplo\nVorrei un caffè.',
  'exerciseHelp.field.type_missing_word.prompt.body':
      'La palabra ausente completa; la primera letra visible es una pista.\n\nQué escribir\nUna frase con exactamente un hueco ___ y palabras completas aceptadas, una por línea. QQL obtiene automáticamente el primer grafema Unicode; el estudiante escribe la palabra completa.\n\nComprobaciones\nTodas las respuestas deben compartir exactamente ese primer grafema. La pista no se añade a la respuesta.\n\nEjemplo\nJe vais à l’___. Respuesta: école. El estudiante ve é______ y escribe école.',
  'exerciseHelp.field.listening_spelling.prompt.body':
      'Texto visible para Type what you hear.\n\nQué escribir\nUn texto que se muestra tal como está; este preset no quita automáticamente la respuesta. Audio text controla lo que se oye.\n\nComprobaciones\nRevisa Preview para que el prompt no revele la respuesta. Las respuestas escritas van en Missing word.\n\nEjemplo\nListen and type the word you hear.',
  'exerciseHelp.field.listening_spelling.missingWords.body':
      'Respuestas escritas aceptadas por Type what you hear.\n\nQué escribir\nCada línea es una palabra o pasaje completo, no texto que deba ocultarse. Puedes usar {Io}, [prendo|vorrei], grupos enlazados [*:il|i] [*:tuo|tuoi] y reordenación (non arrivo <> oggi).\n\nComprobaciones\nSe necesita al menos una respuesta. Se rechazan expresiones inválidas o más de 128 variantes. Deben corresponder a Audio text; comprueba el prompt visible en Preview.\n\nEjemplo\ncaffè',
  'exerciseHelp.field.missing_word.prompt.body':
      'Transcripción completa desde la que se crean huecos.\n\nQué escribir\nIncluye las palabras que se ocultarán. Usa texto normal, sin puntos o guiones de hueco; los saltos de línea forman el mismo pasaje.\n\nComprobaciones\nCada Missing word debe aparecer en Passage transcript. Audio text debe coincidir con lo que se oye.\n\nEjemplo\nVorrei un caffè, per favore.\nMissing word: caffè',
  'exerciseHelp.field.missing_word.missingWords.body':
      'Palabras o expresiones ocultas en la transcripción.\n\nQué escribir\nUna palabra o expresión literal por línea. Varias líneas crean varios huecos, no respuestas alternativas; no pongas marcadores en la transcripción.\n\nComprobaciones\nAl menos una entrada y todas presentes en Passage transcript, sin distinguir mayúsculas. Los duplicados generan Warning. Aquí no se expande sintaxis de variantes.\n\nEjemplo\ncaffè\nper favore',
  'exerciseHelp.field.matching.prompt.body':
      'Instrucción o Context visible para el estudiante.\n\nQué escribir\nUn texto; los saltos de línea no crean respuestas. Usa la lengua base para instrucciones operativas.\n\nComprobaciones\nDebe corresponder a la pregunta, los pares o los bloques. En Match related words indica la relación en la lengua de estudio.\n\nEjemplo\nBuild the sentence.',
  'exerciseHelp.field.matching.pairs.body':
      'Elementos de las dos columnas para relacionar.\n\nQué escribir\nUn par por línea como left = right. El primer signo igual separa los lados.\n\nComprobaciones\nHace falta al menos un par con ambos lados y separador. Corrige líneas incompletas antes de Preview o Save.\n\nEjemplo\ncasa = house\npane = bread',
  'exerciseHelp.field.word_match.pairs.body':
      'Relaciona palabras de la lengua base con sus traducciones.\n\nQué escribir\nExactamente tres líneas no vacías como source = target; el primer igual separa los lados.\n\nComprobaciones\nLos tres pares necesitan ambos lados y correspondencia única, sin ambigüedad.\n\nEjemplo\nhouse = casa\nbread = pane\nwater = acqua',
  'exerciseHelp.field.super_match.pairs.body':
      'Relaciona palabras de la lengua de estudio, como sinónimos u opuestos.\n\nQué escribir\nExactamente tres líneas left = right, ambos lados en la lengua de estudio. Indica la relación en Match type / instruction.\n\nComprobaciones\nCada par necesita separador y debe seguir la misma relación sin ambigüedad.\n\nEjemplo\ngrande = piccolo\ncaldo = freddo\naperto = chiuso',
  'exerciseHelp.field.audio_match.pairs.body':
      'Relaciona tres audios de la lengua de estudio con sus textos visibles.\n\nQué escribir\nExactamente tres líneas audio text = visible text. El texto visible puede ser la misma lengua o traducción. No hay distractores.\n\nComprobaciones\nAmbos lados son obligatorios y únicos, incluso tras ignorar solo mayúsculas o puntuación. Usa Course Audio Library para grabaciones.\n\nEjemplo\ncasa = house\npane = bread\nacqua = water',
  'exerciseHelp.field.word_order.tokens.body':
      'Bloques para ordenar la frase.\n\nQué escribir\nUn bloque literal en la lengua de estudio por línea. Repite líneas para palabras repetidas. En Inline gaps este campo se llama Extra distractor blocks; las respuestas vienen de {answer} en Sentence with gaps.\n\nComprobaciones\nIncluye cada bloque de Correct sentence y hasta dos distractores no usados. Conserva escritura y puntuación interna.\n\nEjemplo\nIo\nbevo\nun\ncaffè\ntè',
  'exerciseHelp.field.word_order.order.body':
      'Orden correcto de los bloques.\n\nQué escribir\nUn bloque por línea, no toda la frase en una línea. Se unen con espacios. No se usa con Inline gaps, donde las respuestas están en {answer}.\n\nComprobaciones\nCada línea debe coincidir con un bloque disponible, incluidas repeticiones. Es un orden literal: no se expanden variantes.\n\nEjemplo\nIo\nbevo\nun\ncaffè',
  'exerciseHelp.field.image_word.tokens.body':
      'Piezas de la palabra mostrada por la imagen.\n\nQué escribir\nUna letra o sílaba literal por línea; repite si aparece varias veces.\n\nComprobaciones\nIncluye solo las piezas necesarias, sin distractores. Escribe el orden en Correct target-language word y elige una imagen de Exercise.\n\nEjemplo\nca\nsa',
  'exerciseHelp.field.image_word.order.body':
      'Orden de las letras o sílabas.\n\nQué escribir\nUna pieza por línea en el orden correcto. Se unen sin espacios para formar una palabra.\n\nComprobaciones\nUsa cada pieza necesaria una vez, sin distractores, y añade la imagen correspondiente.\n\nEjemplo\nca\nsa\nForman casa.',
  'exerciseHelp.field.flashcard.prompt.body':
      'Material en la lengua de estudio de la Flashcard.\n\nQué escribir\nUna palabra o expresión. El significado, la pronunciación y el ejemplo de uso van en campos separados.\n\nComprobaciones\nEs obligatorio. Flashcard es presentación y no tiene una respuesta puntuada normal.\n\nEjemplo\nbuongiorno',
  'exerciseHelp.field.flashcard.question.body':
      'Significado de la palabra de Flashcard.\n\nQué escribir\nUna explicación o traducción en texto; varias líneas siguen siendo una explicación.\n\nComprobaciones\nUn significado vacío genera Warning de Audit. Comprueba que coincida con la palabra.\n\nEjemplo\ngood morning',
  'exerciseHelp.field.flashcard.tts.body':
      'Pronunciación hablada de Flashcard.\n\nQué escribir\nLa palabra o expresión que debe pronunciarse. No pongas una ruta de grabación; gestiona MP3 en Course Audio Library.\n\nComprobaciones\nSi falta texto de pronunciación, Audit muestra Warning. Comprueba el modo de audio del curso.\n\nEjemplo\nbuongiorno',
  'exerciseHelp.field.flashcard.answers.body':
      'Ejemplo de uso de la palabra de Flashcard.\n\nQué escribir\nPrimera línea no vacía: frase de ejemplo. Segunda línea opcional: traducción. La vista del estudiante añade Usage: automáticamente.\n\nComprobaciones\nSin frase de uso, Audit muestra Warning. Son datos de presentación, no respuestas a elegir.\n\nEjemplo\nBuongiorno, Maria!\nGood morning, Maria!',
};
