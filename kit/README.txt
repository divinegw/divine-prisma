gw2-facetado — faceted cursors for Guild Wars 2
===============================================

An original cursor pack drawn in the game's faceted, metallic style.
21 drawings, 7 colours, plain and glow versions, 5 sizes.
Preview of every colour: previa-todas-as-cores.png

Portuguese names: "Instalar" = install, "Desinstalar" = uninstall,
"previa" = preview, "brilho" = glow, "manual (sem script)" = manual (no script).
The installer window is in English on non-Portuguese Windows.


INSTALL IN 3 STEPS
------------------
1. You need Nexus (raidcore.gg/Nexus) and the "Custom Cursors" addon
   (in game: Ctrl+O > Addons > Library > Custom Cursors > Install).
2. Extract the whole ZIP (right-click > Extract All) and close the game.
3. Double-click "Instalar.bat". In the window, pick a colour and a size and
   click Install.

The window finds the game folder on its own and shows whether Nexus and
Custom Cursors are there. To switch colour or size, open Instalar.bat again.
No need to start the game first: if the addon has no settings yet, the
installer creates them.


WHICH SIZE?
-----------
48 px is the default. On large screens or with a larger game UI, try 64 px;
96 and 128 px are for a really big cursor. The window shows an actual-size
preview.

The game has three "Cursor contrast" modes (Options > General >
Accessibility): Off, Low and High. Each mode uses different cursors (no halo,
halo, ring). The installer covers all three and adjusts sizes so the cursor
looks the same size in any mode. In High mode only the default arrow is
replaced for now (see NOTES).


WHAT THE INSTALLER CHANGES
--------------------------
- Only the known game cursors: arrow, talk, interact, hands, revive,
  crosshair, inspect (magnifier), salvage kit and resize.
- The enemy arrow stays red. The ally arrow (shown over friendly NPCs) uses
  the chosen colour; tick "Ally arrow in green" in the window to keep the
  game's green.
- Every other cursor and addon option is left alone.
- settings.json is backed up first (settings.json.backup-gw2-facetado-...).

Drawings the game does not use (double arrow, hammer, rotate, target, area
target, pointing hand) are installed as extras. The game has no hammer
cursor: salvage kits (infinite ones too) use the arrow with green/red circular
arrows, which the installer already replaces. To use an extra, pick it in the
Custom Cursors menu in game.


UNINSTALL
---------
Open Instalar.bat and click Uninstall, or double-click "Desinstalar.bat".
The gw2-facetado cursors go back to the game default and the pack folder is
deleted. Other cursors stay as they are.


WHERE THINGS ARE
----------------
Custom Cursors lives INSIDE your game folder (the one with Gw2-64.exe), which
differs per PC (e.g. C:\Program Files\Guild Wars 2, D:\Games\Guild Wars 2, or
on Steam ...\steamapps\common\Guild Wars 2).

  <game folder>\addons\CustomCursors\settings.json         settings
  <game folder>\addons\CustomCursors\cursors\gw2-facetado\  this pack

If the window cannot find it, click "Browse...". Not sure where it is?
Right-click the Guild Wars 2 shortcut > "Open file location". On Steam:
right-click the game > Manage > Browse local files.


IS IT SAFE?
-----------
- There is no .exe. The .bat files run the PowerShell scripts in
  _arquivos\instalador; open them in Notepad and read them first.
- The scripts use no internet, need no admin rights, and only touch:
    addons\CustomCursors\settings.json   (backed up)
    addons\CustomCursors\cursors\gw2-facetado\
- The .bat uses "-ExecutionPolicy Bypass" because Windows blocks scripts
  downloaded from the internet. It applies only to this script, this run.
- Check the ZIP's SHA-256 against the one on the download page:
    certutil -hashfile gw2-facetado-kit.zip SHA256


NO SCRIPT (MANUAL INSTALL)
--------------------------
1. Copy _arquivos\gw2-facetado into <game folder>\addons\CustomCursors\cursors\
2. Copy _arquivos\manual (sem script)\<Colour>\<size> px\settings.json into
   <game folder>\addons\CustomCursors\
   WARNING: this replaces the whole settings.json. If you already had
   cursors set up in the addon, keep a copy of yours first.
Or pick each cursor in the Custom Cursors menu in game; click points for
every file are in _arquivos\gw2-facetado\hotspots.json.


NOTES
-----
- High cursor contrast: the game uses another set of cursors in that mode and
  only the default arrow has been identified so far. The others show the game
  default. If you play in High mode, please report it on the project page.
- Custom Cursors may log a warning when not every game cursor has a file set
  (addon issue #4). It is only a warning.
- Addons are third-party: ArenaNet does not review or approve any of them, and
  you use them at your own risk. This pack only changes how the cursor looks.
- Not affiliated with ArenaNet, NCSOFT or the author of Custom Cursors.


PROJECT AND LICENSE
-------------------
Page, source code and issues: https://github.com/divinegw/gw2-facetado
Artwork: CC BY-NC 4.0 (share and modify with credit, no commercial use).
Scripts: MIT.
