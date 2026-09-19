---
id: PS-191
titolo: Ripristina il rilascio dopo il tentativo di ripubblicare v0.3.0
tipo: fix
area: tooling
stato: COMPLETATO
priorita: alta
dipende_da: [PS-134]
origine: Run GitHub fallita dopo il merge della PR 19, segnalata dal proprietario
creato: 2026-09-17
aggiornato: 2026-09-19
---

# PS-191 — Ripristina il rilascio dopo il tentativo di ripubblicare v0.3.0

## Contesto

Il merge della PR #19 ha avviato la run
[35264823462](https://github.com/AlessioBarbanti/PidgeonSurvivor/actions/runs/35264823462)
su `main` (`385e79e`). Lo step `Refuse to republish an existing version`
ha fermato il job prima della compilazione: `config/version` vale ancora
`0.3.0`, il cui tag e la cui Release esistono dal 2026-09-14.

## Comportamento atteso

Il contenuto integrato viene pubblicato come `v0.3.1`, con `versionCode=301`,
attraverso il normale merge `develop` → `main` e i gate del workflow PS-134.

## Criteri di accettazione

- [x] `project.godot` dichiara `0.3.1`; il tag risulta libero prima del rilascio.
- [x] La run di rilascio supera il controllo del tag e termina con successo.
- [x] La Release `v0.3.1` contiene un APK firmato, non debuggabile, con
      `versionName=0.3.1` e `versionCode=301`, verificato dal workflow.
- [x] Il tag e la Release `v0.3.0` restano intatti.

## Ambito

`project.godot`, questa card, board e istruzioni di preflight in `docs/setup.md`.

## Verifica

Controllo del diff, formato versione, formula del versionCode e disponibilità
del tag remoto; esecuzione reale di `android-release.yml` e ispezione dei log.
Nessuna modifica al gameplay: la suite GUT dell'integrazione resta evidenza
separata (484/484), senza ripeterla per il solo numero di versione.

## Gate manuali

Il runtime fisico dell'APK su Pixel 9 rimane aperto in PS-134; il lag residuo
con Marghe resta in PS-189. Il successo della pubblicazione non chiude quei gate.

## Decisioni

- **2026-09-17 — Incremento patch esplicito per recuperare il rilascio fallito.**
  `0.3.1` è il primo patch successivo disponibile. Si conserva il controllo
  contro la sovrascrittura delle versioni pubblicate; rilanciare il vecchio
  commit senza cambiare versione riprodurrebbe lo stesso errore.
- 2026-09-19: chiusa dal proprietario con il passaggio in blocco di tutte le card `IN VERIFICA` a `COMPLETATO`.

## Documenti sincronizzati

- [x] `docs/setup.md`: preflight della versione prima del merge di rilascio.
- [x] `docs/cards/README.md`: stato ed evidenze della correzione.

## Evidenze

- **2026-09-17 — Preflight locale:** `PS191_VERSION_OK version=0.3.1
  versionCode=301`; `git diff --check` superato. `git ls-remote` completato
  senza errori e senza risultati per `refs/tags/v0.3.1`. La Release `v0.3.0`
  resta pubblicata. Verifica CI della nuova versione in attesa del merge.
- **2026-09-19 — Rilascio CI:** merge della PR #21 su `main` (`bb54e94`),
  run [35407623940](https://github.com/AlessioBarbanti/PidgeonSurvivor/actions/runs/35407623940)
  verde in tutti gli step, compreso il controllo del tag. La Release `v0.3.1`
  contiene `pidgeon-survivor.apk` (68 500 998 byte); l'ispezione statica del
  workflow riporta `versionCode='301' versionName='0.3.1'`, nessun
  `application-debuggable`, firma APK Signature Scheme v2 verificata. Tag e
  Release `v0.3.0` intatti. Il tag `v0.3.1` punta a `ee3879f` (testa di
  `develop`) invece che al merge: stesso albero di `bb54e94`, nessuna
  differenza di contenuto.
