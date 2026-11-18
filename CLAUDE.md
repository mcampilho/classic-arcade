# Classic Arcade (PT: Arcade Clássico) — 18 jogos inspirados nos clássicos (Godot 4.7)

18 jogos originais inspirados em clássicos dos anos 70–90 (Pong, Breakout, Space
Invaders… Lemmings), cada um com três estilos visuais que partilham a mesma
jogabilidade. Todos os gráficos, sons e música são gerados em código — não há
ficheiros de imagem ou áudio. Builds para Windows, Linux, Android e Web
(GitHub Pages). `README.md` (inglês) e `README.pt.md` descrevem cada jogo,
estilos, controlos e regras — mantém os dois em sincronia ao mudar um jogo.

## Comandos

```bash
godot --path . -- --pong            # abre diretamente um jogo (qualquer "arg" de GAMES em core/main.gd)
godot --path . -- --pong --play --style=2   # já a jogar, com o 3.º estilo
godot --path . -- --lang=pt --mouse # forçar idioma; --mouse desliga o modo táctil
godot --path . -- --settings=user://dev.cfg # outro ficheiro de definições (não mexe nas do jogador)
godot --headless --path . -s res://tests/run_tests.gd   # testes (código de saída = n.º de falhas)
./build.sh [windows|linux|android|web|all|test]   # exportações locais para builds/ (precisa dos templates do Godot 4.7)
python3 i18n/build.py               # regenera i18n/strings.gd a partir de i18n/strings.json
```

Neste PC o Godot está em `E:\Portable\scoop\apps\godot\4.7.2\godot.console.exe`; o `python3`
do Scoop é `E:\Portable\scoop\shims\python3.exe` (o `python3` da Microsoft Store pode vir primeiro no PATH).

CI: `.github/workflows/builds.yml` corre os testes, confirma que `strings.gd` está em sincronia,
exporta as 4 plataformas a cada push para `main`, publica a versão Web no GitHub Pages e cria
Release nas tags `v*`.

## Arquitetura

- `core/main.gd` — lançador; a lista `GAMES` regista cada jogo (título, ano, arg, script).
- `core/game_shell.gd` (`GameShell`) — moldura comum: menu com demo, opções (`add_option`),
  estilos, pausa, fim de jogo/recorde (`show_result`, `show_players_result`), mensagens (`say`),
  botão de pausa tátil, botão "voltar" do Android, pausa ao perder o foco.
- `core/skin_base.gd` (`SkinBase`) — base de todos os estilos: vozes de áudio, sons em cache, `play()`.
- `core/` — também: `settings.gd` (`user://settings.cfg`, secção por jogo, valores validados),
  `i18n.gd`, `synth.gd` (síntese de som), `pixel_art.gd`, `pixel_font.gd`, `ui.gd`,
  `inspirations.gd` (rodapé "inspirado em" com história e link da Wikipédia).
- `games/<jogo>/` — padrão fixo:
  - `<jogo>_main.gd` — estende `GameShell`; só define opções, mensagens e o texto do fim de jogo.
  - `<jogo>_game.gd` — lógica e regras; emite sinais (toques, pontos, game over…).
  - `skins/<jogo>_skin.gd` — classe base do estilo (estende `SkinBase`; desenha em `_draw()`, sons em `_build_sfx()`).
  - `skins/*_skin.gd` — os três estilos (clássico da época, moderno/neon, estilo original).
- `i18n/strings.json` — `{"English text": ["português", "español"]}`; `strings.gd` é gerado.
- `tests/run_tests.gd` — testes sem extras (excluídos das exportações).

## Regras

- O inglês é o idioma de origem: o texto EN no código é a chave de tradução.
  Texto novo → acrescentar a `i18n/strings.json` (PT + ES) e correr `python3 i18n/build.py`.
  Nunca editar `i18n/strings.gd` à mão.
- Código, comentários e doc (`##`) em inglês; indentação com tabs (GDScript).
- Nada de assets externos: gráficos e áudio são gerados em código.
- Regras de jogo fiéis ao original; sprites e nomes originais (não copiar os dos clássicos).
- Renderer GL Compatibility, viewport 1280×720, stretch `canvas_items`.
- Correr os testes depois de mudar um jogo; um jogo novo entra nos testes ao ser registado em `GAMES`.

## Git / atenção

Remote `git@github.com:mcampilho/classic-arcade.git` (antes `classic-games`), ramo `main`.
GitHub Pages: https://mcampilho.github.io/classic-arcade/
- Executáveis `ClassicArcade.*`; pacote Android `io.github.mcampilho.classicarcade`.
- Presets do editor, `build.sh` e CI exportam todos para `builds/` (ignorado pelo git):
  nunca versionar binários exportados. O histórico ainda tem ~280 MB de binários antigos.
