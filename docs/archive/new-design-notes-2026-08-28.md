# Archivio — Note di design del 28 agosto 2026

> Nota temporanea superata: la CTA Boss e lo sprite dello splitter sono stati
> integrati; il lavoro sui proiettili è tracciato da PS-002.

## Pulsanti: asset ancora da generare

Oggi la UI riusa due sole texture CTA (`character_select_cta_base.png` arancio
e `secondary_button_cta_base.png` blu-oro) su welcome, selezione personaggio,
tutorial, pausa e fine partita. È una scelta di design legittima (due varianti
coerenti riusate ovunque), non un ripiego: non serve moltiplicare gli asset
solo per varietà.

Un asset nuovo vale la pena solo dove il rettangolo flat resta visibile e
stona con il resto ormai texturizzato:

- **Boss UI — `ContinueButton` ("AFFRONTA")** (`scenes/ui/boss_ui.tscn`):
  resta un rettangolo viola flat (`StyleBoxFlat_continue_normal/hover`),
  mentre tutto il resto del pannello intro boss (bordo, titolo, quote) ha già
  una finitura curata. È il pulsante più visibile rimasto senza grafica
  dedicata, ricompare a ogni boss. Prossimo step: generare una plancia CTA
  in tono viola/magenta coerente con la palette boss (`0.7, 0.24, 0.96` /
  `0.78, 0.32, 1`), stesso trattamento a nine-patch delle altre due texture.
- **Variante "danger/destructive"**: azioni distruttive o di conferma rischiosa
  (`ConfirmChangeButton` in pausa, eventuale conferma di reset) oggi usano la
  stessa plancia arancione dei CTA positivi ("Riprendi", "Gioca con X").
  Valutare una terza variante (rossa) solo se in futuro serve distinguere
  visivamente un'azione irreversibile da un'azione di progressione normale;
  non è un problema visto oggi, solo un rischio di chiarezza UX.

## Nemici: sprite mancante

- **Frammento dello splitter ("piccione viola")** (`data/enemies/enemy_archetype_splitter_fragment.tres`,
  id `splitter_fragment`): è il nemico che compare quando uccidi uno
  `splitter` (`enemy_archetype_splitter.tres`), che invece ha già uno sprite
  animato dedicato (`assets/art/enemies/pigeons/pigeon_splitter.png`, 3 frame
  di camminata). Il frammento non ha `sprite_frames`: usa solo
  `silhouette_kind = 0` ("Round") con `body_color`/`outline_color`/
  `accent_color` viola, cioè il disegno procedurale di fallback pensato per
  "nessun asset mancante non lascia un buco visivo" — non uno sprite
  disegnato. Prossimo step: generare uno sprite pixel-art per
  `splitter_fragment`, coerente con la palette viola già definita
  (`0.7, 0.28, 0.85` / `0.94, 0.72, 1.0`) e in stile con `pigeon_splitter.png`,
  magari come piccione "sciamato"/più piccolo per leggere subito la
  differenza di taglia rispetto al genitore.

## Proiettili: decisione aperta, non un gap da colmare

Sia i proiettili del giocatore (`scripts/combat/projectile.gd`) sia quelli
nemici/boss (`scripts/bosses/boss_projectile.gd`) sono disegnati al 100% in
modo procedurale (`_draw()`: cerchio pieno + outline + scia/arco), colore
guidato da `body_color`/`trail_color`/`outline_color` esportati per
differenziare arma per arma. Non è un'incoerenza come i pulsanti o il
frammento viola: è la stessa tecnica ovunque, in linea col principio già visto
nei nemici procedurali (nessun asset mancante lascia un buco visivo).

Passare a sprite texturizzati non è un "fix", è un cambio di direzione
artistica: servirebbe un asset per ogni arma/abilità (oggi la differenziazione
è solo colore/scia) e andrebbe validata la leggibilità con molti nemici e
proiettili a schermo insieme, tipica di un survivors-like. Da valutare come
scelta esplicita, non da eseguire come conseguenza automatica del lavoro sui
pulsanti/nemici.

## Cosa NON convertire

I pulsanti "glifo" (ingranaggio impostazioni, pausa in HUD, frecce carosello
in `character_select_overlay.tscn`) e le card (`upgrade_card.tscn`) restano
volutamente rettangoli flat scuri con bordo colorato: fanno parte di un
secondo livello di controlli compatti/iconici coerente in tutta la UI, non
sono placeholder dimenticati. Non generare texture per questi finché non
cambia la direzione artistica dell'intero secondo livello.
