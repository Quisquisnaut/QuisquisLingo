QuisquisLingo - Anleitung für Windows
====================================

QuisquisLingo ist eine Anwendung zum Sprachenlernen für Lernende und
Kursersteller. Sie verbindet strukturierte Lektionen, interaktive Übungen,
Audioaktivitäten und Wiederholungswerkzeuge und bietet außerdem Werkzeuge zum
Erstellen und Bearbeiten eigener Sprachkurse.

Sie richtet sich sowohl an Menschen, die eine Sprache lernen möchten, als auch
an Autoren, Lehrkräfte und andere Benutzer, die eigene Kurse erstellen wollen.

Einen schnellen visuellen Überblick über die Funktionsweise von QuisquisLingo
bietet QQL infographic.png, die im Anwendungspaket enthalten ist.

Um QuisquisLingo zu starten, führen Sie QuisquisLingo.exe aus.

VERWENDUNG DES PAKETS
---------------------

Dieses Paket enthält die QQL-Anwendung. Entpacken Sie vor dem Start das gesamte
ZIP-Archiv und lassen Sie alle mitgelieferten Dateien und den Ordner data
zusammen. Verteilen, verschieben, löschen oder benennen Sie einzelne EXE- oder
DLL-Dateien nicht um.

STARTPRÜFUNGEN
-------------

Vor dem Start prüft QuisquisLingo die erforderlichen Paketdateien, die
Windows-Kompatibilität und Media Foundation. Diese Prüfungen laden keine
Software herunter, installieren nichts, fordern keine erhöhten Rechte an,
ändern nicht die Registrierung und nehmen keine Änderungen an Windows vor.

Bei einem behebbaren Problem erscheint eine einzige Meldung mit Continue
anyway und Cancel. Continue anyway versucht QQL zu starten; Cancel schließt es.
Fehlt eine wesentliche Programmdatei, bietet die Meldung Close an, da das Paket
erneut heruntergeladen und vollständig entpackt werden muss.

Die Unterstützung von Wine ist experimentell. Fehlt Media Foundation unter
Wine, funktionieren der Start oder Audio- und Medienfunktionen möglicherweise
nicht.

MICROSOFT VISUAL C++ RUNTIME
----------------------------

Das vollständige Paket enthält diese Microsoft Visual C++ x64-Runtimedateien:

msvcp140.dll
vcruntime140.dll
vcruntime140_1.dll

Fehlt eine davon, laden Sie das vollständige QuisquisLingo-Windows-Paket erneut
herunter und entpacken Sie es vollständig. Verwenden Sie für
Runtime-Installationsprogramme nur offizielle Microsoft-Quellen und laden Sie
niemals einzelne DLL-Dateien von Websites Dritter herunter.

Offizielle Informationen von Microsoft:
https://learn.microsoft.com/en-us/cpp/windows/latest-supported-vc-redist

MEDIA FOUNDATION
----------------

Windows-N-Editionen benötigen für Audio- und Medienfunktionen möglicherweise
Microsoft Media Feature Pack. Normalerweise ist Media Feature Pack unter den
optionalen Windows-Features verfügbar. Bei einigen Versionen von Windows N ist
es dort möglicherweise nicht verfügbar. Laden Sie in diesem Fall das passende
Media Feature Pack für Ihre Windows-Version von der Microsoft-Website herunter.

Starten Sie Windows nach der Installation von Media Feature Pack neu.
QuisquisLingo lädt oder installiert es nicht automatisch und ändert keine
Systemeinstellungen.

SPRACHAUSGABE
-------------

QuisquisLingo verwendet die in Windows installierten Stimmen. Die verfügbaren
Sprachen und Stimmen hängen von den installierten Windows-Sprach- und
Stimmkomponenten ab. Ist keine kompatible Stimme vorhanden, installieren Sie
die passende Komponente über die Windows-Einstellungen.

Audio Settings > Test Voice spricht nur den eingegebenen Text und verwendet die
für den ausgewählten Kurs konfigurierte Stimmsprache.

PROTOKOLLE UND DIAGNOSE
-----------------------

Das Haupt-Absturzprotokoll befindet sich unter:

Documents\QuisquisLingo\Logs\quisquislingo_crash.log

Das Protokoll der Startprüfung befindet sich unter:

%LOCALAPPDATA%\QuisquisLingo\Logs\quisquislingo_launcher.log

Settings > Debug zeigt Diagnoseoptionen. Die Protokolle verbleiben auf dem
lokalen Computer und werden nicht automatisch hochgeladen.

FEHLERBEHEBUNG
--------------

1. Entpacken Sie das vollständige ZIP-Archiv vollständig.
2. Führen Sie QuisquisLingo.exe aus dem entpackten Paket aus.
3. Wird eine fehlende Runtime-DLL gemeldet, laden Sie das vollständige Paket
   erneut herunter und entpacken Sie es, bevor Sie ein offizielles
   Microsoft-Runtime-Installationsprogramm erwägen.
4. Wird Media Feature Pack benötigt, folgen Sie den obigen Hinweisen und
   starten Sie Windows nach der Installation neu.
5. Startet QQL weiterhin nicht, bewahren Sie die vollständige Fehlermeldung und
   die verfügbaren Protokolldateien für den Support auf.
