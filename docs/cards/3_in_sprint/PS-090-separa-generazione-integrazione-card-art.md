---
id: PS-090
titolo: Separa generazione asset e integrazione nel workflow delle card tipo art
tipo: chore
area: tooling
priorita: media
stato: PRONTO
dipende_da: []
origine: conversazione del proprietario 2026-09-04
creato: 2026-09-04
aggiornato: 2026-09-04
---

# PS-090 — Separa generazione asset e integrazione nel workflow delle card tipo art

## Contesto

Oggi una card `tipo: art` non si ferma alla produzione dell'asset. La skill
condivisa `.agents/skills/game-art-designer/SKILL.md` — usata sia
dall'agente Claude sia da quello Codex — dichiara come step obbligatorio
"Integra e verifica": inserire il derivato nel componente runtime, aggiornare
riferimenti (`.tres`, scene), rinfrescare l'import Godot ed eseguire i profili
di verifica richiesti dalla card, tutto nella stessa card e nella stessa
sessione della generazione. `PS-068` ne è un esempio concreto già in corso:
oltre a produrre i nuovi busti, la card tocca direttamente
`data/friends/*.tres` per i campi portrait. Questo mescola due lavori di
natura diversa — produzione visiva soggetta a review percettiva, e wiring dei
dati che richiede solo correttezza tecnica — nella stessa card, complicando
sia la delega esclusiva a Game Art Designer sia la revisione di ciò che una
card `art` ha effettivamente diritto di cambiare.

## Comportamento atteso

Una card `tipo: art` si conclude quando l'asset (master + derivato +
manifest) è prodotto e ha superato l'art review; il suo criterio di
completamento non include più il wiring nei dati/scene/registry di gioco.
Collegare l'asset finito all'interfaccia o al dato che lo consuma diventa il
lavoro di una card successiva, dello stesso `tipo` che avrebbe avuto senza la
componente grafica (`feat`/`fix`/`ux`/`chore`), aperta esplicitamente in fase
di autoria o all'handoff della card `art`.

## Criteri di accettazione

- [ ] `.agents/skills/game-art-designer/SKILL.md` non richiede più, come
      criterio di completamento, di inserire il derivato nel componente
      runtime: si ferma a master, derivato, manifest e art review.
      L'integrazione (`.tres`, scene, registry, refresh import, esecuzione
      dei profili di verifica di gameplay) è dichiarata esplicitamente come
      **fuori ambito** per una card `art`, con un rimando alla card di
      integrazione.
- [ ] `.claude/skills/asset-pipeline/SKILL.md` resta la fonte per la
      derivazione tecnica (script `process-*.ps1`, esclusione dei master,
      manifest) ed è ora richiamata sia dalla card `art` (solo per derivare)
      sia dalla card di integrazione (per wire-in e verifica), invece di
      essere implicitamente bundlata solo nella prima.
- [ ] `docs/cards/README.md` aggiorna la regola di delega: una card `art` che
      richiede nuovi asset **non include mai** la propria integrazione nei
      criteri di accettazione; l'autore (skill `card-crea` o chi apre la
      card) apre o predispone una card di integrazione collegata tramite
      `dipende_da`.
- [ ] La skill `card-crea` riflette la stessa regola per l'autoria di nuove
      card: quando una richiesta implica sia produrre arte sia usarla in
      gioco, il default diventa due card collegate, non una card mista,
      salvo che il lavoro di integrazione sia banale a sufficienza da restare
      un singolo criterio di accettazione esplicitamente marcato come tale.
- [ ] Le card `tipo: art` attualmente aperte e non ancora avviate
      ([PS-078](./PS-078-tematizza-catalogo-specialita-barb.md)) sono
      riviste contro la nuova regola; le card già in `4_to_test` (PS-028,
      PS-049, PS-052, PS-058, PS-068) restano come sono — hanno già prodotto
      e integrato l'asset sotto il contratto precedente, e riaprirle per
      separare a posteriori generazione e integrazione non produce alcun
      beneficio osservabile.

## Ambito

- `.agents/skills/game-art-designer/SKILL.md`.
- `.claude/skills/asset-pipeline/SKILL.md` (solo per esplicitare la
  suddivisione dei passi fra le due card, non per cambiarne gli script).
- `docs/cards/README.md` (regola di delega e di board).
- `.claude/skills/card-crea/SKILL.md`.
- [PS-078](./PS-078-tematizza-catalogo-specialita-barb.md), solo se la
  revisione richiede di aggiustarne i criteri di accettazione per rispettare
  la nuova regola.

Non toccare:

- `.codex/agents/game-art-designer.toml`: se duplica testo della skill
  condivisa invece di richiamarla, l'allineamento resta una card separata,
  non un ampliamento di questa;
- le card `art` già in `4_to_test` (PS-028, PS-049, PS-052, PS-058, PS-068):
  restano storiche sotto il contratto con cui sono state lavorate;
- gli script `tools/process-*.ps1` e il loro comportamento tecnico.

## Verifica

- Nessuno smoke GUT: questa card cambia solo documentazione di processo, non
  runtime. La verifica è una lettura incrociata: le tre skill toccate non si
  contraddicono, e la nuova regola resta seguibile da una sessione che parte
  da zero (nessun riferimento implicito a decisioni prese solo in questa
  card).
- Profilo minimo prima della chiusura: nessuno (nessun codice o dato di
  runtime cambia).

## Gate manuali

- [ ] Runtime Windows: non applicabile
- [ ] Validazione statica APK: non applicabile
- [ ] Runtime fisico Pixel 9: non applicabile
- [ ] Controllo percettivo richiesto: no

## Decisioni

- **2026-09-04 — Unisce le due richieste del proprietario ("controlliamo che
  le card generino solo asset" e "modifichiamo la skill perché generi prima
  e integri dopo") in una sola card.** Sono la stessa decisione di processo
  vista da due angoli — cosa deve valere ("solo asset") e come farlo valere
  (cambiare la skill che lo esegue). Tenerle separate avrebbe prodotto due
  card che finiscono per modificare lo stesso file
  (`game-art-designer/SKILL.md`) con criteri sovrapposti, contro la regola
  della board che vieta tracker paralleli sulla stessa decisione.
- **2026-09-04 — Le card `art` già in verifica non vengono riaperte.**
  Separare a posteriori generazione e integrazione per un lavoro già fatto e
  funzionante non cambia nulla di osservabile per chi gioca; la nuova regola
  vale per il lavoro non ancora iniziato.
- **2026-09-04 — [PS-091](./PS-091-genera-placeholder-powerup-nuove-statistiche.md)
  è il primo caso applicato alla nuova regola**, per costruzione: è stata
  scritta come card di sola generazione fin dall'inizio.

## Documenti sincronizzati

- [ ] `docs/cards/README.md`: regola di delega aggiornata.

## Note

Questa card non implementa alcuna nuova card di integrazione: si limita a
stabilire che, da qui in avanti, la generazione ne richiede una collegata
quando l'asset deve entrare in gioco.
