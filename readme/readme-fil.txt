QuisquisLingo - Gabay para sa Windows
====================================

Ang QuisquisLingo ay isang application sa pag-aaral ng wika para sa mga
mag-aaral at gumagawa ng kurso. Pinagsasama nito ang mga nakaayos na aralin,
interaktibong pagsasanay, gawaing may audio, at mga kasangkapan sa pagbabalik-aral,
habang nagbibigay din ng mga kasangkapan sa paggawa at pag-edit ng mga kurso sa
wika.

Dinisenyo ito kapwa para sa mga taong gustong matuto ng wika at sa mga may-akda,
guro, o iba pang gumagamit na gustong gumawa ng sarili nilang mga kurso.

Para sa mabilis na biswal na pangkalahatang-ideya kung paano gumagana ang
QuisquisLingo, tingnan ang QQL infographic.png na kasama sa package ng application.

Para simulan ang QuisquisLingo, patakbuhin ang QuisquisLingo.exe.

PAGGAMIT SA PACKAGE
-------------------

Nasa package na ito ang QQL application. I-extract ang buong ZIP archive bago
ito simulan, at panatilihing magkakasama ang lahat ng kasamang file at ang data
folder. Huwag ipamahagi, ilipat, burahin, o palitan ang pangalan ng mga hiwalay
na EXE o DLL file.

MGA PAGSUSURI SA PAGSISIMULA
----------------------------

Bago magsimula, sinusuri ng QuisquisLingo ang mga kinakailangang file ng package,
pagiging compatible sa Windows, at Media Foundation. Ang mga pagsusuring ito ay
hindi kailanman nagda-download o nag-i-install ng software, humihingi ng
administrator permission, nagbabago ng registry, o gumagawa ng pagbabago sa
Windows.

Kung maaaring magpatuloy sa kabila ng problema, may lalabas na isang mensahe na
may Continue anyway at Cancel. Susubukang simulan ng Continue anyway ang QQL;
isasara ito ng Cancel. Kung may nawawalang mahalagang program file, Close ang
ibibigay ng mensahe dahil kailangang muling i-download at ganap na i-extract ang
package.

Experimental ang suporta sa Wine. Kapag walang Media Foundation sa Wine, maaaring
hindi makapagsimula ang programa o hindi gumana ang mga feature ng audio at media.

MICROSOFT VISUAL C++ RUNTIME
----------------------------

Kasama sa kumpletong package ang mga sumusunod na Microsoft Visual C++ x64
runtime file:

msvcp140.dll
vcruntime140.dll
vcruntime140_1.dll

Kung may nawawala, muling i-download ang kumpletong QuisquisLingo Windows package
at i-extract ang lahat ng laman nito. Gumamit lamang ng opisyal na Microsoft
source para sa runtime installer, at huwag kailanman mag-download ng hiwalay na
DLL file mula sa mga third-party website.

Opisyal na impormasyon mula sa Microsoft:
https://learn.microsoft.com/en-us/cpp/windows/latest-supported-vc-redist

MEDIA FOUNDATION
----------------

Maaaring kailanganin ng mga Windows N edition ang Microsoft Media Feature Pack
para sa audio at media functionality. Karaniwang makikita ang Media Feature Pack
sa Windows Optional Features. Sa ilang bersyon ng Windows N, maaaring wala ang
Media Feature Pack sa Optional Features. Sa ganitong sitwasyon, i-download mula
sa website ng Microsoft ang Media Feature Pack na naaangkop sa iyong bersyon ng
Windows.

I-restart ang Windows pagkatapos i-install ang Media Feature Pack. Hindi ito
awtomatikong dina-download o ini-install ng QuisquisLingo at hindi nito binabago
ang system settings.

TEXT-TO-SPEECH
--------------

Ginagamit ng QuisquisLingo ang mga speech voice na naka-install sa Windows. Ang
mga available na wika at voice ay nakadepende sa mga Windows language at voice
component na naka-install sa computer. Kung walang compatible na voice, i-install
ang naaangkop na component sa pamamagitan ng Windows settings.

Binibigkas lamang ng Audio Settings > Test Voice ang text na inilagay mo at
ginagamit nito ang voice language na itinakda ng napiling kurso.

MGA LOG AT DIAGNOSTIC
---------------------

Dito nakaimbak ang pangunahing crash log:

Documents\QuisquisLingo\Logs\quisquislingo_crash.log

Dito nakaimbak ang log ng pagsusuri sa pagsisimula:

%LOCALAPPDATA%\QuisquisLingo\Logs\quisquislingo_launcher.log

Makikita sa Settings > Debug ang mga diagnostic option. Nananatili sa lokal na
computer ang mga log at hindi awtomatikong ina-upload.

PAGLUTAS NG PROBLEMA
--------------------

1. Ganap na i-extract ang buong ZIP archive.
2. Patakbuhin ang QuisquisLingo.exe mula sa na-extract na package.
3. Kung iniulat na may nawawalang runtime DLL, muling i-download at i-extract ang
   kumpletong package bago isaalang-alang ang opisyal na Microsoft runtime
   installer.
4. Kung kailangan ang Media Feature Pack, sundin ang gabay sa itaas at i-restart
   ang Windows pagkatapos ng pag-install.
5. Kung hindi pa rin nagsisimula ang QQL, itabi ang buong error message at mga
   available na log file para sa suporta.
