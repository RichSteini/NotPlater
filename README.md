# NotPlater Addon for TBC 2.4.3

![NotPlater addon demo (non targeted vs. targeted enemy)](/images/demo.png)

Feature rich nameplate addon for TBC 2.4.3 that was designed based on the modern Plater addon. The main purpose is to provide extensive threat information on nameplates with fully configurable options. The core features include:
- Threat display with dps / healer and tank mode 
    - Nameplate Color Coding (including an option for class colors)
    - Threat Status Bar/Text
    - Threat Differential Text 
    - Threat Number Text
- Fully customizable look, every bar (including borders) / text is movable / scalable
- Textual health font for enemy healthbar in different configurations (percent, min / max, both)
- Textual casting fonts for enemy castbar in different configurations (spellname, time remaining, time taken, both)\
- Highly adjustable Target Options
    - Border Indicator and Highlight like in Plater
    - Non-Target Shading
    - Target Overlay
    - Mouseover Highlight
    - Target-Target Text
- Stacking Options
- Simulator Frame
- Profiles

If you find any bugs feel free to message me (Hardc0re#6291 on discord) or report an issue.

## Threat Display Feature Description

![Threat display features](/images/demo4.png)

The picture above shows all the threat features that are available. They can be independently enabled / disabled. There exist two different modes, namely dps / healer and tank mode. For each mode the colors of the fonts and bars can be set individually.
- Threat Color Coding\
  Three different threat colors of the healthbar based on the colors of Plater, but can be changed settings.
- Threat Status Bar/Text\
  Shows your % on threat based on the highest person on threat within your group as a status bar and/or text. There are also color options for 100%, above 90% and below 90% for both status bar and text.
- Threat Differential Text\
  This shows the threat differential between you and second on threat if you are first on threat. If you are not first on threat then it shows the threat differential between the first on threat and you. Colors can be changed for each mode, default colors have the following intend, respective to the meaning of the modes: Green - save zone, Red - danger, Orange - close to danger. The font is fully customizable.
- Threat Number Text\
  This shows the number you are on threat. There are three different colors which display, depending on the mode with respective colors: First on threat, above 80% on threat and below 80% on threat. The font is fully customizable.

## NotPlater Simulator Frame

![NotPlater Simulator](/images/notplater_simulator_frame.gif)

This frame simulates a nameplate and is meant to ease the process of configuring, so you don't have to look for proper test scenarios. It also simulates a threat scenario of a group of 10 people internally, which is shown when you hover over the simulated frame. The simulator is moveable on the outer region and you can target/untarget the simulated frame by clicking on it.

## Settings (/np or /notplater or Click on the Minimap Button)

![Settings](/images/demo_settings.png)

The image above shows the settings that are available for the addon. You can either access them over the minimap button or with the slash commands /np or /notplater. All features that have been described are adjustable in the settings dialog.

## Addon folder structure

Rename the downloaded folder to "NotPlater" (remove "-versionnumber" from the folder name) and put the folder in:\
..\Interface\AddOns\
..\Interface\AddOns\NotPlater

## Acknowledgements

- As already mentioned, the design is inspired by the Plater addon.