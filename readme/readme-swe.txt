QuisquisLingo - Guide för Windows
================================

QuisquisLingo är ett språkinlärningsprogram för elever och kursskapare. Det
kombinerar strukturerade lektioner, interaktiva övningar, ljudaktiviteter och
verktyg för repetition, och innehåller även verktyg för att skapa och redigera
språkkurser.

Det är utformat både för personer som vill lära sig ett språk och för författare,
lärare eller andra användare som vill bygga egna kurser.

En snabb visuell översikt över hur QuisquisLingo fungerar finns i
QQL infographic.png, som ingår i programpaketet.

Starta QuisquisLingo genom att köra QuisquisLingo.exe.

ANVÄNDA PAKETET
---------------

Det här paketet innehåller QQL-programmet. Packa upp hela ZIP-arkivet innan du
startar det och håll alla medföljande filer och mappen data tillsammans.
Distribuera, flytta, radera eller byt inte namn på enskilda EXE- eller DLL-filer.

KONTROLLER VID START
--------------------

Innan start kontrollerar QuisquisLingo de nödvändiga paketfilerna,
Windows-kompatibilitet och Media Foundation. Kontrollerna hämtar eller installerar
aldrig programvara, begär inte administratörsbehörighet, ändrar inte registry
eller Windows.

Ett problem som det går att fortsätta efter ger ett enda meddelande med Continue
anyway och Cancel. Continue anyway försöker starta QQL; Cancel stänger det. Om en
nödvändig programfil saknas visar meddelandet Close eftersom paketet måste hämtas
och packas upp fullständigt på nytt.

Stödet för Wine är Experimental. Om Media Foundation saknas under Wine kan det
hindra start eller göra att ljud- och mediefunktioner inte fungerar.

MICROSOFT VISUAL C++ RUNTIME
----------------------------

Det fullständiga paketet innehåller följande Microsoft Visual C++ x64 runtime-filer:

msvcp140.dll
vcruntime140.dll
vcruntime140_1.dll

Om någon saknas hämtar du det fullständiga QuisquisLingo-paketet för Windows igen
och packar upp allt. Använd endast officiella Microsoft-källor för runtime
installer och hämta aldrig enskilda DLL-filer från tredje parts webbplatser.

Officiell information från Microsoft:
https://learn.microsoft.com/en-us/cpp/windows/latest-supported-vc-redist

MEDIA FOUNDATION
----------------

Windows N-utgåvor kan kräva Microsoft Media Feature Pack för ljud- och
mediefunktioner. Media Feature Pack finns normalt under Windows Optional
Features. I vissa versioner av Windows N finns Media Feature Pack kanske inte
under Optional Features. Hämta i så fall den Media Feature Pack som passar din
Windows-version från Microsofts webbplats.

Starta om Windows när Media Feature Pack har installerats. QuisquisLingo hämtar
eller installerar det inte automatiskt och ändrar inte systeminställningarna.

TEXT-TILL-TAL
-------------

QuisquisLingo använder talröster som är installerade i Windows. Vilka språk och
röster som finns beror på de språk- och röstkomponenter för Windows som är
installerade på datorn. Om ingen kompatibel röst finns installerar du lämplig
komponent via inställningarna i Windows.

Audio Settings > Test Voice läser endast upp den text du skriver in och använder
röstspråket som är inställt för den valda kursen.

LOGGAR OCH DIAGNOSTIK
---------------------

Huvudsaklig crash log lagras här:

Documents\QuisquisLingo\Logs\quisquislingo_crash.log

Loggen för startkontrollen lagras här:

%LOCALAPPDATA%\QuisquisLingo\Logs\quisquislingo_launcher.log

Settings > Debug visar diagnostikalternativ. Loggarna stannar på den lokala
datorn och överförs inte automatiskt.

FELSÖKNING
----------

1. Packa upp hela ZIP-arkivet fullständigt.
2. Kör QuisquisLingo.exe från det uppackade paketet.
3. Om en runtime DLL rapporteras saknad hämtar och packar du upp hela paketet
   igen innan du överväger en officiell Microsoft runtime installer.
4. Om Media Feature Pack krävs följer du anvisningarna ovan och startar om
   Windows efter installationen.
5. Om QQL fortfarande inte startar sparar du hela felmeddelandet och tillgängliga
   loggfiler för support.
