gw2-facetado — faceted cursors for Guild Wars 2
===============================================

An original cursor pack drawn in the game's faceted, metallic style.
21 drawings, 7 colours, plain and glow versions, 5 sizes.
Preview of every colour: previa-todas-as-cores.png

Colour folder names (Portuguese): Roxo = purple, Ciano = cyan,
Dourado = gold, Prata = silver, Rosa = pink, Verde = green, Vermelho = red.
"brilho" = glow (white outline). "Instalar" = install, "Desinstalar" =
uninstall, "previa" = preview, "manual (sem script)" = manual (no script).


WHAT'S INSIDE
-------------
  Ciano\ Dourado\ Prata\ Rosa\ Roxo\ Verde\ Vermelho\   one folder per colour
      previa-<colour>.png           that colour's drawings and the 5 sizes
      Instalar <Colour> 32 px.bat   one installer per size
      ...
      Instalar <Colour> 128 px.bat
      Desinstalar.bat
      manual (sem script)\          ready-made settings.json, one per size
  Desinstalar.bat                   the same uninstaller, at the top level
  _arquivos\                        image pack and scripts (no need to open)


BEFORE YOU INSTALL
------------------
1. Install Nexus (raidcore.gg/Nexus).
2. From the Nexus addon library, install "Custom Cursors" (jordanrye).
3. Start the game once and close it. This creates the addon's settings file.


INSTALL
-------
1. Extract the whole ZIP anywhere.
2. Open the folder of the colour you want and check its preview.
3. With the game CLOSED, double-click "Instalar <Colour> <size> px.bat".
4. Confirm the game folder and confirm the install.

Which size? 48 px is the default. On large screens or with a larger game UI,
try 64 px; 96 and 128 px are for a really big cursor. To switch colour or
size, just run another "Instalar".

The installer:
- changes only the known game cursors (arrow, talk, interact, hands, revive,
  crosshair, zoom, recycle, resize) in both of the game's cursor contrast
  modes (normal and high, with halo); the enemy arrow stays red and the
  ally arrow green;
- leaves every other cursor and addon option alone;
- backs up settings.json first (settings.json.backup-gw2-facetado-...).

Drawings the game doesn't use by default (double arrow, hammer, rotate,
target, area target, pointing hand) are installed too and can be picked from
the Custom Cursors menu in game.


UNINSTALL
---------
With the game closed, double-click "Desinstalar.bat" (top level or any colour
folder: it's the same). The gw2-facetado cursors go back to the game default
and, if you want, the pack folder is deleted.


WHERE THINGS ARE
----------------
Custom Cursors lives INSIDE your game folder, which differs per PC
(e.g. C:\Program Files\Guild Wars 2, D:\Games\Guild Wars 2, or on Steam
...\steamapps\common\Guild Wars 2). It is the folder with Gw2-64.exe.

  <game folder>\addons\CustomCursors\settings.json         settings
  <game folder>\addons\CustomCursors\cursors\gw2-facetado\  this pack

The installer finds it on its own (game shortcuts, installed-programs list,
common locations, Steam) and always asks first. If nothing is found, it opens
a folder picker.

Not sure where it is? Right-click the Guild Wars 2 shortcut > "Open file
location". On Steam: right-click the game > Manage > Browse local files.
Tip: extract this ZIP inside the game folder and it is found right away.

Paths in settings.json are relative to the game folder, so they work on any
PC, wherever the game is installed.


IS IT SAFE?
-----------
- There is no .exe. Each .bat is a single line that runs the scripts in
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
2. Copy <Colour>\manual (sem script)\<size> px\settings.json into
   <game folder>\addons\CustomCursors\
   WARNING: this replaces the whole settings.json. If you already had
   cursors set up in the addon, keep a copy of yours first.
Or pick each cursor in the Custom Cursors menu in game; click points for
every file are in _arquivos\gw2-facetado\hotspots.json.


NOTES
-----
- Custom Cursors may show a warning when not every game cursor has a file set
  (addon issue #4). It is only a warning.
- Addons are third-party: ArenaNet does not review or approve any of them, and
  you use them at your own risk. This pack only changes how the cursor looks.
- Not affiliated with ArenaNet, NCSOFT or the author of Custom Cursors.


PROJECT AND LICENSE
-------------------
Page, source code and issues: https://github.com/divinegw/gw2-facetado
Artwork: CC BY-NC 4.0 (share and modify with credit, no commercial use).
Scripts: MIT.
