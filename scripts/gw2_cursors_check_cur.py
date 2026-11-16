"""Confere os .cur gerados carregando cada um pela API do Windows.

Para cada arquivo e cada tamanho: LoadImageW(LR_LOADFROMFILE) tem que dar
certo, o bitmap tem que ter o tamanho pedido e o ponto de clique devolvido
por GetIconInfo tem que bater com hotspots-cur.json.

uso: python gw2_cursors_check_cur.py <pasta_dos_cur>
"""
import ctypes, json, os, sys
from ctypes import wintypes as W

OUT = sys.argv[1]
u32, g32 = ctypes.windll.user32, ctypes.windll.gdi32


class ICONINFO(ctypes.Structure):
    _fields_ = [("fIcon", W.BOOL), ("xHotspot", W.DWORD), ("yHotspot", W.DWORD),
                ("hbmMask", W.HBITMAP), ("hbmColor", W.HBITMAP)]


class BITMAP(ctypes.Structure):
    _fields_ = [("bmType", W.LONG), ("bmWidth", W.LONG), ("bmHeight", W.LONG),
                ("bmWidthBytes", W.LONG), ("bmPlanes", W.WORD), ("bmBitsPixel", W.WORD),
                ("bmBits", ctypes.c_void_p)]


u32.LoadImageW.restype = W.HANDLE
u32.LoadImageW.argtypes = [W.HINSTANCE, W.LPCWSTR, W.UINT, ctypes.c_int, ctypes.c_int, W.UINT]
u32.GetIconInfo.argtypes = [W.HANDLE, ctypes.POINTER(ICONINFO)]
u32.DestroyCursor.argtypes = [W.HANDLE]
g32.GetObjectW.argtypes = [W.HANDLE, ctypes.c_int, ctypes.c_void_p]
g32.DeleteObject.argtypes = [W.HANDLE]
IMAGE_CURSOR, LR_LOADFROMFILE = 2, 0x10

man = json.load(open(os.path.join(OUT, "hotspots-cur.json"), encoding="utf-8"))
falhas, ok = [], 0
for rel, sizes in man.items():
    path = os.path.join(OUT, *rel.split("/"))
    for s, (hx, hy) in sizes.items():
        s = int(s)
        h = u32.LoadImageW(None, path, IMAGE_CURSOR, s, s, LR_LOADFROMFILE)
        if not h:
            falhas.append(f"{rel} {s}: não carregou")
            continue
        ii = ICONINFO()
        u32.GetIconInfo(h, ctypes.byref(ii))
        bm = BITMAP()
        g32.GetObjectW(ii.hbmColor or ii.hbmMask, ctypes.sizeof(bm), ctypes.byref(bm))
        if (bm.bmWidth, ii.xHotspot, ii.yHotspot) != (s, hx, hy):
            falhas.append(f"{rel} {s}: largura {bm.bmWidth}, clique {ii.xHotspot},{ii.yHotspot} (esperado {hx},{hy})")
        else:
            ok += 1
        for b in (ii.hbmMask, ii.hbmColor):
            if b:
                g32.DeleteObject(b)
        u32.DestroyCursor(h)

print(f"{len(man)} arquivos, {ok} tamanhos ok, {len(falhas)} falhas")
for f in falhas[:30]:
    print(" ", f)
sys.exit(1 if falhas else 0)
