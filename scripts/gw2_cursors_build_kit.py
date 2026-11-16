r"""Monta o kit de lançamento do gw2-facetado.

Saída em <dist>:
  gw2-facetado-kit\          pasta do kit (instalador Nexus/Custom Cursors)
    <Cor>\                   uma pasta por cor: prévia, um .bat por tamanho,
                             Desinstalar.bat e settings.json manuais por tamanho
    _arquivos\               pacote PNG e scripts do instalador
  gw2-facetado-kit.zip       o mesmo, zipado
  gw2-facetado-cur.zip       os .cur por cor (YoloMouse e afins), se existirem
  SHA256.txt                 hashes dos ZIPs

uso: python gw2_cursors_build_kit.py <pasta_do_pacote_png> <pasta_kit_fonte> <dist> [--so-previas]
"""
import hashlib, json, os, shutil, sys, zipfile
from PIL import Image, ImageDraw, ImageFont

PACK, SRC, DIST = sys.argv[1:4]
CORES = [("roxo", "Roxo"), ("ciano", "Ciano"), ("dourado", "Dourado"), ("prata", "Prata"),
         ("rosa", "Rosa"), ("verde", "Verde"), ("vermelho", "Vermelho")]
TAMANHOS = [32, 48, 64, 96, 128]
KIT = os.path.join(DIST, "gw2-facetado-kit")
ARQ = os.path.join(KIT, "_arquivos")
PACK_REL = "addons/CustomCursors/cursors/gw2-facetado"
TIPOS = sorted(d for d in os.listdir(PACK) if os.path.isdir(os.path.join(PACK, d)))


def write(path, text, enc):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", encoding=enc, newline="\r\n") as f:
        f.write(text)


# ---------------------------------------------------------------- prévia por cor
def fonte(tam, negrito=False):
    for nome in (("segoeuib.ttf", "arialbd.ttf") if negrito else ("segoeui.ttf", "arial.ttf")):
        try:
            return ImageFont.truetype(os.path.join(os.environ.get("WINDIR", r"C:\Windows"), "Fonts", nome), tam)
        except OSError:
            pass
    return ImageFont.load_default()


def cursor(tipo, variante, tam):
    return Image.open(os.path.join(PACK, tipo, f"gw2-{tipo}-{variante}-{tam}.png")).convert("RGBA")


def previa(cor, nome, destino):
    """Prévia de um pacote de cor: os 5 tamanhos e os 21 desenhos (normal e com brilho)."""
    W, M = 1240, 32
    ESCURO, CLARO, FUNDO = (52, 62, 76), (196, 186, 160), (30, 33, 38)
    TXT, SUB = (236, 236, 236), (160, 166, 174)
    f_tit, f_sec, f_txt, f_peq = fonte(34, True), fonte(20, True), fonte(16), fonte(13)
    col, cel = 7, (W - 2 * M - 24 - 2 * 12) // 14  # 7 colunas por painel, 2 painéis (+12 de borda cada)
    linhas = -(-len(TIPOS) // col)
    alt_tam = 128 + 64
    H = M + 80 + 40 + alt_tam * 2 + 30 + 40 + linhas * (cel + 22) + M + 30
    img = Image.new("RGB", (W, H), FUNDO)
    d = ImageDraw.Draw(img)
    y = M
    d.text((M, y), f"gw2-facetado · {nome}", font=f_tit, fill=TXT)
    d.text((M, y + 46), "21 desenhos · versão normal e com brilho · 5 tamanhos · para o Custom Cursors (Nexus)",
           font=f_txt, fill=SUB)
    y += 80 + 20

    # tamanhos reais, num painel escuro (normal) e num claro (brilho)
    d.text((M, y), "Tamanhos (em pixels reais)", font=f_sec, fill=TXT)
    y += 36
    # cada bloco ocupa a largura de dois cursores daquele tamanho; a sobra vira espaço igual entre eles
    blocos = [max(2 * t + 8, 110) for t in TAMANHOS]
    gap = (W - 2 * M - sum(blocos)) / (len(TAMANHOS) + 1)
    for i, (variante, fundo, cor_txt) in enumerate(((cor, ESCURO, TXT), (f"{cor}-brilho", CLARO, (40, 34, 24)))):
        y0 = y + i * alt_tam
        d.rectangle([M, y0, W - M, y0 + alt_tam - 8], fill=fundo)
        x0 = M + gap
        for t, b in zip(TAMANHOS, blocos):
            xi = x0 + (b - (2 * t + 8)) / 2
            for k, tipo in enumerate(("seta", "mao-aberta")):
                c = cursor(tipo, variante, t)
                img.paste(c, (int(xi + k * (t + 8)), y0 + 14 + (128 - t)), c)
            rot = f"{t} px" + (" · brilho" if i else "")
            d.text((x0 + (b - d.textlength(rot, font=f_txt)) / 2, y0 + alt_tam - 40), rot, font=f_txt, fill=cor_txt)
            x0 += b + gap
    y += alt_tam * 2 + 22

    # todos os desenhos em 64 px
    d.text((M, y), "Todos os desenhos (64 px) — à esquerda normal, à direita com brilho", font=f_sec, fill=TXT)
    y += 36
    pw = (W - 2 * M - 24) // 2
    for p, (variante, fundo, cor_txt) in enumerate(((cor, ESCURO, SUB), (f"{cor}-brilho", CLARO, (70, 62, 46)))):
        x0 = M + p * (pw + 24)
        cx_base = x0 + (pw - col * cel) // 2
        d.rectangle([x0, y, x0 + pw, y + linhas * (cel + 22) + 8], fill=fundo)
        for n, tipo in enumerate(TIPOS):
            cx, cy = cx_base + (n % col) * cel, y + 6 + (n // col) * (cel + 22)
            c = cursor(tipo, variante, 64)
            img.paste(c, (cx + (cel - 64) // 2, cy), c)
            w = d.textlength(tipo, font=f_peq)
            d.text((cx + (cel - w) / 2, cy + 66), tipo, font=f_peq, fill=cor_txt)
    y += linhas * (cel + 22) + 20
    d.text((M, y), "Inimigo continua vermelho e aliado verde em todas as cores. "
                   "github.com/divinegw/gw2-facetado", font=f_peq, fill=SUB)
    img.save(destino, optimize=True)


if "--so-previas" in sys.argv:
    os.makedirs(os.path.join(DIST, "previas"), exist_ok=True)
    for cor, nome in CORES:
        previa(cor, nome, os.path.join(DIST, "previas", f"previa-{cor}.png"))
    sys.exit()

# ---------------------------------------------------------------- kit
if os.path.isdir(KIT):
    shutil.rmtree(KIT)
shutil.copytree(PACK, os.path.join(ARQ, "gw2-facetado"))

# scripts: PowerShell 5.1 precisa de BOM para ler acentos em UTF-8
for name in os.listdir(os.path.join(SRC, "_instalador")):
    text = open(os.path.join(SRC, "_instalador", name), encoding="utf-8-sig").read()
    write(os.path.join(ARQ, "instalador", name), text, "utf-8-sig" if name.endswith(".ps1") else "utf-8")
for name in ("LEIA-ME.txt", "README.txt", "LICENSE.txt"):
    write(os.path.join(KIT, name), open(os.path.join(SRC, name), encoding="utf-8-sig").read(), "utf-8-sig")
shutil.copy(os.path.join(PACK, "_previa.png"), os.path.join(KIT, "previa-todas-as-cores.png"))

# settings.json pronto por cor e tamanho (instalação manual, no estilo dos packs do Discord do Raidcore).
# Substitui o settings.json inteiro: é a alternativa para quem não quer rodar script.
hot = json.load(open(os.path.join(PACK, "hotspots.json"), encoding="utf-8"))
mapa = json.load(open(os.path.join(SRC, "_instalador", "mapa.json"), encoding="utf-8"))["cursores"]
GENERAL = {"enable_combat_cursor": False, "enable_hotspot_preview": False, "enable_nexus_cursor": False,
           "link_width_height_inputs": True, "toggle_debug_window": False}
EMPTY = {"file_format": 0, "file_path": "", "height": 0, "hotspot_x": 0, "hotspot_y": 0, "width": 0}


def manual(cor, tam):
    cursors = []
    for m in mapa:
        variante = cor + m["variante"][3:] if m["variante"].startswith("cor") else m["variante"]
        rel = f'{m["tipo"]}/gw2-{m["tipo"]}-{variante}-{tam}.png'
        hx, hy = hot[rel]["hotspot"]
        cursors.append({"cursor_id": m["id"], "file_format": 1, "file_path": f"{PACK_REL}/{rel}",
                        "height": tam, "hotspot_x": hx, "hotspot_y": hy, "width": tam})
    return {"cursors": sorted(cursors, key=lambda c: c["cursor_id"]), "general": GENERAL,
            "hidden_cursors": [], "special_cursors": [dict(cursor_id=i, **EMPTY) for i in (10, 11)]}


# um .bat por tamanho; o caminho volta uma pasta (..) até _arquivos
PS = 'powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0{base}_arquivos\\instalador\\{script}" {args}'


def bat(path, base, script, args=""):
    write(path, f"@echo off\n{PS.format(base=base, script=script, args=args).rstrip()}\npause\n", "ascii")


for cor, nome in CORES:
    pasta = os.path.join(KIT, nome)
    os.makedirs(pasta)
    previa(cor, nome, os.path.join(pasta, f"previa-{cor}.png"))
    for t in TAMANHOS:
        bat(os.path.join(pasta, f"Instalar {nome} {t} px.bat"), "..\\", "instalar.ps1", f"-Cor {cor} -Tamanho {t}")
        d = os.path.join(pasta, "manual (sem script)", f"{t} px")
        os.makedirs(d)
        with open(os.path.join(d, "settings.json"), "w", encoding="utf-8", newline="\n") as f:
            json.dump(manual(cor, t), f, indent="\t", ensure_ascii=False)
    bat(os.path.join(pasta, "Desinstalar.bat"), "..\\", "desinstalar.ps1")
bat(os.path.join(KIT, "Desinstalar.bat"), "", "desinstalar.ps1")


# ---------------------------------------------------------------- ZIPs
def zipdir(folder, zpath, root_name):
    if os.path.exists(zpath):
        os.remove(zpath)
    with zipfile.ZipFile(zpath, "w", zipfile.ZIP_DEFLATED, compresslevel=9) as z:
        for base, _, files in os.walk(folder):
            for fn in sorted(files):
                full = os.path.join(base, fn)
                z.write(full, os.path.join(root_name, os.path.relpath(full, folder)))


CUR_README = r"""gw2-facetado — cursores .cur / .cur cursors
===========================================

Uma pasta por cor (Ciano, Dourado, Prata, Rosa, Roxo, Verde, Vermelho).
Dentro de cada uma:

  previa-<cor>.png      os desenhos daquela cor e os 5 tamanhos
  32 px\ ... 128 px\    os 42 cursores (21 desenhos, normal e "-brilho")
                        num tamanho só
  todos os tamanhos\    os mesmos 42, cada .cur com os 5 tamanhos dentro;
                        o programa escolhe o tamanho mais próximo

"-brilho" = versão com borda branca (como o cursor de alto contraste do jogo).
Cada .cur já traz o ponto de clique certo.

YoloMouse: não há instalador, porque o YoloMouse escolhe cada cursor dentro do
jogo. Copie a pasta do tamanho que quiser (ex.: Verde\48 px) para a pasta de
cursores do YoloMouse e, no jogo, aperte Ctrl+Alt+C sobre cada cursor para
escolher o desenho. Ainda não testado dentro do YoloMouse.

One folder per colour (roxo purple, ciano cyan, dourado gold, prata silver,
rosa pink, verde green, vermelho red), each with a preview, one subfolder per
size (32-128 px) and "todos os tamanhos" (all sizes in each .cur).
"-brilho" = glow (white outline). For YoloMouse: copy the size folder you want
into YoloMouse's cursor folder and press Ctrl+Alt+C in game over each cursor to
pick it. Not yet tested inside YoloMouse.

https://github.com/divinegw/gw2-facetado
Desenhos / artwork: CC BY-NC 4.0 — veja / see LICENSE.txt
"""

zips = [os.path.join(DIST, "gw2-facetado-kit.zip")]
zipdir(KIT, zips[0], "gw2-facetado-kit")
cur = os.path.join(DIST, "gw2-facetado-cur")
if os.path.isdir(cur):
    write(os.path.join(cur, "LICENSE.txt"), open(os.path.join(SRC, "LICENSE.txt"), encoding="utf-8-sig").read(), "utf-8-sig")
    write(os.path.join(cur, "LEIA-ME.txt"), CUR_README, "utf-8-sig")
    for cor, nome in CORES:
        if os.path.isdir(os.path.join(cur, nome)):
            shutil.copy(os.path.join(KIT, nome, f"previa-{cor}.png"), os.path.join(cur, nome, f"previa-{cor}.png"))
    shutil.copy(os.path.join(PACK, "_previa.png"), os.path.join(cur, "previa-todas-as-cores.png"))
    zips.append(os.path.join(DIST, "gw2-facetado-cur.zip"))
    zipdir(cur, zips[1], "gw2-facetado-cur")

lines = []
for z in zips:
    h = hashlib.sha256(open(z, "rb").read()).hexdigest().upper()
    lines.append(f"{h}  {os.path.basename(z)}")
    print(f"{os.path.basename(z)}: {os.path.getsize(z) / 2**20:.1f} MB  {h}")
write(os.path.join(DIST, "SHA256.txt"), "\n".join(lines) + "\n", "ascii")
