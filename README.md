# Lospec Palette Importer
### An Aseprite extension by [sudo_whoami](https://sudo-whoami.itch.io)

![LPI icon](./screenshots/LPI%20icon.png)

This [Aseprite](https://aseprite.org) extension allows you to use and save color palettes from [Lospec](https://lospec.com). Simply enter the name of the Lospec palette you want to import.

*current release: [v1.4.2](https://sudo-whoami.itch.io/lospec-palette-importer)*

## Latest Changes
Version 1.4.2 comes hot on the heels of v1.4.1 to address an issue preventing the "Open In App..." feature from working for some Windows users

Version 1.4.1 fixes a few bugs somebody introduced in the last update 😅 and improves a few other things...
- Massive refactor to break up `main()` into many smaller functions to make my life easier
- Remove unused/unnecessary code from `getLospecData` function
- Fix issues with the "Save as preset" and "Save and use now" options not actually saving palettes
- Improve Lospec "Open In App..." behavior on Windows
- Remove a rogue `print` statement that somehow got left in the last build
- UI/UX improvements
    - Improved layout of the import dialog
    - Tweak preferences dialog for visual consistency
    - "OK" on the import dialog is now "Import" because that makes more sense
    - "Cancel" on the palette preview dialog is now "Back...", and clicking on it will return you to the import dialog. This way you can redo your search or "re-roll" your random palette (thanks to Lospec Discord user **@cptn.piranha** for the idea!)
    - Closing the warning dialog that shows up after entering an empty or malformed palette name will now return you to the import dialog instead of closing the extension altogether
    - Closing the dialog that shows up after searching for a palette that doesn't exist will now return you to the import dialog instead of closing the extension altogether
- Update how metadata for GPL palettes is formatted in order to deal with an Aseprite issue where palette info text won't show up
    - **NOTE**: I'm not sure *what* is causing this bug, but I've tested the new format and any newly imported palettes shouldn't be affected. The relevant GitHub issue is [#5014](https://github.com/aseprite/aseprite/issues/5104)

>[!IMPORTANT]
>The minimum required Aseprite version is now 1.3.7 (API version 28)

##

### Import
![import dialog](./screenshots/import%20dialog.png)

### Palette Preview
![preview dialog](./screenshots/palette%20preview%20dialog.png)

### Preferences
![preferences dialog](./screenshots/prefs%20dialog.png)

## Requirements

This extension has been tested on both Windows and Mac OS (specifically, Windows 11 and Mac OS Sequoia 15.3.2)

It is intended to run on Aseprite version 1.3.7 or later and requires API version 28 (as long as you have the latest version of Aseprite, you should be fine!)

## Permissions
When you run this plugin for the first time, you'll be aked to grant some permissions. This extension uses `curl` under the hood to get data from Lospec and will need your permission to execute that command. Addtionally, this extension will need your permission to write files if you intend to save any imported palettes.

When prompted, select the "Give full trust to this script" checkbox and then click "Give Script Full Access" (you'll only need to do this once)

![security dialog](./screenshots/security%20dialog.png)

## Features & Usage
If you know the name of the palette you want to import, simply enter it and click the **Import** button. If you're looking for inspiration, you can also check out the current **Daily** palette or a **Random** palette!

Once you've imported the palette you want, you can...
- Save it as a preset and use it immediately
- Use it without saving
- Save it as a preset without overriding the currently selected palette

Palettes are saved in GIMP palette format (*.gpl) by default since this option allows for other info from Lospec to be included with the palette, such as the author's name and the Lospec palette list URL

Palettes can also be saved in *.aseprite format, but this option won't include any of the extra data from Lospec

To use this plugin, just open the "Options" menu above the color palette and then select "Import Palette from Lospec"

>[!TIP]
>If a palette you've just imported doesn't show up in the palette list immediately, just click the refresh button in the upper-right corner of the list

![palette menu](./screenshots/palette%20menu%20selection.png)

## Installation
You can download this extension from [itch.io](https://sudo-whoami.itch.io/lospec-palette-importer) as a "pay what you want" tool

If you find this extension useful, please consider donating via itch.io to support further development! &hearts;
