---
id: PS-206
titolo: Fai puntare la pre-release di debug al commit compilato
tipo: fix
area: tooling
stato: IN CORSO
priorita: media
dipende_da: []
origine:
creato: 2026-09-22
aggiornato: 2026-09-22
---

# PS-206 — Fai puntare la pre-release di debug al commit compilato

## Contesto

`android-debug-release.yml` (PS-060) pubblica l'APK di debug sulla
pre-release `android-debug-latest`, dichiarata in `docs/setup.md` come "tag
mobile". Il tag però non si muove: `softprops/action-gh-release` aggiorna
asset e descrizione di una release esistente ma non sposta il suo tag. Dopo
la pubblicazione del 22 settembre (run 35665231120, commit `80dfc13`) l'APK e
la descrizione erano nuovi, mentre il tag puntava ancora a `076cdb5` (PS-060),
la release mostrava come data il 1° settembre e come destinazione `main`. Chi
scarica l'APK riceve la build giusta; chi guarda il tag o il sorgente allegato
trova codice di settembre.

## Comportamento atteso

Dopo ogni esecuzione riuscita del workflow, la pre-release
`android-debug-latest` punta al commit appena compilato: tag, destinazione,
data di pubblicazione, descrizione e APK si riferiscono tutti alla stessa
build.

## Criteri di accettazione

- [ ] Dopo un'esecuzione riuscita, `git ls-remote origin
      refs/tags/android-debug-latest` restituisce lo SHA compilato dalla run.
- [ ] La pre-release ha data di pubblicazione della run e resta marcata come
      pre-release, con l'APK di debug come asset.
- [ ] Se la build o i controlli statici falliscono, la pre-release precedente
      resta intatta: la vecchia viene rimossa solo dopo che l'APK nuovo ha
      superato i controlli.
- [ ] Alla prima esecuzione, quando la pre-release non esiste ancora, il
      workflow non fallisce.

## Ambito

- `.github/workflows/android-debug-release.yml`, solo il passo di
  pubblicazione.
- Non toccare `android-release.yml` (PS-134): la release pubblica è taggata
  `v<versione>` da un tag nuovo a ogni versione e non ha questo problema.
- Non toccare build, versioni della toolchain né controlli statici dell'APK.

## Verifica

- Nessun test GUT: la card non cambia il runtime del gioco.
- Verifica: una run `workflow_dispatch` su `develop`, poi `git ls-remote` del
  tag e `gh release view android-debug-latest`.

## Gate manuali

- [ ] Runtime Windows — non pertinente
- [ ] Validazione statica APK — coperta dal workflow stesso
- [ ] Runtime fisico Pixel 9 — non pertinente
- [ ] Controllo percettivo richiesto: no

## Decisioni

- **2026-09-22 — Ricreare la pre-release invece di spostare solo il tag.**
  Cancellare la release insieme al suo tag (`gh release delete
  --cleanup-tag`) e ricrearla con `target_commitish` sullo SHA della run
  sistema in un colpo solo tag, destinazione e data; spostare soltanto il tag
  avrebbe lasciato la data del 1° settembre. La cancellazione avviene dopo i
  controlli statici, così un errore di build non lascia senza pre-release.
- **Rischio accettato:** se fallisce proprio il caricamento, dopo la
  cancellazione, la pre-release manca fino alla run successiva. È una build
  interna di debug; l'APK resta comunque fra gli artifact della run.

## Documenti sincronizzati

- [ ] `docs/setup.md` — nessuna modifica attesa: dichiara già il "tag
      mobile", che ora lo diventa davvero.

## Note

Scoperta durante la pubblicazione della pre-release di PS-202.
