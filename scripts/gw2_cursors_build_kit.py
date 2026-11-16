r"""Monta o kit de lançamento do gw2-facetado.

Saída em <dist>:
  gw2-facetado-kit\          pasta do kit (instalador Nexus/Custom Cursors)
  gw2-facetado-kit.zip       o mesmo, zipado
  gw2-facetado-cur.zip       os .cur por cor (YoloMouse e afins), se existirem
  SHA256.txt                 hashes dos ZIPs

uso: python gw2_cursors_build_kit.py <pasta_do_pacote_png> <pasta_kit_fonte> <dist>
"""
import hashlib, os, shutil, sys, zipfile

PACK, SRC, DIST = sys.argv[1:4]
CORES = [("roxo", "Roxo"), ("ciano", "Ciano"), ("dourado", "Dourado"), ("prata", "Prata"),
         ("rosa", "Rosa"), ("verde", "Verde"), ("vermelho", "Vermelho")]
KIT = os.path.join(DIST, "gw2-facetado-kit")


def write(path, text, enc):
    with open(path, "w", encoding=enc, newline="\r\n") as f:
        f.write(text)


if os.path.isdir(KIT):
    shutil.rmtree(KIT)
os.makedirs(os.path.join(KIT, "_instalador"))

# pacote PNG (sem os backups e arquivos soltos que não sejam do pacote)
shutil.copytree(PACK, os.path.join(KIT, "gw2-facetado"))

# scripts: PowerShell 5.1 precisa de BOM para ler acentos em UTF-8
for name in os.listdir(os.path.join(SRC, "_instalador")):
    text = open(os.path.join(SRC, "_instalador", name), encoding="utf-8-sig").read()
    enc = "utf-8-sig" if name.endswith(".ps1") else "utf-8"
    write(os.path.join(KIT, "_instalador", name), text, enc)
for name in ("LEIA-ME.txt", "README.txt", "LICENSE.txt"):
    write(os.path.join(KIT, name), open(os.path.join(SRC, name), encoding="utf-8-sig").read(), "utf-8-sig")

# settings.json pronto por cor (instalação manual, no estilo dos packs do Discord do Raidcore).
# Substitui o settings.json inteiro: é a alternativa para quem não quer rodar script.
import json
MANUAL_SIZE = 48
PACK_REL = "addons/CustomCursors/cursors/gw2-facetado"
hot = json.load(open(os.path.join(PACK, "hotspots.json"), encoding="utf-8"))
mapa = json.load(open(os.path.join(SRC, "_instalador", "mapa.json"), encoding="utf-8"))["cursores"]
GENERAL = {"enable_combat_cursor": False, "enable_hotspot_preview": False, "enable_nexus_cursor": False,
           "link_width_height_inputs": True, "toggle_debug_window": False}
EMPTY = {"file_format": 0, "file_path": "", "height": 0, "hotspot_x": 0, "hotspot_y": 0, "width": 0}
for cor, nome in CORES:
    cursors = []
    for m in mapa:
        variante = cor + m["variante"][3:] if m["variante"].startswith("cor") else m["variante"]
        rel = f'{m["tipo"]}/gw2-{m["tipo"]}-{variante}-{MANUAL_SIZE}.png'
        hx, hy = hot[rel]["hotspot"]
        cursors.append({"cursor_id": m["id"], "file_format": 1, "file_path": f"{PACK_REL}/{rel}",
                        "height": MANUAL_SIZE, "hotspot_x": hx, "hotspot_y": hy, "width": MANUAL_SIZE})
    cfg = {"cursors": sorted(cursors, key=lambda c: c["cursor_id"]), "general": GENERAL,
           "hidden_cursors": [], "special_cursors": [dict(cursor_id=i, **EMPTY) for i in (10, 11)]}
    d = os.path.join(KIT, "manual", nome)
    os.makedirs(d, exist_ok=True)
    with open(os.path.join(d, "settings.json"), "w", encoding="utf-8", newline="\n") as f:
        json.dump(cfg, f, indent="\t", ensure_ascii=False)

PS = 'powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0_instalador\\{}" {}'
for cor, nome in CORES:
    write(os.path.join(KIT, f"Instalar - {nome}.bat"),
          f"@echo off\n{PS.format('instalar.ps1', '-Cor ' + cor)}\npause\n", "ascii")
write(os.path.join(KIT, "Desinstalar.bat"), f"@echo off\n{PS.format('desinstalar.ps1', '')}\npause\n", "ascii")


def zipdir(folder, zpath, root_name):
    if os.path.exists(zpath):
        os.remove(zpath)
    with zipfile.ZipFile(zpath, "w", zipfile.ZIP_DEFLATED, compresslevel=9) as z:
        for base, _, files in os.walk(folder):
            for fn in sorted(files):
                full = os.path.join(base, fn)
                z.write(full, os.path.join(root_name, os.path.relpath(full, folder)))


CUR_README = """gw2-facetado — cursores .cur / .cur cursors
===========================================

Uma pasta por cor. Cada .cur traz 5 tamanhos (32 a 128 px), cada um com o seu
ponto de clique; o programa escolhe o tamanho mais próximo. "-brilho" = versão
com borda branca. Para o YoloMouse: copie a pasta da cor e escolha cada cursor
no jogo (Ctrl+Alt+C). Ainda não testado dentro do YoloMouse.

One folder per colour (roxo purple, ciano cyan, dourado gold, prata silver,
rosa pink, verde green, vermelho red). Each .cur holds 5 sizes (32-128 px)
with their own click point. "-brilho" = glow (white outline). For YoloMouse:
copy the colour folder and pick each cursor in game (Ctrl+Alt+C). Not yet
tested inside YoloMouse.

https://github.com/divinegw/gw2-facetado
Desenhos / artwork: CC BY-NC 4.0 — veja / see LICENSE.txt
"""

zips = [os.path.join(DIST, "gw2-facetado-kit.zip")]
zipdir(KIT, zips[0], "gw2-facetado-kit")
cur = os.path.join(DIST, "gw2-facetado-cur")
if os.path.isdir(cur):
    write(os.path.join(cur, "LICENSE.txt"), open(os.path.join(SRC, "LICENSE.txt"), encoding="utf-8-sig").read(), "utf-8-sig")
    write(os.path.join(cur, "LEIA-ME.txt"), CUR_README, "utf-8-sig")
    zips.append(os.path.join(DIST, "gw2-facetado-cur.zip"))
    zipdir(cur, zips[1], "gw2-facetado-cur")

lines = []
for z in zips:
    h = hashlib.sha256(open(z, "rb").read()).hexdigest().upper()
    lines.append(f"{h}  {os.path.basename(z)}")
    print(f"{os.path.basename(z)}: {os.path.getsize(z) / 2**20:.1f} MB  {h}")
write(os.path.join(DIST, "SHA256.txt"), "\n".join(lines) + "\n", "ascii")
