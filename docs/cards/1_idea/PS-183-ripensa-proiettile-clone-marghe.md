---
id: PS-183
titolo: Ripensa l'attacco del clone di Marghe, forse un'esplosione al posto del proiettile
tipo: ux
area: gameplay
stato: DA DEFINIRE
priorita: alta
dipende_da: []
origine: test reale su Pixel 9 della v0.3.0, 2026-09-15
creato: 2026-09-15
aggiornato: 2026-09-15
---

# PS-183 — Ripensa l'attacco del clone di Marghe, forse un'esplosione al posto del proiettile

## Contesto

[PS-173](../4_to_test/PS-173-clone-marghe-spara-ai-nemici.md) e
[PS-174](../4_to_test/PS-174-evil-marghe-clone-minaccia-accumulo.md) hanno
dato al clone di Marghe (e al clone di Evil Marghe) un attacco a proiettili
verso i nemici vicini. Testando la build reale v0.3.0, il proprietario non è
convinto dal trattamento attuale del proiettile e propone come possibile
alternativa un'esplosione — senza però che sia ancora una richiesta ferma
("l'idea dei proiettili del clone di Marghe non mi piace, forse se
esplodesse?").

Non è chiaro se il problema riportato è:
- la **leggibilità** (il proiettile del clone si confonde con l'arma del
  Player — criterio già scritto sia in PS-173 che in PS-174, quindi se è
  questo potrebbe essere un fallimento di quel criterio più che una
  richiesta di redesign);
- il **feeling** dell'attacco (un proiettile "sparato" non si sente
  coerente con l'identità teatrale/cosplay del clone);
- oppure altro non ancora esplicitato.

E se l'idea "esplosione" è un cambio di **area d'effetto** (danno in area
invece che proiettile singolo, con implicazioni di bilanciamento) o solo un
**restyle visivo** del colpo esistente (stesso danno/target, VFX diverso).

## Comportamento atteso

**Da definire** dopo la risposta del proprietario: questa card non fissa
ancora "Comportamento atteso"/"Criteri di accettazione" perché la direzione
è ambigua e potrebbe richiedere nuovo asset VFX (consultare
`game-art-designer` in modalità pianificazione se la risposta implica
sintesi visiva nuova, non solo riuso).

## Domanda per il proprietario

1. Cosa esattamente non convince nel proiettile attuale: la leggibilità
   (si confonde con l'arma del Player), il feeling (troppo "sparo" e poco
   "clone teatrale"), o altro?
2. L'idea "esplosione" è un cambio di area d'effetto (danno in area al posto
   del proiettile singolo) o solo un restyle visivo del colpo, a parità di
   danno/target?
3. Vale sia per il clone di Marghe (PS-173, alleato) sia per quello di Evil
   Marghe (PS-174, nemico), o solo per uno dei due?

## Criteri di accettazione

Da scrivere dopo la risposta del proprietario.

## Ambito

- Script legati a PS-173/PS-174 (clone di Marghe ed Evil Marghe).
- Eventuale nuovo asset VFX, se la risposta implica sintesi visiva non
  ancora prodotta: in quel caso possibile collaborazione con
  `game-art-designer` (vedi `docs/cards/README.md`, regola sulle richieste
  ambigue sulla direzione visiva).

## Verifica

Da definire con i nuovi criteri.

## Gate manuali

- [ ] Controllo percettivo richiesto: sì — è un giudizio di feeling
      dell'attacco, non misurabile a priori.
- Altri gate: da definire con la geometria/ambito reale una volta chiarita
  la direzione.

## Decisioni

- **2026-09-15 — Resta `DA DEFINIRE`.** Priorità alta per volontà esplicita
  del proprietario, ma manca ancora la decisione precisa su cosa cambiare:
  non fissare un contratto sulla base di un'ipotesi ("forse") non ancora
  confermata.

## Documenti sincronizzati

- [ ] Nessuno finché la direzione non è decisa.

## Note

Segnalato dal proprietario durante il test reale su Pixel 9 della v0.3.0,
insieme ad altri cinque problemi nella stessa sessione (PS-178..PS-182).
