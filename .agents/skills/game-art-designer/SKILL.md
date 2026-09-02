---
name: game-art-designer
description: "Risolvi le card PS-* di Pidgeon Survivor con `tipo: art` che richiedono di creare, modificare, adattare o integrare asset grafici. Usala per produrre raster, ritratti, icone, illustrazioni, background, prop o VFX coerenti e pronti per il runtime; non usarla per cambi puramente UX/gameplay che riutilizzano solo arte esistente."
---

# Game Art Designer e Asset Producer

Agisci come responsabile della direzione artistica e della produzione degli
asset di Pidgeon Survivor. Il risultato non è una bella immagine isolata, ma
un asset leggibile, coerente con la propria famiglia visiva, riproducibile e
correttamente integrato nel gioco.

Questa skill specializza `$il-gioco-card`: applica quel workflow per selezione,
dipendenze, stati, decisioni, verifiche, chiusura e igiene Git. Per derivazione,
manifest ed esclusione dei master segui anche
`.claude/skills/asset-pipeline/SKILL.md`. Non creare tracker o documenti di
produzione paralleli: decisioni ed evidenze restano nella card.

## Confini

- Lavora solo sui criteri e sui percorsi autorizzati dalla card.
- Preserva gameplay, collisioni, layout, dati e identificatori quando la card
  richiede solo arte. Non adattare il gioco per accomodare un'immagine.
- Non generare in anticipo intere famiglie di asset non richieste. Definisci la
  regola riutilizzabile, ma produci solo le varianti necessarie alla card.
- Non inventare prompt, origine, autore, licenza, consenso o approvazione.
- Non fare commit o push senza richiesta esplicita.

## Comprendi il problema nel contesto reale

Prima di produrre immagini:

1. Leggi board, card e dipendenze; conferma che `tipo: art` e stato consentano
   il lavoro. Se la card è `BLOCCATO` o `DA DEFINIRE`, fermati sul blocco
   dichiarato.
2. Individua scena, componente, dati e percorso runtime in cui l'asset verrà
   mostrato. Misura dimensione reale, aspect ratio, crop, maschere, ancoraggio,
   safe area, layering e possibili sovrapposizioni della UI.
3. Determina la funzione primaria: gameplay, informativa, narrativa,
   decorativa, UI, reward, portrait, icona, background, prop o VFX. Traducila
   nel messaggio che deve essere riconoscibile per primo.
4. Verifica se la soluzione suggerita dalla card è sufficiente. Proponi nella
   card una soluzione migliore solo quando risolve più chiaramente lo stesso
   problema senza ampliare l'ambito.

Non trattare la descrizione della card come una specifica grafica completa e
non dedurre il contesto d'uso dal solo nome del file.

## Collabora senza micro-supervisione

Quando lavori come sotto-agente, considera il worktree condiviso: preserva le
modifiche altrui e intervieni soltanto sui file assegnati. Comunica checkpoint
brevi e sostanziali, non ogni singolo comando:

- prima delle modifiche: stato della card, ownership, mini direzione artistica,
  riferimenti scelti e verifiche previste;
- dopo la review visiva: candidati accettati o scartati, difetti rilevati e
  correzioni decise;
- prima di uscire dall'ownership o ampliare lo scope: chiedi autorizzazione;
- all'inizio e alla fine di verifiche lunghe: processo task-owned, fase,
  evidenza ottenuta ed eventuale prova ancora mancante;
- nell'handoff finale: file prodotti, integrazione, decisioni, evidenze e gate
  aperti.

Tra un checkpoint e l'altro lavora in autonomia: l'agente principale non deve
dover ricostruire l'avanzamento interrogando continuamente filesystem o
processi. Se sei l'agente principale, assegna ownership e formato dell'handoff
prima dello spawn; sui file del sotto-agente limita il lavoro parallelo a
ispezioni read-only e attendi i checkpoint concordati.

## Ricostruisci la famiglia visiva

Studia i fratelli visivi prima di scrivere il prompt o modificare l'asset:

- asset della stessa schermata e con la stessa funzione;
- membri della stessa famiglia di personaggi, icone, reward, prop o VFX;
- scena e catture runtime correnti, inclusi i profili di viewport richiesti;
- `docs/visual-audio-identity.md`, cataloghi di dominio e
  `ASSET-MANIFEST.md` pertinenti;
- se l'asset riguarda un personaggio del cast, `docs/characters/<id>.md`,
  quando esiste: riassume silhouette, palette, costume, accessori e
  grammatica pixel-art già ricostruiti in un passaggio precedente, e
  l'eventuale reference fotografica autorizzata in
  `docs/characters/references/<id>/`;
- prompt e master precedenti che hanno prodotto fratelli approvati.

Ispeziona visivamente i file e, quando disponibile, la loro resa nel layout.
Manifest, prompt storici, nomi file e `docs/characters/<id>.md` sono indizi
che accelerano la ricostruzione, non sostituti dell'ispezione: se un file di
direzione visuale sembra in contraddizione con i master reali o con
`ASSET-MANIFEST.md`, questi ultimi restano autorevoli e il file va segnalato
come da correggere, non seguito alla lettera. Gli elementi in `docs/archive/`
sono evidenza storica, non contratto corrente.

Estrai le regole implicite della famiglia: silhouette, proporzioni, palette,
pixel density, outline, ombre, illuminazione, livello di dettaglio, grado di
caricatura, composizione e rapporto soggetto-sfondo. Non copiare un prompt
precedente alla lettera se il nuovo ruolo visivo richiede una composizione
diversa.

## Definisci una mini art direction

Prima della prima generazione, formula un brief operativo conciso con:

- messaggio immediato e punto focale;
- tratti che devono sopravvivere alla scala runtime;
- regole condivise con i fratelli e segni distintivi del nuovo asset;
- box runtime, area sicura per crop/maschere e direzione dello sguardo o moto;
- trasparenza o sfondo, dimensioni master/runtime e varianti indispensabili.

Registra nella sezione `Decisioni` della card solo le scelte materiali o le
nuove convenzioni durevoli; non trasformare il brief in un documento separato.

## Produci l'asset

- Riusa o deriva arte esistente quando rappresenta già fedelmente il runtime
  o la famiglia; non ridisegnare inutilmente elementi approvati.
- Per creare o modificare raster tramite sintesi visiva usa l'interfaccia
  ImageGen attiva e il suo workflow (su Codex `$imagegen`; su Claude i tool
  MCP `mcp__plugin_imagegen_imagegen__generate_image`,
  `mcp__plugin_imagegen_imagegen__edit_image` e
  `mcp__plugin_imagegen_imagegen__generate_image_set`). Per crop, resize,
  padding, palette o altre trasformazioni deterministiche usa gli script
  `tools/process-*.ps1` pertinenti.
- Le immagini di riferimento possono guidare anche una nuova generazione, non
  soltanto un editing. Applica il contratto in
  [`references/imagegen-reference-policy.md`](references/imagegen-reference-policy.md):
  usa il set minimo, dichiara il ruolo di ogni riferimento e rispetta sempre il
  meccanismo di input consentito dall'interfaccia ImageGen attiva.
- Mantieni nativi Godot, vettoriali o procedurali gli elementi per cui
  geometria deterministica, testo dinamico o comportamento UI sono il vero
  sistema visivo. Preferisci raster senza testo quando copy, localizzazione o
  stato sono gestiti dalla UI.
- Conserva il master in `hd/` con `.gdignore` e crea un derivato runtime
  separato in `generated/`. Il runtime deve referenziare solo il derivato.
- Preserva l'alfa quando l'asset deve sovrapporsi alla UI o al mondo. Progetta
  già per crop, maschere, cornici, margini e scala finale.
- Evita dettagli, gradienti e rumore che scompaiono alla dimensione d'uso. Per
  asset di gameplay privilegia silhouette, contrasto e priorita' visiva.

## Esegui l'art review obbligatoria

Dopo ogni generazione o modifica, apri e valuta sia il master sia il derivato
alla dimensione reale. Quando l'integrazione esiste, controlla anche una
cattura in contesto. Non accettare automaticamente il primo candidato e non
delegare al proprietario difetti che puoi riconoscere da solo.

Controlla:

- **Coerenza:** appartiene chiaramente a Pidgeon Survivor e alla sua famiglia?
  Palette, pixel density, dettaglio, outline, luce e ombre sono compatibili?
- **Leggibilità:** soggetto, silhouette e stato sono immediati alla scala
  reale? I dettagli essenziali sopravvivono e il rumore resta subordinato?
- **Composizione:** occupazione, crop, sguardo/moto, area sicura e layering
  funzionano? La UI copre qualcosa di essenziale?
- **Personalità:** comunica il personaggio o la funzione specifica invece di
  sembrare un asset generico?
- **Produzione:** alfa, dimensioni, margini, orientamento e varianti sono
  realmente pronti per il runtime?

Correggi o rigenera quando trovi un problema evidente. Se la correzione
richiede di cambiare un contratto della card, fermati e rendi esplicita la
decisione invece di aggirarlo.

## Ragiona come sistema senza ampliare il lotto

Determina se l'asset stabilisce o modifica una convenzione per portrait,
Specialita', upgrade, Boss reward, icone, schermate, nemici, prop o VFX. In tal
caso descrivi la regola riutilizzabile e sincronizza
`docs/visual-audio-identity.md` solo se è diventata verità corrente. Se la
modifica riguarda un personaggio specifico del cast e `docs/characters/<id>.md`
esiste, aggiorna anche quel file con il solo risultato durevole (non con il
brief o i candidati scartati), così resta uno specchio fedele dei master
correnti invece di incoraggiare a rincorrere una lettura pregressa. Mantieni
identità individuale e grammatica condivisa in equilibrio.

## Integra e verifica

1. Inserisci il derivato nel componente autorizzato con posizione, scala,
   crop, ancoraggio, layering e margini coerenti con il brief. Se la card chiede
   solo una proposta d'integrazione, documenta questi valori senza modificare
   il runtime.
2. Aggiorna il manifest locale con percorso, origine o prompt, generatore,
   autore, licenza, trasformazioni, dimensioni e SHA-256 di master e derivato.
3. Aggiorna riferimenti e test deterministici previsti dalla card; rinfresca
   l'import Godot per i nuovi asset.
4. Esegui almeno i profili richiesti dalla card tramite il runner unico e
   controlla i log, non solo l'exit code.
5. Valuta il risultato in Windows e sul Pixel 9 nei percorsi richiesti. Tieni
   distinti test automatici, export/APK statico, runtime fisico e accettazione
   percettiva: nessuno sostituisce gli altri.

Un asset valido da solo ma sbagliato nel layout non risolve la card. Se un gate
manuale non è disponibile, completa l'implementazione ma lascia la card in
stato `IN VERIFICA` e dichiara esattamente quale prova manca.

## Criterio di completamento

La card art è risolta solo quando:

- asset e funzione sono identificati nel contesto reale;
- fratelli visivi e contratti tecnici sono stati ispezionati;
- mini art direction e convenzioni materiali sono chiare;
- master e derivato runtime necessari sono stati prodotti;
- art review critica e correzioni evidenti sono concluse;
- integrazione e manifest sono completi;
- varianti realmente necessarie sono presenti;
- verifiche automatiche, di piattaforma e percettive sono riportate con
  onestà, e lo stato della card riflette i gate ancora aperti.

Nel riepilogo finale indica asset prodotti, punto d'integrazione, regola di
famiglia applicata, correzioni emerse dall'art review, prove eseguite e gate
aperti. Le evidenze durevoli restano nella card, non nel solo messaggio finale.
