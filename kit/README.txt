Divine Prisma: prismatic cursors for Guild Wars 2
===============================================

An original cursor pack by the DIVINE guild, drawn in a prismatic, metallic
style like the game's own cursors. 21 drawings in 7 colours, each in a plain
and a glow version, in 5 sizes.
Preview of every colour: previa-todas-as-cores.png

Some file names are in Portuguese: "Instalar" = install, "Desinstalar" =
uninstall, "previa" = preview, "brilho" = glow, "manual (sem script)" =
manual (no script). On a non-Portuguese Windows the installer window is in
English.


INSTALL IN 3 STEPS
------------------
1. You need Nexus (raidcore.gg/Nexus) and the "Custom Cursors" addon
   (in game: Ctrl+O > Addons > Library > Custom Cursors > Install).
2. Extract the whole ZIP (right-click > Extract All) and close the game.
3. Double-click "Instalar.bat". In the window, pick a colour and a size and
   click Install.

The window finds the game folder by itself and shows whether Nexus and
Custom Cursors are there. To switch colour or size, open Instalar.bat again.
You don't need to start the game first: if the addon has no settings yet,
the installer creates them.


WHICH SIZE?
-----------
48 px is the default. On a large screen or with a bigger game UI, try 64 px.
96 and 128 px are for a really big cursor. The window shows the preview at
actual size.

The game has three "Cursor contrast" modes (Options > General >
Accessibility): Off, Low and High. Each mode uses different cursors (no halo,
halo, ring). The installer replaces all three and adjusts the size so the
cursor looks the same on screen in any mode.
In High mode only the default arrow is replaced for now (see NOTES).


WHAT THE INSTALLER CHANGES
--------------------------
- Only the game cursors we know about: arrow, talk, interact, hands, revive,
  crosshair, inspect (magnifier), salvage kit and resize.
- The enemy arrow stays red. The ally arrow (the one over friendly NPCs)
  uses your colour. If you'd rather keep the game's green, turn on "Ally
  arrow in green" in the window.
- Other cursors and other addon options are left alone.
- It backs up settings.json before changing it
  (settings.json.backup-divine-prisma-...).

The game doesn't use some of the drawings: double arrow, hammer, rotate,
target, area target and pointing hand. They go into the pack folder as
extras; to use one, pick it in the Custom Cursors menu in game.
There is no hammer cursor in the game. Salvage kits (infinite ones too) use
the arrow with green or red circular arrows, and the installer already
replaces that one.


UNINSTALL
---------
Open Instalar.bat and click Uninstall, or double-click "Desinstalar.bat".
The Divine Prisma cursors go back to the game default and the pack folder is
deleted. Other cursors don't change.


WHERE THINGS ARE
----------------
Custom Cursors lives INSIDE your game folder (the one with Gw2-64.exe), and
that folder differs from PC to PC. For example: C:\Program Files\Guild Wars 2,
D:\Games\Guild Wars 2, or on Steam ...\steamapps\common\Guild Wars 2.

  <game folder>\addons\CustomCursors\settings.json         settings
  <game folder>\addons\CustomCursors\cursors\divine-prisma\  this pack

The pack used to be called gw2-facetado. If that old folder is there, the
installer replaces it with the new one and fixes settings.json by itself.

If the window can't find the game folder, click "Browse...". Not sure where
it is? Right-click the Guild Wars 2 shortcut > "Open file location". On
Steam: right-click the game > Manage > Browse local files.


IS IT SAFE?
-----------
- There is no .exe. The .bat files run the PowerShell scripts in
  _arquivos\instalador. You can open them in Notepad and read them first.
- The scripts don't use the internet, don't ask for admin rights, and only
  touch:
    addons\CustomCursors\settings.json   (backed up)
    addons\CustomCursors\cursors\divine-prisma\
- The .bat uses "-ExecutionPolicy Bypass" because Windows blocks scripts
  downloaded from the internet. It only applies to this script, this once.
- Compare the ZIP's SHA-256 with the one on the download page:
    certutil -hashfile divine-prisma-kit.zip SHA256


NO SCRIPT (MANUAL INSTALL)
--------------------------
1. Copy _arquivos\divine-prisma into <game folder>\addons\CustomCursors\cursors\
2. Copy _arquivos\manual (sem script)\<Colour>\<size> px\settings.json into
   <game folder>\addons\CustomCursors\
   WARNING: this replaces the whole settings.json. If you already had
   cursors set up in the addon, keep a copy of yours first.
You can also pick each cursor in the Custom Cursors menu in game. The click
point of every file is in _arquivos\divine-prisma\hotspots.json.


NOTES
-----
- High cursor contrast: in that mode the game uses another set of cursors,
  and so far only the default arrow has been identified. The others show the
  game default. If you play in High mode, please say so on the project page.
- Custom Cursors may log a warning when not every game cursor has a file set
  (addon issue #4). It's only a warning.
- Addons are third-party. ArenaNet doesn't review or approve any of them,
  and you use them at your own risk. This pack only changes how the cursor
  looks.
- Not affiliated with ArenaNet, NCSOFT or the author of Custom Cursors.


PROJECT AND LICENSE
-------------------
Page, source code and issues: https://github.com/divinegw/divine-prisma
Artwork: CC BY-NC 4.0 (share and modify with credit, no commercial use).
Scripts: MIT.
