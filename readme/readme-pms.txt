QuisquisLingo - Guida për Windows
================================

QuisquisLingo a l'é n'aplicassion për amprende le lenghe, pensà për j'aprendiss
e për chi a crea cors. A buta ansema lesson struturà, esercissi interativ,
atività audio e utiss për l'arpass, e a dà ëdcò dj'utiss për creé e modifiché
di cors ëd lenga.

A l'é progetà sia për le përson-e ch'a veulo amprende na lenga, sia për autor,
ansegnant o d'àutri utent ch'a veulo fé ij sò cors.

Për avej na curta presentassion visual ëd com QuisquisLingo a marcia, ch'a
varda QQL infographic.png, comprèisa ant ël package ëd l'aplicassion.

Për avijé QuisquisLingo, ch'a fasa parte QuisquisLingo.exe.

DOVRÉ ËL PACKAGE
----------------

Sto package a conten l'aplicassion QQL. Ch'a dëscompata tut l'archivi ZIP
primma d'avijelo e ch'a ten-a ansema tuti ij file dàit e la cartela data. Ch'a
distribuissa pa, tramuda pa, dëscancela pa e arcàmbia pa ël nòm a dij singoj
file EXE o DLL.

CONTRÒJ A L'AVIAMENT
-------------------

Primma ëd parte, QuisquisLingo a contròla ij file necessàri dël package, la
compatibilità con Windows e Media Foundation. Sti contròj a dëscario pa e a
nstalo pa ëd programa, a ciamo pa ij drit d'aministrator, a modìfico pa ël
registry e a cambio pa Windows.

Na dificultà ch'a përmet ëd continué a fà vëdde un messagi sol con Continue
anyway e Cancel. Continue anyway a preuva a avijé QQL; Cancel a lo sara. S'a
manca un file essensial dël programa, ël messagi a propon Close përchè a venta
dëscarié torna ël package e dëscompatalo tut.

Ël suport për Wine a l'é Experimental. Se Media Foundation a manca sota Wine,
ël programa a peul pa parte o le funsion audio e media a peulo pa travajé.

MICROSOFT VISUAL C++ RUNTIME
----------------------------

Ël package complet a conten sti file runtime Microsoft Visual C++ x64:

msvcp140.dll
vcruntime140.dll
vcruntime140_1.dll

S'a na manca un, ch'a dëscaria torna ël package Windows complet ëd
QuisquisLingo e ch'a lo dëscompata tut. Për runtime installer, ch'a deuvra mach
le sorgiss ofissiaj ëd Microsoft e ch'a dëscaria mai dij file DLL singoj da
sit ëd ters.

Anformassion ofissiaj Microsoft:
https://learn.microsoft.com/en-us/cpp/windows/latest-supported-vc-redist

MEDIA FOUNDATION
----------------

Le edission Windows N a peulo avèj da manca dël Microsoft Media Feature Pack
për le funsion audio e media. Normalment Media Feature Pack a l'é disponìbil an
Windows Optional Features. An chèich version ëd Windows N, Media Feature Pack a
peul pa esse disponìbil an Optional Features. An col cas, ch'a dëscaria dal sit
Microsoft ël Media Feature Pack giust për soa version ëd Windows.

Ch'a aravìa Windows apress l'instalassion ëd Media Feature Pack. QuisquisLingo
a lo dëscaria pa e a lo nstala pa automaticament, e a cambia pa le regolassion
dël sistema.

TEXT-TO-SPEECH
--------------

QuisquisLingo a deuvra le vos ëd paròla nstalà an Windows. Le lenghe e le vos
disponìbij a dipendo dai component ëd lenga e ëd vos Windows nstalà an slë
computer. Se gnun-a vos compatìbil a l'é disponìbil, ch'a nstala ël component
giust con le regolassion ëd Windows.

Audio Settings > Test Voice a les mach ël test ch'a l'ha scrivù e a deuvra la
lenga dla vos configurà dal cors selessionà.

LOG E DIAGNÒSTICA
-----------------

Ël crash log prinsipal a ven salvà ambelessì:

Documents\QuisquisLingo\Logs\quisquislingo_crash.log

Ël log dij contròj a l'aviament a ven salvà ambelessì:

%LOCALAPPDATA%\QuisquisLingo\Logs\quisquislingo_launcher.log

Settings > Debug a fà vëdde le opsion ëd diagnòstica. Ij log a resto an slë
computer local e a son pa carià automaticament.

GAVESSE DA LE DIFICULTÀ
-----------------------

1. Ch'a dëscompata tut l'archivi ZIP.
2. Ch'a fasa parte QuisquisLingo.exe dal package dëscompatà.
3. Se a ven signalà che un runtime DLL a manca, ch'a dëscaria e dëscompata torna
   ël package complet primma ëd pensé a un runtime installer ofissial Microsoft.
4. Se Media Feature Pack a serv, ch'a vada dapress a le anformassion sì-dzora e
   ch'a aravìa Windows apress l'instalassion.
5. Se QQL a part ancora pa, ch'a ten-a ël messagi d'eror complet e ij file log
   disponìbij për l'assistensa.
