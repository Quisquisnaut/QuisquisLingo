QuisquisLingo - Sturlevr Windows
===============================

QuisquisLingo zo un arload evit deskiñ yezhoù, graet evit an deskidi hag ar re
a grou kentelioù. Ennañ e kaver kentelioù frammennet, poelladennoù etreoberiat,
obererezhioù son ha binvioù adwelet, hag ivez binvioù evit krouiñ hag embann
kentelioù yezh.

Graet eo evit an dud a fell dezho deskiñ ur yezh hag evit ar skrivagnerien, ar
gelennerien pe an implijerien all a fell dezho sevel o c'hentelioù dezho o-unan.

Evit gwelout buan, dre skeudennoù, penaos ez a QuisquisLingo en-dro, sellit ouzh
QQL infographic.png, lakaet e-barzh pakad an arload.

Evit loc'hañ QuisquisLingo, erounezit QuisquisLingo.exe.

IMPLIJOUT AR PAKAD
------------------

An arload QQL zo er pakad-mañ. Diwrazit dielloù ar ZIP penn-da-benn a-raok
loc'hañ anezhañ, ha dalc'hit an holl restroù pourchaset hag an teuliad data
a-gevret. Arabat ingalañ, dilec'hiañ, dilemel pe adenvel restroù EXE pe DLL
unan-ha-unan.

GWIRIAÑ E-KERZH AL LOC'HAÑ
-------------------------

A-raok loc'hañ e wirieka QuisquisLingo restroù ret ar pakad, kenglotusted Windows
ha Media Foundation. Ar gwiriadennoù-se ne bellgargont ha ne staliont meziant ebet,
ne c'houlennont ket gwirioù merour, ne cheñchont ket ar registry ha ne gemmont
ket Windows.

Pa c'haller kenderc'hel daoust d'ur gudenn e vez diskouezet ur gemennadenn gant
Continue anyway ha Cancel. Continue anyway a glask loc'hañ QQL; Cancel a serr
anezhañ. Ma vank ur restr ret evit ar goulev e kinnigo ar gemennadenn Close, rak
ret eo pellgargañ ar pakad en-dro ha diwrazañ anezhañ penn-da-benn.

Experimental eo ar skor evit Wine. Ma n'eus ket Media Foundation dindan Wine e
c'hall al loc'hañ c'hwitañ, pe ne c'hall ket an arc'hwelioù son ha media mont
en-dro.

MICROSOFT VISUAL C++ RUNTIME
----------------------------

Er pakad klok emañ ar restroù runtime Microsoft Visual C++ x64-mañ:

msvcp140.dll
vcruntime140.dll
vcruntime140_1.dll

Ma vank unan anezho, pellgargit en-dro pakad Windows klok QuisquisLingo ha
diwrazit anezhañ penn-da-benn. Evit runtime installer, grit gant mammennoù
ofisiel Microsoft hepken, ha na bellgargit morse restroù DLL unan-ha-unan diwar
lec'hiennoù trede.

Titouroù ofisiel Microsoft:
https://learn.microsoft.com/en-us/cpp/windows/latest-supported-vc-redist

MEDIA FOUNDATION
----------------

E stummoù Windows N e c'hall bezañ ret kaout Microsoft Media Feature Pack evit
an arc'hwelioù son ha media. Peurliesañ e vez kavet Media Feature Pack e Windows
Optional Features. E stummoù zo eus Windows N e c'hall Media Feature Pack bezañ
diank diouzh Optional Features. En degouezh-se, pellgargit diwar lec'hienn
Microsoft ar Media Feature Pack a glot gant ho stumm Windows.

Adloc'hit Windows goude bezañ staliet Media Feature Pack. QuisquisLingo ne
bellgarg hag ne stal anezhañ ent emgefreek, ha ne gemm ket arventennoù ar reizhiad.

TEXT-TO-SPEECH
--------------

QuisquisLingo a implij ar mouezhioù komz staliet e Windows. Ar yezhoù hag ar
mouezhioù hegerz a zalc'h d'ar parzhioù yezh ha mouezh Windows staliet war an
urzhiataer. Ma n'eus mouezh kenglotus ebet, staliit ar parzh dereat dre arventennoù
Windows.

Audio Settings > Test Voice a lavar an destenn enskrivet ganeoc'h hepken hag a
implij yezh ar vouezh kefluniet gant ar gentel dibabet.

LOGOÙ HA DIAGNOSTIK
-------------------

Amañ e vez miret ar crash log pennañ:

Documents\QuisquisLingo\Logs\quisquislingo_crash.log

Amañ e vez miret log ar gwiriadennoù loc'hañ:

%LOCALAPPDATA%\QuisquisLingo\Logs\quisquislingo_launcher.log

Settings > Debug a ziskouez dibarzhioù diagnostik. Chom a ra al logoù war an
urzhiataer lec'hel ha ne vezont ket karget enlinenn ent emgefreek.

DISKOULMAÑ KUDENNOÙ
-------------------

1. Diwrazit dielloù ar ZIP penn-da-benn.
2. Erounezit QuisquisLingo.exe eus ar pakad diwrazet.
3. Ma vez kemennet e vank ur runtime DLL, pellgargit ha diwrazit ar pakad klok
   en-dro a-raok soñjal e runtime installer ofisiel Microsoft.
4. Ma vez ret Media Feature Pack, heuilhit ar sturioù a-us hag adloc'hit Windows
   goude bezañ staliet anezhañ.
5. Ma ne loc'h ket QQL c'hoazh, mirit ar gemennadenn fazi glok hag ar restroù log
   hegerz evit ar skoazell.
