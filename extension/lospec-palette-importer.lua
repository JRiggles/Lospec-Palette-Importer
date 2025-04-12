--[[
MIT LICENSE
Copyright © 2024-25 John Riggles [sudo_whoami]

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the “Software”), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
]]
-- stop complaining about unknown Aseprite API methods
---@diagnostic disable: undefined-global
-- ignore dialogs which are defined with local names for readablity, but may be unused
---@diagnostic disable: unused-local

local sluggify = require("sluggify") -- used to convert user input into valid URL slugs

local preferences = {} -- create a global table to store extension preferences
local defaultSavePath = app.fs.joinPath(app.fs.userConfigPath, "palettes")

local main  -- forward declaration of the main function (avoids circular dependency issues)

local function setPrefs()
  -- allow the user to set a custom path for saved palettes (or restore the default path)
  local setPrefsDlg =
    Dialog("Lospec Palette Importer - Preferences"):label {text = "Save palettes to:"}:entry {
    id = "savePathOverride",
    text = preferences.paletteSavePath,
    focus = false
  }
  setPrefsDlg:button {
    text = "Reset to default",
    onclick = function()
      setPrefsDlg:modify {id = "savePathOverride", text = defaultSavePath}
    end
  }:separator():-- allow the user to select their preferred palette format
  label {text = "Save palettes as:"}:radio {
    id = "gpl",
    text = "*.gpl (recommended)",
    selected = (preferences.paletteFormat == ".gpl")
  }:radio {
    id = "aseprite",
    text = "*.aseprite",
    selected = (preferences.paletteFormat == ".aseprite")
  }:separator():button {id = "ok", text = "OK"}:show()

  -- save palette format preference
  preferences.paletteFormat = setPrefsDlg.data.gpl and ".gpl" or ".aseprite"
  local newPath = setPrefsDlg.data.savePathOverride
  if app.fs.isDirectory(newPath) then
    -- save the new path to the preferences if it's a valid directory
    preferences.paletteSavePath = newPath
  else
    app.alert {
      title = "Invalid Directory",
      text = "The specified path is not an existing directory."
    }
  end
end

local function hexToColor(hex)
  -- take a 'hex' color string and convert it to a Color object
  local r = tonumber(hex:sub(1, 2), 16)
  local g = tonumber(hex:sub(3, 4), 16)
  local b = tonumber(hex:sub(5, 6), 16)
  return Color(r, g, b)
end

local function jsonToColorTable(hexTable)
  -- take a table of hex color strings 'hexTable', and convert it to a table of Color objects
  local colorTable = {}
  for _, hex in ipairs(hexTable) do
    table.insert(colorTable, hexToColor(hex))
  end
  return colorTable
end

local function setPaletteAsCurrent(palette)
  -- set the given 'palette' as the current palette for the active sprite
  app.activeSprite:setPalette(palette)
  app.refresh()
end

local function checkOverwrite(savePath)
  -- check if the palette at 'savePath' exists and warn the user if it would be replaced
  local exists = app.fs.isFile(savePath)
  if exists then
    local paletteExistsWarningDlg =
      Dialog("This Palette Already Exists!"):label {
      text = "A palette with this name already exists. Do you want to replace it?"
    }:newrow():label {text = '(selecting "No" will update the active palette but won\'t save it)'}:button {
      id = "yes",
      text = "Yes"
    }:button {id = "no", text = "No"}:show()
    if paletteExistsWarningDlg.data.yes then
      return true
    else
      return false
    end
  else -- this palette hasn't been saved yet, so go ahead
    return true
  end
end

local function writeGplFile(savePath, name, author, url, colors)
  -- write the palette info to a *.gpl file
  local gplFile = assert(io.open(savePath, "w"), "Error writing to palette file!")
  gplFile:write("GIMP Palette", "\n")
  gplFile:write("#" .. name, "\n")
  gplFile:write("#Created by " .. author, "\n")
  gplFile:write("#" .. #colors .. " colors", "\n")
  gplFile:write('#Imported with "Lospec Palette Importer"\n')
  gplFile:write("#Lospec URL: " .. url, "\n")
  -- write each color to the gpl file as rgb values with the hex code as a comment
  for _, color in ipairs(colors) do
    local r = hexToColor(color).red
    local g = hexToColor(color).green
    local b = hexToColor(color).blue
    gplFile:write(r, " ", g, " ", b, " #", color, "\n")
  end
  gplFile:close()
end

local function getLospecData(url)
  local command = 'curl -Ls "' .. url .. '"'
  if true or app.os.windows then
    -- fetch data via curl using io.popen
    local handle = assert(io.popen(command), "curl error - could not connect to " .. url)
    local result = handle:read("*a")
    assert(handle:close(), "curl error - could not close connection")
    return result

  -- keeping this in case we need to revert later if there are issues with io.popen on MacOS:

  -- else -- assume a non-Windows OS, use os.execute instead of io.popen
  --     local tempFilePath = app.fs.joinPath(app.fs.tempPath, "palettedata.tmp")
  --     -- execute curl, redirect output to a temporary file
  --     os.execute(command .. " > " .. tempFilePath)
  --     local file = io.open(tempFilePath, "r")
  --     if file then
  --         local result = file:read("*a")
  --         file:close()
  --         -- os.remove(tempFilePath) -- NOTE: os.remove is not currently available in Aseprite
  --         os.execute("rm " .. tempFilePath) -- remove temporary file
  --         return result
  --     else
  --         app.alert { title = "Error Loading Palette Data", text = "Could not open temp file" }
  --         return
  --     end
  end
end

local function getDaily()
  -- get the Lospec daily palette name
  ---@type string
  return getLospecData([[https://lospec.com/palette-list/current-daily-palette.txt]])
end

local function WindowsRegQuery()
  local key = [[HKEY_CLASSES_ROOT\lospec-palette]] -- load URI handler into registry
  local handle =
    assert(io.popen("reg query " .. key .. ' /v "URL Protocol"'), "Error checking registry for URI handler")
  local regQuery = handle:read("*a")
  handle:close()
  return regQuery
end

local function checkWindowsRegistry()
  if preferences.suppressURIRegAlert == true then
    return
  end
  local query = WindowsRegQuery()
  if query == nil or query == "" then
    local regPermissionDlg =
      Dialog("lospec.com URI Handler Not Registered"):label {
      text = "Your permission is required in order to allow Lospec Palette "
    }:newrow():label {text = 'Importer to handle "Open In App..." links from lospec.com.'}:newrow():label {
      text = 'Please click "OK", then click "Yes" on the Windows UAC prompt.'
    }:button {id = "ok", text = "OK"}:button {id = "cancel", text = "Cancel"}:separator():check {
      id = "notagain",
      text = "Don't show this again"
    }:show()

    if regPermissionDlg.data.notagain then
      preferences.suppressURIRegAlert = true
    end

    if regPermissionDlg.data.ok then -- permission granted, update registry
      os.execute(
        'regedit /s "%appdata%\\Aseprite\\extensions\\lospec-palette-importer\\WindowsHelper\\RegisterURIHandler.reg"'
      )
      -- confirm initial URI handler registration
      query = WindowsRegQuery()
      if query == nil or query == "" then
        app.alert {
          title = "URI Handler Registration Failed",
          text = "An error occurred while registering the lospec.com URI handler. Please try again."
        }
      else
        app.alert {
          title = "URI Handler Registration Successful",
          text = "lospec.com URI handler registered successfully!"
        }
        preferences.suppressURIRegAlert = true
      end
    end
  end
end

local function checkApiVersion()
  if app.apiVersion < 28 then
    app.alert {
      title = "Lospec Palette Importer",
      text = "This extension requires Aseprite version 1.3.7 (API version 28) or higher."
    }
    return false
  end
  return true
end

local function checkSprite()
  if not app.sprite then
    app.alert {
      title = "No Active Sprite!",
      text = "Please open a sprite or create a new one"
    }
    return false
  end
  return true
end

local function createNamePromptDialog()
  return Dialog("Lospec Palette Importer"):label {text = "Palette name or Lospec URL slug (case-insenstitive):"}:entry {
    id = "rawName",
    focus = true
  }:button {id = "import", text = "Import"}:separator():newrow():button {id = "daily", text = "Get daily palette"}:button {
    id = "random",
    text = "Get random palette"
  }:separator():button {id = "prefs", text = "Preferences...", onclick = setPrefs}:button {
    id = "cancel",
    text = "Cancel"
  }
end

local function checkWindowsEnv()
  if os.getenv("ASEPRITE_EXECUTABLE") ~= app.fs.appPath then
    os.execute(string.format('setx %s "%s"', "ASEPRITE_EXECUTABLE", app.fs.appPath))
  end
end

local function determineRawName(dialog)
  if dialog.data.daily then
    return getDaily()
  elseif app.params["fromURI"] then
    return app.params["fromURI"]:sub(#"lospec-palette://" + 1)
  else
    return dialog.data.rawName
  end
end

local function validatePaletteName(name, isRandom)
  if isRandom or (name and name ~= "") then
    return true
  end
  Dialog("Invalid Palette Name"):label {text = "Palette names may only contain the following characters:"}:newrow():label {
    text = "  alphanumerics: A-Z, a-z, 0-9"
  }:newrow():label {text = "  hyphens/dashes: - "}:newrow():label {
    text = '  spaces (these will be converted to hyphens "-")'
  }:newrow():label {text = "  square brackets: [ and ] (these will be ignored)"}:button {text = "OK"}:show()
  return false
end

local function constructLospecUrl(slug, isRandom)
  if isRandom then
    return "https://lospec.com/palette-list/random.json"
  else
    return "https://lospec.com/palette-list/" .. slug .. ".json"
  end
end

local function fetchPaletteData(url)
  local data = getLospecData(url)
  return assert(json.decode(data), "Error decoding JSON data.")
end

local function showPaletteNotFoundDialog(name, url)
  Dialog("Palette Not Found"):label {text = 'Couldn\'t find a palette named "' .. name .. '" on Lospec.'}:newrow():label {
    text = "Please make sure the palette's name is spelled correctly."
  }:newrow():label {text = "(tried this URL: " .. url .. ")"}:button {text = "OK"}:show()
end

local function savePaletteToFile(path, palette, name, author, url, colors)
  if preferences.paletteFormat == ".gpl" then
    writeGplFile(path, name, author, url, colors)
  elseif preferences.paletteFormat == ".aseprite" then
    palette:saveAs(path)
  end
end

local function handlePaletteSaveOptions(dlg, palette, name, author, url, colors)
  local savePath = app.fs.joinPath(preferences.paletteSavePath, name .. preferences.paletteFormat)
  if dlg.data.saveAndUse then
    if checkOverwrite(savePath) then
      savePaletteToFile(savePath, palette, name, author, url, colors)
    end
    setPaletteAsCurrent(palette)
  elseif dlg.data.use then
    setPaletteAsCurrent(palette)
  elseif dlg.data.save then
    savePaletteToFile(savePath, palette, name, author, url, colors)
  end
end

local function showPalettePreviewDialog(data, url, wasRandom)
  local name = data.name
  local author = data.author ~= "" and data.author or "an unspecified author"
  local colors = data.colors
  local ncolors = #colors

  local palette = Palette(ncolors)
  for i, hex in ipairs(colors) do
    palette:setColor(i - 1, hexToColor(hex))
  end

  local previewDlg =
    Dialog("Lospec Palette Importer - Preview"):label {
    text = '"' .. name .. '" by ' .. author .. ", " .. ncolors .. " colors"
  }:newrow()

  local urlDisplay = url:gsub("%.json$", "")
  if wasRandom then
    urlDisplay = urlDisplay:gsub("%random", sluggify.sluggify(name))
  end

  previewDlg:entry {
    id = "urlPreview",
    text = urlDisplay,
    onchange = function()
      previewDlg:modify {id = "urlPreview", text = urlDisplay}
    end
  }:separator()

  local maxPerRow, colorTable = 16, jsonToColorTable(colors)
  for i = 1, ncolors, maxPerRow do
    local row = {}
    for j = i, math.min(i + maxPerRow - 1, ncolors) do
      table.insert(row, colorTable[j])
    end
    previewDlg:shades {
      mode = "pick",
      colors = row,
      hexpand = ncolors <= maxPerRow,
      onclick = function(e)
        if e.button == MouseButton.LEFT then
          app.fgColor = e.color
        elseif e.button == MouseButton.RIGHT then
          app.bgColor = e.color
        end
      end
    }:newrow()
  end

  previewDlg:separator():button {id = "saveAndUse", text = "Save and use now", focus = true}:button {
    id = "use",
    text = "Use now, don't save"
  }:newrow():button {id = "save", text = "Save as preset"}:button {
    id = "back",
    text = "Back...",
    onclick = function()
      previewDlg:close()
      app.params.fromURI = nil
      main()
    end
  }:show()

  handlePaletteSaveOptions(previewDlg, palette, name, author, urlDisplay, colors)
end

function main()
  if not checkApiVersion() then
    return
  end
  if app.os.windows then
    -- ensure everything is set up for the URI handler on Windows
    checkWindowsRegistry()
    checkWindowsEnv()
  end
  if not checkSprite() then
    return
  end

  local dialog = createNamePromptDialog()
  if not app.params["fromURI"] then
    dialog:show()
  end

  if dialog.data.import or dialog.data.daily or dialog.data.random or app.params["fromURI"] then
    local rawName = determineRawName(dialog)
    local paletteName = sluggify.sluggify(rawName)
    if not validatePaletteName(paletteName, dialog.data.random) then
      return main()
    end

    local url = constructLospecUrl(paletteName, dialog.data.random)
    local paletteData = fetchPaletteData(url)
    if paletteData.error then
      showPaletteNotFoundDialog(rawName, url)
      return main()
    end

    showPalettePreviewDialog(paletteData, url, dialog.data.random)
    app.params.fromURI = nil
    app.command.Refresh()
  end
end

-- Aseprite plugin API stuff...
---@diagnostic disable-next-line: lowercase-global
function init(plugin) -- initialize extension
  preferences = plugin.preferences -- update preferences global with plugin.preferences values
  -- if the user hasn't configured a custom path for saved palettes, use the default
  if preferences.paletteSavePath == nil then
    preferences.paletteSavePath = defaultSavePath
  end
  -- if the user hasn't specified a preferred palette format, use the default (*.gpl)
  if preferences.paletteFormat == nil then
    preferences.paletteFormat = ".gpl"
  end

  if preferences.suppressURIRegAlert == nil then
    preferences.suppressURIRegAlert = false
  end

  -- add "Import Palette from Lospec" command to palette options menu
  plugin:newCommand {
    id = "importFromLospec",
    title = "Import Palette from Lospec",
    group = "palette_generation",
    onclick = main -- run main function
  }
end

---@diagnostic disable-next-line: lowercase-global
function exit(plugin)
  plugin.preferences = preferences -- save preferences
  app.params.fromURI = nil -- reset URI input storage so manual import can be used again
  app.refresh() -- refresh to load any changes to the palette list
  return nil
end
