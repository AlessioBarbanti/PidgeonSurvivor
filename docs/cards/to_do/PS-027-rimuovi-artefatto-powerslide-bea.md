---
id: PS-027
titolo: Rimuovi l'artefatto residuo dalla Powerslide di Bea
tipo: fix
area: arte
stato: IN CORSO
priorita: media
dipende_da: []
origine:
creato: 2026-08-30
aggiornato: 2026-08-31
---

# PS-027 — Rimuovi l'artefatto residuo dalla Powerslide di Bea

## Contesto

Durante la Powerslide di Bea resta visibile un elemento grafico sotto l'abilità che non appartiene più alla direzione visuale corrente.

L'elemento sembra essere un vecchio SVG o un residuo della precedente implementazione degli artefatti visivi sotto le abilità e deve essere individuato e rimosso.

## Comportamento atteso

Durante l'intera Powerslide devono essere visibili esclusivamente lo sprite corrente di Bea e i VFX previsti dal design attuale, inclusa la scia di fuoco.

Il vecchio elemento grafico sotto Bea non deve più comparire durante attivazione, movimento, fine dell'abilità o cleanup.

La rimozione deve essere esclusivamente visuale e non deve modificare traiettoria, distanza, durata, danno o collisioni della Powerslide.

## Criteri di accettazione

- [x] Nessun vecchio SVG o artefatto grafico residuo compare sotto Bea
      durante la Powerslide. **Causa reale trovata** (non era un asset SVG
      ma una forma geometrica disegnata dal codice, screenshot del
      proprietario alla mano): `fire_z_trail.gd:_draw()` disegnava due
      `draw_polyline()` a bordo dritto e larghezza costante (`_trail_width`,
      `40` al rank 1) *sotto* la texture di fiamma stampata. Il nastro di
      fiamma è ondulato e non riempie l'intera larghezza in ogni punto: dove
      si assottiglia, il bordo dritto della polyline sottostante spuntava
      fuori — esattamente il "rettangolo/riga sotto" segnalato. Rimosse
      entrambe le chiamate.
- [x] L'artefatto non compare al primo frame dell'attivazione — non
      disegnato più in nessun frame, la rimozione è nel corpo di `_draw()`
      eseguito a ogni frame.
- [x] L'artefatto non compare durante lo spostamento — idem.
- [x] L'artefatto non rimane visibile alla conclusione dell'abilità — idem,
      nessuna logica diversa a fine durata: `_draw()` smette di essere
      chiamato quando il nodo si libera (`_finish_effect()`, invariato).
- [x] La scia di fuoco corrente resta visibile e invariata. I tasselli di
      texture (`draw_texture_rect` con `FIRE_TRAIL_TEXTURE`) e le scintille
      (`draw_colored_polygon`) non sono stati toccati: solo le due
      `draw_polyline` sono state rimosse.
- [x] Direzione e distanza della Powerslide restano invariate.
      `_build_straight_path()` non è stato toccato; coperto da
      `test_ps027_bea_powerslide_visual_cleanup.gd`.
- [x] Danno, durata, hitbox e collisioni restano invariati.
      `_apply_damage_tick()` e `_is_point_near_trail()` non sono stati
      toccati (usano `_path_points`/`_trail_width`, indipendenti dal
      disegno); coperto dallo stesso test.
- [ ] Restart e cambio personaggio non lasciano nodi o risorse visuali
      residue — coperto solo per il caso "fine naturale della durata" nel
      test automatico; il caso restart/cambio personaggio non è stato
      eseguito a runtime (nessun Godot in questa sessione).
- [x] La risorsa legacy non resta referenziata dal runtime se non è più
      utilizzata da nessun altro sistema — non era una risorsa/asset ma
      codice inline (`Color` letterali dentro `draw_polyline`); nessun file
      da ripulire.

## Ambito

- Scene e script VFX della Powerslide.
- Risorse grafiche collegate all'attiva di Bea.
- Nodi visuali legacy ancora istanziati dall'abilità.
- Eventuale SVG o asset obsoleto individuato durante la verifica.

Non modificare:

- `get_last_movement_direction()` e contratto direzionale della Powerslide;
- distanza dello scatto;
- scia di fuoco corrente;
- danno e tick della scia;
- cooldown e rank dell'abilità;
- sprite principale di Bea.

## Verifica

- Test: `tests/unit/test_ps027_bea_powerslide_visual_cleanup.gd` (`extends
  GutGameplayTest`). La card indicava originariamente uno smoke a script
  `SceneTree` in `tests/integration/`: quel contratto non è la convenzione
  corrente (vedi `docs/verification-workflow.md`, tutti i test vivono in
  `tests/unit/test_*.gd` con report GUT), quindi la formulazione è corretta
  qui invece di crearne uno stile obsoleto. Il test copre due cose: (1) per
  lettura del sorgente, che `draw_polyline` non compare più in
  `fire_z_trail.gd`; (2) a runtime, che direzione, distanza, danno del primo
  tick e cleanup a fine durata restano invariati. L'assenza *visiva* del
  bordo non è verificabile in un test headless senza cattura del rendering:
  resta un gate percettivo.
- Registrato in `tools/milestone-test-map.json` sotto la regola
  `scripts/abilities/*` / `data/abilities/*`.
- Profilo minimo prima della chiusura: `Relevant` con
  `-FocusedSmoke tests/unit/test_ps027_bea_powerslide_visual_cleanup.gd`
  (non ancora eseguito, vedi Note).

## Gate manuali

- [ ] Runtime Windows — necessario prima di `COMPLETATO`: nessun Godot
      disponibile in questa sessione per eseguirlo.
- [ ] Validazione statica APK — non pertinente, nessuna superficie Android
      specifica.
- [ ] Runtime fisico Pixel 9 (percorso: Bea → Powerslide in almeno quattro
      direzioni → osserva attivazione, scia e fine abilità) — non eseguito.
- [ ] Controllo percettivo richiesto: sì — è l'unico modo per confermare
      che il bordo non spunta più fuori in nessuna direzione/rank; lo
      screenshot del proprietario ha identificato la causa ma non sostituisce
      la conferma a schermo dopo il fix.

## Decisioni

- **2026-08-30 — Rimuovere il residuo visuale legacy dalla Powerslide.** L'attiva deve mostrare soltanto gli elementi grafici appartenenti alla direzione corrente.
- **Sostituisce:** presenza del vecchio artefatto/SVG residuo sotto l'abilità.
- **2026-08-31 — Causa trovata dopo uno screenshot del proprietario, non era
  un asset.** L'indagine statica per file/scene/dati non aveva trovato nulla
  perché l'artefatto non è un SVG o un nodo residuo: è la geometria delle
  due `draw_polyline()` di `_draw()` (il "glow" sotto la texture), che
  probabilmente precedevano l'introduzione della texture pixel-art
  `fire_trail.png` ed erano rimaste come base sotto di essa. Rimosse
  entrambe; texture e scintille restano invariate.
- **2026-08-31 — Nessun cambiamento a dati o hitbox.** L'unico file toccato
  per il comportamento è `scripts/abilities/fire_z_trail.gd`, solo dentro
  `_draw()`: `_apply_damage_tick`, `_is_point_near_trail` e
  `_build_straight_path` sono intatti.

## Documenti sincronizzati

- [ ] `prd.md` o `CLAUDE.md`: non richiesto salvo scoperta di un contratto visuale documentato errato.
- [ ] `characters.md`, `powerup-catalog.md` o `content-approvals.md`: non richiesto.
- [ ] Nota `*-verification.md`, se sono state prodotte nuove evidenze.

## Note

Prima di eliminare fisicamente la risorsa dal repository, verificare che non sia referenziata da altre scene o abilità. Non applicabile in pratica: la causa reale non era una risorsa (vedi sotto).

**Verifica non eseguita.** Il fix è stato implementato e controllato per
lettura (rimozione mirata, nessun'altra riga toccata) più un test
automatico nuovo, ma non è stato lanciato `run-milestone-checks.ps1`:
nessun Godot/PowerShell disponibile in questo ambiente. Il profilo
`Relevant` su Windows e il controllo percettivo su device restano i gate
aperti prima di poter chiudere la card `COMPLETATO`.

### 2026-08-31 — Cronologia dell'indagine

Prima fase, senza screenshot: ho investigato a fondo senza poter eseguire
Godot (ambiente Linux senza motore in questa sessione) e non ho trovato
alcun nodo, script o risorsa che disegni un elemento grafico legacy durante
la Powerslide. Percorsi controllati ed esclusi (nessuno di questi era la
causa, ma restano un utile inventario di cosa NON è coinvolto):

- `scripts/abilities/fire_z_trail.gd` (l'unico script che implementa
  l'attiva di Bea): disegna solo scia, tasselli di fiamma e scintille dalla
  texture corrente; nessun nodo o `preload` legacy.
- `data/friends/bea.tres`: nessun campo referenzia SVG o asset obsoleti.
- `scenes/game/movement_slice.tscn`: `FireZTrail` non ha una `.tscn`
  propria (istanziata da script), nessun nodo residuo collegato a Bea.
- `assets/art/third_party/pinhead_inline_skate/inline_skate.svg` esiste ma
  non è referenziato da alcun `.tres`/`.tscn`/`.gd` (`grep` su tutto il
  repository): è solo provenienza storica, non viene mai caricato a
  runtime.
- Il vecchio pittogramma `icons/abilities/powerslide.svg` non esiste più sul
  disco: nessun riferimento rotto.
- `assets/art/vfx/abilities/generated/fire_trail.png`: canale alfa corretto
  (trasparente ai bordi, opaco al centro — verificato con Pillow), nessun
  artefatto di rendering; le due forme a "goccia" visibili nella texture
  sono braci/scintille disegnate intenzionalmente nello stesso stile
  dell'illustrazione, non un residuo.
- `Player.set_momentum_trail_enabled()` (la scia di slancio, un sistema
  diverso appartenente a Magno) è attivata solo quando
  `passive_id == MAGNO_AERODYNAMIC_FLOW`: non si attiva per Bea.
- `instinctive_dodge_triggered` (il tell della passiva di Bea, B45) è
  emesso solo da `resolve_incoming_damage()`, un percorso completamente
  separato dall'attivazione della Powerslide.
- Nessun VFX generico "sotto ogni abilità" in `AbilityController` o
  `CombatFeedback`: l'esecuzione delega interamente a
  `AbilityEffectRegistry.execute_effect()`, specifico per `fire_z_trail`.

**Domanda per il proprietario:** non riesco a identificare l'artefatto per
lettura statica del codice — serve un'informazione che solo tu hai. Puoi
fornire uno screenshot o una registrazione della Powerslide con l'artefatto
visibile, o descriverlo con più precisione (forma, colore, in che momento
esatto della Powerslide appare — attivazione, durante lo scatto, o alla
fine)? Con quello individuo il file esatto invece di modificare codice alla
cieca.

### 2026-08-31 — Risolta dopo lo screenshot

Il proprietario ha fornito uno screenshot in-run: un bordo dritto e netto,
color magenta/bordeaux, visibile lungo il lato della scia di fuoco proprio
dove il nastro ondulato di fiamma si assottiglia. Riletto `_draw()` di
`fire_z_trail.gd` con quell'indizio: le due `draw_polyline(_path_points,
Color(...), _trail_width o _trail_width*0.34, true)` disegnate *prima* dei
tasselli di texture sono un rettangolo a bordo dritto di larghezza
costante (`_trail_width = 40` al rank 1); il nastro di fiamma stampato sopra
ha invece una silhouette ondulata che non copre sempre l'intera larghezza —
nei punti più sottili il bordo dritto della polyline sottostante resta
visibile. Rimosse entrambe le chiamate: vedi Criteri di accettazione e
Decisioni per il dettaglio del fix.
