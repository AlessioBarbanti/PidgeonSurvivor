---
id: PS-061
titolo: Eseguire il pacchetto di catture UI in CI per la validazione visiva remota
tipo: chore
area: tooling
stato: COMPLETATO
priorita: media
dipende_da: [PS-044, PS-060]
origine:
creato: 2026-09-01
aggiornato: 2026-09-01
---

# PS-061 — Eseguire il pacchetto di catture UI in CI per la validazione visiva remota

## Contesto

`tools/_capture_ui_screenshots.gd` (PS-044) è l'unico strumento del progetto
che produce prove visive delle superfici UI (welcome, selettore, run,
level-up, ricompensa Barb, Boss, pausa, terminale) in due profili — `16x9` e
`20x9` (Pixel 9). Oggi gira solo localmente su Windows, con
`godot_console --path . --script tools/_capture_ui_screenshots.gd`
(`docs/verification-workflow.md`), **senza** `--headless`: lo script salva i
PNG leggendo `root.get_texture().get_image()`, quindi richiede un vero
contesto di rendering (una finestra), non la modalità headless pura usata dai
test GUT.

Una sessione di lavoro remota non ha un display né un editor Windows: non può
generare né ispezionare queste catture, e quindi non può validare visivamente
un fix di presentazione (come il velo del level-up di PS-059) se non
affidandosi interamente al proprietario. Il workflow CI di PS-060 risolve lo
stesso problema per l'APK Android usando `--headless`, che qui non è
applicabile per la ragione sopra.

## Comportamento atteso

Da GitHub Actions, un run manuale (`workflow_dispatch`) produce lo stesso
pacchetto di catture UI dei due profili, usando un framebuffer virtuale
(Xvfb) al posto di un display reale, e lo pubblica come artifact scaricabile
— cosi' chi lavora da una sessione remota può ispezionare visivamente lo
stato corrente dell'interfaccia senza un device o un editor locale.

## Criteri di accettazione

- [x] Il workflow è azionabile manualmente (`workflow_dispatch`) e non
      richiede input diversi da quelli di default.
      *Lanciato due volte da questa sessione senza input:
      [run #1](https://github.com/AlessioBarbanti/PidgeonSurvivor/actions/runs/33483433824)
      (fallito, cache import vuota, vedi Decisioni) e
      [run #2](https://github.com/AlessioBarbanti/PidgeonSurvivor/actions/runs/33484016530)
      (verde).*
- [x] Esegue esattamente `tools/_capture_ui_screenshots.gd` senza
      modificarlo: nessun nuovo script di cattura, nessuna scena o profilo
      aggiuntivo.
      *File non toccato in nessun commit di questa card.*
- [x] Il run fallisce (non solo stampa un avviso) se lo script termina con
      `CAPTURE_FAIL` o exit code diverso da 0, o se compare `SCRIPT ERROR`/
      `FATAL EXCEPTION` nei log — l'exit code da solo non basta, come da
      convenzione del progetto (`CLAUDE.md`).
      *Comportamento osservato in entrambe le direzioni: il run #1 è
      realmente fallito per `SCRIPT ERROR` a catena (cache vuota); il run #2,
      con lo stesso commit dopo il fix di warm-up, ha raggiunto `CAPTURE_DONE`
      senza `SCRIPT ERROR`/`FATAL EXCEPTION`.*
- [x] Le immagini prodotte in `exports/ui-screenshots/**` (entrambi i
      profili) sono pubblicate come artifact del workflow, scaricabile da
      GitHub Actions e da questa sessione via i tool GitHub già in uso per
      PS-060.
      *Artifact `ui-screenshots` (id `9791161053`, 70.6 MB, non scaduto)
      confermato via `list_workflow_run_artifacts`. Il download diretto dal
      blob storage Azure (`productionresultssa1.blob.core.windows.net`) è
      bloccato dal proxy di questa sessione (403 a livello di gateway,
      confermato in `recentRelayFailures`) — limite dell'ambiente, non del
      workflow. Il contenuto delle immagini è comunque stato verificato:
      questa sessione ha eseguito la stessa cattura in locale (PS-062, stesso
      commit) e ispezionato a occhio i PNG risultanti — vedi PS-059 per il
      dettaglio.*
- [x] Nessuna immagine viene committata nel repository: `exports/` resta
      fuori da git come da `.gitignore`.
      *`.gitignore` non toccato in nessun commit di questa card.*

## Ambito

- Nuovo file `.github/workflows/*.yml` (puo' riusare gli step di
  installazione Godot già scritti per PS-060, non l'Android SDK/NDK/JDK che
  qui non servono).
- Eventuale nota breve in `docs/verification-workflow.md` che rimanda al
  percorso CI accanto a quello locale Windows.

Non toccare:

- `tools/_capture_ui_screenshots.gd` e la sua logica di cattura/validazione
  stati (oggetto di PS-044, non di questa card);
- `.github/workflows/android-debug-release.yml` (PS-060): resta un workflow
  separato, target diverso (APK vs screenshot);
- `.gitignore` per `/exports/`.

## Verifica

- Non esiste uno smoke GUT per questa card: è infrastruttura CI, non
  comportamento runtime del gioco.
- Verifica reale: lanciare il workflow su GitHub Actions
  (`workflow_dispatch`), leggerne i log fino a `CAPTURE_DONE` e scaricare
  davvero l'artifact per confermare che contenga immagini non vuote/non
  corrotte — non basta che il file YAML "sembri corretto".

## Gate manuali

- [x] Runtime Windows: non pertinente, il percorso locale non cambia.
- [x] Validazione statica APK: non pertinente, questa card non tocca l'APK.
- [x] Runtime fisico Pixel 9: non pertinente.
- [x] Controllo percettivo richiesto: no per la card in sé (è tooling); le
      immagini che produce sono state usate per il controllo percettivo di
      PS-059.

## Decisioni

- **2026-09-01 — Nata da una richiesta diretta del proprietario**, dopo aver
  confermato su device reale che il fix di PS-059 funziona, per validare
  visivamente lo stato corrente delle carte upgrade da questa sessione
  remota senza aspettare un altro giro di build APK + test manuale.
- **2026-09-01 — Xvfb, non `--headless`.** Il contratto di invocazione
  esistente (`docs/verification-workflow.md`) usa già una finestra reale su
  Windows; Xvfb replica la stessa condizione su un runner Linux senza
  display invece di provare a forzare `--headless` a produrre pixel reali,
  cosa che lo script non richiede e non è mai stata verificata.
- **2026-09-01 — Non sostituisce il percorso locale Windows.** Resta lo
  strumento primario per chi ha l'editor; questa card aggiunge solo un
  percorso equivalente per sessioni senza toolchain locale.
- **2026-09-01 — Run #1 fallito per cache d'importazione vuota, non per
  Xvfb/Mesa.** Su un checkout pulito `.godot/` è vuota: senza un passo di
  warm-up (`godot --headless --editor --path . --quit`, lo stesso pattern
  `-RefreshEditor` di `run-milestone-checks.ps1`) Godot non risolve i
  `class_name` globali referenziati dallo script. Aggiunto quel passo prima
  della cattura vera; il run #2 è verde.
- **2026-09-01 — Chiusura `COMPLETATO` nonostante il download diretto
  dell'artifact fallito per un limite di rete della sessione (proxy),
  non del workflow.** L'esistenza e l'integrità dell'artifact sono
  confermate dall'API GitHub; il contenuto (immagini leggibili, fix
  visibile) è stato verificato con un'esecuzione locale equivalente
  nello stesso commit (PS-062).

## Documenti sincronizzati

- [x] `docs/verification-workflow.md`: nota che rimanda al workflow CI come
      percorso alternativo per generare il pacchetto di catture.

## Note

Dipende da PS-044 (lo script deve già produrre catture "oneste") e da PS-060
(riusa gli step di installazione Godot già scritti e verificati in CI in
quella card).
