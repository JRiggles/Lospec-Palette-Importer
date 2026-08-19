local palette = {}

function palette.hexToColor(hex)
  local red = tonumber(hex:sub(1, 2), 16)
  local green = tonumber(hex:sub(3, 4), 16)
  local blue = tonumber(hex:sub(5, 6), 16)
  return Color {red = red, green = green, blue = blue}
end

function palette.jsonToColorTable(hexTable)
  local colorTable = {}
  for _, hex in ipairs(hexTable) do
    table.insert(colorTable, palette.hexToColor(hex))
  end
  return colorTable
end

function palette.setAsCurrent(currentPalette)
  app.activeSprite:setPalette(currentPalette)
  app.refresh()
end

return palette
