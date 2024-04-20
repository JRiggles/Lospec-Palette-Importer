@echo off
SETLOCAL enableDelayedExpansion
REM the ASEPRITE_EXECUTABLE environment variable is set by lospec-palette-importer.lua at run time
REM and contains the path to aseprite.exe (Aseprite API variable 'app.fs.appPath')
REM [Thanks to Lospec Discord user @Fabico for the inspiration!]

REM run lospec-palette-importer helper "lpihelper.lua", pass in url slug as app.params value
REM %1 is the URI and should be "lospec-palette://[palette slug]"
"%ASEPRITE_EXECUTABLE%" --script-param fromURI=%1 --script "%appdata%\Aseprite\extensions\lospec-palette-importer\lpihelper.lua"
