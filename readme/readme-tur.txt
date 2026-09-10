QuisquisLingo - Windows Kılavuzu
===============================

QuisquisLingo, dil öğrenenler ve kurs hazırlayanlar için bir dil öğrenme
uygulamasıdır. Yapılandırılmış dersleri, etkileşimli alıştırmaları, sesli
etkinlikleri ve tekrar araçlarını bir araya getirirken dil kursu oluşturma ve
düzenleme araçları da sunar.

Hem bir dil öğrenmek isteyen kişiler hem de kendi kurslarını hazırlamak isteyen
yazarlar, öğretmenler ve diğer kullanıcılar için tasarlanmıştır.

QuisquisLingo'nun nasıl çalıştığına hızlıca göz atmak için uygulama paketinde
bulunan QQL infographic.png dosyasına bakın.

QuisquisLingo'yu başlatmak için QuisquisLingo.exe dosyasını çalıştırın.

PAKETİN KULLANIMI
-----------------

Bu paket QQL uygulamasını içerir. Başlatmadan önce ZIP arşivinin tamamını
çıkarın ve sağlanan tüm dosyalarla data klasörünü bir arada tutun. EXE veya DLL
dosyalarını tek başına dağıtmayın, taşımayın, silmeyin ya da yeniden
adlandırmayın.

BAŞLANGIÇ DENETİMLERİ
---------------------

QuisquisLingo başlamadan önce gerekli paket dosyalarını, Windows uyumluluğunu ve
Media Foundation bileşenini denetler. Bu denetimler yazılım indirmez veya
kurmaz, yükseltilmiş yetki istemez, kayıt defterini değiştirmez ve Windows'ta
değişiklik yapmaz.

Giderilebilir bir sorunda Continue anyway ve Cancel seçeneklerini içeren tek bir
ileti gösterilir. Continue anyway QQL'yi başlatmayı dener; Cancel programı
kapatır. Temel bir program dosyası eksikse ileti yalnızca Close seçeneğini
sunar; paketin yeniden indirilip tamamen çıkarılması gerekir.

Wine desteği deneyseldir. Wine ortamında Media Foundation eksikse program
başlamayabilir veya ses ve medya özellikleri çalışmayabilir.

MICROSOFT VISUAL C++ ÇALIŞMA ZAMANI
-----------------------------------

Tam paket şu Microsoft Visual C++ x64 çalışma zamanı dosyalarını içerir:

msvcp140.dll
vcruntime140.dll
vcruntime140_1.dll

Bunlardan biri eksikse QuisquisLingo Windows paketinin tamamını yeniden indirin
ve bütünüyle çıkarın. Çalışma zamanı yükleyicileri için yalnızca resmi Microsoft
kaynaklarını kullanın ve üçüncü taraf sitelerden asla tek tek DLL dosyaları
indirmeyin.

Resmi Microsoft bilgileri:
https://learn.microsoft.com/en-us/cpp/windows/latest-supported-vc-redist

MEDIA FOUNDATION
----------------

Windows N sürümlerinde ses ve medya işlevleri için Microsoft Media Feature Pack
gerekebilir. Media Feature Pack normalde Windows İsteğe Bağlı Özellikler
bölümünde bulunur. Bazı Windows N sürümlerinde bu bölümde yer almayabilir. Böyle
bir durumda Windows sürümünüze uygun Media Feature Pack paketini Microsoft web
sitesinden indirin.

Media Feature Pack kurulduktan sonra Windows'u yeniden başlatın. QuisquisLingo
bu paketi otomatik olarak indirmez veya kurmaz ve sistem ayarlarını değiştirmez.

METİNDEN KONUŞMAYA
------------------

QuisquisLingo, Windows'ta yüklü konuşma seslerini kullanır. Kullanılabilir
diller ve sesler bilgisayarda yüklü Windows dil ve ses bileşenlerine bağlıdır.
Uyumlu bir ses yoksa uygun bileşeni Windows ayarlarından yükleyin.

Audio Settings > Test Voice yalnızca girdiğiniz metni seslendirir ve seçili
kursta yapılandırılan ses dilini kullanır.

GÜNLÜKLER VE TANI
-----------------

Ana çökme günlüğü burada saklanır:

Documents\QuisquisLingo\Logs\quisquislingo_crash.log

Başlangıç denetimi günlüğü burada saklanır:

%LOCALAPPDATA%\QuisquisLingo\Logs\quisquislingo_launcher.log

Settings > Debug tanı seçeneklerini gösterir. Günlükler yerel bilgisayarda
kalır ve otomatik olarak yüklenmez.

SORUN GİDERME
-------------

1. ZIP arşivinin tamamını bütünüyle çıkarın.
2. Çıkarılmış paketteki QuisquisLingo.exe dosyasını çalıştırın.
3. Bir çalışma zamanı DLL dosyasının eksik olduğu bildirilirse resmi Microsoft
   yükleyicisini düşünmeden önce tam paketi yeniden indirip çıkarın.
4. Media Feature Pack gerekiyorsa yukarıdaki yönlendirmeyi izleyin ve kurulumdan
   sonra Windows'u yeniden başlatın.
5. QQL yine başlamazsa destek için hata iletisinin tamamını ve kullanılabilir
   günlük dosyalarını saklayın.
