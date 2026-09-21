---
id: PS-201
titolo: Il nome Spiedo confligge con la lista di parole vietate
tipo: chore
area: contenuti
stato: DA DEFINIRE
priorita: bassa
dipende_da: []
origine:
creato: 2026-09-21
aggiornato: 2026-09-21
---

# PS-201 — Il nome Spiedo confligge con la lista di parole vietate

## Contesto

[PS-196](../5_completed/PS-196-contratto-armi-per-personaggio.md) dichiara che
i nomi delle armi vivono nel registro utensile/brace/condimento e **mai** in
quello della carne, riservato alle Specialità di Barb.

L'arma di Bea approvata dal proprietario il 2026-09-18 si chiama `Spiedo`. La
lista `FORBIDDEN_MEAT_WORDS` di
[tests/unit/test_ps089_ordinary_catalog_meat_audit.gd:27-28](../../../tests/unit/test_ps089_ordinary_catalog_meat_audit.gd)
contiene sia `spiedino` sia `spiedo`.

Nessun gate è rosso: quel test audita soltanto i titoli delle carte ordinarie
del catalogo (`_discover_ordinary_upgrade_definitions()`), non le armi. Il
conflitto è quindi fra il contratto scritto e il dato, non fra due
verificatori — e per questo non lo vedrebbe nessuno finché non lo si guarda.

La tensione è reale in entrambe le direzioni: uno spiedo *è* un utensile da
brace, ma il progetto quella parola l'ha già classificata come carne quando
ha scritto la lista.

## Domanda aperta per il proprietario

Due uscite, entrambe legittime:

1. **Il nome resta.** Si dichiara che `spiedo` nudo è l'utensile e che la
   lista lo vieta solo per i titoli dei powerup, dove `spiedino` lo farebbe
   leggere come il boccone. Costo: una riga di eccezione motivata in
   `docs/powerup-catalog.md` e un commento nella lista.
2. **L'arma si rinomina.** Il candidato è `Ferretto` — è letteralmente lo
   spiedo abruzzese come oggetto, e la parola non è un taglio. Costo: il
   `.tres`, `docs/characters.md` e le card PS-198/PS-200.

Finché la domanda è aperta il nome resta `Spiedo` e il gioco funziona: non
blocca nulla.

## Ambito

- `data/weapons/spiedo.tres` (solo se si rinomina).
- `docs/characters.md`, `docs/powerup-catalog.md`.
- `tests/unit/test_ps089_ordinary_catalog_meat_audit.gd` — eventuale commento
  o estensione dell'audit anche alle armi.

## Verifica

Dipende dall'uscita scelta. Se l'audit viene esteso anche ai nomi delle armi,
serve una riga in `tools/milestone-test-map.json` che leghi `data/weapons/*`
a quel test.

## Gate manuali

- [ ] Runtime Windows — non pertinente
- [ ] Validazione statica APK — non pertinente
- [ ] Runtime fisico Pixel 9 — non pertinente
- [ ] Controllo percettivo richiesto: no

## Decisioni

- **2026-09-21 — Card aperta invece di rinominare d'ufficio.** Il nome è stato
  approvato esplicitamente dal proprietario: cambiarlo per far quadrare una
  lista interna sarebbe una decisione di contenuto presa di nascosto.

## Note

Osservazione minore della stessa famiglia: `marinata` (arma di Marghe,
PS-200) non è nella lista, ma `salamoia` sì. Se il criterio è la famiglia
semantica e non la parola esatta, va rivista anche quella.
