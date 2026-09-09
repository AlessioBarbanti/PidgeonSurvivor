---
id: PS-144
titolo: Valuta arte dedicata per le VFX degli attacchi Boss (oltre il telegraph)
tipo: art
area: arte
stato: DA DEFINIRE
priorita: bassa
dipende_da: [PS-141]
origine:
creato: 2026-09-10
aggiornato: 2026-09-10
---

# PS-144 — Valuta arte dedicata per le VFX degli attacchi Boss (oltre il telegraph)

## Contesto

Oggi tutte le VFX degli attacchi Boss (`scripts/bosses/first_boss.gd`) sono
disegni vettoriali procedurali — `draw_arc`/`draw_circle` per il ring del
volley radiale, il cerchio del blast mirato e il mirino a croce — senza
alcuna texture. Solo il corpo del Boss stesso (`BossSprite`) è uno sprite
d'arte vero. Il proprietario ha segnalato di non gradire questo aspetto
"piatto" delle abilità, oltre al problema specifico del telegraph già
affrontato in [PS-141](../2_to_do/PS-141-arricchisci-telegraph-attacchi-boss.md)
(arricchimento procedurale: glow, animazione di intensità legata al
countdown, senza nuova arte).

PS-141 lascia esplicitamente aperta la possibilità che, se il risultato
procedurale resta troppo "vettoriale", serva una vera passata d'arte (es.
una decal di terra bruciata) come step successivo. Questa card generalizza
quella possibilità a tutti i pattern d'attacco visivo del Boss, non solo al
telegraph, ma **non decide ancora** se e quanto procedere: dipende da quanto
l'arricchimento procedurale di PS-141 risolverà già la sensazione "piatta"
una volta implementato e visto in gioco.

## Domanda da porre al proprietario (per uscire da DA DEFINIRE)

Dopo aver visto PS-141 risolto e verificato in gioco:

1. La sensazione "piatta" persiste ancora sui pattern d'attacco Boss (ring
   volley radiale, blast mirato, mirino a croce), o l'arricchimento
   procedurale di PS-141 è già sufficiente?
2. Se persiste, quali pattern specifici richiedono arte dedicata — tutti, o
   solo quelli percepiti come più deboli? Arte generica riusabile su
   Boss/Evil, o differenziata per identità (coerente con PS-051, identità
   individuale degli Evil)?
3. Che tipo di asset: texture statiche (decal, ring), sprite-sheet animati,
   o un mix? Questo determina la complessità della card `art` risultante e
   se serve un consulto di pianificazione con `game-art-designer` (probabile,
   vista l'ambiguità attuale sulla direzione visiva).

## Ambito

- Nessuna implementazione in questa card: è un segnaposto per una decisione
  futura del proprietario, non ancora una card `PRONTO`.
- Quando si deciderà di procedere, questa card (o una nuova che la
  sostituisce) andrà rifinita in consulto di pianificazione con
  `game-art-designer` prima di scrivere Comportamento atteso/Criteri di
  accettazione (la richiesta è oggi ambigua sulla direzione visiva — regola
  PS-109).
- Se confermata, seguirà probabilmente il pattern a due card (PS-090):
  una `tipo: art` per master/derivato/manifest, una di integrazione separata.

## Decisioni

- **2026-09-10 — Aperta come DA DEFINIRE, non PRONTO.** Il proprietario ha
  chiesto esplicitamente di "metterla in idea per ora": la valutazione
  dipende dall'esito di PS-141, non ancora risolta al momento dell'apertura
  di questa card.

## Note

Non duplica PS-141 (telegraph, già scoped e pronta) né la riapre: la
generalizza come possibilità futura sugli altri pattern d'attacco, da
attivare solo dopo aver visto se il procedurale già arricchito basta.
