# Board delle card

Card leggere per modifiche e richieste che non meritano una slice B-series nel
[development plan](../development-plan.md). Il development plan resta la fonte di
verità operativa per la roadmap; questa board copre il lavoro puntuale.

- Un file per card: `PS-<numero>-<slug>.md`, numerazione progressiva.
- Il vocabolario degli stati è lo stesso del development plan: `DA DEFINIRE`,
  `BLOCCATO`, `PRONTO`, `IN CORSO`, `IN VERIFICA`, `VERIFICATO`, `COMPLETATO`.
- Modello: [`_TEMPLATE.md`](./_TEMPLATE.md).
- Skill: `card-crea` per aprirne una, `card-risolvi` per chiuderla.
- Se una card cresce fino a richiedere gate di piattaforma completi e una nota di
  verifica, promuovila a slice B-series nel development plan e lascia nella card
  il puntatore.

| ID | Titolo | Tipo | Area | Stato | Priorità |
|---|---|---|---|---|---|
| [PS-001](./PS-001-tell-di-stato-senza-snaturare-lo-sprite.md) | Comunicare la fase della passiva senza ridipingere lo sprite | ux | arte | IN CORSO | alta |
| [PS-002](./PS-002-restyle-proiettili-giocatore-e-nemici.md) | Sostituire i proiettili "debug" con sprite ImageGen leggibili | art | arte | IN VERIFICA | media |
