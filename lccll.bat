@echo off
setlocal enabledelayedexpansion
set "ver=v1.0"
set "LUNAR_VERSION=1.8.9"
set "LUNAR_MODULE="
set "CONFIG_FILE=config.txt"
set "githubAPI=https://api.github.com/repos/unethicalteam/lccll/releases/latest"
set "githubURL=https://github.com/unethicalteam/lccll/releases/latest"
set "llwgithubAPI=https://api.github.com/repos/uchks/LunarLaunchWrapper/releases/latest"

title lccll - lunar client command line launcher %ver%

:: Check for lccll update
for /f "tokens=2 delims=:" %%I in ('curl -s "%githubAPI%" ^| find "tag_name"') do set "latestTag=%%~I"
set "latestTag=!latestTag:~1,-1!"
set "latestTag=!latestTag:"=!"
if /i "!latestTag!" neq "!ver!" (
    call :Header
    echo A new version of lccll: !latestTag! was found on GitHub!
    echo You can download it from: [36m!githubURL![0m
    echo Press any key to exit...
    pause >nul
    exit /b
)

if exist LunarLaunchWrapper-*.jar (
    :: Check for LunarLaunchWrapper update
    for /f "tokens=2 delims=:" %%I in ('curl -s "%llwgithubAPI%" ^| find "tag_name"') do set "latestllwTag=%%~I"
    set "latestllwTag=!latestllwTag:~1,-1!"
    set "latestllwTag=!latestllwTag:"=!"
    if /i "!latestllwTag!" neq "!ver!" (
        call :Header
        echo A new version of LunarLaunchWrapper: !latestllwTag! was found on GitHub!
        echo Press any key to download the update...
        pause >nul

        :: Delete existing LunarLaunchWrapper-***.jar files
        for %%F in (LunarLaunchWrapper-*.jar) do (
            del "%%F"
        )

        call :DownloadFile "https://github.com/uchks/LunarLaunchWrapper/releases/download/!latestllwTag!/LunarLaunchWrapper-!latestllwTag!.jar" "LunarLaunchWrapper-!latestllwTag!.jar"
        echo Download Completed.
        timeout /t 2 > nul
    )
)

:header
cls
echo lccll - lunar client command line launcher
echo Created by [31munethical[0m
echo [36mhttps://discord.gg/vhJ8Dsp9qa[0m
echo.
goto :eof

:menu
call :header
if "%HWID%"=="0" (
    echo 1^) Block HWID: Yes
) else (
    echo 1^) Block HWID: No
)
echo 2) Set Window Size (Current: %LUNAR_WIDTH% x %LUNAR_HEIGHT%)
if "%LUNAR_MODULE%"=="lunar" (
    echo 3) Set Lunar Module (Current: OptiFine)
) else (
    echo 3^) Set Lunar Module (Current: Forge)
)
echo 4) Download LunarLaunchWrapper
echo 5) Run Lunar Client
echo 6) Exit
echo.
set /p "input=Enter the corresponding number and press Enter: "

if "%input%"=="1" (
    if "%HWID%"=="0" (
        set "HWID_FILE=%USERPROFILE%\.lunarclient\launcher-cache\hwid-private-do-not-share"
        if exist "!HWID_FILE!" (
            set /p HWID=<"!HWID_FILE!"
            goto menu
        ) else (
            echo HWID not found. HWID will remain blocked.
        )
    ) else (
        set "HWID=0"
        goto menu
    )
) else if "%input%"=="2" (
    cls
    set /p "LUNAR_WIDTH=Window width (e.g., 1920): "
    set /p "LUNAR_HEIGHT=Window height (e.g., 1080): "
    
    echo LUNAR_WIDTH=!LUNAR_WIDTH!>"%CONFIG_FILE%"
    echo LUNAR_HEIGHT=!LUNAR_HEIGHT!>>"%CONFIG_FILE%"
) else if "%input%"=="3" (
    cls
    call :header
    echo 1) OptiFine
    echo 2) Forge
    echo -----------------------------
    echo 3) Go Back
    set /p "module=Enter the corresponding number and press Enter: "

    if "%module%"=="1" (
        set "LUNAR_MODULE=lunar"
        echo %LUNAR_MODULE% >> %CONFIG_FILE%
    ) else if "%module%"=="2" (
        set "LUNAR_MODULE=lunar forge"
        echo %LUNAR_MODULE% >> %CONFIG_FILE%
    )
) else if "%input%"=="4" (
    cls
    call :header
    echo Downloading LunarLaunchWrapper...
    call :DownloadFile "https://github.com/uchks/LunarLaunchWrapper/releases/download/!latestllwTag!/LunarLaunchWrapper-!latestllwTag!.jar" "LunarLaunchWrapper-!latestllwTag!.jar"
    echo Download Completed.
    timeout /t 2 > nul
) else if "%input%"=="5" (
    cls
    set "LUNAR_JVM_ARGS=--add-modules jdk.naming.dns --add-exports jdk.naming.dns/com.sun.jndi.dns=java.naming -Djna.boot.library.path=natives -Dlog4j2.formatMsgNoLookups=true --add-opens java.base/java.io=ALL-UNNAMED -Xms3072m -Xmx3072m -Djava.library.path=natives"
    set "LUNAR_JRE=%USERPROFILE%\.lunarclient\jre\4dcd188552ce8876d5e55e1f6d22505109bfa4cb\zulu17.34.19-ca-jre17.0.3-win_x64\bin\java"
    set "LUNAR_CLASSPATH=lunar-lang.jar;lunar-emote.jar;lunar.jar;optifine-0.1.0-SNAPSHOT-all.jar;v1_8-0.1.0-SNAPSHOT-all.jar;common-0.1.0-SNAPSHOT-all.jar;genesis-0.1.0-SNAPSHOT-all.jar"
    set "LUNAR_MAIN_CLASS=com.moonsworth.lunar.genesis.Genesis"
    set "ICHOR_EXT_FILE=OptiFine_v1_8.jar"
    
    if exist "LunarLaunchWrapper-1.0.0.jar" (
        echo Running Lunar Client...
        %LUNAR_JRE% ^
            --add-opens java.base/java.lang=ALL-UNNAMED ^
            %LUNAR_JVM_ARGS% ^
            -cp LunarLaunchWrapper-1.0.0.jar ^
            wtf.zani.launchwrapper.LunarLaunchWrapperKt ^
            --module %LUNAR_MODULE% ^
            --version %LUNAR_VERSION% ^
            --gameDir "%APPDATA%\.minecraft" ^
            --hwid %HWID%
        pause
    ) else (
        echo Running Lunar Client...
        cd "%USERPROFILE%\.lunarclient\offline\multiver"
        %LUNAR_JRE% %LUNAR_JVM_ARGS% ^
            -cp "%LUNAR_CLASSPATH%" ^
            -javaagent:%USERPROFILE%\.lunarclient\agents\Weave-Loader-Agent-0.2.4.jar ^
            -javaagent:%USERPROFILE%\.lunarclient\agents\LunarAntiPollingRateCheck.jar ^
            -javaagent:%USERPROFILE%\.lunarclient\agents\LunarEnable.jar ^
            "%LUNAR_MAIN_CLASS%" ^
            --version "%LUNAR_VERSION%" ^
            --accessToken 0 ^
            --assetIndex %LUNAR_VERSION:.9=% ^
            --userProperties {} ^
            --gameDir "%APPDATA%\.minecraft" ^
            --texturesDir "%USERPROFILE%\.lunarclient\textures" ^
            --width "%LUNAR_WIDTH%" ^
            --height "%LUNAR_HEIGHT%" ^
            --workingDirectory . ^
            --classpathDir . ^
            --ichorClassPath "%LUNAR_CLASSPATH%" ^
            --ichorExternalFiles "%ICHOR_EXT_FILE%" ^
            --installationId 0 ^
            --hwid %HWID% ^
            --launcherVersion %LAUNCHER_VERSION%
        pause
    )
) else if "%input%"=="6" (
    exit /b 0
) else (
    echo Invalid choice.
    pause
)
goto menu

pause

:: Handles downloading files via cURL
:DownloadFile
call :Header
set "url=%~1" 
set "output=%~2"
curl -L "%url%" > "!output!.tmp" 
if !errorlevel! neq 0 (
    call :Header
    echo Error downloading "!output!".
    echo.
    timeout /t 2 > nul
    del "!output!.tmp" 2>nul
)
move /y "!output!.tmp" "!output!"
goto :eof
