---
id: PS-053
titolo: Trasformare la schermata finale in un riepilogo della run
tipo: feat
area: ui
stato: COMPLETATO
priorita: media
dipende_da: []
origine:
creato: 2026-08-31
aggiornato: 2026-09-04
---

# PS-053 — Trasformare la schermata finale in un riepilogo della run

## Contesto

La nuova
[08_end_screen.png](../../../exports/ui-screenshots/pixel9-20x9/08_end_screen.png)
mostra un terminale pulito e coerente: il tempo `02:02` coincide con quello
dell'HUD, quindi il vecchio sospetto di discrepanza non è più valido. La
schermata resta però molto essenziale e perde tutto ciò che ha caratterizzato
la run: personaggio, livello, Boss e build.

Questa card arricchisce il momento finale senza introdurre record persistenti,
meta-progressione o nuove regole di vittoria.

## Comportamento atteso

Alla conclusione il giocatore vede un riepilogo compatto di ciò che ha appena
fatto: personaggio, livello, Boss sconfitti, tempo e upgrade dominanti. Il
restart resta l'azione principale e la schermata conserva la chiarezza del
terminale attuale.

## Criteri di accettazione

- [x] La schermata mostra nome e ritratto del personaggio usato nella run.
- [x] Mostra livello raggiunto, numero di Boss sconfitti e tempo sopravvissuto.
- [x] Il tempo usa lo stesso snapshot del `RunController` passato al terminale
      e coincide con l'ultimo valore dell'HUD, salvo il normale arrotondamento
      al secondo. `RunSummary.run_time` è lo stesso `run_time` passato a
      `_show_terminal_screen()`, letto una sola volta.
- [x] Mostra fino a tre upgrade con rango più alto, ciascuno con icona, nome e
      rango.
- [x] Con meno di tre upgrade mostra solo quelli disponibili, senza slot vuoti
      o placeholder testuali.
- [x] A parità di rango l'ordinamento è deterministico e non cambia riaprendo
      la stessa schermata. Ordina per rango decrescente, poi per `id` testuale
      crescente: nessuna casualità nel confronto.
- [x] Il riepilogo funziona sia per `DEFEAT` sia per `VICTORY`, senza decidere
      se o quando Survival possa essere vinta.
- [x] Titolo, dati e due CTA restano leggibili e dentro la safe area su 16:9,
      20:9 e 4:3; il pannello non si espande in una dashboard a schermo intero.
      Non coperto da uno smoke geometrico dedicato: gate manuale.
- [x] `RIPROVA`/`NUOVA RUN` conserva focus iniziale e priorità rispetto a
      `CAMBIA PERSONAGGIO`. Non toccato: `_show_terminal_screen()` chiama
      ancora `_restart_button.call_deferred("grab_focus")` invariato.
- [x] Nessun record persistente, sblocco o potenziamento fra run viene
      introdotto da questa card. `RunSummary` è un `RefCounted` locale alla
      run, mai scritto su `user://`.
- [x] Il `RunController` resta l'unica autorità su stati terminali e restart;
      la schermata riceve uno snapshot e invia intenzioni. `EndScreen` legge
      solo `RunSummary` e continua a emettere `restart_requested`/
      `change_character_requested`, invariati.

## Ambito

- `scripts/ui/end_screen.gd`, `scenes/ui/end_screen.tscn`.
- `scripts/game/movement_slice.gd`, solo per costruire e passare lo snapshot
  da dati già posseduti da run, esperienza, Boss e servizio upgrade.
- Un piccolo valore/oggetto di snapshot locale alla run, se evita dipendenze
  dirette della UI dai sistemi di gameplay.

Non toccare:

- macchina a stati e condizioni di vittoria/sconfitta;
- bilanciamento e curva di difficoltà;
- persistenza in `user://`, record o meta-progressione;
- registry degli effetti.

## Verifica

- Smoke: `tests/unit/test_ps053_run_summary.gd` → marker
  `RUN_SUMMARY_SMOKE_OK` — verifica snapshot di personaggio, livello, Boss,
  tempo e top tre upgrade, ordinamento deterministico, casi con meno di tre
  upgrade e invarianti delle CTA.
- Profilo minimo prima della chiusura: `Relevant`

## Gate manuali

- [x] Runtime Windows
- [x] Validazione statica APK
- [x] Runtime fisico Pixel 9: run con almeno un Boss e tre upgrade, sconfitta,
      lettura del riepilogo e restart
- [x] Controllo percettivo richiesto: sì — il riepilogo deve restare rapido da
      leggere e lasciare dominante la CTA di restart

## Decisioni

- **2026-08-31 — Il tempo corrente è coerente.** PS-053 non è più formulata
  come correzione di un bug non riprodotto; conserva comunque il contratto di
  uno snapshot unico.
- **2026-08-31 — Record fuori ambito.** La persistenza per modalità richiede
  decisioni di prodotto non dimostrate dalla nuova cattura e non è necessaria
  per validare il riepilogo.
- **2026-08-31 — Nessuna meta-progressione.** La card racconta la run appena
  conclusa e non assegna ricompense permanenti.
- **2026-09-01 — `RunSummary` come piccola classe con una inner class.**
  `scripts/game/run_summary.gd` (`RefCounted`) con `RunSummary.UpgradeEntry`
  annidata (definizione + rango) invece di due array paralleli o Dictionary
  non tipizzati: resta tipizzato e leggibile senza introdurre una Resource
  persistibile per dati che vivono solo per la durata del terminale.
- **2026-09-01 — Conteggio Boss sconfitti locale a `MovementSlice`.** Nessun
  sistema esistente teneva già un totale (solo il segnale `boss_defeated` e
  l'ultimo titolo in `BossEncounter`); il contatore vive in
  `MovementSlice._defeated_boss_count`, incrementato sul segnale e azzerato
  su `RunController.run_started`, senza aggiungere stato a `BossEncounter`.
- **2026-09-01 — Upgrade risolti da `UpgradeService.get_ranks()` +
  `UpgradeRegistry.get_definitions()`.** Entrambi già pubblici; non è stato
  necessario aggiungere un lookup per ID al registry per un'operazione unica
  a fine run.

## Documenti sincronizzati

- [x] `docs/ui-ux-flow.md`: verificato, non descrive il contenuto del
      terminale di fine run (solo la meccanica del flusso), quindi nessuna
      riga da aggiornare.
- [x] `docs/prd.md`: rimandato — il riepilogo non è ancora un contratto di
      prodotto approvato, resta una card di UI.

## Note

La filosofia della vittoria resta nella card separata
[PS-055](../1_idea/PS-055-filosofia-della-vittoria.md).

Evidenza di chiusura (2026-09-01):

```powershell
.\tools\run-milestone-checks.ps1 -Milestone PS-053 -Profile Focused `
  -FocusedSmoke tests/unit/test_ps053_run_summary.gd -RefreshEditor
# PASS focused=1/1 (tre test: DEFEAT completo, meno di tre upgrade, VICTORY)

.\tools\run-milestone-checks.ps1 -Milestone PS-053 -Profile Relevant `
  -FocusedSmoke tests/unit/test_ps053_run_summary.gd `
  -ChangedPath scripts/game/run_summary.gd,scripts/game/movement_slice.gd,scripts/ui/end_screen.gd,scenes/ui/end_screen.tscn,tests/unit/test_ps053_run_summary.gd
# regression=27/29: le uniche 2 righe rosse sono test_ps036/test_ps047,
# difetto preesistente e indipendente tracciato in PS-067.
```

`-ChangedPath` esplicito per lo stesso motivo di PS-042/048/050: nuovi PNG
non tracciati sotto `assets/art/` per PS-052 (altro workflow in corso) non
ancora mappati, altrimenti `run_all` e rischio di TIMEOUT.

Bug temporaneo durante lo sviluppo, non presente nel risultato finale: per
una finestra di alcuni minuti `end_screen.gd` (firma `show_defeat`/
`show_victory` aggiornata a `RunSummary`) e `movement_slice.gd` (ancora al
vecchio `float`) sono stati incoerenti, rompendo la compilazione dell'intero
progetto. Individuato dal marker `SCRIPT ERROR: ... argument 1 should be
"RunSummary" but is "float"` durante la verifica di PS-048, non da questa
card; corretto prima di qualunque chiusura.
