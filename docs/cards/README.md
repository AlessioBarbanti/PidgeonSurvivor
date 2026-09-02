# Board delle card

Questa board è la **sola fonte di verità operativa** per tutto il lavoro di
sviluppo: funzionalità, fix, arte, documentazione, tooling e release.

- Un file per card: `PS-<numero>-<slug>.md`, numerazione progressiva, nella
  cartella corrispondente alla fase corrente.
- Il vocabolario degli stati è: `DA DEFINIRE`,
  `BLOCCATO`, `PRONTO`, `IN CORSO`, `IN VERIFICA`, `COMPLETATO`.
- Le cinque cartelle sono numerate secondo l'ordine di avanzamento e
  raggruppano gli stati senza sostituirli:
  - `1_idea`: `DA DEFINIRE`;
  - `2_to_do`: `BLOCCATO`, `PRONTO` (non ancora pescata nello sprint corrente);
  - `3_in_sprint`: `PRONTO` (pescata nel blocco su cui si sta lavorando adesso,
    in coda) o `IN CORSO`;
  - `4_to_test`: `IN VERIFICA`;
  - `5_completed`: `COMPLETATO`.
- Quando cambia fase, sposta il file nella cartella corretta e aggiorna il link
  nella board nello stesso cambiamento.
- Modello: [`_TEMPLATE.md`](./_TEMPLATE.md).
- Skill: `card-crea` per aprirne una, `card-risolvi` per chiuderla.
- Ogni lavoro parte da una card. Non creare roadmap o tracker paralleli.
- Le dipendenze vivono in `dipende_da`; una card non può essere `PRONTO` se un
  prerequisito non ha raggiunto almeno `IN VERIFICA` (si sblocca quando il
  prerequisito entra in `4_to_test`, non serve che sia `COMPLETATO`).
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
  delegandole a quell'agente.
- Decisioni e motivazioni restano nella card. Il contratto risultante viene
  sincronizzato in PRD, `CLAUDE.md`, cataloghi o approvazioni pertinenti.
- Una card completata resta storica; un cambiamento successivo apre una nuova
  card e indica cosa sostituisce.

| ID | Titolo | Tipo | Area | Stato | Priorità | Dipende da |
|---|---|---|---|---|---|---|
| [PS-001](./4_to_test/PS-001-tell-di-stato-senza-snaturare-lo-sprite.md) | Comunicare la fase della passiva senza ridipingere lo sprite | ux | arte | IN VERIFICA | alta | — |
| [PS-002](./5_completed/PS-002-restyle-proiettili-giocatore-e-nemici.md) | Sostituire i proiettili "debug" con sprite ImageGen leggibili | art | arte | COMPLETATO | media | — |
| [PS-003](./5_completed/PS-003-conferma-abilita-passiva-zat.md) | Conferma il funzionamento di Guarigione Ritardata | chore | gameplay | COMPLETATO | alta | — |
| [PS-004](./4_to_test/PS-004-lega-Tempesta-di-Tuoni-al-danno-recuperabile.md) | Lega Tempesta di Tuoni al danno recuperabile | feat | gameplay | IN VERIFICA | alta | PS-003 |
| [PS-005](./4_to_test/PS-005-Boss-timer.md) | Annuncia l'arrivo del Boss | ux | gameplay | IN VERIFICA | alta | — |
| [PS-006](./4_to_test/PS-006-bosses-new-abilities.md) | Dai agli Evil una Signature Ability | feat | gameplay | IN VERIFICA | alta | PS-004 |
| [PS-007](./4_to_test/PS-007-impedire-run-AFK-lategame.md) | Impedisci che la late run diventi AFK | feat | gameplay | IN VERIFICA | alta | — |
| [PS-008](./4_to_test/PS-008-eventi-di-ondata.md) | Introduci eventi d'ondata | feat | gameplay | IN VERIFICA | alta | — |
| [PS-009](./5_completed/PS-009-trasparenza-dialog-boss.md) | Rendi trasparente la Boss UI sotto il Player | ux | ui | COMPLETATO | media | — |
| [PS-012](./4_to_test/PS-012-barb-specialities.md) | Introduci le Specialità di Barb | feat | gameplay | IN VERIFICA | alta | — |
| [PS-013](./4_to_test/PS-013-crash-typedarray-seconda-offerta-upgrade.md) | Correggi il crash TypedArray alla seconda offerta upgrade | fix | ui | IN VERIFICA | alta | — |
| [PS-014](./4_to_test/PS-014-logo-welcome-fuori-viewport.md) | Riporta il logo della welcome dentro il viewport | fix | ui | IN VERIFICA | media | — |
| [PS-015](./5_completed/PS-015-bordo-pixelato-card-selettore.md) | Adegua il test della card centrale del selettore all'artwork di selezione | fix | ui | COMPLETATO | bassa | — |
| [PS-016](./4_to_test/PS-016-tutorial-fuori-safe-area.md) | Riporta il tutorial dentro la safe area su tutti i profili | fix | ui | IN VERIFICA | media | — |
| [PS-017](./5_completed/PS-017-font-size-locale-selettore-personaggi.md) | Rimuovi il font-size locale reintrodotto nel selettore personaggi | fix | ui | COMPLETATO | bassa | — |
| [PS-018](./5_completed/PS-018-hud-composta-danno-restart-vita.md) | Correggi danno e restart della vita nella scena HUD composta | fix | gameplay | COMPLETATO | alta | — |
| [PS-019](./5_completed/PS-019-manifest-vfx-hash-non-aggiornato.md) | Riallinea l'hash del manifest VFX per instinctive_dodge_accent | chore | arte | COMPLETATO | bassa | — |
| [PS-020](./5_completed/PS-020-diagnostica-flakiness-backdrop-selettore.md) | Diagnostica il fallimento intermittente sul backdrop del selettore | chore | tooling | COMPLETATO | bassa | — |
| [PS-021](./5_completed/PS-021-import-orfano-backdrop-bronze.md) | Rimuovi l'import orfano del backdrop bronze del selettore | chore | arte | COMPLETATO | bassa | — |
| [PS-022](./5_completed/PS-022-b15-target-registrati-in-piu-suite-completa.md) | Diagnostica i due target registrati in più di test_b15_boss_encounter | chore | tooling | COMPLETATO | media | — |
| [PS-023](./4_to_test/PS-023-runner-verifica-affidabile.md) | Rendi leggibile e non bloccante il runner di verifica | chore | tooling | IN VERIFICA | alta | — |
| [PS-024](./4_to_test/PS-024-riduci-danno-onda-urto-magno.md) | Riduci il danno dell'Onda d'Urto di Magno | fix | gameplay | IN VERIFICA | alta | — |
| [PS-025](./4_to_test/PS-025-aumenta-dimensioni-avvertimento-boss.md) | Aumenta le dimensioni dell'avvertimento Boss | ux | ui | IN VERIFICA | media | — |
| [PS-026](./4_to_test/PS-026-rinomina-piccione-speciale-piccione-malvagio.md) | Rinomina Piccione Speciale in Piccione Malvagio | chore | gameplay | IN VERIFICA | media | — |
| [PS-027](./4_to_test/PS-027-rimuovi-artefatto-powerslide-bea.md) | Rimuovi l'artefatto residuo dalla Powerslide di Bea | fix | arte | IN VERIFICA | media | — |
| [PS-028](./4_to_test/PS-028-rendi-piroetta-alea-circolare.md) | Rendi circolare la rotazione della Gran Piroetta | art | arte | IN VERIFICA | media | — |
| [PS-029](./4_to_test/PS-029-rendi-tell-stato-personaggi-piu-visibili.md) | Rendi più visibili i tell di stato dei personaggi | ux | gameplay | IN VERIFICA | alta | — |
| [PS-030](./5_completed/PS-030-runner-crash-su-test-eliminato.md) | Correggi il crash del runner quando un test viene eliminato | fix | tooling | COMPLETATO | media | — |
| [PS-031](./5_completed/PS-031-runner-crasha-su-warning-stderr-di-git.md) | Il runner crasha su un warning stderr di git invece di continuare | fix | tooling | COMPLETATO | media | — |
| [PS-032](./5_completed/PS-032-seed-run-non-deterministico-nei-test-gut.md) | Il seed di run non deterministico nei test GUT causa flakiness sparsa | fix | tooling | COMPLETATO | alta | — |
| [PS-033](./4_to_test/PS-033-riquadro-vita-boss-minimale-floating.md) | Elimina l'HUD dedicata del Boss, la vita resta solo overhead | ux | ui | IN VERIFICA | media | — |
| [PS-034](./4_to_test/PS-034-rimuovi-xp-fissa-ricompensa-boss.md) | Rimuovi la ricompensa XP fissa dalla sconfitta del Boss | fix | gameplay | IN VERIFICA | alta | — |
| [PS-036](./4_to_test/PS-036-Barb-specialities-ux-enhance.md) | Rendi distinta la schermata delle Specialità di Barb | ux | ui | IN VERIFICA | media | — |
| [PS-037](./4_to_test/PS-037-alza-probabilita-evil-boss-50.md) | Alza la probabilità Evil Boss dal 25% al 50% | chore | gameplay | IN VERIFICA | media | — |
| [PS-038](./5_completed/PS-038-documentazione-game-design-review-interna.md) | Documentazione di game design per review interna | chore | docs | COMPLETATO | media | — |
| [PS-039](./5_completed/PS-039-api-mancante-vittoria-ricompensa-boss.md) | Regressione sulla ricompensa XP del Boss dopo PS-006 | fix | gameplay | COMPLETATO | alta | — |
| [PS-040](./4_to_test/PS-040-iframe-atterraggio-powerslide-bea.md) | Aggiungi i-frame all'atterraggio della Powerslide di Bea | feat | gameplay | IN VERIFICA | media | — |
| [PS-041](./4_to_test/PS-041-scia-slancio-magno-non-si-resetta.md) | La scia di slancio di Magno non si azzera all'avvio di una nuova partita | fix | gameplay | IN VERIFICA | media | — |
| [PS-042](./4_to_test/PS-042-subordina-scintille-powerslide-bea.md) | Subordina le scintille della Powerslide al nastro di fuoco | fix | arte | IN VERIFICA | media | — |
| [PS-043](./5_completed/PS-043-riallinea-board-con-i-file-card.md) | Riallineare la board ai file-card realmente presenti | chore | docs | COMPLETATO | alta | — |
| [PS-044](./4_to_test/PS-044-catture-ui-oneste-e-rappresentative.md) | Rendere il pacchetto di catture UI onesto e rappresentativo | chore | tooling | IN VERIFICA | alta | — |
| [PS-045](./4_to_test/PS-045-gerarchia-visiva-arena-di-run.md) | Riequilibrare composizione e leggibilità dell'arena 20:9 | ux | arte | IN VERIFICA | alta | — |
| [PS-046](./4_to_test/PS-046-isola-il-modal-di-level-up.md) | Isolare il modal di level-up da HUD e cronometro | ux | ui | IN VERIFICA | alta | — |
| [PS-047](./4_to_test/PS-047-gerarchia-carte-upgrade.md) | Compattare e gerarchizzare le carte upgrade | ux | ui | IN VERIFICA | alta | PS-046 |
| [PS-048](./4_to_test/PS-048-fedelta-al-runtime-di-tre-pagine-tutorial.md) | Allineare tre pagine del tutorial a ciò che il gioco mostra davvero | ux | ui | IN VERIFICA | media | — |
| [PS-049](./4_to_test/PS-049-genera-illustrazioni-tutorial.md) | Generare le tre illustrazioni definitive del tutorial | art | arte | IN VERIFICA | media | PS-048 |
| [PS-050](./4_to_test/PS-050-uniforma-impostazioni-welcome-alla-pausa.md) | Uniformare le impostazioni della welcome al sistema della pausa | ux | ui | IN VERIFICA | media | — |
| [PS-051](./4_to_test/PS-051-identita-individuale-degli-evil.md) | Dare identità individuale agli Evil nella Boss intro | ux | ui | IN VERIFICA | media | — |
| [PS-052](./4_to_test/PS-052-genera-ritratti-evil-e-icone-signature.md) | Generare i ritratti Evil e le icone Signature definitivi | art | arte | IN VERIFICA | media | PS-051 |
| [PS-053](./4_to_test/PS-053-riepilogo-finale-della-run.md) | Trasformare la schermata finale in un riepilogo della run | feat | ui | IN VERIFICA | media | — |
| [PS-054](./2_to_do/PS-054-presenza-del-personaggio-nel-selettore.md) | Adattare il selettore personaggi al 20:9 | ux | ui | PRONTO | media | — |
| [PS-055](./1_idea/PS-055-filosofia-della-vittoria.md) | Decidere la filosofia della vittoria fra Survival e Difesa Grigliata | chore | gameplay | DA DEFINIRE | media | — |
| [PS-056](./2_to_do/PS-056-ducking-e-stinger-nei-momenti-chiave.md) | Aggiungere ducking e stinger su avvertimento Boss, level-up e ricompensa Barb | feat | audio | PRONTO | bassa | — |
| [PS-057](./4_to_test/PS-057-errori-fisica-su-split-del-piccione-viola.md) | Eliminare gli errori di fisica quando il piccione viola si sdoppia | fix | gameplay | IN VERIFICA | media | — |
| [PS-058](./4_to_test/PS-058-genera-arte-nuovi-prop-arena.md) | Generare l'arte definitiva dei nuovi prop dell'arena | art | arte | IN VERIFICA | media | PS-045 |
| [PS-059](./5_completed/PS-059-schiarisci-contrasto-modal-level-up.md) | Schiarire il contrasto fra velo e carte nei modal di scelta | fix | ui | COMPLETATO | alta | PS-046, PS-047 |
| [PS-060](./5_completed/PS-060-ci-build-apk-github-release.md) | Compilare l'APK Android in CI e pubblicarlo come GitHub Release | chore | tooling | COMPLETATO | media | — |
| [PS-061](./5_completed/PS-061-catture-ui-in-ci-per-validazione-remota.md) | Eseguire il pacchetto di catture UI in CI per la validazione visiva remota | chore | tooling | COMPLETATO | media | PS-044, PS-060 |
| [PS-062](./5_completed/PS-062-setup-sandbox-remoto-validazione-locale.md) | Script di setup Godot nel sandbox remoto per validare prima di commit/push | chore | tooling | COMPLETATO | media | — |
| [PS-063](./4_to_test/PS-063-metapanel-trabocca-carte-upgrade.md) | Il MetaPanel delle carte upgrade esce dal bordo della carta | fix | ui | IN VERIFICA | alta | PS-047 |
| [PS-064](./4_to_test/PS-064-top-level-ignora-offset-safe-area.md) | I nodi top_level dei modal ignorano l'offset del safe-rect del display | fix | ui | IN VERIFICA | alta | PS-059 |
| [PS-065](./4_to_test/PS-065-barb-reward-header-non-entra-in-safe-area.md) | L'header del premio Barb non entra nel rettangolo sicuro a risoluzioni compatte | fix | ui | IN VERIFICA | media | PS-064 |
| [PS-066](./4_to_test/PS-066-rimuovi-numero-scorciatoia-carte.md) | Rimuovere il numero di scorciatoia visibile dalle carte upgrade | fix | ui | IN VERIFICA | bassa | PS-047 |
| [PS-067](./4_to_test/PS-067-carte-upgrade-e-barb-escono-di-6px-dalla-safe-area.md) | Le carte upgrade e Barb escono di 6px dalla safe area | fix | ui | IN VERIFICA | alta | — |
| [PS-068](./2_to_do/PS-068-genera-ritratti-busto-cast-giocabile.md) | Generare i ritratti busto definitivi del cast giocabile | art | arte | PRONTO | media | — |
| [PS-069](./2_to_do/PS-069-ridisegna-selettore-personaggi-per-ritratti-busto.md) | Ridisegnare il selettore personaggi per ospitare i ritratti busto | ux | ui | BLOCCATO | media | PS-068 |
| [PS-070](./2_to_do/PS-070-aggiorna-aspettativa-32x32-evil-portrait-b17.md) | Aggiorna l'aspettativa 32x32 su evil_portrait in test_b17_friend_content | fix | tooling | PRONTO | bassa | — |
| [PS-071](./4_to_test/PS-071-pannello-boss-intro-esce-dalla-safe-area.md) | Il pannello della Boss Intro esce dalla safe area | fix | ui | IN VERIFICA | media | — |
| [PS-072](./2_to_do/PS-072-audio-schivata-sesto-senso-equino-bea.md) | Dai un audio alla schivata Sesto Senso Equino di Bea | feat | audio | PRONTO | media | — |
| [PS-073](./2_to_do/PS-073-musica-boss-dedicata.md) | Introduci una musica Boss dedicata | feat | audio | PRONTO | media | — |
| [PS-074](./2_to_do/PS-074-suono-click-generico-bottoni-ui.md) | Aggiungi un suono di click ai bottoni UI oggi silenziosi | ux | audio | PRONTO | bassa | — |
| [PS-075](./2_to_do/PS-075-sfx-morte-nemico.md) | Aggiungi un SFX alla morte dei nemici | feat | audio | PRONTO | media | — |
| [PS-076](./2_to_do/PS-076-aumenta-densita-nemica-a-schermo.md) | Aumenta la densità nemica a schermo a parità di rischio e progressione | chore | gameplay | PRONTO | alta | — |
| [PS-077](./2_to_do/PS-077-espandi-pool-specialita-barb.md) | Espandi il pool delle Specialità di Barb con le carte signature rimaste | feat | gameplay | PRONTO | media | PS-012 |
| [PS-078](./2_to_do/PS-078-tematizza-catalogo-specialita-barb.md) | Tematizza il catalogo delle Specialità di Barb come piatti speciali del grigliatore | art | arte | BLOCCATO | media | PS-077 |
| [PS-079](./2_to_do/PS-079-particellare-tell-stato-personaggi.md) | Sostituisci il contorno bocciato con un particellare non aderente | ux | arte | PRONTO | alta | — |
| [PS-080](./2_to_do/PS-080-musica-vittoria-sconfitta.md) | Aggiungi una musica dedicata a vittoria e sconfitta | feat | audio | PRONTO | media | — |
| [PS-081](./2_to_do/PS-081-layer-musicale-intensita-late-run.md) | Aggiungi un layer musicale di intensità crescente late-run | feat | audio | PRONTO | media | — |
