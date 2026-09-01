---
id: PS-061
titolo: Eseguire il pacchetto di catture UI in CI per la validazione visiva remota
tipo: chore
area: tooling
stato: IN CORSO
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

- [ ] Il workflow è azionabile manualmente (`workflow_dispatch`) e non
      richiede input diversi da quelli di default.
- [ ] Esegue esattamente `tools/_capture_ui_screenshots.gd` senza
      modificarlo: nessun nuovo script di cattura, nessuna scena o profilo
      aggiuntivo.
- [ ] Il run fallisce (non solo stampa un avviso) se lo script termina con
      `CAPTURE_FAIL` o exit code diverso da 0, o se compare `SCRIPT ERROR`/
      `FATAL EXCEPTION` nei log — l'exit code da solo non basta, come da
      convenzione del progetto (`CLAUDE.md`).
- [ ] Le immagini prodotte in `exports/ui-screenshots/**` (entrambi i
      profili) sono pubblicate come artifact del workflow, scaricabile da
      GitHub Actions e da questa sessione via i tool GitHub già in uso per
      PS-060.
- [ ] Nessuna immagine viene committata nel repository: `exports/` resta
      fuori da git come da `.gitignore`.

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

- [ ] Runtime Windows: non pertinente, il percorso locale non cambia.
- [ ] Validazione statica APK: non pertinente, questa card non tocca l'APK.
- [ ] Runtime fisico Pixel 9: non pertinente.
- [ ] Controllo percettivo richiesto: no per la card in sé (è tooling); le
      immagini che produce possono pero' essere usate per un controllo
      percettivo su un'altra card.

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

## Documenti sincronizzati

- [ ] `docs/verification-workflow.md`: nota che rimanda al workflow CI come
      percorso alternativo per generare il pacchetto di catture.

## Note

Dipende da PS-044 (lo script deve già produrre catture "oneste") e da PS-060
(riusa gli step di installazione Godot già scritti e verificati in CI in
quella card).
