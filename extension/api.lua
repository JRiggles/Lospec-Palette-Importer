local api = {}

function api.getLospecData(url)
  local command = 'curl -Ls "' .. url .. '"'
  ---@diagnostic disable-next-line: undefined-field
  if app.os.linux then
    command = '/usr/bin/env -i PATH=/usr/bin:/bin /usr/bin/curl -Ls "' .. url .. '" 2>&1'
  end
  local handle = assert(io.popen(command), "curl error - could not connect to " .. url)
  local result = handle:read("*a")
  handle:close()
  return result
end

function api.getDaily()
  return api.getLospecData([[https://lospec.com/palette-list/current-daily-palette.txt]])
end

function api.getTag()
  return api.getLospecData([[https://lospec.com/dailies/current-daily-tag.txt]])
end

function api.fetchPaletteData(url)
  local data = api.getLospecData(url)
  return assert(json.decode(data), "Error decoding JSON data.")
end

function api.fetchSuggestions(query)
  local data = api.getLospecData("https://api.lospec.com/palettes/suggest/" .. query)
  return assert(json.decode(data), "Error decoding JSON data.")
end

return api
