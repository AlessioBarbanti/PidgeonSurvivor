---
id: PS-133
titolo: Adotta develop come branch di sviluppo e main come branch di rilascio
tipo: chore
area: tooling
stato: COMPLETATO
priorita: alta
dipende_da: []
origine:
creato: 2026-09-08
aggiornato: 2026-09-09
---

# PS-133 — Adotta develop come branch di sviluppo e main come branch di rilascio

## Contesto

Oggi il repository ha un solo branch a lungo termine, `main`, che riceve
direttamente tutto il lavoro. Non esiste quindi un punto nella storia che
significhi «questa è una versione che si può dare alla gente»: ogni commit su
`main` è indistinguibile da qualunque altro, e i due workflow CI esistenti
(`android-debug-release.yml` e `ui-screenshots.yml`) sono entrambi a solo
`workflow_dispatch` proprio perché nessun evento del repository segnala
l'intenzione di rilasciare.

Il proprietario vuole separare i due significati: `develop` per lo sviluppo
quotidiano, `main` come branch di rilascio, dove si arriva solo per merge da
`develop` — e quel merge diventa il segnale che fa partire la build pubblica
([PS-134](./PS-134-apk-di-release-firmato-e-versionato-al-merge-su-main.md)).

Verificato prima di procedere: **nessun workflow, script o documento del
repository filtra o referenzia il branch `main`** (i due workflow usano solo
`workflow_dispatch`, `tools/*.ps1` non contengono `origin/main`). L'unica
menzione è una frase discorsiva in `docs/powerup-catalog.md`. Non ci sono
pull request aperte. Il raggio d'impatto della rinomina è quindi minimo.

## Comportamento atteso

Il branch di default del repository si chiama `develop` e conserva l'intera
storia di `main`. Accanto a esso esiste `main`, che parte dallo stesso commit e
da lì in avanti avanza **solo** per merge da `develop`. Il lavoro quotidiano —
branch di card, sessioni Claude, commit — parte da `develop` e ci ritorna;
`main` resta la fotografia dell'ultima versione pubblicata.

La documentazione durevole descrive questo flusso in un solo posto, così che
una sessione futura non debba dedurlo dalla forma dei branch.

## Criteri di accettazione

- [x] Il branch di default del repository su GitHub è `develop` e contiene la
      stessa storia che aveva `main` (nessun commit perso, nessun rebase).
- [x] Esiste il branch `main` sul remoto, allineato a `develop` al momento
      della separazione.
- [x] La copia locale ha `develop` che traccia `origin/develop`, e
      `git remote show origin` riporta `develop` come HEAD.
- [x] `docs/setup.md` contiene una sezione che descrive il flusso
      `develop → main`, quale branch riceve il lavoro, cosa significa un merge
      su `main` e quale workflow ne scatta.
- [x] Nessun riferimento residuo a `main` come branch di sviluppo nei documenti
      durevoli: la frase in `docs/powerup-catalog.md` che dice «implementato e
      mergiato in `main`» è storica e va lasciata com'è, ma nessun documento
      deve istruire a lavorare su `main`.
- [x] Nessun workflow CI resta agganciato a un nome di branch inesistente
      (verifica esplicita: entrambi i workflow attuali usano solo
      `workflow_dispatch` e non vanno toccati da questa card).

## Ambito

- `docs/setup.md`: nuova sezione sul flusso di branch e rilascio.
- Operazioni sul repository GitHub e sulla copia locale (rinomina, creazione
  del nuovo `main`, riallineamento del tracking).

Non toccare:

- `.github/workflows/android-debug-release.yml` e
  `.github/workflows/ui-screenshots.yml`: restano a `workflow_dispatch`, il
  trigger di rilascio è materia di PS-134;
- la storia dei commit: la rinomina preserva `main` così com'è, senza rebase,
  squash o riscritture;
- la frase storica in `docs/powerup-catalog.md`.

## Verifica

- Nessuno smoke GUT: la card non tocca il runtime del gioco. La verifica è
  l'ispezione diretta dello stato dei branch sul remoto e in locale.

## Gate manuali

- [x] **Rinomina su GitHub** — eseguita dal proprietario: `develop` è il
      branch di default remoto, `main` esiste allineato. Procedura in Note.
- [x] Riallineamento della copia locale del proprietario dopo la rinomina:
      `develop` locale traccia `origin/develop`.

Non pertinenti: runtime Windows, validazione statica dell'APK, runtime fisico
Pixel 9, controllo percettivo — nessuna modifica al gioco.

## Decisioni

- **2026-09-08 — Rinomina vera, non semplice creazione di `develop`.**
  Richiesta esplicita del proprietario («rinominare il branch sia locale che
  remoto da main a develop»). Usare la funzione di rinomina di GitHub invece di
  creare un `develop` nuovo ha due vantaggi concreti: reindirizza
  automaticamente le pull request aperte e lascia dei redirect per i vecchi
  riferimenti. Con zero PR aperte al momento della decisione il vantaggio è
  teorico, ma il costo è nullo e la semantica è quella richiesta.
- **2026-09-08 — `main` viene ricreato dopo la rinomina, non prima.**
  Rinominando `main` in `develop` il repository resta senza `main`; il nuovo
  `main` va creato subito dopo dallo stesso commit. Nell'ordine inverso GitHub
  rifiuterebbe la rinomina per collisione di nome.
- **2026-09-08 — Il branch di default diventa `develop`.** È il branch su cui
  si lavora, quindi è quello che deve accogliere per default una nuova sessione
  o un clone. `main` resta un branch normale, di sola destinazione.
- **2026-09-09 — Verificato e chiuso.** Confermato via `gh api` che
  `default_branch` del repository è `develop`; `git remote show origin`
  riporta `develop` come HEAD; `main` esiste sul remoto (allineato al momento
  della separazione, poi avanzato per merge da `develop` come da disegno,
  incluso il primo merge che ha fatto scattare PS-134). `git branch -u
  origin/develop develop` già in vigore in locale. `docs/setup.md` contiene la
  sezione «Flusso di branch e rilascio». Nessun riferimento residuo a `main`
  come branch di sviluppo nei documenti durevoli (unica menzione storica
  invariata in `docs/powerup-catalog.md`). Nessuno dei due workflow esistenti
  (`android-debug-release.yml`, `ui-screenshots.yml`) è stato toccato. Tutti i
  criteri e i gate manuali sono soddisfatti: card completata.

## Documenti sincronizzati

- [x] [docs/setup.md](../../../docs/setup.md): sezione «Flusso di branch e
      rilascio».

## Note

**Procedura per il proprietario (GitHub, interfaccia web).** Nessun passo qui
è eseguibile da questa sessione:

1. Settings → Branches → accanto a `main`, il pulsante di rinomina → nuovo
   nome `develop`. GitHub sposta il branch di default su `develop`, retargeta
   le PR aperte e crea i redirect.
2. Sempre in Branches (o dalla vista dei branch), creare `main` da `develop`.
3. Facoltativo ma consigliato: proteggere `main` in modo che accetti solo
   merge da pull request, così un push diretto non fa partire per errore una
   build pubblica.

**Riallineamento della copia locale**, dopo i passi sopra:

```powershell
git branch -m main develop
git fetch origin --prune
git branch -u origin/develop develop
git remote set-head origin -a
```

Il branch di lavoro corrente di questa sessione
(`claude/branch-alignment-wpib1h`) non è interessato: nasce dallo stesso commit
e dopo la rinomina risulterà semplicemente basato su `develop`.
