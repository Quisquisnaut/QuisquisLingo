QuisquisLingo - Mwongozo wa Windows
===================================

QuisquisLingo ni programu ya kujifunza lugha kwa wanafunzi na waundaji wa kozi.
Inaunganisha masomo yaliyopangwa, mazoezi shirikishi, shughuli za sauti na zana
za marudio, huku pia ikitoa zana za kuunda na kuhariri kozi za lugha.

Imeundwa kwa watu wanaotaka kujifunza lugha na pia kwa waandishi, walimu au
watumiaji wengine wanaotaka kutengeneza kozi zao wenyewe.

Kwa muhtasari wa haraka wa kuona jinsi QuisquisLingo inavyofanya kazi, tazama
QQL infographic.png iliyojumuishwa katika kifurushi cha programu.

Ili kuanzisha QuisquisLingo, endesha QuisquisLingo.exe.

KUTUMIA KIFURUSHI
-----------------

Kifurushi hiki kina programu ya QQL. Fungua kumbukumbu yote ya ZIP kabla ya
kuanzisha programu, na uweke faili zote zilizotolewa pamoja na folda ya data
mahali pamoja. Usisambaze, usihamishe, usifute wala kubadili jina la faili
moja moja za EXE au DLL.

UKAGUZI WA KUANZA
-----------------

Kabla ya kuanza, QuisquisLingo hukagua faili muhimu za kifurushi, uoanifu wa
Windows na Media Foundation. Ukaguzi huu haupakui wala kusakinisha programu,
hauombi mamlaka ya msimamizi, haubadili registry wala kufanya mabadiliko katika
Windows.

Tatizo linaloruhusu kuendelea huonyesha ujumbe mmoja wenye Continue anyway na
Cancel. Continue anyway hujaribu kuanzisha QQL; Cancel huifunga. Faili muhimu ya
programu ikikosekana, ujumbe hutoa Close kwa sababu ni lazima kifurushi kipakuliwe
na kufunguliwa tena kikamilifu.

Usaidizi wa Wine ni Experimental. Kukosekana kwa Media Foundation katika Wine
kunaweza kuzuia programu kuanza au kufanya vipengele vya sauti na media visifanye
kazi.

MICROSOFT VISUAL C++ RUNTIME
----------------------------

Kifurushi kamili kina faili hizi za runtime za Microsoft Visual C++ x64:

msvcp140.dll
vcruntime140.dll
vcruntime140_1.dll

Faili yoyote ikikosekana, pakua tena kifurushi kamili cha QuisquisLingo cha
Windows na ukifungue chote. Tumia vyanzo rasmi vya Microsoft pekee kwa runtime
installer, na kamwe usipakue faili moja moja za DLL kutoka tovuti za watu wengine.

Maelezo rasmi ya Microsoft:
https://learn.microsoft.com/en-us/cpp/windows/latest-supported-vc-redist

MEDIA FOUNDATION
----------------

Matoleo ya Windows N yanaweza kuhitaji Microsoft Media Feature Pack kwa utendaji
wa sauti na media. Kwa kawaida Media Feature Pack hupatikana katika Windows
Optional Features. Katika baadhi ya matoleo ya Windows N, Media Feature Pack
inaweza kutopatikana katika Optional Features. Hali hiyo ikitokea, pakua Media
Feature Pack inayofaa toleo lako la Windows kutoka tovuti ya Microsoft.

Anzisha Windows upya baada ya kusakinisha Media Feature Pack. QuisquisLingo
haipakui wala kuisakinisha kiotomatiki na haibadili mipangilio ya mfumo.

TEXT-TO-SPEECH
--------------

QuisquisLingo hutumia sauti za usemi zilizosakinishwa katika Windows. Lugha na
sauti zinazopatikana hutegemea vipengele vya lugha na sauti vya Windows
vilivyosakinishwa kwenye kompyuta. Ikiwa hakuna sauti inayooana, sakinisha
kipengele kinachofaa kupitia mipangilio ya Windows.

Audio Settings > Test Voice hutamka maandishi unayoingiza pekee na hutumia lugha
ya sauti iliyosanidiwa na kozi iliyochaguliwa.

LOG NA UCHUNGUZI
----------------

Crash log kuu huhifadhiwa hapa:

Documents\QuisquisLingo\Logs\quisquislingo_crash.log

Log ya ukaguzi wa kuanza huhifadhiwa hapa:

%LOCALAPPDATA%\QuisquisLingo\Logs\quisquislingo_launcher.log

Settings > Debug huonyesha chaguo za uchunguzi. Log hubaki kwenye kompyuta ya
ndani na hazipakuliwi kiotomatiki.

UTATUZI WA MATATIZO
-------------------

1. Fungua kumbukumbu yote ya ZIP kikamilifu.
2. Endesha QuisquisLingo.exe kutoka kwenye kifurushi kilichofunguliwa.
3. Ukijulishwa kuwa runtime DLL haipo, pakua na ufungue tena kifurushi kamili
   kabla ya kufikiria kutumia runtime installer rasmi ya Microsoft.
4. Ikiwa Media Feature Pack inahitajika, fuata mwongozo ulio juu na uanzishe
   Windows upya baada ya kuisakinisha.
5. Ikiwa QQL bado haianzi, hifadhi ujumbe kamili wa hitilafu na faili za log
   zinazopatikana kwa ajili ya usaidizi.
