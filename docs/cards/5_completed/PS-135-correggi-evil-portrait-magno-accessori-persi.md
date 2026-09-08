---
id: PS-135
titolo: Correggi evil_portrait.png di Magno per ripristinare gli accessori identitari
tipo: art
area: arte
stato: COMPLETATO
priorita: media
dipende_da: []
origine:
creato: 2026-09-08
aggiornato: 2026-09-08
---

# PS-135 — Correggi evil_portrait.png di Magno per ripristinare gli accessori identitari

## Contesto

L'agente `direttore-artistico`, invocato su richiesta del proprietario per
revisionare i tre file HD di Magno in `assets/art/characters/magno/hd/`
(`portrait.png`, `poses.png`, `evil_portrait.png`), ha approvato `portrait.png`
e `poses.png` ma segnalato `evil_portrait.png` come non coerente con gli altri
due file dello stesso personaggio.

Confronto diretto con `portrait.png`/`poses.png`:

- il copricapo cornuto con gemma turchese — l'elemento identitario più forte
  del personaggio — è assente, coperto dai capelli;
- lo spallaccio con due corna d'avorio e gemma in castone dorato è sostituito
  da un pauldron generico (cuoio scuro invecchiato, borchie tonde, disco
  dorato, cintura di pelliccia), senza alcun motivo bovino;
- è presente una collana con ciondolo ad artiglio/dente non prevista dal
  prompt registrato in `ASSET-MANIFEST.md`.

Capelli lunghi/mossi e canotta nera **non** sono un problema: sono
esplicitamente previsti dal prompt approvato in `ASSET-MANIFEST.md`
(riga `evil_magno`, sezione Evil) e vanno mantenuti.

Sui fratelli visivi (Alea, Zat, Bea) la regola già scritta nel manifest —
"preservare acconciatura, corporatura, colori dell'abito e accessori del
personaggio; applicare una sola grammatica Evil sopra" — è rispettata alla
lettera: solo Magno perde accessori non menzionati nel prompt. Il risultato
oggi si legge come un guerriero fantasy generico, non come "Magno corrotto".

Questa è una correzione di un master già promosso (hash registrati in
`ASSET-MANIFEST.md`, righe 281 e 250), non una nuova integrazione: il derivato
runtime sostituisce il file già consumato allo stesso percorso
(`magno/generated/evil_portrait.png`), già cablato nella Boss Intro. Non serve
quindi una card di integrazione gemella (PS-090 non si applica: non è arte
nuova da agganciare, è una correzione che rientra nel percorso già esistente).

## Comportamento atteso

`evil_portrait.png` di Magno, confrontato fianco a fianco con `portrait.png` e
`poses.png`, si legge immediatamente come "stesso personaggio, versione
corrotta": stessa identità a colpo d'occhio, con solo la grammatica Evil
(fumo, occhio, crepe, rim light) applicata sopra.

## Criteri di accettazione

- [x] Il copricapo cornuto con gemma turchese è presente e riconoscibile
      nella nuova versione (anche solo parzialmente visibile tra i capelli
      lunghi, come tell identitario).
- [x] Lo spallaccio presenta le due corna d'avorio e la gemma in castone
      dorato coerenti con `portrait.png`/`poses.png`, non il pauldron
      generico attuale.
- [x] La collana ad artiglio/dente non documentata nel prompt è rimossa.
- [x] Capelli lunghi/mossi e canotta nera restano, come da prompt approvato
      in `ASSET-MANIFEST.md`.
- [x] Fumo prugna, occhio magenta-viola, crepe energetiche e rim light
      restano applicati con lo stesso linguaggio già in uso sugli altri Evil
      del cast (nessuna regressione sulla grammatica Evil già approvata).
- [x] Il nuovo master HD (`magno/hd/evil_portrait.png`, `1254x1254`) e il
      derivato runtime (`magno/generated/evil_portrait.png`, `256x256`)
      sostituiscono i file esistenti agli stessi percorsi, con hash SHA-256
      ricalcolati.
- [x] `ASSET-MANIFEST.md` (`assets/art/characters/ASSET-MANIFEST.md`, righe
      Magno nelle tabelle Evil e master/derivato) è aggiornato con i nuovi
      byte e hash SHA-256.

## Ambito

- `assets/art/characters/magno/hd/evil_portrait.png`.
- `assets/art/characters/magno/generated/evil_portrait.png`.
- `assets/art/characters/ASSET-MANIFEST.md` (righe Magno pertinenti).

Non toccare:

- `magno/hd/portrait.png`, `magno/hd/poses.png` e i rispettivi derivati, già
  approvati;
- gli asset degli altri personaggi del cast;
- il cablaggio della Boss Intro o qualunque scena/script (il derivato
  sostituisce il file già consumato allo stesso percorso, nessun wiring
  nuovo).

## Verifica

- Art review: confronto diretto con `portrait.png`/`poses.png` e con
  `alea/hd/evil_portrait.png` come riferimento di fedeltà normal→evil, più
  manifest, come da convenzione PS-090.
- `magno/generated/evil_portrait.png` combacia col pattern
  `assets/art/characters/*/generated/*` di `tools/milestone-test-map.json`
  (i master in `hd/` non lo innescano, il derivato sì): non è una card senza
  smoke GUT. `.\tools\run-milestone-checks.ps1 -Milestone PS-135 -Profile
  Relevant` → `regression=22/22 status=PASS`, nessun `SCRIPT ERROR`/`FATAL
  EXCEPTION` nei log (`%TEMP%\il-gioco-verification\20260908-214313-PS-135`).

## Gate manuali

Runtime Windows, validazione statica APK e runtime fisico Pixel 9 non sono
pertinenti: la card sostituisce i byte di un asset già cablato senza modificare
wiring o logica.

- [x] Approvazione percettiva del proprietario — confronto diretto fianco a
      fianco con `portrait.png`, `poses.png` e con
      `alea/hd/evil_portrait.png` come riferimento di fedeltà. La review
      tecnica dell'agente non sostituisce questa approvazione esplicita.

## Decisioni

- **2026-09-08 — Correzione avviata sugli stessi percorsi.** PS-135 modifica
  esclusivamente il master Evil di Magno e il suo derivato già cablato;
  `portrait.png`, `poses.png`, gli altri personaggi e il wiring runtime restano
  invariati.
- **2026-09-08 — Candidato prodotto e posto in verifica.** Selezionato l'edit
  ImageGen `exec-a924d2dd-e49e-4f1f-8a51-f3adae6e9982.png`, seguito dal
  passaggio `background-extraction`
  `exec-4d8894d3-ef07-4938-8874-836bbe0d2f2c.png`. La review isolata del
  derivato a `256x256` conferma la leggibilità dei tell richiesti; la card
  resta `IN VERIFICA` fino all'approvazione esplicita del proprietario.
- **2026-09-08 — Approvazione percettiva ricevuta.** Il proprietario ha
  approvato esplicitamente il candidato con “Perfetto”; PS-135 può quindi
  passare da `IN VERIFICA` a `COMPLETATO`.
- **2026-09-08 — Corretta la sezione Verifica: la card innesca smoke GUT.**
  La prima stesura dichiarava "nessuno smoke GUT" per analogia con PS-090, ma
  `magno/generated/evil_portrait.png` combacia col pattern
  `assets/art/characters/*/generated/*` di `tools/milestone-test-map.json` (a
  differenza dei master in `hd/`, esentati). Eseguito
  `run-milestone-checks.ps1 -Milestone PS-135 -Profile Relevant`:
  `regression=22/22 status=PASS`, log senza `SCRIPT ERROR`/`FATAL EXCEPTION`.

- **2026-09-08 — Riferimento di fedeltà normal→evil: `alea/hd/evil_portrait.png`.**
  Scelto dal direttore-artistico durante la revisione perché applica
  correttamente la regola già scritta nel manifest (acconciatura, colori
  abito e accessori identitari preservati, solo grammatica evil sopra).
- **2026-09-08 — Capelli lunghi e canotta nera restano.** Sono previsti dal
  prompt approvato in `ASSET-MANIFEST.md` (`evil_magno`); la correzione
  riguarda solo gli accessori persi (copricapo, spallaccio) e l'aggiunta non
  documentata (collana), non l'intera direzione dell'Evil.
- **Aperto — checklist per-personaggio nel manifest.** Il direttore-artistico
  ha suggerito di aggiungere in `ASSET-MANIFEST.md` (sezione Evil) una riga
  di checklist esplicita "accessori identitari preservati: sì/no" per
  personaggio, per evitare che una deviazione intenzionale nel prompt (es.
  "capelli lunghi") venga letta come autorizzazione implicita a perdere anche
  accessori non menzionati. Non è un criterio di accettazione di questa card:
  se il proprietario lo conferma, va aperta una card `chore` separata sul
  processo di manifest/art review.

## Documenti sincronizzati

- [x] `ASSET-MANIFEST.md` (`assets/art/characters/`): righe Magno aggiornate
      con i nuovi hash.

## Note

Revisione originale eseguita dall'agente `direttore-artistico` su richiesta
esplicita del proprietario, confrontando i tre file HD di Magno con i
fratelli visivi Alea/Zat/Bea e con `docs/characters.md`.

Evidenza di produzione PS-135: master `1254x1254`, SHA-256
`DD729B392C959404089177E8489C135436BC1D02076A0B0EDDC266E78EF8365D`;
derivato `256x256`, SHA-256
`49DE75C71232CCD7FBCF5A54711A761022365612110AA07BF549FAD9EA7C68F5`.
I quattro angoli del derivato hanno alpha `0`; nessun test GUT o gate di
piattaforma è pertinente perché il wiring non è cambiato.
