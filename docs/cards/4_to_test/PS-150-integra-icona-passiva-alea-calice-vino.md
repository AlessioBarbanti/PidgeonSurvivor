---
id: PS-150
titolo: Integra la nuova icona della passiva di Alea al posto dell'aquila
tipo: chore
area: arte
stato: IN VERIFICA
priorita: media
dipende_da: [PS-149]
origine:
creato: 2026-09-10
aggiornato: 2026-09-10
---

# PS-150 — Integra la nuova icona della passiva di Alea al posto dell'aquila

## Contesto

[PS-149](../5_completed/PS-149-genera-icona-passiva-alea-calice-vino.md) produce
il candidato non wired per la nuova icona passiva di Alea (calice di vino
rosso inclinato, con sbordo e stellina).
Questa card possiede la promozione ai percorsi canonici e il ripuntamento in
`data/friends/alea.tres`, che per il contratto PS-090 non appartengono a una
card `tipo: art`.

`data/friends/alea.tres` ha già `passive_id = &"alea_two_fingers_and_go"`
(rinominato da [PS-105](../4_to_test/PS-105-nuova-passiva-alea-due-dita-e-parto.md)),
ma `passive_icon` referenzia ancora
`assets/art/icons/passives/generated/alea_eagle_never_misses.png`: questo è
l'unico disallineamento rimasto fra dati e arte.

## Comportamento atteso

Nel selettore personaggi, la carta passiva di Alea mostra la nuova icona a
calice di vino approvata da PS-149 al posto dell'aquila, senza cambiare
testo, layout o qualunque altro dato della passiva.

## Criteri di accettazione

- [x] Il master approvato di PS-149 sostituisce
      `assets/art/icons/passives/hd/alea_eagle_never_misses_source.png` col
      nuovo file `hd/alea_two_fingers_and_go_source.png` (rinomina, non
      duplicazione: il vecchio file dell'aquila viene rimosso).
- [x] Il derivato approvato di PS-149 sostituisce
      `assets/art/icons/passives/generated/alea_eagle_never_misses.png` col
      nuovo file `generated/alea_two_fingers_and_go.png` (stessa regola di
      rinomina).
- [x] `data/friends/alea.tres` ripunta l'`ExtResource` di `passive_icon` al
      nuovo percorso `generated/alea_two_fingers_and_go.png`; nessun altro
      campo del file cambia.
- [x] `assets/art/icons/passives/ASSET-MANIFEST.md` sposta la sezione del
      candidato PS-149 dalla tabella "in revisione" a quella dei wired
      correnti, aggiornando la riga Alea con i percorsi e gli hash
      definitivi.
- [x] Il selettore personaggi mostra la nuova icona per Alea; nessuna
      regressione sul resto del selettore o su qualunque altro personaggio —
      verificato da `test_b18w_character_select_refinement.gd` (aggiornato
      al nuovo percorso) e dal resto della suite `Relevant` (20/20).
- [x] Il refresh import Godot della nuova icona non produce `SCRIPT ERROR` né
      `FATAL EXCEPTION` (profilo `Focused -RefreshEditor`, 3/3 verdi).

## Ambito

- `assets/art/icons/passives/hd/`, `assets/art/icons/passives/generated/`:
  solo i due file di Alea.
- `data/friends/alea.tres`: solo `passive_icon`.
- `assets/art/icons/passives/ASSET-MANIFEST.md`.

Non toccare:

- `passive_id`, testo, o qualunque altro campo di `data/friends/alea.tres`;
- il calice HUD di Alea (PS-104/PS-106), asset distinto;
- le altre sette icone passive del cast;
- `scripts/content/friend_passive_controller.gd` e la logica della passiva
  (PS-105), invariata.

## Verifica

- Smoke: `tests/unit/test_b18w_character_select_refinement.gd`, aggiornato
  al nuovo percorso `alea_two_fingers_and_go.png` per l'attesa
  `EXPECTED_PASSIVE_ICON_PATHS[&"alea"]` (prima referenziava ancora
  `alea_eagle_never_misses.png`).
- Focused (`-RefreshEditor`): `3/3` file, nessun `SCRIPT ERROR`/
  `FATAL EXCEPTION`.
- Relevant: `4/4` focused, `20/20` regressioni, 24/24 step, nessun
  `SCRIPT ERROR`/`FATAL EXCEPTION`.
- Full: `137/137` regressioni (426 asserzioni, 0 fallite), toolchain PASS,
  138/138 step, nessun `SCRIPT ERROR`/`FATAL EXCEPTION`.

## Gate manuali

- [ ] Runtime Windows
- [ ] Validazione statica APK
- [ ] Runtime fisico Pixel 9 (percorso: selettore personaggi, carta Alea)
- [ ] Controllo percettivo richiesto: sì, l'icona nel selettore alla
      dimensione reale

## Decisioni

- **2026-09-10 — Separata da PS-149 per PS-090.** Il cambio di soggetto
  richiede un nuovo slug di file, quindi un ripuntamento reale in
  `data/friends/alea.tres`: non è un rinfresco in-place come PS-131.
- **2026-09-10 — Promossa subito dopo l'approvazione di PS-149.** Il
  proprietario ha approvato il candidato e chiesto esplicitamente di
  integrarlo («sostituiamola in game»). Rinomina in-place (non copia): i
  vecchi file `alea_eagle_never_misses*` sono stati rimossi da git, non
  lasciati come doppioni.
- **2026-09-10 — Automatici verdi, gate manuali lasciati aperti per
  onestà.** Nessun export/avvio Windows reale, ispezione statica APK o
  prova fisica Pixel 9 eseguiti in questa sessione; il controllo percettivo
  copre solo il candidato isolato (PS-149), non ancora l'icona wired dentro
  il selettore reale.

## Documenti sincronizzati

- [x] `assets/art/icons/passives/ASSET-MANIFEST.md`: tabella wired
      aggiornata con i percorsi e gli hash definitivi di Alea; sezione
      candidato PS-149 marcata "approvato e promosso".
- [x] `docs/characters.md`: nessuna modifica necessaria, descrive già il
      tema "Due Dita e Parto" indipendentemente dall'icona.

## Note

Sbloccata quando PS-149 raggiunge almeno `IN VERIFICA` (candidato approvato
dal proprietario).
