"""Converte o pacote gw2-facetado (PNGs) em cursores .cur do Windows.

Cada tipo/cor vira UM .cur com os 5 tamanhos (32, 48, 64, 96, 128) dentro,
cada tamanho com o seu ponto de clique tirado do hotspots.json. O Windows
(e programas como o YoloMouse) escolhem o tamanho mais próximo do pedido.

As imagens vão como DIB 32 bits (BGRA + máscara AND), o formato clássico,
para funcionar até em leitores de .cur que não aceitam PNG embutido.

uso: python gw2_cursors_to_cur.py <pasta_do_pacote> <pasta_de_saida>
"""
import json, os, struct, sys
from collections import defaultdict
from PIL import Image

PACK, OUT = sys.argv[1], sys.argv[2]
hot = json.load(open(os.path.join(PACK, "hotspots.json"), encoding="utf-8"))


def dib(img):
    """Imagem RGBA -> bloco DIB de cursor (cabeçalho + XOR BGRA + máscara AND)."""
    w, h = img.size
    px = img.load()
    xor = bytearray()
    for y in range(h - 1, -1, -1):  # DIB é de baixo para cima
        for x in range(w):
            r, g, b, a = px[x, y]
            xor += bytes((b, g, r, a))
    row = ((w + 31) // 32) * 4  # linha da máscara de 1 bit, alinhada em 4 bytes
    mask = bytearray()
    for y in range(h - 1, -1, -1):
        bits = bytearray(row)
        for x in range(w):
            if px[x, y][3] == 0:  # transparente
                bits[x // 8] |= 0x80 >> (x % 8)
        mask += bits
    head = struct.pack("<IiiHHIIiiII", 40, w, h * 2, 1, 32, 0, len(xor) + len(mask), 0, 0, 0, 0)
    return head + bytes(xor) + bytes(mask)


def cur(entries):
    """entries: lista de (img, hx, hy) -> bytes do arquivo .cur."""
    blobs = [dib(img) for img, _, _ in entries]
    out = struct.pack("<HHH", 0, 2, len(entries))  # tipo 2 = cursor
    off = 6 + 16 * len(entries)
    for (img, hx, hy), blob in zip(entries, blobs):
        w, h = img.size
        out += struct.pack("<BBBBHHII", w % 256, h % 256, 0, 0, hx, hy, len(blob), off)
        off += len(blob)
    return out + b"".join(blobs)


# agrupa "tipo/gw2-tipo-cor-TAM.png" por (tipo, cor)
groups = defaultdict(list)
for rel, info in hot.items():
    tipo, name = rel.split("/")
    cor = name[len(f"gw2-{tipo}-"):].rsplit("-", 1)[0]
    groups[(tipo, cor)].append((info["size"], rel, info["hotspot"]))

manifest = {}
for (tipo, cor), items in sorted(groups.items()):
    items.sort()  # 32 primeiro: leitores simples usam a primeira entrada
    entries = []
    for size, rel, (hx, hy) in items:
        img = Image.open(os.path.join(PACK, *rel.split("/"))).convert("RGBA")
        if img.size != (size, size):
            sys.exit(f"tamanho inesperado em {rel}: {img.size}")
        entries.append((img, hx, hy))
    # organizado por cor: quem quer o verde pega só a pasta verde (normal + brilho)
    dest_rel = f"{cor.removesuffix('-brilho')}/gw2-{tipo}-{cor}.cur"
    dest = os.path.join(OUT, *dest_rel.split("/"))
    os.makedirs(os.path.dirname(dest), exist_ok=True)
    with open(dest, "wb") as f:
        f.write(cur(entries))
    manifest[dest_rel] = {str(s): list(hs) for s, _, hs in items}

with open(os.path.join(OUT, "hotspots-cur.json"), "w", encoding="utf-8", newline="\n") as f:
    json.dump(manifest, f, indent=1, ensure_ascii=False)
print(len(manifest), "arquivos .cur em", OUT)
