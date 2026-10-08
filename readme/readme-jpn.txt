QuisquisLingo - Windows ガイド
==============================

QuisquisLingo は、語学学習者とコース作成者のための語学学習アプリケーション
です。体系的なレッスン、インタラクティブな練習、音声アクティビティ、復習
ツールに加え、語学コースを作成および編集するためのツールも備えています。

言語を学びたい方だけでなく、自分のコースを作りたい著者、教師、その他の
ユーザーにも適しています。

QuisquisLingo の仕組みをすばやく視覚的に確認するには、アプリケーション
パッケージに含まれる QQL infographic.png をご覧ください。

QuisquisLingo を起動するには、QuisquisLingo.exe を実行してください。

パッケージの使用方法
----------------------

このパッケージには QQL アプリケーションが含まれています。起動する前に ZIP
アーカイブ全体を展開し、付属するすべてのファイルと data フォルダーを一緒に
保管してください。個々の EXE または DLL ファイルを配布、移動、削除、名前
変更しないでください。

起動時の確認
------------

QuisquisLingo は起動前に、必要なパッケージファイル、Windows の互換性、
Media Foundation を確認します。この確認によってソフトウェアがダウンロード
またはインストールされたり、管理者権限が要求されたり、レジストリや Windows
が変更されたりすることはありません。

続行可能な問題の場合は、Continue anyway と Cancel を含むメッセージが 1 件
表示されます。Continue anyway は QQL の起動を試み、Cancel は終了します。
必須のプログラムファイルがない場合は、パッケージの再ダウンロードと完全な
展開が必要なため、メッセージに Close が表示されます。

Wine のサポートは Experimental です。Wine で Media Foundation が不足して
いると、起動できない場合や、音声およびメディア機能が動作しない場合があります。

MICROSOFT VISUAL C++ RUNTIME
----------------------------

完全なパッケージには、次の Microsoft Visual C++ x64 runtime ファイルが
含まれています。

msvcp140.dll
vcruntime140.dll
vcruntime140_1.dll

いずれかがない場合は、QuisquisLingo Windows パッケージ全体を再度ダウンロード
し、完全に展開してください。Runtime installer は Microsoft の公式配布元
のみを使用し、個別の DLL ファイルを第三者の Web サイトからダウンロード
しないでください。

Microsoft の公式情報：
https://learn.microsoft.com/en-us/cpp/windows/latest-supported-vc-redist

MEDIA FOUNDATION
----------------

Windows N エディションでは、音声およびメディア機能のために Microsoft Media
Feature Pack が必要になることがあります。Media Feature Pack は通常 Windows
Optional Features から入手できます。一部の Windows N バージョンでは、Media
Feature Pack が Optional Features にない場合があります。その場合は、お使いの
Windows バージョンに適した Media Feature Pack を Microsoft の Web サイトから
ダウンロードしてください。

Media Feature Pack のインストール後に Windows を再起動してください。
QuisquisLingo がこれを自動的にダウンロードまたはインストールしたり、システム
設定を変更したりすることはありません。

TEXT-TO-SPEECH
--------------

QuisquisLingo は Windows にインストールされている音声を使用します。利用できる
言語と音声は、コンピューターにインストールされている Windows の言語および
音声コンポーネントによって異なります。互換性のある音声がない場合は、Windows
の設定から適切なコンポーネントをインストールしてください。

Audio Settings > Test Voice は入力したテキストだけを読み上げ、選択した
コースで設定されている音声言語を使用します。

ログと診断
----------

メインの crash log は次の場所に保存されます。

Documents\QuisquisLingo\Logs\quisquislingo_crash.log

起動確認の log は次の場所に保存されます。

%LOCALAPPDATA%\QuisquisLingo\Logs\quisquislingo_launcher.log

Settings > Debug には診断オプションがあります。Log はローカルコンピューター
内に保持され、自動的にアップロードされることはありません。

トラブルシューティング
------------------------

1. ZIP アーカイブ全体を完全に展開します。
2. 展開したパッケージから QuisquisLingo.exe を実行します。
3. Runtime DLL がないと報告された場合は、Microsoft 公式の runtime installer
   を検討する前に、完全なパッケージを再度ダウンロードして展開します。
4. Media Feature Pack が必要な場合は上記の案内に従い、インストール後に
   Windows を再起動します。
5. それでも QQL が起動しない場合は、サポートに備えてエラーメッセージ全体と
   利用可能な log ファイルを保管してください。
