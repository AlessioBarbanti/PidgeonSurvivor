---
id: PS-175
titolo: Diagnostica il residuo di non-determinismo nella separazione nemici su Full
tipo: fix
area: gameplay
stato: IN VERIFICA
priorita: bassa
dipende_da: [PS-171, PS-174]
origine: verifica PS-165 2026-09-13
creato: 2026-09-13
aggiornato: 2026-09-16
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

- [x] Cinque Full consecutivi senza cache verdi sul test di separazione.
- [x] Causa nella fixture riprodotta e corretta, runtime invariato.
- [x] Nessun allargamento della tolleranza: resta 0,001 px per ogni posizione.

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

Windows runtime, APK e Pixel 9 non pertinenti: cambia solo il test.
Revisione del branch prima dell'integrazione; nessun merge automatico.

## Decisioni

- **2026-09-13 — Aperta come card separata invece di espandere PS-165.**
  Nessun file toccato da PS-165 interseca la logica di separazione; il
  fallimento è emerso solo perché PS-165 esegue `-Profile Full` come parte
  della propria verifica.


- **2026-09-16 — Causa riprodotta nella fixture, nessun epsilon allargato.**
  Il primo `_physics_process(1/60)` partiva dal ciclo grafico, dopo un'attesa
  di process frame. `move_and_slide()` prende il delta dell'engine e non
  quello passato al metodo del nemico. La sonda ha misurato `physics=false`,
  delta grafico 0,006896 contro 0,006944444 s nelle due simulazioni: un errore
  iniziale che la separazione a molti corpi amplifica. Il Focused originale
  ha fallito tutte le 32 posizioni (`20260916-010332-PS-175`).
  Ogni passo attende ora `SceneTree.physics_frame` prima di muovere i corpi,
  incluso il primo e il caso del nemico singolo. Tolleranza invariata 0,001;
  nessun intervento al runtime, alla griglia o al bilanciamento.
- **2026-09-16 — Due cause diverse.** PS-177 riguarda un evento di collisione
  pendente per una posizione iniziale errata; PS-175 un delta grafico usato
  per il primo passo fisico. Non si introduce un reset globale delle fixture
  per nascondere due difetti locali distinti.

## Documenti sincronizzati

- [x] Board e `docs/verification-workflow.md`.

## Note

Evidenza raccolta durante la sessione di verifica di PS-165 (2026-09-13),
log del run fallito in
`C:\Users\aless\AppData\Local\Temp\il-gioco-verification\20260913-223906-PS-165\gut-regression.log`
(percorso locale, non nel repository). Il run immediatamente successivo,
identico per codice, è risultato verde (142/142).


Verifica finale 2026-09-16: cinque esecuzioni consecutive di Full con
-NoCache e un solo processo GUT: 150 script / 469 test verdi per esecuzione,
toolchain e project smoke verdi. Nessun SCRIPT ERROR, FATAL EXCEPTION,
SMOKE_FAIL o CONTRACT_FAIL. Log in %TEMP%/il-gioco-verification:
20260916-081407-PS-188, 20260916-081639-PS-188, 20260916-081909-PS-188,
20260916-082143-PS-188, 20260916-082416-PS-188.

Stato IN VERIFICA per la revisione del branch refactor/test-cleaning-2026-09-16.

Verifica aggiuntiva sul risultato finale del branch, dopo PS-178:
`20260916-150244-PS-188` Full senza cache, 151 script / 474 casi nello
stesso processo GUT, nessun fallimento o pending e nessun marker di errore.
Release `20260916-145813-PS-178`: 474 casi, smoke Windows e APK statico
verdi; Android fisico aperto. Le misure del lag e i relativi limiti restano
nella card PS-178, distinta dalle correzioni delle fixture e del runner.
