QuisquisLingo - Canllaw Windows
===============================

Mae QuisquisLingo yn gymhwysiad dysgu ieithoedd ar gyfer dysgwyr a chrewyr
cyrsiau. Mae'n cyfuno gwersi strwythuredig, ymarferion rhyngweithiol,
gweithgareddau sain ac offer adolygu, ac mae hefyd yn darparu offer ar gyfer
creu a golygu cyrsiau iaith.

Fe'i cynlluniwyd ar gyfer pobl sydd am ddysgu iaith ac ar gyfer awduron,
athrawon neu ddefnyddwyr eraill sydd am lunio eu cyrsiau eu hunain.

I gael trosolwg gweledol cyflym o sut mae QuisquisLingo yn gweithio, gweler
QQL infographic.png, sydd wedi'i gynnwys ym mhecyn y cymhwysiad.

I gychwyn QuisquisLingo, rhedwch QuisquisLingo.exe.

DEFNYDDIO'R PECYN
-----------------

Mae'r pecyn hwn yn cynnwys cymhwysiad QQL. Echdynnwch archif ZIP gyfan cyn ei
gychwyn, a chadwch yr holl ffeiliau a ddarparwyd a'r ffolder data gyda'i gilydd.
Peidiwch â dosbarthu, symud, dileu nac ailenwi ffeiliau EXE neu DLL unigol.

GWIRIADAU CYCHWYN
-----------------

Cyn cychwyn, mae QuisquisLingo yn gwirio ffeiliau gofynnol y pecyn,
cydnawsedd Windows a Media Foundation. Nid yw'r gwiriadau hyn byth yn lawrlwytho
neu osod meddalwedd, yn gofyn am hawliau gweinyddwr, yn newid y registry nac yn
addasu Windows.

Os oes modd parhau ar ôl problem, dangosir un neges gyda Continue anyway a
Cancel. Mae Continue anyway yn ceisio cychwyn QQL; mae Cancel yn ei gau. Os oes
ffeil rhaglen hanfodol ar goll, bydd y neges yn cynnig Close gan fod rhaid
lawrlwytho'r pecyn eto a'i echdynnu'n llawn.

Mae cymorth Wine yn Experimental. Gall diffyg Media Foundation o dan Wine atal
y rhaglen rhag cychwyn neu beri i nodweddion sain a chyfryngau beidio â gweithio.

MICROSOFT VISUAL C++ RUNTIME
----------------------------

Mae'r pecyn cyflawn yn cynnwys y ffeiliau runtime Microsoft Visual C++ x64 hyn:

msvcp140.dll
vcruntime140.dll
vcruntime140_1.dll

Os oes un ar goll, lawrlwythwch becyn Windows cyflawn QuisquisLingo eto a'i
echdynnu'n llawn. Defnyddiwch ffynonellau swyddogol Microsoft yn unig ar gyfer
runtime installer, a pheidiwch byth â lawrlwytho ffeiliau DLL unigol o wefannau
trydydd parti.

Gwybodaeth swyddogol Microsoft:
https://learn.microsoft.com/en-us/cpp/windows/latest-supported-vc-redist

MEDIA FOUNDATION
----------------

Gall fod angen Microsoft Media Feature Pack ar rifynnau Windows N ar gyfer
swyddogaethau sain a chyfryngau. Fel arfer, mae Media Feature Pack ar gael yn
Windows Optional Features. Ar rai fersiynau o Windows N, efallai na fydd Media
Feature Pack ar gael yn Optional Features. Os felly, lawrlwythwch y Media Feature
Pack priodol ar gyfer eich fersiwn chi o Windows o wefan Microsoft.

Ailgychwynnwch Windows ar ôl gosod Media Feature Pack. Nid yw QuisquisLingo yn
ei lawrlwytho na'i osod yn awtomatig ac nid yw'n newid gosodiadau'r system.

TEXT-TO-SPEECH
--------------

Mae QuisquisLingo yn defnyddio'r lleisiau lleferydd sydd wedi'u gosod yn Windows.
Mae'r ieithoedd a'r lleisiau sydd ar gael yn dibynnu ar y cydrannau iaith a llais
Windows sydd wedi'u gosod ar y cyfrifiadur. Os nad oes llais cydnaws ar gael,
gosodwch y gydran briodol drwy osodiadau Windows.

Dim ond y testun rydych yn ei roi y mae Audio Settings > Test Voice yn ei
lefaru, ac mae'n defnyddio iaith y llais sydd wedi'i ffurfweddu gan y cwrs dan
sylw.

LOGIAU A DIAGNOSTEG
-------------------

Cedwir y prif crash log yn:

Documents\QuisquisLingo\Logs\quisquislingo_crash.log

Cedwir log y gwiriadau cychwyn yn:

%LOCALAPPDATA%\QuisquisLingo\Logs\quisquislingo_launcher.log

Mae Settings > Debug yn dangos opsiynau diagnostig. Mae logiau'n aros ar y
cyfrifiadur lleol ac nid ydynt yn cael eu huwchlwytho'n awtomatig.

DATRYS PROBLEMAU
----------------

1. Echdynnwch archif ZIP gyfan yn llwyr.
2. Rhedwch QuisquisLingo.exe o'r pecyn sydd wedi'i echdynnu.
3. Os adroddir bod runtime DLL ar goll, lawrlwythwch ac echdynnwch y pecyn
   cyflawn eto cyn ystyried runtime installer swyddogol Microsoft.
4. Os oes angen Media Feature Pack, dilynwch y cyfarwyddyd uchod ac
   ailgychwynnwch Windows ar ôl ei osod.
5. Os nad yw QQL yn cychwyn o hyd, cadwch y neges gwall gyflawn a'r ffeiliau log
   sydd ar gael at ddibenion cymorth.
