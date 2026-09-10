---
id: PS-150
titolo: Integra la nuova icona della passiva di Alea al posto dell'aquila
tipo: chore
area: arte
stato: BLOCCATO
priorita: media
dipende_da: [PS-149]
origine:
creato: 2026-09-10
aggiornato: 2026-09-10
---

# PS-150 — Integra la nuova icona della passiva di Alea al posto dell'aquila

## Contesto

[PS-149](./PS-149-genera-icona-passiva-alea-bottiglia-vino.md) produce il
candidato non wired per la nuova icona passiva di Alea (bottiglia di vino).
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
bottiglia di vino approvata da PS-149 al posto dell'aquila, senza cambiare
testo, layout o qualunque altro dato della passiva.

## Criteri di accettazione

- [ ] Il master approvato di PS-149 sostituisce
      `assets/art/icons/passives/hd/alea_eagle_never_misses_source.png` col
      nuovo file `hd/alea_two_fingers_and_go_source.png` (rinomina, non
      duplicazione: il vecchio file dell'aquila viene rimosso).
- [ ] Il derivato approvato di PS-149 sostituisce
      `assets/art/icons/passives/generated/alea_eagle_never_misses.png` col
      nuovo file `generated/alea_two_fingers_and_go.png` (stessa regola di
      rinomina).
- [ ] `data/friends/alea.tres` ripunta l'`ExtResource` di `passive_icon` al
      nuovo percorso `generated/alea_two_fingers_and_go.png`; nessun altro
      campo del file cambia.
- [ ] `assets/art/icons/passives/ASSET-MANIFEST.md` sposta la sezione del
      candidato PS-149 dalla tabella "in revisione" a quella dei wired
      correnti, aggiornando la riga Alea con i percorsi e gli hash
      definitivi.
- [ ] Il selettore personaggi mostra la nuova icona per Alea; nessuna
      regressione sul resto del selettore o su qualunque altro personaggio.
- [ ] Il refresh import Godot della nuova icona non produce `SCRIPT ERROR` né
      `FATAL EXCEPTION`.

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

- Smoke: regressione sul test esistente che verifica le icone passive del
  cast (se presente) o nuova asserzione mirata che `data/friends/alea.tres`
  risolve `passive_icon` a un percorso che non contiene `eagle`.
- Profilo minimo prima della chiusura: `Relevant`.

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

## Documenti sincronizzati

- [ ] `assets/art/icons/passives/ASSET-MANIFEST.md`: tabella wired aggiornata.
- [ ] `docs/characters.md`: nessuna modifica prevista, descrive già il tema
      "Due Dita e Parto" indipendentemente dall'icona.

## Note

Sbloccata quando PS-149 raggiunge almeno `IN VERIFICA` (candidato approvato
dal proprietario).
