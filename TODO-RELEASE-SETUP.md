# TODO — Setup rilascio (guida temporanea)

> File temporaneo, non fa parte della board `docs/cards/`. Da cancellare
> una volta completati questi passi (PS-133, PS-134).

Due cose bloccano la pipeline di rilascio, e nessuna è eseguibile da una
sessione Claude: entrambe richiedono accesso a impostazioni/segreti che
questa sessione non ha.

## 1. Rinominare il branch `main` → `develop` (PS-133)

Su GitHub, interfaccia web:

1. **Settings → Branches** → accanto a `main`, pulsante di rinomina →
   nuovo nome `develop`. GitHub sposta il branch di default, retargeta le
   PR aperte e crea i redirect.
2. Sempre in Branches: **creare un nuovo `main`** a partire da `develop`.
   Ordine obbligatorio: al contrario GitHub rifiuta la rinomina per
   collisione di nome.
3. Consigliato: proteggere `main` in modo che accetti solo merge da pull
   request, così un push diretto non fa partire per errore una build
   pubblica (il workflow di release scatta su `push` a `main`).

Poi, in locale:

```powershell
git branch -m main develop
git fetch origin --prune
git branch -u origin/develop develop
git remote set-head origin -a
```

## 2. Creare il keystore di release e caricare i secret (PS-134)

Il workflow `android-release.yml` fallisce finché questi tre secret non
esistono (Settings → Secrets and variables → Actions):

| Secret | Contenuto |
|---|---|
| `ANDROID_KEYSTORE_BASE64` | il `.jks` codificato base64 |
| `ANDROID_KEYSTORE_PASSWORD` | password del keystore e della chiave (devono coincidere) |
| `ANDROID_KEY_ALIAS` | alias della chiave, es. `pidgeon-survivor` |

Creazione del keystore, una volta sola, in locale — **mai** nel repository:

```powershell
keytool -genkeypair -v `
  -keystore pidgeon-survivor-release.jks `
  -alias pidgeon-survivor `
  -keyalg RSA -keysize 2048 -validity 10000
```

Conversione in base64 per il secret:

```powershell
[Convert]::ToBase64String([IO.File]::ReadAllBytes("pidgeon-survivor-release.jks")) `
  | Set-Content pidgeon-survivor-release.jks.b64
```

Il file `.jks` va in un backup sicuro fuori dal repository: chi lo perde
non può più aggiornare l'app già installata sui telefoni della gente.

Dettagli completi: `docs/setup.md` §"Flusso di branch e rilascio" e
§"Firma release"; card [PS-133](docs/cards/3_in_sprint/PS-133-develop-per-lo-sviluppo-main-per-il-rilascio.md)
e [PS-134](docs/cards/3_in_sprint/PS-134-apk-di-release-firmato-e-versionato-al-merge-su-main.md).
