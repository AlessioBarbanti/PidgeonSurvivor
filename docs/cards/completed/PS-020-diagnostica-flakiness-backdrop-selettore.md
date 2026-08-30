---
id: PS-020
titolo: Diagnostica il fallimento intermittente sul backdrop del selettore
tipo: chore
area: tooling
stato: COMPLETATO
priorita: bassa
dipende_da: []
origine:
creato: 2026-08-30
aggiornato: 2026-08-30
---

# PS-020 — Diagnostica il fallimento intermittente sul backdrop del selettore

## Contesto

`tests/unit/test_b18b_visual_identity.gd` fallisce in modo intermittente e
non deterministico su un controllo del fondale pixel-art tracciato del
selettore personaggi (contratto B18W in `movement_slice.gd`), con lo stesso
identico worktree fra un'esecuzione e l'altra. Scoperto durante la
migrazione dei test da smoke legacy a GUT; il comportamento intermittente
era già presente nello smoke legacy equivalente. Ipotesi più probabile:
effetto collaterale del restyle asset in corso da parte dell'utente
sull'area proiettili/personaggi (non tracciato da questa card), che può
introdurre una dipendenza da timing o da uno stato di caricamento asset non
ancora completamente deterministico nel test.

## Comportamento atteso

Il test relativo al backdrop pixel-art del selettore produce lo stesso
esito (verde o rosso) a ogni esecuzione, a parità di codice e asset, senza
dipendere dall'ordine di caricamento o da tempistiche non controllate.

## Criteri di accettazione

- [x] Causa radice dell'intermittenza identificata e documentata in questa
      card (dipendenza da frame non atteso, asset caricato in modo
      asincrono, stato condiviso non resettato, o altro).
- [x] Il test produce lo stesso esito per almeno 10 esecuzioni consecutive
      in isolamento (`-gtest=` sul solo file).
- [x] Se la causa è nel test (attesa di frame insufficiente, seed non
      fissato), il test viene reso deterministico senza allargare
      tolleranze per farlo passare artificialmente.
      *Condizione non ricorsa: la causa non è nel test. Nessuna riga di
      `test_b18b_visual_identity.gd` è stata toccata e nessuna tolleranza è
      stata allargata.*
- [x] Se la causa è nel codice di gioco (es. un ordine di inizializzazione
      non garantito), il problema reale viene descritto qui e, se richiede
      una modifica al codice di gioco, viene aperta una card separata per
      quella modifica.
      *Condizione non ricorsa: la causa non è nel codice di gioco. È stata
      comunque aperta [PS-021](./PS-021-import-orfano-backdrop-bronze.md)
      per il residuo di igiene emerso durante la diagnosi.*

## Ambito

- `tests/unit/test_b18b_visual_identity.gd` e, se la causa risultasse nel
  codice di gioco, il contratto B18W del fondale pixel-art in
  `scripts/game/movement_slice.gd` (solo diagnosi in questa card; l'eventuale
  fix del codice di gioco va in una card dedicata).

Non modificare come soluzione di comodo:

- non allargare tolleranze numeriche o temporali solo per far passare il
  test senza capire la causa.

## Verifica

- Test: `tests/unit/test_b18b_visual_identity.gd`.
- Profilo minimo prima della chiusura: `Focused` ripetuto più volte per
  confermare la scomparsa dell'intermittenza.

## Gate manuali

- [x] Runtime Windows: non richiesto per la sola diagnosi.
- [x] Validazione statica APK: non richiesta.
- [x] Runtime fisico Pixel 9: non richiesto.
- [x] Controllo percettivo richiesto: no.

## Decisioni

- **2026-08-30 — Scoperto durante la migrazione GUT, non introdotto da
  essa.** L'intermittenza era già presente nello smoke legacy equivalente
  con lo stesso identico worktree.
- **2026-08-30 — Causa radice: cache di import Godot assente, non
  intermittenza del test.** Il controllo B18W leggeva
  `_character_select_overlay.get_backdrop().texture`; quando
  `.godot/imported/` non contiene il `.ctex` di
  `assets/art/ui/character_select/character_select_backdrop.png`, una run di
  gioco headless (che non importa nulla da sola) ottiene `texture == null` e
  il contratto fallisce correttamente. `.godot/` è generato e **non** fa
  parte del worktree: due run "a parità di worktree" possono quindi vedere
  stati di import diversi. Nessun frame mancante, nessun seed, nessuno stato
  condiviso fra test.
- **2026-08-30 — Nessuna modifica a test o codice di gioco.** Il contratto
  B18W ha fatto il suo lavoro: ha segnalato un asset non caricabile.
  Renderlo tollerante nasconderebbe una build senza fondale. Il presidio
  corretto resta quello già scritto in `CLAUDE.md`: dopo aver toccato un
  asset importato si rinfresca la cache dell'editor (`-RefreshEditor`) prima
  di eseguire i test.
- **2026-08-30 — Residuo separato.** Il `.import` orfano del vecchio nome
  `character_select_backdrop_bronze.png` è stato spostato su
  [PS-021](./PS-021-import-orfano-backdrop-bronze.md) invece di allargare
  questa card.

## Documenti sincronizzati

- [x] Nessuno: la regola operativa (`-RefreshEditor` dopo un asset
      importato) è già in `CLAUDE.md`, sezione «Verifica».

## Note

**Ricostruzione dai log storici** (`%TEMP%\il-gioco-verification\`):

| Ora (2026-08-29) | Evento |
|---|---|
| 21:41–21:45 | quattro run `B18B` verdi |
| 21:45 | `character_select_backdrop.png` sostituito su disco (restyle del proprietario, poi commit `3d048e4`) |
| 21:46:25 | in `.godot/imported/` esiste solo il `.ctex` del vecchio nome `character_select_backdrop_bronze.png` |
| 21:47:18 e 21:48:33 | `20260829-214718-B18B`, `20260829-214833-B18B`: `B18W richiede il fondale pixel-art tracciato del selettore.` → `B18V_CONTRACT_FAIL` |
| 21:49:20 in poi | run di nuovo verdi (import rigenerato nel frattempo) |
| 22:02:24 | scritti `character_select_backdrop.png.import` e il `.ctex` corrispondente, ancora attuali |

Le uniche due occorrenze del messaggio in tutto lo storico dei log sono
quelle delle 21:47 e 21:48, dentro la finestra in cui il PNG nuovo esisteva
ma non era ancora importato.

**Riproduzione controllata (2026-08-30).** Rimossi temporaneamente
`.godot/imported/character_select_backdrop.png-156b3db126d93388c30c78576161e11c.ctex`
e il `.md5` gemello (copiati prima in area temporanea), poi:

```powershell
.\tools\run-milestone-checks.ps1 -Milestone PS-020 -Profile Focused `
  -FocusedSmoke tests/unit/test_b18b_visual_identity.gd -OutputMode Detailed -NoCache
```

→ `status=FAIL`, log `20260830-133444-PS-020`, stesso identico messaggio
`B18W richiede il fondale pixel-art tracciato del selettore.` seguito da
`B18V_CONTRACT_FAIL`. Ripristinati i due file (`dest_md5` verificato), il
test torna verde.

**Dieci esecuzioni consecutive in isolamento (2026-08-30).** Con
`-NoCache` — senza, la cache del runner restituisce `CACHED` e le ripetizioni
non provano nulla:

```
run=1..10 status=PASS
```

Log da `20260830-133043-PS-020` a `20260830-133348-PS-020`.
