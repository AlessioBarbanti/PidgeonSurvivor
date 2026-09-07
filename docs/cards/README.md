# Board delle card

Questa board è la **sola fonte di verità operativa** per tutto il lavoro di
sviluppo: funzionalità, fix, arte, documentazione, tooling e release.

- Un file per card: `PS-<numero>-<slug>.md`, numerazione progressiva, nella
  cartella corrispondente alla fase corrente.
- Il vocabolario degli stati è: `DA DEFINIRE`,
  `BLOCCATO`, `PRONTO`, `IN CORSO`, `IN ATTESA ASSET`, `IN VERIFICA`,
  `COMPLETATO`, `SCARTATA`.
- Le sei cartelle sono numerate secondo l'ordine di avanzamento e
  raggruppano gli stati senza sostituirli:
  - `1_idea`: `DA DEFINIRE`;
  - `2_to_do`: `BLOCCATO`, `PRONTO` (non ancora pescata nello sprint corrente);
  - `3_in_sprint`: `PRONTO` (pescata nel blocco su cui si sta lavorando adesso,
    in coda), `IN CORSO` o `IN ATTESA ASSET`;
  - `4_to_test`: `IN VERIFICA`;
  - `5_completed`: `COMPLETATO`;
  - `6_rejected`: `SCARTATA`.
- `IN ATTESA ASSET` (PS-110) è una card di integrazione già cablata su un
  placeholder generato (`tools/generate-art-placeholder.ps1`), in attesa
  del solo asset reale prodotto da una card `art` collegata via
  `dipende_da`. Resta in `3_in_sprint` come `IN CORSO`; la selezione
  "prossima card" la ignora perché non è `PRONTO`. Vedi la regola dedicata
  più sotto.
- `SCARTATA` è uno stato terminale come `COMPLETATO`: il proprietario ha
  valutato la card e ha deciso di non perseguirla. Si applica da qualunque
  stato non `IN CORSO`; la card resta storica in `6_rejected` con il motivo
  dello scarto in `Decisioni`, non va eliminata né riaperta silenziosamente
  (un ripensamento apre una nuova card, come per `COMPLETATO`).
- Quando cambia fase, sposta il file nella cartella corretta e aggiorna il link
  nella board nello stesso cambiamento.
- Modello: [`_TEMPLATE.md`](./_TEMPLATE.md).
- Skill: `card-crea` per aprirne una, `card-risolvi` per chiuderla.
- Ogni lavoro parte da una card. Non creare roadmap o tracker paralleli.
- Le dipendenze vivono in `dipende_da`; una card non può essere `PRONTO` se un
  prerequisito non ha raggiunto almeno `IN VERIFICA` (si sblocca quando il
  prerequisito entra in `4_to_test`, non serve che sia `COMPLETATO`).
  Eccezione (PS-110): una card di integrazione che dipende da una card
  `tipo: art` può iniziare subito, anche col prerequisito ancora `PRONTO`/
  `IN CORSO`, cablando un placeholder al posto dell'asset reale — a patto
  che quella card `art` abbia già fissato la geometria di consegna in
  modalità pianificazione (PS-109). In tal caso l'integrazione entra in
  `IN ATTESA ASSET` invece che restare bloccata, ma non può comunque
  raggiungere `IN VERIFICA`/`COMPLETATO` finché l'asset reale non sostituisce
  il placeholder.
- Ordine: prima `IN CORSO`, poi `PRONTO` per priorità e, a parità, ID crescente.
- Sprint corrente: a "procediamo con la prossima card" si controlla prima
  `3_in_sprint/`. Se contiene ancora card, si continua da lì per priorità (a
  parità, ID crescente). Se `3_in_sprint/` è vuota, si sceglie da `2_to_do/` la
  card `PRONTO` a priorità più alta e la sua catena di dipendenza
  (`dipende_da`, in entrambe le direzioni) fino al confine naturale del
  filone; l'intero blocco si sposta in `3_in_sprint/` e si parte dalla prima.
  In caso di dubbio su quali card includere nel blocco, si chiede al
  proprietario prima di spostare i file.
- Card `tipo: art` che richiedono creare o generare nuovi asset grafici (non
  la sola integrazione, l'adattamento geometrico/procedurale o il riuso di
  arte esistente) sono di competenza dell'agente Game Art Designer
  (`.agents/skills/game-art-designer/SKILL.md`), disponibile sia su Claude
  (`.claude/agents/game-art-designer.md`) sia su Codex
  (`.codex/agents/game-art-designer.toml`); la skill `card-risolvi` su Claude
  non le seleziona automaticamente come "prossima card" e le implementa solo
  delegandole a quell'agente. La sintesi visiva vera e propria resta
  esclusiva di Codex (PS-112): il game-art-designer lato Claude non ha
  accesso diretto a ImageGen e, quando serve nuova sintesi non ancora
  prodotta da Codex, si ferma e la segnala invece di generarla con altri
  mezzi.
- Una card `tipo: art` che richiede nuovi asset **non include mai** la
  propria integrazione nei criteri di accettazione (PS-090): si ferma a
  master, derivato, manifest e art review. Collegare l'asset finito al dato,
  alla scena o al registry che lo consuma è compito di una card separata,
  dello stesso `tipo` che avrebbe avuto senza la componente grafica
  (`feat`/`fix`/`ux`/`chore`), collegata tramite `dipende_da` o aperta
  esplicitamente in autoria/handoff — mai bundlata dentro la card `art`.
  Le card `art` chiuse prima di PS-090 restano storiche sotto il contratto
  con cui sono state lavorate.
- Quando una richiesta è ambigua sulla direzione visiva o implica un asset
  che dovrà contenere/comporsi con contenuto variabile a runtime o
  integrarsi in un layout esistente, `card-crea` non fissa da sola
  "Comportamento atteso"/"Criteri di accettazione" (PS-109): delega prima la
  consultazione al Game Art Designer lato Claude in modalità pianificazione.
  Il sotto-agente non può interpellare direttamente il proprietario
  (`AskUserQuestion` non è disponibile ai sotto-agenti, PS-111): prepara le
  domande/opzioni e, se prevede nuova arte, la scomposizione in
  pezzi/geometria di consegna, ma è l'orchestratore (`card-crea`) a porle
  al proprietario e a rigirargli la risposta perché finalizzi la card.
  L'esecutore Codex resta comunque un puro produttore: opera solo su card
  già complete di direzione, mai in questa fase.
  Le card `art` chiuse prima di PS-109 restano storiche sotto il contratto
  con cui sono state lavorate.
- Una card di integrazione può procedere prima che l'asset reale esista,
  cablando `tools/generate-art-placeholder.ps1` alla geometria già decisa in
  pianificazione (PS-110): stato `IN ATTESA ASSET`, non `IN CORSO` generico,
  così è visibile in tabella senza dover risalire a mano la catena
  `dipende_da`. Il segnale serve anche a chi gestisce la coda di Codex: una
  card `art` referenziata da una riga `IN ATTESA ASSET` sta bloccando
  qualcosa di reale e ha priorità su una card `art` `PRONTO` che nessuno sta
  ancora aspettando. La card di integrazione non può chiudersi (`IN VERIFICA`/
  `COMPLETATO`) finché il pixel (0,0) del derivato referenziato è ancora la
  firma del placeholder (magenta pieno, `255,0,255,255`): è il gate
  automatico che impedisce di spedire uno stand-in per errore.
- Decisioni e motivazioni restano nella card. Il contratto risultante viene
  sincronizzato in PRD, `CLAUDE.md`, cataloghi o approvazioni pertinenti.
- Una card completata resta storica; un cambiamento successivo apre una nuova
  card e indica cosa sostituisce.

| ID | Titolo | Tipo | Area | Stato | Priorità | Dipende da |
|---|---|---|---|---|---|---|
| [PS-001](./6_rejected/PS-001-tell-di-stato-senza-snaturare-lo-sprite.md) | Comunicare la fase della passiva senza ridipingere lo sprite | ux | arte | SCARTATA | alta | — |
| [PS-002](./5_completed/PS-002-restyle-proiettili-giocatore-e-nemici.md) | Sostituire i proiettili "debug" con sprite ImageGen leggibili | art | arte | COMPLETATO | media | — |
| [PS-003](./5_completed/PS-003-conferma-abilita-passiva-zat.md) | Conferma il funzionamento di Guarigione Ritardata | chore | gameplay | COMPLETATO | alta | — |
| [PS-004](./5_completed/PS-004-lega-Tempesta-di-Tuoni-al-danno-recuperabile.md) | Lega Tempesta di Tuoni al danno recuperabile | feat | gameplay | COMPLETATO | alta | PS-003 |
| [PS-005](./5_completed/PS-005-Boss-timer.md) | Annuncia l'arrivo del Boss | ux | gameplay | COMPLETATO | alta | — |
| [PS-006](./5_completed/PS-006-bosses-new-abilities.md) | Dai agli Evil una Signature Ability | feat | gameplay | COMPLETATO | alta | PS-004 |
| [PS-007](./5_completed/PS-007-impedire-run-AFK-lategame.md) | Impedisci che la late run diventi AFK | feat | gameplay | COMPLETATO | alta | — |
| [PS-008](./5_completed/PS-008-eventi-di-ondata.md) | Introduci eventi d'ondata | feat | gameplay | COMPLETATO | alta | — |
| [PS-009](./5_completed/PS-009-trasparenza-dialog-boss.md) | Rendi trasparente la Boss UI sotto il Player | ux | ui | COMPLETATO | media | — |
| [PS-012](./5_completed/PS-012-barb-specialities.md) | Introduci le Specialità di Barb | feat | gameplay | COMPLETATO | alta | — |
| [PS-013](./5_completed/PS-013-crash-typedarray-seconda-offerta-upgrade.md) | Correggi il crash TypedArray alla seconda offerta upgrade | fix | ui | COMPLETATO | alta | — |
| [PS-014](./5_completed/PS-014-logo-welcome-fuori-viewport.md) | Riporta il logo della welcome dentro il viewport | fix | ui | COMPLETATO | media | — |
| [PS-015](./5_completed/PS-015-bordo-pixelato-card-selettore.md) | Adegua il test della card centrale del selettore all'artwork di selezione | fix | ui | COMPLETATO | bassa | — |
| [PS-016](./5_completed/PS-016-tutorial-fuori-safe-area.md) | Riporta il tutorial dentro la safe area su tutti i profili | fix | ui | COMPLETATO | media | — |
| [PS-017](./5_completed/PS-017-font-size-locale-selettore-personaggi.md) | Rimuovi il font-size locale reintrodotto nel selettore personaggi | fix | ui | COMPLETATO | bassa | — |
| [PS-018](./5_completed/PS-018-hud-composta-danno-restart-vita.md) | Correggi danno e restart della vita nella scena HUD composta | fix | gameplay | COMPLETATO | alta | — |
| [PS-019](./5_completed/PS-019-manifest-vfx-hash-non-aggiornato.md) | Riallinea l'hash del manifest VFX per instinctive_dodge_accent | chore | arte | COMPLETATO | bassa | — |
| [PS-020](./5_completed/PS-020-diagnostica-flakiness-backdrop-selettore.md) | Diagnostica il fallimento intermittente sul backdrop del selettore | chore | tooling | COMPLETATO | bassa | — |
| [PS-021](./5_completed/PS-021-import-orfano-backdrop-bronze.md) | Rimuovi l'import orfano del backdrop bronze del selettore | chore | arte | COMPLETATO | bassa | — |
| [PS-022](./5_completed/PS-022-b15-target-registrati-in-piu-suite-completa.md) | Diagnostica i due target registrati in più di test_b15_boss_encounter | chore | tooling | COMPLETATO | media | — |
| [PS-023](./5_completed/PS-023-runner-verifica-affidabile.md) | Rendi leggibile e non bloccante il runner di verifica | chore | tooling | COMPLETATO | alta | — |
| [PS-024](./5_completed/PS-024-riduci-danno-onda-urto-magno.md) | Riduci il danno dell'Onda d'Urto di Magno | fix | gameplay | COMPLETATO | alta | — |
| [PS-025](./5_completed/PS-025-aumenta-dimensioni-avvertimento-boss.md) | Aumenta le dimensioni dell'avvertimento Boss | ux | ui | COMPLETATO | media | — |
| [PS-026](./5_completed/PS-026-rinomina-piccione-speciale-piccione-malvagio.md) | Rinomina Piccione Speciale in Piccione Malvagio | chore | gameplay | COMPLETATO | media | — |
| [PS-027](./5_completed/PS-027-rimuovi-artefatto-powerslide-bea.md) | Rimuovi l'artefatto residuo dalla Powerslide di Bea | fix | arte | COMPLETATO | media | — |
| [PS-028](./5_completed/PS-028-rendi-piroetta-alea-circolare.md) | Rendi circolare la rotazione della Gran Piroetta | art | arte | COMPLETATO | media | — |
| [PS-029](./6_rejected/PS-029-rendi-tell-stato-personaggi-piu-visibili.md) | Rendi più visibili i tell di stato dei personaggi | ux | gameplay | SCARTATA | alta | — |
| [PS-030](./5_completed/PS-030-runner-crash-su-test-eliminato.md) | Correggi il crash del runner quando un test viene eliminato | fix | tooling | COMPLETATO | media | — |
| [PS-031](./5_completed/PS-031-runner-crasha-su-warning-stderr-di-git.md) | Il runner crasha su un warning stderr di git invece di continuare | fix | tooling | COMPLETATO | media | — |
| [PS-032](./5_completed/PS-032-seed-run-non-deterministico-nei-test-gut.md) | Il seed di run non deterministico nei test GUT causa flakiness sparsa | fix | tooling | COMPLETATO | alta | — |
| [PS-033](./5_completed/PS-033-riquadro-vita-boss-minimale-floating.md) | Elimina l'HUD dedicata del Boss, la vita resta solo overhead | ux | ui | COMPLETATO | media | — |
| [PS-034](./5_completed/PS-034-rimuovi-xp-fissa-ricompensa-boss.md) | Rimuovi la ricompensa XP fissa dalla sconfitta del Boss | fix | gameplay | COMPLETATO | alta | — |
| [PS-036](./5_completed/PS-036-Barb-specialities-ux-enhance.md) | Rendi distinta la schermata delle Specialità di Barb | ux | ui | COMPLETATO | media | — |
| [PS-037](./5_completed/PS-037-alza-probabilita-evil-boss-50.md) | Alza la probabilità Evil Boss dal 25% al 50% | chore | gameplay | COMPLETATO | media | — |
| [PS-038](./5_completed/PS-038-documentazione-game-design-review-interna.md) | Documentazione di game design per review interna | chore | docs | COMPLETATO | media | — |
| [PS-039](./5_completed/PS-039-api-mancante-vittoria-ricompensa-boss.md) | Regressione sulla ricompensa XP del Boss dopo PS-006 | fix | gameplay | COMPLETATO | alta | — |
| [PS-040](./5_completed/PS-040-iframe-atterraggio-powerslide-bea.md) | Aggiungi i-frame all'atterraggio della Powerslide di Bea | feat | gameplay | COMPLETATO | media | — |
| [PS-041](./5_completed/PS-041-scia-slancio-magno-non-si-resetta.md) | La scia di slancio di Magno non si azzera all'avvio di una nuova partita | fix | gameplay | COMPLETATO | media | — |
| [PS-042](./5_completed/PS-042-subordina-scintille-powerslide-bea.md) | Subordina le scintille della Powerslide al nastro di fuoco | fix | arte | COMPLETATO | media | — |
| [PS-043](./5_completed/PS-043-riallinea-board-con-i-file-card.md) | Riallineare la board ai file-card realmente presenti | chore | docs | COMPLETATO | alta | — |
| [PS-044](./5_completed/PS-044-catture-ui-oneste-e-rappresentative.md) | Rendere il pacchetto di catture UI onesto e rappresentativo | chore | tooling | COMPLETATO | alta | — |
| [PS-045](./5_completed/PS-045-gerarchia-visiva-arena-di-run.md) | Riequilibrare composizione e leggibilità dell'arena 20:9 | ux | arte | COMPLETATO | alta | — |
| [PS-046](./5_completed/PS-046-isola-il-modal-di-level-up.md) | Isolare il modal di level-up da HUD e cronometro | ux | ui | COMPLETATO | alta | — |
| [PS-047](./5_completed/PS-047-gerarchia-carte-upgrade.md) | Compattare e gerarchizzare le carte upgrade | ux | ui | COMPLETATO | alta | PS-046 |
| [PS-048](./5_completed/PS-048-fedelta-al-runtime-di-tre-pagine-tutorial.md) | Allineare tre pagine del tutorial a ciò che il gioco mostra davvero | ux | ui | COMPLETATO | media | — |
| [PS-049](./5_completed/PS-049-genera-illustrazioni-tutorial.md) | Generare le tre illustrazioni definitive del tutorial | art | arte | COMPLETATO | media | PS-048 |
| [PS-050](./5_completed/PS-050-uniforma-impostazioni-welcome-alla-pausa.md) | Uniformare le impostazioni della welcome al sistema della pausa | ux | ui | COMPLETATO | media | — |
| [PS-051](./5_completed/PS-051-identita-individuale-degli-evil.md) | Dare identità individuale agli Evil nella Boss intro | ux | ui | COMPLETATO | media | — |
| [PS-052](./5_completed/PS-052-genera-ritratti-evil-e-icone-signature.md) | Generare i ritratti Evil e le icone Signature definitivi | art | arte | COMPLETATO | media | PS-051 |
| [PS-053](./5_completed/PS-053-riepilogo-finale-della-run.md) | Trasformare la schermata finale in un riepilogo della run | feat | ui | COMPLETATO | media | — |
| [PS-055](./5_completed/PS-055-filosofia-della-vittoria.md) | Decidere la filosofia della vittoria fra Survival e Difesa Grigliata | chore | gameplay | COMPLETATO | media | — |
| [PS-056](./2_to_do/PS-056-ducking-e-stinger-nei-momenti-chiave.md) | Aggiungere ducking e stinger su avvertimento Boss, level-up e ricompensa Barb | feat | audio | PRONTO | bassa | — |
| [PS-057](./5_completed/PS-057-errori-fisica-su-split-del-piccione-viola.md) | Eliminare gli errori di fisica quando il piccione viola si sdoppia | fix | gameplay | COMPLETATO | media | — |
| [PS-058](./5_completed/PS-058-genera-arte-nuovi-prop-arena.md) | Generare l'arte definitiva dei nuovi prop dell'arena | art | arte | COMPLETATO | media | PS-045 |
| [PS-059](./5_completed/PS-059-schiarisci-contrasto-modal-level-up.md) | Schiarire il contrasto fra velo e carte nei modal di scelta | fix | ui | COMPLETATO | alta | PS-046, PS-047 |
| [PS-060](./5_completed/PS-060-ci-build-apk-github-release.md) | Compilare l'APK Android in CI e pubblicarlo come GitHub Release | chore | tooling | COMPLETATO | media | — |
| [PS-061](./5_completed/PS-061-catture-ui-in-ci-per-validazione-remota.md) | Eseguire il pacchetto di catture UI in CI per la validazione visiva remota | chore | tooling | COMPLETATO | media | PS-044, PS-060 |
| [PS-062](./5_completed/PS-062-setup-sandbox-remoto-validazione-locale.md) | Script di setup Godot nel sandbox remoto per validare prima di commit/push | chore | tooling | COMPLETATO | media | — |
| [PS-063](./5_completed/PS-063-metapanel-trabocca-carte-upgrade.md) | Il MetaPanel delle carte upgrade esce dal bordo della carta | fix | ui | COMPLETATO | alta | PS-047 |
| [PS-064](./5_completed/PS-064-top-level-ignora-offset-safe-area.md) | I nodi top_level dei modal ignorano l'offset del safe-rect del display | fix | ui | COMPLETATO | alta | PS-059 |
| [PS-065](./5_completed/PS-065-barb-reward-header-non-entra-in-safe-area.md) | L'header del premio Barb non entra nel rettangolo sicuro a risoluzioni compatte | fix | ui | COMPLETATO | media | PS-064 |
| [PS-066](./5_completed/PS-066-rimuovi-numero-scorciatoia-carte.md) | Rimuovere il numero di scorciatoia visibile dalle carte upgrade | fix | ui | COMPLETATO | bassa | PS-047 |
| [PS-067](./5_completed/PS-067-carte-upgrade-e-barb-escono-di-6px-dalla-safe-area.md) | Le carte upgrade e Barb escono di 6px dalla safe area | fix | ui | COMPLETATO | alta | — |
| [PS-068](./5_completed/PS-068-genera-ritratti-busto-cast-giocabile.md) | Generare i ritratti busto definitivi del cast giocabile | art | arte | COMPLETATO | media | — |
| [PS-069](./5_completed/PS-069-ridisegna-selettore-personaggi-per-ritratti-busto.md) | Ridisegnare il selettore personaggi attorno ai ritratti busto | ux | ui | COMPLETATO | media | PS-068 |
| [PS-070](./2_to_do/PS-070-aggiorna-aspettativa-32x32-evil-portrait-b17.md) | Aggiorna l'aspettativa 32x32 su evil_portrait in test_b17_friend_content | fix | tooling | PRONTO | bassa | — |
| [PS-071](./5_completed/PS-071-pannello-boss-intro-esce-dalla-safe-area.md) | Il pannello della Boss Intro esce dalla safe area | fix | ui | COMPLETATO | media | — |
| [PS-072](./5_completed/PS-072-audio-schivata-sesto-senso-equino-bea.md) | Dai un audio alla schivata Sesto Senso Equino di Bea | feat | audio | COMPLETATO | media | — |
| [PS-073](./5_completed/PS-073-musica-boss-dedicata.md) | Introduci una musica Boss dedicata | feat | audio | COMPLETATO | media | — |
| [PS-074](./2_to_do/PS-074-suono-click-generico-bottoni-ui.md) | Aggiungi un suono di click ai bottoni UI oggi silenziosi | ux | audio | PRONTO | bassa | — |
| [PS-075](./6_rejected/PS-075-sfx-morte-nemico.md) | Aggiungi un SFX alla morte dei nemici | feat | audio | SCARTATA | media | — |
| [PS-076](./5_completed/PS-076-aumenta-densita-nemica-a-schermo.md) | Aumenta la densità nemica a schermo a parità di rischio e progressione | chore | gameplay | COMPLETATO | alta | — |
| [PS-077](./5_completed/PS-077-espandi-pool-specialita-barb.md) | Espandi il pool delle Specialità di Barb con le carte signature rimaste | feat | gameplay | COMPLETATO | media | PS-012 |
| [PS-078](./4_to_test/PS-078-tematizza-catalogo-specialita-barb.md) | Tematizza le Specialità di Barb come pezzi di carne alla griglia | art | arte | IN VERIFICA | media | PS-077 |
| [PS-079](./5_completed/PS-079-particellare-tell-stato-personaggi.md) | Sostituisci il contorno bocciato con un particellare non aderente | ux | arte | COMPLETATO | alta | — |
| [PS-080](./4_to_test/PS-080-musica-vittoria-sconfitta.md) | Aggiungi una musica dedicata a vittoria e sconfitta | feat | audio | IN VERIFICA | media | — |
| [PS-081](./2_to_do/PS-081-layer-musicale-intensita-late-run.md) | Aggiungi un layer musicale di intensità crescente late-run | feat | audio | PRONTO | media | — |
| [PS-082](./4_to_test/PS-082-camera-non-centrata-su-restart.md) | Ricentra davvero la camera sul personaggio al restart | fix | gameplay | IN VERIFICA | media | — |
| [PS-083](./5_completed/PS-083-storicizza-prompt-e-reference-generazione.md) | Storicizzare prompt e reference di generazione | chore | arte | COMPLETATO | bassa | — |
| [PS-084](./5_completed/PS-084-direzione-visuale-per-personaggio-e-reference-cast.md) | Documentare la direzione visuale per personaggio e collegarla agli agenti art | chore | arte | COMPLETATO | media | — |
| [PS-085](./4_to_test/PS-085-introduci-sparo-manuale-con-secondo-joystick.md) | Introduci lo sparo manuale come modalità alternativa allo sparo automatico | feat | gameplay | IN VERIFICA | media | — |
| [PS-086](./5_completed/PS-086-cattura-output-runner-strozza-i-test.md) | La cattura dell'output del runner strozza l'esecuzione dei test | fix | tooling | COMPLETATO | alta | — |
| [PS-087](./5_completed/PS-087-definisci-statistiche-base-personaggi.md) | Definisci gli scarti di statistiche base per personaggio | chore | gameplay | COMPLETATO | alta | — |
| [PS-088](./5_completed/PS-088-verifica-differenziazione-statistiche-personaggi.md) | Verifica automaticamente la differenziazione statistica dei personaggi | chore | tooling | COMPLETATO | alta | PS-087 |
| [PS-089](./5_completed/PS-089-elimina-sovrapposizioni-tema-carne-powerup.md) | Elimina le sovrapposizioni fra il tema carne delle Specialità e il catalogo powerup ordinario | chore | arte | COMPLETATO | media | — |
| [PS-090](./5_completed/PS-090-separa-generazione-integrazione-card-art.md) | Separa generazione asset e integrazione nel workflow delle card tipo art | chore | tooling | COMPLETATO | media | — |
| [PS-091](./6_rejected/PS-091-genera-placeholder-powerup-nuove-statistiche.md) | Genera i placeholder icona per i powerup di eventuali nuove statistiche | art | arte | SCARTATA | bassa | PS-087, PS-090 |
| [PS-092](./2_to_do/PS-092-nuova-icona-ravviva-la-brace.md) | Genera una nuova icona per Ravviva la Brace! (ex Bis di Salsiccia) | art | arte | PRONTO | bassa | — |
| [PS-093](./4_to_test/PS-093-nuovi-assi-scarto-base-personaggi.md) | Introduci cinque nuovi assi di scarto base per personaggio | feat | gameplay | IN VERIFICA | media | PS-087 |
| [PS-094](./4_to_test/PS-094-specialita-cariche-abilita-attiva.md) | Introduci una Specialità di Barb per cariche multiple dell'abilità attiva | feat | gameplay | IN VERIFICA | media | — |
| [PS-095](./4_to_test/PS-095-audita-spawn-nemici-sempre-fuori-vista.md) | Audita e correggi lo spawn nemici che compare dentro l'area visibile | fix | gameplay | IN VERIFICA | media | — |
| [PS-096](./4_to_test/PS-096-await-orfano-grow-to-fit-content-upgrade-card.md) | Diagnostica l'await orfano di UpgradeCard._grow_to_fit_content in full suite | fix | tooling | IN VERIFICA | bassa | — |
| [PS-097](./4_to_test/PS-097-await-orfano-defer-reflow-top-margin.md) | Applica a UpgradeOverlay/BarbRewardOverlay la correzione dell'await orfano di PS-096 | fix | tooling | IN VERIFICA | bassa | PS-096 |
| [PS-098](./4_to_test/PS-098-genera-aura-potenziamento-e-tell-termici.md) | Genera l'aura di potenziamento di Lollo e i tell termici di Aleo | art | arte | IN VERIFICA | media | — |
| [PS-099](./4_to_test/PS-099-aura-iperfocus-lollo-e-tell-termico-aleo.md) | Sostituisci il particellare di Lollo e Aleo con aura di potenziamento e tell termico | ux | arte | IN VERIFICA | media | PS-098 |
| [PS-100](./4_to_test/PS-100-rimuovi-ansia-dalle-specialita-di-barb.md) | Rimuovi L'Ansia dalle Specialità di Barb | chore | gameplay | IN VERIFICA | media | — |
| [PS-101](./4_to_test/PS-101-racconta-fame-dietro-agli-evil.md) | Racconta la fame dietro agli Evil e la redenzione di Barb | feat | gameplay | IN VERIFICA | media | — |
| [PS-102](./4_to_test/PS-102-cornice-dedicata-boss-intro.md) | Genera una cornice dedicata per la Boss Intro | art | arte | IN VERIFICA | media | — |
| [PS-103](./4_to_test/PS-103-integra-cornice-boss-intro.md) | Integra la cornice dedicata nella Boss Intro | ux | ui | IN VERIFICA | media | PS-102 |
| [PS-104](./5_completed/PS-104-icona-calice-sobrieta-alea.md) | Genera l'icona del calice per la Sobrietà di Alea | art | arte | COMPLETATO | media | — |
| [PS-105](./4_to_test/PS-105-nuova-passiva-alea-due-dita-e-parto.md) | Sostituisci la passiva di Alea con Due Dita e Parto | feat | gameplay | IN VERIFICA | media | — |
| [PS-106](./4_to_test/PS-106-integra-icona-calice-sobrieta-alea-hud.md) | Integra l'icona del calice Sobrietà di Alea in HUD | ux | ui | IN VERIFICA | media | PS-104 |
| [PS-107](./4_to_test/PS-107-rigenera-icona-punto-di-cottura.md) | Rigenera l'icona di Punto di Cottura (ex Salamoia Bolognese) | art | arte | IN VERIFICA | media | — |
| [PS-108](./4_to_test/PS-108-integra-carta-punto-di-cottura.md) | Integra la carta Punto di Cottura nel catalogo live | chore | gameplay | IN VERIFICA | media | PS-107 |
| [PS-109](./5_completed/PS-109-consulta-game-art-designer-prima-di-fissare-criteri-art.md) | Consulta il game-art-designer prima di fissare i criteri di una card che tocca l'arte | chore | tooling | COMPLETATO | media | PS-090 |
| [PS-110](./5_completed/PS-110-placeholder-asset-e-stato-in-attesa-asset.md) | Placeholder generato e stato IN ATTESA ASSET per procedere prima dell'asset reale | chore | tooling | COMPLETATO | media | PS-109 |
| [PS-111](./5_completed/PS-111-askuserquestion-non-disponibile-ai-sottoagenti.md) | Correggi PS-109: AskUserQuestion non è disponibile ai sotto-agenti | fix | tooling | COMPLETATO | media | PS-109 |
| [PS-112](./5_completed/PS-112-vieta-imagegen-diretto-game-art-designer-claude.md) | Vieta l'accesso diretto a ImageGen al game-art-designer lato Claude | fix | tooling | COMPLETATO | media | — |
| [PS-113](./4_to_test/PS-113-cabla-cap-fps-performance-profile.md) | Cabla il cap FPS dal PerformanceProfile attivo | perf | piattaforma | IN VERIFICA | alta | — |
| [PS-114](./1_idea/PS-114-cabla-render-scale-risoluzione-interna.md) | Cabla render_scale del PerformanceProfile alla risoluzione interna | perf | piattaforma | DA DEFINIRE | media | — |
| [PS-115](./2_to_do/PS-115-modalita-risparmio-energetico-profilo-mobile-low.md) | Aggiungi una Modalità risparmio energetico con profilo mobile_low | feat | piattaforma | BLOCCATO | media | PS-113, PS-117 |
| [PS-116](./4_to_test/PS-116-aumenta-risoluzione-sprite-gameplay-cast.md) | Aumenta la risoluzione nativa dello sprite di gameplay del cast a 64×64 | fix | arte | IN VERIFICA | media | — |
| [PS-117](./2_to_do/PS-117-subviewport-mondo-di-gioco-per-render-scale.md) | Sposta il mondo di gioco in un SubViewport dedicato per abilitare render_scale | perf | piattaforma | PRONTO | media | — |
| [PS-118](./4_to_test/PS-118-nome-e-icona-nona-specialita-cariche-abilita.md) | Genera nome e icona definitivi per la nona Specialità (cariche multiple abilità attiva) | art | arte | IN VERIFICA | bassa | — |
| [PS-119](./4_to_test/PS-119-fix-spawn-non-sospeso-boss-ricorrente-con-evento-attivo.md) | Correggi lo spawn ordinario che non si sospende durante un Boss se un evento d'ondata è già maturato | fix | gameplay | IN VERIFICA | alta | — |
| [PS-120](./4_to_test/PS-120-fix-ricarica-cariche-abilita-e-indicatore-hud.md) | Correggi il tetto di ricarica delle cariche abilità e distingui l'indicatore HUD di ricarica in background | fix | gameplay | IN VERIFICA | alta | PS-094 |
| [PS-121](./4_to_test/PS-121-carte-ripetibili-sature-escono-dal-pool.md) | Le carte ripetibili che hanno raggiunto il proprio tetto runtime escono dal pool di scelta | fix | gameplay | IN VERIFICA | alta | — |
| [PS-122](./4_to_test/PS-122-contorno-ricarica-riparte-da-capo.md) | Il contorno di ricarica in background deve sempre ripartire da un cerchio pieno | fix | gameplay | IN VERIFICA | media | PS-120 |
| [PS-123](./4_to_test/PS-123-ricalibra-hp-danno-archetipi-nemici-post-ps076.md) | Ricalibra HP e danno degli archetipi nemici dopo la densificazione di PS-076 | fix | gameplay | IN VERIFICA | alta | — |
| [PS-124](./4_to_test/PS-124-eventi-ondata-che-riducono-la-pressione.md) | Correggi gli eventi d'ondata che riducono la pressione invece di aumentarla | fix | gameplay | IN VERIFICA | alta | — |
| [PS-125](./6_rejected/PS-125-scala-xp-costante-lungo-la-curva-late-run.md) | Rendi costante la scala XP/kill lungo la curva late-run | fix | gameplay | SCARTATA | alta | — |
| [PS-126](./4_to_test/PS-126-nessuna-scala-difficolta-oltre-5-minuti.md) | Introduci una curva di pressione oltre il minuto 5 (Boss ricorrente trivializzato) | feat | gameplay | IN VERIFICA | alta | PS-055 |
