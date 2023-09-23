@echo off
setlocal enabledelayedexpansion
set "LUNAR_VERSION=1.8.9"
set "CONFIG_FILE=config.txt"

if not exist "%CONFIG_FILE%" (
    echo LUNAR_WIDTH=1280>>"%CONFIG_FILE%"
    echo LUNAR_HEIGHT=720>>"%CONFIG_FILE%"
)

for /f "tokens=1,2 delims== " %%a in (%CONFIG_FILE%) do (
    if "%%a"=="LUNAR_WIDTH" set "LUNAR_WIDTH=%%b"
    if "%%a"=="LUNAR_HEIGHT" set "LUNAR_HEIGHT=%%b"
)

for /f "tokens=2 delims=: " %%a in ('curl -s https://launcherupdates.lunarclientcdn.com/latest.yml ^| findstr "version:"') do (
    set "LAUNCHER_VERSION=%%a"
)

:menu
cls
echo   lccll - lunar client command line launcher
echo   Created by [31munethical[0m
echo   [36mhttps://discord.gg/vhJ8Dsp9qa[0m
echo.
if "%HWID%"=="0" (
    echo   1^) Block HWID: Yes
) else (
    echo   1^) Block HWID: No
)
echo   2) Set Window Size (Current: %LUNAR_WIDTH% x %LUNAR_HEIGHT%)
echo   3) Run Lunar Client
echo   4) Exit
echo.
set /p "input=Enter the corresponding number and press Enter: "

if "%input%"=="1" (
    if "%HWID%"=="0" (
        set "HWID_FILE=%USERPROFILE%\.lunarclient\launcher-cache\hwid-private-do-not-share"
        if exist "%HWID_FILE%" (
            set /p HWID=<"%HWID_FILE%"
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
    echo Running Lunar Client..
    
    set "LUNAR_JVM_ARGS=--add-modules jdk.naming.dns --add-exports jdk.naming.dns/com.sun.jndi.dns=java.naming -Djna.boot.library.path=natives -Dlog4j2.formatMsgNoLookups=true --add-opens java.base/java.io=ALL-UNNAMED -Xms3072m -Xmx3072m -Djava.library.path=natives"
    set "LUNAR_JRE=%USERPROFILE%\.lunarclient\jre\4dcd188552ce8876d5e55e1f6d22505109bfa4cb\zulu17.34.19-ca-jre17.0.3-win_x64\bin\java"
    set "LUNAR_CLASSPATH=lunar-lang.jar;lunar-emote.jar;lunar.jar;optifine-0.1.0-SNAPSHOT-all.jar;v1_8-0.1.0-SNAPSHOT-all.jar;common-0.1.0-SNAPSHOT-all.jar;genesis-0.1.0-SNAPSHOT-all.jar"
    set "LUNAR_MAIN_CLASS=com.moonsworth.lunar.genesis.Genesis"
    set "ICHOR_EXT_FILE=OptiFine_v1_8.jar"

    cd "%USERPROFILE%\.lunarclient\offline\multiver"

    %LUNAR_JRE% %LUNAR_JVM_ARGS% ^
    	-cp "%LUNAR_CLASSPATH%" ^
    	-javaagent:C:\Users\jason\.lunarclient\agents\Weave-Loader-Agent-0.2.4.jar ^
    	-javaagent:C:\Users\jason\.lunarclient\agents\LunarAntiPollingRateCheck.jar ^
    	-javaagent:C:\Users\jason\.lunarclient\agents\LunarEnable.jar ^
    	"%LUNAR_MAIN_CLASS%" ^
    	--version "%LUNAR_VERSION%" ^
    	--accessToken 0 ^
    	--assetIndex %LUNAR_VERSION:.9=% ^
    	--userProperties {} ^
    	--gameDir "%USERPROFILE%\.minecraft" ^
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
    goto menu
) else if "%input%"=="4" (
    exit /b 0
) else (
    echo Invalid choice.
    pause
)
goto menu

pause
