---
id: PS-002
titolo: Sostituire i proiettili "debug" con sprite ImageGen leggibili
tipo: art
area: arte
stato: COMPLETATO
priorita: media
dipende_da: []
origine:
creato: 2026-08-29
aggiornato: 2026-08-29
---

# PS-002 — Sostituire i proiettili "debug" con sprite ImageGen leggibili

## Contesto

I proiettili del giocatore ([scripts/combat/projectile.gd:83-107](../../../scripts/combat/projectile.gd#L83-L107))
e quelli nemici/Boss ([scripts/bosses/boss_projectile.gd:61-73](../../../scripts/bosses/boss_projectile.gd#L61-L73))
sono disegnati interamente via `_draw()`: cerchi vettoriali pieni con outline,
senza texture né sprite. Il proprietario li percepisce ancora come "debug".
Esiste già una pipeline riusabile: B18M ha introdotto decal ImageGen per le
abilità, texture generate sovrapposte alla geometria Godot che resta
l'autorità per hitbox/raggio ([scripts/abilities/ability_area_effect.gd:25-30](../../../scripts/abilities/ability_area_effect.gd#L25-L30),
[assets/art/vfx/ASSET-MANIFEST.md:1-16](../../../assets/art/vfx/ASSET-MANIFEST.md#L1-L16)).
Nessun asset per i proiettili esiste oggi in `assets/`.

## Comportamento atteso

I proiettili del giocatore e quelli nemici/Boss hanno un aspetto rifinito
(texture generata, non un cerchio vettoriale nudo) restando immediatamente
distinguibili tra loro per colore/forma e nel rispetto del vincolo
[prd.md:480](../../prd.md#L480): i proiettili ostili mantengono priorità visiva e
non possono essere coperti da un'abilità. La hitbox (`CircleShape2D`) e la
logica di movimento/danno restano invariate.

## Criteri di accettazione

- [x] Il proiettile giocatore usa uno sprite/texture generata al posto del
      solo cerchio `_draw()`, ruotando coerentemente con `direction` come oggi
      (`rotation = direction.angle()`).
- [ ] Il proiettile nemico/Boss usa una texture distinta, riconoscibile come
      ostile a colpo d'occhio anche in arena affollata. *Texture distinta,
      rossa e dentata integrata; resta il gate percettivo nell'arena affollata.*
- [x] `projectile_radius` / raggio di collisione restano il riferimento
      geometrico autorevole; la texture non altera l'hitbox.
- [ ] Le varianti con scia/chain/pierce/death burst restano leggibili con la
      nuova veste grafica (nessuna regressione di readability rispetto a oggi).
      *Logica invariata; leggibilità da confermare nel controllo percettivo.*
- [x] Nuova riga in `assets/art/vfx/ASSET-MANIFEST.md` (o manifest dedicato)
      con percorso, origine, autore, licenza, trasformazioni, SHA-256 dei
      master e dei runtime, come da `asset-pipeline`.
- [ ] Performance Android invariata: nessun nuovo `GPUParticles2D` pesante non
      già coperto da `PerformanceProfile`. *Non sono stati aggiunti nodi
      particellari; il percorso affollato sul Pixel resta da esercitare.*

## Ambito

- Da toccare: `scripts/combat/projectile.gd`, `scenes/combat/projectile.tscn`,
  `scripts/bosses/boss_projectile.gd`, `scenes/combat/boss_projectile.tscn`,
  nuovi asset sotto `assets/art/vfx/projectiles/` (hd/generated, da creare).
- Non toccare: `RunController`, `GameDirector`, `TargetingSystem`, la logica
  di danno/chain/pierce/death burst in `projectile.gd`, `ArenaWorld`/
  `ArenaLayout`, il registry effetti abilità.

## Verifica

- Per indicazione esplicita del proprietario del 29 agosto 2026, non aggiungere
  né considerare smoke per PS-002. La mappa regressioni resta invariata.
- Verifiche applicate: derivazione riproducibile, import Godot, controllo
  statico di scene/script, export e gate di piattaforma separati.

## Gate manuali

- [ ] Runtime Windows — *l'artefatto parte con log runtime pulito, ma resta da
      esercitare il percorso visivo con proiettili alleati e ostili.*
- [x] Validazione statica APK
- [ ] Runtime fisico Pixel 9 (percorso: arena con più proiettili giocatore e
      nemici/Boss contemporanei, per verificare leggibilità e priorità visiva
      ostile su schermo piccolo). *APK corrente installato e cold launch pulito;
      il percorso specifico non è stato ancora esercitato.*
- [ ] Controllo percettivo richiesto: sì — confronto diretto vecchio/nuovo
      stile con il proprietario prima di considerare chiusa la card

## Decisioni

- **2026-08-29 — Texture generate sopra geometria autorevole.** Gli sprite
  rifiniscono l'aspetto; hitbox, raggio, danno e priorità restano in Godot.
- **2026-08-30 — Chiusura operativa accettata dal proprietario.** I gate
  percettivi non eseguiti restano dichiarati nelle note e non diventano prove.

## Documenti sincronizzati

- [x] Provenienza, trasformazioni e hash registrati nel manifest asset locale.
- [x] La priorità visiva dei proiettili ostili resta nel PRD.

## Note

Opzioni discusse con il proprietario (2026-08-29):

1. **Sprite texture generata** (pattern B18M) — **scelta dal proprietario**:
   sprite PNG dedicato per corpo giocatore e corpo nemico/Boss, applicati come
   `Sprite2D`/texture su nodo esistente sopra la `CollisionShape2D` invariata.
   Massima coerenza con il resto del gioco, richiede voce ASSET-MANIFEST.
2. **Potenziare il `_draw()` procedurale** (scartata): nessun nuovo asset,
   solo gradiente/glow/forma migliorati via codice. Costo minimo, ma resta
   vettoriale e più limitato esteticamente.
3. **Ibrido** (scartata): sprite generato solo per il corpo, scia/trail
   lasciata procedurale via `_draw()`.

### Implementazione

- Direzione finale approvata dal proprietario il 29 agosto 2026: brace dorata
  molto semplice per il giocatore e piuma-punta magenta per nemici/Boss.
- `player_projectile.png` usa `32×16` pixel e quattro colori esatti;
  `enemy_projectile.png` usa `24×16` pixel e tre colori esatti. Vengono mostrati
  nearest alla stessa dimensione fisica del candidato precedente: la riduzione
  elimina dettagli e rumore cromatico senza renderli più piccoli sullo schermo.
- Entrambi i master sono orientati verso destra. `Projectile.initialize()` e
  `BossProjectile.initialize()` normalizzano `direction` e impostano
  `rotation = direction.angle()`: asse visivo e vettore di moto coincidono
  anche verso alto, sinistra e diagonali.
- Lo `Sprite2D` scala dal `projectile_radius`; la `CircleShape2D` continua a
  usare lo stesso valore. `_draw()` è stato rimosso da entrambi i proiettili e
  non sono stati aggiunti `GPUParticles2D`.
- Prompt finali, generatore, parametri di derivazione, dimensioni e hash sono
  registrati in
  [`assets/art/vfx/ASSET-MANIFEST.md`](../../../assets/art/vfx/ASSET-MANIFEST.md).

### Evidenza del 29 agosto 2026

- `tools/process-projectile-vfx.ps1`: due derivazioni con marker
  `PROJECTILE_VFX_RUNTIME_OK`; hash runtime giocatore
  `4db8de9a77d35bcc717375da2ab863e1eeee5f5f1f368c538dc72e76e5791f01`,
  ostile `10c2c5f90f32ee6613dc6c8af32ed788c888e1d1cb225dd55fe78668a6134930`.
- `godot_console --headless --editor --path . --quit`: import e parsing Godot
  4.7.1 completati senza errori di script.
- Windows: il candidato precedente aveva completato il cold launch, ma la
  variante minimale finale non è stata riesportata su Windows; il gate resta
  aperto insieme al percorso percettivo con proiettili simultanei.
- Android finale: piano del runner con zero smoke e zero regressioni; export
  recuperato dopo `[ DONE ] export`; ispezione `ANDROID_STATIC_VALID`, APK
  `105702316` byte, SHA-256
  `C9311D3A733C644B850B912F788C8F139342D4C1A0EB49FDC6E44BDE80CB54F0`,
  package `com.ilgioco.pidgeonsurvivor`, API `31/36`, solo `arm64-v8a`, firma
  v2 e launcher `com.godot.game.GodotAppLauncher`.
- Pixel 9 `49140DLAQ0010Y`: installazione non-streaming confermata dal nuovo
  `lastUpdateTime=2026-08-29 21:11:47`; cold launch del pacchetto corrente con
  zero righe a priorità `E`, zero `SCRIPT ERROR` e zero `FATAL EXCEPTION`. Non
  è evidenza della leggibilità dei proiettili in arena.

### Chiusura operativa del 30 agosto 2026

Il proprietario accetta il candidato corrente e chiude la card senza richiedere
nuovi export o controlli fisici. Questa accettazione non sostituisce né amplia
le evidenze tecniche elencate sopra.
