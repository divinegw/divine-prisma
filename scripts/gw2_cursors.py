"""Pacote original de cursores no estilo facetado/metálico do GW2 (v2).

Gera todos os tipos de cursor (seta, fala, engrenagem, mãos, alvos, martelo,
lupa, redimensionar, craft...) em 7 cores, versão normal e com brilho, em
vários tamanhos. Cada tipo vai para a sua subpasta.

uso: python gw2_cursors.py <pasta_saida> [--sheet previa.png] [--only tipo1,tipo2]
"""
import json, math, os, sys
import numpy as np
from PIL import Image, ImageDraw, ImageFilter

S = 1024  # tela mestre (supersampling)
OUT = sys.argv[1]
os.makedirs(OUT, exist_ok=True)

# Geometria da seta em coordenadas 0..1 (ponta no canto superior esquerdo)
T = (0.075, 0.055)   # ponta (ponto de clique)
R = (0.735, 0.665)   # asa direita
N = (0.395, 0.640)   # entalhe
B = (0.105, 0.945)   # asa de baixo
M = (0.215, 0.560)   # ponto interno da faceta esquerda (dá volume)

PALETTES = {
    # nome: (claro, médio, escuro, sombra)
    "dourado": ("#FFF6D2", "#E6B65A", "#9C6A22", "#4A2F0C"),
    "vermelho": ("#FFE1DA", "#F06A5E", "#A82E2B", "#4E1111"),
    "prata": ("#FFFFFF", "#C9D2DB", "#6F7C88", "#2B333B"),
    "ciano": ("#E2FCFF", "#43D3EE", "#167F9C", "#0A3442"),
    "verde": ("#F0FFDB", "#8EE45A", "#358424", "#12340D"),
    "rosa": ("#FFE6F5", "#FF62BE", "#B21F74", "#4C0C30"),
    "roxo": ("#F1E4FF", "#B06BFF", "#5A24B0", "#24104A"),
}
SIZES = [128, 96, 64, 48, 32]
OUTLINE = "#120C08"


def hexrgb(h):
    h = h.lstrip("#")
    return np.array([int(h[i:i + 2], 16) for i in (0, 2, 4)], dtype=np.float32)


XF = [1.0, 0.0, 0.0]  # escala, deslocamento x, deslocamento y


def P(pt):
    k, ox, oy = XF
    return ((ox + pt[0] * k) * S, (oy + pt[1] * k) * S)


def Ln(v):
    return v * XF[0] * S


def rot(pts, ang, c):
    a = math.radians(ang)
    ca, sa = math.cos(a), math.sin(a)
    return [(c[0] + (x - c[0]) * ca - (y - c[1]) * sa, c[1] + (x - c[0]) * sa + (y - c[1]) * ca) for x, y in pts]


def to_arr(im):
    return np.asarray(im, dtype=np.float32) / 255.0


def to_img(a):
    return Image.fromarray((np.clip(a, 0, 1) * 255).astype(np.uint8))


class Canvas:
    def __init__(self):
        self.im = Image.new("L", (S, S), 0)
        self.d = ImageDraw.Draw(self.im)

    def poly(self, pts, v=255):
        self.d.polygon([P(p) for p in pts], fill=v)

    def ellipse(self, c, rx, ry, v=255):
        x, y = P(c)
        self.d.ellipse([x - Ln(rx), y - Ln(ry), x + Ln(rx), y + Ln(ry)], fill=v)

    def circle(self, c, r, v=255):
        self.ellipse(c, r, r, v)

    def ring(self, c, r, t):
        self.circle(c, r + t / 2)
        self.circle(c, r - t / 2, 0)

    def capsule(self, a, b, w, v=255):
        self.d.line([P(a), P(b)], fill=v, width=max(1, int(round(Ln(w)))))
        self.circle(a, w / 2, v)
        self.circle(b, w / 2, v)

    def rect(self, cx, cy, w, h, ang=0, c=None, v=255):
        pts = [(cx - w / 2, cy - h / 2), (cx + w / 2, cy - h / 2), (cx + w / 2, cy + h / 2), (cx - w / 2, cy + h / 2)]
        if ang:
            pts = rot(pts, ang, c or (cx, cy))
        self.poly(pts, v)

    def taper(self, a, b, r0, r1, v=255):
        """Dedo: cápsula que afina da base (a, raio r0) até a ponta (b, raio r1)."""
        dx, dy = b[0] - a[0], b[1] - a[1]
        ln = math.hypot(dx, dy) or 1
        px, py = -dy / ln, dx / ln
        self.poly([(a[0] + px * r0, a[1] + py * r0), (b[0] + px * r1, b[1] + py * r1),
                   (b[0] - px * r1, b[1] - py * r1), (a[0] - px * r0, a[1] - py * r0)], v)
        self.circle(a, r0, v)
        self.circle(b, r1, v)

    def teardrop(self, c, r, tip, v=255):
        """Gota lisa: círculo + triângulo até a ponta pelos pontos tangentes (sem quina)."""
        dx, dy = tip[0] - c[0], tip[1] - c[1]
        d = math.hypot(dx, dy)
        th = math.acos(min(1.0, r / d))
        base = math.atan2(dy, dx)
        t1 = (c[0] + r * math.cos(base + th), c[1] + r * math.sin(base + th))
        t2 = (c[0] + r * math.cos(base - th), c[1] + r * math.sin(base - th))
        self.circle(c, r, v)
        self.poly([tip, t1, c, t2], v)

    def horn(self, p0, p1, p2, p3, w0, v=255, n=32, power=0.85):
        """Chifre: curva cúbica que afina da base (largura w0) até a ponta."""
        pts_l, pts_r = [], []
        for i in range(n + 1):
            t = i / n
            mt = 1 - t
            x = mt ** 3 * p0[0] + 3 * mt * mt * t * p1[0] + 3 * mt * t * t * p2[0] + t ** 3 * p3[0]
            y = mt ** 3 * p0[1] + 3 * mt * mt * t * p1[1] + 3 * mt * t * t * p2[1] + t ** 3 * p3[1]
            tx = 3 * mt * mt * (p1[0] - p0[0]) + 6 * mt * t * (p2[0] - p1[0]) + 3 * t * t * (p3[0] - p2[0])
            ty = 3 * mt * mt * (p1[1] - p0[1]) + 6 * mt * t * (p2[1] - p1[1]) + 3 * t * t * (p3[1] - p2[1])
            ln = math.hypot(tx, ty) or 1
            nx, ny = -ty / ln, tx / ln
            w = w0 / 2 * (1 - t) ** power
            pts_l.append((x + nx * w, y + ny * w))
            pts_r.append((x - nx * w, y - ny * w))
        self.poly(pts_l + pts_r[::-1], v)
        self.circle(p0, w0 / 2, v)

    def arc(self, c, r, t, a0, a1, head=None, v=255, n=48):
        angs = np.radians(np.linspace(a0, a1, n))
        outer = [(c[0] + (r + t / 2) * math.cos(a), c[1] + (r + t / 2) * math.sin(a)) for a in angs]
        inner = [(c[0] + (r - t / 2) * math.cos(a), c[1] + (r - t / 2) * math.sin(a)) for a in angs[::-1]]
        self.poly(outer + inner, v)
        if head:
            hw, hl = head
            a = angs[-1]
            u = (math.cos(a), math.sin(a))
            d = (-math.sin(a), math.cos(a))
            p = (c[0] + r * u[0], c[1] + r * u[1])
            self.poly([(p[0] + u[0] * hw, p[1] + u[1] * hw), (p[0] + d[0] * hl, p[1] + d[1] * hl),
                       (p[0] - u[0] * hw, p[1] - u[1] * hw)], v)

    def arr(self):
        return to_arr(self.im)


# ---------------------------------------------------------------- tons
def scalar_gradient(t0, t1, p0, p1):
    yy, xx = np.mgrid[0:S, 0:S].astype(np.float32)
    x0, y0 = P(p0)
    x1, y1 = P(p1)
    dx, dy = x1 - x0, y1 - y0
    t = ((xx - x0) * dx + (yy - y0) * dy) / (dx * dx + dy * dy)
    return t0 + (t1 - t0) * np.clip(t, 0, 1)


def bevel_tone(m, n=22, hi=0.80, lo=0.40, strength=0.45):
    """Tom 0..1 de um relevo chanfrado (topo plano + bordas facetadas)."""
    n = max(4, int(round(n * XF[0])))
    cur = to_img(m)
    acc = m.copy()
    for _ in range(n):
        cur = cur.filter(ImageFilter.MinFilter(3))
        acc += to_arr(cur)
    h = to_arr(to_img(acc / (n + 1)).filter(ImageFilter.GaussianBlur(1.5)))
    gy, gx = np.gradient(h)
    dot = np.clip((gx + gy) * 0.7071 * (n + 1), -1.2, 1.2)
    ys, xs = np.nonzero(m > 0.5)
    yy, xx = np.mgrid[0:S, 0:S].astype(np.float32)
    if len(xs):
        x0, x1, y0, y1 = xs.min(), xs.max(), ys.min(), ys.max()
        diag = np.clip(((xx - x0) + (yy - y0)) / max(1, (x1 - x0) + (y1 - y0)), 0, 1)
    else:
        diag = np.zeros_like(m)
    flat = hi + (lo - hi) * diag
    # filete claro na crista do chanfro de cima/esquerda
    crest = np.clip(dot - 0.75, 0, 1) * 0.6
    return np.clip(flat + strength * dot + crest, 0, 1)


# ---------------------------------------------------------------- partes
def part(mask, tone, pal=None, spec=None, rimk=15):
    return {"mask": mask, "tone": tone, "pal": pal, "spec": spec, "rimk": rimk}


def facet_part(facets, pal=None, rimk=9):
    """Parte lapidada: lista de (polígono, (tom0, tom1, ponto0, ponto1))."""
    mask = np.zeros((S, S), np.float32)
    tone = np.zeros((S, S), np.float32)
    for poly, (t0, t1, p0, p1) in facets:
        c = Canvas()
        c.poly(poly)
        fm = c.arr()
        tone = tone * (1 - fm) + scalar_gradient(t0, t1, p0, p1) * fm
        mask = np.maximum(mask, fm)
    return part(mask, np.clip(tone, 0, 1), pal, rimk=rimk)


def rdilate(img, r):
    """Dilatação redonda aproximada (desfoque + limiar)."""
    b = img.filter(ImageFilter.GaussianBlur(r / 2))
    return b.point(lambda v: 255 if v > 6 else 0)


def rerode(img, r):
    inv = img.point(lambda v: 255 - v)
    return rdilate(inv, r).point(lambda v: 255 - v)


def bevel_part(draw, pal=None, n=22, rimk=15, smooth=0, **kw):
    cv = Canvas()
    draw(cv)
    if smooth:  # fecha entalhes nas emendas de formas (ex.: chifre + berço)
        cv.im = rerode(rdilate(cv.im, smooth), smooth).filter(ImageFilter.GaussianBlur(1.2))
    m = cv.arr()
    return part(m, bevel_tone(m, n, **kw), pal, rimk=rimk)


def arrow_part(s=1.0, tip=T, pal=None):
    f = lambda p: (tip[0] + (p[0] - T[0]) * s, tip[1] + (p[1] - T[1]) * s)
    t, r, n, b, mm = map(f, (T, R, N, B, M))
    cv = Canvas()
    cv.poly([t, r, n, b])
    mask = cv.arr()
    tone = np.zeros((S, S), np.float32)
    for poly, (t0, t1, p0, p1) in [
        ([t, r, n], (1.0, 2 / 3, t, r)),      # face superior (luz)
        ([t, n, mm], (2 / 3, 1 / 3, t, n)),   # face central
        ([t, mm, b], (1 / 3, 0.0, t, b)),     # face esquerda (sombra)
        ([mm, n, b], (1 / 3, 2 / 3, b, n)),   # face inferior
    ]:
        c = Canvas()
        c.poly(poly)
        fm = c.arr()
        tone = tone * (1 - fm) + scalar_gradient(t0, t1, p0, p1) * fm
    edge = Image.new("L", (S, S), 0)
    d = ImageDraw.Draw(edge)
    d.line([P(t), P(n)], fill=150, width=max(1, int(7 * s * XF[0])))
    d.line([P(f((T[0] + 0.012, T[1] + 0.02))), P(f((R[0] - 0.04, R[1] - 0.02)))], fill=210, width=max(1, int(9 * s * XF[0])))
    spec = to_arr(edge.filter(ImageFilter.GaussianBlur(3))) * mask
    return part(mask, tone, pal, spec)


MINI = dict(s=0.22, tip=(0.04, 0.04))  # (v1, não usado)
DART_TIP = (0.04, 0.04)   # ponta da setinha incorporada = ponto de clique
DART_REACH = 0.23         # distância (na diagonal) da ponta até a borda do desenho;
                          # deixa um vão visível entre a cunha e o desenho em todos os tamanhos
WEDGE = 0.18              # comprimento dos lados retos da cunha


def dart_part():
    """Cunha de canto (◤): topo e lado esquerdo retos, face diagonal virada
    para o desenho, com duas facetas (cima clara, baixo escura)."""
    t = DART_TIP
    a = (t[0] + WEDGE, t[1] + 0.035)          # ponta da direita (topo cai um pouco)
    b = (t[0] + 0.030, t[1] + WEDGE)          # ponta de baixo
    mid = ((a[0] + b[0]) / 2, (a[1] + b[1]) / 2)
    notch = (t[0] + (mid[0] - t[0]) * 0.80, t[1] + (mid[1] - t[1]) * 0.80)  # leve entalhe
    cv = Canvas()
    cv.poly([t, a, notch, b])
    mask = cv.arr()
    tone = np.zeros((S, S), np.float32)
    for poly, (t0, t1, p0, p1) in [([t, a, notch], (1.0, 0.62, t, a)),
                                   ([t, notch, b], (0.38, 0.06, t, b))]:
        f = Canvas()
        f.poly(poly)
        fm = f.arr()
        tone = tone * (1 - fm) + scalar_gradient(t0, t1, p0, p1) * fm
    edge = Image.new("L", (S, S), 0)
    ImageDraw.Draw(edge).line([P((t[0] + 0.012, t[1] + 0.012)), P(notch)], fill=170, width=max(1, int(6 * XF[0])))
    spec = to_arr(edge.filter(ImageFilter.GaussianBlur(2.5))) * mask
    return part(mask, tone, None, spec)


def find_diag_edge(fn):
    """Primeiro ponto do desenho na diagonal a partir do canto (coordenadas 0..1)."""
    union = np.zeros((S, S), np.float32)
    for p in fn():
        union = np.maximum(union, p["mask"])
    for i in range(1, 600):
        s = i / 1000
        x, y = P((s, s))
        if union[min(S - 1, int(y)), min(S - 1, int(x))] > 0.5:
            return s
    return 0.3


def double_arrow_draw(c, length, ang, shaft=0.085, hw=0.13, hl=0.17):
    def draw(cv):
        half = length / 2
        cv.rect(c[0], c[1], length - 2 * hl + 0.02, shaft, ang=ang, c=c)
        for sgn in (-1, 1):
            tip = (c[0] + sgn * half, c[1])
            base = c[0] + sgn * (half - hl)
            cv.poly(rot([tip, (base, c[1] - hw), (base, c[1] + hw)], ang, c))
    return draw


def cycle_parts(c, r, t, pal=None, head=(0.09, 0.13)):
    return [bevel_part(lambda cv: cv.arc(c, r, t, 200, 310, head=head), pal, n=14),
            bevel_part(lambda cv: cv.arc(c, r, t, 20, 130, head=head), pal, n=14)]


HAND_TILT = {"aberta": -10, "fechada": -18, "apontar": -6}
# estilo das mãos: atual | A (facetada) | B (manopla) | C (luva clássica)
# dedão (e indicador estendido) — v0 é o instalado até 13/11
THUMB_VARIANTS = {
    "0": {"thumb": [(0.400, 0.72), (0.300, 0.645), (0.210, 0.545), (0.170, 0.465)], "thumb_r": (.064, .046)},
    # 1: natural — dedão curto em 2 falanges, sobe na diagonal; indicador ~ do tamanho do médio
    "1": {"thumb": [(0.375, 0.715), (0.275, 0.615), (0.225, 0.525)], "thumb_r": (.074, .052),
          "index": ([(0.405, 0.52), (0.398, 0.34), (0.385, 0.155)], .057, .043)},
    # 2: colado — dedão encostado na lateral, apontando para cima (silhueta compacta)
    "2": {"thumb": [(0.370, 0.725), (0.300, 0.630), (0.285, 0.535)], "thumb_r": (.072, .052),
          "index": ([(0.405, 0.52), (0.398, 0.35), (0.388, 0.170)], .058, .044)},
    # 3: robusto — dedão curto e grosso, uma peça só, ponta chanfrada (ar de manopla)
    "3": {"thumb": [(0.385, 0.705), (0.245, 0.565)], "thumb_r": (.085, .062),
          "index": ([(0.405, 0.52), (0.396, 0.33), (0.382, 0.140)], .060, .046)},
}
# cabo do martelo — v0 é o instalado até 13/11 (cabo 0,66, longo demais)
HAMMER_VARIANTS = {
    "0": {"len": 0.66, "grip": 3, "pommel": "bloco"},
    "1": {"len": 0.46, "grip": 3, "pommel": "bloco"},    # só mais curto, mesmo desenho
    "2": {"len": 0.38, "grip": 2, "pommel": "disco"},    # marreta curta, pomo redondo
    "3": {"len": 0.50, "grip": "faixa", "pommel": "bloco"},  # médio, empunhadura numa faixa só
}
HAMMER_VAR = sys.argv[sys.argv.index("--hammer-var") + 1] if "--hammer-var" in sys.argv else "2"  # escolhido em 13/11: marreta
HAND_VAR = sys.argv[sys.argv.index("--hand-var") + 1] if "--hand-var" in sys.argv else "final"
# escolha do usuário em 13/11: mão aberta com o dedão "natural" (1); as outras com o "colado" (2)
HAND_VAR_FINAL = {"aberta": "1", "fechada": "2", "apontar": "2"}
HAND_STYLE = sys.argv[sys.argv.index("--hand-style") + 1] if "--hand-style" in sys.argv else "A"  # escolhida em 13/11


def hand_parts(kind, s=1.0, dx=0.0, dy=0.0):
    """Luva arredondada: dedos afinando, dorso oval e punho com aba."""
    piv = (0.52, 0.62)
    ang = HAND_TILT[kind]

    def f(p):
        p = rot([p], ang, piv)[0]
        return (p[0] * s + dx, p[1] * s + dy)

    # (pontos do dedo: base, [junta], ponta), raio na base, raio na ponta
    fingers = {
        # dedos em leque, com leve curva e ponta mais fina
        "aberta": [([(0.415, 0.50), (0.385, 0.33), (0.345, 0.18)], .055, .041),
                   ([(0.505, 0.48), (0.505, 0.30), (0.512, 0.11)], .057, .043),
                   ([(0.595, 0.50), (0.622, 0.33), (0.658, 0.17)], .054, .041),
                   ([(0.670, 0.56), (0.715, 0.44), (0.768, 0.32)], .046, .035)],
        # agarrando: dedos dobrados, juntos, nós dos dedos marcados
        "fechada": [([(0.410, 0.54), (0.395, 0.42), (0.420, 0.36)], .064, .056),
                    ([(0.505, 0.52), (0.505, 0.38), (0.530, 0.31)], .066, .058),
                    ([(0.598, 0.53), (0.612, 0.41), (0.638, 0.355)], .063, .055),
                    ([(0.678, 0.58), (0.700, 0.49), (0.725, 0.445)], .054, .047)],
        "apontar": [([(0.505, 0.52), (0.510, 0.41), (0.545, 0.37)], .058, .050),
                    ([(0.600, 0.53), (0.615, 0.43), (0.645, 0.39)], .056, .048),
                    ([(0.675, 0.58), (0.700, 0.49), (0.730, 0.46)], .049, .042),
                    ([(0.405, 0.52), (0.392, 0.30), (0.372, 0.08)], .057, .043)],
    }[kind]
    # dedão e indicador estendido: variantes em teste (--hand-var)
    tv = THUMB_VARIANTS[HAND_VAR_FINAL[kind] if HAND_VAR == "final" else HAND_VAR]
    thumb, thumb_r = tv["thumb"], tv["thumb_r"]
    if kind == "apontar" and tv.get("index"):
        fingers = fingers[:3] + [tv["index"]]

    st = HAND_STYLE
    PALM = [(0.330, 0.50), (0.735, 0.52), (0.755, 0.70), (0.685, 0.82), (0.385, 0.82), (0.310, 0.68)]
    CUFF = [(0.37, 0.79), (0.69, 0.79), (0.74, 0.95), (0.33, 0.95)]

    def segs(pts, r0, r1):
        n = len(pts) - 1
        for i in range(n):
            yield i, n, f(pts[i]), f(pts[i + 1]), (r0 + (r1 - r0) * i / n) * s, (r0 + (r1 - r0) * (i + 1) / n) * s

    # ---- atual: luva arredondada (instalada em 13/11)
    def finger_atual(pts, r0, r1):
        def draw(cv):
            for _, _, a, b, ra, rb in segs(pts, r0, r1):
                cv.taper(a, b, ra, rb)
        return [bevel_part(draw, n=30, rimk=9, hi=0.86, lo=0.42, strength=0.5)]

    # ---- A: luva facetada (low-poly, mesma lógica de luz das setas)
    def finger_facet(pts, r0, r1):
        facets = []
        for i, n, a, b, ra, rb in segs(pts, r0, r1):
            dx_, dy_ = b[0] - a[0], b[1] - a[1]
            ln = math.hypot(dx_, dy_) or 1
            d = (dx_ / ln, dy_ / ln)
            p = (-d[1], d[0])
            if p[0] * -0.7071 + p[1] * -0.7071 < 0:  # lado +p deve ser o iluminado
                p = (-p[0], -p[1])
            if i == 0:  # base do dedo entra fundo no dorso (sem vão entre dedo e mão)
                a = (a[0] - d[0] * 0.09 * s, a[1] - d[1] * 0.09 * s)
            A1, A2 = (a[0] + p[0] * ra, a[1] + p[1] * ra), (a[0] - p[0] * ra, a[1] - p[1] * ra)
            B1, B2 = (b[0] + p[0] * rb, b[1] + p[1] * rb), (b[0] - p[0] * rb, b[1] - p[1] * rb)
            if i > 0:  # junta: losango que fecha a dobra
                facets.append(([A1, (a[0] - d[0] * ra, a[1] - d[1] * ra), A2, (a[0] + d[0] * ra, a[1] + d[1] * ra)], (0.6, 0.6, a, b)))
            k = -0.07 * i
            facets.append(([a, A1, B1, b], (0.95 + k, 0.78 + k, a, b)))
            facets.append(([a, b, B2, A2], (0.40 + k, 0.26 + k, a, b)))
            if i == n - 1:
                tip = (b[0] + d[0] * rb * 0.6, b[1] + d[1] * rb * 0.6)  # ponta chanfrada, não garra
                facets.append(([B1, tip, b], (0.95, 0.80, b, tip)))
                facets.append(([b, tip, B2], (0.36, 0.24, b, tip)))
        return [facet_part(facets, rimk=9)]

    def dome(poly, base=0.62, amp=0.32, rimk=7):
        """Polígono em facetas triangulares a partir do centro (cúpula lapidada)."""
        pts = [f(p) for p in poly]
        cx = sum(p[0] for p in pts) / len(pts)
        cy = sum(p[1] for p in pts) / len(pts)
        cp = (cx, cy)
        facets = []
        for i in range(len(pts)):
            a, b = pts[i], pts[(i + 1) % len(pts)]
            mx, my = (a[0] + b[0]) / 2, (a[1] + b[1]) / 2
            nx, ny = mx - cx, my - cy
            ln = math.hypot(nx, ny) or 1
            lit = (nx * -0.7071 + ny * -0.7071) / ln
            facets.append(([cp, a, b], (base + 0.08, base + amp * lit, cp, (mx, my))))
        return facet_part(facets, rimk=rimk)

    # ---- B: manopla de armadura (placas segmentadas, rebites)
    def finger_plate(pts, r0, r1):
        out = []
        for i, n, a, b, ra, rb in segs(pts, r0, r1):
            dx_, dy_ = b[0] - a[0], b[1] - a[1]
            ln = math.hypot(dx_, dy_) or 1
            g = min(0.018 * s, ln * 0.15)
            a2 = (a[0] + dx_ / ln * g, a[1] + dy_ / ln * g)
            b2 = b if i == n - 1 else (b[0] - dx_ / ln * g, b[1] - dy_ / ln * g)
            out.append(bevel_part(lambda cv, a2=a2, b2=b2, ra=ra, rb=rb: cv.taper(a2, b2, ra, rb),
                                  n=18, rimk=11, hi=0.92, lo=0.40, strength=0.62))
        return out

    # ---- C: luva clássica (dedos juntos, costuras, punho com faixa)
    def finger_soft(pts, r0, r1):
        def draw(cv):
            for _, _, a, b, ra, rb in segs(pts, r0 * 1.14, r1 * 1.18):
                cv.taper(a, b, ra, rb)
        return [bevel_part(draw, n=34, rimk=7, hi=0.84, lo=0.44, strength=0.42)]

    finger = {"atual": finger_atual, "A": finger_facet, "B": finger_plate, "C": finger_soft}[st]

    def palm_parts():
        if st == "A":
            return [dome(PALM)]
        if st == "B":
            plate = bevel_part(lambda cv: cv.poly([f(p) for p in PALM]), n=30, rimk=9, hi=0.88, lo=0.36, strength=0.62)
            return [plate]
        if st == "C":
            def palm_c(cv):
                cv.ellipse(f((0.535, 0.63)), 0.235 * s, 0.18 * s)
                cv.poly([f(p) for p in [(0.31, 0.60), (0.75, 0.60), (0.71, 0.81), (0.36, 0.81)]])
            return [bevel_part(palm_c, n=40, rimk=5, hi=0.84, lo=0.42, strength=0.45)]

        def palm(cv):
            cv.ellipse(f((0.535, 0.62)), 0.225 * s, 0.175 * s)
            cv.poly([f(p) for p in [(0.33, 0.60), (0.735, 0.60), (0.70, 0.80), (0.37, 0.80)]])
        return [bevel_part(palm, n=46, rimk=7, hi=0.84, lo=0.40, strength=0.5)]

    def top_parts():  # o que vai por cima do dorso
        if st == "B":
            guard = bevel_part(lambda cv: cv.capsule(f((0.36, 0.535)), f((0.715, 0.555)), 0.075 * s),
                               n=16, rimk=11, hi=0.95, lo=0.45, strength=0.6)
            rivets = bevel_part(lambda cv: [cv.circle(f(c), 0.022 * s) for c in [(0.42, 0.66), (0.53, 0.68), (0.64, 0.66)]],
                                n=6, rimk=7, hi=1.0, lo=0.6, strength=0.5)
            return [guard, rivets]
        return []

    def cuff_parts():
        if st == "A":
            return [dome(CUFF, base=0.45, amp=0.25, rimk=13)]
        if st == "B":
            body = bevel_part(lambda cv: cv.poly([f(p) for p in [(0.36, 0.79), (0.70, 0.79), (0.77, 0.96), (0.30, 0.96)]]),
                              n=22, rimk=13, hi=0.78, lo=0.30, strength=0.6)
            ridge = bevel_part(lambda cv: cv.capsule(f((0.35, 0.86)), f((0.715, 0.86)), 0.045 * s),
                               n=10, rimk=9, hi=0.95, lo=0.5, strength=0.5)
            return [body, ridge]
        if st == "C":
            body = bevel_part(lambda cv: cv.poly([f(p) for p in CUFF]), n=26, rimk=11, hi=0.72, lo=0.36)
            band = bevel_part(lambda cv: cv.poly([f(p) for p in [(0.365, 0.80), (0.695, 0.80), (0.705, 0.845), (0.355, 0.845)]]),
                              n=8, rimk=7, hi=0.55, lo=0.28, strength=0.4)
            return [body, band]
        return [bevel_part(lambda cv: cv.poly([f(p) for p in CUFF]), n=26, rimk=13, hi=0.70, lo=0.34)]

    # todos os dedos (inclusive o indicador estendido) saem de trás do dorso,
    # como numa mão de verdade; nada é "colado" por cima
    parts = []
    for fg in fingers:
        parts += finger(*fg)
    parts += finger(thumb, *thumb_r)
    parts += palm_parts()
    parts += top_parts()
    parts += cuff_parts()
    return parts


# ---------------------------------------------------------------- tipos
# cada tipo: (função que devolve as partes, ponto de clique, "canto"|"centro")
def t_seta():
    return [arrow_part()]


def t_seta_dupla():
    """Seta com um 'eco' atrás: a de trás só aparece como uma lâmina em V
    (topo e lado esquerdo), um pouco mais escura, como uma camada de fundo."""
    back = arrow_part(0.80, (0.05, 0.04))
    back["tone"] = back["tone"] * 0.78
    back["spec"] = back["spec"] * 0.5
    # deslocamento mais para baixo que para a direita: assim a lâmina aparece
    # nas duas bordas (topo e esquerda), formando o V
    front = arrow_part(0.76, (0.135, 0.215))
    front["rimk"] = 27  # vão escuro largo entre as duas camadas
    return [back, front]


def t_fala():
    def draw(cv):
        cv.ellipse((0.565, 0.52), 0.37, 0.295)
        cv.poly([(0.40, 0.74), (0.57, 0.79), (0.35, 0.955)])
    return [bevel_part(draw, n=26)]


def t_engrenagem():
    c = (0.565, 0.565)

    def draw(cv):
        cv.circle(c, 0.28)
        for i in range(8):
            cv.poly(rot([(c[0] - 0.062, c[1] - 0.22), (c[0] + 0.062, c[1] - 0.22),
                         (c[0] + 0.047, c[1] - 0.385), (c[0] - 0.047, c[1] - 0.385)], i * 45, c))  # um dente aponta para a cunha
        cv.circle(c, 0.11, 0)
    return [bevel_part(draw, n=24)]


def t_lupa():
    c = (0.50, 0.50)
    ring = bevel_part(lambda cv: (cv.ring(c, 0.255, 0.10), cv.capsule((0.71, 0.71), (0.885, 0.885), 0.11)), n=18)
    plus = bevel_part(lambda cv: (cv.rect(c[0], c[1], 0.25, 0.08), cv.rect(c[0], c[1], 0.08, 0.25)), n=12)
    return [ring, plus]


def t_martelo():
    # posição manual: a face longa da cabeça fica paralela à face da cunha
    c = (0.27, 0.27)
    A = -45

    hv = HAMMER_VARIANTS[HAMMER_VAR]
    L, y0 = hv["len"], 0.10  # comprimento do cabo, a partir da base da cabeça

    def handle(cv):
        cv.rect(c[0], c[1] + y0 + L / 2, 0.105, L, ang=A, c=c)
        if hv["pommel"] == "disco":  # pomo redondo
            x, y = rot([(c[0], c[1] + y0 + L + 0.03)], A, c)[0]
            cv.circle((x, y), 0.065)
        else:                        # pomo em bloco
            cv.rect(c[0], c[1] + y0 + L + 0.035, 0.16, 0.075, ang=A, c=c)

    def grip(cv):  # empunhadura: tiras de couro ou uma faixa só
        if hv["grip"] == "faixa":
            cv.rect(c[0], c[1] + y0 + L * 0.68, 0.13, L * 0.42, ang=A, c=c)
        else:
            n = hv["grip"]
            for i in range(n):
                cv.rect(c[0], c[1] + y0 + L * (0.50 + 0.40 * i / max(1, n - 1)), 0.13, 0.038, ang=A, c=c)

    def head(cv):
        cv.rect(c[0], c[1], 0.30, 0.21, ang=A, c=c)
        for sx in (-0.15, 0.15):
            cv.rect(c[0] + sx, c[1], 0.075, 0.26, ang=A, c=c)
        cv.rect(c[0], c[1] + 0.125, 0.15, 0.06, ang=A, c=c)  # colar do cabo
    return [bevel_part(handle, n=14), bevel_part(grip, n=6, rimk=7), bevel_part(head, n=22)]


def t_girar():
    return cycle_parts((0.57, 0.57), 0.29, 0.09)

def t_alvo():
    c = (0.56, 0.56)

    def draw(cv):
        cv.ring(c, 0.30, 0.07)
        cv.rect(c[0], c[1], 0.68, 0.065)
        cv.rect(c[0], c[1], 0.065, 0.68)
        for dxy in ((0.34, 0), (-0.34, 0), (0, 0.34), (0, -0.34)):
            cv.circle((c[0] + dxy[0], c[1] + dxy[1]), 0.045)
    return [bevel_part(draw, n=14)]


REVIVE_VAR = sys.argv[sys.argv.index("--revive-var") + 1] if "--revive-var" in sys.argv else "4"  # escolhido em 13/11: gota no berço

# berço alto em V: chifres finos que sobem, fundo que escorre em pingos
CRADLE = [(0.335, 0.13), (0.300, 0.32), (0.330, 0.50), (0.400, 0.64), (0.430, 0.80), (0.470, 0.74),
          (0.510, 0.90), (0.535, 0.80), (0.560, 0.97), (0.585, 0.80), (0.610, 0.90), (0.650, 0.74),
          (0.690, 0.80), (0.720, 0.64), (0.790, 0.50), (0.820, 0.32), (0.785, 0.13), (0.745, 0.33),
          (0.700, 0.48), (0.560, 0.60), (0.420, 0.48), (0.375, 0.33)]


def t_reviver():
    """Reviver aliado (ícone do jogo: emblema prateado com dois chifres,
    uma esfera no centro e o fundo escorrendo em pingos)."""
    if REVIVE_VAR in ("4", "5", "6"):
        # direção nova (curvas): berço redondo + chifres curvos + pingos lisos
        mx = 0.56
        mir = lambda p: (2 * mx - p[0], p[1])
        cfg = {
            # 4: gota de vida para cima no berço (leitura clássica do ícone)
            "4": dict(horn=[(0.329, 0.535), (0.262, 0.42), (0.262, 0.27), (0.335, 0.15)], hw=0.092,
                      cut=((mx, 0.46), 0.195, 0.255), center="gota"),
            # 5: esfera + corpo afunilando para baixo (mais perto do ícone do jogo)
            "5": dict(horn=[(0.335, 0.53), (0.27, 0.43), (0.28, 0.29), (0.35, 0.19)], hw=0.12,
                      cut=((mx, 0.44), 0.18, 0.27), center="esfera"),
            # 6: chifres abertos, curvando para fora (silhueta mais larga e heráldica)
            "6": dict(horn=[(0.335, 0.53), (0.20, 0.44), (0.19, 0.25), (0.285, 0.14)], hw=0.13,
                      cut=((mx, 0.46), 0.20, 0.255), center="gota"),
        }[REVIVE_VAR]

        def cradle(cv):
            # 1) berço + chifres, suavizados juntos (a emenda por fora fica lisa)
            cv.ellipse((mx, 0.60), 0.285, 0.265)
            h = cfg["horn"]
            cv.horn(*h, cfg["hw"])
            cv.horn(*[mir(p) for p in h], cfg["hw"])
            cv.im = rerode(rdilate(cv.im, 12), 12)
            cv.d = ImageDraw.Draw(cv.im)
            # 2) pingos e boca do berço por cima, sem suavizar (mantêm a forma)
            for c, r, tip in [((0.465, 0.855), 0.048, (0.465, 0.72)), ((mx, 0.915), 0.056, (mx, 0.75)),
                              ((0.655, 0.855), 0.048, (0.655, 0.72))]:
                cv.teardrop(c, r, tip)
            (cc, rx, ry) = cfg["cut"]
            cv.ellipse(cc, rx, ry, v=0)

        def center(cv):
            if cfg["center"] == "gota":
                cv.teardrop((mx, 0.525), 0.112, (mx, 0.215))
            else:
                cv.circle((mx, 0.33), 0.088)
                cv.teardrop((mx, 0.47), 0.072, (mx, 0.69))
        return [bevel_part(cradle, n=18), bevel_part(center, n=16, hi=0.95, lo=0.55)]
    if REVIVE_VAR == "1":   # fiel: escudo compacto, chifres curtos, figura (esfera + corpo) no meio
        def shield(cv):
            cv.poly([(0.30, 0.17), (0.255, 0.40), (0.29, 0.60), (0.37, 0.74), (0.40, 0.88), (0.46, 0.80),
                     (0.51, 0.93), (0.56, 0.84), (0.61, 0.93), (0.66, 0.80), (0.72, 0.88), (0.75, 0.74),
                     (0.83, 0.60), (0.865, 0.40), (0.82, 0.17), (0.755, 0.36), (0.72, 0.52), (0.56, 0.72),
                     (0.40, 0.52), (0.365, 0.36)])

        def figure(cv):
            cv.circle((0.56, 0.345), 0.092)
            cv.poly([(0.475, 0.40), (0.645, 0.40), (0.61, 0.52), (0.56, 0.69), (0.51, 0.52)])
        return [bevel_part(shield, n=18), bevel_part(figure, n=14, hi=0.95, lo=0.58)]
    if REVIVE_VAR == "2":   # gota de vida para cima, entre chifres curvos; 3 pingos grandes
        def cradle(cv):
            cv.poly([(0.30, 0.20), (0.27, 0.40), (0.33, 0.58), (0.42, 0.70), (0.44, 0.88), (0.50, 0.76),
                     (0.56, 0.97), (0.62, 0.76), (0.68, 0.88), (0.70, 0.70), (0.79, 0.58), (0.85, 0.40),
                     (0.82, 0.20), (0.77, 0.40), (0.70, 0.55), (0.56, 0.63), (0.42, 0.55), (0.35, 0.40)])

        def drop(cv):
            cv.circle((0.56, 0.47), 0.105)
            cv.poly([(0.473, 0.42), (0.647, 0.42), (0.56, 0.19)])
        return [bevel_part(cradle, n=16), bevel_part(drop, n=14, hi=0.95, lo=0.58)]
    if REVIVE_VAR == "3":   # espírito se erguendo: cabeça, braços em V para cima, corpo em chama
        def arms(cv):
            cv.taper((0.50, 0.47), (0.33, 0.25), 0.065, 0.045)
            cv.taper((0.62, 0.47), (0.79, 0.25), 0.065, 0.045)

        def body(cv):
            cv.poly([(0.45, 0.40), (0.67, 0.40), (0.74, 0.58), (0.68, 0.72), (0.73, 0.88), (0.63, 0.81),
                     (0.56, 0.97), (0.49, 0.81), (0.39, 0.88), (0.44, 0.72), (0.38, 0.58)])
        return [bevel_part(arms, n=14), bevel_part(body, n=20),
                bevel_part(lambda cv: cv.circle((0.56, 0.29), 0.10), n=14, hi=0.95, lo=0.58)]

    def cup(cv):
        cv.ellipse((0.56, 0.55), 0.27, 0.26)
        cv.poly([(0.29, 0.52), (0.37, 0.42), (0.265, 0.25)])           # chifre esquerdo
        cv.poly([(0.83, 0.52), (0.75, 0.42), (0.855, 0.25)])           # chifre direito
        cv.poly([(0.40, 0.73), (0.50, 0.79), (0.43, 0.93)])            # chamas de baixo
        cv.poly([(0.49, 0.79), (0.63, 0.79), (0.56, 0.975)])
        cv.poly([(0.62, 0.79), (0.72, 0.73), (0.69, 0.93)])
        cv.ellipse((0.56, 0.42), 0.175, 0.225, v=0)                     # boca do cálice

    def drop(cv):
        cv.circle((0.56, 0.48), 0.095)
        cv.poly([(0.482, 0.435), (0.638, 0.435), (0.56, 0.24)])
    return [bevel_part(cup, n=18), bevel_part(drop, n=14, hi=0.92, lo=0.55)]


def t_mira():
    c = (0.5, 0.5)

    def draw(cv):
        cv.ring(c, 0.28, 0.065)
        for i in range(4):
            cv.poly(rot([(c[0] - 0.032, c[1] - 0.18), (c[0] + 0.032, c[1] - 0.18),
                         (c[0] + 0.032, c[1] - 0.42), (c[0] - 0.032, c[1] - 0.42)], i * 90, c))
            x, y = rot([(c[0], c[1] - 0.42)], i * 90, c)[0]
            cv.circle((x, y), 0.042)
    return [bevel_part(draw, n=14), bevel_part(lambda cv: cv.circle(c, 0.045), n=8)]


def t_alvo_area():
    c = (0.5, 0.5)

    def draw(cv):
        cv.ring(c, 0.40, 0.04)
        cv.ring(c, 0.33, 0.03)
        o = 0.36
        cv.poly([(c[0], c[1] - o), (c[0] + o, c[1]), (c[0], c[1] + o), (c[0] - o, c[1])])
        i = o - 0.065
        cv.poly([(c[0], c[1] - i), (c[0] + i, c[1]), (c[0], c[1] + i), (c[0] - i, c[1])], 0)
        for k in range(4):
            cv.poly(rot([(c[0] - 0.05, c[1] - 0.38), (c[0] + 0.05, c[1] - 0.38), (c[0], c[1] - 0.47)], k * 90, c))
        for k in range(8):
            x, y = rot([(c[0], c[1] - 0.365)], k * 45 + 22.5, c)[0]
            cv.circle((x, y), 0.022)
    return [bevel_part(draw, n=12)]


def t_mao_aberta():
    return hand_parts("aberta")


def t_mao_fechada():
    return hand_parts("fechada")


def t_mao_apontar():
    return hand_parts("apontar")


def t_mao_ajuste():
    # mão maior (protagonista) e seta ↕ mais fina, encostada à direita
    return hand_parts("apontar", s=0.92, dx=-0.04, dy=0.05) + [
        bevel_part(double_arrow_draw((0.875, 0.55), 0.62, 90, shaft=0.058, hw=0.085, hl=0.12), n=12)]


def t_redim(ang):
    return lambda: [bevel_part(double_arrow_draw((0.5, 0.5), 0.84, ang), n=18)]


def t_craft(pal):
    return lambda: [arrow_part(0.72, (0.06, 0.05))] + cycle_parts((0.70, 0.68), 0.19, 0.07, pal=pal, head=(0.075, 0.11))


TYPES = {
    # nome: (partes, ponto de clique em 0..1, deslocamento do brilho)
    "seta": (t_seta, T, (0.10, 0.09)),
    "seta-dupla": (t_seta_dupla, (0.06, 0.05), (0.12, 0.12)),
    "fala": (t_fala, "canto", (0.12, 0.12)),
    "engrenagem": (t_engrenagem, "canto", (0.12, 0.12)),
    "lupa": (t_lupa, "canto", (0.12, 0.12)),
    "martelo": (t_martelo, "canto-fixo", (0.12, 0.12)),
    "girar": (t_girar, "canto", (0.12, 0.12)),
    "alvo": (t_alvo, "canto", (0.12, 0.12)),
    "reviver": (t_reviver, "canto", (0.12, 0.12)),
    "mira": (t_mira, (0.5, 0.5), (0.15, 0.15)),
    "alvo-area": (t_alvo_area, (0.5, 0.5), (0.15, 0.15)),
    "mao-aberta": (t_mao_aberta, (0.45, 0.30), (0.15, 0.15)),
    "mao-fechada": (t_mao_fechada, (0.50, 0.50), (0.15, 0.15)),
    "mao-apontar": (t_mao_apontar, (0.339, 0.16), (0.15, 0.15)),   # ponta do indicador (dedão colado)
    "mao-ajuste": (t_mao_ajuste, (0.272, 0.197), (0.15, 0.15)),
    "redim-h": (t_redim(0), (0.5, 0.5), (0.15, 0.15)),
    "redim-v": (t_redim(90), (0.5, 0.5), (0.15, 0.15)),
    "redim-diag1": (t_redim(45), (0.5, 0.5), (0.15, 0.15)),
    "redim-diag2": (t_redim(-45), (0.5, 0.5), (0.15, 0.15)),
    "craft-perto": (t_craft("verde"), (0.06, 0.05), (0.12, 0.12)),
    "craft-longe": (t_craft("vermelho"), (0.06, 0.05), (0.12, 0.12)),
}


# ---------------------------------------------------------------- render
HALO_R = 34      # largura da borda branca, em px da tela mestre (1024)
HALO_FADE = 12   # esmaecimento curto por fora da borda
HALO_MAX = HALO_R + HALO_FADE + 2


def edt_near(sil, dmax=HALO_MAX):
    """Distância euclidiana exata até a silhueta (só até dmax px).

    Coluna: distância 1-D pelo truque do acumulado; linha: mínimo de
    g(x+k)^2 + k^2 para |k| <= dmax (exato dentro da janela)."""
    h, w = sil.shape
    big = np.float32(dmax + 1)
    ys = np.arange(h, dtype=np.float32)[:, None]
    up = np.where(sil, ys, -1e9)
    up = np.maximum.accumulate(up, axis=0)
    dn = np.where(sil, ys, 1e9)
    dn = np.minimum.accumulate(dn[::-1], axis=0)[::-1]
    g = np.minimum(ys - up, dn - ys)
    g = np.minimum(g, big).astype(np.float32)
    g2 = g * g
    best = g2.copy()
    pad = np.full((h, w + 2 * dmax), big * big, np.float32)
    pad[:, dmax:dmax + w] = g2
    for k in range(1, dmax + 1):
        kk = np.float32(k * k)
        np.minimum(best, pad[:, dmax + k:dmax + k + w] + kk, out=best)
        np.minimum(best, pad[:, dmax - k:dmax - k + w] + kk, out=best)
    return np.sqrt(best)


def holes_mask(binary):
    """Regiões vazias que não tocam a borda da tela."""
    img = Image.fromarray(np.where(binary, 255, 0).astype(np.uint8))
    pad = Image.new("L", (S + 2, S + 2), 0)
    pad.paste(img, (1, 1))
    ImageDraw.floodfill(pad, (0, 0), 128)
    return np.asarray(pad, dtype=np.uint8)[1:-1, 1:-1] == 0


def halo(outline):
    """Halo v3 (13/11): borda branca de largura FIXA que acompanha a forma do
    cursor, como um cursor de alto contraste.

    - distância euclidiana exata na resolução mestre: a borda é um offset
      fiel da silhueta (sem fechamento, sem borrão, sem deformar cantos);
    - vãos fechados que sobram entre elementos (mão e seta ↕...) são tapados;
    - aberturas do próprio desenho (furo da engrenagem, miolo da lupa...)
      ficam vazadas, sem branco dentro."""
    sil = outline > 0.5
    design = holes_mask(sil)
    d = edt_near(sil)
    band = np.clip(HALO_R - d + 0.5, 0, 1)
    fade = np.clip(1 - (d - HALO_R) / HALO_FADE, 0, 1) ** 2 * 0.35
    g = np.maximum(band * 0.97, fade)
    # buracos pequenos entre elementos, cercados pelo halo: tapa
    covered = sil | (band > 0.5)
    gaps = holes_mask(covered) & ~design
    if gaps.any():
        lab = np.where(gaps, 0, 255).astype(np.uint8)
        done = np.zeros_like(gaps)
        for y, x in zip(*np.nonzero(gaps)):
            if done[y, x]:
                continue
            tmp = Image.fromarray(lab)
            ImageDraw.floodfill(tmp, (int(x), int(y)), 77)
            reg = np.asarray(tmp) == 77
            done |= reg
            if reg.sum() < 0.02 * S * S:
                g[reg] = 0.97
    g[design] = 0.0
    return g


def build(fn, glow, corner=False, fit=True):
    if corner and not fit:
        parts = fn() + [dart_part()]
    elif corner:
        # empurra o desenho até a borda dele ficar logo atrás da cunha do canto
        # (a diagonal se mapeia nela mesma, então a borda vai para c + e*kb;
        #  kb encolhe o desenho só o necessário para caber na tela)
        base = XF[:]
        XF[:] = [1.0, 0.0, 0.0]
        e = find_diag_edge(fn)
        union = np.zeros((S, S), np.float32)
        for p in fn():
            union = np.maximum(union, p["mask"])
        ys, xs = np.nonzero(union > 0.5)
        x0, x1, y0, y1 = xs.min() / S, xs.max() / S, ys.min() / S, ys.max() / S
        tau = DART_TIP[0] + DART_REACH * 0.7071
        lim = [1.0, (0.965 - tau) / max(1e-3, x1 - e), (0.965 - tau) / max(1e-3, y1 - e)]
        for lo in (x0, y0):
            if lo < e:
                lim.append((tau - 0.035) / (e - lo))
        kb = min(lim)
        c = tau - e * kb
        XF[:] = [base[0] * kb, base[1] + c * base[0], base[2] + c * base[0]]
        parts = fn()
        XF[:] = base
        parts = parts + [dart_part()]
    else:
        parts = fn()
    union = np.zeros((S, S), np.float32)
    for p in parts:
        union = np.maximum(union, p["mask"])
    outline = to_arr(to_img(union).filter(ImageFilter.MaxFilter(41)))
    ga = halo(outline) if glow else None
    rims = [None] + [to_arr(to_img(p["mask"]).filter(ImageFilter.MaxFilter(p["rimk"]))) for p in parts[1:]]
    return parts, outline, ga, rims


def ramp(tone, pal):
    stops = [hexrgb(c) for c in (pal[3], pal[2], pal[1], pal[0])]  # sombra, escuro, médio, claro
    xs = [0, 1 / 3, 2 / 3, 1]
    t = tone.ravel()
    ch = [np.interp(t, xs, [s[i] for s in stops]) for i in range(3)]
    return np.stack(ch, -1).reshape(S, S, 3).astype(np.float32)


def colorize(built, pal):
    parts, outline, ga, rims = built
    rgb = np.zeros((S, S, 3), np.float32)
    alpha = np.zeros((S, S), np.float32)
    if ga is not None:
        rgb = rgb * (1 - ga[..., None]) + 255.0 * ga[..., None]
        alpha = np.maximum(alpha, ga)
    oc = hexrgb(OUTLINE)
    rgb = rgb * (1 - outline[..., None]) + oc * outline[..., None]
    alpha = np.maximum(alpha, outline)
    for p, rim in zip(parts, rims):
        if rim is not None:
            rgb = rgb * (1 - rim[..., None]) + oc * rim[..., None]
        m = p["mask"][..., None]
        col = ramp(p["tone"], PALETTES[p["pal"]] if p["pal"] else pal)
        rgb = rgb * (1 - m) + col * m
        if p["spec"] is not None:
            em = p["spec"][..., None] * 0.55
            rgb = rgb * (1 - em) + np.array([255, 255, 245], np.float32) * em
    img = np.dstack([np.clip(rgb, 0, 255), np.clip(alpha, 0, 1) * 255]).astype(np.uint8)
    return Image.fromarray(img, "RGBA")


def premul_resize(im, size):
    a = np.asarray(im, dtype=np.float32)
    a[..., :3] *= a[..., 3:4] / 255.0
    small = Image.fromarray(a.astype(np.uint8), "RGBA").resize((size, size), Image.LANCZOS)
    b = np.asarray(small, dtype=np.float32)
    al = b[..., 3:4]
    b[..., :3] = np.where(al > 0, b[..., :3] * 255.0 / np.maximum(al, 1), 0)
    return Image.fromarray(np.clip(b, 0, 255).astype(np.uint8), "RGBA")


only = None
if "--only" in sys.argv:
    only = set(sys.argv[sys.argv.index("--only") + 1].split(","))

colors = None  # --colors dourado,roxo  (só para testes rápidos)
if "--colors" in sys.argv:
    colors = set(sys.argv[sys.argv.index("--colors") + 1].split(","))

manifest = {}
sheet = {}  # tipo -> {tag: img64}
for tname, (fn, hot, goff) in TYPES.items():
    if only and tname not in only:
        continue
    os.makedirs(os.path.join(OUT, tname), exist_ok=True)
    corner = hot in ("canto", "canto-fixo")
    fit = hot == "canto"
    if corner:
        hot = DART_TIP
    for glow in (False, True):
        XF[:] = [0.70, goff[0], goff[1]] if glow else [1.0, 0.0, 0.0]
        built = build(fn, glow, corner, fit)
        hx, hy = XF[1] + hot[0] * XF[0], XF[2] + hot[1] * XF[0]
        for cname, pal in PALETTES.items():
            if colors and cname not in colors:
                continue
            master = colorize(built, pal)
            tag = f"{cname}{'-brilho' if glow else ''}"
            for size in SIZES:
                img = premul_resize(master, size)
                rel = f"{tname}/gw2-{tname}-{tag}-{size}.png"
                img.save(os.path.join(OUT, rel), optimize=True)
                manifest[rel] = {"size": size, "hotspot": [min(size - 1, round(hx * size)), min(size - 1, round(hy * size))]}
                if size == 64:
                    sheet.setdefault(tname, {})[tag] = img
    print(tname, flush=True)

hp = os.path.join(OUT, "hotspots.json")
if only and os.path.exists(hp):
    old = json.load(open(hp, encoding="utf-8"))
    old.update(manifest)
    manifest = old
with open(hp, "w", encoding="utf-8") as f:
    json.dump(manifest, f, ensure_ascii=False, indent=1)

if "--sheet" in sys.argv:
    path = sys.argv[sys.argv.index("--sheet") + 1]
    tags = [c for c in PALETTES] + [c + "-brilho" for c in PALETTES]
    cell = 76
    W, H = 150 + cell * len(tags), cell * len(sheet) + 10
    bg = Image.new("RGBA", (W, H), (58, 74, 90, 255))
    d = ImageDraw.Draw(bg)
    for r, (tname, imgs) in enumerate(sheet.items()):
        y = 5 + r * cell
        d.text((8, y + 30), tname, fill=(255, 255, 255, 255))
        for i, tag in enumerate(tags):
            x = 150 + i * cell
            if i >= len(PALETTES):
                bg.paste((196, 186, 160, 255), (x, y, x + cell, y + cell))
            if tag in imgs:
                bg.alpha_composite(imgs[tag], (x + 6, y + 6))
    bg.save(path)
print(len(manifest), "arquivos")
