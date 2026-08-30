# Mappa della documentazione

La documentazione è separata per funzione, così stato corrente, contratti,
decisioni ed evidenze non si duplicano.

## Documenti correnti

| Documento | Domanda a cui risponde |
|---|---|
| [`cards/README.md`](./cards/README.md) | Cosa è aperto, cosa viene dopo, da cosa dipende e quali decisioni sono state prese? |
| [`prd.md`](./prd.md) | Come deve funzionare il prodotto corrente? |
| [`characters.md`](./characters.md) | Qual è l'identità corrente degli otto profili? |
| [`powerup-catalog.md`](./powerup-catalog.md) | Quali powerup esistono o sono proposti? |
| [`verification-workflow.md`](./verification-workflow.md) | Come funzionano profili, cache, marker e log del runner? |
| [`setup.md`](./setup.md) | Come si prepara toolchain ed export locale? |

## Evidenze

I file `b*-verification.md` e `m0-verification.md` sono verbali storici: vanno
aperti dalla card o dal riferimento storico interessato, non letti come roadmap. Restano nella
radice di `docs/` per non rompere i collegamenti esistenti.

- fondazioni: `m0`, B03–B18 e B22;
- refinement: B18B–B18W;
- evoluzione: B24–B36;
- chiusura aggregata: [`b24-b35-gate-closure-verification.md`](./b24-b35-gate-closure-verification.md).

Una nota di verifica registra soltanto prove realmente eseguite. Un cambio di
stato o un'accettazione del proprietario resta nella card e non riscrive
retroattivamente il verbale.

## Archivio

[`archive/`](./archive/README.md) conserva i vecchi piani, i decision log e le
proposte superate. I file archiviati non sono backlog attivi; si consultano per
razionali e ricostruzione storica.

Le note temporanee devono diventare card oppure aggiornare un contratto durevole
e poi essere archiviate o rimosse. Non creare un secondo tracker generale.
