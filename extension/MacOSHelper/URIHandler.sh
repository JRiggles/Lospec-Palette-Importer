#!/bin/bash
# add aseprite to PATH for CLI access

# standalone aseprite path
export PATH="/Applications/Aseprite.app/Contents/MacOS:$PATH"

# Steam Aseprite path
export PATH="/Users/$USER/Library/Application Support/Steam/steamapps/common/Aseprite/Aseprite.app/Contents/MacOS:$PATH"

# run lospec-palette-importer helper "lpihelper.lua", pass in url slug as app.params value
# try running from the standalone scripts dir first, then try the steam version if that fails
aseprite --script-param fromURI=$1 --script "/Users/$USER/Library/Application Support/Aseprite/extensions/lospec-palette-importer/lpihelper.lua" ||
aseprite --script-param fromURI=$1 --script "/Users/$USER/Library/Application Support/Steam/steamapps/common/Aseprite/data/extensions/lospec-palette-importer/lpihelper.lua" &
# bring Aseprite to the front (requires "Privacy & Security > Automation" permission)
osascript -e 'tell application "System Events" to set frontmost of process "Aseprite" to true'
exit
# $1 is passed in by the URI and should be "lospec-palette://[palette slug]"
