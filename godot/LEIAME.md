# The Curse of Vallack — versão Godot (Android)

Porte do jogo do GameMaker para o **Godot 4.7** (2D, renderizador Compatibility),
**exclusivo para o Android** (celular, controles de toque). A lógica de cada objeto
do GameMaker foi traduzida para GDScript em `src/objects/`, sobre uma pequena camada
que imita o GameMaker (`src/core/`).

> **Plataformas são independentes:** este projeto Godot é só o mobile. A versão de
> **PC é o projeto GameMaker** (pasta acima desta). Cada pedido de mudança é feito
> separadamente na plataforma a que se refere.

## Abertura e créditos
- Ao abrir o jogo: vídeo da **GAMBITECH STUDIO** (`assets/video/intro_estudio.ogv`,
  passa inteiro, não dá para pular) → aviso de jogo fictício → título → menu.
- Os nomes da equipe passam nos **créditos do fim da demo**, depois de
  "Obrigado por jogar nossa Demo." (e também depois do "CONTINUA..." da fase 2).
  O texto dos créditos fica em `Lib.creditos_lista()` (`src/core/lib.gd`).
- Para trocar o vídeo: o Godot só toca **.ogv** (Theora). Converta o vídeo novo para
  .ogv e substitua o arquivo com o mesmo nome.

## Abrir e testar no computador (desenvolvimento)
1. Abra o Godot 4.7 e importe a pasta `godot/` (arquivo `project.godot`).
2. Aperte F5 para testar o mobile na janela (teclado, controle e mouse ajudam nos testes;
   o jogo é distribuído só como APK).

## Gerar o APK
- No editor: **Projeto > Exportar > Android > Exportar Projeto** (o preset já está pronto:
  arm64-v8a, pacote `com.fapan.thecurseofvallack`, assinado com a chave de debug).
- Pela linha de comando (na pasta `godot/`):

```bash
godot --headless --export-debug "Android" ../build/TheCurseOfVallack.apk
```

Instalar no celular (com a depuração USB ligada):

```bash
adb install -r ../build/TheCurseOfVallack.apk
```

Para publicar na Play Store é preciso uma chave de release própria (Projeto > Exportar >
Android > Keystore > Release) e exportar com `--export-release`.

## Controles no celular
- Estilo Castlevania: **analógico + 4 botões** (▼ + PULO desce de passarelas e ilhas). Esquerda:
  analógico que nasce onde o polegar toca. Direita: ATAQUE, PESADO, PULO e ESQ · DEF.
  - ▼ + ATAQUE = rasteira · ▲ + ATAQUE = sub-arma (lâmina bumerangue)
  - ▼ + PESADO = chama de Sylla · ▲ + PESADO = lançador
  - ESQ · DEF com ◄ ► rola, com ▼ salta para trás; sem seta defende (segurar) e
    apara (apertar na hora do golpe)
  - Só aparecem quando servem: MAGIA (depois de liberada; ▲ / ▼ trocam a magia),
    FÚRIA (barra cheia) e AÇÃO (ABRIR baú, SALVAR no cristal, EXECUTAR inimigo marcado).
  - Nos diálogos e cenas o botão do canto se chama **PULAR**; nos menus, VOLTAR.
  - O mapeamento fica em `touch_controls.gd` (`_efetiva`).
- HUD em **moldura gótica** (estilo Castlevania): brasão com o retrato do herói (o
  número na joia é o nível da espada) sobre uma placa de ferro com moldura dourada,
  vida em gomos, magia e fúria; ao lado, o **quadro da sub-arma** (Lâmina Bumerangue,
  ou a Chama de Sylla quando agachado) com o contador de essência; orbs embaixo. No
  topo, o objetivo com uma bússola. A **barra do chefe** fica embaixo, entre o
  analógico e os botões. A arte fica em `assets/ui/` (SVG).
- **Baú**: perto dele o botão AÇÃO vira um botão **ABRIR** grande e pulsando, e uma
  placa ABRIR aparece sobre o baú; longe, volta a ser a AÇÃO / sub-arma.
- Topo direito: pausa e ARMAS. Nos menus: toque nas opções e use **VOLTAR**
  (o botão voltar do Android também funciona).
- O jogo pausa sozinho quando o app vai para o fundo.
- Em OPÇÕES: tamanho e opacidade dos botões de toque, vibração, 30/60 FPS e qualidade.
- No celular o jogo começa em **30 FPS** (estável em aparelhos simples; testado num
  Redmi Note 14S). Em celulares mais fortes, OPÇÕES > TAXA DE QUADROS > 60.

## Instalar em celulares Xiaomi / Redmi / POCO
O HyperOS bloqueia instalações pelo cabo ("Instalação via USB bloqueada"). Em
Opções do desenvolvedor, ligue **Instalar via USB** e **Depuração USB (Configurações
de segurança)**; se ainda aparecer a notificação "Bloquear instalação", libere por ela.

## Medir desempenho no aparelho
Crie o arquivo `perf.ligado` na pasta de dados do app e o jogo escreve no log
(`adb logcat -s godot`) o tempo gasto por objeto a cada 4 segundos:

```bash
adb shell run-as com.fapan.thecurseofvallack touch files/perf.ligado
```

## Estrutura
| Pasta | Conteúdo |
|---|---|
| `src/core/g.gd` | o "motor": laço fixo de 60 passos/s, instâncias, salas, colisão, entrada, áudio |
| `src/core/pen.gd` | desenho no estilo GameMaker sobre o RenderingServer |
| `src/core/lib_base.gd`, `lib.gd` | os scripts do GameMaker (scr_*) |
| `src/core/touch_controls.gd` | controles de toque |
| `src/objects/` | um arquivo por objeto do GameMaker |
| `assets/sprites`, `assets/rooms`, `assets/data` | sprites, salas e arquivos incluídos, convertidos do projeto original |

## Visual
- **Cenário da Fase 1 desenhado por código** (no lugar da pintura de fundo): a
  ferramenta `ferramentas/GeraCenario.cs` (raiz do projeto, rodada por
  `powershell -File ferramentas/gerar_cenario.ps1`) desenha em pixel art casas em
  enxaimel (inteiras, em chamas e queimadas), igreja com vitrais, torre de vigia,
  barracas, poço, lampiões, árvores, pinheiros, a árvore anciã da praça do chefe,
  ponte, muro, cerca, sebe e chão, mais as faixas distantes (montanhas, floresta,
  vila ao longe e nuvens). Ela grava `assets/data/cenario_fase1.png` (atlas) e
  `cenario_fase1.json` (peças, âncoras de chaminés, fogo, janelas e luzes, e a
  disposição da fase) aqui e em `datafiles/` do PC. O `obj_vila` monta tudo em
  duas camadas: "longe" (céu, lua e faixas com profundidade) e "perto" (a vila,
  com o fogo da maldição nos telhados, a fumaça saindo das chaminés, as janelas
  tremeluzindo e os halos das luzes presos a cada peça). Depois de gerar de novo,
  rode `--import` no Godot.
- **Arte da equipe (v1.13)**: o herói, o Homem-Porco e a Mulher-Aranha em HD (Alex),
  o esqueleto arqueiro, a Árvore Amaldiçoada, a árvore assombrada e os matos/plantas
  (Eduardo) entram pelo importador `ferramentas/importar_arte.ps1` (raiz do projeto;
  as folhas originais ficam em `ferramentas/_arte_equipe/`). Ele corta cada folha
  entre os corpos (os rastros de luz que invadem a pose vizinha ficam no seu quadro),
  usa a MESMA escala em todas as animações de um personagem (medida pelo rosto do
  herói em cada folha), alinha os pés e o centro do corpo de todos os quadros e grava
  nas duas versões (GameMaker e `assets/sprites` + `sprites.json`, com a escala HD "k").
  A quantidade de quadros segue a tabela de golpes e a IA. Para refazer:
  `powershell -File ferramentas/importar_arte.ps1` (depois `--import` no Godot).
- **Fase 1 em andares** (inspirada nas referências da equipe, `Lib.terreno_dados`, a
  mesma tabela da versão PC): escadarias de madeira que se sobem andando (degraus de
  8 px), passarelas e ilhas de terra de **mão única** (`obj_plataforma`: sobe-se
  pulando por baixo, desce-se com ▼ + PULO), um andaime alto com caixotes de orbs, a
  torre de vigia do arqueiro e ilhas sobre os abismos e os espinhos. As ilhas usam as
  peças do Alex (`ferramentas/gerar_pecas.ps1` → `assets/data/pecas_fase1.*`). Os
  pedaços de castelo que ficavam espalhados pela vila (muralhas, torres, colunas,
  portões em arco) saem da fase, e o fundo tem **três fileiras de casas**, quase todas
  em chamas. A fase 2 usa o salão do Castelo do Alex em alta resolução
  (`assets/data/castelo_a/b.png`).
- **Sprites de personagens, inimigos e boss** passam por um tratamento automático:
  contorno escuro, limpeza da borda, nitidez/contraste/saturação e suavização dos
  quadros que eram muito "quadriculados"; na corrida do herói foi retirada a perna
  fantasma semitransparente. Os originais ficam em `_originais/` (o Godot ignora).
  Para refazer (por exemplo depois de trocar um sprite original):
  `powershell -File ferramentas/processar_sprites.ps1` (parâmetros por família no script).
- **Pós-processamento** só no cenário (contraste, cor, vinheta), desligado na
  qualidade BAIXA (`G._criar_pos`).
- **Efeitos de batalha**: corte de luz e onda de choque em cada acerto (`obj_fx`,
  tipo `corte`), rastro da espada com brilho; **clima de guerra** (`obj_guerra`):
  flechas incendiárias e catapultas ao fundo, brasas e cinzas na frente.
- Menus e painéis no estilo ornamentado dourado/carmesim (`desenhar_painel`).
- Câmera: o "olhar à frente" desliza suavemente ao trocar de direção (antes a tela
  pulava e o herói parecia se teletransportar para trás).
- **Impacto e peso** (combate mais intenso): pausa de impacto maior nos golpes
  pesados, a câmera leva um "chute" na direção da pancada (`camera_empurrar`) e volta
  depois da pausa; o herói apanhando também empurra a tela. **Golpe fatal**
  (`golpe_fatal`): ao derrotar um monstro o tempo para, desacelera (com intervalo,
  para não arrastar as hordas) e o corpo explode em chamas como no Castlevania
  (`obj_fx`, tipo `chamas_morte`). A fumaça roxa dos corpos ficou discreta
  (poucos sopros pequenos).
- **Abismos e plataformas** (`obj_terreno`, dados em `Lib.terreno_dados`, a mesma
  tabela da versão PC): o chão é cortado nos vãos e quem cai morre (o monstro some
  e conta como derrotado). Fase 1: 2 abismos e andaimes de madeira sobre os
  espinhos; fase 2: 3 abismos e lajes de pedra presas por correntes. Vãos de até
  ~120 px e plataformas 88 px acima do chão (o pulo cheio sobe ~98; segure o PULO).
- HUD: a faixa do objetivo aparece quando ele muda (7 s) e some.
- **Dificuldade (v1.13)**: os 4 níveis ficaram bem separados e o combate mais intenso
  (`LibBase.dif_*`, a mesma tabela da versão PC). Cada nível muda a vida (0,6x a 2,1x),
  o dano (0,45x a 1,8x), a espera entre golpes, a velocidade, quantos atacam juntos
  (1 a 4) e QUAIS golpes cada inimigo usa (`dif_golpe_liberado`): no FÁCIL só o golpe
  básico; do MÉDIO em diante o salto da besta, a onda roxa do porco e a teia da aranha;
  no DIFÍCIL a fúria do porco (invoca esqueletos) e 2 flechas do arqueiro; no EXTREMO 3
  flechas em leque. O nível do inimigo no mapa (Nv 1-5) sobe mais forte nos níveis
  altos, então a fase 2 aperta mais; a besta, o escudeiro e o arqueiro também sobem.
- Câmera mais perto do herói (`CAMERA_ALTURA` 280) e cores menos cartum no
  pós-processamento (roxo neon apagado, saturação menor, curva de filme).
- **Virar de lado e hitbox (v1.14)**: o `Pen` espelha como o GameMaker (`Pen._ret`).
  Com tamanho negativo, o Godot espelha a textura mas desenha a partir da posição
  dada; antes, todo sprite virado para a esquerda saía deslocado a largura inteira do
  desenho. O herói e os inimigos "teletransportavam" ao virar, e os inimigos ficavam
  longe da própria caixa de colisão. Todo retângulo novo com tamanho que pode ser
  negativo passa por `Pen._ret`. O andar obedece ao `velh` (`velh_para`): acelera,
  freia e, para virar, passa pelo zero. Os inimigos viram com um instante de reação
  (`inimigo_virar`). A origem de cada animação fica no tronco MÉDIO dos quadros
  (importador). As máscaras da aranha (42x64) e da besta (32x68) cobrem o corpo
  desenhado. O aviso da placa sobe acima da cabeça do herói em vez de cobri-lo, e o
  desenho da escadaria acompanha o degrau que o herói pisa.
- **Menu épico (v1.14, igual na versão PC)**: uma cena de cinema atrás do menu
  (`obj_menu._desenhar_cena`): a Árvore Amaldiçoada gigante no horizonte em chamas, o
  herói em silhueta recortado pela luz do fogo, névoa, cinzas caindo, brasas subindo e
  faixas pretas de cinema. Depois da abertura vem "PRESSIONE QUALQUER BOTÃO" (ou "TOQUE
  NA TELA"). A logo e as opções ficam numa coluna à esquerda, e a opção escolhida ganha
  uma lâmina de luz vermelha e um losango em brasa (`menu_caixa` = área de toque).
- **O reino arrasado (v1.14)**: o gerador do cenário (`GeraCenario.cs`) desenha casas
  destruídas (`casa_x1`..`x7`): só o térreo de pé com postes carbonizados, telhado
  desabado em "V", empena furada sobre os escombros e montes de entulho com brasas.
  Há uma quarta fileira ao fundo (plano 3, a mais escura), mais ruínas nas outras
  fileiras e algumas casas da frente desabadas, abrindo a vista. A cidade ao longe tem
  casas sem telhado, incêndios brilhando e colunas de fumaça subindo
  (`obj_vila._incendios_longe`).
- **Desempenho no celular (v1.14, `src/core/desempenho.gd`)**: perfis MÍNIMO, LEVE,
  EQUILIBRADO, MÁXIMO e AUTOMÁTICO (o padrão), em OPÇÕES > DESEMPENHO.
  - Os níveis: MÍNIMO e LEVE usam qualidade baixa, 30 FPS e resolução reduzida (o jogo
    é desenhado em 720p e ampliado para a tela, o que alivia a placa de vídeo). O
    MÍNIMO também tira as fileiras do fundo e os incêndios ao longe. EQUILIBRADO usa
    qualidade média a 30 FPS. MÁXIMO usa qualidade alta a 60 FPS.
  - O AUTOMÁTICO escolhe o nível pela ficha do aparelho (placa de vídeo, núcleos e
    memória) na primeira vez. Durante as fases ele mede o FPS a cada 4 s: desce um
    nível depois de 8 s abaixo do alvo e sobe se o processamento couber com folga no
    nível de cima por 20 s. Não volta a subir para um nível de onde já desceu, e salva
    o nível em `config.ini` (`nivel_auto`).
  - Mexer em QUALIDADE, TAXA DE QUADROS ou RESOLUÇÃO muda o perfil para PERSONALIZADO.
    A medição só roda no celular; o log mostra as linhas `[desempenho]`.
- **Menu inicial (v1.15, igual na versão PC)**: a mesma composição dos menus épicos de
  ação feita com a arte do jogo.
  - No alto, à esquerda, a logo sobre uma pincelada de sangue (`mancha_sangue.png`).
  - Logo abaixo, a lista curta: a opção escolhida em pergaminho claro, as outras em
    vermelho-sangue.
  - À direita, o busto de Twilight em close (`heroi_retrato.png`, recortado da arte HD
    da equipe e olhando para o menu), sob um céu de tempestade com a luz rompendo as
    nuvens.
  - No canto, "✕ = SELECIONAR".
  - As duas imagens saem de `ferramentas/gerar_menu.ps1` (`GeraMenu.cs`).
- **Fase 1 com caminhos de escalar (v1.15)**, nos dados de `Lib.terreno_dados`:
  - `escalar`: escadas de mão, cordas e correntes. PULO ou cima segurado perto agarra e
    sobe; ▼ desce; PULO + lado salta para fora. No alto, o herói passa para a
    plataforma; um golpe o derruba.
  - `pontes_corda`: uma ponte de corda sobre o primeiro abismo.
  - `suspensas`: plataformas penduradas por cordas sob o forte e numa forca sobre o
    segundo abismo.
- **Portão trancado e a chave (v1.15)**:
  - No meio da fase há um portão de paliçada (`obj_portao_trancado`). Chegando sem a
    chave, aparece "ACHE A CHAVE DO PORTÃO" e o objetivo vira "suba ao forte de madeira".
  - A chave está num baú selado no alto do forte, que se alcança pela escada de mão,
    pelas plataformas penduradas e pela corda.
  - Ao pisar no forte, surgem os guardiões (2 no FÁCIL, 3 nos outros níveis), presos à
    área do forte. Derrotados, o selo do baú se quebra, a chave voa até o herói (fica
    no HUD) e o portão abre. Tudo fica no save.
- **Inimigos espalhados (v1.15)**: antes vinham em bandos de 3 a 5; agora ficam
  distribuídos pela fase (`mover`), também em cima das plataformas, fora das arenas dos
  chefes.
- **Rastro mágico da espada (v1.15)**: o arco ganhou uma aura de magia carmesim e solta
  faíscas douradas e brasas que voam, caem e somem (`faiscas_espada`; menos na
  qualidade baixa).
- **Trilha sonora (v1.16, igual na versão PC)**: as cinco músicas da pasta "Trilha sonora"
  viraram `bgm_main_menu`, `bgm_loading_screen`, `bgm_battle_phase1`, `bgm_mini_boss` e
  `bgm_final_boss_phase1` (OGG em `assets/data`).
  - `ferramentas/converter_trilha.ps1` (`GeraTrilha.cs`, com o ffmpeg do GameMaker) tira o
    silêncio e o fade-out final, fecha o loop (os últimos 4 s se misturam ao começo, sem
    corte) e iguala o volume em -14 LUFS.
  - Gatilhos: menu → `bgm_main_menu`; carregamento → `bgm_loading_screen`; a fase 1
    começa → `bgm_battle_phase1` (a fase 2 segue com `mus_fase`); arena do Carrasco →
    `bgm_mini_boss` e, vencido, de volta à batalha; a Árvore desperta →
    `bgm_final_boss_phase1`; a Árvore derrotada → a música some (fade-out de 2,5 s);
    resultado e créditos → `bgm_main_menu`. Toda troca tem fade de 1,5 s.
  - `sfx_important_message` (impacto metálico grave, sintetizado): toca nos avisos da
    tela, quando o objetivo muda, na barreira do guardião e quando o pergaminho do COMO
    JOGAR abre. Avisos de sistema (jogo salvo, checkpoint, controle, desempenho) ficam
    sem som.
  - Golpe de espada: os cortes já variam o tom em ±0,05. Se um `sfx_sword_slash.ogg` for
    colocado em `assets/data` (e em `datafiles` no PC), ele vira o som dos cortes.
  - As trilhas antigas `mus_menu`, `mus_carregamento` e `mus_boss` não vão mais para o APK.
- **v1.17 (igual na versão PC)**
  - **Mapa das 18 fases** (`obj_mapa`, foto de cada fase em `mapa_fases.jpg`): só a fase 1
    está liberada; as outras têm cadeado e "EM DESENVOLVIMENTO"; o dragão voa ao lado da
    última. **Perfil e conquistas** (`obj_perfil`, `perfil.ini`): o nome de quem joga
    aparece só nas conquistas; recompensas em orbs, títulos e 6 estilos de lâmina.
  - **Sequência de golpes** (`obj_qte`): o Carrasco e a Árvore só caem acertando a
    sequência; errou, o chefe empurra e volta a atacar. A curva sobe com a dificuldade
    (`V117.qte_parametros`: 3 a 8 botões, de 100 a 50 quadros cada).
  - **Animações da equipe** (`ferramentas/importar_folhas.ps1`, na raiz, lê as folhas
    `ferramentas/_folhas_v117/*.jpg`): recorta cada quadro, tira o fundo e o número, iguala a
    escala (0,70) e alinha os quadros numa tela comum. Escada: `spr_player_subindo_escada` /
    `descendo_escada` (de costas); corda e corrente: `pular_e_agarrar_cordas` e depois
    `segurando_e_subindo_cordas`. QUADRADO: 1 toque `ataque_rapido`, 2º `ataque_duplo`,
    3º `ataque_triplo` e o 4º solta o `ataque_frenetico` inteiro (combo LÂMINA DE VALLACK).
  - **Espada em chamas**: a lâmina de cada quadro está medida (`src/core/lamina_dados.gd`,
    gerado por `ferramentas/gerar_lamina.ps1`); nos quadros de corte o rastro de fogo segue o
    caminho real da lâmina e solta línguas de fogo e brasas; o acerto explode em fogo
    (`explosao_fogo`). As cores seguem o estilo de lâmina do perfil.
  - **Sem mancha preta**: o inimigo derrotado agora arde em brasa e se desfaz em chamas
    (`chamas_corpo` / `chamas_estouro`); antes virava uma silhueta negra com fumaça preta.
  - Carregamento das fases em 30 s com dicas de combos; menu com tochas, braseiros e
    faíscas que seguem o dedo; dificuldades niveladas (`dif_*` com degraus mais suaves).
## Ferramentas de teste (não vão para o APK)
- Checar se todos os scripts compilam:
  `godot --headless --path godot res://src/tools/checar.tscn -- checar`
- Roteiros automáticos com capturas de tela (usam saves separados, `teste_*.ini`):
  `godot --path godot -- teste=jogo shots=C:/caminho/prints`
  (roteiros: `intro`, `intro_pular`, `jogo`, `toque`, `menus`, `corrida`, `virar`, `chefe`,
  `fase2`, `fim`, `fps`, `perf`, `castlevania`, `terreno`, `vila`, `andares`, `escada`, `caixas` (máscaras e golpes com F1), `arvore`, `castelo`, `chave` (portão, escada, corda, forte, baú e chave); acrescente `fps30` para testar no modo 30 FPS e `perfil=1` a `perfil=4` para forçar um nível de desempenho).
  Para não atrapalhar quem está usando o PC: `--position -3000,40 --audio-driver Dummy`
  (janela fora da área visível e sem som; as capturas saem de dentro do jogo).
