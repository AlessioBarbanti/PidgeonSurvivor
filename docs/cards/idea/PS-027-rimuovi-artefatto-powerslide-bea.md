---
id: PS-027
titolo: Rimuovi l'artefatto residuo dalla Powerslide di Bea
tipo: fix
area: arte
stato: DA DEFINIRE
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

- [ ] Nessun vecchio SVG o artefatto grafico residuo compare sotto Bea durante la Powerslide.
- [ ] L'artefatto non compare al primo frame dell'attivazione.
- [ ] L'artefatto non compare durante lo spostamento.
- [ ] L'artefatto non rimane visibile alla conclusione dell'abilità.
- [ ] La scia di fuoco corrente resta visibile e invariata.
- [ ] Direzione e distanza della Powerslide restano invariate.
- [ ] Danno, durata, hitbox e collisioni restano invariati.
- [ ] Restart e cambio personaggio non lasciano nodi o risorse visuali residue.
- [ ] La risorsa legacy non resta referenziata dal runtime se non è più utilizzata da nessun altro sistema.

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

- Smoke: `tests/integration/_bea_powerslide_visual_cleanup_smoke.gd` → marker `BEA_POWERSLIDE_VISUAL_CLEANUP_SMOKE_OK`
- Profilo minimo prima della chiusura: `Relevant`

## Gate manuali

- [ ] Runtime Windows
- [ ] Validazione statica APK
- [ ] Runtime fisico Pixel 9 (percorso: Bea → Powerslide in almeno quattro direzioni → osserva attivazione, scia e fine abilità)
- [ ] Controllo percettivo richiesto: sì

## Decisioni

- **2026-08-30 — Rimuovere il residuo visuale legacy dalla Powerslide.** L'attiva deve mostrare soltanto gli elementi grafici appartenenti alla direzione corrente.
- **Sostituisce:** presenza del vecchio artefatto/SVG residuo sotto l'abilità.

## Documenti sincronizzati

- [ ] `prd.md` o `CLAUDE.md`: non richiesto salvo scoperta di un contratto visuale documentato errato.
- [ ] `characters.md`, `powerup-catalog.md` o `content-approvals.md`: non richiesto.
- [ ] Nota `*-verification.md`, se sono state prodotte nuove evidenze.

## Note

Prima di eliminare fisicamente la risorsa dal repository, verificare che non sia referenziata da altre scene o abilità.

### 2026-08-31 — Indagine statica senza esito, card spostata a DA DEFINIRE

Ho investigato a fondo senza poter eseguire Godot (ambiente Linux senza
motore in questa sessione) e non ho trovato alcun nodo, script o risorsa che
disegni un elemento grafico legacy durante la Powerslide. Percorsi
controllati ed esclusi:

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
