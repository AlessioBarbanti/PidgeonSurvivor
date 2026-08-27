# B34 — Coerenza UI pixel-fantasy arcade

Data implementazione: 27 agosto 2026  
Stato: `IN VERIFICA`

## Modifica consegnata

- Pausa, HUD e controlli touch usano la stessa palette notte, oro/arancio,
  crema, cyan funzionale e rosa/rosso della grammatica pixel-fantasy arcade.
- I pulsanti della pausa distinguono azioni primarie e secondarie; slider e
  toggle sono ancora controlli Godot accessibili, ma hanno rendering locale.
- XP/HP, timer e pausa conservano geometrie B18Q/B31. Il medaglione dell'abilità
  è un sibling non interattivo: il Button resta icon-only e conserva cooldown,
  target e `StyleBoxEmpty` B18K.
- Il joystick cambia soltanto palette e dettagli di disegno; input radius,
  visual radius, deadzone, acquisizione, ownership e multitouch B18L restano
  invariati.
- Il polish finale compatta la selezione: entrambe le card kit hanno altezza,
  padding e allineamento identici, gli emblemi crescono e il blocco
  nome/ruolo/CTA recupera spazio verticale. XP/HP guadagnano pochi pixel e un
  contrasto metallico senza variare il `GAMEPLAY_TOP_INSET`; pausa, ingranaggio,
  frecce e medaglione adottano lo stesso bevel scuro/oro.

## Evidenza disponibile

| Gate | Esito |
|---|---|
| Refresh editor headless | Verde: `godot_console --headless --editor --path . --quit` |
| Avvio headless scena principale | Verde: `godot_console --headless --path . --quit-after 3`; i contratti bootstrap incluso `B18Q_CONTRACT_OK` sono verdi, ma non è un test script |
| Smoke B34 e regressioni | Non eseguiti su richiesta del proprietario |
| Runtime/export Windows | Non eseguito |
| Export/ispezione APK Android | Verde: `ANDROID_STATIC_VALID`, SHA-256 `42D348759228290E605514B604AF19091D7E4B970D90E026D808C86299B877A4`, package `com.ilgioco.pidgeonsurvivor`, min SDK 31, target 36, arm64-v8a, firma v2 |
| Installazione/cold launch Pixel 9 | Verde: APK aggiornato installato, `GodotAppLauncher` in foreground e processo Godot attivo senza `FATAL EXCEPTION` o `SCRIPT ERROR` osservati |
| Cattura visuale Pixel 9 | Verde a 20:9: welcome, selezione, gameplay e pausa mostrano card kit allineate, HUD più leggibile e la famiglia iconica coerente |
| Android fisico multitouch, lifecycle, percezione umana | Aperto: richiede joystick tenuto con un dito più tocchi ripetuti sull'abilità, Back/Home/lock-resume e accettazione proprietario |

Non dichiarare chiusi i gate percettivi o touch finché il proprietario non avrà
provato l'APK corrente sul Pixel 9: joystick tenuto con un dito, tocchi ripetuti
sull'abilità con il secondo, poi Back/Home/lock e ripresa esplicita. Le catture
della sequenza Welcome → Selezione → Gameplay → Pausa non sostituiscono questa
prova fisica né l'accettazione umana.

## Correzione durante il polish

Il primo avvio breve della revisione aveva esteso XP/HP a `20`/`22` unità e ha
segnalato il vincolo B18Q. La versione esportata ripristina le altezze
contrattuali `18`/`20`, mantenendo il guadagno visivo tramite bordo, contrasto e
label; il successivo avvio breve ha riportato `B18Q_CONTRACT_OK`. Non è stato
eseguito alcuno smoke o runner B34.
