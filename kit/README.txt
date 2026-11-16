gw2-facetado — faceted cursors for Guild Wars 2
===============================================

An original cursor pack drawn in the game's faceted, metallic style.
21 drawings, 7 colours, plain and glow versions, 5 sizes.
Preview: gw2-facetado\_previa.png

Colour names in the file names (Portuguese): roxo = purple, ciano = cyan,
dourado = gold, prata = silver, rosa = pink, verde = green, vermelho = red.
"brilho" = glow (white outline).


BEFORE YOU INSTALL
------------------
1. Install Nexus (raidcore.gg/Nexus).
2. From the Nexus addon library, install "Custom Cursors" (jordanrye).
3. Start the game once and close it. This creates the addon's settings file.


INSTALL
-------
1. Extract the whole ZIP anywhere.
2. With the game CLOSED, double-click "Instalar - <Colour>.bat"
   (Instalar = Install).
3. Confirm the game folder, pick a size (Enter = 48) and confirm.

The installer:
- changes only the known game cursors (arrow, talk, interact, hands, revive,
  crosshair, zoom, recycle, resize) in both of the game's cursor contrast
  modes (normal and high, with halo); the enemy arrow stays red and the
  ally arrow green;
- leaves every other cursor and addon option alone;
- backs up settings.json first (settings.json.backup-gw2-facetado-...).

To switch colour or size, just run another "Instalar".
The other drawings (magnifier, hammer, crosshair, hands, etc.) are in
addons\CustomCursors\cursors\gw2-facetado and can be picked from the
Custom Cursors menu in game.


UNINSTALL
---------
With the game closed, double-click "Desinstalar.bat". The gw2-facetado cursors
go back to the game default and, if you want, the pack folder is deleted.


IS IT SAFE?
-----------
- There is no .exe. Each .bat is a single line that runs the scripts in the
  _instalador folder; open them in Notepad and read them first.
- The scripts use no internet, need no admin rights, and only touch:
    addons\CustomCursors\settings.json   (backed up)
    addons\CustomCursors\cursors\gw2-facetado\
- The .bat uses "-ExecutionPolicy Bypass" because Windows blocks scripts
  downloaded from the internet. It applies only to this script, this run.
- Check the ZIP's SHA-256 against the one on the download page:
    certutil -hashfile gw2-facetado-kit.zip SHA256

Rather not run any script? Manual install (48 px):
1. Copy the gw2-facetado folder into addons\CustomCursors\cursors\
2. Copy manual\<Colour>\settings.json into addons\CustomCursors\
   WARNING: this replaces the whole settings.json. If you already had
   cursors set up in the addon, keep a copy of yours first.
Or pick each cursor in the Custom Cursors menu in game; click points for
every file are in gw2-facetado\hotspots.json.


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
