# NotPlater addon for TBC 2.4.3

![NotPlater addon demo (non targeted vs. targeted enemy)](/images/demo.png)

Feature rich nameplate addon for TBC 2.4.3 that was designed based on the modern Plater addon. The main purpose is to provide extensive threat information on nameplates with fully configurable options. The core features include:
- Threat display with dps / healer and tank mode 
    - Nameplate color coding in three adjustable different colors
    - Threat differential font 
    - Number on threat font
- Fully customizable look, every bar / text is movable / scalable
- Textual health font for enemy healthbar in different configurations (percent, min / max, both)
- Textual casting font for enemy castbar in different configurations (spellname, time remaining, time taken, both)\

If you find any bugs feel free to message me (Hardc0re#6291 on discord) or send me a pull request.

## Threat display feature description

![Threat display features](/images/demo4.png)

The picture above shows all the threat features that are available. They can be independently enabled / disabled. There exist two different modes, namely dps / healer and tank mode. For each mode the colors of the fonts and bars can be set individually.
- Threat color coding\
  Three different threat colors of the healthbar based on the colors of Plater, but can be changed settings.
- Threat differential\
  This shows the threat differential between you and second on threat if you are first on threat. If you are not first on threat then it shows the threat differential between the first on threat and you. Colors can be changed for each mode, default colors have the following intend, respective to the meaning of the modes: Green - save zone, Red - danger, Orange - close to danger. The font is fully customizable.
- Threat number\
  This shows the number you are on threat. There are three different colors which display, depending on the mode with respective colors: First on threat, upper 20% on threat and lower 80% on threat. The font is fully customizable.


## Settings (/np or /notplater)

![Settings](/images/demo_settings.png)

The image above shows the settings that are available for the addon. You can either access them over the Interface -> AddOns option or with the slash commands /np or /notplater. All features that have been described are adjustable in the settings dialog.


## Addon folder structure

Rename the downloaded folder to "NotPlater" (remove "-versionnumber" from the folder name) and put the folder in:\
..\Interface\AddOns\
..\Interface\AddOns\NotPlater


## Acknowledgements

- As already mentioned, the design is based on the Plater addon that some might know from retail WoW. 
- The addon itself is based on the Nameplates modifier addon for TBC 2.4.3 (not quite sure who actually made it).
