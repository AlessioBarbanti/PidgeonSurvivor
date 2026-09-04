---
id: PS-084
titolo: Documentare la direzione visuale per personaggio e collegarla agli agenti art
tipo: chore
area: arte
stato: IN VERIFICA
priorita: media
dipende_da: []
origine: conversazione del proprietario 2026-09-02
creato: 2026-09-02
aggiornato: 2026-09-02
---

# PS-084 — Documentare la direzione visuale per personaggio e collegarla agli agenti art

## Contesto

La skill condivisa Game Art Designer
(`.agents/skills/game-art-designer/SKILL.md`, usata sia dall'agente Claude
`.claude/agents/game-art-designer.md` sia dall'agente Codex
`.codex/agents/game-art-designer.toml`) ricostruisce oggi la famiglia visiva di
ogni personaggio ispezionando da zero manifest, prompt storici e master HD:
non esiste un documento per personaggio che fissi in modo stabile silhouette,
palette, costume, acconciatura, accessori e grammatica pixel-art. Le foto
reference originali del cast (amici del proprietario, autorizzate solo come
`subject reference`, mai runtime) vivono sotto
`assets/art/characters/references/<id>/`, un albero pensato per asset, mentre
sono materiale di documentazione e provenienza, non un asset da derivare.

## Comportamento atteso

Ogni personaggio giocabile ha un documento di direzione visuale in `docs/`,
verificabile contro i master reali e i manifest, non inventato. Le foto
reference del cast vivono accanto a quella documentazione invece che sotto
`assets/art/`. La skill condivisa Game Art Designer dichiara esplicitamente
che può consultare questi documenti come aiuto, mantenendo invariato l'obbligo
di ispezionare i fratelli visivi reali.

## Criteri di accettazione

- [x] Esiste un file Markdown per ciascuno degli otto personaggi giocabili
      (Alea, Aleo, Bea, Lollo, Magno, Marghe, Migi, Zat) sotto
      `docs/characters/<id>.md`, con silhouette/corporatura, acconciatura,
      palette e costume, accessori distintivi, variante Evil, percorsi dei
      master/derivati correnti ed eventuale reference fotografica associata
      con il suo ruolo dichiarato (`subject reference`).
- [x] Ogni fatto riportato nei nuovi file è tracciabile a
      `docs/characters.md`, `assets/art/characters/ASSET-MANIFEST.md` o ai
      percorsi reali dei file; nessuna provenienza, nome reale o approvazione
      viene inventata.
- [x] Il contenuto di `assets/art/characters/references/` (foto originali e
      `README.md`) è spostato sotto `docs/characters/references/<id>/`, senza
      alterare i byte delle foto.
- [x] La nuova cartella reference resta fuori dall'import Godot (`.gdignore`)
      e dai tre preset export (`exclude_filter`), come lo era prima dello
      spostamento.
- [x] `.gitignore`, `assets/art/characters/ASSET-MANIFEST.md`,
      `docs/archive/generation-prompts-and-references.md` e
      `export_presets.cfg` non citano più il vecchio percorso
      `assets/art/characters/references/`; nessun link rotto resta nei
      documenti aggiornati.
- [x] `.agents/skills/game-art-designer/SKILL.md` dichiara esplicitamente che
      può consultare `docs/characters/<id>.md`, quando esistono, come aiuto
      alla ricostruzione della famiglia visiva, senza indebolire l'obbligo di
      ispezionare i fratelli visivi reali né gli altri vincoli già in vigore
      (provenienza reale, ruolo esplicito dei reference, niente asset
      generato in anticipo).
- [x] `.agents/skills/game-art-designer/references/imagegen-reference-policy.md`
      indica il nuovo percorso delle reference fotografiche autorizzate del
      cast.

## Ambito

- Nuovi file: `docs/characters/<id>.md` per gli otto personaggi.
- Spostamento: `assets/art/characters/references/**` →
  `docs/characters/references/**` (foto, `README.md`, `.gdignore`).
- Aggiornamenti di percorso: `.gitignore`,
  `assets/art/characters/ASSET-MANIFEST.md`,
  `docs/archive/generation-prompts-and-references.md`, `export_presets.cfg`.
- Aggiornamenti di contratto: `.agents/skills/game-art-designer/SKILL.md`,
  `.agents/skills/game-art-designer/references/imagegen-reference-policy.md`.
- Correzione minore: `docs/visual-audio-identity.md` riportava ancora "nessun
  personaggio rappresenta persone reali con l'eccezione di Aleo", superato
  dall'identity pass del 28/08/2026 già registrato in
  `assets/art/characters/ASSET-MANIFEST.md` (reference fotografiche per tutti
  e otto i profili).
- Non tocca: dati gameplay, scene, script runtime, contratti dei `Friend`,
  `selection_portrait`/`evil_portrait` esistenti, il lavoro in corso di
  PS-068 (i due busti Player già prodotti per Alea e Aleo vengono solo
  descritti come "in produzione", non integrati né approvati da questa card).
- Non riscrive le decisioni già registrate in PS-083: le correzioni di
  percorso sono annotate lì in `Note`, non nei `Decisioni` originali.

## Verifica

- Sola documentazione: nessuno smoke GUT applicabile.
- Verifica manuale: ogni percorso citato nei nuovi file e negli aggiornamenti
  esiste davvero sul filesystem; gli hash già registrati nel manifest restano
  quelli calcolati prima dello spostamento (nessun contenuto binario cambia);
  nessuna occorrenza residua del vecchio percorso nei documenti aggiornati.
- Profilo minimo prima della chiusura: non applicabile (nessun runtime
  toccato).

## Gate manuali

- [ ] Runtime Windows — non applicabile, nessun asset runtime o scena toccata.
- [ ] Validazione statica APK — non applicabile.
- [ ] Runtime fisico Pixel 9 — non applicabile.
- [x] Controllo percettivo richiesto: no per l'automazione; il proprietario
      resta libero di rileggere i nuovi file di direzione visuale per
      accuratezza dei contenuti.

## Decisioni

- **2026-09-02 — Le reference fotografiche traslocano sotto `docs/`.**
  Sono materiale di documentazione e provenienza (foto private di persone
  reali, mai runtime), non un asset da derivare: la loro casa naturale è
  accanto alla documentazione di direzione visuale, non sotto `assets/art/`.
  Protezione da import/export invariata (`.gdignore` + `exclude_filter`),
  solo il percorso cambia.
- **2026-09-02 — I nuovi file sono un aiuto, non una fonte sostitutiva.**
  `.agents/skills/game-art-designer/SKILL.md` continua a richiedere
  l'ispezione dei fratelli visivi reali; i documenti per personaggio
  velocizzano la ricostruzione ma non la sostituiscono, per evitare che uno
  di questi file diventi una "verità congelata" mai riconciliata con i master
  reali.
- **2026-09-02 — Nessun nome reale nei nuovi file.** Le persone fotografate
  restano identificate solo con l'id del personaggio in gioco (`alea`,
  `aleo`, …), coerentemente con il trattamento già in uso nel manifest e
  nell'archivio storico.

## Documenti sincronizzati

- [x] `assets/art/characters/ASSET-MANIFEST.md`.
- [x] `docs/archive/generation-prompts-and-references.md`.
- [x] `docs/visual-audio-identity.md` (correzione minore, vedi Ambito).
- [x] `.agents/skills/game-art-designer/SKILL.md` e
      `references/imagegen-reference-policy.md`.

## Note

Le due card di riferimento restano PS-083 (archivio storico prompt/reference,
ancora `IN VERIFICA`, non riaperta: solo una nota di percorso) e PS-068
(ritratti busto Player, `IN CORSO`, non toccata nel contenuto).
