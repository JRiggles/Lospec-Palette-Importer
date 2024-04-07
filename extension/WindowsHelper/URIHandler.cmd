@echo off
SETLOCAL enableDelayedExpansion

REM Initialize variable to store Aseprite executable path
set "ASEPRITE_EXECUTABLE="

REM Loop through all logical disk drives to find Aseprite.exe (needed for CLI access)
for /f "skip=1 delims=" %%d in ('wmic logicaldisk get deviceid') do (
    for /f %%e in ('where /r %%d "Aseprite.exe" 2^>nul') do (
        if exist "%%e" (
            set "ASEPRITE_EXECUTABLE=%%e"
            REM Break the loop if Aseprite executable is found
            goto :EndLoop
        )
    )
)

:EndLoop

REM run lospec-palette-importer helper "lpihelper.lua", pass in url slug as app.params value
REM %1 is the URI and should be "lospec-palette://[palette slug]"
%ASEPRITE_EXECUTABLE% --script-param fromURI=%1 --script "%appdata%\Aseprite\extensions\lospec-palette-importer\lpihelper.lua"
