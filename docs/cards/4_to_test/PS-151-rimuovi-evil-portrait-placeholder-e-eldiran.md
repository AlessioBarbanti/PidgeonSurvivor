---
id: PS-151
titolo: Rimuovi il fallback evil_portrait_placeholder e la dipendenza da eldiran_rpg_characters
tipo: chore
area: gameplay
stato: IN VERIFICA
priorita: media
dipende_da: []
origine:
creato: 2026-09-10
aggiornato: 2026-09-10
---

# PS-151 — Rimuovi il fallback evil_portrait_placeholder e la dipendenza da eldiran_rpg_characters

## Contesto

Mentre lavorava sui nuovi asset di Alea per PS-150, il proprietario ha
cancellato dal worktree `assets/art/third_party/eldiran_rpg_characters/` e
`assets/art/third_party/pinhead_inline_skate/`. `pinhead_inline_skate` non
era più referenziato da nessun file. `eldiran_rpg_characters/
RPGCharacterSprites32x32-transparent.png` era invece ancora un `ext_resource`
in tutti e otto i `data/friends/*.tres`, usato per costruire
`evil_portrait_placeholder` (un `AtlasTexture` ritagliato dal foglio), e in
`tests/unit/test_b17_friend_content.gd`, che ne verificava anche lo SHA-256.
Senza quel file il caricamento di ogni `FriendDefinition` si sarebbe rotto.

Il fallback era però già morto a runtime: da PS-052 tutti e otto i profili
hanno `evil_portrait` valorizzato e `portraits_approved = true`, quindi
`FriendDefinition.get_public_evil_portrait()` non ha mai risolto
`evil_portrait_placeholder` in produzione. Il proprietario ha confermato
esplicitamente di non volere alcun fallback per il ritratto Evil: «Elimina
tutte le referenze di quel file, non mi serve e appesantisce solo il gioco e
la logica. Non mi interessa il fallback».

## Comportamento atteso

Nessun personaggio dipende più dal foglio CC0 di terze parti. Il ritratto
Evil di un profilo non approvato resta semplicemente vuoto (nessuna texture),
invece di cadere su un ritaglio generico non pertinente al personaggio. Il
ritratto Player mantiene il proprio fallback dedicato (`portrait_placeholder`,
la stessa immagine del personaggio), invariato.

## Criteri di accettazione

- [x] `scripts/content/friend_definition.gd` non dichiara più
      `evil_portrait_placeholder`; `is_valid()` non lo richiede più;
      `get_public_evil_portrait()` ritorna `evil_portrait` se
      `portraits_approved`, altrimenti `null` (nessun placeholder).
- [x] Nessuno degli otto `data/friends/*.tres` referenzia più
      `assets/art/third_party/eldiran_rpg_characters/` (`ext_resource`
      `2_sheet`, `sub_resource AtlasTexture_evil`,
      `evil_portrait_placeholder`); `portrait_placeholder` (Player) resta
      invariato.
- [x] `assets/art/third_party/eldiran_rpg_characters/` e
      `assets/art/third_party/pinhead_inline_skate/` restano rimosse dal
      worktree; nessun file nel repository le referenzia più.
- [x] `tests/unit/test_b17_friend_content.gd` non referenzia più il file
      eliminato: `test_derived_sprite_sheet_asset_integrity` (verificava lo
      SHA-256 del foglio) è rimosso; `test_safe_fallbacks_and_asset_replacement`
      verifica che un profilo non approvato risolva `evil_portrait` a `null`
      invece che al placeholder rimosso.
- [x] Nessuna regressione sul resto del roster (le altre sette Evil, ritratti
      Player, Boss Intro).

## Ambito

- `scripts/content/friend_definition.gd`.
- `data/friends/alea.tres`, `aleo.tres`, `bea.tres`, `lollo.tres`,
  `magno.tres`, `marghe.tres`, `migi.tres`, `zat.tres`.
- `tests/unit/test_b17_friend_content.gd`, `tools/milestone-test-map.json`
  se necessario.
- `docs/visual-audio-identity.md`: rimuovere le due righe della tabella
  third_party e la nota sul fallback Eldiran.

Non toccare:

- `portrait_placeholder` (fallback Player) e la sua logica in
  `get_public_portrait()`;
- `evil_portrait`, `portrait`, `selection_portrait` e gli altri asset
  approvati di ciascun personaggio;
- Il wiring di PS-150 (`passive_icon` di Alea), card distinta.

## Verifica

- Smoke: `tests/unit/test_b17_friend_content.gd` (aggiornato) e
  `tests/unit/test_ps051_boss_intro_identity.gd` (Evil intro, ritratto
  Evil).
- Focused (`-RefreshEditor`): `3/3` file (incluso `test_b17_friend_content.gd`),
  nessun `SCRIPT ERROR`/`FATAL EXCEPTION`.
- Relevant: `4/4` focused, `20/20` regressioni, 24/24 step, nessun
  `SCRIPT ERROR`/`FATAL EXCEPTION`.
- Full: `137/137` regressioni (426 asserzioni, 0 fallite), toolchain PASS,
  138/138 step, nessun `SCRIPT ERROR`/`FATAL EXCEPTION`.

## Gate manuali

- [ ] Runtime Windows
- [ ] Validazione statica APK
- [ ] Runtime fisico Pixel 9
- [ ] Controllo percettivo richiesto: no — nessun asset visivo nuovo, solo
      rimozione di un fallback mai esercitato in produzione.

## Decisioni

- **2026-09-10 — Cancellazione avviata dal proprietario, contratto chiuso da
  questa card.** Il proprietario ha cancellato i due asset third-party
  lavorando su PS-150; segnalato perché la sola cancellazione avrebbe rotto
  il caricamento di tutti gli otto `FriendDefinition`. Il proprietario ha poi
  scelto esplicitamente di rimuovere ogni riferimento e il fallback stesso,
  invece di ripristinare il file.
- **2026-09-10 — Nessun impatto runtime osservabile.** Il fallback non era
  mai stato esercitato dal 2026-08 (PS-052): tutti gli otto profili hanno
  `evil_portrait` approvato. La rimozione è un chore di pulizia, non un
  cambio di comportamento per un giocatore.

## Documenti sincronizzati

- [x] `docs/visual-audio-identity.md`: rimossa la tabella third_party e
      aggiornata la nota su PS-051/PS-052 per riflettere la rimozione del
      fallback.

## Note

`pinhead_inline_skate` non richiede modifiche a codice o dati: non era
referenziato da nessun file prima della cancellazione.
