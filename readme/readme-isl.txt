QuisquisLingo - Leiðbeiningar fyrir Windows
==========================================

QuisquisLingo er tungumálanámsforrit fyrir nemendur og höfunda námskeiða. Það
sameinar skipulagðar kennslustundir, gagnvirkar æfingar, hljóðverkefni og
upprifjunarverkfæri, auk verkfæra til að búa til og breyta tungumálanámskeiðum.

Það er hannað bæði fyrir fólk sem vill læra tungumál og fyrir höfunda, kennara
eða aðra notendur sem vilja útbúa sín eigin námskeið.

Fljótlegt myndrænt yfirlit yfir virkni QuisquisLingo er að finna í
QQL infographic.png, sem fylgir forritspakkanum.

Til að ræsa QuisquisLingo skaltu keyra QuisquisLingo.exe.

NOTKUN PAKKANS
--------------

Þessi pakki inniheldur QQL-forritið. Afþjappaðu öllu ZIP-safninu áður en þú
ræsir það og geymdu allar meðfylgjandi skrár og möppuna data saman. Ekki dreifa,
færa, eyða eða endurnefna stakar EXE- eða DLL-skrár.

RÆSINGARPRÓFANIR
----------------

Áður en QuisquisLingo er ræst kannar það nauðsynlegar pakkaskrár, samhæfni við
Windows og Media Foundation. Þessar prófanir sækja aldrei eða setja upp hugbúnað,
biðja ekki um stjórnandaréttindi, breyta ekki registry né Windows.

Ef unnt er að halda áfram þrátt fyrir vandamál birtast ein skilaboð með Continue
anyway og Cancel. Continue anyway reynir að ræsa QQL; Cancel lokar því. Ef
nauðsynlega forritsskrá vantar bjóða skilaboðin Close, því sækja þarf pakkann
aftur og afþjappa honum að fullu.

Stuðningur við Wine er Experimental. Ef Media Foundation vantar í Wine getur
það komið í veg fyrir ræsingu eða valdið því að hljóð- og miðlunareiginleikar
virki ekki.

MICROSOFT VISUAL C++ RUNTIME
----------------------------

Heildarpakkinn inniheldur eftirfarandi Microsoft Visual C++ x64 runtime-skrár:

msvcp140.dll
vcruntime140.dll
vcruntime140_1.dll

Ef einhver þeirra vantar skaltu sækja heildarpakka QuisquisLingo fyrir Windows
aftur og afþjappa honum að fullu. Notaðu aðeins opinberar heimildir Microsoft
fyrir runtime installer og sæktu aldrei stakar DLL-skrár af vefsvæðum þriðju
aðila.

Opinberar upplýsingar Microsoft:
https://learn.microsoft.com/en-us/cpp/windows/latest-supported-vc-redist

MEDIA FOUNDATION
----------------

Windows N-útgáfur kunna að krefjast Microsoft Media Feature Pack fyrir hljóð-
og miðlunaraðgerðir. Media Feature Pack er venjulega aðgengilegt undir Windows
Optional Features. Í sumum útgáfum af Windows N er Media Feature Pack mögulega
ekki aðgengilegt undir Optional Features. Sæktu þá Media Feature Pack sem hæfir
þinni útgáfu af Windows af vef Microsoft.

Endurræstu Windows eftir uppsetningu Media Feature Pack. QuisquisLingo sækir
það ekki eða setur það upp sjálfkrafa og breytir ekki kerfisstillingum.

TEXTI Í TAL
-----------

QuisquisLingo notar talraddir sem eru uppsettar í Windows. Tiltæk tungumál og
raddir fara eftir tungumála- og raddhlutum Windows sem eru uppsettir í tölvunni.
Ef engin samhæf rödd er tiltæk skaltu setja viðeigandi hlut upp í stillingum
Windows.

Audio Settings > Test Voice les aðeins upp textann sem þú slærð inn og notar
raddtungumálið sem valið námskeið skilgreinir.

ANNÁLAR OG GREINING
-------------------

Aðal crash log er vistað hér:

Documents\QuisquisLingo\Logs\quisquislingo_crash.log

Log ræsiprófunarinnar er vistað hér:

%LOCALAPPDATA%\QuisquisLingo\Logs\quisquislingo_launcher.log

Settings > Debug sýnir greiningarvalkosti. Log-skrárnar eru áfram á tölvunni og
er ekki hlaðið upp sjálfkrafa.

ÚRRÆÐALEIT
----------

1. Afþjappaðu öllu ZIP-safninu að fullu.
2. Keyrðu QuisquisLingo.exe úr afþjappaða pakkanum.
3. Ef tilkynnt er um runtime DLL sem vantar skaltu sækja og afþjappa allan
   pakkann aftur áður en þú íhugar opinberan Microsoft runtime installer.
4. Ef Media Feature Pack er nauðsynlegt skaltu fylgja leiðbeiningunum hér að
   ofan og endurræsa Windows eftir uppsetningu.
5. Ef QQL ræsist enn ekki skaltu geyma öll villuskilaboðin og tiltækar log-skrár
   fyrir aðstoð.
