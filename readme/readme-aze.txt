QuisquisLingo - Windows bələdçisi
================================

QuisquisLingo öyrənənlər və kurs yaradıcıları üçün dil öyrənmə tətbiqidir.
O, strukturlaşdırılmış dərsləri, interaktiv tapşırıqları, səs fəaliyyətlərini və
təkrar alətlərini birləşdirir, həmçinin dil kursları yaratmaq və redaktə etmək
üçün alətlər təqdim edir.

Tətbiq həm dil öyrənmək istəyən insanlar, həm də öz kurslarını hazırlamaq istəyən
müəlliflər, müəllimlər və digər istifadəçilər üçün nəzərdə tutulub.

QuisquisLingo-nun necə işlədiyinə dair qısa vizual baxış üçün tətbiq paketinə
daxil edilmiş QQL infographic.png faylına baxın.

QuisquisLingo-nu başlatmaq üçün QuisquisLingo.exe faylını işə salın.

PAKETDƏN İSTİFADƏ
-----------------

Bu paket QQL tətbiqini ehtiva edir. Başlatmazdan əvvəl bütün ZIP arxivini açın
və verilmiş bütün faylları data qovluğu ilə birlikdə saxlayın. Ayrı-ayrı EXE və
ya DLL fayllarını paylaşmayın, köçürməyin, silməyin və adlarını dəyişməyin.

BAŞLANĞIC YOXLAMALARI
---------------------

Başlatmazdan əvvəl QuisquisLingo tələb olunan paket fayllarını, Windows ilə
uyğunluğu və Media Foundation-u yoxlayır. Bu yoxlamalar heç vaxt proqram təminatı
yükləmir və quraşdırmır, administrator icazəsi istəmir, registry-ni və ya
Windows-u dəyişmir.

Davam etməyə imkan verən problem olduqda Continue anyway və Cancel seçimləri
olan bir mesaj göstərilir. Continue anyway QQL-i başlatmağa cəhd edir; Cancel onu
bağlayır. Vacib proqram faylı yoxdursa, mesaj Close seçimini təqdim edir, çünki
paket yenidən endirilməli və tam açılmalıdır.

Wine dəstəyi Experimental vəziyyətindədir. Wine mühitində Media Foundation-un
olmaması başlanğıca mane ola və ya səs və media funksiyalarının işləməməsinə
səbəb ola bilər.

MICROSOFT VISUAL C++ RUNTIME
----------------------------

Tam paketə aşağıdakı Microsoft Visual C++ x64 runtime faylları daxildir:

msvcp140.dll
vcruntime140.dll
vcruntime140_1.dll

Onlardan biri yoxdursa, tam QuisquisLingo Windows paketini yenidən endirin və
bütünlüklə açın. Runtime installer üçün yalnız rəsmi Microsoft mənbələrindən
istifadə edin və ayrı-ayrı DLL fayllarını heç vaxt üçüncü tərəf saytlarından
endirməyin.

Microsoft-un rəsmi məlumatı:
https://learn.microsoft.com/en-us/cpp/windows/latest-supported-vc-redist

MEDIA FOUNDATION
----------------

Windows N buraxılışları səs və media funksiyaları üçün Microsoft Media Feature
Pack tələb edə bilər. Media Feature Pack adətən Windows Optional Features
bölməsində mövcuddur. Windows N-in bəzi versiyalarında Media Feature Pack
Optional Features daxilində olmaya bilər. Bu halda Windows versiyanıza uyğun
Media Feature Pack-i Microsoft saytından endirin.

Media Feature Pack quraşdırıldıqdan sonra Windows-u yenidən başladın.
QuisquisLingo onu avtomatik endirmir və ya quraşdırmır və sistem parametrlərini
dəyişmir.

MƏTNDƏN NİTQƏ
--------------

QuisquisLingo Windows-da quraşdırılmış nitq səslərindən istifadə edir. Mövcud
dillər və səslər kompüterdə quraşdırılmış Windows dil və səs komponentlərindən
asılıdır. Uyğun səs yoxdursa, Windows parametrlərindən müvafiq komponenti
quraşdırın.

Audio Settings > Test Voice yalnız daxil etdiyiniz mətni səsləndirir və seçilmiş
kursda təyin olunmuş səs dilindən istifadə edir.

JURNALLAR VƏ DİAQNOSTİKA
------------------------

Əsas crash log burada saxlanılır:

Documents\QuisquisLingo\Logs\quisquislingo_crash.log

Başlanğıc yoxlamasının log faylı burada saxlanılır:

%LOCALAPPDATA%\QuisquisLingo\Logs\quisquislingo_launcher.log

Settings > Debug diaqnostika seçimlərini göstərir. Log faylları yerli kompüterdə
qalır və avtomatik yüklənmir.

PROBLEMLƏRİN HƏLLİ
------------------

1. Bütün ZIP arxivini tam açın.
2. Açılmış paketdən QuisquisLingo.exe faylını işə salın.
3. Runtime DLL-in çatışmadığı bildirilirsə, rəsmi Microsoft runtime installer
   seçimini nəzərdən keçirməzdən əvvəl tam paketi yenidən endirin və açın.
4. Media Feature Pack tələb olunursa, yuxarıdakı göstərişlərə əməl edin və
   quraşdırmadan sonra Windows-u yenidən başladın.
5. QQL hələ də başlamırsa, dəstək üçün tam xəta mesajını və mövcud log fayllarını
   saxlayın.
