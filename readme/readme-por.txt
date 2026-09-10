QuisquisLingo - Guia para Windows
================================

QuisquisLingo é uma aplicação para aprender idiomas, destinada a estudantes e
criadores de cursos. Combina lições estruturadas, exercícios interativos,
atividades de áudio e ferramentas de revisão, além de oferecer recursos para
criar e editar cursos de idiomas.

Foi concebida tanto para quem deseja estudar um idioma como para autores,
professores ou outros utilizadores que queiram criar os seus próprios cursos.

Para uma visão geral rápida e visual de como QuisquisLingo funciona, consulte
QQL infographic.png, incluída no pacote da aplicação.

Para iniciar QuisquisLingo, execute QuisquisLingo.exe.

UTILIZAÇÃO DO PACOTE
--------------------

Este pacote contém a aplicação QQL. Extraia todo o arquivo ZIP antes de a
iniciar e mantenha juntos todos os ficheiros fornecidos e a pasta data. Não
distribua, mova, elimine ou mude o nome de ficheiros EXE ou DLL isoladamente.

VERIFICAÇÕES DE ARRANQUE
------------------------

Antes de iniciar, QuisquisLingo verifica os ficheiros necessários do pacote, a
compatibilidade com Windows e Media Foundation. Estas verificações não
descarregam nem instalam programas, não pedem privilégios elevados, não alteram
o registo e não modificam Windows.

Um problema recuperável apresenta uma única mensagem com Continue anyway e
Cancel. Continue anyway tenta iniciar QQL; Cancel fecha-o. Se faltar um ficheiro
essencial, a mensagem apresenta Close, pois o pacote deve ser novamente
descarregado e extraído.

O suporte de Wine é experimental. A ausência de Media Foundation em Wine pode
impedir o arranque ou o funcionamento dos recursos de áudio e multimédia.

RUNTIME MICROSOFT VISUAL C++
----------------------------

O pacote completo inclui estes ficheiros de runtime Microsoft Visual C++ x64:

msvcp140.dll
vcruntime140.dll
vcruntime140_1.dll

Se faltar algum, descarregue novamente o pacote completo de QuisquisLingo para
Windows e extraia-o por inteiro. Utilize apenas fontes oficiais da Microsoft
para instaladores de runtime e nunca descarregue DLL individuais de sites de
terceiros.

Informações oficiais da Microsoft:
https://learn.microsoft.com/en-us/cpp/windows/latest-supported-vc-redist

MEDIA FOUNDATION
----------------

As edições Windows N podem necessitar de Microsoft Media Feature Pack para
recursos de áudio e multimédia. Normalmente, Media Feature Pack está disponível
nas Funcionalidades Opcionais do Windows. Em algumas versões de Windows N, pode
não estar disponível nessa área. Nesse caso, descarregue do site da Microsoft o
Media Feature Pack adequado à sua versão de Windows.

Reinicie Windows depois de instalar Media Feature Pack. QuisquisLingo não o
descarrega nem instala automaticamente e não altera as definições do sistema.

CONVERSÃO DE TEXTO EM VOZ
-------------------------

QuisquisLingo utiliza as vozes instaladas em Windows. Os idiomas e as vozes
disponíveis dependem dos componentes de idioma e voz instalados no computador.
Se não houver uma voz compatível, instale o componente adequado nas definições
do Windows.

Audio Settings > Test Voice reproduz apenas o texto introduzido e utiliza o
idioma de voz configurado pelo curso selecionado.

REGISTOS E DIAGNÓSTICO
----------------------

O registo principal de falhas encontra-se em:

Documents\QuisquisLingo\Logs\quisquislingo_crash.log

O registo da verificação de arranque encontra-se em:

%LOCALAPPDATA%\QuisquisLingo\Logs\quisquislingo_launcher.log

Settings > Debug mostra opções de diagnóstico. Os registos permanecem no
computador local e não são enviados automaticamente.

RESOLUÇÃO DE PROBLEMAS
----------------------

1. Extraia completamente todo o arquivo ZIP.
2. Execute QuisquisLingo.exe a partir do pacote extraído.
3. Se for indicada uma DLL de runtime em falta, descarregue e extraia novamente
   o pacote completo antes de considerar um instalador oficial da Microsoft.
4. Se Media Feature Pack for necessário, siga as instruções acima e reinicie
   Windows depois da instalação.
5. Se QQL continuar sem iniciar, guarde a mensagem de erro completa e os
   ficheiros de registo disponíveis para o suporte.
