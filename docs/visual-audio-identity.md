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
- **Cast giocabile** ([characters.md](./characters.md), righe 111-124): gli
  otto profili (Zat, Bea, Aleo, Alea, Lollo, Migi, Marghe, Magno, con le
  rispettive Evil) seguono la direzione presentazionale approvata per il
  fondale della welcome screen, tradotta in silhouette leggibili. Nessun
  personaggio rappresenta persone reali, con l'eccezione dichiarata di Aleo
  (ispirato ai tratti di una persona reale con consenso esplicito del
  proprietario, rework del 28/08/2026): resta comunque "una caricatura
  pixel-art e non una somiglianza fotografica". L'intero cast di sprite è
  stato rigenerato in un passaggio di identità unico il 28/08/2026.
- **Stile pixel-art**: confermato in modo ricorrente nei manifest di
  cartella, per esempio `assets/art/arena/ASSET-MANIFEST.md` ("caricatured
  pixel-art arcade... polished hand-crafted pixel art, restrained chunky
  pixel clusters") e `assets/art/enemies/pigeons/ASSET-MANIFEST.md`
  (contorno plum scuro, piuma lavanda, becco e zampe arancio per i
  piccioni nemici). `docs/archive/aleo-rework-art-prompts.md` conserva i
  prompt storici dello stile ("crisp dark outline, limited palette, chunky
  readable pixel clusters") come evidenza, non come contratto corrente.

## Struttura degli asset grafici

`assets/art/` è organizzato per categoria, ciascuna con il proprio
`ASSET-MANIFEST.md` (riga richiesta per ogni nuovo asset, per contratto
`CLAUDE.md`). Conteggio file PNG per cartella principale (istantanea al
31/08/2026):

| Cartella | PNG | Manifest | Note |
|---|---|---|---|
| `icons/upgrades` | 41 | [ASSET-MANIFEST.md](../assets/art/icons/upgrades/ASSET-MANIFEST.md) | Icone potenziamenti |
| `characters/players` (+ `carousel/`, `hd/`) | 24 | [ASSET-MANIFEST.md](../assets/art/characters/players/ASSET-MANIFEST.md) | 8 strisce Player, identity pass 28/08/2026 |
| `vfx/abilities` | 18 | [ASSET-MANIFEST.md](../assets/art/vfx/ASSET-MANIFEST.md) | Copre anche `vfx/projectiles` e `icons/abilities` |
| `icons/passives` | 16 | [ASSET-MANIFEST.md](../assets/art/icons/passives/ASSET-MANIFEST.md) | Dichiara approvazione percettiva finale ancora aperta |
| `enemies/pigeons` (+ `hd/`) | 16 | [ASSET-MANIFEST.md](../assets/art/enemies/pigeons/ASSET-MANIFEST.md) | Sprite piccioni per archetipo |
| `icons/abilities` | 9 | in `vfx/ASSET-MANIFEST.md` | Icone abilità attive generate |
| `ui/character_select` | 8 | [ASSET-MANIFEST.md](../assets/art/ui/character_select/ASSET-MANIFEST.md) | Fondale selettore |
| `icons/enemies` | 8 | [ASSET-MANIFEST.md](../assets/art/icons/enemies/ASSET-MANIFEST.md) | B49: **non ancora assegnate al runtime** |
| `arena` (`hd/`, `generated/`) | 15 | [ASSET-MANIFEST.md](../assets/art/arena/ASSET-MANIFEST.md) | Sfondo pavimento arena |
| `vfx/projectiles` | 4 | in `vfx/ASSET-MANIFEST.md` | |
| `ui/tutorial` | 4 | [ASSET-MANIFEST.md](../assets/art/ui/tutorial/ASSET-MANIFEST.md) | |
| `ui/welcome` | 3 | [ASSET-MANIFEST.md](../assets/art/ui/welcome/ASSET-MANIFEST.md) | Fondale welcome B18O |
| `ui/barb_reward` | 3 | [ASSET-MANIFEST.md](../assets/art/ui/barb_reward/ASSET-MANIFEST.md) | Caricatura Barb (PS-036), da foto personale non conservata nel repo |
| `ui/pause` | 2 | [ASSET-MANIFEST.md](../assets/art/ui/pause/ASSET-MANIFEST.md) | Cornice riusata da pausa, cambio personaggio, tutorial, terminale, intro Boss |
| `ui/boss` | 2 | [ASSET-MANIFEST.md](../assets/art/ui/boss/ASSET-MANIFEST.md) | Plancia CTA "AFFRONTA" |
| `pickups` | 2 | [ASSET-MANIFEST.md](../assets/art/pickups/ASSET-MANIFEST.md) | Coscia di piccione, pickup cura |
| `branding` | 3 | [ASSET-MANIFEST.md](../assets/art/branding/ASSET-MANIFEST.md) | Icona app e adaptive icon Android |
| `third_party/eldiran_rpg_characters` | 2 | `LICENSE.md` | Sprite RPG 32×32 CC0, vedi nota sotto |
| `third_party/pinhead_inline_skate` | 1 | `LICENSE.md` | Provenienza storica, sostituito da `icons/abilities/generated/powerslide.png` |

### Discrepanza osservata: ritratto Boss ancora sul placeholder generico

Tutti gli otto `data/friends/*.tres` impostano `portrait`/`evil_portrait`
come ritaglio dello stesso foglio generico CC0 di terze parti
(`assets/art/third_party/eldiran_rpg_characters/…png`), identico al
`portrait_placeholder`/`evil_portrait_placeholder`, nonostante
`portraits_approved = true`. `FriendDefinition.get_public_portrait()` e
`get_public_evil_portrait()`
([scripts/content/friend_definition.gd:241-258](../scripts/content/friend_definition.gd))
restituiscono comunque questo valore quando "approvato", ed è quello che
`BossDefinition.get_safe_portrait()` usa per il ritratto `Evil <Nome>`
mostrato in run. Sprite di gioco, ritratto di selezione personaggio e icona
passiva usano invece asset bespoke — è **solo il ritratto Boss** a restare
sul placeholder generico. Segnalato qui come stato osservato; non è
un'azione di questa card (solo documentazione, nessuna modifica ad asset o
codice).

## Audio

Gestore unico e scene-local: `GameAudio`
([scripts/audio/game_audio.gd](../scripts/audio/game_audio.gd)), istanziato
in `scenes/game/movement_slice.tscn`, nessun autoload. Bus `SFX` e `Music`,
pool di 12 `AudioStreamPlayer` per gli SFX, un player dedicato per la
musica di run e uno per quella di menu, persistenza volume/mute su
`user://audio_settings.cfg`.

15 cue dichiarati: `SHOT`, `HIT`, `PLAYER_DAMAGE`, `PICKUP`, `LEVEL_UP`,
`ABILITY_ACTIVATE`, `ABILITY_READY`, `BOSS_WARNING`, `BOSS_ATTACK`, `DODGE`,
`UI_CONFIRM`, `PAUSE`, `RESUME`, `VICTORY`, `DEFEAT`.
`has_complete_cue_set()` ne verifica **14**, escludendo esplicitamente
`DODGE`: il commento sorgente dichiara che `dodge_stream` (Sesto Senso
Equino di Bea) resta un no-op silenzioso finché non arriva un asset
dedicato — mancanza dichiarata direttamente nel codice, non dedotta.

File audio runtime: 14 SFX Kenney CC0
([kenney_b18/ASSET-MANIFEST.md](../assets/audio/third_party/kenney_b18/ASSET-MANIFEST.md))
mappati 1:1 sui cue completi; musica di run `super_wreck_roadway_loop.ogg`
(Umplix, CC0); musica menu `menu_music_loop.ogg` (wipics, CC0). Un asset
musicale superato resta in `congusbongus_b29/` (`head_in_the_sand.ogg`),
dichiarato non referenziato nel proprio manifest. Loop musicale impostato a
runtime (`AudioStreamOggVorbis.loop = true`), non nel file sorgente.
`docs/credits.md` riepiloga le attribuzioni.

## `PerformanceProfile`

[scripts/platform/performance_profile.gd](../scripts/platform/performance_profile.gd):
profilo dichiarativo, "modifica solo la presentazione e non il
bilanciamento" (commento sorgente). Campi: `target_fps` (30-240),
`render_scale` (0.5-1.0), `max_transient_feedback`, più soglie di stress
test (`stress_enemy_count`, `stress_projectile_count`,
`stress_pickup_count`) usate dall'harness di stress, non dal gameplay
normale.

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
