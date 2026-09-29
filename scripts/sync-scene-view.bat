@echo off
setlocal EnableExtensions EnableDelayedExpansion

rem ============================================================================
rem  Scene View kit - sync
rem
rem  Drop this one file into the root of a Cocos Creator project and run it.
rem  It fetches the kit, installs the runtime Scene view into assets\scene-view,
rem  switches on the one engine module it needs, and updates itself.
rem
rem  Nothing else to set up afterwards: AutoBoot.ts attaches the tool to every
rem  scene, so the next Play already has it. F1 toggles.
rem ============================================================================

rem AI AGENT NOTE: bump this whenever this file changes.
set "SYNC_VERSION=1.1.0"

rem Fill this in once the kit has a remote. After that, one file is all any
rem project ever needs and every project updates from the same place.
set "KIT_URL=https://github.com/nampham2000/scene-view-kit.git"

set "KIT_NAME=scene-view-kit"

set "ROOT_DIR=%~dp0"
if "%ROOT_DIR:~-1%"=="\" set "ROOT_DIR=%ROOT_DIR:~0,-1%"

set "KIT_DIR=%ROOT_DIR%\%KIT_NAME%"
set "TARGET_DIR=%ROOT_DIR%\assets\scene-view"
set "ENGINE_JSON=%ROOT_DIR%\settings\v2\packages\engine.json"
set "MEMO_FILE=%LOCALAPPDATA%\scene-view-kit-source.txt"
set "SOURCE_DIR="
set "REMEMBERED="
set "ANSWER="

echo.
echo ================================================================
echo   SCENE VIEW KIT - SYNC v%SYNC_VERSION%
echo ================================================================
echo   project: %ROOT_DIR%
echo.

if not exist "%ROOT_DIR%\package.json" goto :notAProject
if not exist "%ROOT_DIR%\assets\" goto :notAProject

rem ------------------------------------------------------------------ kit ---
rem Preference order: a configured remote, a kit already sitting in the
rem project, whatever worked last time on this machine, then ask.
if defined KIT_URL goto :useRemote
if exist "%KIT_DIR%\assets\scene-view\SceneViewDebug.ts" goto :useLocalKit

if exist "%MEMO_FILE%" set /p "REMEMBERED="<"%MEMO_FILE%"
if defined REMEMBERED (
    echo !REMEMBERED! | findstr /I /R "^https*:// ^git@ \.git$" >nul
    if not errorlevel 1 (
        set "KIT_URL=!REMEMBERED!"
        echo [kit] remote remembered from a previous run
        goto :useRemote
    )
    if exist "!REMEMBERED!\assets\scene-view\SceneViewDebug.ts" (
        set "SOURCE_DIR=!REMEMBERED!\assets\scene-view"
        echo [kit] local kit remembered from a previous run
        goto :haveSource
    )
    if exist "!REMEMBERED!\SceneViewDebug.ts" (
        set "SOURCE_DIR=!REMEMBERED!"
        echo [kit] local source remembered from a previous run
        goto :haveSource
    )
)

echo Where is the Scene View kit?
echo Enter a git URL, or the folder holding the kit ^(or its assets\scene-view^).
echo ^(tip: drag the folder into this window^)
echo.
set /p "ANSWER=kit: "
echo.
if not defined ANSWER goto :noSource
set "ANSWER=!ANSWER:"=!"
if "!ANSWER:~-1!"=="\" set "ANSWER=!ANSWER:~0,-1!"

echo !ANSWER! | findstr /I /R "^https*:// ^git@ \.git$" >nul
if not errorlevel 1 (
    set "KIT_URL=!ANSWER!"
    >"%MEMO_FILE%" echo !ANSWER!
    goto :useRemote
)
if exist "!ANSWER!\assets\scene-view\SceneViewDebug.ts" (
    set "SOURCE_DIR=!ANSWER!\assets\scene-view"
    >"%MEMO_FILE%" echo !ANSWER!
    goto :haveSource
)
if exist "!ANSWER!\SceneViewDebug.ts" (
    set "SOURCE_DIR=!ANSWER!"
    >"%MEMO_FILE%" echo !ANSWER!
    goto :haveSource
)
echo [ERROR] "!ANSWER!" holds no SceneViewDebug.ts
goto :fail

:useRemote
where git >nul 2>&1
if errorlevel 1 (
    echo [ERROR] git is not on PATH, cannot fetch the kit.
    goto :fail
)
git -C "%ROOT_DIR%" rev-parse --is-inside-work-tree >nul 2>&1
if errorlevel 1 (
    rem Not a git project, so a submodule is impossible: keep a plain clone.
    if exist "%KIT_DIR%\.git" (
        echo [kit] updating clone
        git -C "%KIT_DIR%" pull --ff-only >nul 2>&1
    ) else (
        echo [kit] cloning !KIT_URL!
        git clone --depth 1 "!KIT_URL!" "%KIT_DIR%" >nul 2>&1
        if errorlevel 1 (
            echo [ERROR] git clone failed: !KIT_URL!
            goto :fail
        )
    )
) else (
    git -C "%ROOT_DIR%" submodule status -- "%KIT_NAME%" >nul 2>&1
    if errorlevel 1 (
        echo [kit] registering submodule %KIT_NAME%
        git -C "%ROOT_DIR%" submodule add --force "!KIT_URL!" "%KIT_NAME%"
        if errorlevel 1 goto :fail
    ) else (
        echo [kit] updating submodule %KIT_NAME%
    )
    git -C "%ROOT_DIR%" submodule update --init --recursive -- "%KIT_NAME%"
    if errorlevel 1 goto :fail
)
>"%MEMO_FILE%" echo !KIT_URL!

:useLocalKit
if not defined SOURCE_DIR set "SOURCE_DIR=%KIT_DIR%\assets\scene-view"

:haveSource
if not exist "!SOURCE_DIR!\SceneViewDebug.ts" (
    echo [ERROR] "!SOURCE_DIR!" holds no SceneViewDebug.ts
    goto :fail
)
echo [source] !SOURCE_DIR!

rem ----------------------------------------------------------------- copy ---
rem .meta is deliberately excluded: these are plain scripts with no asset
rem references, so each project generating its own UUIDs is safer than carrying
rem one set everywhere.
if not exist "%TARGET_DIR%\" mkdir "%TARGET_DIR%"
robocopy "!SOURCE_DIR!" "%TARGET_DIR%" *.ts *.md /XF *.meta /NFL /NDL /NJH /NJS /NC /NS /NP >nul
if errorlevel 8 (
    echo [ERROR] copy failed.
    goto :fail
)
echo [ok] scripts installed in assets\scene-view

rem -------------------------------------------------------------- settings ---
rem No "!" in the snippet below: delayed expansion eats it and silently deletes
rem whole conditions, which is also why it says "===undefined" throughout.
if exist "%ENGINE_JSON%" (
    call node -e "const fs=require('fs');const f=process.argv[1];let raw=fs.readFileSync(f,'utf8');if(raw.charCodeAt(0)===65279)raw=raw.slice(1);const j=JSON.parse(raw);const mods=j.modules===undefined?undefined:j.modules;const cfg=mods===undefined?undefined:mods.configs;const def=cfg===undefined?undefined:cfg.defaultConfig;const cache=def===undefined?undefined:def.cache;if(cache===undefined){console.log('[ok] engine modules untouched - project uses defaults, geometry renderer is on');process.exit(0)}const e=cache['geometry-renderer'];if(e===undefined){console.log('[ok] geometry-renderer not cropped');process.exit(0)}if(e._value===true){console.log('[ok] geometry-renderer already on');process.exit(0)}e._value=true;fs.writeFileSync(f,JSON.stringify(j,null,2)+String.fromCharCode(10));console.log('[ok] geometry-renderer switched ON - gizmos need it, revert under Feature Cropping');" "%ENGINE_JSON%"
    if errorlevel 1 echo [warn] could not read or update engine.json - check Feature Cropping by hand.
) else (
    echo [ok] no engine.json yet - project uses defaults, geometry renderer is on
)

rem ----------------------------------------------------------- self-update ---
rem The kit owns the newest copy of this script, so refresh it in place. Skipped
rem when this file is being run from inside the kit itself.
set "SELF_SOURCE=%KIT_DIR%\scripts\sync-scene-view.bat"
if exist "%SELF_SOURCE%" if /I not "%~f0"=="%SELF_SOURCE%" (
    copy /Y "%SELF_SOURCE%" "%ROOT_DIR%\sync-scene-view.bat" >nul
    if not errorlevel 1 echo [ok] sync script refreshed from the kit
)

echo.
echo ================================================================
echo   DONE - open the project and press Play. F1 toggles the view.
echo   Nothing to attach: AutoBoot.ts wires itself into every scene.
echo ================================================================
echo.
if /I not "%SCENE_VIEW_NO_PAUSE%"=="1" pause
exit /b 0

:noSource
echo [ERROR] No kit given, nothing installed.
echo         Run it again and enter a git URL or a folder, or set KIT_URL
echo         at the top of this file.
goto :fail

:notAProject
echo [ERROR] This does not look like a Cocos Creator project root.
echo         Expected package.json and an assets\ folder next to this file.
goto :fail

:fail
echo.
if /I not "%SCENE_VIEW_NO_PAUSE%"=="1" pause
exit /b 1
