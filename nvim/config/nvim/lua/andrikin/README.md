Listagem de links e informações, juntadas ao longo do tempo, de ferramentas e
softwares para uso com o Neovim.

## BOOTSTRAP: 

Baixar win-portable-neovim, baixar neovim.zip, baixar neovim-qt.zip ou um GUI de
preferência, extrair tudo no mesmo diretório, respeitando a estrutura de pastas
do neovim.

## Lista de dependências:

- [curl](https://curl.se/windows/latest.cgi?p=win64-mingw.zip)
- [unzip](http://linorg.usp.br/CTAN/systems/win32/w32tex/unzip.exe)
- [w64devkit-compiler](https://github.com/skeeto/w64devkit/releases/download/v1.21.0/w64devkit-1.21.0.zip) -- removido em favor do **CYGWIN**.
- [cygwin](https://cygwin.com/setup-x86_64.exe) -- **UTILIZADO**.
- [git](https://github.com/git-for-windows/git/releases/download/v2.43.0.windows.1/Git-2.43.0-64-bit.tar.bz2) -- full version.
- [git](https://github.com/git-for-windows/git/releases/download/v2.43.0.windows.1/MinGit-2.43.0-64-bit.zip) -- minimal version.
- [fd](https://github.com/sharkdp/fd/releases/download/v8.7.1/fd-v8.7.1-x86_64-pc-windows-gnu.zip)
- [ripgrep](https://github.com/BurntSushi/ripgrep/releases/download/14.0.3/ripgrep-14.0.3-i686-pc-windows-msvc.zip)
- [sumatra](https://www.sumatrapdfreader.org/dl/rel/3.5.2/SumatraPDF-3.5.2-64.zip)
- [node](https://nodejs.org/dist/v20.10.0/node-v20.10.0-win-x64.zip)
- [Tectonic](https://github.com/tectonic-typesetting/tectonic/releases/download/tectonic%400.14.1/tectonic-0.14.1-x86_64-pc-windows-msvc.zip) -- **UTILIZADO**.
- [TinyTex](https://github.com/rstudio/tinytex-releases/releases/download/v2023.12/TinyTeX-1-v2023.12.zip)
- [maven](https://dlcdn.apache.org/maven/maven-3/3.9.6/binaries/apache-maven-3.9.6-bin.zip)
- [sqlite](https://www.sqlite.org/2024/sqlite-tools-win-x64-3460000.zip)
- [himalaya](https://github.com/pimalaya/himalaya/releases/download/v1.0.0-beta.4/himalaya.x86_64-windows.zip) -- ferramenta CLI para encaminhar e-mail com Neovim.
- [fzf](https://github.com/junegunn/fzf/releases/download/v0.56.3/fzf-0.56.3-windows_amd64.zip)
- [pandoc](https://github.com/jgm/pandoc/releases/download/3.5/pandoc-3.5-windows-x86_64.zip)
- [cmail](https://www.inveigle.net/downloads/CMail_0.8.11_x86.zip) -- CLI tool
para encaminhar e-mails.
- [java](https://download.java.net/java/GA/jdk21.0.1/415e3f918a1f4062a0074a2794853d0d/12/GPL/openjdk-21.0.1_windows-x64_bin.zip) -- Openjdk **UTILIZADO**.
- [java](https://download.oracle.com/java/21/latest/jdk-21_windows-x64_bin.zip) -- Oracle.
- [gradle](https://services.gradle.org/distributions/gradle-8.10.2-bin.zip)
- [jdtls](https://www.eclipse.org/downloads/download.php?file=/jdtls/snapshots/jdt-language-server-latest.tar.gz)
- [Como fazer PYTHON portável](https://chrisapproved.com/blog/portable-python-for-windows.html)
- [python 3.8.9](https://www.python.org/ftp/python/3.8.9/python-3.8.9-embed-amd64.zip) (Windows 7).
- [python 3.12.1](https://www.python.org/ftp/python/3.12.1/python-3.12.1-embed-amd64.zip) (Windows 10+).
- [Instalador PIP](https://bootstrap.pypa.io/get-pip.py)
- rust -- **TODO**.

## LSP's:

- [javascript](https://github.com/denoland/deno/releases/download/v1.27.0/deno-x86_64-pc-windows-msvc.zip) -- deno 1.27.0 - **Windows 7**.
- [lua](https://github.com/LuaLS/lua-language-server/releases/download/3.7.3/lua-language-server-3.7.3-win32-x64.zip)
- emmet:
    ```console
    npm install -g emmet-ls
    ```
- python:
    ```console
    pip install pyright | npm -g install pyright
    ```
- rust: **TODO**.

## WINDOWS: 

- [Explorador de arquivos (Explorer++)](https://explorerplusplus.com/download) -- **RECOMENDADO**.
- [Explorador de arquivos (Dolphin)](https://cdn.kde.org/ci-builds/system/dolphin/master/windows/dolphin-master-6789-windows-cl-msvc2022-x86_64.exe)
    - **BUGS do Dolphin**:
        1. <https://forum.kde.org/viewtopic.php%3Ff=59&t=173363.html>
        2. <https://bugs.kde.org/show_bug.cgi?id=498581#c0>
- [Gerenciador de arquivos compactados (Ark)](https://cdn.kde.org/ci-builds/utilities/ark/master/windows/ark-master-2365-windows-cl-msvc2022-x86_64.exe)
- [Programa para extrair arquivos de ".msi"](https://github.com/activescott/lessmsi/releases/download/v2.7.3/lessmsi-v2.7.3.zip)
- [Programa para alternar rapidamente entre desktops (Windows 10)](https://sourceforge.net/projects/virtuawin/files/VirtuaWin/4.5/VirtuaWin_portable_4.5.zip/download)
- [Programa para alternar rapidamente entre desktops (Windows 11)](https://github.com/nadimkobeissi/binkybox/releases/download/v0.2.1/binkybox-0.2.1.rar)
- [AltSnap](https://github.com/RamonUnch/AltSnap/releases/download/1.65/AltSnap1.65bin_x64.zip)
- [Shutdown Timer Classic](https://github.com/lukaslangrock/ShutdownTimerClassic/releases/download/v1.3.1/ShutdownTimerClassic_v1.3.1.zip)
- Ativar janela ao mover mouse:
    1. <https://www.elevenforum.com/t/turn-on-or-off-activate-window-by-hovering-over-with-mouse-pointer-in-windows-11.6104/>
    2. <https://www.elevenforum.com/t/change-time-to-activate-window-by-hovering-over-with-mouse-pointer-in-windows-11.6105/>
- Esconder mouse enquanto digita:
    1. <https://softwareok.com/?seite=Microsoft/AutoHideMouseCursor>
    2. <https://github.com/Stefan-Z-Camilleri-zz/Windows-Cursor-Hider>
- [nomacs](https://nomacs.org/docs/getting-started/installation/) - Visualizador de imagens.
- Download VS Build Tools: 
    1. <https://gist.github.com/mmozeiko/7f3162ec2988e81e56d5c4e22cde9977>
    2. <https://gist.githubusercontent.com/mmozeiko/7f3162ec2988e81e56d5c4e22cde9977/raw/50d5f534519bce8c118df3e2a2bc9a6f16e29a58/portable-msvc.py>
    3. <https://gist.githubusercontent.com/CrendKing/154abfa33200ef1cda38ddd61f4d414b/raw/591930da175eddf9690d84af1da5e01d64207f4b/portable-msvc.py>
    - **OBS**: incluir os diretórios dos executáveis nas variáveis de ambiente
    do usuário - **PATH, LIB, INCLUDE** - alterando comando no script para:
        ```console
        setx VARIAVEL "VALOR"
        ```
- [qView](https://interversehq.com/qview/) - simples visualizador de imagens.
- [WindowTabs](https://github.com/leafOfTree/WindowTabs) - agrupador de janelas.

## Macros LibreOffice:

- [Guia Python para Macros](https://wiki.documentfoundation.org/Macros/Python_Design_Guide)
- [API LibreOffice](https://api.libreoffice.org/)
- [Macros LibreOffice](https://help.libreoffice.org/latest/en-US/text/sbasic/python/main0000.html?DbPAR=BASIC)

## Sites para programas Freeware:

- [portablefreeware](https://www.portablefreeware.com/)
- [portableapps](https://portableapps.com/)
- [softwareok](https://www.softwareok.com/)
- [Muldersoft](https://muldersoft.com/#)

