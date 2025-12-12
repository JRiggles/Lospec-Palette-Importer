-- 'lpihelper' middleware is used to trigger the 'importFromLospec' command, since extensions can't
-- be run from the CLI, but scripts can

-- stop complaining about unknown Aseprite API methods
---@diagnostic disable: undefined-global

if app.params["fromURI"] then
    if not app.sprite then -- open a new file if necessary
        app.command.newFile { ui = false, width = 160, height = 144 }
    end
    app.command.importFromLospec() -- run the palette importer
end
