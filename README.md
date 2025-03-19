# Lospec Palette Importer

![LPI icon](./screenshots/LPI%20icon.png)

#### An Aseprite extension
*current release: [v1.4.0](https://sudo-whoami.itch.io/lospec-palette-importer)*

## Latest Changes
- Version 1.4.0 brings some quality-of-life improvements to the extension's UI/UX. Preferences can now be accessed by clicking the "Preferences..." button on the import dialog.

>[!IMPORTANT]
>The minimum required Aseprite version is now 1.3.7 (API version 28)

##
This [Aseprite](https://aseprite.org) extension allows you to use and save color palettes from [Lospec](https://lospec.com). Simply enter the name of the Lospec palette you want to import.

### Import
![import dialog](./screenshots/import%20dialog.png)

### Palette Preview
![preview dialog](./screenshots/palette%20preview%20dialog.png)

### Preferences
![preferences dialog](./screenshots/prefs%20dialog.png)

## Requirements

This extension has been tested on both Windows and Mac OS (specifically, Windows 11 and Mac OS Sonoma 14.3.1)

It is intended to run on Aseprite version 1.3.7 or later and requires API version 28 (as long as you have the latest version of Aseprite, you should be fine!)

## Permissions
When you run this plugin for the first time, you'll be aked to grant some permissions. This extension uses `curl` under the hood to get data from Lospec and will need your permission to execute that command. Addtionally, this extension will need your permission to write files if you intend to save any imported palettes.

When prompted, select the "Give full trust to this script" checkbox and then click "Give Script Full Access" (you'll only need to do this once)

![security dialog](./screenshots/security%20dialog.png)

## Features & Usage
Once you've imported the palette you want, you can...
- Save it as a preset and use it immediately
- Use it without saving
- Save it as a preset without overriding the currently selected palette

Palettes are saved in GIMP palette format (*.gpl) by default since this option allows for other info from Lospec to be included with the palette, such as the author's name and the Lospec palette list URL

Palettes can also be saved in *.aseprite format, but this option won't include any of the extra data from Lospec

To use this plugin, just open the "Options" menu above the color palette and then select "Import Palette from Lospec"

![palette menu](./screenshots/palette%20menu%20selection.png)

## Installation
You can download this extension from [itch.io](https://sudo-whoami.itch.io/lospec-palette-importer) as a "pay what you want" tool

If you find this extension useful, please consider donating via itch.io to support further development! &hearts;
