QuisquisLingo - Windows 指南
===========================

QuisquisLingo 是一款面向语言学习者和课程创作者的语言学习应用。它将结构化
课程、互动练习、音频活动和复习工具融为一体，同时还提供创建和编辑语言课程
的工具。

它既适合希望学习语言的人，也适合希望自行构建课程的作者、教师及其他用户。

如需快速了解 QuisquisLingo 的工作方式，请查看应用程序包中附带的
QQL infographic.png。

要启动 QuisquisLingo，请运行 QuisquisLingo.exe。

使用程序包
----------

此程序包包含 QQL 应用程序。启动前请完整解压 ZIP 压缩包，并将提供的所有文件
和 data 文件夹放在一起。请勿单独分发、移动、删除或重命名任何 EXE 或 DLL
文件。

启动检查
--------

启动前，QuisquisLingo 会检查必需的程序包文件、Windows 兼容性和 Media
Foundation。这些检查绝不会下载或安装软件、请求管理员权限、修改注册表或
更改 Windows。

遇到可以继续运行的问题时，会显示一条包含 Continue anyway 和 Cancel 的
消息。Continue anyway 会尝试启动 QQL；Cancel 会将其关闭。如果缺少必需的
程序文件，消息会提供 Close，因为此时必须重新下载并完整解压程序包。

Wine 支持属于 Experimental。Wine 中缺少 Media Foundation 可能导致程序
无法启动，或者音频及媒体功能无法工作。

MICROSOFT VISUAL C++ RUNTIME
----------------------------

完整程序包中包含以下 Microsoft Visual C++ x64 runtime 文件：

msvcp140.dll
vcruntime140.dll
vcruntime140_1.dll

如果缺少其中任何文件，请重新下载完整的 QuisquisLingo Windows 程序包并完整
解压。Runtime 安装程序只能从 Microsoft 官方来源获取，切勿从第三方网站下载
单独的 DLL 文件。

Microsoft 官方信息：
https://learn.microsoft.com/en-us/cpp/windows/latest-supported-vc-redist

MEDIA FOUNDATION
----------------

Windows N 版本可能需要 Microsoft Media Feature Pack 才能使用音频和媒体
功能。Media Feature Pack 通常可在 Windows Optional Features 中找到。在
某些 Windows N 版本中，Optional Features 可能不提供 Media Feature Pack。
在这种情况下，请从 Microsoft 网站下载适合您的 Windows 版本的 Media
Feature Pack。

安装 Media Feature Pack 后请重新启动 Windows。QuisquisLingo 不会自动下载
或安装它，也不会更改系统设置。

TEXT-TO-SPEECH
--------------

QuisquisLingo 使用 Windows 中已安装的语音。可用语言和语音取决于电脑上安装
的 Windows 语言及语音组件。如果没有兼容的语音，请通过 Windows 设置安装
相应组件。

Audio Settings > Test Voice 只朗读您输入的文本，并使用所选课程配置的语音
语言。

日志和诊断
----------

主崩溃日志存储在：

Documents\QuisquisLingo\Logs\quisquislingo_crash.log

启动检查日志存储在：

%LOCALAPPDATA%\QuisquisLingo\Logs\quisquislingo_launcher.log

Settings > Debug 提供诊断选项。日志保留在本地电脑中，不会自动上传。

问题排查
--------

1. 完整解压整个 ZIP 压缩包。
2. 从解压后的程序包中运行 QuisquisLingo.exe。
3. 如果提示缺少 runtime DLL，请先重新下载并解压完整程序包，再考虑使用
   Microsoft 官方 runtime 安装程序。
4. 如果需要 Media Feature Pack，请按照上述说明操作，并在安装后重新启动
   Windows。
5. 如果 QQL 仍无法启动，请保留完整的错误消息和可用日志文件，以便寻求支持。
