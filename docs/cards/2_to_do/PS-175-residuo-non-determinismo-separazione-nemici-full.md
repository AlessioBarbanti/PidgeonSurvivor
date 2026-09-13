---
id: PS-175
titolo: Diagnostica il residuo di non-determinismo nella separazione nemici su Full
tipo: fix
area: gameplay
stato: PRONTO
priorita: bassa
dipende_da: [PS-171, PS-174]
origine: verifica PS-165 2026-09-13
creato: 2026-09-13
aggiornato: 2026-09-13
---

# PS-175 — Diagnostica il residuo di non-determinismo nella separazione nemici su Full

## Contesto

PS-174 ha diagnosticato e corretto tre difetti nel sistema di separazione
anti-sovrapposizione di PS-171 (`scripts/actors/base_enemy.gd`), incluso un
bug di determinismo causato da una cache statica condivisa fra fixture GUT
diverse nello stesso processo (`-Profile Full`), risolto indicizzando la
cache per `RunController` e ordinando ogni cella per `get_instance_id()`
prima di sommare i contributi di respinta. Verificato allora con `-Profile
Full` eseguito due volte consecutive, 143/143 entrambe le volte.

Durante la verifica di [PS-165](../4_to_test/PS-165-rendi-leggibili-scorrevoli-collisioni-prop.md)
(2026-09-13, card non correlata: collisioni statiche dei prop, nessun file
toccato interseca `base_enemy.gd`/`ranged_enemy.gd`), `-Profile Full` ha
fallito una volta su `tests/unit/test_ps171_enemy_overlap_separation.gd` con
scarti di posizione di 1-2px su diversi tiratori (es. tiratore #21: atteso
`(196.79, -102.23)`, ottenuto `(195.51, -101.11)`), poi è passato pulito al
secondo tentativo senza alcuna modifica nel frattempo. Il fix di PS-174
(ordinamento per instance_id) elimina la sensibilità all'ordine di iterazione
di `get_nodes_in_group()`, ma non necessariamente ogni fonte di non-
determinismo residua (es. l'ordine in cui le fixture precedenti nello stesso
processo vengono effettivamente liberate da `add_child_autofree`, che è
deferred e può variare leggermente il numero di nemici "fantasma" ancora vivi
al momento in cui parte una fixture successiva).

## Comportamento atteso

A parità di codice, `-Profile Full` deve produrre lo stesso esito (verde o
rosso) in esecuzioni ripetute consecutive. Se un piccolo scarto numerico è
fisiologico (somma in virgola mobile su centinaia di corpi), il test deve
dichiararlo esplicitamente con una tolleranza, invece di un'uguaglianza
esatta che lo rende un flake.

## Criteri di accettazione

- [ ] `-Profile Full` eseguito almeno 5 volte consecutive su
      `test_ps171_enemy_overlap_separation.gd` (o il file che lo sostituisce)
      produce lo stesso esito tutte le volte.
- [ ] Se la causa è un residuo di non-determinismo reale nella simulazione
      (non solo nel test), il fix vive in `scripts/actors/base_enemy.gd` o
      affini, non nell'allentare l'asserzione per nasconderlo.
- [ ] Se invece lo scarto è fisiologico (somma float non associativa anche a
      ordine fisso, entro un epsilon piccolo e stabile), il test lo dichiara
      con `assert_vector_near`/tolleranza esplicita invece di uguaglianza
      esatta, e la card motiva perché quell'epsilon è la scelta corretta.

## Ambito

- `scripts/actors/base_enemy.gd`: solo se emerge una causa reale ulteriore
  rispetto al fix di PS-174.
- `tests/unit/test_ps171_enemy_overlap_separation.gd`.
- Non toccare `scripts/game/obstacles/*` o `scenes/game/movement_slice.tscn`
  (PS-165): nessuna relazione con questa card.

## Verifica

- GUT: `tests/unit/test_ps171_enemy_overlap_separation.gd`.
- Profilo minimo prima della chiusura: `Full`, eseguito ripetutamente per
  raccogliere evidenza di stabilità (non basta una singola esecuzione verde,
  vista la natura intermittente del sintomo).

## Gate manuali

- [ ] Runtime Windows: non pertinente (bug di test/determinismo, non di feel).
- [ ] Validazione statica APK: non pertinente.
- [ ] Runtime fisico Pixel 9: non pertinente.
- [ ] Controllo percettivo richiesto: no.

## Decisioni

- **2026-09-13 — Aperta come card separata invece di espandere PS-165.**
  Nessun file toccato da PS-165 interseca la logica di separazione; il
  fallimento è emerso solo perché PS-165 esegue `-Profile Full` come parte
  della propria verifica.

## Documenti sincronizzati

- [ ] Nessuno atteso, salvo che l'indagine riveli un contratto di
      determinismo da formalizzare oltre quanto già scritto in PS-171/PS-174.

## Note

Evidenza raccolta durante la sessione di verifica di PS-165 (2026-09-13),
log del run fallito in
`C:\Users\aless\AppData\Local\Temp\il-gioco-verification\20260913-223906-PS-165\gut-regression.log`
(percorso locale, non nel repository). Il run immediatamente successivo,
identico per codice, è risultato verde (142/142).
