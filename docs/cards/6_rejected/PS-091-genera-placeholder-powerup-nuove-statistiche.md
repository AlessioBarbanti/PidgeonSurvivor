---
id: PS-091
titolo: Genera i placeholder icona per i powerup di eventuali nuove statistiche
tipo: art
area: arte
priorita: bassa
stato: SCARTATA
dipende_da: [PS-087, PS-090]
origine: conversazione del proprietario 2026-09-04
creato: 2026-09-04
aggiornato: 2026-09-04
---

# PS-091 — Genera i placeholder icona per i powerup di eventuali nuove statistiche

## Contesto

[PS-087](../5_completed/PS-087-definisci-statistiche-base-personaggi.md) può concludere
che i tre assi B47 esistenti (salute, velocità, cadenza) non bastano a
differenziare in modo coerente ogni personaggio dal proprio ruolo, e
raccomandare un nuovo asse statistico. Se questo accade, ogni nuovo asse
esposto anche come powerup ordinario avrà bisogno di una nuova carta
`UpgradeDefinition` e quindi di una nuova icona a tema grigliatore — non
carne, per non collidere con [PS-078](../3_in_sprint/PS-078-tematizza-catalogo-specialita-barb.md)/[PS-089](../5_completed/PS-089-elimina-sovrapposizioni-tema-carne-powerup.md).
Questa card esiste per preparare quell'asset senza aspettare che l'intera
implementazione del nuovo asse sia pronta.

## Comportamento atteso

Per ogni nuovo asse statistico che PS-087 raccomanda esplicitamente e che il
proprietario conferma, esiste un'icona placeholder pronta per il runtime
(master + derivato + manifest), coerente con la direzione visiva grigliatore
già stabilita, pronta per essere referenziata da una futura carta powerup —
ma non ancora referenziata da nessuna, perché quella carta non esiste finché
non la implementa una card di integrazione separata.

## Criteri di accettazione

- [x] Questa card si attiva **solo se** PS-087 chiude raccomandando almeno un
      nuovo asse statistico; se PS-087 si chiude senza quella
      raccomandazione, questa card passa a `SCARTATA` con riferimento alla
      decisione di PS-087, senza produrre alcun asset. **Esito: `SCARTATA`**,
      vedi Decisioni.
- [ ] Per ogni nuovo asse confermato dal proprietario, esiste un'icona
      `128×128` derivata in `assets/art/icons/upgrades/generated/`, con
      master HD corrispondente in `hd/` e riga nel relativo
      `ASSET-MANIFEST.md`.
- [ ] L'icona segue la direzione visiva già stabilita in
      `docs/powerup-catalog.md` (utensili, condimenti, pirofile, brace,
      cottura — mai carne, riservata alle Specialità di Barb).
- [ ] L'icona non è referenziata da alcun `.tres`, scena o test: questa card
      produce solo l'asset, per contratto [PS-090](./PS-090-separa-generazione-integrazione-card-art.md).
      Collegarla a una nuova `UpgradeDefinition` è compito di una card di
      integrazione separata, aperta quando l'asse viene effettivamente
      implementato.
- [ ] Nessuna modifica a `data/upgrades/*.tres` esistenti, a
      `UpgradeRegistry`, a `UpgradeEffectRegistry` o a qualunque scena.

## Ambito

- `assets/art/icons/upgrades/hd/` e `assets/art/icons/upgrades/generated/`:
  solo le nuove icone placeholder.
- `assets/art/icons/upgrades/ASSET-MANIFEST.md`.

Non toccare:

- `data/upgrades/*.tres`, `UpgradeRegistry`, `UpgradeEffectRegistry`,
  `scenes/game/movement_slice.tscn`: la carta powerup che userà questa icona
  non viene creata qui;
- `data/friends/*.tres` e il meccanismo B47: quello è PS-087;
- le Specialità di Barb e il resto del catalogo ordinario: nessuna icona
  esistente viene toccata.

## Verifica

- Nessuno smoke GUT: la card non produce alcun riferimento runtime da
  testare. La verifica è la sola art review (coerenza, leggibilità,
  produzione) descritta dalla skill Game Art Designer.
- Profilo minimo prima della chiusura: nessuno (nessun dato o scena di
  runtime cambia).

## Gate manuali

- [ ] Runtime Windows: non applicabile, nessun runtime coinvolto
- [ ] Validazione statica APK: non applicabile
- [ ] Runtime fisico Pixel 9: non applicabile
- [ ] Controllo percettivo richiesto: sì — l'icona va valutata a dimensione
      reale `128×128` prima di essere accettata come placeholder, anche se
      non ancora integrata in una carta.

## Decisioni

- **2026-09-04 — `SCARTATA`: PS-087 non ha raccomandato alcun nuovo asse.**
  [PS-087](../5_completed/PS-087-definisci-statistiche-base-personaggi.md) ha
  chiuso (`COMPLETATO`) concludendo che i tre assi B47 esistenti bastano a
  differenziare tutti gli otto personaggi dal proprio ruolo, con solo Alea e
  Aleo rivisti; nessun quarto asse statistico è stato raccomandato (vedi
  Decisioni di PS-087). Per il primo criterio di accettazione di questa
  card, l'esito previsto e ora verificato è lo scarto senza lavoro svolto:
  nessuna icona prodotta, nessuna modifica a `data/upgrades/*.tres`.
- **2026-09-04 — Card condizionale, non speculativa nel contenuto.** Non
  genera in anticipo un'intera famiglia di icone per assi ipotetici: resta
  bloccata finché PS-087 non nomina esplicitamente un asse reale, poi produce
  solo l'icona per quell'asse — coerente con il vincolo della skill Game Art
  Designer di non produrre in anticipo famiglie di asset non richieste.
- **2026-09-04 — Solo generazione, mai integrazione.** Applica da subito la
  regola di [PS-090](./PS-090-separa-generazione-integrazione-card-art.md):
  l'icona esce pronta ma non referenziata; la carta powerup che la userà è
  una card di integrazione futura, aperta insieme all'implementazione
  meccanica del nuovo asse.
- **2026-09-04 — Esito plausibile: `SCARTATA`.** Se PS-087 non raccomanda
  nessun nuovo asse — esito atteso quanto l'alternativa, dato che i tre assi
  esistenti potrebbero bastare — questa card si scarta senza lavoro svolto:
  non è un fallimento della card, è l'esito previsto di una domanda aperta.
- **2026-09-04 — Non contraddetta da [PS-093](../2_to_do/PS-093-nuovi-assi-scarto-base-personaggi.md).**
  PS-093 introduce cinque nuovi assi di scarto base, ma nasce da una
  richiesta diretta del proprietario in una conversazione successiva, non
  da una raccomandazione di PS-087 (che infatti non l'ha mai fatta): il
  trigger scritto sopra resta quello letterale e non si è mai verificato.
  Nel merito, PS-093 non genera comunque nuove carte del catalogo ordinario
  (compone coi powerup già esistenti per XP/raggio/difesa, introduce il
  critico come sistema in `WeaponController` senza impegnarsi a costruire
  una carta catalogo per esso): non c'è quindi un buco di icone lasciato
  scoperto da questo scarto. Se in futuro nascesse davvero una nuova carta
  catalogo per uno di quegli assi, è materia di una card nuova aperta allora
  (stesso principio già dichiarato per `COMPLETATO`/`SCARTATA` nella board),
  non una riapertura di questa.

## Documenti sincronizzati

- [ ] `assets/art/icons/upgrades/ASSET-MANIFEST.md`, se la card produce
      un'icona.
- [ ] `docs/powerup-catalog.md`, solo se il proprietario vuole registrare qui
      il nuovo asse come proposta futura — non un obbligo di questa card.

## Note

Questa card resta `BLOCCATO` finché PS-087 non raggiunge almeno `IN
VERIFICA` con una raccomandazione esplicita di nuovo asse, e finché PS-090
non stabilisce il contratto di sola generazione a cui questa card si
attiene fin dalla scrittura.
