--[[
MIT LICENSE
Copyright © 2024 John Riggles [sudo_whoami]

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

local function setSavePath()
    -- allow the user to set a custom path for saved palettes (or restore the default path)
    local setPathDlg = Dialog("Enter Path for Saved Palettes")
        :entry { id = "savePathOverride", text = preferences.paletteSavePath }
        setPathDlg:button {
            text = "Reset to Default",
            onclick = function ()
                setPathDlg:modify { id = "savePathOverride", text = defaultSavePath }
            end
        }
        :button { text = "Use This Path", focus = true }
        :show()

    local newPath = setPathDlg.data.savePathOverride
    if app.fs.isDirectory(newPath) then
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
    -- set the give 'palette' as the current palette for the active sprite
    app.activeSprite:setPalette(palette)
    app.refresh()
end

local function checkOverwrite(savePath)
    -- check if the palette at 'savePath' exists and warn the user if if would be replaced
    local exists = app.fs.isFile(savePath)
    if exists then
        local paletteExistsWarningDlg = Dialog("This Palette Already Exists!")
            :label { text = "A palette with this name already exists. Do you want to replace it?" }
            :newrow()
            :label { text = '(selecting "No" will update the active palette but won\'t save it)' }:button { id = "yes", text = "Yes" }
            :button { id = "no", text = "No" }
            :show()
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
    gplFile:write("#Lospec URL: " .. url, "\n")
    gplFile:write("#" .. #colors .. " colors", "\n")
    gplFile:write(
        "#Imported into Aseprite via \"Lospec Palette Importer\"",
        " - (C)2024 J. Riggles [sudo_whoami] - MIT LICENSE",
        "\n"
    )
    -- write each color to the gpl file as rgb values with the hex code as a comment
    for _, color in ipairs(colors) do
        local r = hexToColor(color).red
        local g = hexToColor(color).green
        local b = hexToColor(color).blue
        gplFile:write(r, " ", g, " ", b, " #", color, "\n")
    end
    gplFile:close()
end

local function getOS()
    return package.config:sub(1, 1) == "\\" and "Windows" or "Unix"
end

local function getLospecData(url)
    local command = 'curl -Ls "' .. url .. '"'
    if getOS() == "Windows" then
        -- fetch data via curl using io.popen
        local handle = assert(io.popen(command), "curl error - could not connect to " .. url)
        local result = handle:read("*a")
        assert(handle:close(), "curl error - could not close connection")
        return result
    else -- assume a non-Windows OS, use os.execute instead of io.popen
        local tempFilePath = app.fs.joinPath(app.fs.tempPath, "palettedata.tmp")
        -- execute curl, redirect output to a temporary file
        os.execute(command .. " > " .. tempFilePath)
        local file = io.open(tempFilePath, "r")
        if file then
            local result = file:read("*a")
            file:close()
            -- os.remove(tempFilePath) -- NOTE: os.remove is not currently available in Aseprite
            os.execute("rm " .. tempFilePath) -- remove temporary file
            return result
        else
            app.alert { title = "Error Loading Palette Data", text = "Could not open temp file" }
            return
        end
    end
end

local function getDaily()
    -- get the Lospec daily palette name
    ---@type string
    return getLospecData([[https://lospec.com/palette-list/current-daily-palette.txt]])
end

local function WindowsRegQuery()
    local key = [[HKEY_CLASSES_ROOT\lospec-palette]] -- load URI handler into registry
    local handle = assert(
        io.popen('reg query ' .. key .. ' /v "URL Protocol"'),
        "Error checking registry for URI handler"
    )
    local regQuery = handle:read("*a")
    handle:close()
    return regQuery
end

local function URIregistryCheck()
    if preferences.suppressURIRegAlert == true then
        return
    end
    local query = WindowsRegQuery()
    if query == nil or query == "" then
        local regPermissionDlg = Dialog("lospec.com URI Handler Not Registered")
            :label { text = "Your permission is required in order to allow Lospec Palette " }
            :newrow()
            :label { text = "Importer to handle \"Open In App...\" links from lospec.com." }
            :newrow()
            :label { text = "Please click \"OK\", then click \"Yes\" on the Windows UAC prompt." }
            :button { id = "ok", text = "OK" }
            :button { id = "cancel", text = "Cancel" }
            :separator()
            :check { id = "notagain", text = "Don't show this again" }
            :show()

        if regPermissionDlg.data.notagain then
            preferences.suppressURIRegAlert = true
        end

        if regPermissionDlg.data.ok then -- permission granted, update registry
            os.execute( "regedit /s \"%appdata%\\Aseprite\\extensions\\lospec-palette-importer\\WindowsHelper\\RegisterURIHandler.reg\"" )
            -- confirm initial URI handler registration
            query = WindowsRegQuery()
            if query == nil or query == "" then
                app.alert("An error occurred while registering the lospec.com URI handler. Please try again.")
            else
                app.alert("lospec.com URI handler registered successfully!")
                preferences.suppressURIRegAlert = true
            end
        end

    else
        return -- nothing to do
    end
end

local function main()
    if getOS() == "Windows" then
        URIregistryCheck() -- check for URI handler in registry (Windows only)
    end

    -- check if there's an active sprite (can't run this without a sprite, but just in case...)
    if not app.sprite then
        app.alert {
            title = "No Active Sprite!",
            text = "Please open a sprite or create a new one"
        }
        return -- bail
    end

    local namePromptDlg = Dialog("Import Palette from Lospec")
        :label { text = "Palette name (or Lospec URL slug):"}
        :entry { id = "rawName", focus = true}
        :newrow()
        :button { id = "daily", text = "Get Daily Palette" }
        :newrow()
        :button { id = "random", text = "Get Random Palette" }
        :separator()
        :label { text = "Palette names are case-insenstitive" }
        :button { id = "ok", text = "OK" }
        :button { id = "cancel", text = "Cancel" }
    if not app.params["fromURI"] then
        namePromptDlg:show()
    end

    if (namePromptDlg.data.ok or namePromptDlg.data.daily or
        namePromptDlg.data.random or app.params["fromURI"]) then
        -- get the palette name from the user, sanitized to remove invalid characters
        local rawName = ""
        if not namePromptDlg.data.daily and not app.params["fromURI"] then
            -- rawName is coming from the user prompt
            rawName = namePromptDlg.data.rawName
        elseif namePromptDlg.data.daily then
            rawName = getDaily()
        elseif app.params["fromURI"] then
            -- get palettes slug from URI passed in by CLI call
            rawName = app.params["fromURI"]
            -- strip off URI protocol prefix
            rawName = rawName:sub(#"lospec-palette://" + 1)
        end
        local paletteName = sluggify.sluggify(rawName)

        -- show a warning dialog if the palette name is empty
        if not namePromptDlg.data.random and (paletteName == nil or paletteName == "") then
            local invalidInputDlg = Dialog("Invalid Palette Name")
                :label { text = "Palette names may only contain the following characters:" }
                :newrow()
                :label { text = "  alphanumerics: A-Z, a-z, 0-9" }
                :newrow()
                :label { text = "  hyphens/dashes: - " }
                :newrow()
                :label { text = '  spaces (these will be converted to hyphens "-")' }
                :newrow()
                :label { text = "  square brackets: [ and ] (these will be ignored)" }
                :button { text = "OK" }
                :show()
            return -- bail
        end

        -- construct URL for the Lospec API
        local url = ""
        if namePromptDlg.data.random then
            url = "https://lospec.com/palette-list/random.json"
        else
            url = "https://lospec.com/palette-list/" .. paletteName .. ".json"
        end
        -- fetch JSON data from Lospec
        local data = getLospecData(url)
        -- parse JSON response
        local paletteData = assert(
            json.decode(data),
            "Error decoding JSON data. Aseprite API v1.3-rc5 or greater is required."
        )

        if paletteData.error then
            local paletteNotFoundDlg = Dialog("Palette Not Found")
                :label {
                    text = 'Couldn\'t find a palette named "' .. rawName .. '" on Lospec.'
                }
                :newrow()
                :label { text = "Please make sure the palette's name is spelled" }
                :newrow()
                :label { text = "correctly, then try again." }
                :newrow()
                :label { text = "(tried this URL: " .. url .. ")" }
                :button { text = "OK" }
                :show()
        else
            -- extract color data from the JSON response
            local author = paletteData.author
            local colors = paletteData.colors
            local name = paletteData.name
            -- get number of colors in palette
            local ncolors = #colors

            -- setup fallback in case of missing author name
            if author == "" then
                author = "an unspecified author"
            end

            --create new palette
            local palette = Palette(ncolors)
            for index, color in ipairs(colors) do
                palette:setColor(index - 1, hexToColor(color))
            end

            -- show a dialog with a preview of the imported palette
            local allColors = jsonToColorTable(colors)
            local maxColorsPerRow = 16
            -- remove file extension from url so it can be shown in the preview dialog below
            local lospecUrl = url:gsub("%.json$", "")

            local palettePreviewDlg = Dialog("Lospec Importer - Palette Preview")
                :label { text = '"' .. name .. '" by ' .. author .. ", " .. ncolors .. " colors" }
                :newrow()
            palettePreviewDlg:entry { -- NOTE: specifying palettePreviewDlg is necessary here
                id = "urlPreview",
                text = lospecUrl,
                -- set the text back to the URL on change, making this "read-only" but copyable
                onchange = function()
                    palettePreviewDlg:modify { id = "urlPreview", text = lospecUrl }
                    end
                }
                :separator()
                -- add shades in rows of 'maxColorsPerRow'
                for i = 1, ncolors, maxColorsPerRow do
                    local endIndex = math.min(i + maxColorsPerRow - 1, ncolors)
                    local colorRow = {}
                    for j = i, endIndex do
                        table.insert(colorRow, allColors[j])
                    end
                    -- insert new row of shades, expand to fit if there aren't too many colors
                    local doExpand = ncolors <= maxColorsPerRow
                    palettePreviewDlg:shades {
                        mode = "pick",
                        colors = colorRow,
                        hexpand = doExpand,
                        onclick = function(e)
                            if e.button == MouseButton.LEFT then
                              app.fgColor = e.color
                            elseif e.button == MouseButton.RIGHT then
                              app.bgColor = e.color
                            end
                          end
                    }:newrow()
                end
            palettePreviewDlg
                :separator()
                :label { text = "Palette save format:" }
                :radio { id = "gpl", text = "*.gpl (default)", selected = true }
                :radio { id = "aseprite", text = "*.aseprite" }
                :newrow()
                :button { text = "Set save location...", onclick = setSavePath }
                :separator()
                :button { id="saveAndUse", text="Save and use now", focus = true}
                :button { id = "use", text = "Use now, don't save" }
                :newrow()
                :button { id = "save", text = "Save as preset" }
                :button { id = "cancel", text = "Cancel" }
                :show()
            -- set palette file extension
            local paletteExtension = ""
            if palettePreviewDlg.data.gpl then
                paletteExtension = ".gpl"
            elseif palettePreviewDlg.data.aseprite then
                paletteExtension = ".aseprite"
            end

            local savePath = app.fs.joinPath(
                preferences.paletteSavePath, name .. paletteExtension
            )

            -- save and use: save the palette as a preset and update the current sprite's palette
            if palettePreviewDlg.data.saveAndUse then
                if checkOverwrite(savePath) then
                    if palettePreviewDlg.data.gpl then
                        writeGplFile(savePath, name, author, lospecUrl, colors)
                    elseif palettePreviewDlg.data.aseprite then
                        palette:saveAs(savePath)
                    end
                end
                setPaletteAsCurrent(palette)

            -- use: update the current sprite's palette without saving the palette to a file
            elseif palettePreviewDlg.data.use then
                setPaletteAsCurrent(palette)

            -- save: save the palettes as a preset, but retain the current sprite's palette
            elseif palettePreviewDlg.data.save then
                if palettePreviewDlg.data.gpl then
                    writeGplFile(savePath, name, author, lospecUrl, colors)
                elseif palettePreviewDlg.data.aseprite then
                    palette:saveAs(savePath)
                end
            end
        end
    app.command.Refresh() -- refresh to load any changes to the palette list
    app.params.fromURI = nil -- reset URI input storage so manual import can be used again
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
    -- this is handled in main() also - it's here JIC
    app.params.fromURI = nil -- reset URI input storage so manual import can be used again
    return nil
end
