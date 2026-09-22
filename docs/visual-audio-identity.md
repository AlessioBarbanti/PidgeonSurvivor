# Identità visiva e audio

Questo documento riassume lo stato attuale di direzione artistica, struttura
degli asset grafici e audio. Non duplica gli `ASSET-MANIFEST.md` di
cartella: li linka. Non è un backlog: lo stato operativo resta nella
[board](./cards/README.md).

## Direzione artistica dichiarata

La direzione visiva vive nei cataloghi di contenuto e nei manifest, non in
`CLAUDE.md` (che copre solo architettura e stile GDScript) — è un'assenza
del documento architetturale, non una lacuna di questo file.

- **Powerup** ([powerup-catalog.md](./powerup-catalog.md), righe 11-14): la
  direzione comune è quella dei **grigliatori** — carne, utensili da
  barbecue, pirofile, brace, condimenti, oggetti da cucina. I piccioni
  restano associati ai nemici e non devono essere il soggetto principale
  delle icone dei powerup positivi.
- **Armi per personaggio** ([prd.md](./prd.md), §3.1A): stesso registro
  utensile/brace/condimento dei powerup ordinari, mai quello della carne
  riservato alle Specialità di Barb. Ogni arma ha nome e icona propri, alla
  stessa gerarchia di lettura delle icone passiva: si riconoscono nel
  selettore personaggi e nel pannello build in pausa prima ancora di giocare.
  Quando il proiettile di un'arma condivide lo spazio con un VFX della passiva
  dello stesso personaggio, i due vanno tenuti visivamente distinti — è il
  caso dei frammenti orbitanti della `Graticola` di Migi contro le placche
  aderenti del suo Guscio Tartarughina.
- **Indicatore HUD di Alea** ([manifest](../assets/art/icons/hud/ASSET-MANIFEST.md)):
  il calice Sobrietà è una coppia di layer pixel-art allineati, con vetro
  freddo/ornamenti oro statici e vino borgogna isolato; il riempimento verticale
  progressivo comunica lo stato anche attraverso la massa del liquido, non il
  solo colore. Un anello di carica procedurale (PS-138,
  [scripts/ui/alea_sobriety_indicator.gd](../scripts/ui/alea_sobriety_indicator.gd))
  avvolge la sola coppa e scalda colore da bronzo (`#A67B35`, lo stesso già
  presente nel master) a oro vivo (`#F4BC55`) seguendo `charge_ratio`: è il
  segnale primario del "quanto manca", il vino resta secondario. Un alone
  luminoso attorno al vetro segnala lo stato Brilla — nessuno shader,
  nessun nuovo asset: stessa tecnica di disegno procedurale già in uso per
  l'anello di ricarica di `TouchAbilityButton` (PS-120/PS-122) e per la
  cornice di `PixelArcadeMedallion`.
- **Cast giocabile** ([characters.md](./characters.md), righe 111-124): gli
  otto profili (Zat, Bea, Aleo, Alea, Lollo, Migi, Marghe, Magno, con le
  rispettive Evil) seguono la direzione presentazionale approvata per il
  fondale della welcome screen, tradotta in silhouette leggibili e caricature
  pixel-art. L'identity pass del 28/08/2026 ha uniformato tutti e otto i
  profili alla direzione approvata; i dettagli per personaggio sono in
  `docs/characters/<id>.md` e le reference visive riservate restano fuori da
  import ed export in `docs/characters/references/<id>/`.
- **Bottoni secondari del pannello pausa** ([pause_overlay.tscn](../scenes/ui/pause_overlay.tscn)):
  CAMBIA PERSONAGGIO, IMPOSTAZIONI ed ESCI condividono la stessa texture
  nine-slice (`secondary_button_cta_base.png`), il cui canale rosso è ≈0 —
  `modulate_color` può quindi solo scurire/schiarire lungo il blu esistente
  (una rampa di *valore*), mai produrre un vero hue-shift. Quando più bottoni
  condividono una nine-slice a canale rosso nullo, la differenziazione va
  costruita su tre assi indipendenti, non su uno solo: luminosità
  (`modulate_color`, PS-145/PS-147: CAMBIA PERSONAGGIO base senza modulate,
  IMPOSTAZIONI chiaro con moltiplicatore `>1` per garantire uno schiarimento
  percepibile a prescindere dal valore nativo della texture, ESCI il più
  scuro dei tre con moltiplicatore `<1`), spaziatura di gruppo (uno
  spaziatore doppio isola le azioni distruttive, come ESCI, da quelle
  reversibili) e `font_color` come unico vero accento di tinta (il corallo
  di ESCI, preso in prestito dalla famiglia cromatica di "GAME OVER" in
  `end_screen.tscn` ma desaturato — non troppo, o si legge come rosa tenue
  invece che come segnale d'allerta).
  **Validazione obbligatoria sul rendering, non sui soli valori pianificati:**
  la prima versione di questa rampa (PS-147, valori entro ±0.15-0.2 fra
  gradini contigui) era corretta sulla carta ma indistinguibile a colpo
  d'occhio nello screenshot renderizzato — il delta minimo percepibile su
  questa texture, dentro la cornice scura del pannello, è risultato più
  vicino a ±0.3-0.4. La revisione va sempre chiesta sull'artefatto finale
  (`direttore-artistico` sullo screenshot in
  `exports/ui-screenshots/07_pause_overlay.png`, non sui numeri nel
  `.tscn`), prima di considerare il gate percettivo di una card chiuso.
- **Specialità di Barb: due trattamenti distinti a seconda del contesto,
  mai un terzo** (PS-164, confermato da `direttore-artistico` sul render
  finale): su una card grande cliccabile (`UpgradeCard`, ricompensa di Barb),
  bordo+sfondo ambra dedicati (`upgrade_card.gd:_apply_visual_treatment`); su
  una riga di riepilogo read-only (`PauseOverlay`, riepilogo build in pausa),
  solo il `font_color` del titolo passa all'oro già in uso nel pannello per
  `ConfirmationTitleLabel` (`Color(1, 0.85, 0.32, 1)`), mai un bordo/sfondo —
  quel trattamento resta riservato alle card cliccabili. Misurato sui pixel
  reali di `exports/ui-screenshots/07_pause_overlay.png`: lo scarto di
  tinta fra crema (`Color(1, 0.91, 0.7, 1)`) e oro è ≈0.34 sul canale blu,
  ben oltre la soglia ±0.3-0.4 già stabilita per questo pannello scuro (vedi
  voce sui bottoni secondari sopra) — un solo canale di distinzione basta,
  non serve un secondo segnale (peso del font, tag testuale, icona).
  Nelle caselle read-only dell'HUD (PS-204, `HudUpgradeSlot`) vale la stessa
  regola: l'unico testo è il rango, che per le Specialità passa allo stesso
  oro; cornice e fondo restano quelli delle caselle ordinarie (fondo scuro
  delle barre HUD, bordo `Color(0.72, 0.52, 0.24)`, attenuati a metà alpha
  nelle caselle vuote).
- **Ornamenti d'angolo delle carte upgrade**
  ([manifest](../assets/art/ui/upgrade_card/ASSET-MANIFEST.md)): per gli usi a
  clip, il medaglione/rivetto esiste come asset autonomo con alpha reale e
  margini progettati per il box finale; non si ritaglia direttamente una
  cornice intera opaca, perché il suo bezel incorporato non coincide col fondo
  della carta. Un solo master non direzionale viene riusato sui quattro angoli
  tramite `flip_h`/`flip_v`.
- **Nine-slice di `pause_panel_frame.png` su box piccoli (PS-154)**: il
  `texture_margin` va sempre impostato alla dimensione reale del motivo
  dorato del corner nel file sorgente (`56` orizzontale, `52` verticale,
  stessi valori di `pause_overlay.tscn`), mai ridotto per "adattarlo" a una
  card più piccola — un margine più stretto non scala il motivo, lo tronca
  (il motivo non parte da (0,0), vedi manifest di `ui/pause`). Godot scala
  proporzionalmente i margini da solo quando il box è più stretto della somma
  dei due margini: è quel comportamento nativo a fare il lavoro, non un
  valore diverso a mano. Quando più card della stessa fascia condividono la
  cornice a dimensioni diverse (roster del selettore personaggi:
  selezionato più grande, vicini più piccoli), usare la stessa altezza per
  tutte se i bordi devono restare allineati fra loro — un inset applicato
  solo a una dimensione (es. larghezza) e non all'altra crea un
  disallineamento sull'asse non scalato, invisibile con un bordo piatto ma
  evidente con una cornice-asset.
- **Gerarchia selezionato/non-selezionato via desaturazione**
  (`CharacterSelectOverlay`, PS-154): quando più elementi condividono lo
  stesso trattamento visivo (stessa cornice-asset) e la gerarchia va
  comunicata altrimenti, si usa un `ShaderMaterial` per nodo
  (`assets/shaders/desaturate.gdshader`, parametro `saturation` animato in
  tween) applicato al bottone/`Control` intero — non un `modulate` grigio
  (che attenua senza desaturare davvero) né una dimensione diversa della
  cornice. Il materiale è per-nodo (non condiviso) proprio per poter animare
  ogni card in transizione indipendentemente dalle altre.
- **Stile pixel-art**: confermato in modo ricorrente nei manifest di
  cartella, per esempio `assets/art/arena/ASSET-MANIFEST.md` ("caricatured
  pixel-art arcade... polished hand-crafted pixel art, restrained chunky
  pixel clusters") e `assets/art/enemies/pigeons/ASSET-MANIFEST.md`
  (contorno plum scuro, piuma lavanda, becco e zampe arancio per i
  piccioni nemici). `docs/archive/generation-prompts-and-references.md` conserva i
  prompt storici dello stile ("crisp dark outline, limited palette, chunky
  readable pixel clusters") come evidenza, non come contratto corrente.

## Struttura degli asset grafici

`assets/art/` è organizzato per categoria, ciascuna con il proprio
`ASSET-MANIFEST.md` (riga richiesta per ogni nuovo asset, per contratto
`CLAUDE.md`). Conteggio file PNG per cartella principale (istantanea al
03/09/2026):

| Cartella | PNG | Manifest | Note |
|---|---|---|---|
| `icons/upgrades` | 41 | [ASSET-MANIFEST.md](../assets/art/icons/upgrades/ASSET-MANIFEST.md) | Icone potenziamenti |
| `characters/<id>` (`hd/`, `generated/`) | 56 | [ASSET-MANIFEST.md](../assets/art/characters/ASSET-MANIFEST.md) | 8 personaggi, sprite/carousel e busti Player + Evil |
| `vfx/abilities` | 18 | [ASSET-MANIFEST.md](../assets/art/vfx/ASSET-MANIFEST.md) | Copre anche `vfx/projectiles` e `icons/abilities` |
| `icons/passives` | 16 | [ASSET-MANIFEST.md](../assets/art/icons/passives/ASSET-MANIFEST.md) | Dichiara approvazione percettiva finale ancora aperta |
| `enemies/pigeons` (+ `hd/`) | 16 | [ASSET-MANIFEST.md](../assets/art/enemies/pigeons/ASSET-MANIFEST.md) | Sprite piccioni per archetipo |
| `icons/abilities` | 9 | in `vfx/ASSET-MANIFEST.md` | Icone abilità attive generate |
| `ui/character_select` | 8 | [ASSET-MANIFEST.md](../assets/art/ui/character_select/ASSET-MANIFEST.md) | Fondale selettore |
| `icons/enemies` | 8 | [ASSET-MANIFEST.md](../assets/art/icons/enemies/ASSET-MANIFEST.md) | B49: **non ancora assegnate al runtime** |
| `arena` (`hd/`, `generated/`) | 15 | [ASSET-MANIFEST.md](../assets/art/arena/ASSET-MANIFEST.md) | Sfondo pavimento arena |
| `vfx/projectiles` | 4 | in `vfx/ASSET-MANIFEST.md` | |
| `ui/tutorial` | 10 | [ASSET-MANIFEST.md](../assets/art/ui/tutorial/ASSET-MANIFEST.md) | PS-049: ability/pickups/telegraphs, sfondo ImageGen + composizione deterministica di elementi runtime reali |
| `ui/welcome` | 3 | [ASSET-MANIFEST.md](../assets/art/ui/welcome/ASSET-MANIFEST.md) | Fondale welcome B18O |
| `ui/barb_reward` | 3 | [ASSET-MANIFEST.md](../assets/art/ui/barb_reward/ASSET-MANIFEST.md) | Caricatura dedicata di Barb (PS-036) |
| `ui/pause` | 2 | [ASSET-MANIFEST.md](../assets/art/ui/pause/ASSET-MANIFEST.md) | Cornice riusata da pausa, cambio personaggio, tutorial, terminale, intro Boss |
| `ui/upgrade_card` | 3 | [ASSET-MANIFEST.md](../assets/art/ui/upgrade_card/ASSET-MANIFEST.md) | Rivetto d'angolo PS-152: master, copia review e derivato runtime |
| `ui/boss` | 4 | [ASSET-MANIFEST.md](../assets/art/ui/boss/ASSET-MANIFEST.md) | Plancia CTA "AFFRONTA"; cornice PS-102 orfana da PS-176 (asset su disco, non più cablata) |
| `pickups` | 2 | [ASSET-MANIFEST.md](../assets/art/pickups/ASSET-MANIFEST.md) | Coscia di piccione, pickup cura |
| `branding` | 3 | [ASSET-MANIFEST.md](../assets/art/branding/ASSET-MANIFEST.md) | Icona app e adaptive icon Android |

### Sprite di gameplay del cast (PS-116)

Dal 7 settembre 2026 `assets/art/characters/<id>/generated/sprite.png` è una
striscia `192x64` (3 frame da `64x64`, prima `96x32`/`32x32`), derivata dallo
stesso master `hd/poses.png` con `tools/process-cast-sprite.ps1 -CanvasSize 64
-Padding 4` (prima `-CanvasSize 32 -Padding 2`, stesso rapporto area
utile/canvas). Causa: il canvas nativo del Player era piu' piccolo di quello
dei piccioni nemici (`48x48`) ma veniva ingrandito ~2x a schermo
(`CharacterSprite.scale` in `player.tscn`), risultando piu' "morbido" a
confronto. La scala del nodo e' stata dimezzata in proporzione
(`1.65 → 0.825`) cosi' il footprint finale a schermo resta invariato
(~66px); le region `AtlasTexture_gameplay_*` nei `data/friends/<id>.tres`
sono state aggiornate da celle `32x32` a `64x64`. Il corpo Evil (Boss) riusa
la stessa texture (`BossDefinition.get_visual_texture()` →
`friend_profile.get_gameplay_idle_right()`), quindi beneficia
automaticamente di un fattore di ingrandimento dimezzato
(`target_diameter / texture_size`, indipendente dal cambio).

Dall'8 settembre 2026 (PS-132) i soli derivati di **alea** e **zat** usano un
trattamento di leggibilita opt-in dello stesso script
(`-ReadabilityTreatment -PaletteColors 16 -FinalAlphaThreshold 140
-OutlineDarkenFactor 0.2 -OutlineThickness 2`): downscale che conserva la
massa al posto del nearest-neighbor secco (che a fattore di scala ~17x
scartava quasi tutti i pixel sorgente e frammentava gli arti sottili),
soglia alfa finale per bordi netti, quantizzazione palette median-cut e
contorno scuro derivato dal colore dominante di ciascun frame. Canvas,
region atlas e hitbox restano quelli di PS-116; gli altri sei personaggi
sono byte-identici a prima (trattamento opt-in, non nuovo default). Dettagli
e soglie di verifica nella card PS-132.

### Ritratti busto Player (PS-068)

Dal 3 settembre 2026 ogni `data/friends/*.tres` usa come `portrait` e
`portrait_placeholder` il derivato dedicato
`assets/art/characters/<id>/generated/portrait.png` (256×256, sfondo
trasparente). Gli otto `portraits_are_placeholders` sono `false`: il foglio
CC0 Eldiran non è più il fallback dei busti Player. I master restano in
`<id>/hd/portrait.png`, esclusi da import ed export.

La grammatica condivisa è pixel-art arcade a cluster visibili, outline scuro,
ombre a fasce e inquadratura coerente dalla vita verso l'alto. `poses.png`
domina design, costume e proporzioni; le reference visive riservate hanno ruolo
secondario di continuità del soggetto. L'accettazione percettiva del
proprietario copre tutti gli otto busti; Marghe è stata accettata dopo la
correzione dei capelli da castani a neri.

### Ritratti Boss fluttuanti nella Boss Intro (PS-176, sostituisce PS-051/PS-052/PS-102/PS-103)

PS-176 sostituisce il trattamento a pannello/medaglione/tinta di PS-051 con un
ritratto Boss "fluttuante" mostrato per intero in `contain`, senza pannello,
cornice o icona Signature. I nove ritratti definitivi (otto Evil più il
Piccione Malvagio) sono i busti `1536×1024` forniti dal proprietario in
`assets/Evil portrais new/*.png`, con ornamentazione (ali, catene, gemme,
cornice dorata) e cartiglio per la citazione già dipinti dentro l'immagine.
Sostituiscono i precedenti busti quadrati `256×256` prodotti da PS-052 (Evil)
e PS-128 (Piccione Malvagio): ogni `data/friends/*.tres` continua a
valorizzare `evil_portrait` (`assets/art/characters/<id>/generated/evil_portrait.png`)
e `data/bosses/first_boss.tres` continua a valorizzare `portrait`
(`assets/art/characters/piccione_malvagio/generated/portrait.png`), stessi
percorsi, nuovo contenuto. Il derivato runtime è ottenuto con
`tools/process-boss-portrait.ps1` (ridimensionamento bicubico che preserva il
rapporto d'aspetto `3:2`, nessun ritaglio sui bounds alpha: l'intera tela
dipinta è contenuto valido). Le otto icone Signature restano invariate e
continuano a esistere come asset (`assets/art/icons/signatures/generated/evil_<signature_id>.png`),
ma non sono più mostrate nella Boss Intro.

`BossUI` ([scripts/ui/boss_ui.gd](../scripts/ui/boss_ui.gd)) sovrappone la
citazione (`BossDefinition.get_safe_quote()`) al ritratto tramite ancore
percentuali (`AspectRatioContainer` più un `Control` non-container per il
posizionamento libero), calibrate sul rettangolo verde misurato su
`assets/Evil portrais new/REFERENCE.png`. Titolo e tinta personale
dell'`accent_color` non sono più applicati a nulla nella Boss Intro (erano il
contratto di PS-051, rimosso). Il Piccione Malvagio riceve lo stesso
trattamento degli Evil, senza layout ad hoc.

L'accettazione percettiva del proprietario (confronto con `direttore-artistico`
sulla resa cablata in scena) resta un gate manuale registrato nella card
[PS-176](../docs/cards/5_completed/PS-176-ritratti-boss-fluttuanti-senza-cornice.md).

**Fascia HUD superiore durante la Boss Intro (PS-180).** Il ritratto
full-bleed cresce nello spazio verticale prima riservato a `GameHud.TopBand`
(il gutter che teneva libera la fascia, `BossUI.CONTENT_TOP_MARGIN`), che
altrimenti risulterebbe invaso dall'arte opaca — lo stesso problema già
osservato da PS-176. Convenzione emersa dalla revisione del
`direttore-artistico`: **il top band di `GameHud` non viene mai nascosto
(`visible = false`) in nessuno stato non-`RUNNING`**; resta sempre almeno
visibile a piena opacità, come già accade in `LEVEL_UP`/`BARB_REWARD`/
`MANUAL_PAUSE`. Scende sotto `1.0` di alpha (`GameHud.TOP_BAND_BOSS_INTRO_ALPHA`)
solo quando il contenuto del modale occupa geometricamente lo stesso spazio
verticale della fascia stessa — oggi l'unico caso è `BOSS_INTRO`. Un
prossimo overlay che avesse bisogno di più spazio verticale segue la stessa
regola: attenuare, mai nascondere del tutto.

### Cornice Boss Intro, rimossa (PS-102/PS-103, scartate da PS-176)

`assets/art/ui/boss/generated/boss_intro_frame.png` (medaglione ritratto
circolare, ferro brunito, piume plum e brace arancio) non è più cablata nella
Boss Intro: PS-176 l'ha sostituita col ritratto fluttuante a schermo intero.
Il file resta sul disco come asset orfano, fuori dall'ambito di rimozione
della card. PS-102 e PS-103 sono state spostate a `SCARTATA`.

## Audio

Gestore unico e scene-local: `GameAudio`
([scripts/audio/game_audio.gd](../scripts/audio/game_audio.gd)), istanziato
in `scenes/game/movement_slice.tscn`, nessun autoload. Bus `SFX` e `Music`,
pool di 12 `AudioStreamPlayer` per gli SFX, un player dedicato per la
musica di run, uno per quella di menu, uno per la traccia Boss (PS-073) e uno
per la musica dedicata di fine run (PS-080), persistenza volume/mute su
`user://audio_settings.cfg`.

17 cue dichiarati: `SHOT`, `HIT`, `PLAYER_DAMAGE`, `PICKUP`, `LEVEL_UP`,
`ABILITY_ACTIVATE`, `ABILITY_READY`, `BOSS_WARNING`, `BOSS_ATTACK`,
`BOSS_VICTORY`, `DODGE`, `UI_CONFIRM`, `UI_CLICK`, `PAUSE`, `RESUME`,
`VICTORY`, `DEFEAT`. `has_complete_cue_set()` li verifica tutti e **17**
(PS-136 ha aggiunto `BOSS_VICTORY`, una fanfara puntuale a ogni sconfitta di
Boss — inclusa ogni ricorrenza nella stessa run — distinta dal cue `VICTORY`
di fine run; PS-074 ha aggiunto `UI_CLICK`, il click generico dei bottoni UI
che non avevano già un cue dedicato).

PS-074 — `UI_CLICK`: ogni overlay/schermata con bottoni prima silenziosi
(`PauseOverlay`, `CharacterSelectOverlay`, `WelcomeScreen`, `TutorialScreen`,
`EndScreen`, `BossUI`) espone un segnale `ui_click_requested()`, emesso solo
dai bottoni **senza** un cue già dedicato — mai da quelli che causano già
`UI_CONFIRM`/`PAUSE`/`RESUME` (es. Gioca e Tutorial della welcome, o
"Successivo" quando diventa "GIOCA" sull'ultima pagina del tutorial, restano
sul solo `UI_CONFIRM` esistente). `GameAudio._on_ui_click_requested()` è
l'unico handler condiviso, con un debounce di 80ms sullo stesso cue per
evitare accumulo su pressioni ravvicinate (es. Precedente/Successivo tenuti
premuti).

File audio runtime: 16 SFX Kenney CC0
([kenney_b18/ASSET-MANIFEST.md](../assets/audio/third_party/kenney_b18/ASSET-MANIFEST.md))
mappati 1:1 sui cue di combattimento/interfaccia; `DODGE` usa
`dodge.ogg`, un take del CC0 Swishes Sound Pack di artisticdude
([artisticdude_swishes/ASSET-MANIFEST.md](../assets/audio/third_party/artisticdude_swishes/ASSET-MANIFEST.md));
musica di run `super_wreck_roadway_loop.ogg` (Umplix, CC0)
([super_wreck_roadway_loop/ASSET-MANIFEST.md](../assets/audio/third_party/super_wreck_roadway_loop/ASSET-MANIFEST.md));
musica menu
`menu_music_loop.ogg` (wipics, CC0); musica Boss dedicata (PS-073)
`boss_music_loop.ogg`, "Vilified" di Matthew Pablo, CC-BY 3.0 — l'unico asset
audio del progetto con attribuzione obbligatoria invece che volontaria
([matthewpablo_vilified/ASSET-MANIFEST.md](../assets/audio/third_party/matthewpablo_vilified/ASSET-MANIFEST.md)).
Musica dedicata di fine run (PS-080), un solo colpo non in loop, distinta dai
cue SFX `VICTORY`/`DEFEAT` esistenti (entrambi restano attivi insieme alla
nuova musica, non sostituiti): `victory_music.wav`, "Victory Fanfare Short" di
cynicmusic, CC0
([cynicmusic_victory_fanfare/ASSET-MANIFEST.md](../assets/audio/third_party/cynicmusic_victory_fanfare/ASSET-MANIFEST.md));
`defeat_music.wav`, "Sad game over" di Emma_MA, CC0
([emma_ma_sad_game_over/ASSET-MANIFEST.md](../assets/audio/third_party/emma_ma_sad_game_over/ASSET-MANIFEST.md)).
Un asset musicale superato resta in `congusbongus_b29/`
(`head_in_the_sand.ogg`), dichiarato non referenziato nel proprio manifest.
Loop musicale impostato a runtime (`AudioStreamOggVorbis.loop`/
`AudioStreamMP3.loop = true`), non nel file sorgente — le due tracce di fine
run non sono mai messe in loop. Dall'ingresso
dell'intro Boss (`boss_intro_started`) alla sconfitta (`boss_defeated`) la
musica di run e quella Boss si scambiano con un crossfade di
`PresentationTimings.BOSS_MUSIC_CROSSFADE_SECONDS` (1.5s) sul bus `Music`; la
musica di run riprende dalla posizione lasciata, non da capo.

Ducking nei momenti chiave (PS-056): il countdown dell'avvertimento Boss
(`GameDirector.BossWarningPhase.COUNTDOWN`, non l'`APPROACHING` più
anticipato), `LEVEL_UP` e `BARB_REWARD` abbassano la musica di run di
`GameAudio.MUSIC_DUCK_OFFSET_DB` (-8 dB) invece di fermarla — a differenza di
`MANUAL_PAUSE`, che resta un'interruzione netta. La discesa
(`PresentationTimings.MUSIC_DUCK_DOWN_SECONDS`, 0.25s) è più rapida della
risalita (`MUSIC_DUCK_UP_SECONDS`, 0.6s); più momenti sovrapposti restano a
un solo livello, non si sommano, e la musica risale solo quando l'ultimo si
chiude. Il countdown Boss riusa il cue `BOSS_WARNING` come stinger; la
ricompensa Barb riusa `LEVEL_UP`, che nel level-up stesso è già lo stinger
esistente.

Accelerazione late-run (PS-081): fra `late_run_curve_start_seconds` e
`late_run_curve_full_seconds` (le stesse soglie della curva di difficoltà,
`EnemySpawnProfile`, `docs/systems-difficulty.md`) la musica di run accelera
gradualmente fino a `pitch_scale = 1.0 + GameAudio.MUSIC_LATE_RUN_MAX_PITCH_SCALE_OFFSET`
(+12%, tarabile dopo l'ascolto reale), restando a quel valore oltre la
soglia finale. Nessun nuovo asset: stessa traccia, solo velocità di
riproduzione (e quindi anche intonazione) più alta — non un secondo layer da
sincronizzare in fase. La traccia Boss dedicata (PS-073) non è mai toccata.
Il valore deriva in continuo dal tempo di run corrente
(`RunController.run_time_changed`), quindi resta fermo da solo nei modal che
sospendono il clock di run (`LEVEL_UP`, `BARB_REWARD`, `MANUAL_PAUSE`,
`BOSS_INTRO`) e riprende dal punto corretto senza stato salvato a parte;
resta indipendente dal ducking di PS-056, che agisce sul volume dello stesso
player.

`docs/credits.md` riepiloga le attribuzioni.

## `PerformanceProfile`

[scripts/platform/performance_profile.gd](../scripts/platform/performance_profile.gd):
profilo dichiarativo, "modifica solo la presentazione e non il
bilanciamento" (commento sorgente). Campi: `target_fps` (30-240),
`render_scale` (0.5-1.0), `max_transient_feedback`, più soglie di stress
test (`stress_enemy_count`, `stress_projectile_count`,
`stress_pickup_count`) usate dall'harness di stress, non dal gameplay
normale.

**`target_fps` (PS-113):** applicato a `Engine.max_fps` in
`movement_slice._configure_performance_hardening()`, subito dopo la
risoluzione del profilo attivo. Prima di PS-113 il campo era dichiarato e
validato ma non consumato: il motore rendeva senza limite di frame, probabile
causa principale di calore e consumo batteria su Android di fascia bassa a
refresh rate alto.

Due profili dati: `windows_performance_profile.tres`
(`max_transient_feedback = 300`) e `mobile_performance_profile.tres`
(`max_transient_feedback = 150`); entrambi hanno `target_fps = 60`,
`render_scale = 1.0` e soglie di stress identiche — **`render_scale` non è
oggi differenziato fra le due piattaforme** nei dati correnti. Selezione a
runtime in `movement_slice._resolve_performance_profile()` (mobile se la
piattaforma è mobile, altrimenti Windows), applicato al numero massimo di
effetti di combat feedback attivi.

**Nota aperta**: non è stato individuato, in questa ricognizione, un punto
del codice che applichi effettivamente `render_scale` a viewport o
risoluzione interna — il campo è dichiarato e validato ma il suo consumer
non è stato trovato. Da verificare con una ricerca dedicata prima di
descriverne l'effetto pratico in futuro, non assunto qui.
