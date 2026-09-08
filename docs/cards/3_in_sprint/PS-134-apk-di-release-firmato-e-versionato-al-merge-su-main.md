---
id: PS-134
titolo: Pubblica un APK di release firmato e versionato al merge su main
tipo: chore
area: tooling
stato: IN CORSO
priorita: alta
dipende_da: [PS-133]
origine:
creato: 2026-09-08
aggiornato: 2026-09-08
---

# PS-134 — Pubblica un APK di release firmato e versionato al merge su main

## Contesto

L'unica build automatica esistente è quella di
[PS-060](../5_completed/PS-060-ci-build-apk-github-release.md):
`.github/workflows/android-debug-release.yml` esporta con `--export-debug`,
firma col keystore di debug di Godot, pubblica come **prerelease** sul tag
mobile `android-debug-latest` e dichiara nel corpo della Release di non essere
una build firmata. Serve a una sessione senza toolchain locale, non a un
giocatore.

Il proprietario vuole una seconda build, distinta: quella che la gente scarica.
Deve essere senza debugger, firmata davvero, e corredata da un numero di
versione — e deve uscire solo quando `develop` viene mergiato su `main`
([PS-133](./PS-133-develop-per-lo-sviluppo-main-per-il-rilascio.md)).

Due ostacoli reali, accertati sul repository:

- **Non esiste un keystore di release.** `docs/setup.md` §«Firma release e
  Google Play futuro» lo documenta già come futuro, con le tre variabili
  `GODOT_ANDROID_KEYSTORE_RELEASE_PATH` / `_USER` / `_PASSWORD` che Godot legge.
  Senza keystore, `--export-release` non produce un APK installabile.
- **Non esiste un numero di versione propagato.** `project.godot` ha
  `config/version="0.1.0"`, ma `export_presets.cfg` ha `version/name=""` e
  `version/code=1` fissi su entrambi i preset Android: l'APK di oggi non porta
  alcuna versione leggibile.

## Comportamento atteso

Un merge di `develop` su `main` fa partire un nuovo workflow dedicato che
esporta il preset `Android APK` in **release** (nessun debugger, nessun
overhead di debug), lo firma col keystore di release conservato nei GitHub
Secrets, e pubblica una GitHub Release **non** prerelease, taggata con la
versione del gioco, con l'APK come asset scaricabile.

Il numero di versione ha una sola fonte di verità: `config/version` in
`project.godot`. Il workflow lo legge, lo scrive in `version/name` del preset
nella copia di lavoro della CI (senza committare nulla), ne deriva un
`version/code` intero e monotono, e infine **verifica sull'APK prodotto** che
la versione dichiarata sia davvero quella attesa. Alzare la versione è quindi
un solo gesto: cambiare `config/version` nel commit che va su `main`.

Il workflow di debug di PS-060 resta esattamente com'è: `workflow_dispatch`,
prerelease, tag mobile. Le due build non si sovrascrivono a vicenda perché
usano tag di Release diversi.

## Criteri di accettazione

- [ ] Esiste `.github/workflows/android-release.yml` che scatta su `push` verso
      `main` e, in aggiunta, a mano da `workflow_dispatch`.
- [ ] Il workflow di debug `android-debug-release.yml` conserva il trigger
      `workflow_dispatch` e il tag `android-debug-latest`: le due build non si
      contendono la stessa Release.
- [ ] L'export usa `--export-release`, non `--export-debug`.
- [ ] L'ispezione statica dell'APK prodotto **fallisce** la build se
      `aapt2 dump badging` riporta `application-debuggable`: è la verifica
      osservabile di «senza debugger», non un'assunzione basata sul flag di
      export.
- [ ] L'ispezione statica **fallisce** la build se il certificato riportato da
      `apksigner verify --print-certs` è quello di debug di Android
      (`CN=Android Debug`): garantisce che sia stato usato il keystore vero e
      non un fallback silenzioso.
- [ ] `aapt2 dump badging` riporta `versionName` uguale a `config/version` di
      `project.godot` e `versionCode` uguale al valore derivato; se non
      coincidono la build fallisce.
- [ ] Il workflow fallisce con un messaggio esplicito, prima di iniziare
      l'export, se manca uno dei secret del keystore: nessun tentativo di
      proseguire producendo un artefatto inutilizzabile.
- [ ] Il workflow fallisce se esiste già un tag per la versione corrente:
      pubblicare due volte la stessa versione richiede di alzare
      `config/version`, non di sovrascrivere una Release esistente.
- [ ] La GitHub Release prodotta ha `prerelease: false`, tag `v<versione>`, e
      l'APK come asset scaricabile.
- [ ] `export_presets.cfg` **non** viene modificato nel repository: la
      valorizzazione di `version/name` e `version/code` avviene solo nella copia
      di lavoro della CI.
- [ ] Restano invariati package id, `minSdk` 31, `targetSdk` 36 e la sola ABI
      `arm64-v8a`, verificati come già fa il workflow di debug.

## Ambito

- Nuovo `.github/workflows/android-release.yml`.
- `docs/setup.md`: sezione della firma release aggiornata da «quando verrà
  creato» a procedura operativa, più i nomi dei secret attesi.

Non toccare:

- `.github/workflows/android-debug-release.yml` (se non per una nota di
  rimando) e `.github/workflows/ui-screenshots.yml`;
- `export_presets.cfg` e `project.godot` in repository: la versione si alza
  quando si decide di rilasciare, non in questa card;
- il preset `Android AAB (future)`, che resta uno smoke strutturale;
- qualunque file di gioco, scena, dato o script runtime.

## Verifica

- Nessuno smoke GUT: la card non tocca il runtime del gioco. La verifica vive
  dentro il workflow stesso, come gate che fanno fallire la build (debuggable,
  certificato, versione, tag duplicato).
- La prova reale è la prima esecuzione verde su `main` con l'APK installabile
  scaricato dalla Release.

## Gate manuali

- [ ] **Creazione del keystore di release e caricamento dei secret** — la deve
      eseguire il proprietario: questa sessione non ha accesso ai secret del
      repository. Comandi e nomi esatti in Note.
- [ ] Prima esecuzione del workflow su `main` conclusa verde, con la Release
      pubblicata e l'APK presente fra gli asset.
- [ ] Runtime fisico Pixel 9: l'APK **di release** scaricato dalla Release va
      installato su device e il gioco avviato almeno fino a una run. Una build
      release non è mai stata provata su device: cambia il livello di
      ottimizzazione e la firma, quindi il gate di PS-060 non vale per questa.

Non pertinenti: controllo percettivo, runtime Windows (nessuna modifica al
gioco).

## Decisioni

- **2026-09-08 — Trigger: `push` su `main`.** È il modo in cui GitHub segnala
  un merge completato di `develop` su `main`. Nota nota e accettata: scatta
  anche su un push diretto a `main`, non solo su un merge da PR. La protezione
  del branch suggerita in PS-133 è ciò che rende il caso improbabile; il
  workflow non prova a distinguere i due, perché farlo richiederebbe di
  ispezionare il tipo di commit e produrrebbe falsi negativi sui merge
  fast-forward.
- **2026-09-08 — Workflow separato invece di estendere quello di debug.**
  Le due build hanno trigger, flag di export, firma, tag e pubblico diversi:
  fonderle in un solo file avrebbe richiesto condizionali su quasi ogni step.
  Il costo è una certa duplicazione degli step di toolchain, accettata in
  cambio di due file leggibili ciascuno per conto proprio.
- **2026-09-08 — Scelta del proprietario: keystore di release vero, non firma
  di debug.** Fra le tre opzioni proposte (keystore vero nei secret; build
  release firmata col keystore di debug come tappa intermedia; card scritta ma
  build bloccata) il proprietario ha scelto il keystore vero. Conseguenza
  accettata: la pipeline non è verde finché i secret non esistono, ed è per
  questo che il workflow fallisce subito con un messaggio esplicito invece di
  produrre un artefatto non installabile.
- **2026-09-08 — Scelta del proprietario: `config/version` come unica fonte di
  verità.** Fra le tre opzioni proposte (`project.godot`; tag git; contatore
  della run CI) il proprietario ha scelto `project.godot`. Conseguenze: un solo
  valore da alzare, la versione mostrata dal gioco coincide con quella
  dell'APK e col tag della Release, e ripubblicare la stessa versione è un
  errore rilevato invece che una sovrascrittura silenziosa.
- **2026-09-08 — `version/code` derivato, non contato.** Formula
  `major*10000 + minor*100 + patch`, che da `0.1.0` dà `100`. È monotona
  finché minor e patch restano sotto 100 — vincolo dichiarato qui e verificato
  dal workflow, perché Android rifiuta un `versionCode` che non cresce e un
  contatore di run non avrebbe alcun rapporto con la versione mostrata.
- **2026-09-08 — I gate di onestà stanno nel workflow, non nella fiducia nei
  flag.** Passare `--export-release` non dimostra che l'APK non sia
  debuggabile, e configurare un keystore non dimostra che sia stato usato:
  entrambe le proprietà sono verificate sull'artefatto prodotto, coerentemente
  con la regola di progetto per cui l'exit code non basta.

## Documenti sincronizzati

- [ ] [docs/setup.md](../../../docs/setup.md): sezione «Firma release e Google
      Play futuro» aggiornata con procedura, nomi dei secret e rimando al
      workflow; sezione CI con la distinzione fra build di debug e build
      pubblica.

## Note

**Creazione del keystore (proprietario, una volta sola).** Da eseguire in
locale, mai nel repository:

```powershell
keytool -genkeypair -v `
  -keystore pidgeon-survivor-release.jks `
  -alias pidgeon-survivor `
  -keyalg RSA -keysize 2048 -validity 10000
```

Usare **la stessa password** per il keystore e per la chiave: Godot riceve una
sola password tramite `GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD` e non può
distinguerle.

Il file `.jks` va conservato in un backup sicuro e **mai** committato: chi
possiede quel keystore è, per Android, l'autore dell'app, e perderlo significa
non poter più aggiornare l'app già installata sui telefoni della gente.

**Secret da creare** (Settings → Secrets and variables → Actions):

| Secret | Contenuto |
|---|---|
| `ANDROID_KEYSTORE_BASE64` | il `.jks` codificato base64 |
| `ANDROID_KEYSTORE_PASSWORD` | la password scelta sopra |
| `ANDROID_KEY_ALIAS` | l'alias, qui `pidgeon-survivor` |

Per ottenere il base64:

```powershell
[Convert]::ToBase64String([IO.File]::ReadAllBytes("pidgeon-survivor-release.jks")) `
  | Set-Content pidgeon-survivor-release.jks.b64
```

**Come si pubblica una versione**, una volta chiusa la card: alzare
`config/version` in `project.godot` su `develop`, mergiare `develop` su `main`,
e il workflow fa il resto. Se si dimentica di alzarla, la build fallisce sul
tag già esistente invece di sovrascrivere la Release precedente.
