# B18C — Player animato e direzione persistente

## Stato

Implementazione e commit dedicato completati. Gate automatici, runtime e
verifica visiva Windows/Pixel 9 chiusi il 24 agosto 2026.

## Contratto implementato

- il corpo circolare azzurro e il cannoncino disegnato da `WeaponController`
  non vengono più renderizzati;
- ogni `FriendDefinition` dichiara una posa laterale destra, quattro fasi di
  camminata e la frequenza di animazione nei dati;
- Magno, Bea, Zat, Alea e Aleo alternano i tre ritagli laterali disponibili;
  Lollo, Migi e Marghe hanno una sola posa laterale valida nel foglio CC0 e
  usano quindi la stessa texture con bob e lieve inclinazione tra le fasi,
  senza attraversare i ritagli trasparenti del foglio;
- il Player ribalta gli stessi sprite per guardare a sinistra;
- qualsiasi movimento anima il personaggio, mentre il neutro mostra la posa
  ferma;
- l'ultimo asse orizzontale non nullo determina la direzione; input verticale,
  neutro, pausa e focus loss non la cancellano;
- `Player.get_facing_direction()` espone `Vector2.LEFT` o `Vector2.RIGHT` alle
  abilità attive;
- restart e nuova run ripartono in posa ferma verso destra.

Gli sprite sono ritagli `32×32` dal foglio CC0 già approvato. Dimensioni e
velocità del Player restano unità logiche del mondo Godot; questa modifica non
tocca collisioni, velocità, danni o distanze gameplay.

## Verifica automatica

Comando dedicato:

```powershell
godot_console --headless --path . --resolution 1280x720 --script tests/integration/_player_direction_animation_smoke.gd
```

Marker atteso:

```text
B18C_PLAYER_DIRECTION_ANIMATION_SMOKE_OK
```

Il test copre i dati di tutti gli otto profili, posa ferma, alternanza delle
fasi, fallback esplicito di Lollo, sinistra/destra, diagonale, movimento
verticale, neutro, pausa e restart. Il contratto composto della scena stampa
inoltre `B18C_CONTRACT_OK`.

Risultati del 23 agosto 2026:

- `22/22` smoke in `tests/integration/` verdi, con marker atteso e log privi di
  `SCRIPT ERROR`, `FATAL EXCEPTION`, leak `ObjectDB` o risorse residue;
- `tools/verify-toolchain.ps1 -RunProjectSmoke`: superato su Godot `4.7.1`;
- export debug `Windows Desktop`: completato;
- smoke dell'export Windows a `1280×720`: exit `0`, `B18C_CONTRACT_OK` presente
  e nessun errore runtime.

## Gate manuali chiusi

- Windows: Magno e Lollo verificati in posa neutra, movimento a destra/sinistra
  e flip. Le catture dirette della finestra Godot confermano animazione leggibile
  e assenza di cannoncino e fondo circolare azzurro;
- Pixel 9 `tokay`, Android 17/API 37: joystick fisico, cambi di direzione,
  rilascio, posa ferma sul lato persistente e abilità col secondo dito approvati;
- pausa, Home, lock/sblocco, ripresa esplicita e restart non lasciano input,
  direzione o grafica residui. La posizione resta invariata dopo lock/resume con
  la correzione lifecycle descritta in B18L.

Le catture Windows restano locali in `exports/screenshots/`, directory ignorata
da Git. Il commit della slice è `ceeaa47`.
