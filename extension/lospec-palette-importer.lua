--[[
MIT LICENSE
Copyright © 2024 John Riggles

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the “Software”), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
]]

-- stop complaining about unknow Aseprite API methods
---@diagnostic disable: undefined-global
-- ignore dialogs which are defined with local names for readablity, but may be unused
---@diagnostic disable: unused-local

-- local utf8 = require("utf8") -- utf8 lib is necessary to handle special characters
-- NOTE: looks like utf8 is included in the Aseprite API as a global

local letters = { -- mapping of replacementChar characters
    ["áàâǎăãảȧạäåḁāąⱥȁấầẫẩậắằẵẳặǻǡǟȁȃａ"] = "a",
    ["ÁÀÂǍĂÃẢȦẠÄÅḀĀĄȺȀẤẦẪẨẬẮẰẴẲẶǺǠǞȀȂＡ"] = "A",
    ["ḃḅḇƀᵬᶀｂ"] = "b",
    ["ḂḄḆɃƁʙＢ"] = "B",
    ["ćĉčċçḉȼɕｃƇ"] = "c",
    ["ĆĈČĊÇḈȻＣƈ"] = "C",
    ["ďḋḑḍḓḏđɗƌｄᵭᶁᶑȡ"] = "d",
    ["ĎḊḐḌḒḎĐƉƊƋＤᴅᶑȡ"] = "D",
    ["éèêḙěĕẽḛẻėëēȩęɇȅếềễểḝḗḕȇẹệｅᶒⱸ"] = "e",
    ["ÉÈÊḘĚĔẼḚẺĖËĒȨĘɆȄẾỀỄỂḜḖḔȆẸỆＥᴇ"] = "E",
    ["ḟƒｆᵮᶂ"] = "f",
    ["ḞƑＦ"] = "F",
    ["ǵğĝǧġģḡǥɠｇᶃ"] = "g",
    ["ǴĞĜǦĠĢḠǤƓＧɢ"] = "G",
    ["ĥȟḧḣḩḥḫ̱ẖħⱨｈ"] = "h",
    ["ĤȞḦḢḨḤḪĦⱧＨʜ"] = "H",
    ["íìĭîǐïḯĩįīỉȉȋịḭɨiıｉ"] = "i",
    ["ÍÌĬÎǏÏḮĨĮĪỈȈȊỊḬƗİIＩ"] = "I",
    ["ĵɉｊʝɟʄǰ"] = "j",
    ["ĴɈＪᴊ"] = "J",
    ["ḱǩķḳḵƙⱪꝁｋᶄ"] = "k",
    ["ḰǨĶḲḴƘⱩꝀＫᴋ"] = "K",
    ["ĺľļḷḹḽḻłŀƚⱡɫｌɬᶅɭȴ"] = "l",
    ["ĹĽĻḶḸḼḺŁĿȽⱠⱢＬʟ"] = "L",
    ["ḿṁṃɱｍᵯᶆ"] = "m",
    ["ḾṀṂⱮＭᴍ"] = "M",
    ["ńǹňñṅņṇṋṉɲƞｎŋᵰᶇɳȵ"] = "n",
    ["ŃǸŇÑṄŅṆṊṈṉƝȠＮŊɴ"] = "N",
    ["óòŏôốồỗổǒöȫőõṍṏȭȯȱøǿǫǭōṓṑỏȍȏơớờỡởợọộɵｏⱺᴏ"] = "o",
    ["ÓÒŎÔỐỒỖỔǑÖȪŐÕṌṎȬȮȰØǾǪǬŌṒṐỎȌȎƠỚỜỠỞỢỌỘƟＯ"] = "O",
    ["ṕṗᵽ"] = "p",
    ["ṔṖⱣƤＰ"] = "P",
    ["ɋʠｑ"] = "q",
    ["ɊＱ"] = "Q",
    ["ŕřṙŗȑȓṛṝṟɍɽｒᵲᶉɼɾᵳ"] = "r",
    ["ŔŘṘŖȐȒṚṜṞɌⱤＲʀ"] = "R",
    ["śṥŝšṧṡşṣṩșｓßẛᵴᶊʂȿſ"] = "s",
    ["ŚṤŜŠṦṠŞṢṨȘＳẞ"] = "S",
    ["ťṫţṭțṱṯŧⱦƭʈｔẗᵵƫȶ"] = "t",
    ["ŤṪŢṬȚṰṮŦȾƬƮＴᴛ"] = "T",
    ["úùŭûǔůüǘǜǚǖűũṹųūṻủȕȗưứừữửựụṳṷṵʉᶙ"] = "u",
    ["ÚÙŬÛǓŮÜǗǛǙǕŰŨṸŲŪṺỦȔȖƯỨỪỮỬỰỤṲṶṴɄＵ"] = "U",
    ["ṽṿʋｖⱱⱴᴠᶌ"] = "v",
    ["ṼṾƲＶ"] = "V",
    ["ẃẁŵẅẇẉⱳｗẘ"] = "w",
    ["ẂẀŴẄẆẈⱲＷ"] = "W",
    ["ẍẋｘᶍ"] = "x",
    ["ẌẊＸ"] = "X",
    ["ýỳŷÿỹẏȳỷỵɏƴｙẙ"] = "y",
    ["ÝỲŶŸỸẎȲỶỴɎƳＹʏ"] = "Y",
    ["źẑžżẓẕƶȥⱬｚᵶᶎʐʑɀᴢ"] = "z",
    ["ŹẐŽŻẒẔƵȤⱫＺ"] = "Z",
}

local function replaceAccents(str)
    local normalizedString = ''
    for _, char in utf8.codes(str) do -- convert the strign into constituent utf8 bytes
        local replaced = false
        for accentChars, replacementChar in pairs(letters) do
            for _, accent in utf8.codes(accentChars) do
                if char == accent then
                    normalizedString = normalizedString .. replacementChar
                    replaced = true
                    break
                end
            end
            if replaced then
                break
            end
        end
        if not replaced then -- no replacementChar necessary, append the character as-is
            normalizedString = normalizedString .. utf8.char(char)
        end
    end
    return normalizedString
end

-- NOTE: this is a lua implementation of Sam Keddy's (skeddles') slugify which is used by Lospec
-- https://github.com/skeddles/sluggify
local function slugify(text)
    local slug = text
        :gsub("[\\/ ]+", "-") -- replace slashes and spaces with dashes "-"
        slug = replaceAccents(slug) -- replace all accent characters w/ their 'normal' equiv.
        :gsub("[^A-Za-z0-9%-]+", "") -- remove all non-alphanumeric characters
        :gsub("[%-]+", "-") -- replace multiple consecutive dashes with a single dash
        :gsub("^%-+", "") -- remove leading dashes
        :gsub("%-+$", "") -- remove trailing dashes
        :lower()
    return slug
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
        " - (C)2024 J. Riggles - MIT LICENSE",
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

local function getJSONData(url)
    local command = 'curl -s "' .. url .. '"'
    if getOS == "Windows" then
        -- fetch JSON data via curl using io.popen
        local handle = assert(io.popen(command), "curl error - could not connect to " .. url)
        local result = handle:read("*a")
        assert(handle:close(), "curl error - could not close connection")
        return result
    else -- assume a non-Windows OS, use os.execute instead of io.popen
        local tempFilePath = app.fs.tempPath .. "palettedata.tmp"
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

local function main()
    -- check if there's an active sprite (can't run this without a sprite, but just in case...)
    if not app.activeSprite then
        app.alert {
            title = "No Active Sprite!",
            text = "Please open a sprite or create a new one"
        }
        return -- bail
    end

    local namePromptDlg = Dialog("Import Palette from Lospec")
        :label { text = "Palette name:"}
        :entry { id = "rawName", focus = true}
        :separator()
        :label { text = "Palette names are case-insenstitive and may only"}
        :newrow()
        :label { text = "contain the following characters:" }
        :newrow()
        :label { text = "A-Z, a-z, 0-9, space, hyphen/dash (-), brackets ([])" }
        :button { id = "ok", text = "OK" }
        :button { id = "cancel", text = "Cancel" }
        :show()

    if namePromptDlg.data.ok then
        -- get the palette name from the user, sanitized to remove invalid characters
        local rawName = namePromptDlg.data.rawName
        local paletteName = slugify(rawName)

        if paletteName == nil or paletteName == "" then
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
        local url = "https://lospec.com/palette-list/" .. paletteName .. ".json"

        -- fetch JSON data from Lospec
        local data = getJSONData(url)

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
            palettePreviewDlg:entry {  -- NOTE: specifying palettePreviewDlg is necessary here
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
                :button { id="saveAndUse", text="Save and use now", focus = true}
                :button { id = "use", text = "Use now, don't save" }
                :newrow()
                :button { id = "save", text = "Save as preset" }
                :button { id = "cancel", text = "Cancel" }
                :separator()
                :label { text = "Palette save format:" }
                :radio { id = "gpl", text = "*.gpl (default)", selected = true }
                :radio { id = "aseprite", text = "*.aseprite" }
                :show()

            local paletteExtension
            if palettePreviewDlg.data.gpl then
                paletteExtension = ".gpl"
            elseif palettePreviewDlg.data.aseprite then
                paletteExtension = ".aseprite"
            end

            local ps = app.fs.pathSeparator
            local savePath = app.fs.userConfigPath .. "palettes" .. ps .. name .. paletteExtension

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
    end
end

-- Aseprite plugin API stuff...
---@diagnostic disable-next-line: lowercase-global
function init(plugin) -- initialize extension
    -- if plugin.preferences.count == nil then
    --     plugin.preferences.count = 0
    -- end

    plugin:newCommand {
        id = "importFromLospec",
        title = "Import Palette from Lospec",
        group = "palette_generation",
        onclick = main -- run main function
    }
end

---@diagnostic disable-next-line: lowercase-global
function exit(plugin)
    -- no cleanup
    return nil
end
