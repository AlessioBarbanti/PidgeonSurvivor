---
id: PS-018
titolo: Correggi danno e restart della vita nella scena HUD composta
tipo: fix
area: gameplay
stato: PRONTO
priorita: alta
dipende_da: []
origine:
creato: 2026-08-30
aggiornato: 2026-08-30
---

# PS-018 — Correggi danno e restart della vita nella scena HUD composta

## Contesto

Nella scena composta (Player, HUD e run reali insieme, non fixture isolate),
un danno da contatto di prova non produce la riduzione di vita attesa
sull'HUD, e un restart successivo non riporta la vita al valore massimo
corretto. Scoperto durante la migrazione dei test da smoke legacy a GUT;
riprodotto identico rilanciando lo smoke legacy originale (`_hud_smoke.gd`,
non toccato) in isolamento prima che venisse cancellato: non è un problema
introdotto dalla migrazione. Trattandosi di vita e danno reali (non solo
presentazione), l'impatto è più alto delle altre regressioni visive
elencate nelle card sorelle.

## Comportamento atteso

Nella scena composta, un danno da contatto applicato al Player si riflette
sull'HUD nella quantità esatta inflitta; un restart successivo riporta la
vita mostrata dall'HUD esattamente al massimo, senza residui della run
precedente.

## Criteri di accettazione

- [ ] Applicare 20 danni da contatto nella scena composta porta il valore
      vita dell'HUD a 80 (partendo da 100), non a un valore diverso.
- [ ] Dopo `request_defeat()` e un restart della run, il valore vita
      dell'HUD torna esattamente a 100 (o al massimo corrente del
      personaggio equipaggiato, se diverso da 100), mai sopra il massimo.
- [ ] Il timer e la barra XP dell'HUD si azzerano correttamente allo stesso
      restart (comportamento già corretto, da non regredire).
- [ ] Il comportamento resta corretto su restart ripetuti in sequenza
      (almeno tre run consecutive nello stesso processo).

## Ambito

- Collegamento fra `HealthComponent`/`Player` e `GameHud` nella scena
  composta (`scenes/game/movement_slice.tscn`), in particolare
  l'aggiornamento della vita dopo danno da contatto e il reset al restart.

Non modificare:

- il calcolo del danno da contatto stesso (`ContactDamage`,
  `HealthComponent.take_damage`), se già corretto isolatamente;
- la logica di restart di `RunController` per stati non legati alla vita.

## Verifica

- Test: `tests/unit/test_b09_hud.gd` (sezione scena composta) — fallisce
  oggi sui due controlli sopra descritti.
- Profilo minimo prima della chiusura: `Relevant`

## Gate manuali

- [ ] Runtime Windows
- [ ] Validazione statica APK
- [ ] Runtime fisico Pixel 9 (percorso: subisci danno da contatto in run
      reale, verifica la barra vita HUD, muori e riparti, verifica il
      reset)
- [ ] Controllo percettivo richiesto: no (è un controllo numerico, non
      visivo)

## Decisioni

- **2026-08-30 — Scoperto durante la migrazione GUT, non introdotto da
  essa.** Riprodotto rilanciando lo smoke legacy originale in isolamento
  prima che venisse cancellato: falliva identico. Priorità alta perché
  riguarda un numero di gameplay reale (vita/danno), non solo presentazione.

## Documenti sincronizzati

- [ ] Nessuno previsto; fix di comportamento interno.

## Note

Nessuna alternativa scartata: la card nasce da un'osservazione automatica
già presente nel test prima della migrazione.
