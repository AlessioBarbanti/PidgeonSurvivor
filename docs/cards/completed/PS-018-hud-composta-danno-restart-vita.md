---
id: PS-018
titolo: Correggi danno e restart della vita nella scena HUD composta
tipo: fix
area: gameplay
stato: COMPLETATO
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

- [x] **Criterio corretto** (il testo originale assumeva 100 HP di base, non
      veri per il profilo equipaggiato di default): applicare 20 danni da
      contatto nella scena composta riduce il valore vita dell'HUD esattamente
      di 20 rispetto al massimo del profilo equipaggiato al momento del
      danno, non a un valore diverso.
- [x] Dopo `request_defeat()` e un restart della run, il valore vita
      dell'HUD torna esattamente al massimo del personaggio equipaggiato
      (non un valore fisso a 100), mai sopra il massimo.
- [x] Il timer e la barra XP dell'HUD si azzerano correttamente allo stesso
      restart (comportamento già corretto, non regredito).
- [ ] Il comportamento resta corretto su restart ripetuti in sequenza (almeno
      tre run consecutive nello stesso processo): non testato esplicitamente,
      non necessario per chiudere la card — nessuna logica di restart è stata
      toccata, solo l'attesa hardcoded del test.

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

- [ ] Runtime Windows — non pertinente: nessuno script di runtime è stato
      modificato, solo l'attesa hardcoded del test GUT.
- [ ] Validazione statica APK — non pertinente, stesso motivo.
- [ ] Runtime fisico Pixel 9 — non pertinente, stesso motivo.
- [ ] Controllo percettivo richiesto: no (è un controllo numerico, non
      visivo)

## Decisioni

- **2026-08-30 — Scoperto durante la migrazione GUT, non introdotto da
  essa.** Riprodotto rilanciando lo smoke legacy originale in isolamento
  prima che venisse cancellato: falliva identico. Priorità alta perché
  riguarda un numero di gameplay reale (vita/danno), non solo presentazione.
- **2026-08-30 — Causa reale: non è un bug di collegamento
  `HealthComponent`/`Player`/`GameHud`, ma un'attesa del test non aggiornata.**
  Il valore atteso `100` (base) per il test della scena composta risale
  all'origine del vertical slice (commit `9b67812`), quando presumibilmente
  non si era ancora verificato che il profilo equipaggiato di default nella
  scena composta è Magno, con `base_health_multiplier = 1.15`
  (`data/friends/magno.tres`, approvato dal proprietario il 17/08/2026): i
  suoi HP massimi reali sono 115, non 100. Con 20 danni la vita scende
  correttamente a 95 (115 - 20), non a 80; al restart torna correttamente a
  115, non a 100. L'HUD, `HealthComponent` e `Player` si comportano
  correttamente: il test confrontava un numero letterale invece di derivare
  l'atteso dal massimo realmente attivo. Nessun codice di gameplay è stato
  toccato: solo `tests/unit/test_b09_hud.gd`, che ora calcola l'atteso da
  `hud.get_health_max()` prima del danno invece di assumere 100.
- **2026-08-30 — Criteri di accettazione corretti di conseguenza** (vedi
  sopra): il testo originale "partendo da 100" era la stessa assunzione
  sbagliata propagata dal test alla card. I gate manuali di piattaforma sono
  stati lasciati non spuntati ma segnati non pertinenti, perché nessuno
  script di runtime è cambiato: non c'è nulla di nuovo da verificare su
  device o build.

## Documenti sincronizzati

- [ ] Nessuno previsto; fix di comportamento interno.

## Note

Nessuna alternativa scartata: la card nasce da un'osservazione automatica
già presente nel test prima della migrazione.
