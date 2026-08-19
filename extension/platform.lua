local platform = {}

local function windowsRegQuery()
  local key = [[HKEY_CLASSES_ROOT\lospec-palette]]
  local handle =
    assert(
      io.popen("reg query " .. key .. ' /v "URL Protocol"'),
      "Error checking registry for URI handler"
    )
  local result = handle:read("*a")
  handle:close()
  return result
end

function platform.checkWindowsRegistry(preferences)
  if preferences.suppressURIRegAlert == true then
    return
  end

  local query = windowsRegQuery()
  if query ~= nil and query ~= "" then
    return
  end

  local dialog =
    Dialog("lospec.com URI Handler Not Registered"):label {
    text = "Your permission is required in order to allow Lospec Palette "
  }:newrow():label {
    text = 'Importer to handle "Open In App..." links from lospec.com.'
  }:newrow():label {
    text = 'Please click "OK", then click "Yes" on the Windows UAC prompt.'
  }:button {
    id = "ok",
    text = "OK"
  }:button {
    id = "cancel",
    text = "Cancel"
  }:separator():check {
    id = "notagain",
    text = "Don't show this again"
  }:show()

  if dialog.data.notagain then
    preferences.suppressURIRegAlert = true
  end
  if not dialog.data.ok then
    return
  end

  os.execute(
    'regedit /s "%appdata%\\Aseprite\\extensions\\lospec-palette-importer\\WindowsHelper\\RegisterURIHandler.reg"'
  )
  query = windowsRegQuery()
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

function platform.checkWindowsEnv()
  if os.getenv("ASEPRITE_EXECUTABLE") ~= app.fs.appPath then
    os.execute(string.format('setx %s "%s"', "ASEPRITE_EXECUTABLE", app.fs.appPath))
  end
end

function platform.openExternalUrl(url)
  ---@diagnostic disable-next-line: undefined-field
  if app.os.windows then
    os.execute('start "" "' .. url .. '"')
  ---@diagnostic disable-next-line: undefined-field
  elseif app.os.macos then
    os.execute('open "' .. url .. '"')
  ---@diagnostic disable-next-line: undefined-field
  elseif app.os.linux then
    os.execute('xdg-open "' .. url .. '"')
  end
end

return platform
