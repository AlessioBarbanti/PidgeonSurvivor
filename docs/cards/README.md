# Board delle card

Questa board è la **sola fonte di verità operativa** per tutto il lavoro di
sviluppo: funzionalità, fix, arte, documentazione, tooling e release.

- Un file per card: `PS-<numero>-<slug>.md`, numerazione progressiva.
- Il vocabolario degli stati è: `DA DEFINIRE`,
  `BLOCCATO`, `PRONTO`, `IN CORSO`, `IN VERIFICA`, `VERIFICATO`, `COMPLETATO`.
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
| [PS-001](./PS-001-tell-di-stato-senza-snaturare-lo-sprite.md) | Comunicare la fase della passiva senza ridipingere lo sprite | ux | arte | IN CORSO | alta | — |
| [PS-002](./PS-002-restyle-proiettili-giocatore-e-nemici.md) | Sostituire i proiettili "debug" con sprite ImageGen leggibili | art | arte | COMPLETATO | media | — |
| [PS-003](./PS-003-conferma-abilita-passiva-zat.md) | Confermare Guarigione Ritardata | chore | gameplay | PRONTO | alta | — |
| [PS-004](./PS-004-lega-Tempesta-di-Tuoni-al-danno-recuperabile.md) | Legare Tempesta di Tuoni al danno recuperabile | feat | gameplay | BLOCCATO | alta | PS-003 |
| [PS-005](./PS-005-Boss-timer.md) | Annunciare l'arrivo del Boss | ux | gameplay | PRONTO | alta | — |
| [PS-006](./PS-006-bosses-new-abilities.md) | Dare agli Evil una Signature Ability | feat | gameplay | BLOCCATO | alta | PS-004 |
| [PS-007](./PS-007-impedire-run-AFK-lategame.md) | Impedire che la late run diventi AFK | feat | gameplay | PRONTO | alta | — |
| [PS-008](./PS-008-eventi-di-ondata.md) | Introdurre eventi d'ondata | feat | gameplay | PRONTO | alta | — |
| [PS-009](./PS-009-trasparenza-dialog-boss.md) | Rendere trasparente la Boss UI sotto il Player | ux | ui | PRONTO | media | — |
| [PS-010](./PS-010-implementa-difesa-grigliata.md) | Implementare Difesa Grigliata | feat | gameplay | PRONTO | alta | — |
| [PS-011](./PS-011-confeziona-prima-release-nativa.md) | Confezionare la prima release nativa | chore | piattaforma | BLOCCATO | alta | PS-010 |
