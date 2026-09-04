---
id: PS-029
titolo: Rendi più visibili i tell di stato dei personaggi
tipo: ux
area: gameplay
stato: SCARTATA
priorita: alta
dipende_da: []
origine: B44
creato: 2026-08-30
aggiornato: 2026-09-04
---

# PS-029 — Rendi più visibili i tell di stato dei personaggi

## Contesto

Alcuni personaggi comunicano stati temporanei o modalità della passiva tramite outline, tinta o altri tell visuali, ma durante il combattimento questi segnali risultano troppo deboli.

Il problema è particolarmente evidente con Iperfocus ADHD di Lollo e va verificato anche sugli altri personaggi che utilizzano tell di stato equivalenti.

## Comportamento atteso

Gli stati gameplay che richiedono un tell visuale devono essere riconoscibili sul personaggio durante una normale run, anche con orde dense, proiettili e VFX contemporaneamente a schermo.

Il passaggio da uno stato all'altro deve essere percepibile senza dover contare secondi o osservare statistiche indirette.

La revisione deve partire da Lollo e includere un controllo degli altri tell di stato già presenti nel roster, aumentando contrasto, spessore, intensità o separazione visiva dove necessario.

Il tell deve restare presentazionale e non modificare durata, valori o logica dello stato.

## Criteri di accettazione

- [ ] Iperfocus e Distrazione di Lollo sono distinguibili immediatamente durante il gameplay.
      *Percettivo, non verificabile in headless.*
- [ ] Il tell di Lollo resta visibile sopra lo sfondo arena e durante orde dense.
      *Percettivo.*
- [ ] Il tell non viene annullato visivamente dal normale sprite del Player.
      *Percettivo: il disegno resta `show_behind_parent` come in PS-001, non
      alterato da questa card, ma non riconfermato a video.*
- [x] Gli altri personaggi con stati o fasi visualmente dichiarate vengono
      verificati nello stesso pass. *Audit eseguito su Aleo, Lollo, Alea e
      Migi: trovata e corretta la coppia quasi identica di Migi (guscio
      pronto/scudo), coperta dal nuovo test automatico.*
- [ ] Lo stato caldo e freddo di Aleo resta chiaramente distinguibile durante
      il combattimento. *Percettivo.*
- [ ] Gli eventuali tell attivi di Alea restano leggibili durante la loro
      finestra. *Percettivo; la presentazione/colore/durata della finestra
      sono ora coperti da smoke automatico, la leggibilità reale no.*
- [ ] Ogni tell continua a rispettare la priorità del feedback di danno e
      degli altri segnali critici. *Codice non toccato da questa card, ma il
      profilo `Relevant` (che include `test_b44_state_tells.gd`) non è stato
      rieseguito in questa sessione: riconferma aperta.*
- [ ] Il cambio di stato produce un cambiamento visivo percepibile senza
      modificare il gameplay. *La parte "senza modificare il gameplay" è
      confermata dal diff (solo colori/spessore); la percettibilità resta un
      gate percettivo aperto.*
- [x] La leggibilità non dipende esclusivamente da una differenza cromatica
      minima. *Ora garantito per costruzione: bordo di separazione scuro +
      spessore aumentato, indipendenti dal colore di stato, più una soglia di
      distanza cromatica minima imposta e testata fra le due fasi di ogni
      personaggio.*
- [ ] I tell non coprono hitbox percepite, telegraph ostili o proiettili
      importanti. *Per costruzione il bordo resta entro pochi pixel dalla
      sagoma propria, ma non confermato a video.*
- [ ] Restart e cambio personaggio eliminano correttamente ogni tell residuo.
      *Logica di reset non toccata da questa card; non riconfermato in questa
      sessione (`Relevant` non eseguito).*
- [ ] Pausa e stati non `RUNNING` conservano il comportamento temporale
      corrente. *Stessa nota: logica non toccata, non riconfermato in questa
      sessione.*

## Ambito

- Sistema visuale dei passive/state tell del Player.
- Outline, tint, aura o altri indicatori già usati per gli stati del roster.
- Priorità visuale rispetto a hit flash e VFX.
- Verifica specifica di Lollo e revisione trasversale dei personaggi con tell già implementati.

Non modificare:

- durata di Iperfocus o Distrazione;
- bonus/malus di Lollo;
- soglia termica o modificatori di Aleo;
- probabilità o logica degli stati di Alea;
- statistiche, cooldown, passive o abilità;
- collisioni e hitbox.

## Verifica

- Smoke: `tests/unit/test_ps029_state_tell_visibility.gd` (GUT). Il percorso
  legacy citato all'apertura (`tests/integration/_character_state_tells_smoke.gd`,
  marker `CHARACTER_STATE_TELLS_SMOKE_OK`) non esiste nel repository: la
  suite `tests/integration/` di quel tipo è stata dismessa dal cutover GUT, e
  l'analogo storico (`_b44_state_tells_smoke.gd`) resta solo come evidenza
  PS-001. Creato invece un test GUT dedicato, coerente con `CLAUDE.md` e con
  la convenzione delle altre card dell'area (`test_ps003_*`, `test_ps004_*`),
  registrato in `tools/milestone-test-map.json`.
- Profilo minimo prima della chiusura: `Relevant`.

## Gate manuali

- [ ] Runtime Windows
- [ ] Validazione statica APK
- [ ] Runtime fisico Pixel 9 (percorso: Lollo → osserva almeno un ciclo Iperfocus/Distrazione; Aleo → attraversa la soglia HP; verifica gli altri profili con tell attivo)
- [ ] Controllo percettivo richiesto: sì

## Decisioni

- **2026-08-30 — I tell di stato devono essere leggibili in combattimento reale.** L'esistenza tecnica di outline o tint non è sufficiente se il cambio di stato non viene percepito dal giocatore.
- **Sostituisce:** intensità/leggibilità corrente dei tell visuali quando insufficiente.
- **2026-09-01 — Verificato lo storico prima di implementare: la card non è
  obsoleta, è il seguito diretto di PS-001.** Su richiesta esplicita del
  proprietario di controllare i pregressi, riletti `git log` e
  [PS-001](../6_rejected/PS-001-tell-di-stato-senza-snaturare-lo-sprite.md):
  PS-001 ha introdotto il meccanismo di contorno (`PassiveStateOutline`,
  8 direzioni, sostituendo la tinta piena B44) ma i suoi stessi criteri
  percettivi ("resta leggibile a densità massima") sono rimasti aperti. Questa
  card estende esattamente quel meccanismo invece di duplicarlo.
- **2026-09-01 — Bordo di separazione scuro oltre al solo aumento di
  spessore.** `PassiveStateOutline` disegna ora un secondo contorno, più
  esterno e scuro (`separator_thickness`), sotto al colore di stato. Crea
  contrasto contro qualunque sfondo indipendentemente dalla combinazione
  cromatica, invece di affidarsi solo a colori più saturi. Spessore base
  alzato da 2.0 a 4.0 unità locali, separatore aggiunto a 2.0.
- **2026-09-01 — Spessore alzato oltre la prima stima dopo segnalazione
  diretta del proprietario a metà sessione.** Riferimento: "anche l'attuale
  sagoma risulta troppo sottile, specialmente su pixel [Android]". Verificato
  che `PerformanceProfile.render_scale` non è ancora consumato da alcun
  codice (dichiarato ma inerte), quindi la causa non è un downscale interno
  su Android: resta comunque un gate percettivo su device da chiudere.
- **2026-09-01 — Ricolorati `OUTLINE_LOLLO_DISTRACTED` e `OUTLINE_MIGI_SHIELD`.**
  Erano i due casi reali di "differenza cromatica minima" nel roster:
  `LOLLO_DISTRACTED` era un grigio-blu desaturato che si mimetizza con lo
  sfondo arena; `MIGI_SHIELD` e `MIGI_SHELL_READY` erano due ciano quasi
  identici (distanza RGB euclidea ≈0.18 su una scala 0–1.73). Riscritti a
  distanza ≥0.4, soglia ora imposta da test automatico su tutte le coppie del
  roster (Aleo, Lollo, Alea, Migi). Aleo e Alea avevano già contrasto
  sufficiente (≈0.9–1.1) e non sono stati toccati. Nessun nome di costante è
  cambiato: gli smoke esistenti che confrontano contro `OUTLINE_*` per nome
  restano validi senza modifiche.
- **2026-09-01 — Migi incluso nell'audit pur non essendo nominato nei criteri
  di accettazione.** Il criterio "gli altri personaggi ... vengono verificati
  nello stesso pass" copre esplicitamente questo caso; Migi usa lo stesso
  canale (`OUTLINE_MIGI_*`) e aveva il problema di contrasto più marcato del
  roster.
- **2026-09-01 — Nuovo test GUT dedicato invece del percorso smoke citato
  dalla card.** Vedi sezione Verifica: il percorso originale non esiste più
  nel repository dopo il cutover GUT.
- **2026-09-01 — Coordinare il gate percettivo di Alea con PS-028.** La
  [Gran Piroetta aggiornata](../5_completed/PS-028-rendi-piroetta-alea-circolare.md) usa ora
  una corona più circolare e priva di stelle grandi. Quando i gate verranno
  ripresi, il tell attivo di Alea va osservato anche durante questo VFX per
  verificare che resti leggibile; nessun gate è stato eseguito in questa
  sessione e lo stato della card resta invariato.
- **2026-09-02 — Eredita la bocciatura di PS-001: il meccanismo che questa
  card rinforzava è bocciato, non solo da rifinire.** Il proprietario ha
  bocciato `PassiveStateOutline` per tutti e quattro i personaggi (rompe la
  silhouette pixel-art, non si integra esteticamente). Spessore, separatore e
  contrasto cromatico introdotti qui restano una diagnosi tecnica corretta
  ("la leggibilità non deve dipendere solo dal colore") ma si applicano a un
  meccanismo che va sostituito, non solo rifinito ulteriormente. I criteri
  percettivi ancora aperti sopra restano intenzionalmente non spuntati. La
  responsabilità di trovare una soluzione sostitutiva passa a
  [PS-079](../5_completed/PS-079-particellare-tell-stato-personaggi.md); questa
  card resta storica come evidenza che il problema non era la scelta dei
  colori.
- **2026-09-04 — `SCARTATA`.** Eredita lo scarto definitivo di PS-001: il
  meccanismo a contorno che questa card rinforzava non verrà rilavorato.
  PS-079 (particellare non aderente) l'ha sostituito ed è `COMPLETATO`.

## Documenti sincronizzati

- [x] `prd.md` o `CLAUDE.md` — non necessario: nessuna nuova regola
      trasversale di presentazione, solo un rinforzo di un meccanismo già
      contrattualizzato da PS-001.
- [x] `characters.md` e `content-approvals.md` — non necessario: le
      descrizioni pubbliche esistenti ("un'aura ciano o arancio", "un
      contorno colorato... dichiara la fase") restano accurate; nessun
      colore pubblicamente documentato è cambiato (i colori ritoccati, Lollo
      distratto e Migi scudo, non erano nominati in `characters.md`).
- [ ] Nota `*-verification.md` — non ancora prodotta: nessuna evidenza
      Windows/Android raccolta in questa sessione.

## Note

Non uniformare necessariamente tutti i personaggi allo stesso effetto grafico. L'obiettivo è rendere ogni stato leggibile mantenendo l'identità visuale del relativo personaggio.

Lollo è il riferimento minimo da correggere; la card include un audit degli altri tell già esistenti per evitare che lo stesso problema rimanga altrove.

### Che cosa è cambiato

- [`scripts/vfx/passive_state_outline.gd`](../../../scripts/vfx/passive_state_outline.gd):
  `thickness` default 2.0 → 4.0; nuovo `separator_thickness` (default 2.0,
  `@export_range(0.0, 4.0, 0.1)`) e relativo `SEPARATOR_COLOR`, disegnati
  come secondo passaggio a 8 direzioni prima del colore di stato in `_draw()`.
- [`scripts/actors/player.gd`](../../../scripts/actors/player.gd): due nuovi
  getter di sola osservabilità, `get_passive_state_outline_thickness()` e
  `get_passive_state_outline_separator_thickness()`, sullo stesso schema di
  `get_character_self_modulate()` introdotto da PS-001.
- [`scripts/content/friend_passive_controller.gd`](../../../scripts/content/friend_passive_controller.gd):
  `OUTLINE_LOLLO_DISTRACTED` e `OUTLINE_MIGI_SHIELD` ricolorati (vedi
  Decisioni). Nessun'altra costante toccata.
- Nuovo [`tests/unit/test_ps029_state_tell_visibility.gd`](../../../tests/unit/test_ps029_state_tell_visibility.gd):
  spessore/separatore di default, distanza cromatica minima fra le coppie di
  stato del roster, finestra attiva di Alea (comparsa/colore/scomparsa) e
  transizione guscio/scudo di Migi — nessuno dei due coperto da
  `test_b44_state_tells.gd`.
- [`tools/milestone-test-map.json`](../../../tools/milestone-test-map.json):
  aggiunta la riga per il nuovo test alla regola che lega
  `friend_passive_controller.gd`/`passive_state_outline.gd`.

### Verifica eseguita

- `.\tools\run-milestone-checks.ps1 -Milestone PS-029 -Profile Focused -FocusedSmoke tests/unit/test_ps029_state_tell_visibility.gd -RefreshEditor -NoCache`
  → `PASS`, 4/4 test verdi (`test_ps029_outline_thickness_and_separator_increased`,
  `test_ps029_state_color_pairs_meet_minimum_contrast`,
  `test_ps029_alea_tell_active_only_during_window`,
  `test_ps029_migi_shell_and_shield_tells_are_distinct`), nessun
  `SCRIPT ERROR`/`FATAL EXCEPTION` nel log.

### Verifica NON eseguita

Il profilo `Relevant` (che include `test_b44_state_tells.gd` e le altre
regressioni dell'area) non è stato eseguito in questa sessione: il
proprietario ha scelto di fermarsi dopo un falso allarme di blocco (in realtà
era solo il prompt di conferma del comando, in attesa di approvazione).
Restano quindi aperti: profilo `Relevant`, tutti i gate manuali
Windows/APK/Pixel 9/percettivo elencati sopra, e la nota
`*-verification.md`. Il rischio di regressione sulle aree non ritoccate
(reset, pausa, priorità hit-flash) è basso perché il diff in quelle zone è
solo additivo (nuovi getter, nessuna riga esistente modificata), ma resta da
confermare con `Relevant` prima di passare a `COMPLETATO`.
