QuisquisLingo - Panduan Windows
===============================

QuisquisLingo adalah aplikasi pembelajaran bahasa untuk pelajar dan pembuat
kursus. Aplikasi ini memadukan pelajaran terstruktur, latihan interaktif,
aktivitas audio, dan alat peninjauan, sekaligus menyediakan alat untuk membuat
dan menyunting kursus bahasa.

QuisquisLingo dirancang bagi orang yang ingin mempelajari bahasa serta penulis,
pengajar, atau pengguna lain yang ingin membuat kursus mereka sendiri.

Untuk melihat gambaran visual singkat tentang cara kerja QuisquisLingo, buka
QQL infographic.png yang disertakan dalam paket aplikasi.

Untuk memulai QuisquisLingo, jalankan QuisquisLingo.exe.

MENGGUNAKAN PAKET
-----------------

Paket ini berisi aplikasi QQL. Ekstrak seluruh arsip ZIP sebelum memulainya,
dan simpan semua file yang disertakan serta folder data di tempat yang sama.
Jangan mendistribusikan, memindahkan, menghapus, atau mengganti nama file EXE
atau DLL secara terpisah.

PEMERIKSAAN AWAL
----------------

Sebelum dimulai, QuisquisLingo memeriksa file paket yang diperlukan,
kompatibilitas Windows, dan Media Foundation. Pemeriksaan ini tidak pernah
mengunduh atau memasang perangkat lunak, meminta hak administrator, mengubah
registry, atau memodifikasi Windows.

Masalah yang masih memungkinkan aplikasi dijalankan akan menampilkan satu pesan
dengan Continue anyway dan Cancel. Continue anyway mencoba memulai QQL; Cancel
menutupnya. Jika file program yang penting tidak ada, pesan akan menawarkan
Close karena paket harus diunduh dan diekstrak kembali secara lengkap.

Dukungan Wine bersifat Experimental. Media Foundation yang tidak tersedia di
Wine dapat mencegah aplikasi dimulai atau membuat fitur audio dan media tidak
berfungsi.

MICROSOFT VISUAL C++ RUNTIME
----------------------------

Paket lengkap menyertakan file runtime Microsoft Visual C++ x64 berikut:

msvcp140.dll
vcruntime140.dll
vcruntime140_1.dll

Jika salah satunya tidak ada, unduh kembali paket Windows QuisquisLingo lengkap
dan ekstrak seluruh isinya. Gunakan hanya sumber resmi Microsoft untuk runtime
installer, dan jangan pernah mengunduh file DLL satu per satu dari situs pihak
ketiga.

Informasi resmi Microsoft:
https://learn.microsoft.com/en-us/cpp/windows/latest-supported-vc-redist

MEDIA FOUNDATION
----------------

Edisi Windows N mungkin memerlukan Microsoft Media Feature Pack agar fungsi
audio dan media dapat digunakan. Media Feature Pack biasanya tersedia di
Windows Optional Features. Pada beberapa versi Windows N, Media Feature Pack
mungkin tidak tersedia di Optional Features. Jika demikian, unduh Media Feature
Pack yang sesuai dengan versi Windows Anda dari situs web Microsoft.

Mulai ulang Windows setelah memasang Media Feature Pack. QuisquisLingo tidak
mengunduh atau memasangnya secara otomatis dan tidak mengubah pengaturan sistem.

TEXT-TO-SPEECH
--------------

QuisquisLingo menggunakan suara ucapan yang terpasang di Windows. Bahasa dan
suara yang tersedia bergantung pada komponen bahasa dan suara Windows yang
terpasang di komputer. Jika tidak ada suara yang kompatibel, pasang komponen
yang sesuai melalui pengaturan Windows.

Audio Settings > Test Voice hanya mengucapkan teks yang Anda masukkan dan
menggunakan bahasa suara yang dikonfigurasi oleh kursus yang dipilih.

LOG DAN DIAGNOSTIK
------------------

Crash log utama disimpan di:

Documents\QuisquisLingo\Logs\quisquislingo_crash.log

Log pemeriksaan awal disimpan di:

%LOCALAPPDATA%\QuisquisLingo\Logs\quisquislingo_launcher.log

Settings > Debug menampilkan opsi diagnostik. Log tetap berada di komputer
lokal dan tidak diunggah secara otomatis.

PEMECAHAN MASALAH
-----------------

1. Ekstrak seluruh arsip ZIP secara lengkap.
2. Jalankan QuisquisLingo.exe dari paket yang telah diekstrak.
3. Jika ada laporan runtime DLL yang hilang, unduh dan ekstrak kembali paket
   lengkap sebelum mempertimbangkan runtime installer resmi Microsoft.
4. Jika Media Feature Pack diperlukan, ikuti petunjuk di atas dan mulai ulang
   Windows setelah pemasangan.
5. Jika QQL masih tidak dapat dimulai, simpan pesan kesalahan lengkap dan file
   log yang tersedia untuk mendapatkan bantuan.
