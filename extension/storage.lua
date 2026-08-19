local storage = {}

function storage.checkOverwrite(savePath)
  if not app.fs.isFile(savePath) then
    return true
  end

  local dialog = Dialog("This Palette Already Exists!"):label {
    text = "A palette with this name already exists. Do you want to replace it?"
  }:newrow():label {
    text = '(selecting "No" will update the active palette but won\'t save it)'
  }:button {
    id = "yes",
    text = "Yes"
  }:button {
    id = "no",
    text = "No"
  }:show()
  return dialog.data.yes == true
end

function storage.writeGplFile(savePath, name, author, url, colors, paletteModule)
  local gplFile = assert(io.open(savePath, "w"), "Error writing to palette file!")
  gplFile:write("GIMP Palette", "\n")
  gplFile:write("#" .. name, "\n")
  gplFile:write("#Created by " .. author, "\n")
  gplFile:write("#" .. #colors .. " colors", "\n")
  gplFile:write('#Imported with "Lospec Palette Importer"\n')
  gplFile:write("#Lospec URL: " .. url, "\n")
  for _, color in ipairs(colors) do
    local asepriteColor = paletteModule.hexToColor(color)
    gplFile:write(
      asepriteColor.red, " ", asepriteColor.green, " ", asepriteColor.blue, " #", color, "\n"
    )
  end
  gplFile:close()
end

function storage.savePalette(path, currentPalette, name, author, url, colors, preferences, paletteModule)
  if preferences.paletteFormat == ".gpl" then
    storage.writeGplFile(path, name, author, url, colors, paletteModule)
  elseif preferences.paletteFormat == ".aseprite" then
    currentPalette:saveAs(path)
  end
end

return storage
