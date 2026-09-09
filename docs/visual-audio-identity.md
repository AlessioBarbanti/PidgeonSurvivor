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
  fondale della welcome screen, tradotta in silhouette leggibili. Nessun
  profilo è una somiglianza fotografica: tutti restano caricature pixel-art.
  L'identity pass del 28/08/2026 ha però superato la baseline iniziale (senza
  fotografie) per tutti e otto i profili, usando riferimenti fotografici
  forniti e autorizzati esplicitamente dal proprietario come `subject
  reference` (dettaglio per personaggio in `docs/characters/<id>.md`, foto in
  `docs/characters/references/<id>/`); Aleo resta il solo rework
  dichiaratamente ispirato ai tratti di una persona reale con consenso
  esplicito documentato oltre alla semplice reference. L'intero cast di
  sprite è stato rigenerato in un passaggio di identità unico il 28/08/2026.
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
| `ui/barb_reward` | 3 | [ASSET-MANIFEST.md](../assets/art/ui/barb_reward/ASSET-MANIFEST.md) | Caricatura Barb (PS-036), da foto personale non conservata nel repo |
| `ui/pause` | 2 | [ASSET-MANIFEST.md](../assets/art/ui/pause/ASSET-MANIFEST.md) | Cornice riusata da pausa, cambio personaggio, tutorial, terminale, intro Boss |
| `ui/boss` | 4 | [ASSET-MANIFEST.md](../assets/art/ui/boss/ASSET-MANIFEST.md) | Plancia CTA "AFFRONTA" e cornice Boss Intro PS-102 (in attesa di wiring PS-103) |
| `pickups` | 2 | [ASSET-MANIFEST.md](../assets/art/pickups/ASSET-MANIFEST.md) | Coscia di piccione, pickup cura |
| `branding` | 3 | [ASSET-MANIFEST.md](../assets/art/branding/ASSET-MANIFEST.md) | Icona app e adaptive icon Android |
| `third_party/eldiran_rpg_characters` | 2 | `LICENSE.md` | Sprite RPG 32×32 CC0, vedi nota sotto |
| `third_party/pinhead_inline_skate` | 1 | `LICENSE.md` | Provenienza storica, sostituito da `icons/abilities/generated/powerslide.png` |

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
domina design, costume e proporzioni; le fotografie personali autorizzate
forniscono solo citazioni fisionomiche semplificate, mai una copia
fotorealistica. L'accettazione percettiva del proprietario copre tutti gli otto
busti; Marghe è stata accettata dopo la correzione dei capelli da castani a
neri.

### Stato dei ritratti Evil nella Boss Intro (PS-051, integrato da PS-052)

PS-051 ha dato identità individuale alla Boss Intro degli Evil. PS-052 ha
prodotto e integrato gli asset definitivi: ogni `data/friends/*.tres`
valorizza `evil_portrait` con il busto dedicato del personaggio
(`assets/art/characters/<id>/generated/evil_portrait.png`), distinto dal
precedente ritaglio condiviso del foglio CC0 di terze parti
(`assets/art/third_party/eldiran_rpg_characters/…png`), che resta solo come
`evil_portrait_placeholder` di fallback. Ogni `data/bosses/signatures/*.tres`
espone inoltre un'icona dedicata
(`assets/art/icons/signatures/generated/evil_<signature_id>.png`) tramite il
campo `BossSignatureDefinition.icon`. I sedici segnaposto `fake_*.png`
introdotti da PS-051 sono stati rimossi dalle cartelle runtime.

`BossUI` ([scripts/ui/boss_ui.gd](../scripts/ui/boss_ui.gd)) mostra ritratto e
icona quando il Boss è un Evil, e tinge nome e cornice con l'`accent_color`
della Signature (mescolato a bianco per restare leggibile); il Piccione
Malvagio (`data/bosses/first_boss.tres`) non ha Signature e resta sul
trattamento neutro, senza slot icona.

L'accettazione percettiva del proprietario (silhouette, leggibilità alla
dimensione reale della Boss intro sul Pixel 9) resta un gate manuale aperto
su [PS-052](../docs/cards/4_to_test/PS-052-genera-ritratti-evil-e-icone-signature.md).

### Cornice Boss Intro (PS-102, in attesa di PS-103)

`assets/art/ui/boss/generated/boss_intro_frame.png` è la placca di rivelazione
neutra: medaglione ritratto circolare in alto, ferro brunito, piume plum e
brace arancio attorno a un centro libero per il copy nativo. Non contiene
colori personali né testo; PS-103 la applicherà senza cambiare la modulazione
già prevista per `Evil <Nome>` o il trattamento neutro del Piccione Malvagio.

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
`boss_music_loop.mp3`, "Vilified" di Matthew Pablo, CC-BY 3.0 — l'unico asset
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
