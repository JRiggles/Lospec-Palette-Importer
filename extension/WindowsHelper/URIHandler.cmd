REM add Aseprite to PATH for CLI access
REM standalone Aseprite path
SET "PATH=C:\Program Files\Aseprite;%PATH%"
REM Steam Aseprite path
SET "PATH=C:\Program Files (x86)\Steam\steamapps\common\Aseprite;%PATH%"

REM run lospec-palette-importer helper "lpihelper.lua", pass in url slug as app.params value
REM try running from the standalone scripts dir first, then try the steam version if that fails
aseprite.exe --script-param fromURI=%1 --script "C:\Users\%USERNAME%\AppData\Roaming\Aseprite\extensions\lospec-palette-importer\lpihelper.lua" || aseprite.exe --script-param fromURI=%1 --script "C:\Program Files (x86)\Steam\steamapps\common\Aseprite\data\extensions\lospec-palette-importer\lpihelper.lua" && EXIT
REM %1 should is passed in by the URI and should be "lospec-palette://[palette slug]"
