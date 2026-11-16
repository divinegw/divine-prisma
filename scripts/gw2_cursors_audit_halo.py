"""Auditoria do halo: corte na borda, buracos e uniformidade da largura.

Largura: para cada pixel da borda externa do halo (alpha cruzando ~0,6 do lado
de fora), mede a distância até o desenho (pixels não brancos). Num halo que
acompanha a forma, essa distância é praticamente constante.
"""
import os, sys
import numpy as np
from PIL import Image, ImageDraw

pk, out = sys.argv[1], sys.argv[2]
SZ = 256
rows = []
for t in sorted(d for d in os.listdir(pk) if os.path.isdir(os.path.join(pk, d))):
    im = Image.open(f"{pk}/{t}/gw2-{t}-roxo-brilho-128.png").resize((SZ, SZ), Image.LANCZOS)
    a = np.asarray(im).astype(np.float32)
    al = a[..., 3] / 255
    white = (a[..., :3].min(axis=2) > 215)
    icon = (al > 0.6) & ~white
    halo_in = al > 0.6
    # borda externa do halo: pixels dentro do halo com vizinho fora
    nb = np.zeros_like(halo_in)
    nb[1:, :] |= ~halo_in[:-1, :]; nb[:-1, :] |= ~halo_in[1:, :]
    nb[:, 1:] |= ~halo_in[:, :-1]; nb[:, :-1] |= ~halo_in[:, 1:]
    edge = halo_in & nb & ~icon
    ey, ex = np.nonzero(edge)
    iy, ix = np.nonzero(icon)
    ds = []
    for y, x in zip(ey, ex):
        ds.append(np.sqrt(((iy - y) ** 2 + (ix - x) ** 2).min()))
    ds = np.array(ds) if ds else np.array([0.0])
    border = max(al[0].max(), al[-1].max(), al[:, 0].max(), al[:, -1].max())
    rows.append((t, ds.mean(), ds.std(), np.percentile(ds, 5), np.percentile(ds, 95), border, im))
    print(f"{t:14s} largura média={ds.mean():4.1f}px  desvio={ds.std():3.1f}  p5={np.percentile(ds,5):4.1f}  p95={np.percentile(ds,95):4.1f}  borda={border:.2f}")

cell = 266
cols = 6
bg = Image.new("RGBA", (cell * cols, cell * ((len(rows) + cols - 1) // cols)), (30, 34, 48, 255))
d = ImageDraw.Draw(bg)
for i, (t, mu, sd, p5, p95, b, im) in enumerate(rows):
    x, y = (i % cols) * cell, (i // cols) * cell
    bg.paste((196, 186, 160, 255), (x + 3, y + 3, x + cell - 3, y + cell - 3))
    bg.alpha_composite(im, (x + 5, y + 5))
    d.text((x + 8, y + 248), f"{t}  {mu:.1f}±{sd:.1f}px", fill=(0, 0, 0, 255))
bg.save(out)
