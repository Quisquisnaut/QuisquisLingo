QuisquisLingo - Windows 안내서
==============================

QuisquisLingo는 언어 학습자와 코스 제작자를 위한 언어 학습 애플리케이션입니다.
체계적인 레슨, 대화형 연습, 오디오 활동 및 복습 도구를 제공하며, 언어 코스를
만들고 편집하는 도구도 함께 제공합니다.

언어를 배우려는 사람뿐 아니라 자신만의 코스를 만들려는 저자, 교사 및 기타
사용자를 위해 설계되었습니다.

QuisquisLingo의 작동 방식을 빠르게 살펴보려면 애플리케이션 패키지에 포함된
QQL infographic.png를 확인하십시오.

QuisquisLingo를 시작하려면 QuisquisLingo.exe를 실행하십시오.

패키지 사용
-----------

이 패키지에는 QQL 애플리케이션이 포함되어 있습니다. 시작하기 전에 ZIP 압축
파일 전체를 풀고 제공된 모든 파일과 data 폴더를 한곳에 유지하십시오. 개별 EXE
또는 DLL 파일을 배포, 이동, 삭제하거나 이름을 바꾸지 마십시오.

시작 검사
---------

QuisquisLingo는 시작 전에 필요한 패키지 파일, Windows 호환성 및 Media
Foundation을 검사합니다. 이 검사는 소프트웨어를 다운로드하거나 설치하지 않고,
관리자 권한을 요청하거나 레지스트리 또는 Windows를 변경하지 않습니다.

계속 진행할 수 있는 문제가 있으면 Continue anyway와 Cancel이 포함된 메시지
하나가 표시됩니다. Continue anyway는 QQL 시작을 시도하며 Cancel은 종료합니다.
필수 프로그램 파일이 없으면 패키지를 다시 다운로드하여 완전히 풀어야 하므로
메시지에 Close가 표시됩니다.

Wine 지원은 Experimental입니다. Wine에 Media Foundation이 없으면 시작하지
못하거나 오디오 및 미디어 기능이 작동하지 않을 수 있습니다.

MICROSOFT VISUAL C++ RUNTIME
----------------------------

전체 패키지에는 다음 Microsoft Visual C++ x64 runtime 파일이 포함됩니다.

msvcp140.dll
vcruntime140.dll
vcruntime140_1.dll

하나라도 없으면 전체 QuisquisLingo Windows 패키지를 다시 다운로드하여 완전히
푸십시오. Runtime installer는 Microsoft 공식 출처에서만 받고, 개별 DLL 파일을
타사 웹사이트에서 다운로드하지 마십시오.

Microsoft 공식 정보:
https://learn.microsoft.com/en-us/cpp/windows/latest-supported-vc-redist

MEDIA FOUNDATION
----------------

Windows N 에디션에서는 오디오 및 미디어 기능에 Microsoft Media Feature Pack이
필요할 수 있습니다. Media Feature Pack은 일반적으로 Windows Optional Features에서
사용할 수 있습니다. 일부 Windows N 버전에서는 Optional Features에 Media Feature
Pack이 없을 수 있습니다. 이 경우 사용 중인 Windows 버전에 맞는 Media Feature
Pack을 Microsoft 웹사이트에서 다운로드하십시오.

Media Feature Pack을 설치한 후 Windows를 다시 시작하십시오. QuisquisLingo는
이를 자동으로 다운로드하거나 설치하지 않으며 시스템 설정을 변경하지 않습니다.

TEXT-TO-SPEECH
--------------

QuisquisLingo는 Windows에 설치된 음성 목소리를 사용합니다. 사용 가능한 언어와
목소리는 컴퓨터에 설치된 Windows 언어 및 음성 구성 요소에 따라 달라집니다.
호환되는 목소리가 없다면 Windows 설정에서 적절한 구성 요소를 설치하십시오.

Audio Settings > Test Voice는 입력한 텍스트만 말하며, 선택한 코스에 설정된
음성 언어를 사용합니다.

로그 및 진단
------------

기본 crash log는 다음 위치에 저장됩니다.

Documents\QuisquisLingo\Logs\quisquislingo_crash.log

시작 검사 log는 다음 위치에 저장됩니다.

%LOCALAPPDATA%\QuisquisLingo\Logs\quisquislingo_launcher.log

Settings > Debug에서 진단 옵션을 확인할 수 있습니다. Log는 로컬 컴퓨터에
남아 있으며 자동으로 업로드되지 않습니다.

문제 해결
---------

1. 전체 ZIP 압축 파일을 완전히 풉니다.
2. 압축을 푼 패키지에서 QuisquisLingo.exe를 실행합니다.
3. Runtime DLL이 없다는 메시지가 나타나면 Microsoft 공식 runtime installer를
   고려하기 전에 전체 패키지를 다시 다운로드하여 풉니다.
4. Media Feature Pack이 필요하다면 위 안내를 따르고 설치 후 Windows를 다시
   시작합니다.
5. 그래도 QQL이 시작되지 않으면 지원을 위해 전체 오류 메시지와 사용 가능한
   log 파일을 보관합니다.
