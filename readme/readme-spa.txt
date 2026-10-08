QuisquisLingo - Guía para Windows
================================

QuisquisLingo es una aplicación para aprender idiomas destinada tanto a
estudiantes como a creadores de cursos. Combina lecciones estructuradas,
ejercicios interactivos, actividades de audio y herramientas de repaso, y
también permite crear y editar cursos de idiomas.

Está diseñada para quienes desean estudiar un idioma y para autores,
profesores u otros usuarios que quieran crear sus propios cursos.

Para ver rápidamente cómo funciona QuisquisLingo, consulta
QQL infographic.png, incluida en el paquete de la aplicación.

Para iniciar QuisquisLingo, ejecuta QuisquisLingo.exe.

USO DEL PAQUETE
---------------

Este paquete contiene la aplicación QQL. Extrae todo el archivo ZIP antes de
iniciarla y conserva juntos todos los archivos suministrados y la carpeta data.
No distribuyas, muevas, elimines ni cambies el nombre de archivos EXE o DLL por
separado.

COMPROBACIONES DE INICIO
------------------------

Antes de iniciarse, QuisquisLingo comprueba los archivos necesarios del
paquete, la compatibilidad con Windows y Media Foundation. Estas comprobaciones
no descargan ni instalan programas, no solicitan privilegios elevados, no
cambian el registro ni modifican Windows.

Un problema recuperable muestra un único mensaje con Continue anyway y Cancel.
Continue anyway intenta iniciar QQL; Cancel lo cierra. Si falta un archivo
esencial del programa, el mensaje ofrece Close porque es necesario volver a
descargar y extraer el paquete.

La compatibilidad con Wine es experimental. Si Media Foundation no está
disponible en Wine, es posible que el inicio o las funciones de audio y
multimedia no funcionen.

RUNTIME DE MICROSOFT VISUAL C++
-------------------------------

El paquete completo incluye estos archivos del runtime Microsoft Visual C++
x64:

msvcp140.dll
vcruntime140.dll
vcruntime140_1.dll

Si falta alguno, vuelve a descargar el paquete completo de QuisquisLingo para
Windows y extráelo por completo. Usa únicamente fuentes oficiales de Microsoft
para los instaladores del runtime y nunca descargues DLL individuales de sitios
de terceros.

Información oficial de Microsoft:
https://learn.microsoft.com/en-us/cpp/windows/latest-supported-vc-redist

MEDIA FOUNDATION
----------------

Las ediciones Windows N pueden necesitar Microsoft Media Feature Pack para las
funciones de audio y multimedia. Normalmente, Media Feature Pack está
disponible en Características opcionales de Windows. En algunas versiones de
Windows N, puede no aparecer allí. En ese caso, descarga desde el sitio web de
Microsoft el Media Feature Pack adecuado para tu versión de Windows.

Reinicia Windows después de instalar Media Feature Pack. QuisquisLingo no lo
descarga ni instala automáticamente y no cambia la configuración del sistema.

SÍNTESIS DE VOZ
---------------

QuisquisLingo usa las voces instaladas en Windows. Los idiomas y las voces
disponibles dependen de los componentes de idioma y voz instalados en el
equipo. Si no hay una voz compatible, instala el componente adecuado desde la
configuración de Windows.

Audio Settings > Test Voice reproduce únicamente el texto que introduzcas y
usa el idioma de voz configurado por el curso seleccionado.

REGISTROS Y DIAGNÓSTICO
-----------------------

El registro principal de fallos se guarda en:

Documents\QuisquisLingo\Logs\quisquislingo_crash.log

El registro de comprobación de inicio se guarda en:

%LOCALAPPDATA%\QuisquisLingo\Logs\quisquislingo_launcher.log

Settings > Debug muestra las opciones de diagnóstico. Los registros permanecen
en el equipo local y no se cargan automáticamente.

SOLUCIÓN DE PROBLEMAS
---------------------

1. Extrae por completo el archivo ZIP.
2. Ejecuta QuisquisLingo.exe desde el paquete extraído.
3. Si se informa de una DLL de runtime ausente, vuelve a descargar y extraer
   el paquete completo antes de considerar un instalador oficial de Microsoft.
4. Si se necesita Media Feature Pack, sigue las indicaciones anteriores y
   reinicia Windows después de instalarlo.
5. Si QQL sigue sin iniciarse, conserva el mensaje de error completo y los
   archivos de registro disponibles para solicitar asistencia.
