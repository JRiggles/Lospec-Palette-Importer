--[[
MIT LICENSE
Copyright © 2024-26 John Riggles [sudo_whoami]

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
of the Software, and to permit persons to whom the Software is furnished to do
so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
]]
---@diagnostic disable: undefined-global

local api = require("api")
local dialogs = require("dialogs")
local palette = require("palette")
local platform = require("platform")
local sluggify = require("sluggify")
local storage = require("storage")

local preferences = {}
local defaultSavePath = app.fs.joinPath(app.fs.userConfigPath, "palettes")
local main

local function sanitizeNameForFile(name)
  name = name:gsub('[\\/:*?"<>|%c]', "-")
  return name:gsub("^%s+", ""):gsub("%s+$", ""):gsub("%-+", "-")
end

local context = {
  api = api,
  palette = palette,
  platform = platform,
  sluggify = sluggify,
  storage = storage,
  preferences = preferences,
  sanitizeName = sanitizeNameForFile,
  onBack = function()
    main()
  end
}

function main()
  if app.apiVersion < 28 then
    app.alert {
      title = "Lospec Palette Importer",
      text = "This extension requires Aseprite version 1.3.7 (API version 28) or higher."
    }
    return
  end

  ---@diagnostic disable-next-line: undefined-field
  if app.os.windows then
    platform.checkWindowsRegistry(preferences)
    if app.params.fromURI then
      platform.checkWindowsEnv()
    end
  end

  if not app.sprite then
    app.alert {
      title = "No Active Sprite!",
      text = "Please open a sprite or create a new one"
    }
    return
  end

  local importDialog = dialogs.createImportDialog(preferences, defaultSavePath)
  if not app.params.fromURI then
    importDialog:show()
  end

  if (importDialog.data and not importDialog.data.cancel) or app.params.fromURI then
    local rawName = dialogs.determineRawName(importDialog, api)
    if rawName:sub(1, 32) == "https://lospec.com/palette-list/" then
      rawName = rawName:sub(33)
    end

    local paletteSlug = sluggify.sluggify(rawName)
    if not (importDialog.data.import or importDialog.data.daily or importDialog.data.random or app.params.fromURI) then
      return
    end

    if not dialogs.validatePaletteName(paletteSlug) then
      return main()
    end

    local url = "https://lospec.com/palette-list/" .. paletteSlug .. ".json"
    local paletteData = api.fetchPaletteData(url)
    if paletteData.error then
      dialogs.showPaletteSuggestions(rawName, context)
      return
    end

    dialogs.showPalettePreview(paletteData, url, importDialog.data.random, importDialog.data.daily, context)
    app.params.fromURI = nil
    app.command.Refresh()
  end
end

---@diagnostic disable-next-line: lowercase-global
function init(plugin)
  preferences = plugin.preferences
  context.preferences = preferences

  if preferences.paletteSavePath == nil then
    preferences.paletteSavePath = defaultSavePath
  end
  if preferences.paletteFormat == nil then
    preferences.paletteFormat = ".gpl"
  end
  if preferences.suppressURIRegAlert == nil then
    preferences.suppressURIRegAlert = false
  end
  if preferences.suggestionLimit == nil then
    preferences.suggestionLimit = 5
  end

  plugin:newCommand {
    id = "importFromLospec",
    title = "Import Palette from Lospec",
    group = "palette_generation",
    onclick = main
  }
end

---@diagnostic disable-next-line: lowercase-global
function exit(plugin)
  plugin.preferences = preferences
  app.params.fromURI = nil
  app.refresh()
  return nil
end
