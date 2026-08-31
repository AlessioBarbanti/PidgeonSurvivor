# Board delle card

Questa board è la **sola fonte di verità operativa** per tutto il lavoro di
sviluppo: funzionalità, fix, arte, documentazione, tooling e release.

- Un file per card: `PS-<numero>-<slug>.md`, numerazione progressiva, nella
  cartella corrispondente alla fase corrente.
- Il vocabolario degli stati è: `DA DEFINIRE`,
  `BLOCCATO`, `PRONTO`, `IN CORSO`, `IN VERIFICA`, `COMPLETATO`.
- Le quattro cartelle raggruppano gli stati senza sostituirli:
  - `idea`: `DA DEFINIRE`;
  - `to_do`: `BLOCCATO`, `PRONTO`, `IN CORSO`;
  - `to_test`: `IN VERIFICA`;
  - `completed`: `COMPLETATO`.
- Quando cambia fase, sposta il file nella cartella corretta e aggiorna il link
  nella board nello stesso cambiamento.
- Modello: [`_TEMPLATE.md`](./_TEMPLATE.md).
- Skill: `card-crea` per aprirne una, `card-risolvi` per chiuderla.
- Ogni lavoro parte da una card. Non creare roadmap o tracker paralleli.
- Le dipendenze vivono in `dipende_da`; una card non può essere `PRONTO` se un
  prerequisito non è `COMPLETATO`.
- Ordine: prima `IN CORSO`, poi `PRONTO` per priorità e, a parità, ID crescente.
- Decisioni e motivazioni restano nella card. Il contratto risultante viene
  sincronizzato in PRD, `CLAUDE.md`, cataloghi o approvazioni pertinenti.
- Una card completata resta storica; un cambiamento successivo apre una nuova
  card e indica cosa sostituisce.

| ID | Titolo | Tipo | Area | Stato | Priorità | Dipende da |
|---|---|---|---|---|---|---|
| [PS-001](./to_test/PS-001-tell-di-stato-senza-snaturare-lo-sprite.md) | Comunicare la fase della passiva senza ridipingere lo sprite | ux | arte | IN VERIFICA | alta | — |
| [PS-002](./completed/PS-002-restyle-proiettili-giocatore-e-nemici.md) | Sostituire i proiettili "debug" con sprite ImageGen leggibili | art | arte | COMPLETATO | media | — |
| [PS-003](./completed/PS-003-conferma-abilita-passiva-zat.md) | Confermare Guarigione Ritardata | chore | gameplay | COMPLETATO | alta | — |
| [PS-004](./to_test/PS-004-lega-Tempesta-di-Tuoni-al-danno-recuperabile.md) | Legare Tempesta di Tuoni al danno recuperabile | feat | gameplay | IN VERIFICA | alta | PS-003 |
| [PS-005](./to_test/PS-005-Boss-timer.md) | Annunciare l'arrivo del Boss | ux | gameplay | IN VERIFICA | alta | — |
| [PS-006](./to_test/PS-006-bosses-new-abilities.md) | Dare agli Evil una Signature Ability | feat | gameplay | IN VERIFICA | alta | PS-004 |
| [PS-007](./to_test/PS-007-impedire-run-AFK-lategame.md) | Impedire che la late run diventi AFK | feat | gameplay | IN VERIFICA | alta | — |
| [PS-008](./to_test/PS-008-eventi-di-ondata.md) | Introdurre eventi d'ondata | feat | gameplay | IN VERIFICA | alta | — |
| [PS-009](./completed/PS-009-trasparenza-dialog-boss.md) | Rendere trasparente la Boss UI sotto il Player | ux | ui | COMPLETATO | media | — |
| [PS-010](./idea/PS-010-implementa-difesa-grigliata.md) | Implementare Difesa Grigliata | feat | gameplay | DA DEFINIRE | alta | — |
| [PS-011](./idea/PS-011-confeziona-prima-release-nativa.md) | Confezionare la prima release nativa | chore | piattaforma | DA DEFINIRE | alta | PS-010 |
| [PS-012](./to_test/PS-012-barb-specialities.md) | Introdurre le Specialità di Barb | feat | gameplay | IN VERIFICA | alta | — |
| [PS-013](./to_test/PS-013-crash-typedarray-seconda-offerta-upgrade.md) | Correggere il crash TypedArray alla seconda offerta upgrade | fix | ui | IN VERIFICA | alta | — |
| [PS-014](./to_test/PS-014-logo-welcome-fuori-viewport.md) | Riportare il logo della welcome dentro il viewport | fix | ui | IN VERIFICA | media | — |
| [PS-015](./completed/PS-015-bordo-pixelato-card-selettore.md) | Adeguare il test della card centrale del selettore all'artwork di selezione | fix | ui | COMPLETATO | bassa | — |
| [PS-016](./to_test/PS-016-tutorial-fuori-safe-area.md) | Riportare il tutorial dentro la safe area su tutti i profili | fix | ui | IN VERIFICA | media | — |
| [PS-017](./completed/PS-017-font-size-locale-selettore-personaggi.md) | Rimuovere il test che vietava font-size locali nel selettore personaggi | fix | ui | COMPLETATO | bassa | — |
| [PS-018](./completed/PS-018-hud-composta-danno-restart-vita.md) | Correggere danno e restart della vita nella scena HUD composta | fix | gameplay | COMPLETATO | alta | — |
| [PS-019](./completed/PS-019-manifest-vfx-hash-non-aggiornato.md) | Riallineare l'hash del manifest VFX per instinctive_dodge_accent | chore | arte | COMPLETATO | bassa | — |
| [PS-020](./completed/PS-020-diagnostica-flakiness-backdrop-selettore.md) | Diagnosticare il fallimento intermittente sul backdrop del selettore | chore | tooling | COMPLETATO | bassa | — |
| [PS-021](./completed/PS-021-import-orfano-backdrop-bronze.md) | Rimuovere l'import orfano del backdrop bronze del selettore | chore | arte | COMPLETATO | bassa | — |
| [PS-022](./to_do/PS-022-b15-target-registrati-in-piu-suite-completa.md) | Diagnosticare i due target registrati in più di test_b15_boss_encounter | chore | tooling | PRONTO | media | — |
| [PS-023](./to_test/PS-023-runner-verifica-affidabile.md) | Rendere leggibile e non bloccante il runner di verifica | chore | tooling | IN VERIFICA | alta | — |
| [PS-026](./to_do/PS-026-rinomina-piccione-speciale-piccione-malvagio.md) | Rinomina Piccione Speciale in Piccione Malvagio | chore | gameplay | IN CORSO | media | — |
| [PS-030](./to_do/PS-030-runner-crash-su-test-eliminato.md) | Correggi il crash del runner quando un test viene eliminato | fix | tooling | PRONTO | media | — |
| [PS-033](./to_test/PS-033-riquadro-vita-boss-minimale-floating.md) | Eliminare l'HUD dedicata del Boss, vita solo overhead | ux | ui | IN VERIFICA | media | — |
| [PS-036](./to_test/PS-036-Barb-specialities-ux-enhance.md) | Rendi distinta la schermata delle Specialità di Barb | ux | ui | IN VERIFICA | media | — |
| [PS-037](./to_do/PS-037-alza-probabilita-evil-boss-50.md) | Alza la probabilità Evil Boss dal 25% al 50% | chore | gameplay | IN CORSO | media | — |
