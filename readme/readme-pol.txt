QuisquisLingo — przewodnik dla Windows
=====================================

QuisquisLingo to aplikacja do nauki języków przeznaczona dla osób uczących się
i twórców kursów. Łączy uporządkowane lekcje, interaktywne ćwiczenia, zadania
dźwiękowe i narzędzia do powtórek, a także udostępnia funkcje tworzenia i
edytowania kursów językowych.

Jest przeznaczona zarówno dla osób, które chcą uczyć się języka, jak i dla
autorów, nauczycieli oraz innych użytkowników tworzących własne kursy.

Krótki przegląd działania QuisquisLingo znajduje się w pliku
QQL infographic.png dołączonym do pakietu aplikacji.

Aby uruchomić QuisquisLingo, wykonaj plik QuisquisLingo.exe.

KORZYSTANIE Z PAKIETU
---------------------

Ten pakiet zawiera aplikację QQL. Przed uruchomieniem rozpakuj całe archiwum ZIP
i przechowuj razem wszystkie dostarczone pliki oraz folder data. Nie
rozpowszechniaj, nie przenoś, nie usuwaj ani nie zmieniaj nazw pojedynczych
plików EXE lub DLL.

KONTROLE PODCZAS URUCHAMIANIA
----------------------------

Przed uruchomieniem QuisquisLingo sprawdza wymagane pliki pakietu, zgodność z
Windows oraz Media Foundation. Kontrole te nie pobierają ani nie instalują
oprogramowania, nie żądają podwyższonych uprawnień, nie zmieniają rejestru ani
ustawień Windows.

Problem możliwy do pominięcia powoduje wyświetlenie jednego komunikatu z
przyciskami Continue anyway i Cancel. Continue anyway podejmuje próbę
uruchomienia QQL, a Cancel zamyka program. Jeśli brakuje niezbędnego pliku,
komunikat udostępnia Close, ponieważ pakiet trzeba ponownie pobrać i rozpakować.

Obsługa Wine jest eksperymentalna. Brak Media Foundation w Wine może uniemożliwić
uruchomienie albo działanie funkcji dźwiękowych i multimedialnych.

ŚRODOWISKO MICROSOFT VISUAL C++
-------------------------------

Pełny pakiet zawiera następujące pliki środowiska Microsoft Visual C++ x64:

msvcp140.dll
vcruntime140.dll
vcruntime140_1.dll

Jeśli któregoś brakuje, ponownie pobierz pełny pakiet QuisquisLingo dla Windows
i rozpakuj go w całości. Instalatory środowiska pobieraj wyłącznie z oficjalnych
źródeł Microsoft i nigdy nie pobieraj pojedynczych plików DLL z witryn innych
firm.

Oficjalne informacje Microsoft:
https://learn.microsoft.com/en-us/cpp/windows/latest-supported-vc-redist

MEDIA FOUNDATION
----------------

Edycje Windows N mogą wymagać Microsoft Media Feature Pack do obsługi dźwięku i
multimediów. Media Feature Pack jest zwykle dostępny w opcjonalnych funkcjach
Windows. W niektórych odmianach Windows N może go tam nie być. W takim przypadku
pobierz z witryny Microsoft pakiet Media Feature Pack odpowiedni dla używanej
wersji Windows.

Po zainstalowaniu Media Feature Pack uruchom ponownie Windows. QuisquisLingo nie
pobiera ani nie instaluje go automatycznie i nie zmienia ustawień systemowych.

SYNTEZA MOWY
------------

QuisquisLingo korzysta z głosów zainstalowanych w Windows. Dostępne języki i
głosy zależą od składników językowych i głosowych zainstalowanych na komputerze.
Jeśli nie ma zgodnego głosu, zainstaluj odpowiedni składnik w ustawieniach
Windows.

Audio Settings > Test Voice odczytuje tylko wpisany tekst i korzysta z języka
głosu skonfigurowanego w wybranym kursie.

DZIENNIKI I DIAGNOSTYKA
-----------------------

Główny dziennik awarii jest przechowywany w:

Documents\QuisquisLingo\Logs\quisquislingo_crash.log

Dziennik kontroli uruchamiania jest przechowywany w:

%LOCALAPPDATA%\QuisquisLingo\Logs\quisquislingo_launcher.log

Settings > Debug wyświetla opcje diagnostyczne. Dzienniki pozostają na
komputerze lokalnym i nie są automatycznie wysyłane.

ROZWIĄZYWANIE PROBLEMÓW
-----------------------

1. Rozpakuj całe archiwum ZIP.
2. Uruchom QuisquisLingo.exe z rozpakowanego pakietu.
3. Jeśli zgłoszono brak biblioteki DLL środowiska, ponownie pobierz i rozpakuj
   pełny pakiet przed rozważeniem oficjalnego instalatora Microsoft.
4. Jeśli wymagany jest Media Feature Pack, postępuj zgodnie z powyższymi
   wskazówkami i po instalacji uruchom ponownie Windows.
5. Jeśli QQL nadal się nie uruchamia, zachowaj pełny komunikat o błędzie i
   dostępne pliki dzienników na potrzeby pomocy technicznej.
