local dialogs = {}

local function setPreferences(preferences, defaultSavePath)
  local dialog =
    Dialog("Lospec Palette Importer - Preferences"):label {
    text = "Save palettes to:"
  }:entry {
    id = "savePathOverride",
    text = preferences.paletteSavePath,
    focus = false
  }
  dialog:button {
    text = "Reset to default",
    onclick = function()
      dialog:modify {
        id = "savePathOverride",
        text = defaultSavePath
      }
    end
  }:separator():label {
    text = "Save palettes as:"
  }:radio {
    id = "gpl",
    text = "*.gpl (recommended)",
    selected = preferences.paletteFormat == ".gpl"
  }:radio {
    id = "aseprite",
    text = "*.aseprite",
    selected = preferences.paletteFormat == ".aseprite"
  }:separator():label {
    text = "Number of palette suggestions (3-10):"
  }:slider {
    id = "suggestionLimitSlider",
    label = "",
    min = 3,
    max = 10,
    value = preferences.suggestionLimit or 5,
    onchange = function()
      preferences.suggestionLimit = dialog.data.suggestionLimitSlider
    end
  }:separator():button {
    id = "ok",
    text = "OK"
  }:show()

  preferences.paletteFormat = dialog.data.gpl and ".gpl" or ".aseprite"
  local newPath = dialog.data.savePathOverride
  if app.fs.isDirectory(newPath) then
    preferences.paletteSavePath = newPath
  else
    app.alert {
      title = "Invalid Directory",
      text = "The specified path is not an existing directory."
    }
  end
end

function dialogs.createImportDialog(preferences, defaultSavePath)
  return Dialog("Lospec Palette Importer"):label {
    text = "Palette name or Lospec URL slug (case-insenstitive):"
  }:entry {
    id = "rawName",
    focus = true
  }:button {
    id = "import",
    text = "Import"
  }:separator():newrow():button {
    id = "daily",
    text = "Get daily palette"
  }:button {
    id = "random",
    text = "Get random palette"
  }:separator():button {
    id = "prefs",
    text = "Preferences...",
    onclick = function()
      setPreferences(preferences, defaultSavePath)
    end
  }:button {
    id = "cancel",
    text = "Cancel"
  }
end

function dialogs.determineRawName(dialog, api)
  if dialog.data.daily then
    return api.getDaily()
  elseif dialog.data.random then
    return "random"
  elseif app.params.fromURI then
    return app.params.fromURI:sub(18)
  end
  return dialog.data.rawName
end

function dialogs.validatePaletteName(slug)
  if slug and slug ~= "" then
    return true
  end
  Dialog("Invalid Palette Name"):label {
    text = "Palette names may only contain the following characters:"
  }:newrow():label {
    text = "  alphanumerics: A-Z, a-z, 0-9"
  }:newrow():label {
    text = "  hyphens/dashes: - "
  }:newrow():label {
    text = '  spaces (these will be converted to hyphens "-")'
  }:newrow():label {
    text = "  square brackets: [ and ] (these will be ignored)"
  }:button {
    text = "OK"
  }:show()
  return false
end

local function savePaletteOptions(dialog, currentPalette, name, author, url, colors, context)
  local sanitizedName = context.sanitizeName(name)
  local savePath =
    app.fs.joinPath(context.preferences.paletteSavePath, sanitizedName .. context.preferences.paletteFormat)
  if dialog.data.saveAndUse or dialog.data.save then
    if context.storage.checkOverwrite(savePath) then
      context.storage.savePalette(
        savePath,
        currentPalette,
        name,
        author,
        url,
        colors,
        context.preferences,
        context.palette
      )
    end
    if dialog.data.saveAndUse then
      context.palette.setAsCurrent(currentPalette)
    end
  elseif dialog.data.use then
    context.palette.setAsCurrent(currentPalette)
  end
end

function dialogs.showPalettePreview(data, url, isRandom, isDailyPalette, context)
  local name = data.name
  local author = data.author ~= "" and data.author or "an unspecified author"
  local colors = data.colors
  local colorCount = #colors
  local currentPalette = Palette(colorCount)
  for index, hex in ipairs(colors) do
    currentPalette:setColor(index - 1, context.palette.hexToColor(hex))
  end

  local dialog =
    Dialog("Lospec Palette Importer - Preview"):label {
    text = '"' .. name .. '" by ' .. author .. ", " .. colorCount .. " colors"
  }:newrow():label {
    id = "dailyTag",
    text = "Daily Tag: #" .. context.api.getTag(),
    visible = isDailyPalette
  }
  local urlDisplay = url:gsub("%.json$", "")
  if isRandom then
    urlDisplay = urlDisplay:gsub("%random", context.sluggify.sluggify(name))
  end

  dialog:button {
    id = "urlPreview",
    text = "Open: " .. urlDisplay,
    onclick = function()
      context.platform.openExternalUrl(urlDisplay)
    end,
    onchange = function()
      dialog:modify {
        id = "urlPreview",
        text = "Open: " .. urlDisplay
      }
    end
  }:separator()

  local maxPerRow = 16
  local colorTable = context.palette.jsonToColorTable(colors)
  for index = 1, colorCount, maxPerRow do
    local row = {}
    for colorIndex = index, math.min(index + maxPerRow - 1, colorCount) do
      table.insert(row, colorTable[colorIndex])
    end
    dialog:shades {
      mode = "pick",
      colors = row,
      hexpand = colorCount <= maxPerRow,
      onclick = function(event)
        if event.button == MouseButton.LEFT then
          app.fgColor = event.color
        elseif event.button == MouseButton.RIGHT then
          app.bgColor = event.color
        end
      end
    }:newrow()
  end

  dialog:separator():button {
    id = "saveAndUse",
    text = "Save and use now",
    focus = true
  }:button {
    id = "use",
    text = "Use now, don't save"
  }:newrow():button {
    id = "save",
    text = "Save as preset"
  }:button {
    id = "back",
    text = "Back...",
    onclick = function()
      dialog:close()
      app.params.fromURI = nil
      context.onBack()
    end
  }:show()

  savePaletteOptions(dialog, currentPalette, name, author, urlDisplay, colors, context)
end

function dialogs.showPaletteNotFound(name, url)
  Dialog("Palette Not Found"):label {
    text = 'Couldn\'t find a palette named "' .. name .. '" on Lospec.'
  }:newrow():label {
    text = "Please make sure the palette's name is spelled correctly."
  }:newrow():label {
    text = "(tried this URL: " .. url .. ")"
  }:button {
    text = "OK"
  }:show()
end

function dialogs.showPaletteSuggestions(query, context)
  local suggestions = context.api.fetchSuggestions(query)
  local dialog =
    Dialog("Did you mean one of these?"):label {
    text = "We couldn't find a palette with the exact name "
  }:newrow():label {
    text = '"' .. query .. '"'
  }:newrow():label {
    text = "but here are some close matches:"
  }:newrow()

  local limit = context.preferences.suggestionLimit or 5
  local count = 0
  for _, suggestion in ipairs(suggestions.data) do
    if count >= limit then
      break
    end
    dialog:button {
      text = suggestion.title,
      onclick = function()
        dialog:close()
        local url = "https://lospec.com/palette-list/" .. suggestion.slug
        local data = context.api.fetchPaletteData(url .. ".json")
        dialogs.showPalettePreview(data, url .. ".json", false, false, context)
      end
    }:newrow()
    count = count + 1
  end
  dialog:separator():button {
    text = "None of these are correct...",
    onclick = function()
      dialog:close()
    end
  }:show()
end

return dialogs
