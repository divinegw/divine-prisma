# gw2-facetado

Cursores facetados para **Guild Wars 2**, feitos para o addon **Custom Cursors** do Nexus.
*Faceted cursors for Guild Wars 2, made for the Custom Cursors Nexus addon. [English below](#english).*

![Prévia: 21 desenhos em 7 cores; à direita, a versão com brilho](docs/previa.png)

- **21 desenhos:** seta, seta dupla, conversar, engrenagem, lupa, martelo, girar, alvo, mira, alvo de área, 4 mãos, 4 setas de redimensionar, reciclar perto/longe e reviver.
- **7 cores:** roxo, ciano, dourado, prata, rosa, verde e vermelho. Todas têm versão normal e versão com **brilho** (borda branca, como o cursor de alto contraste do jogo).
- **5 tamanhos:** 32, 48, 64, 96 e 128 px, cada um com o seu ponto de clique.
- O desenho é original, feito por código no estilo metálico dos cursores do jogo. O pacote não usa arquivos de terceiros.

## Download

Pegue os arquivos na página [**Releases**](../../releases/latest):

| Arquivo | Para quem |
|---|---|
| `gw2-facetado-kit.zip` | Quem usa o **Nexus** com o **Custom Cursors**. Traz o instalador, a instalação manual e o pacote de PNGs. |
| `gw2-facetado-cur.zip` | **YoloMouse** e outros programas que leem `.cur`. Uma pasta por cor, e cada `.cur` traz os 5 tamanhos. |
| `SHA256.txt` | Os hashes dos ZIPs, para conferir o download. |

## Instalação (Nexus e Custom Cursors)

**Antes de instalar:**
1. Instale o [Nexus](https://raidcore.gg/Nexus).
2. Na biblioteca de addons do Nexus, instale o **Custom Cursors** (jordanrye).
3. Abra o jogo uma vez e feche. Isso cria o `settings.json` do addon.

**Com o instalador (recomendado):**
1. Extraia o `gw2-facetado-kit.zip` inteiro.
2. Com o jogo **fechado**, dê dois cliques em `Instalar - <Cor>.bat`, por exemplo `Instalar - Verde.bat`.
3. Confirme a pasta do jogo, escolha o tamanho (Enter = 48) e confirme.

O instalador:
- mostra a lista do que vai mudar antes de aplicar;
- faz backup do `settings.json` (`settings.json.backup-gw2-facetado-<data>`);
- copia o pacote para `addons\CustomCursors\cursors\gw2-facetado`;
- troca **só** os 34 cursores conhecidos, sem mexer nos outros cursores nem nas opções do addon.

Para trocar de cor ou de tamanho, rode outro `Instalar`. Para desfazer, use `Desinstalar.bat`: ele volta esses cursores ao padrão do jogo e pergunta se deve apagar a pasta do pacote.

**Sem script (manual, 48 px):**
1. Copie a pasta `gw2-facetado` do ZIP para `addons\CustomCursors\cursors\`.
2. Copie `manual\<Cor>\settings.json` para `addons\CustomCursors\`. **Atenção:** isso substitui o arquivo inteiro. Se você já tinha cursores configurados no addon, guarde o seu antes.

Os desenhos que o mapa não usa (seta dupla, martelo, girar, alvo, alvo de área, mão de apontar) ficam na pasta do pacote. Dá para escolhê-los no menu do Custom Cursors, dentro do jogo. Os pontos de clique estão em `gw2-facetado\hotspots.json`.

## Quais cursores mudam

O jogo usa ids diferentes para o mesmo cursor no contraste normal e no contraste alto (com halo). O mapa cobre os dois modos:

| Cursor do jogo | Desenho | Contraste normal | Contraste alto (halo) |
|---|---|---|---|
| Seta padrão / sobre link do chat | seta, na cor escolhida | 2876413485, 2359510116 | 2876413485, 3482162487, 2154574276 |
| Inimigo | seta **vermelha fixa** | 2681826372 | 2681826372, 2692527230 |
| Aliado | seta **verde fixa** | 1391593731 | — |
| Conversar | fala | 204507100 | 2733722094 |
| Interagir (prata e dourada) | engrenagem | 1904910409, 3176363084 | 3611259902, 774285540 |
| Pegar / agarrar / ajustar | mão aberta / fechada / ajuste | 3536603594, 3872050656 / 2147607764 / 161721809 | 3667960659 |
| Reviver | reviver | 3588320565, 4085153991 | 323847572 |
| Mira | mira | 1020886200, 2123062382 | — |
| Zoom | lupa | 1282737976, 3685266938 | — |
| Reciclar perto / longe | craft-perto / craft-longe | 2115911978 / 3060132843 | — |
| Redimensionar ↔ ↕ ⤡ ⤢ | redim-h / v / diag1 / diag2 | 2449019715, 622306980, 2060294237, 1577035093 | 1887523809, 3711244257, 2953070793 |

No contraste alto, os cursores usam a versão **com brilho** da cor. O mapa completo, com uma nota para cada id, está em [`kit/_instalador/mapa.json`](kit/_instalador/mapa.json).

> Os ids do contraste normal vêm da lista *Current Known IDs*, publicada por clollipops no Discord do Raidcore. Os do contraste alto foram anotados no jogo. Se algum cursor não mudar, ou trocar pelo desenho errado, abra uma [issue](../../issues) com o id que aparece no menu do Custom Cursors.

## É seguro?

- **Não há nenhum `.exe`.** Cada `.bat` tem uma linha só, que chama os scripts de [`kit/_instalador`](kit/_instalador). Eles são texto puro e dá para ler antes de rodar.
- Os scripts **não usam internet**, não pedem administrador e só mexem em `addons\CustomCursors\settings.json` (com backup) e na pasta `addons\CustomCursors\cursors\gw2-facetado`.
- O `.bat` usa `-ExecutionPolicy Bypass` porque o Windows bloqueia scripts baixados da internet. A opção vale só para esse script, nessa execução.
- Para conferir o download, compare o resultado com o `SHA256.txt` da release:
  ```
  certutil -hashfile gw2-facetado-kit.zip SHA256
  ```
- Addons são de terceiros. A ArenaNet não revisa nem aprova nenhum, e cada um usa por sua conta ([política](https://help.guildwars2.com/hc/en-us/articles/360013625034-Policy-Third-Party-Programs)). Este pacote só troca a aparência do cursor.

## Avisos

- O Custom Cursors pode mostrar um aviso quando nem todos os cursores do jogo têm arquivo definido ([issue #4 do addon](https://github.com/jordanrye/nexus-custom-cursors/issues/4)). É só um aviso.
- O instalador também grava os cursores que o jogo ainda não mostrou no seu PC. Ainda falta confirmar se o addon usa essas entradas quando o cursor aparece pela primeira vez. Se algum não mudar, rode o `Instalar` de novo depois de ver esse cursor no jogo.
- O pacote para YoloMouse (`.cur`) foi conferido pela API do Windows, mas ainda **não foi testado dentro do YoloMouse**.

## Para quem quer mexer no código

Requer Python 3 com Pillow e NumPy.

| Script | O que faz |
|---|---|
| `scripts/gw2_cursors.py <saida> [--sheet previa.png] [--only tipos]` | Gera os PNGs, o `hotspots.json` e a prévia. |
| `scripts/gw2_cursors_audit_halo.py <pacote> <saida.png>` | Mede a largura da borda de brilho. |
| `scripts/gw2_cursors_to_cur.py <pacote> <saida>` | Converte o pacote em `.cur` multitamanho, organizado por cor. |
| `scripts/gw2_cursors_check_cur.py <saida>` | Carrega cada `.cur` pela API do Windows e confere o tamanho e o ponto de clique. |
| `scripts/gw2_cursors_build_kit.py <pacote> kit <dist>` | Monta o kit, os `settings.json` manuais, os ZIPs e os hashes. |

## Licença

- **Desenhos** (PNG, `.cur` e a prévia): [CC BY-NC 4.0](https://creativecommons.org/licenses/by-nc/4.0/deed.pt-br). Você pode usar, modificar e redistribuir, desde que dê crédito e não venda.
- **Scripts** (`scripts/` e `kit/_instalador/`): MIT.

O texto completo está em [LICENSE](LICENSE).

Não é afiliado à ArenaNet, à NCSOFT nem ao autor do Custom Cursors. Guild Wars 2 é marca da ArenaNet/NCSOFT.

---

## English

Faceted cursors for **Guild Wars 2**, made for the **Custom Cursors** Nexus addon.
- 21 drawings in 7 colours (*roxo* purple, *ciano* cyan, *dourado* gold, *prata* silver, *rosa* pink, *verde* green, *vermelho* red).
- Each drawing comes plain and with **glow** (*brilho*, a white outline like the game's high-contrast cursor).
- 5 sizes (32 to 128 px).
- Original artwork, generated by code. No third-party files.

**Download** from [Releases](../../releases/latest):
- `gw2-facetado-kit.zip`: installer and pack for Nexus + Custom Cursors.
- `gw2-facetado-cur.zip`: `.cur` files for YoloMouse and similar tools, one folder per colour, 5 sizes per file.

**Install:**
1. Install [Nexus](https://raidcore.gg/Nexus) and the **Custom Cursors** addon from its library.
2. Start the game once, then close it.
3. Extract the ZIP and, with the game **closed**, double-click `Instalar - <Colour>.bat` (*Instalar* = install).

The installer:
- shows what will change before applying it;
- backs up `settings.json`;
- changes only the 34 known cursor ids, covering both normal and high-contrast modes. The enemy arrow stays red and the ally arrow green.

`Desinstalar.bat` (*uninstall*) resets those cursors. To install without running a script, copy the pack folder and `manual\<Colour>\settings.json`; this replaces your whole `settings.json`.

**Safety:**
- There is no `.exe`. Each `.bat` is a single line, and the PowerShell scripts in [`kit/_instalador`](kit/_instalador) are plain text you can read first.
- The scripts make no network access and need no admin rights. They only touch `addons\CustomCursors\settings.json` (backed up) and the pack folder.
- Check the ZIP against `SHA256.txt`.

Normal-contrast ids come from the *Current Known IDs* list by clollipops on the Raidcore Discord. If a cursor doesn't change or shows the wrong drawing, please open an [issue](../../issues) with the id shown in the Custom Cursors menu.

**License:**
- Artwork: [CC BY-NC 4.0](https://creativecommons.org/licenses/by-nc/4.0/). Share and modify with credit, no commercial use.
- Scripts: MIT.
- Full text in [LICENSE](LICENSE).

Not affiliated with ArenaNet, NCSOFT or the author of Custom Cursors.
